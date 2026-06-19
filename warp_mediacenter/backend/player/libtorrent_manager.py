"""Local torrent download manager via libtorrent.

Used for playing torrents that are blocked by Real-Debrid (e.g. WEB-DL, YTS, AMZN).
Downloads sequentially to a temp directory and reports readiness at ≥20% of relevant
portion, after which the local file path is handed to the media player.
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

_TEMP_BASE = "/tmp/warp-mediacenter/libtorrent"
_POLL_INTERVAL = 1.0   # seconds between libtorrent status polls
_READY_THRESHOLD = 0.20  # fraction of relevant bytes that must be present


def _lazy_session():
    """Lazily import and create a libtorrent session (import is deferred to avoid
    crashing the app if libtorrent is not installed)."""
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
        # Identify as qBittorrent so trackers and peers don't reject us.
        # An empty or unknown user-agent is refused by many private trackers
        # and some public ones; peer fingerprint is embedded in the peer ID.
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
        "_piece_size", "_first_piece", "_num_pieces",
        "_meta_applied", "_tail_pieces_start", "_head_pieces_end", "_resume_piece",
        "_lock",
        "proxy",
    )

    def __init__(self, session_id: str, magnet: str, start_percent: float, save_path: str):
        self.session_id      = session_id
        self.magnet          = magnet
        self.start_percent   = start_percent
        self.save_path       = save_path
        self.handle          = None          # lt.torrent_handle, set after add
        self.total_bytes     = 0
        self.file_path: Optional[str] = None
        self.state           = "waiting_metadata"
        self.error_msg: Optional[str] = None
        self._piece_size     = 0
        self._first_piece    = 0
        self._num_pieces     = 0
        self._meta_applied   = False
        self._tail_pieces_start = -1  # first tail piece index; -1 until metadata arrives
        self._head_pieces_end   = 0   # exclusive end of head pieces (0 = none needed)
        self._resume_piece      = 0   # true scrobble % piece (without pre-roll buffer)
        self._lock           = threading.Lock()
        self.proxy           = None          # StreamProxy loopback server, set after tail+head pieces ready


class LibtorrentDownloadManager:
    """Manages libtorrent sequential downloads for the local-playback path."""

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
        """Gracefully pause the torrent, stop the StreamProxy, then delete temp files."""
        dl = self._downloads.pop(session_id, None)
        if dl is None:
            return
        # Pause libtorrent so it flushes in-flight writes before we delete files
        if dl.handle and self._session:
            try:
                if dl.handle.is_valid():
                    dl.handle.pause()
                    time.sleep(0.3)
                self._session.remove_torrent(dl.handle)
            except Exception:
                pass
        # Stop the StreamProxy loopback server (same as RD path stopPreloadSession)
        if dl.proxy:
            try:
                dl.proxy.close()
            except Exception:
                pass
        # Remove the entire save directory (proxy.close() deleted the video file;
        # rmtree cleans up the remaining empty directory tree)
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
        """Background thread: polls libtorrent handles and updates _Download state."""
        while self._running:
            sessions = list(self._downloads.values())
            for dl in sessions:
                try:
                    self._update(dl)
                except Exception as exc:
                    log.warning("libtorrent_monitor_error", session_id=dl.session_id, error=str(exc))
            time.sleep(_POLL_INTERVAL)

    def _update(self, dl: _Download) -> None:
        """Update a single download's state from the libtorrent handle."""
        h = dl.handle
        if h is None or not h.is_valid():
            return

        lt = self._lt
        s  = h.status()

        needs_proxy = False  # flag: create StreamProxy after releasing the lock

        with dl._lock:
            # Map libtorrent state enum to our string states
            state_map = {
                lt.torrent_status.checking_files:         "downloading",
                lt.torrent_status.downloading_metadata:   "waiting_metadata",
                lt.torrent_status.downloading:            "downloading",
                lt.torrent_status.finished:               "seeding",
                lt.torrent_status.seeding:                "seeding",
                lt.torrent_status.allocating:             "downloading",
                lt.torrent_status.checking_resume_data:   "downloading",
            }
            dl.state = state_map.get(s.state, "waiting_metadata")

            if s.state == lt.torrent_status.downloading_metadata:
                return  # nothing more to do until metadata arrives

            ti = h.torrent_file()
            if ti is None:
                return

            # One-time setup once metadata is available
            if not dl._meta_applied:
                dl._num_pieces  = ti.num_pieces()
                dl._piece_size  = ti.piece_length()
                dl.total_bytes  = ti.total_size()

                # Find the largest file to use as the playback target
                largest_size = 0
                largest_path = None
                fs = ti.files()
                for i in range(fs.num_files()):
                    fsize = fs.file_size(i)
                    if fsize > largest_size:
                        largest_size = fsize
                        largest_path = os.path.join(dl.save_path, fs.file_path(i))
                dl.file_path = largest_path

                # Resume: start downloading 10% before the scrobble point to cover
                # the VBR duration%/byte% mismatch. mpv seeks to duration 57% which
                # can correspond to byte 47–57% in x265 VBR files; the buffer ensures
                # that entire range is sequentially downloaded before mpv opens.
                if dl.start_percent > 0:
                    _RESUME_BUFFER = 10.0
                    download_from = max(0.0, dl.start_percent - _RESUME_BUFFER)
                    first = int(download_from / 100.0 * dl._num_pieces)
                    dl._first_piece = max(0, first)
                    # True resume point (scrobble %) for progress reporting
                    dl._resume_piece = min(
                        int(dl.start_percent / 100.0 * dl._num_pieces),
                        dl._num_pieces - 1,
                    )
                    for p in range(dl._first_piece):
                        h.piece_priority(p, 0)

                # Prioritize and deadline the last N pieces so the moov atom
                # (end of non-faststart MP4) is downloaded ASAP out-of-order.
                # set_piece_deadline(p, 0) forces libtorrent to fetch the piece
                # immediately regardless of sequential mode; piece_priority(7)
                # keeps it at the front of the picker once peers have it.
                _TAIL_COUNT = 8
                tail_start = max(dl._first_piece, dl._num_pieces - _TAIL_COUNT)
                dl._tail_pieces_start = tail_start
                for p in range(tail_start, dl._num_pieces):
                    h.piece_priority(p, 7)
                    try:
                        h.set_piece_deadline(p, 0)
                    except Exception:
                        pass  # not available in all libtorrent builds

                # For resume downloads also deadline the first few pieces so the
                # file header (MKV EBML, faststart moov) arrives out-of-order.
                _HEAD_COUNT = 4
                if dl._first_piece > 0:
                    head_end = min(_HEAD_COUNT, dl._first_piece)
                    dl._head_pieces_end = head_end
                    for p in range(head_end):
                        h.piece_priority(p, 7)
                        try:
                            h.set_piece_deadline(p, 0)
                        except Exception:
                            pass
                # else: _head_pieces_end stays 0 — sequential from 0 covers the header

                dl._meta_applied = True
                log.info(
                    "libtorrent_metadata_ready",
                    session_id=dl.session_id,
                    file=dl.file_path,
                    total_mb=round(dl.total_bytes / 1024 / 1024, 1),
                    pieces=dl._num_pieces,
                    start_percent=dl.start_percent,
                    first_piece=dl._first_piece,
                    tail_pieces=f"{tail_start}-{dl._num_pieces - 1}",
                    head_pieces=f"0-{dl._head_pieces_end - 1}" if dl._head_pieces_end > 0 else "none",
                )

            # Start the proxy immediately after metadata is ready.
            # Tail/head pieces are requested via set_piece_deadline(0) above so
            # they arrive out-of-order ASAP; the is_byte_available callback in
            # StreamProxy handles mpv's initial moov-atom seek by blocking in
            # _wait_for() until those pieces land — no need to gate proxy start.
            if dl._meta_applied and dl.proxy is None:
                needs_proxy = True

            dl.total_bytes = ti.total_size() if dl.total_bytes == 0 else dl.total_bytes

            # Log every monitor iteration (~1 s) — mirrors stream_proxy download_progress cadence
            pct = round(s.progress * 100, 1)
            log.info(
                "libtorrent_download_progress",
                session_id=dl.session_id,
                progress_pct=pct,
                mb_downloaded=round(s.total_done / 1024 / 1024, 1),
                mb_total=round(dl.total_bytes / 1024 / 1024, 1),
                download_rate_kb=round(s.download_rate / 1024, 1),
                num_peers=s.num_peers,
            )

        # Start the StreamProxy loopback server outside the lock (it spawns threads).
        # This mirrors the RD path exactly: the same StreamProxy HTTP server serves
        # the in-progress file, just fed by libtorrent instead of a CDN download.
        if needs_proxy and dl.file_path and dl.total_bytes > 0:
            self._start_proxy(dl, h)

        # Re-assert tail/head deadlines every monitor tick. The initial deadline=0
        # expires immediately; libtorrent stops tracking expired deadlines. Re-issuing
        # each second keeps the pieces in the time-critical queue until they land.
        if dl._meta_applied and dl._tail_pieces_start >= 0 and dl.state == "downloading":
            try:
                pieces_tick = s.pieces
                if pieces_tick:
                    for p in range(dl._tail_pieces_start, dl._num_pieces):
                        if not pieces_tick[p]:
                            h.piece_priority(p, 7)
                            h.set_piece_deadline(p, 0)
                    if dl._head_pieces_end > 0:
                        for p in range(dl._head_pieces_end):
                            if not pieces_tick[p]:
                                h.piece_priority(p, 7)
                                h.set_piece_deadline(p, 0)
            except Exception:
                pass

    def _start_proxy(self, dl: _Download, handle) -> None:
        """Create a StreamProxy loopback server for this libtorrent download.

        Reuses the exact same StreamProxy used by the RD/CDN path — only the
        source of bytes differs (libtorrent pieces vs CDN download thread).
        """
        from warp_mediacenter.backend.player.stream_proxy import StreamProxy

        def _get_written(_h=handle, _dl=dl):
            try:
                if not _h.is_valid():
                    return 0
                if _dl._piece_size == 0 or not _dl._meta_applied:
                    return int(_h.status().total_done)
                s = _h.status()
                # Short-circuit: if total_done has reached the full file size,
                # ALL data is physically on disk. Return total_bytes immediately
                # so _stream_from never stalls. This covers checking_files and
                # seeding states where s.pieces[] shows False for pieces that
                # are currently being re-verified but ARE already written.
                if _dl.total_bytes > 0 and int(s.total_done) >= _dl.total_bytes:
                    return _dl.total_bytes
                # Return the CONTIGUOUS byte offset from piece 0, NOT total_done.
                # total_done includes out-of-order tail/head pieces, which leaves
                # zero-filled gaps in the pre-allocated file. If _written were set
                # to total_done, _stream_from would read those zeros and serve
                # them to mpv as valid data, causing "Corrupt file" errors.
                pieces = s.pieces
                if not pieces:
                    return int(s.total_done)
                piece_size = _dl._piece_size
                for p in range(_dl._num_pieces):
                    if not pieces[p]:
                        return p * piece_size
                return _dl.total_bytes
            except Exception:
                return 0

        def _is_done(_dl=dl):
            return _dl.state == "seeding"

        # Piece-availability callback: lets StreamProxy serve non-sequential
        # pieces (tail moov atom, head file-header) without waiting for the
        # sequential watermark (_written = total_done) to reach their position.
        def _is_byte_available(byte_offset, _h=handle, _dl=dl):
            try:
                if _dl._piece_size == 0 or not _dl._meta_applied:
                    return False
                piece_idx = byte_offset // _dl._piece_size
                # Clamp to valid range (last byte may map past last piece)
                if piece_idx >= _dl._num_pieces:
                    piece_idx = _dl._num_pieces - 1
                return bool(_h.status().pieces[piece_idx])
            except Exception:
                return False

        proxy = StreamProxy()
        proxy.start_local(
            file_path=dl.file_path,
            total_size=dl.total_bytes,
            get_written=_get_written,
            is_done=_is_done,
            is_byte_available=_is_byte_available,
        )
        with dl._lock:
            dl.proxy = proxy
        log.info("libtorrent_proxy_started", session_id=dl.session_id, local_url=proxy.local_url)

    def _build_status(self, dl: _Download) -> dict:
        """Build the public status dict from a _Download. Must be called under dl._lock."""
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
                "ready":            False,
            }

        try:
            lt = self._lt
            s  = h.status()
            bytes_downloaded = int(s.total_done)
            total_bytes      = dl.total_bytes or 1

            # pieces_snap fetched once, reused by both resume progress and MP4 gate.
            pieces_snap   = None
            _resume_n_dl  = 0
            _resume_n_rem = 0
            # Use _resume_piece (raw scrobble %) as the progress anchor, not
            # _first_piece (which includes the 10% pre-roll buffer) — otherwise
            # progress would over-report and the 20% threshold would fire early.
            resume_anchor = (
                dl._resume_piece
                if (dl.start_percent > 0 and dl._resume_piece > 0)
                else dl._first_piece
            )
            if dl.start_percent > 0 and dl._meta_applied and resume_anchor > 0 and dl._num_pieces > 0:
                try:
                    pieces_snap   = s.pieces
                    _resume_n_rem = dl._num_pieces - resume_anchor
                    _resume_n_dl  = sum(
                        1 for p in range(resume_anchor, dl._num_pieces) if pieces_snap[p]
                    )
                    progress_pct  = (_resume_n_dl / _resume_n_rem * 100) if _resume_n_rem > 0 else 0.0
                except (IndexError, TypeError, AttributeError):
                    progress_pct = s.progress * 100.0
            else:
                progress_pct = s.progress * 100.0

            # Non-faststart MP4: keep progress_pct at 0% until tail pieces (moov atom)
            # are confirmed on disk. Without this gate, mpv opens at 20% and then hangs
            # for minutes seeking to the moov atom — which the sequential download hasn't
            # reached yet. Once tail pieces land (via deadline or sequential), the gate
            # lifts and onStreamReady fires normally.
            if (dl._meta_applied and dl._tail_pieces_start >= 0 and dl.file_path
                    and dl.state != "seeding"):
                ext = os.path.splitext(dl.file_path)[1].lower()
                if ext in ('.mp4', '.m4v', '.mov'):
                    # Short-circuit: total_done >= total_bytes means all data is on disk
                    # (checking_files phase where s.pieces[] can spuriously show False)
                    tail_ok = dl.total_bytes > 0 and int(s.total_done) >= dl.total_bytes
                    if not tail_ok:
                        try:
                            if pieces_snap is None:
                                pieces_snap = s.pieces
                            tail_ok = (not pieces_snap) or all(
                                pieces_snap[p]
                                for p in range(dl._tail_pieces_start, dl._num_pieces)
                            )
                        except Exception:
                            tail_ok = True
                    if not tail_ok:
                        progress_pct = 0.0

            # Determine "ready" — kept for compatibility; the unified path uses percent
            ready = False
            if dl._meta_applied and dl.file_path:
                if dl.start_percent > 0 and _resume_n_rem > 0:
                    ready = (_resume_n_dl / _resume_n_rem) >= _READY_THRESHOLD
                else:
                    ready = progress_pct >= (_READY_THRESHOLD * 100)

            return {
                "session_id":       dl.session_id,
                "state":            dl.state,
                "progress_pct":     round(progress_pct, 2),
                "bytes_downloaded": bytes_downloaded,
                "total_bytes":      total_bytes,
                "file_path":        dl.file_path,
                "local_url":        dl.proxy.local_url if dl.proxy else None,
                "ready":            ready,
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
