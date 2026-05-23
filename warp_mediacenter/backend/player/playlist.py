"""In-memory playlist/queue management for media playback."""

from __future__ import annotations

import random
from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional, Sequence


@dataclass(slots=True)
class PlaylistItem:
    source: str
    title: str
    media_kind: str
    media_folder: Optional[Path] = None
    season: Optional[int] = None
    episode: Optional[int] = None
    year: Optional[int] = None
    language: str = "eng"


class Playlist:
    """In-memory playlist with shuffle and repeat support."""

    def __init__(self) -> None:
        self._items: List[PlaylistItem] = []
        self._original_order: List[PlaylistItem] = []
        self._current_index: int = -1
        self._shuffle_mode: bool = False
        self._repeat_mode: str = "none"
        self._lock = __import__("threading").Lock()

    @property
    def current_index(self) -> int:
        return self._current_index

    @property
    def repeat_mode(self) -> str:
        return self._repeat_mode

    @property
    def is_empty(self) -> bool:
        return len(self._items) == 0

    @property
    def length(self) -> int:
        return len(self._items)

    @property
    def current_item(self) -> Optional[PlaylistItem]:
        if 0 <= self._current_index < len(self._items):
            return self._items[self._current_index]
        return None

    def add(self, item: PlaylistItem) -> int:
        """Add an item to the playlist. Returns the new length."""
        with self._lock:
            self._items.append(item)
            self._original_order.append(item)
            if self._shuffle_mode:
                self._shuffle_items()
            return len(self._items)

    def add_many(self, items: Sequence[PlaylistItem]) -> int:
        """Add multiple items. Returns the new length."""
        with self._lock:
            self._items.extend(items)
            self._original_order.extend(items)
            if self._shuffle_mode:
                self._shuffle_items()
            return len(self._items)

    def remove(self, index: int) -> bool:
        """Remove an item by index. Returns True if removed."""
        with self._lock:
            if 0 <= index < len(self._items):
                self._items.pop(index)
                self._original_order.pop(index)
                if self._current_index >= len(self._items):
                    self._current_index = max(0, len(self._items) - 1)
                return True
            return False

    def clear(self) -> None:
        """Clear the playlist."""
        with self._lock:
            self._items.clear()
            self._original_order.clear()
            self._current_index = -1

    def next(self) -> Optional[PlaylistItem]:
        """Advance to the next item and return it."""
        with self._lock:
            if not self._items:
                return None

            if self._repeat_mode == "one":
                return self.current_item

            self._current_index += 1

            if self._current_index >= len(self._items):
                if self._repeat_mode == "all":
                    self._current_index = 0
                    return self._items[0]
                self._current_index = len(self._items) - 1
                return None

            return self._items[self._current_index]

    def previous(self) -> Optional[PlaylistItem]:
        """Go to the previous item and return it."""
        with self._lock:
            if not self._items:
                return None

            self._current_index -= 1
            if self._current_index < 0:
                if self._repeat_mode == "all":
                    self._current_index = len(self._items) - 1
                    return self._items[self._current_index]
                self._current_index = 0
                return self._items[0]

            return self._items[self._current_index]

    def shuffle(self) -> None:
        """Toggle shuffle mode."""
        with self._lock:
            self._shuffle_mode = not self._shuffle_mode
            if self._shuffle_mode:
                self._shuffle_items()
            else:
                current = self.current_item
                self._items = list(self._original_order)
                if current:
                    try:
                        self._current_index = self._items.index(current)
                    except ValueError:
                        self._current_index = -1

    def set_repeat(self, mode: str) -> None:
        """Set repeat mode: 'none', 'one', or 'all'."""
        mode = mode.lower()
        if mode not in ("none", "one", "all"):
            raise ValueError(f"Invalid repeat mode: {mode}. Must be 'none', 'one', or 'all'")
        self._repeat_mode = mode

    def items(self) -> List[PlaylistItem]:
        """Return a copy of the current playlist items."""
        with self._lock:
            return list(self._items)

    def _shuffle_items(self) -> None:
        current = self.current_item
        random.shuffle(self._items)
        if current:
            try:
                self._current_index = self._items.index(current)
            except ValueError:
                self._current_index = 0


__all__ = ["Playlist", "PlaylistItem"]
