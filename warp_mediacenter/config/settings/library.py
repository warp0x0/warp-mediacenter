from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, Mapping, MutableMapping, Optional

from dataclasses import dataclass

from .paths import get_library_index_path, get_user_settings_path

LibraryMediaKind = str


def normalize_media_kind(kind: LibraryMediaKind) -> str:
    value = (kind or "").strip().lower()
    if value in {"movie", "movies"}:
        return "movie"
    if value in {"show", "shows", "tv", "tv_show", "tv_shows"}:
        return "show"
    raise ValueError(f"Unsupported media kind '{kind}'")


def coerce_path(value: Optional[str]) -> Optional[str]:
    if not value:
        return None
    path = Path(value).expanduser()
    try:
        return str(path.resolve())
    except Exception:
        return str(path)


def ensure_parent(path: Path) -> None:
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
    except Exception:
        pass


def load_user_settings() -> Dict[str, Any]:
    user_path = get_user_settings_path()
    if not user_path.exists():
        return {}
    try:
        with user_path.open("r", encoding="utf-8") as fh:
            return json.load(fh)
    except Exception:
        return {}


def write_user_settings(payload: Mapping[str, Any]) -> None:
    user_path = get_user_settings_path()
    ensure_parent(user_path)
    with user_path.open("w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2, ensure_ascii=False, sort_keys=True)


def _default_library_index() -> Dict[str, Any]:
    return {"movies": {}, "shows": {}}


def _normalize_index_payload(data: Any) -> Dict[str, Any]:
    if not isinstance(data, MutableMapping):
        return _default_library_index()

    movies = data.get("movies") if isinstance(data.get("movies"), Mapping) else {}
    shows = data.get("shows") if isinstance(data.get("shows"), Mapping) else {}

    return {"movies": dict(movies), "shows": dict(shows)}


def load_library_index() -> Dict[str, Any]:
    index_path = get_library_index_path()
    if not index_path.exists():
        return _default_library_index()
    try:
        with index_path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
    except Exception:
        return _default_library_index()

    return _normalize_index_payload(data)


def save_library_index(index: Mapping[str, Any]) -> None:
    payload = {
        "movies": dict(index.get("movies") or {}),
        "shows": dict(index.get("shows") or {}),
    }
    index_path = get_library_index_path()
    ensure_parent(index_path)
    with index_path.open("w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2, ensure_ascii=False, sort_keys=True)


@dataclass
class LibraryPaths:
    movies: Optional[str] = None
    shows: Optional[str] = None

    def get(self, kind: LibraryMediaKind) -> Optional[str]:
        normalized = normalize_media_kind(kind)
        return self.movies if normalized == "movie" else self.shows

    def set(self, kind: LibraryMediaKind, path: Optional[str]) -> None:
        normalized = normalize_media_kind(kind)
        if normalized == "movie":
            self.movies = coerce_path(path)
        else:
            self.shows = coerce_path(path)

    def as_dict(self) -> Dict[str, Optional[str]]:
        return {
            "movie": self.movies,
            "show": self.shows,
        }


__all__ = [
    "LibraryMediaKind",
    "LibraryPaths",
    "coerce_path",
    "ensure_parent",
    "load_library_index",
    "load_user_settings",
    "normalize_media_kind",
    "save_library_index",
    "write_user_settings",
]
