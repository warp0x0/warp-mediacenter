"""Session manager for buffered remote playback streams.

Creates short-lived preload sessions that download remote media into a local
temp file via :class:`StreamProxy` and expose a per-session local playback URL.
"""

from __future__ import annotations

import time
from dataclasses import dataclass
from datetime import datetime, timezone
from threading import Lock
from typing import Any, Dict, Optional
from uuid import uuid4

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.player.stream_proxy import StreamProxy

log = get_logger(__name__)


# ---------------------------------------------------------------------------
# Libtorrent-backed session shim
# ---------------------------------------------------------------------------

class _LibtorrentProxyShim:
    """Makes a libtorrent download duck-type compatible with StreamProxy
    so a libtorrent session can live in PreloadSessionManager._sessions."""

    def __init__(self, lt_manager: Any, lt_session_id: str) -> None:
        self._lt = lt_manager
        self._lt_sid = lt_session_id
        # Cache the loopback URL once set — it never changes after proxy starts
        self._cached_local_url: Optional[str] = None

    def snapshot(self) -> Dict[str, Any]:
        raw   = self._lt.status(self._lt_sid)
        pct   = raw.get("progress_pct", 0.0)
        total = raw.get("total_bytes", 0)
        # done = True only when the StreamProxy is serving the complete file
        done = bool(raw.get("local_url"))
        # percent is kept at 0.0 during download so the frontend's `pct >= 20`
        # threshold does NOT fire before the file is fully on disk.
        # download_complete=True is the sole trigger for onStreamReady.
        # bytes_downloaded still reflects real progress for the MB counter in the banner.
        return {
            "url":               "",
            "file_path":         raw.get("file_path") if done else None,
            "bytes_downloaded":  raw.get("bytes_downloaded", 0),
            "total_size":        total,
            "remaining_size":    total,
            "percent":           100.0 if done else pct,
            "active":            raw.get("state") in ("downloading", "waiting_metadata", "seeding"),
            "download_complete": done,
            "error":             raw.get("error"),
            "download_rate_kb":  raw.get("download_rate_kb", 0.0),
            "num_peers":         raw.get("num_peers", 0),
        }

    @property
    def local_url(self) -> Optional[str]:
        """Internal loopback URL used by the FastAPI stream endpoint to proxy bytes.
        Cached once set — never changes after the proxy starts."""
        if self._cached_local_url is None:
            self._cached_local_url = self._lt.status(self._lt_sid).get("local_url")
        return self._cached_local_url

    def close(self) -> None:
        self._lt.stop(self._lt_sid)


@dataclass
class _LibtorrentSession:
    """A PreloadSession-compatible wrapper around a libtorrent download."""
    session_id:     str
    proxy:          _LibtorrentProxyShim
    created_at:     datetime
    updated_at:     datetime
    title:          Optional[str] = None
    media_kind:     Optional[str] = None
    active_streams: int = 0

    def touch(self) -> None:
        self.updated_at = datetime.now(timezone.utc)

    def snapshot(self) -> Dict[str, Any]:
        snap  = self.proxy.snapshot()
        error = snap.get("error")
        state = (
            "error"      if error                    else
            "ready"      if snap["download_complete"] else
            "preloading" if snap["active"]            else
            "stopped"
        )
        return {
            "session_id":        self.session_id,
            "state":             state,
            "url":               snap.get("url", ""),
            "file_path":         snap.get("file_path"),
            "title":             self.title,
            "media_kind":        self.media_kind,
            "bytes_downloaded":  snap["bytes_downloaded"],
            "total_size":        snap["total_size"],
            "remaining_size":    snap["remaining_size"],
            "percent":           snap["percent"],
            "download_complete": snap["download_complete"],
            "error":             error,
            "active":            snap["active"],
            "local_torrent":     True,
            "download_rate_kb":  snap.get("download_rate_kb", 0.0),
            "num_peers":         snap.get("num_peers", 0),
            "buffer_ahead_bytes": 0,
            "active_streams":    self.active_streams,
            "created_at":        self.created_at.isoformat(),
            "updated_at":        self.updated_at.isoformat(),
        }


class PreloadSessionCapacityError(RuntimeError):
    """Raised when no capacity is available for a new preload session."""


@dataclass
class PreloadSession:
    session_id: str
    stream_url: str
    proxy: StreamProxy
    created_at: datetime
    updated_at: datetime
    title: Optional[str] = None
    media_kind: Optional[str] = None
    active_streams: int = 0

    def touch(self) -> None:
        self.updated_at = datetime.now(timezone.utc)

    def snapshot(self) -> Dict[str, Any]:
        payload = self.proxy.snapshot()
        error = payload.get("error")
        if error:
            state = "error"
        elif payload.get("download_complete"):
            state = "ready"
        elif payload.get("active"):
            state = "preloading"
        else:
            state = "stopped"

        payload.update(
            {
                "session_id": self.session_id,
                "state": state,
                "title": self.title,
                "media_kind": self.media_kind,
                "buffer_ahead_bytes": self.proxy.buffer_ahead,
                "active_streams": self.active_streams,
                "created_at": self.created_at.isoformat(),
                "updated_at": self.updated_at.isoformat(),
            }
        )
        return payload


class PreloadSessionManager:
    """Create, track, and cleanup preload sessions."""

    def __init__(
        self,
        *,
        ttl_seconds: int = 3600,
        hard_ttl_seconds: int = 8 * 3600,
        max_sessions: int = 12,
    ) -> None:
        self._ttl_seconds = max(60, ttl_seconds)
        self._hard_ttl_seconds = max(self._ttl_seconds, hard_ttl_seconds)
        self._max_sessions = max(1, max_sessions)
        self._sessions: Dict[str, Any] = {}  # PreloadSession | _LibtorrentSession
        self._lock = Lock()

    def create_session(
        self,
        stream_url: str,
        *,
        title: Optional[str] = None,
        media_kind: Optional[str] = None,
        start_percent: float = 0.0,
    ) -> PreloadSession:
        stream_url = stream_url.strip()
        if not stream_url:
            raise ValueError("stream_url required")

        self.cleanup_stale_sessions()
        self._ensure_capacity()
        session_id = uuid4().hex
        proxy = StreamProxy()
        try:
            proxy.start(stream_url, start_percent=max(0.0, min(99.9, start_percent)))
        except Exception:
            proxy.close()
            raise

        now = datetime.now(timezone.utc)
        session = PreloadSession(
            session_id=session_id,
            stream_url=stream_url,
            proxy=proxy,
            created_at=now,
            updated_at=now,
            title=title,
            media_kind=media_kind,
        )

        with self._lock:
            self._sessions[session_id] = session

        log.info(
            "preload_session_created",
            session_id=session_id,
            title=title,
            media_kind=media_kind,
            start_percent=start_percent if start_percent > 0 else None,
        )
        return session

    def create_libtorrent_session(
        self,
        magnet: str,
        *,
        title: Optional[str] = None,
        media_kind: Optional[str] = None,
        start_percent: float = 0.0,
        metadata_timeout: float = 60.0,
    ) -> _LibtorrentSession:
        """Start a libtorrent download and expose it as a preload session.

        Blocks only until torrent metadata arrives (file name and size are known).
        The actual download runs in the background; the proxy URL is populated once
        the file is 100% on disk.  The frontend polls the status endpoint and fires
        onStreamReady when download_complete becomes True.
        """
        from warp_mediacenter.backend.player.libtorrent_manager import get_manager as _lt_get  # noqa: PLC0415

        self.cleanup_stale_sessions()
        self._ensure_capacity()

        lt_manager    = _lt_get()
        lt_session_id = lt_manager.start(magnet=magnet, start_percent=start_percent)

        # Poll until metadata arrives (state transitions to "downloading").
        # This typically takes 5–30 s depending on tracker/peer availability.
        deadline = time.monotonic() + metadata_timeout
        while time.monotonic() < deadline:
            raw = lt_manager.status(lt_session_id)
            if raw.get("state") == "downloading":
                break
            if raw.get("state") == "error":
                lt_manager.stop(lt_session_id)
                raise RuntimeError(raw.get("error") or "libtorrent metadata error")
            time.sleep(0.25)
        else:
            lt_manager.stop(lt_session_id)
            raise TimeoutError("Timed out waiting for torrent metadata")

        now        = datetime.now(timezone.utc)
        session_id = uuid4().hex
        session    = _LibtorrentSession(
            session_id=session_id,
            proxy=_LibtorrentProxyShim(lt_manager, lt_session_id),
            created_at=now,
            updated_at=now,
            title=title,
            media_kind=media_kind,
        )
        with self._lock:
            self._sessions[session_id] = session

        log.info(
            "libtorrent_preload_session_created",
            session_id=session_id,
            lt_session_id=lt_session_id,
            title=title,
            start_percent=start_percent if start_percent > 0 else None,
        )
        return session

    def get_session(self, session_id: str) -> Optional[Any]:
        self.cleanup_stale_sessions()
        with self._lock:
            session = self._sessions.get(session_id)
            if session is not None:
                session.touch()
            return session

    def require_session(self, session_id: str) -> Any:
        session = self.get_session(session_id)
        if session is None:
            raise KeyError(session_id)
        return session

    def acquire_stream(self, session_id: str) -> Any:
        self.cleanup_stale_sessions()
        with self._lock:
            session = self._sessions.get(session_id)
            if session is None:
                raise KeyError(session_id)
            session.active_streams += 1
            session.touch()
            return session

    def release_stream(self, session_id: str) -> None:
        with self._lock:
            session = self._sessions.get(session_id)
            if session is None:
                return
            if session.active_streams > 0:
                session.active_streams -= 1
            session.touch()

    def get_status(self, session_id: str) -> Dict[str, Any]:
        session = self.require_session(session_id)
        return session.snapshot()

    def stop_session(self, session_id: str) -> bool:
        with self._lock:
            session = self._sessions.pop(session_id, None)

        if session is None:
            return False

        try:
            session.proxy.close()
        finally:
            log.info("preload_session_stopped", session_id=session_id)
        return True

    def cleanup_stale_sessions(self) -> int:
        now = datetime.now(timezone.utc)
        stale_sessions = []
        with self._lock:
            for session_id, session in self._sessions.items():
                age = (now - session.updated_at).total_seconds()
                snapshot = session.proxy.snapshot()
                if session.active_streams > 0:
                    continue
                if age > self._hard_ttl_seconds:
                    stale_sessions.append((session_id, session))
                    continue
                if snapshot.get("download_complete") and age > self._ttl_seconds:
                    stale_sessions.append((session_id, session))
                    continue
                if not snapshot.get("active") and age > self._ttl_seconds:
                    stale_sessions.append((session_id, session))

            for session_id, _ in stale_sessions:
                self._sessions.pop(session_id, None)

        for session_id, session in stale_sessions:
            try:
                session.proxy.close()
            except Exception:
                pass

        if stale_sessions:
            log.info("preload_sessions_cleaned", removed=len(stale_sessions))
        return len(stale_sessions)

    def _ensure_capacity(self) -> None:
        with self._lock:
            if len(self._sessions) < self._max_sessions:
                return

            removable = sorted(
                (s for s in self._sessions.values() if s.active_streams == 0),
                key=lambda s: s.updated_at,
            )
            to_remove = max(0, len(self._sessions) - self._max_sessions + 1)
            evicted = removable[:to_remove]
            for session in evicted:
                self._sessions.pop(session.session_id, None)

        for session in evicted:
            try:
                session.proxy.close()
            except Exception:
                pass

        with self._lock:
            if len(self._sessions) >= self._max_sessions:
                raise PreloadSessionCapacityError(
                    "No preload session capacity available; close existing sessions first"
                )

    def close(self) -> None:
        with self._lock:
            sessions = list(self._sessions.values())
            self._sessions.clear()

        for session in sessions:
            try:
                session.proxy.close()
            except Exception:
                pass
