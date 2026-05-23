"""File system watcher for automatic library rescanning.

Uses the `watchdog` library to detect file additions, modifications, and deletions
in library paths and triggers incremental scans automatically.
"""

from __future__ import annotations

import json
import threading
import time
from pathlib import Path
from typing import Callable, Dict, Optional, Sequence

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.library.scanner import ScanResult, scan_once

log = get_logger(__name__)

_VIDEO_EXTENSIONS = {".mp4", ".mkv", ".avi", ".mov", ".m4v", ".ts", ".m2ts", ".webm", ".mpg", ".mpeg"}


def _is_video_file(path: str) -> bool:
    return Path(path).suffix.lower() in _VIDEO_EXTENSIONS


class LibraryWatcher:
    """Watches library paths for file changes and triggers incremental scans.

    Uses debouncing to avoid scanning on every single file event when bulk
    operations (like copying a folder) are in progress.
    """

    def __init__(
        self,
        paths: Sequence[Path],
        *,
        debounce_sec: float = 5.0,
        on_scan_complete: Optional[Callable[[ScanResult], None]] = None,
    ) -> None:
        self._paths = [p.resolve() for p in paths]
        self._debounce_sec = debounce_sec
        self._on_scan_complete = on_scan_complete
        self._watcher: Optional[object] = None
        self._observer: Optional[object] = None
        self._lock = threading.Lock()
        self._pending = False
        self._running = False
        self._scan_thread: Optional[threading.Thread] = None

    @property
    def is_running(self) -> bool:
        return self._running

    def start(self) -> None:
        """Start watching library paths for changes."""
        if self._running:
            return

        try:
            from watchdog.observers import Observer
            from watchdog.events import FileSystemEventHandler

            class _Handler(FileSystemEventHandler):
                def __init__(self, watcher: LibraryWatcher) -> None:
                    self._watcher = watcher

                def on_created(self, event) -> None:  # noqa: ANN001
                    if event.is_directory or _is_video_file(event.src_path):
                        self._watcher._schedule_scan()

                def on_modified(self, event) -> None:  # noqa: ANN001
                    if event.is_directory or _is_video_file(event.src_path):
                        self._watcher._schedule_scan()

                def on_deleted(self, event) -> None:  # noqa: ANN001
                    if event.is_directory or _is_video_file(event.src_path):
                        self._watcher._schedule_scan()

                def on_moved(self, event) -> None:  # noqa: ANN001
                    if event.is_directory or _is_video_file(event.src_path) or _is_video_file(event.dest_path):
                        self._watcher._schedule_scan()

            self._observer = Observer()
            handler = _Handler(self)

            for path in self._paths:
                if path.exists():
                    self._observer.schedule(handler, str(path), recursive=True)
                    log.info("library_watcher_path_added", path=str(path))

            self._observer.start()
            self._running = True
            log.info("library_watcher_started", paths=[str(p) for p in self._paths])

        except ImportError:
            log.warning(
                "library_watcher_watchdog_missing",
                hint="Install watchdog: pip install watchdog",
            )

    def stop(self) -> None:
        """Stop watching library paths."""
        if not self._running:
            return

        self._running = False
        if self._observer:
            self._observer.stop()
            self._observer.join(timeout=10)
            self._observer = None

        log.info("library_watcher_stopped")

    def trigger_scan(self) -> ScanResult:
        """Manually trigger an incremental scan."""
        return scan_once(self._paths, incremental=True, parallel=True, cleanup_missing=True)

    def _schedule_scan(self) -> None:
        """Schedule a debounced scan."""
        with self._lock:
            if self._pending:
                return
            self._pending = True

        def _debounced_scan() -> None:
            time.sleep(self._debounce_sec)
            with self._lock:
                self._pending = False

            log.info("library_watcher_triggering_scan")
            result = scan_once(self._paths, incremental=True, parallel=True, cleanup_missing=True)
            log.info("library_watcher_scan_complete", **result.as_dict())

            if self._on_scan_complete:
                self._on_scan_complete(result)

        thread = threading.Thread(target=_debounced_scan, daemon=True)
        thread.start()

    def __enter__(self) -> "LibraryWatcher":
        self.start()
        return self

    def __exit__(self, *args) -> None:  # noqa: ANN001
        self.stop()


__all__ = ["LibraryWatcher"]
