"""Response cache for the tracker facade.

Mirrors the TTLs the Continue Watching route has always used.  Keys are
namespaced by plugin id so switching the active tracker cannot serve the previous
one's rows — a stale Continue Watching list after switching services would look
exactly like the new tracker having imported your history, which is a confusing
lie to tell the user.

Per-upstream-call caching (individual playback/watched/progress calls) belongs
*inside* the plugin, behind ``context["cache"]``.  The host has no business
knowing that a given tracker needs three API calls to build one row.
"""

from __future__ import annotations

import threading
import time
from typing import Any, Dict, Optional, Tuple

from warp_mediacenter.backend.common.logging import get_logger

log = get_logger(__name__)

TTL_CONTINUE_WATCHING = 120.0
TTL_ITEM_PROGRESS = 300.0


class TrackerCache:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._entries: Dict[str, Tuple[float, Any]] = {}

    # -- keys -----------------------------------------------------------

    @staticmethod
    def cw_key(plugin_id: str, media_type: str, limit: int) -> str:
        return f"tracker:{plugin_id}:cw:{media_type}:{limit}"

    @staticmethod
    def progress_key(plugin_id: str, media_type: str, tmdb_id: str) -> str:
        return f"tracker:{plugin_id}:progress:{media_type}:{tmdb_id}"

    # -- access ---------------------------------------------------------

    def get(self, key: str, ttl: float) -> Optional[Any]:
        with self._lock:
            entry = self._entries.get(key)
        if entry is not None and (time.monotonic() - entry[0]) < ttl:
            return entry[1]
        return None

    def set(self, key: str, value: Any) -> None:
        with self._lock:
            self._entries[key] = (time.monotonic(), value)

    def drop_plugin(self, plugin_id: str) -> int:
        """Forget everything cached for one tracker."""

        prefix = f"tracker:{plugin_id}:"
        with self._lock:
            keys = [k for k in self._entries if k.startswith(prefix)]
            for key in keys:
                self._entries.pop(key, None)
        return len(keys)

    def drop_scope(self, plugin_id: str, scope: str) -> int:
        prefix = f"tracker:{plugin_id}:{scope}"
        with self._lock:
            keys = [k for k in self._entries if k.startswith(prefix)]
            for key in keys:
                self._entries.pop(key, None)
        return len(keys)

    def clear(self) -> None:
        with self._lock:
            self._entries.clear()

    def stats(self) -> Dict[str, Any]:
        with self._lock:
            return {"entries": len(self._entries)}


__all__ = ["TTL_CONTINUE_WATCHING", "TTL_ITEM_PROGRESS", "TrackerCache"]
