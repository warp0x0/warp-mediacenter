"""Session manager for buffered remote playback streams.

Creates short-lived preload sessions that download remote media into a local
temp file via :class:`StreamProxy` and expose a per-session local playback URL.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from threading import Lock
from typing import Any, Dict, Optional
from uuid import uuid4

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.player.stream_proxy import StreamProxy

log = get_logger(__name__)


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
        self._sessions: Dict[str, PreloadSession] = {}
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

    def get_session(self, session_id: str) -> Optional[PreloadSession]:
        self.cleanup_stale_sessions()
        with self._lock:
            session = self._sessions.get(session_id)
            if session is not None:
                session.touch()
            return session

    def require_session(self, session_id: str) -> PreloadSession:
        session = self.get_session(session_id)
        if session is None:
            raise KeyError(session_id)
        return session

    def acquire_stream(self, session_id: str) -> PreloadSession:
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
