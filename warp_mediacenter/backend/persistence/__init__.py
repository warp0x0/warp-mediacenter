"""SQLite-backed persistence helpers for Warp Media Center."""

from .sqlite import (
    connect,
    connection,
    get_setting,
    get_title_by_tmdb,
    get_widget,
    migrate,
    set_setting,
    set_widget,
    upsert_episode,
    upsert_title,
    update_title_artwork_paths,
)

__all__ = [
    "connect",
    "connection",
    "get_setting",
    "get_title_by_tmdb",
    "get_widget",
    "migrate",
    "set_setting",
    "set_widget",
    "upsert_episode",
    "upsert_title",
    "update_title_artwork_paths",
]
