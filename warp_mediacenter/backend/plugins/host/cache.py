"""In-process, per-plugin cache.

Deliberately bounded.  A tracker building Continue Watching will cache upstream
responses on every request; without a cap, a plugin that keys its cache on
something unbounded (a timestamp, a search term) leaks until the process dies.
"""

from __future__ import annotations

import threading
import time
from collections import OrderedDict
from typing import Any, Dict, Optional, Tuple

DEFAULT_MAX_ENTRIES = 256


class PluginCache:
    """TTL cache with LRU eviction, scoped to one plugin."""

    def __init__(self, *, max_entries: int = DEFAULT_MAX_ENTRIES) -> None:
        self._max_entries = max(1, max_entries)
        self._lock = threading.RLock()
        self._entries: "OrderedDict[str, Tuple[float, Any]]" = OrderedDict()

    def get(self, key: str, ttl: float) -> Optional[Any]:
        """Return the cached value if it was stored less than ``ttl`` ago."""

        if ttl <= 0:
            return None
        now = time.time()
        with self._lock:
            entry = self._entries.get(key)
            if entry is None:
                return None
            stored_at, value = entry
            if now - stored_at > ttl:
                self._entries.pop(key, None)
                return None
            self._entries.move_to_end(key)
            return value

    def set(self, key: str, value: Any) -> None:
        with self._lock:
            self._entries[key] = (time.time(), value)
            self._entries.move_to_end(key)
            while len(self._entries) > self._max_entries:
                self._entries.popitem(last=False)

    def delete(self, key: str) -> None:
        with self._lock:
            self._entries.pop(key, None)

    def delete_prefix(self, prefix: str) -> int:
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
            return {"entries": len(self._entries), "max_entries": self._max_entries}


__all__ = ["DEFAULT_MAX_ENTRIES", "PluginCache"]
