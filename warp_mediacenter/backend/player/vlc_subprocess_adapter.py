"""Subprocess-based VLC player adapter.

Launches the system-installed VLC binary as a child process and controls it
via VLC's built-in RC (Remote Control) TCP interface.

Advantages over the python-vlc binding approach (VLCAdapter):
- No python-vlc / libvlc import required — works with any installed VLC.
- Uses the full VLC app binary, which has native TLS support (SecureTransport
  on macOS, GnuTLS/OpenSSL on Linux) and is not affected by the embedded-
  libvlc HTTPS failures seen with some python-vlc configurations.
- VLC version updates are picked up automatically.
"""

from __future__ import annotations

import re
import socket
import subprocess
import threading
import time
from pathlib import Path
from typing import Callable, List, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.player.adapter import (
    AudioTrack,
    PlayerAdapter,
    SubtitleTrackInfo,
)
from warp_mediacenter.backend.player.exceptions import PlayerError
from warp_mediacenter.backend.player.stream_proxy import StreamProxy
from warp_mediacenter.backend.player.vlc_paths import find_system_vlc_binary

log = get_logger(__name__)

# ---------------------------------------------------------------------------
# Module-level constants
# ---------------------------------------------------------------------------

_RC_HOST = "127.0.0.1"
_RC_PORT_BASE = 9100          # first port to try; scans up to +20 for a free one
_VLC_STARTUP_TIMEOUT_S = 8.0  # max seconds to wait for RC socket to accept
_STATE_POLL_INTERVAL_S = 0.5  # how often the daemon thread checks VLC state
_CMD_TIMEOUT_S = 2.0          # socket read timeout for RC commands
_RECV_BUF = 4096

# Adaptive buffer watchdog thresholds for HTTP/HTTPS proxy streams.
#
# When playing through the local StreamProxy, VLC is launched --start-paused.
# The _auto_play_after_buffer thread waits until the download is at least
# _PROXY_HIGH_WATER bytes ahead of VLC's read position (or the max-wait timeout
# expires), then sends "play".
#
# After playback starts, _buffer_watchdog runs continuously:
#   • If buffer_ahead < LOW_WATER  → pause VLC so CDN can rebuild the lead
#   • If buffer_ahead ≥ HIGH_WATER (while watchdog-paused) → resume VLC
#
# Rationale for the values:
#   A typical HD stream has a bitrate of ~0.33 MB/s.  RealDebrid CDN is often
#   observed at 0.3–0.5 MB/s.  At a 0.03 MB/s deficit the 16 MB high-water
#   mark takes 533 s (≈ 9 min) to drain to 4 MB, giving long smooth segments
#   between short (~40 s) watchdog pauses.  The max-wait of 120 s is a
#   fallback for very slow connections so the user isn't left staring at a
#   paused window indefinitely.
_PROXY_HIGH_WATER_BYTES = 16 * 1024 * 1024  # 16 MB — start / resume threshold
_PROXY_LOW_WATER_BYTES  =  4 * 1024 * 1024  #  4 MB — pause threshold
_PROXY_MAX_WAIT_S       = 120.0             # max seconds to wait for initial buffer


# ---------------------------------------------------------------------------
# Free-port helper
# ---------------------------------------------------------------------------

def _find_free_port(base: int) -> int:
    """Return the first free TCP port in [base, base+20)."""
    for port in range(base, base + 20):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind((_RC_HOST, port))
                return port
            except OSError:
                continue
    return base  # last resort — will surface as a connect error


# ---------------------------------------------------------------------------
# RC client
# ---------------------------------------------------------------------------

class _RCClient:
    """Minimal TCP client for VLC's ``--intf rc`` / ``--extraintf rc`` interface.

    VLC listens on ``--rc-host host:port`` and accepts line-oriented text
    commands.  Each response is terminated by a VLC prompt ``"> "``.
    """

    def __init__(self, host: str, port: int) -> None:
        self._host = host
        self._port = port
        self._sock: Optional[socket.socket] = None

    # ------------------------------------------------------------------
    # Connection management
    # ------------------------------------------------------------------

    def _connect(self) -> None:
        if self._sock is not None:
            return
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(_CMD_TIMEOUT_S)
        s.connect((self._host, self._port))
        self._sock = s
        # Drain the VLC banner / initial prompt so the socket is clean.
        self._drain()

    def _drain(self) -> None:
        """Read and discard any pending data (banner / stale prompts)."""
        if self._sock is None:
            return
        self._sock.settimeout(0.3)
        try:
            while True:
                chunk = self._sock.recv(_RECV_BUF)
                if not chunk:
                    break
        except (socket.timeout, OSError):
            pass
        finally:
            self._sock.settimeout(_CMD_TIMEOUT_S)

    def wait_for_ready(self, timeout: float = _VLC_STARTUP_TIMEOUT_S) -> None:
        """Block until VLC's RC interface accepts a TCP connection.

        Retries every 200 ms until *timeout* seconds have elapsed.
        Raises ``PlayerError`` if the socket never becomes available.
        """
        deadline = time.time() + timeout
        last_exc: Exception = OSError("timeout")
        while time.time() < deadline:
            try:
                self._connect()
                log.debug("vlc_rc_connected", host=self._host, port=self._port)
                return
            except OSError as exc:
                last_exc = exc
                time.sleep(0.2)
        raise PlayerError(
            f"VLC RC interface at {self._host}:{self._port} "
            f"not ready after {timeout:.1f}s — {last_exc}"
        )

    def close(self) -> None:
        if self._sock:
            try:
                self._sock.close()
            except OSError:
                pass
            self._sock = None

    # ------------------------------------------------------------------
    # Command execution
    # ------------------------------------------------------------------

    def cmd(self, command: str) -> str:
        """Send *command* to VLC and return the response text (stripped).

        Re-connects automatically if the socket was closed.
        Returns an empty string on any socket error so callers never raise.
        """
        for attempt in range(2):
            try:
                self._connect()
                assert self._sock is not None
                # Drain any unsolicited VLC notifications (state-change messages
                # etc.) that may have arrived since the last command, so they
                # don't contaminate the response we're about to read.
                self._drain()
                self._sock.sendall((command + "\n").encode())
                return self._read_response()
            except OSError as exc:
                log.debug("vlc_rc_send_failed", cmd=command, attempt=attempt, error=str(exc))
                self._sock = None  # force reconnect on next call
                if attempt == 1:
                    return ""
        return ""

    def _read_response(self) -> str:
        """Read until we see the VLC prompt ``> `` or a timeout.

        VLC terminates each command response with ``\\r\\n> `` (CRLF + prompt).
        We stop reading as soon as we detect this pattern.
        """
        assert self._sock is not None
        buf = b""
        try:
            while True:
                chunk = self._sock.recv(_RECV_BUF)
                if not chunk:
                    break
                buf += chunk
                # VLC prompt appears as "> " at the very end of the response,
                # either after CRLF or a bare newline.
                stripped = buf.rstrip(b" ")
                if stripped.endswith(b">") or stripped.endswith(b"\n>"):
                    break
        except socket.timeout:
            pass
        # Strip prompt lines and return clean response text.
        text = buf.decode(errors="replace")
        lines = [ln.rstrip("\r") for ln in text.splitlines()
                 if ln.strip() not in (">", "")]
        return "\n".join(lines).strip()


# ---------------------------------------------------------------------------
# State helpers
# ---------------------------------------------------------------------------

_STATE_RE = re.compile(r"\(\s*state\s+(\w+)\s*\)", re.IGNORECASE)
_VLC_TO_ADAPTER: dict[str, str] = {
    "playing": "Playing",
    "paused":  "Paused",
    "stopped": "Stopped",
    "ended":   "Ended",
    "error":   "Error",
}


def _parse_state(raw: str) -> str:
    m = _STATE_RE.search(raw)
    if m:
        return _VLC_TO_ADAPTER.get(m.group(1).lower(), "Stopped")
    return "Stopped"


def _parse_int(raw: str) -> int:
    """Extract the first integer from a VLC RC response."""
    m = re.search(r"\d+", raw)
    return int(m.group()) if m else 0


# ---------------------------------------------------------------------------
# Main adapter
# ---------------------------------------------------------------------------

class SubprocessVLCAdapter(PlayerAdapter):
    """PlayerAdapter that drives a system-installed VLC via subprocess + RC TCP.

    On construction, ``find_system_vlc_binary()`` locates VLC.  Playback is
    started by ``play()``, which spawns a new VLC process for each media item.
    The RC TCP interface is used for all subsequent status queries and control
    commands.
    """

    def __init__(self) -> None:
        vlc_bin = find_system_vlc_binary()
        if not vlc_bin:
            raise PlayerError(
                "System VLC not found.  Install VLC from https://www.videolan.org/ "
                "or ensure it is on PATH."
            )
        self._vlc_bin: str = vlc_bin
        self._rc_port: int = _find_free_port(_RC_PORT_BASE)

        self._proc: Optional[subprocess.Popen] = None  # type: ignore[type-arg]
        self._rc: Optional[_RCClient] = None
        self._state_callback: Optional[Callable[[str], None]] = None
        self._poll_thread: Optional[threading.Thread] = None
        self._last_state: str = "Stopped"
        self._muted_volume: Optional[int] = None  # stored for toggle_mute
        self._subtitle_delay_ms: int = 0
        self._lock = threading.Lock()

        # When True the buffer watchdog has paused VLC internally for rebuffering.
        # _poll_loop suppresses state-change callbacks for these transitions so the
        # service layer (and therefore Trakt scrobbling) stays oblivious to them.
        self._buffering_paused: bool = False

        # Last non-zero VLC position (ms) captured by the poll loop or by
        # get_position_ms() while VLC is Playing.  Used as a fallback when
        # get_time returns 0 after a stop — VLC resets the position counter
        # as soon as the media stops, so by the time _on_player_state_change
        # fires in the service layer the live query already returns 0.
        # This field is updated every poll cycle (every 500 ms) independently
        # of whether the frontend is polling /player/status, so it works even
        # when the user is watching in the detached desktop VLC window with no
        # UI page open.
        self._last_known_position_ms: int = 0

        # Pre-buffering proxy — routes HTTP/HTTPS CDN streams through a
        # local download-and-serve layer so VLC reads at loopback speed.
        self._proxy = StreamProxy()

        log.info("subprocess_vlc_adapter_ready", binary=self._vlc_bin, rc_port=self._rc_port)

    # ------------------------------------------------------------------
    # Playback lifecycle
    # ------------------------------------------------------------------

    # ------------------------------------------------------------------
    # Pre-buffering (preload before VLC launches)
    # ------------------------------------------------------------------

    def preload(self, url: str) -> None:
        """Start the stream proxy downloading *url* without launching VLC.

        The frontend calls this after obtaining the CDN URL, shows a progress
        bar while the download builds up, then calls :meth:`play` once enough
        has buffered.  :meth:`play` detects the running preload and reuses it
        instead of restarting the download.
        """
        if not url.startswith(("http://", "https://")):
            log.warning("preload_skipped_not_http", url=url[:80])
            return
        if self._proxy.is_active_for(url):
            log.info("preload_already_active", url=url[:80], downloaded_mb=self._proxy.bytes_downloaded // (1024 * 1024))
        else:
            log.info("preload_starting", url=url[:80])
            self._proxy.stop()   # abort any previous stream for a different URL
            self._proxy.start(url)

    def preload_status(self) -> dict:
        """Return the current download progress as a JSON-serialisable dict."""
        return self._proxy.snapshot()

    # ------------------------------------------------------------------
    # Playback lifecycle
    # ------------------------------------------------------------------

    def play(
        self,
        source: str,
        *,
        is_stream: bool = False,
        start_paused: bool = False,
    ) -> None:
        """Spawn VLC with *source* and attach the RC interface.

        When :meth:`preload` was previously called for the same *source* URL,
        :meth:`play` reuses the already-running proxy download so the user
        starts watching immediately instead of waiting again.  For all other
        HTTP/HTTPS sources the stream is routed through a fresh
        :class:`StreamProxy` with an auto-buffer pause/resume cycle.
        """
        use_proxy = source.startswith(("http://", "https://"))

        # Detect an existing preload so we can reuse its download.
        has_preload = use_proxy and self._proxy.is_active_for(source)

        # Kill any previous VLC process.  Only stop the proxy when there is
        # no preload to reuse — otherwise we'd abort the download we just built.
        self._stop_process(stop_proxy=not has_preload)

        if use_proxy:
            if has_preload:
                play_source = self._proxy.local_url
                log.info(
                    "vlc_reusing_preload",
                    proxy=play_source,
                    buffered_mb=self._proxy.bytes_downloaded // (1024 * 1024),
                )
            else:
                play_source = self._proxy.start(source)
                log.info(
                    "vlc_using_stream_proxy",
                    original=source[:80],
                    proxy=play_source,
                )
        else:
            play_source = source

        args: list[str] = [
            self._vlc_bin,
            play_source,
            "--extraintf", "rc",
            "--rc-host", f"{_RC_HOST}:{self._rc_port}",
            "--no-rc-fake-tty",
            "--play-and-stop",
            "--no-repeat",
            "--no-loop",
            # 15-second network cache: the proxy serves at loopback speed so
            # VLC fills this in milliseconds, giving a cushion against stalls.
            "--network-caching", "15000",
        ]

        if use_proxy and not has_preload:
            # No preload: launch paused so the download thread can build a
            # buffer lead.  _auto_play_after_buffer will un-pause once ready.
            args.append("--start-paused")
        elif start_paused:
            args.append("--start-paused")

        log.info(
            "vlc_subprocess_launching",
            binary=self._vlc_bin,
            source=play_source[:80],
            rc_port=self._rc_port,
            has_preload=has_preload,
            proxy=use_proxy,
        )

        self._proc = subprocess.Popen(
            args,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

        self._rc = _RCClient(_RC_HOST, self._rc_port)
        try:
            self._rc.wait_for_ready()
        except PlayerError:
            log.error("vlc_rc_not_ready", pid=self._proc.pid)
            raise

        log.info("vlc_subprocess_started", pid=self._proc.pid, rc_port=self._rc_port)
        self._start_poll_thread()

        if use_proxy and not start_paused:
            if has_preload:
                # Already buffered — run watchdog immediately (safety net).
                t = threading.Thread(
                    target=self._buffer_watchdog,
                    daemon=True,
                    name="vlc-buffer-watchdog",
                )
            else:
                # No preload — wait for initial buffer then run watchdog.
                t = threading.Thread(
                    target=self._auto_play_after_buffer,
                    daemon=True,
                    name="vlc-autoplay",
                )
            t.start()

    def pause(self) -> None:
        self._rc_cmd("pause")

    def resume(self) -> None:
        self._rc_cmd("play")

    def stop(self) -> None:
        self._rc_cmd("stop")

    def close(self) -> None:
        self._rc_cmd("quit")
        self._stop_process()
        self._proxy.close()

    # ------------------------------------------------------------------
    # Seeking / volume / rate
    # ------------------------------------------------------------------

    def seek_ms(self, milliseconds: int) -> None:
        seconds = max(0, milliseconds // 1000)
        self._rc_cmd(f"seek {seconds}")

    def set_volume(self, volume: int) -> None:
        # VLC RC volume scale: 0–512 (256 = 100%).
        vlc_vol = int(max(0, min(100, volume)) * 2.56)
        self._rc_cmd(f"volume {vlc_vol}")

    def get_volume(self) -> int:
        raw = self._rc_cmd("volume")
        vlc_vol = _parse_int(raw)
        return min(100, int(vlc_vol / 2.56))

    def toggle_mute(self) -> None:
        current = self.get_volume()
        if current > 0:
            self._muted_volume = current
            self.set_volume(0)
        else:
            self.set_volume(self._muted_volume or 50)
            self._muted_volume = None

    def set_rate(self, rate: float) -> None:
        # VLC RC interface does not support playback rate; log and ignore.
        log.warning("vlc_rc_rate_unsupported", rate=rate)

    def get_rate(self) -> float:
        return 1.0

    # ------------------------------------------------------------------
    # Position / duration
    # ------------------------------------------------------------------

    def get_position_ms(self) -> int:
        raw = self._rc_cmd("get_time")
        pos = _parse_int(raw) * 1000
        if pos > 0:
            # Keep the adapter-level tracker in sync with every live query
            # (covers now_playing() polls from the frontend as well).
            self._last_known_position_ms = pos
            return pos
        # VLC resets get_time to 0 the moment a media item stops.  Return the
        # last captured position so callers still see a meaningful value during
        # the scrobble-stop calculation that runs immediately after "Stopped" fires.
        return self._last_known_position_ms

    def get_duration_ms(self) -> int:
        raw = self._rc_cmd("get_length")
        return _parse_int(raw) * 1000

    # ------------------------------------------------------------------
    # State
    # ------------------------------------------------------------------

    def get_state(self) -> str:
        if self._proc is not None and self._proc.poll() is not None:
            return "Stopped"
        raw = self._rc_cmd("status")
        return _parse_state(raw)

    def on_state_change(self, callback: Callable[[str], None]) -> None:
        self._state_callback = callback

    # ------------------------------------------------------------------
    # Audio tracks
    # ------------------------------------------------------------------

    def list_audio_tracks(self) -> List[AudioTrack]:
        raw = self._rc_cmd("atrack")
        tracks: List[AudioTrack] = []
        # VLC RC output: "+---[ Audio Track ]" then lines like "| 1 - English *"
        for line in raw.splitlines():
            m = re.match(r"\|\s*(-?\d+)\s*[-–]\s*(.+?)(\s*\*)?$", line.strip())
            if m:
                track_id = int(m.group(1))
                name = m.group(2).strip()
                if track_id >= 0:
                    tracks.append(AudioTrack(track_id=track_id, name=name))
        return tracks

    def set_audio_track(self, track_id: int) -> None:
        self._rc_cmd(f"atrack {track_id}")

    def get_audio_track(self) -> Optional[int]:
        raw = self._rc_cmd("atrack")
        # Active track is marked with " *" at the end of the line.
        for line in raw.splitlines():
            if "*" in line:
                m = re.match(r"\|\s*(-?\d+)", line.strip())
                if m:
                    return int(m.group(1))
        return None

    # ------------------------------------------------------------------
    # Subtitle tracks
    # ------------------------------------------------------------------

    def list_subtitle_tracks(self) -> List[SubtitleTrackInfo]:
        raw = self._rc_cmd("strack")
        tracks: List[SubtitleTrackInfo] = []
        for line in raw.splitlines():
            m = re.match(r"\|\s*(-?\d+)\s*[-–]\s*(.+?)(\s*\*)?$", line.strip())
            if m:
                track_id = int(m.group(1))
                name = m.group(2).strip()
                if track_id >= 0:
                    tracks.append(SubtitleTrackInfo(
                        track_id=track_id,
                        name=name,
                        is_external=("external" in name.lower() or "sub-file" in name.lower()),
                    ))
        return tracks

    def set_subtitle_track(self, track_id: int) -> None:
        self._rc_cmd(f"strack {track_id}")

    def get_subtitle_track(self) -> Optional[int]:
        raw = self._rc_cmd("strack")
        for line in raw.splitlines():
            if "*" in line:
                m = re.match(r"\|\s*(-?\d+)", line.strip())
                if m:
                    return int(m.group(1))
        return None

    def disable_subtitles(self) -> None:
        self._rc_cmd("strack -1")

    def set_subtitle_delay(self, delay_ms: int) -> None:
        self._subtitle_delay_ms = delay_ms
        # VLC RC uses microseconds for spu-delay.
        self._rc_cmd(f"spu-delay {delay_ms * 1000}")

    def get_subtitle_delay(self) -> int:
        return self._subtitle_delay_ms

    def load_external_subtitle(self, path: str) -> bool:
        """Load an external subtitle file into the running VLC instance."""
        # Normalise path (expand ~, resolve symlinks)
        resolved = str(Path(path).expanduser().resolve())
        response = self._rc_cmd(f"sub-file {resolved}")
        log.debug("vlc_rc_sub_file", path=resolved, response=response[:80])
        return True  # RC doesn't reliably report failure; assume success

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    # RC commands that are polled every second — skip info-logging to avoid noise
    _SILENT_CMDS = frozenset(("status", "get_time", "get_length", "volume", "atrack", "strack"))

    def _rc_cmd(self, command: str) -> str:
        """Send an RC command, returning the response or "" if no RC client.

        Control commands (play, pause, seek, sub-file …) are logged at INFO.
        Status polling commands are logged at DEBUG only to avoid noise.
        """
        if self._rc is None:
            return ""
        with self._lock:
            resp = self._rc.cmd(command)
        cmd_name = command.split()[0]
        if cmd_name in self._SILENT_CMDS:
            log.debug("vlc_rc", cmd=command, resp=resp[:80] if resp else "")
        else:
            log.info("vlc_rc_action", cmd=command, resp=resp[:120] if resp else "")
        return resp

    def _stop_process(self, stop_proxy: bool = True) -> None:
        """Terminate the running VLC subprocess and close the RC socket.

        Args:
            stop_proxy: When True (default) also abort the background download
                and delete the temp file.  Pass False when the proxy download
                should be kept alive (e.g., reusing a preload for a new play).
        """
        self._buffering_paused = False       # reset so next play starts clean
        self._last_known_position_ms = 0    # don't bleed previous item's position

        if self._rc is not None:
            try:
                self._rc.cmd("quit")
            except Exception:
                pass
            self._rc.close()
            self._rc = None

        if self._proc is not None:
            if self._proc.poll() is None:
                try:
                    self._proc.terminate()
                    self._proc.wait(timeout=3)
                except Exception:
                    try:
                        self._proc.kill()
                    except Exception:
                        pass
            self._proc = None

        if stop_proxy:
            # Abort the background download and delete the temp file.
            # The proxy HTTP server itself stays alive for the next play().
            self._proxy.stop()

    def _auto_play_after_buffer(self) -> None:
        """Wait for the initial download lead, send "play", then hand off to watchdog.

        Runs in a daemon thread after :meth:`play` when a proxy stream is used.
        VLC is launched --start-paused so the download thread runs uncontested.

        Waits until buffer_ahead ≥ _PROXY_HIGH_WATER_BYTES or the max-wait
        timeout expires, then un-pauses VLC and starts the buffer watchdog.
        """
        start_time = time.time()
        deadline = start_time + _PROXY_MAX_WAIT_S
        last_log = start_time

        while time.time() < deadline:
            if self._proc is None or self._proc.poll() is not None:
                return  # VLC exited before buffer was ready

            buf = self._proxy.buffer_ahead  # == bytes_downloaded at this point (max_served=0)
            now = time.time()

            # Progress log every 10 s so the user can see buffering activity
            if now - last_log >= 10.0:
                log.info(
                    "proxy_buffering",
                    downloaded_mb=f"{self._proxy.bytes_downloaded / 1024 / 1024:.1f}",
                    high_water_mb=f"{_PROXY_HIGH_WATER_BYTES / 1024 / 1024:.0f}",
                    elapsed_s=f"{now - start_time:.0f}",
                )
                last_log = now

            if buf >= _PROXY_HIGH_WATER_BYTES:
                break

            time.sleep(0.5)

        downloaded = self._proxy.bytes_downloaded
        log.info(
            "proxy_initial_buffer_ready",
            downloaded_mb=f"{downloaded / 1024 / 1024:.1f}",
            elapsed_s=f"{time.time() - start_time:.1f}",
        )
        self._rc_cmd("play")

        # Hand off to ongoing watchdog for the rest of playback
        self._buffer_watchdog()

    def _buffer_watchdog(self) -> None:
        """Ongoing pause/resume loop to prevent buffer underruns during playback.

        Runs synchronously (called from the autoplay daemon thread after the
        initial un-pause).  Monitors buffer_ahead every second:

        * buffer_ahead < LOW_WATER  → pause VLC internally, set _buffering_paused
          so the poll loop does NOT surface this to the service layer (and therefore
          does NOT trigger Trakt scrobble or frontend state changes).
        * buffer_ahead ≥ HIGH_WATER (while watchdog-paused) → resume VLC.

        Exits when the process ends or the download is complete.
        """
        watchdog_paused = False

        while True:
            if self._proc is None or self._proc.poll() is not None:
                self._buffering_paused = False
                break  # VLC exited

            if self._proxy.download_complete:
                # Entire file is on disk — no more underruns possible
                if watchdog_paused:
                    log.info(
                        "buffer_watchdog_resuming_final",
                        downloaded_mb=f"{self._proxy.bytes_downloaded / 1024 / 1024:.0f}",
                    )
                    self._buffering_paused = False
                    self._rc_cmd("play")
                log.info("buffer_watchdog_exiting_download_complete")
                break

            buf = self._proxy.buffer_ahead
            downloaded_mb = self._proxy.bytes_downloaded / (1024 * 1024)

            if not watchdog_paused and buf < _PROXY_LOW_WATER_BYTES:
                log.info(
                    "buffer_watchdog_pausing",
                    buffer_ahead_mb=f"{buf / 1024 / 1024:.1f}",
                    downloaded_mb=f"{downloaded_mb:.0f}",
                    low_water_mb=f"{_PROXY_LOW_WATER_BYTES / 1024 / 1024:.0f}",
                )
                # Set flag BEFORE sending RC pause so _poll_loop suppresses the
                # resulting "Paused" state change before service/scrobble sees it.
                self._buffering_paused = True
                self._rc_cmd("pause")
                watchdog_paused = True

            elif watchdog_paused and buf >= _PROXY_HIGH_WATER_BYTES:
                log.info(
                    "buffer_watchdog_resuming",
                    buffer_ahead_mb=f"{buf / 1024 / 1024:.1f}",
                    downloaded_mb=f"{downloaded_mb:.0f}",
                    high_water_mb=f"{_PROXY_HIGH_WATER_BYTES / 1024 / 1024:.0f}",
                )
                self._rc_cmd("play")
                # Clear flag AFTER sending RC play so the "Playing" state change
                # is also suppressed (no spurious "Playing" re-notification to service).
                self._buffering_paused = False
                watchdog_paused = False

            else:
                log.debug(
                    "buffer_watchdog_tick",
                    buffer_ahead_mb=f"{buf / 1024 / 1024:.1f}",
                    downloaded_mb=f"{downloaded_mb:.0f}",
                    watchdog_paused=watchdog_paused,
                )

            time.sleep(1.0)

    def _start_poll_thread(self) -> None:
        """Start a daemon thread that polls VLC state and fires the callback."""
        self._last_state = "unknown"
        t = threading.Thread(target=self._poll_loop, daemon=True, name="vlc-state-poll")
        self._poll_thread = t
        t.start()

    def _poll_loop(self) -> None:
        """Daemon loop: poll VLC state, fire callback on meaningful changes, clean up on end.

        Two special behaviours beyond simple state forwarding:

        1. **Proxy temp-file cleanup** — when VLC transitions to Stopped/Ended
           (either natural end-of-media or explicit stop command), call
           proxy.stop() to delete the temp file immediately rather than waiting
           for the next play() or close() call.

        2. **Buffering-pause suppression** — when the buffer watchdog has
           internally paused VLC (self._buffering_paused is True), the resulting
           Paused/Playing state changes are *not* forwarded to the service layer.
           This prevents Trakt scrobble calls and frontend state flickering during
           the watchdog's periodic rebuffering cycles.
        """
        while True:
            proc = self._proc
            if proc is None or proc.poll() is not None:
                # VLC process has exited unexpectedly or after quit command.
                if self._last_state not in ("Stopped", "Ended"):
                    log.info(
                        "vlc_process_exited",
                        pid=proc.pid if proc else None,
                        return_code=proc.poll() if proc else None,
                        last_state=self._last_state,
                    )
                    self._last_state = "Stopped"
                    self._buffering_paused = False
                    self._proxy.stop()   # delete temp file — process is gone
                    if self._state_callback:
                        try:
                            self._state_callback("Stopped")
                        except Exception:
                            pass
                break

            try:
                state = self.get_state()
            except Exception:
                state = self._last_state

            # Capture position on every Playing cycle so _last_known_position_ms
            # is always fresh.  This is the only position update that happens
            # independently of the frontend UI polling /player/status — critical
            # when the user is watching in the detached VLC window with no browser
            # page open, or between /player/status polls after a seek.
            if state == "Playing":
                try:
                    raw_time = self._rc_cmd("get_time")
                    pos = _parse_int(raw_time) * 1000
                    if pos > 0:
                        self._last_known_position_ms = pos
                except Exception:
                    pass

            if state != self._last_state:
                old_state = self._last_state
                self._last_state = state

                # ── Proxy cleanup on end ────────────────────────────────
                # Fire whether the stop is user-initiated or natural end-of-media.
                # proxy.stop() is idempotent so double-calling is harmless.
                if state in ("Stopped", "Ended") and old_state in ("Playing", "Paused"):
                    log.info(
                        "vlc_playback_ended",
                        new_state=state,
                        old_state=old_state,
                        pid=proc.pid if proc else None,
                    )
                    self._buffering_paused = False
                    self._proxy.stop()  # delete temp file now

                # ── Suppress buffering-internal transitions ─────────────
                # When the buffer watchdog is managing an internal pause cycle,
                # don't surface "Paused" or the subsequent "Playing" to the
                # service layer — they are not user-visible playback events.
                if self._buffering_paused and state in ("Paused", "Playing"):
                    log.debug(
                        "vlc_state_suppressed_buffering",
                        suppressed_state=state,
                        old_state=old_state,
                    )
                    # Fall through to time.sleep without calling _state_callback
                else:
                    log.info(
                        "vlc_state_change",
                        old_state=old_state,
                        new_state=state,
                    )
                    if self._state_callback:
                        try:
                            self._state_callback(state)
                        except Exception:
                            pass

            time.sleep(_STATE_POLL_INTERVAL_S)
