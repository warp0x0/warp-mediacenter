"""Structured logger handed to plugins.

Wraps the host logger so every line is attributable to a plugin, and rate-limits
output — a plugin logging inside a retry loop should not be able to fill the disk
or drown out the host's own diagnostics.
"""

from __future__ import annotations

import threading
import time
from typing import Any

from warp_mediacenter.backend.common.logging import get_logger

#: Per-level budget.  Generous enough for normal operation, tight enough that a
#: runaway loop is capped rather than unbounded.
_MAX_PER_WINDOW = 200
_WINDOW_SECONDS = 60.0


class PluginLogger:
    def __init__(self, plugin_id: str) -> None:
        self._plugin_id = plugin_id
        self._log = get_logger(f"plugin.{plugin_id}")
        self._lock = threading.Lock()
        self._window_start = time.monotonic()
        self._count = 0
        self._suppressed = 0

    def _allowed(self) -> bool:
        now = time.monotonic()
        with self._lock:
            if now - self._window_start >= _WINDOW_SECONDS:
                if self._suppressed:
                    self._log.warning(
                        "plugin_log_suppressed",
                        plugin_id=self._plugin_id,
                        suppressed=self._suppressed,
                    )
                self._window_start = now
                self._count = 0
                self._suppressed = 0
            if self._count >= _MAX_PER_WINDOW:
                self._suppressed += 1
                return False
            self._count += 1
            return True

    def _emit(self, level: str, event: str, **fields: Any) -> None:
        if not self._allowed():
            return
        getattr(self._log, level)(str(event), plugin_id=self._plugin_id, **fields)

    def debug(self, event: str, **fields: Any) -> None:
        self._emit("debug", event, **fields)

    def info(self, event: str, **fields: Any) -> None:
        self._emit("info", event, **fields)

    def warning(self, event: str, **fields: Any) -> None:
        self._emit("warning", event, **fields)

    def error(self, event: str, **fields: Any) -> None:
        self._emit("error", event, **fields)


__all__ = ["PluginLogger"]
