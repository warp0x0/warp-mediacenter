"""SQLite connection helpers and minimal persistence primitives."""

from __future__ import annotations

import json
import sqlite3
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Iterator, MutableMapping, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.config.settings import get_database_path

log = get_logger(__name__)


def _resolve_path(path: Optional[Path]) -> Path:
    db_path = Path(path or get_database_path())
    db_path.parent.mkdir(parents=True, exist_ok=True)
    return db_path


def connect(path: Optional[Path] = None, *, apply_migrations: bool = True) -> sqlite3.Connection:
    """Create a SQLite connection and ensure the schema exists."""

    db_path = _resolve_path(path)
    connection = sqlite3.connect(
        str(db_path),
        detect_types=sqlite3.PARSE_DECLTYPES | sqlite3.PARSE_COLNAMES,
    )
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    connection.execute("PRAGMA journal_mode = WAL")
    if apply_migrations:
        migrate(connection)
    return connection


@contextmanager
def connection(path: Optional[Path] = None) -> Iterator[sqlite3.Connection]:
    conn = connect(path)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def migrate(connection: sqlite3.Connection) -> None:
    """Create required tables if they are missing."""

    connection.executescript(
        """
        CREATE TABLE IF NOT EXISTS titles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tmdb_id TEXT UNIQUE,
            type TEXT NOT NULL,
            title TEXT NOT NULL,
            year INTEGER,
            overview TEXT,
            poster_url TEXT,
            backdrop_url TEXT,
            poster_path TEXT,
            backdrop_path TEXT,
            added_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS episodes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tmdb_id TEXT,
            title_id INTEGER NOT NULL REFERENCES titles(id) ON DELETE CASCADE,
            season INTEGER NOT NULL,
            episode INTEGER NOT NULL,
            name TEXT,
            air_date TEXT,
            added_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now')),
            UNIQUE(title_id, season, episode)
        );

        CREATE TABLE IF NOT EXISTS sources (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title_id INTEGER NOT NULL REFERENCES titles(id) ON DELETE CASCADE,
            url TEXT NOT NULL,
            quality TEXT,
            size_bytes INTEGER,
            scraper TEXT,
            last_checked TEXT
        );

        CREATE TABLE IF NOT EXISTS play_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title_id INTEGER NOT NULL REFERENCES titles(id) ON DELETE CASCADE,
            position INTEGER,
            duration INTEGER,
            last_played TEXT NOT NULL,
            device TEXT
        );

        CREATE TABLE IF NOT EXISTS settings (
            k TEXT PRIMARY KEY,
            v TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS catalog_widgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            widget_key TEXT UNIQUE,
            payload_json TEXT NOT NULL,
            last_updated TEXT NOT NULL,
            ttl_seconds INTEGER NOT NULL
        );
        """
    )


def upsert_title(
    connection: sqlite3.Connection,
    *,
    tmdb_id: Optional[str],
    type: str,
    title: str,
    year: Optional[int],
    overview: Optional[str],
    poster_url: Optional[str],
    backdrop_url: Optional[str],
) -> int:
    """Insert or update a movie/show record and return its primary key."""

    now = _utcnow()
    cursor = connection.execute(
        """
        INSERT INTO titles (tmdb_id, type, title, year, overview, poster_url, backdrop_url, added_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(tmdb_id) DO UPDATE SET
            type=excluded.type,
            title=excluded.title,
            year=excluded.year,
            overview=excluded.overview,
            poster_url=excluded.poster_url,
            backdrop_url=excluded.backdrop_url,
            updated_at=excluded.updated_at
        """,
        (
            tmdb_id,
            type,
            title,
            year,
            overview,
            poster_url,
            backdrop_url,
            now,
            now,
        ),
    )

    if tmdb_id:
        row = connection.execute("SELECT id FROM titles WHERE tmdb_id = ?", (tmdb_id,)).fetchone()
    else:
        row = connection.execute("SELECT id FROM titles WHERE id = ?", (cursor.lastrowid,)).fetchone()

    if row is None:
        raise RuntimeError("Failed to resolve title row after upsert")

    return int(row["id"])


def update_title_artwork_paths(
    connection: sqlite3.Connection,
    title_id: int,
    *,
    poster_path: Optional[str],
    backdrop_path: Optional[str],
) -> None:
    """Persist local filesystem paths for previously stored artwork."""

    connection.execute(
        """
        UPDATE titles
        SET poster_path = ?,
            backdrop_path = ?,
            updated_at = ?
        WHERE id = ?
        """,
        (
            poster_path,
            backdrop_path,
            _utcnow(),
            title_id,
        ),
    )


def upsert_episode(
    connection: sqlite3.Connection,
    *,
    tmdb_id: Optional[str],
    title_id: int,
    season: int,
    episode: int,
    name: Optional[str],
    air_date: Optional[str],
) -> int:
    """Insert or update an episode record and return its primary key."""

    now = _utcnow()
    connection.execute(
        """
        INSERT INTO episodes (tmdb_id, title_id, season, episode, name, air_date, added_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(title_id, season, episode) DO UPDATE SET
            tmdb_id=excluded.tmdb_id,
            name=excluded.name,
            air_date=excluded.air_date,
            updated_at=excluded.updated_at
        """,
        (
            tmdb_id,
            title_id,
            season,
            episode,
            name,
            air_date,
            now,
            now,
        ),
    )
    row = connection.execute(
        "SELECT id FROM episodes WHERE title_id = ? AND season = ? AND episode = ?",
        (title_id, season, episode),
    ).fetchone()
    if row is None:
        raise RuntimeError("Failed to resolve episode row after upsert")
    return int(row["id"])


def get_title_by_tmdb(connection: sqlite3.Connection, tmdb_id: str) -> Optional[sqlite3.Row]:
    """Return a title row for the given TMDb identifier."""

    return connection.execute("SELECT * FROM titles WHERE tmdb_id = ?", (tmdb_id,)).fetchone()


def get_setting(connection: sqlite3.Connection, key: str) -> Optional[str]:
    row = connection.execute("SELECT v FROM settings WHERE k = ?", (key,)).fetchone()
    return None if row is None else str(row["v"])


def set_setting(connection: sqlite3.Connection, key: str, value: str) -> None:
    connection.execute(
        """
        INSERT INTO settings(k, v) VALUES (?, ?)
        ON CONFLICT(k) DO UPDATE SET v = excluded.v
        """,
        (key, value),
    )


def get_widget(connection: sqlite3.Connection, key: str) -> Optional[MutableMapping[str, Any]]:
    """Return a cached widget payload if it is still valid."""

    row = connection.execute(
        "SELECT payload_json, last_updated, ttl_seconds FROM catalog_widgets WHERE widget_key = ?",
        (key,),
    ).fetchone()
    if row is None:
        return None

    payload_raw = row["payload_json"]
    try:
        payload = json.loads(payload_raw)
    except json.JSONDecodeError:
        log.warning("widget_payload_invalid_json", widget_key=key)
        return None

    last_updated_str = str(row["last_updated"])
    ttl_seconds = int(row["ttl_seconds"])
    try:
        last_updated = datetime.fromisoformat(last_updated_str)
    except ValueError:
        log.warning("widget_payload_invalid_timestamp", widget_key=key, value=last_updated_str)
        return None

    now = datetime.now(last_updated.tzinfo) if last_updated.tzinfo else datetime.now()
    if ttl_seconds > 0 and last_updated + timedelta(seconds=ttl_seconds) <= now:
        return None
    if last_updated.date() != now.date():
        return None

    return {
        "payload": payload,
        "last_updated": last_updated,
        "ttl_seconds": ttl_seconds,
    }


def set_widget(
    connection: sqlite3.Connection,
    key: str,
    payload: Any,
    ttl_seconds: int,
) -> None:
    """Persist a widget payload in the catalog cache."""

    if isinstance(payload, str):
        payload_json = payload
    else:
        payload_json = json.dumps(payload, ensure_ascii=False)

    now = datetime.now().astimezone()
    connection.execute(
        """
        INSERT INTO catalog_widgets(widget_key, payload_json, last_updated, ttl_seconds)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(widget_key) DO UPDATE SET
            payload_json=excluded.payload_json,
            last_updated=excluded.last_updated,
            ttl_seconds=excluded.ttl_seconds
        """,
        (
            key,
            payload_json,
            now.isoformat(timespec="seconds"),
            int(ttl_seconds),
        ),
    )


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


__all__ = [
    "connect",
    "connection",
    "migrate",
    "upsert_title",
    "update_title_artwork_paths",
    "upsert_episode",
    "get_title_by_tmdb",
    "get_setting",
    "set_setting",
    "get_widget",
    "set_widget",
]
