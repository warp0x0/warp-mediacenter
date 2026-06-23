"""Local torrent download manager via libtorrent.

Downloads the complete file sequentially to a temp directory, then serves it
via StreamProxy once 100% is on disk.  mpv opens only after the full file is
available, so format constraints (non-faststart MP4, variable-bitrate MKV
seeking) are completely eliminated.
"""

from __future__ import annotations

import os
import shutil
import threading
import time
import uuid
from typing import Dict, Optional

from warp_mediacenter.backend.common.logging import get_logger

log = get_logger(__name__)

_TEMP_BASE    = "/tmp/warp-mediacenter/libtorrent"
_POLL_INTERVAL = 1.0   # seconds between libtorrent status polls


def _lazy_session():
    """Lazily import and create a libtorrent session."""
    try:
        import libtorrent as lt
    except ImportError as exc:
        raise RuntimeError(
            "libtorrent is not installed. Run: pip install libtorrent"
        ) from exc

    settings = {
        "alert_mask": lt.alert.category_t.all_categories,
        "enable_dht": True,
        "enable_lsd": True,
        "enable_natpmp": True,
        "enable_upnp": True,
        # Identify as qBittorrent so trackers/peers don't reject us.
        "user_agent": "qBittorrent/5.0.4",
        "peer_fingerprint": "-qB5004-",
    }
    ses = lt.session(settings)
    return ses, lt


class _Download:
    """State for a single libtorrent download."""

    __slots__ = (
        "session_id", "magnet", "start_percent",
        "save_path", "handle",
        "total_bytes", "file_path",
        "state", "error_msg",
        "_meta_applied",
        "_lock",
        "proxy",
    )

    def __init__(self, session_id: str, magnet: str, start_percent: float, save_path: str):
        self.session_id      = session_id
        self.magnet          = magnet
        self.start_percent   = start_percent
        self.save_path       = save_path
        self.handle          = None
        self.total_bytes     = 0
        self.file_path: Optional[str] = None
        self.state           = "waiting_metadata"
        self.error_msg: Optional[str] = None
        self._meta_applied   = False
        self._lock           = threading.Lock()
        self.proxy           = None   # StreamProxy, set when download is 100% complete


class LibtorrentDownloadManager:
    """Downloads torrents completely, then serves them via a static StreamProxy."""

    def __init__(self) -> None:
        self._downloads: Dict[str, _Download] = {}
        self._session = None
        self._lt = None
        self._session_lock = threading.Lock()
        self._monitor_thread: Optional[threading.Thread] = None
        self._running = False

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def start(self, magnet: str, start_percent: float = 0.0) -> str:
        """Begin downloading a torrent. Returns a session_id."""
        self._ensure_session()

        session_id = str(uuid.uuid4())
        save_path  = os.path.join(_TEMP_BASE, session_id)
        os.makedirs(save_path, exist_ok=True)

        dl = _Download(
            session_id=session_id,
            magnet=magnet,
            start_percent=max(0.0, min(100.0, start_percent)),
            save_path=save_path,
        )

        lt = self._lt
        params = lt.parse_magnet_uri(magnet)
        params.save_path = save_path
        # Sequential download gives more predictable disk I/O and is friendlier
        # to streaming peers; order doesn't affect playback since we wait for 100%.
        params.flags |= lt.torrent_flags.sequential_download

        handle = self._session.add_torrent(params)
        dl.handle = handle

        with self._session_lock:
            self._downloads[session_id] = dl

        log.info("libtorrent_start", session_id=session_id, start_percent=start_percent)
        return session_id

    def status(self, session_id: str) -> dict:
        """Return current download status for a session."""
        dl = self._downloads.get(session_id)
        if dl is None:
            return {"session_id": session_id, "state": "error", "error": "unknown session"}

        with dl._lock:
            return self._build_status(dl)

    def stop(self, session_id: str) -> None:
        """Pause the torrent, stop the StreamProxy, delete temp files."""
        dl = self._downloads.pop(session_id, None)
        if dl is None:
            return
        # Pause + remove libtorrent handle (may already be removed by _stop_and_serve)
        if dl.handle and self._session:
            try:
                if dl.handle.is_valid():
                    dl.handle.pause()
                    time.sleep(0.3)
                self._session.remove_torrent(dl.handle)
            except Exception:
                pass
        if dl.proxy:
            try:
                dl.proxy.close()
            except Exception:
                pass
        try:
            shutil.rmtree(dl.save_path, ignore_errors=True)
        except Exception:
            pass
        log.info("libtorrent_stop", session_id=session_id)

    def shutdown(self) -> None:
        """Stop the monitor thread and abort all downloads."""
        self._running = False
        if self._monitor_thread and self._monitor_thread.is_alive():
            self._monitor_thread.join(timeout=5)
        for sid in list(self._downloads.keys()):
            self.stop(sid)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _ensure_session(self) -> None:
        with self._session_lock:
            if self._session is None:
                self._session, self._lt = _lazy_session()
                self._running = True
                self._monitor_thread = threading.Thread(
                    target=self._monitor_loop, daemon=True, name="libtorrent-monitor"
                )
                self._monitor_thread.start()

    def _monitor_loop(self) -> None:
        while self._running:
            sessions = list(self._downloads.values())
            for dl in sessions:
                try:
                    self._update(dl)
                except Exception as exc:
                    log.warning("libtorrent_monitor_error", session_id=dl.session_id, error=str(exc))
            time.sleep(_POLL_INTERVAL)

    def _update(self, dl: _Download) -> None:
        h = dl.handle
        if h is None or not h.is_valid():
            return

        lt = self._lt
        s  = h.status()

        needs_serve = False

        with dl._lock:
            state_map = {
                lt.torrent_status.checking_files:       "downloading",
                lt.torrent_status.downloading_metadata: "waiting_metadata",
                lt.torrent_status.downloading:          "downloading",
                lt.torrent_status.finished:             "seeding",
                lt.torrent_status.seeding:              "seeding",
                lt.torrent_status.allocating:           "downloading",
                lt.torrent_status.checking_resume_data: "downloading",
            }
            dl.state = state_map.get(s.state, "waiting_metadata")

            if s.state == lt.torrent_status.downloading_metadata:
                return

            ti = h.torrent_file()
            if ti is None:
                return

            # One-time metadata setup
            if not dl._meta_applied:
                dl.total_bytes = ti.total_size()

                largest_size = 0
                largest_path = None
                fs = ti.files()
                for i in range(fs.num_files()):
                    fsize = fs.file_size(i)
                    if fsize > largest_size:
                        largest_size = fsize
                        largest_path = os.path.join(dl.save_path, fs.file_path(i))
                dl.file_path = largest_path
                dl._meta_applied = True

                log.info(
                    "libtorrent_metadata_ready",
                    session_id=dl.session_id,
                    file=dl.file_path,
                    total_mb=round(dl.total_bytes / 1024 / 1024, 1),
                    pieces=ti.num_pieces(),
                )

            # Trigger static serving once download is 100% complete
            if dl.state == "seeding" and dl.proxy is None:
                needs_serve = True

            log.info(
                "libtorrent_download_progress",
                session_id=dl.session_id,
                progress_pct=round(s.progress * 100, 1),
                mb_downloaded=round(s.total_done / 1024 / 1024, 1),
                mb_total=round(dl.total_bytes / 1024 / 1024, 1),
                download_rate_kb=round(s.download_rate / 1024, 1),
                num_peers=s.num_peers,
            )

        if needs_serve and dl.file_path and dl.total_bytes > 0:
            self._stop_and_serve(dl, h)

    def _stop_and_serve(self, dl: _Download, handle) -> None:
        """Remove the torrent from the libtorrent session (stop seeding),
        then start a static StreamProxy that serves the completed file."""
        # Gracefully stop seeding
        try:
            if handle.is_valid():
                handle.pause()
                time.sleep(0.3)   # let libtorrent flush in-flight writes
            self._session.remove_torrent(handle)
        except Exception as exc:
            log.warning("libtorrent_stop_seeding_error", session_id=dl.session_id, error=str(exc))

        # Serve the complete file via StreamProxy — same HTTP server used by the RD path
        from warp_mediacenter.backend.player.stream_proxy import StreamProxy

        total = dl.total_bytes
        proxy = StreamProxy()
        proxy.start_local(
            file_path=dl.file_path,
            total_size=total,
            get_written=lambda: total,   # file is fully on disk
            is_done=lambda: True,        # always complete
        )

        with dl._lock:
            dl.proxy = proxy

        log.info(
            "libtorrent_serving_started",
            session_id=dl.session_id,
            local_url=proxy.local_url,
            file=dl.file_path,
            total_mb=round(total / 1024 / 1024, 1),
        )

    def _build_status(self, dl: _Download) -> dict:
        """Build the public status dict. Must be called under dl._lock."""

        # Proxy is live → download is 100% done and file is being served
        if dl.proxy is not None:
            return {
                "session_id":       dl.session_id,
                "state":            "seeding",
                "progress_pct":     100.0,
                "bytes_downloaded": dl.total_bytes,
                "total_bytes":      dl.total_bytes,
                "file_path":        dl.file_path,
                "local_url":        dl.proxy.local_url,
                "download_complete": True,
                "ready":            True,
            }

        h = dl.handle
        if h is None or not h.is_valid():
            return {
                "session_id":       dl.session_id,
                "state":            "error",
                "progress_pct":     0.0,
                "bytes_downloaded": 0,
                "total_bytes":      0,
                "file_path":        None,
                "local_url":        None,
                "download_complete": False,
                "ready":            False,
            }

        try:
            s = h.status()
            return {
                "session_id":       dl.session_id,
                "state":            dl.state,
                "progress_pct":     round(s.progress * 100.0, 2),
                "bytes_downloaded": int(s.total_done),
                "total_bytes":      dl.total_bytes or 1,
                "file_path":        dl.file_path,
                "local_url":        None,
                "download_complete": False,
                "ready":            False,
            }
        except Exception as exc:
            return {
                "session_id":       dl.session_id,
                "state":            "error",
                "progress_pct":     0.0,
                "bytes_downloaded": 0,
                "total_bytes":      0,
                "file_path":        None,
                "local_url":        None,
                "download_complete": False,
                "ready":            False,
                "error":            str(exc),
            }


# Module-level singleton — wired up at FastAPI startup
_manager: Optional[LibtorrentDownloadManager] = None


def get_manager() -> LibtorrentDownloadManager:
    global _manager
    if _manager is None:
        _manager = LibtorrentDownloadManager()
    return _manager
