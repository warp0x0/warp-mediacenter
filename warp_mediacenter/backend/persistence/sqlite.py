"""SQLite connection helpers and persistence primitives."""

from __future__ import annotations

import json
import sqlite3
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Dict, Iterator, List, MutableMapping, Optional, Sequence

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.config.settings import get_database_path

log = get_logger(__name__)

_SCHEMA_VERSION = 6


def _resolve_path(path: Optional[Path]) -> Path:
    db_path = Path(path or get_database_path())
    db_path.parent.mkdir(parents=True, exist_ok=True)
    return db_path


def connect(path: Optional[Path] = None, *, apply_migrations: bool = True) -> sqlite3.Connection:
    """Create a SQLite connection and ensure the schema is up to date."""

    db_path = _resolve_path(path)
    conn = sqlite3.connect(
        str(db_path),
        detect_types=sqlite3.PARSE_DECLTYPES | sqlite3.PARSE_COLNAMES,
    )
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA journal_mode = WAL")
    conn.execute("PRAGMA busy_timeout = 30000")  # 30 s — tolerate parallel scanner writes
    if apply_migrations:
        migrate(conn)
    return conn


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
    """Apply incremental schema migrations to reach the current version."""

    connection.execute(
        "CREATE TABLE IF NOT EXISTS schema_version (version INTEGER PRIMARY KEY)"
    )
    row = connection.execute("SELECT MAX(version) FROM schema_version").fetchone()
    current = row[0] if row and row[0] is not None else 0

    if current >= _SCHEMA_VERSION:
        return

    log.info("db_migration_start", current_version=current, target_version=_SCHEMA_VERSION)

    if current < 1:
        _apply_v1(connection)
    if current < 2:
        _apply_v2(connection)
    if current < 3:
        _apply_v3(connection)
    if current < 4:
        _apply_v4(connection)
    if current < 5:
        _apply_v5(connection)
    if current < 6:
        _apply_v6(connection)

    connection.execute(
        "INSERT OR REPLACE INTO schema_version (version) VALUES (?)",
        (_SCHEMA_VERSION,),
    )
    connection.commit()
    log.info("db_migration_complete", version=_SCHEMA_VERSION)


def _apply_v1(connection: sqlite3.Connection) -> None:
    """Initial schema — all core tables."""

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

        CREATE INDEX IF NOT EXISTS idx_titles_type ON titles(type);
        CREATE INDEX IF NOT EXISTS idx_titles_title ON titles(title);
        CREATE INDEX IF NOT EXISTS idx_titles_added_at ON titles(added_at DESC);
        CREATE INDEX IF NOT EXISTS idx_sources_title_id ON sources(title_id);
        CREATE INDEX IF NOT EXISTS idx_play_history_title_id ON play_history(title_id);
        CREATE INDEX IF NOT EXISTS idx_play_history_last_played ON play_history(last_played DESC);
        """
    )


def _apply_v2(connection: sqlite3.Connection) -> None:
    """Add source_type and file_path columns to sources table."""

    connection.execute(
        "ALTER TABLE sources ADD COLUMN source_type TEXT NOT NULL DEFAULT 'local'"
    )
    connection.execute(
        "ALTER TABLE sources ADD COLUMN file_path TEXT"
    )
    connection.execute(
        "CREATE INDEX IF NOT EXISTS idx_sources_source_type ON sources(source_type)"
    )


def _apply_v3(connection: sqlite3.Connection) -> None:
    """Add file metadata columns for incremental scanning, status tracking,
    and library_sections table for named scan path groups."""

    connection.execute(
        "ALTER TABLE sources ADD COLUMN file_size INTEGER"
    )
    connection.execute(
        "ALTER TABLE sources ADD COLUMN file_mtime TEXT"
    )
    connection.execute(
        "ALTER TABLE sources ADD COLUMN file_hash TEXT"
    )
    connection.execute(
        "ALTER TABLE sources ADD COLUMN status TEXT NOT NULL DEFAULT 'available'"
    )
    connection.execute(
        "CREATE INDEX IF NOT EXISTS idx_sources_status ON sources(status)"
    )
    connection.execute(
        "CREATE INDEX IF NOT EXISTS idx_sources_file_hash ON sources(file_hash)"
    )

    connection.executescript(
        """
        CREATE TABLE IF NOT EXISTS library_sections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            kind TEXT NOT NULL,
            paths_json TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        );

        CREATE INDEX IF NOT EXISTS idx_sections_kind ON library_sections(kind);
        """
    )


def _apply_v4(connection: sqlite3.Connection) -> None:
    """Add torrent_cache and debrid_magnet_map tables for caching."""

    connection.executescript(
        """
        CREATE TABLE IF NOT EXISTS torrent_cache (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT NOT NULL,
            media_type TEXT NOT NULL,
            results_json TEXT NOT NULL,
            cached_at TEXT NOT NULL,
            ttl_seconds INTEGER NOT NULL DEFAULT 3600
        );

        CREATE INDEX IF NOT EXISTS idx_torrent_cache_query ON torrent_cache(query, media_type);
        CREATE INDEX IF NOT EXISTS idx_torrent_cache_cached_at ON torrent_cache(cached_at);

        CREATE TABLE IF NOT EXISTS debrid_magnet_map (
            magnet_hash TEXT PRIMARY KEY,
            torrent_id TEXT NOT NULL,
            created_at TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_debrid_magnet_created ON debrid_magnet_map(created_at);
        """
    )


def _apply_v5(connection: sqlite3.Connection) -> None:
    """User collections (liked and wishlist) table."""

    connection.executescript(
        """
        CREATE TABLE IF NOT EXISTS user_collections (
            id               INTEGER PRIMARY KEY AUTOINCREMENT,
            collection_type  TEXT NOT NULL,
            tmdb_id          TEXT NOT NULL,
            type             TEXT NOT NULL,
            title            TEXT NOT NULL,
            year             INTEGER,
            overview         TEXT,
            poster_path      TEXT,
            backdrop_path    TEXT,
            rating           REAL,
            vote_count       INTEGER,
            genres_json      TEXT,
            added_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now')),
            UNIQUE(collection_type, tmdb_id)
        );

        CREATE INDEX IF NOT EXISTS idx_user_collections_type
            ON user_collections(collection_type, type);
        CREATE INDEX IF NOT EXISTS idx_user_collections_added_at
            ON user_collections(collection_type, added_at DESC);
        """
    )


def _apply_v6(connection: sqlite3.Connection) -> None:
    """Fix source_type data corrupted by the v2 migration default.

    When v2 added the source_type column it used DEFAULT 'local', so every
    pre-existing row (debrid links, remote URLs, etc.) was silently tagged
    as 'local'.  Real local sources always have file_path set; anything
    without a file_path is a remote/debrid/URL source and must be corrected.
    """
    # Remote/debrid sources that have a URL but no local file path
    connection.execute(
        """
        UPDATE sources
        SET source_type = 'remote'
        WHERE source_type = 'local'
          AND file_path IS NULL
          AND url IS NOT NULL AND url != ''
        """
    )
    # Orphaned rows with neither a file path nor a URL — no useful content
    connection.execute(
        """
        DELETE FROM sources
        WHERE source_type = 'local'
          AND file_path IS NULL
          AND (url IS NULL OR url = '')
        """
    )


# ------------------------------------------------------------------
# Title operations
# ------------------------------------------------------------------

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


def get_title_by_tmdb(connection: sqlite3.Connection, tmdb_id: str) -> Optional[sqlite3.Row]:
    """Return a title row for the given TMDb identifier."""
    return connection.execute("SELECT * FROM titles WHERE tmdb_id = ?", (tmdb_id,)).fetchone()


def get_title_by_id(connection: sqlite3.Connection, title_id: int) -> Optional[sqlite3.Row]:
    """Return a title row by its primary key."""
    return connection.execute("SELECT * FROM titles WHERE id = ?", (title_id,)).fetchone()


def list_titles(
    connection: sqlite3.Connection,
    *,
    type: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
) -> Sequence[sqlite3.Row]:
    """List titles with optional type filter, pagination, ordered by added_at DESC."""
    if type:
        return connection.execute(
            "SELECT * FROM titles WHERE type = ? ORDER BY added_at DESC LIMIT ? OFFSET ?",
            (type, limit, offset),
        ).fetchall()
    return connection.execute(
        "SELECT * FROM titles ORDER BY added_at DESC LIMIT ? OFFSET ?",
        (limit, offset),
    ).fetchall()


def search_titles(
    connection: sqlite3.Connection,
    query: str,
    *,
    limit: int = 20,
) -> Sequence[sqlite3.Row]:
    """Search titles by name using LIKE matching."""
    pattern = f"%{query}%"
    return connection.execute(
        "SELECT * FROM titles WHERE title LIKE ? ORDER BY added_at DESC LIMIT ?",
        (pattern, limit),
    ).fetchall()


def get_recently_added(
    connection: sqlite3.Connection,
    *,
    limit: int = 20,
) -> Sequence[sqlite3.Row]:
    """Return the most recently added titles."""
    return connection.execute(
        "SELECT * FROM titles ORDER BY added_at DESC LIMIT ?",
        (limit,),
    ).fetchall()


# ------------------------------------------------------------------
# Episode operations
# ------------------------------------------------------------------

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


def get_episodes_for_title(
    connection: sqlite3.Connection,
    title_id: int,
    *,
    season: Optional[int] = None,
) -> Sequence[sqlite3.Row]:
    """Return all episodes for a title, optionally filtered by season."""
    if season is not None:
        return connection.execute(
            "SELECT * FROM episodes WHERE title_id = ? AND season = ? ORDER BY season, episode",
            (title_id, season),
        ).fetchall()
    return connection.execute(
        "SELECT * FROM episodes WHERE title_id = ? ORDER BY season, episode",
        (title_id,),
    ).fetchall()


# ------------------------------------------------------------------
# Source operations
# ------------------------------------------------------------------

def upsert_source(
    connection: sqlite3.Connection,
    *,
    title_id: int,
    url: str = "",
    file_path: Optional[str] = None,
    source_type: str = "local",
    quality: Optional[str] = None,
    size_bytes: Optional[int] = None,
    scraper: Optional[str] = None,
    file_size: Optional[int] = None,
    file_mtime: Optional[str] = None,
    file_hash: Optional[str] = None,
    status: str = "available",
) -> int:
    """Insert or update a source record linking a title to a local file or remote URL.

    source_type: 'local', 'remote', 'torrent', 'debrid', 'plugin'
    file_path: local filesystem path (used when source_type='local')
    url: remote URL, magnet link, or debrid stream URL (used for non-local sources)
    file_size: file size in bytes (for change detection)
    file_mtime: last modification time ISO string (for change detection)
    file_hash: SHA-256 hash of first 1MB (for duplicate detection)
    status: 'available', 'missing', 'duplicate'
    """

    now = _utcnow()
    cursor = connection.execute(
        """
        INSERT INTO sources (title_id, url, file_path, source_type, quality, size_bytes, scraper, last_checked, file_size, file_mtime, file_hash, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT DO NOTHING
        """,
        (title_id, url, file_path, source_type, quality, size_bytes, scraper, now, file_size, file_mtime, file_hash, status),
    )

    if cursor.lastrowid:
        return int(cursor.lastrowid)

    row = connection.execute(
        "SELECT id FROM sources WHERE title_id = ? AND COALESCE(file_path, url) = COALESCE(?, ?)",
        (title_id, file_path, url),
    ).fetchone()
    if row is None:
        row = connection.execute(
            "SELECT id FROM sources WHERE title_id = ? ORDER BY id DESC LIMIT 1",
            (title_id,),
        ).fetchone()

    if row is None:
        raise RuntimeError("Failed to resolve source row after upsert")
    return int(row["id"])


def get_sources_for_title(
    connection: sqlite3.Connection,
    title_id: int,
    *,
    source_type: Optional[str] = None,
) -> Sequence[sqlite3.Row]:
    """Return all sources for a title, optionally filtered by source_type."""
    if source_type:
        return connection.execute(
            "SELECT * FROM sources WHERE title_id = ? AND source_type = ?",
            (title_id, source_type),
        ).fetchall()
    return connection.execute(
        "SELECT * FROM sources WHERE title_id = ?",
        (title_id,),
    ).fetchall()


def get_local_file_for_title(
    connection: sqlite3.Connection,
    title_id: int,
) -> Optional[sqlite3.Row]:
    """Return the first local file source for a title, if one exists."""
    return connection.execute(
        "SELECT * FROM sources WHERE title_id = ? AND source_type = 'local' AND file_path IS NOT NULL LIMIT 1",
        (title_id,),
    ).fetchone()


def has_local_source(
    connection: sqlite3.Connection,
    tmdb_id: str,
    media_type: str,
    season: Optional[int] = None,
    episode: Optional[int] = None,
) -> bool:
    """Check if a title/episode has a local file source available.

    For movies: checks if the title has any local source.
    For TV episodes: checks if the specific episode has a local source.
    """
    title_row = connection.execute(
        "SELECT id FROM titles WHERE tmdb_id = ?", (tmdb_id,)
    ).fetchone()
    if title_row is None:
        return False

    title_id = int(title_row["id"])

    if media_type in ("tv", "show", "episode") and season is not None and episode is not None:
        episode_row = connection.execute(
            "SELECT id FROM episodes WHERE title_id = ? AND season = ? AND episode = ?",
            (title_id, season, episode),
        ).fetchone()
        if episode_row is None:
            return False

        source_row = connection.execute(
            "SELECT id FROM sources WHERE title_id = ? AND source_type = 'local' AND status = 'available' LIMIT 1",
            (title_id,),
        ).fetchone()
        return source_row is not None

    source_row = connection.execute(
        "SELECT id FROM sources WHERE title_id = ? AND source_type = 'local' AND status = 'available' LIMIT 1",
        (title_id,),
    ).fetchone()
    return source_row is not None


def get_title_by_tmdb_with_sources(
    connection: sqlite3.Connection,
    tmdb_id: str,
) -> Optional[Dict[str, Any]]:
    """Return title row with source availability info.

    Returns dict with title fields plus:
      - has_local_source: bool
      - source_count: int
      - source_types: list[str]
    """
    title_row = connection.execute(
        "SELECT * FROM titles WHERE tmdb_id = ?", (tmdb_id,)
    ).fetchone()
    if title_row is None:
        return None

    title_id = int(title_row["id"])
    sources = connection.execute(
        "SELECT source_type, status FROM sources WHERE title_id = ?",
        (title_id,),
    ).fetchall()

    source_types = list({s["source_type"] for s in sources})
    has_local = any(s["source_type"] == "local" and s["status"] == "available" for s in sources)

    result = dict(title_row)
    result["has_local_source"] = has_local
    result["source_count"] = len(sources)
    result["source_types"] = source_types
    return result


def get_title_seasons_episodes(
    connection: sqlite3.Connection,
    tmdb_id: str,
) -> List[Dict[str, Any]]:
    """Return flattened episode list with metadata for UI display.

    Each dict contains:
      - episode_id: int
      - season: int
      - episode: int
      - name: str
      - air_date: str
      - has_local_source: bool
      - tmdb_id: str (episode tmdb_id)
    """
    title_row = connection.execute(
        "SELECT id, title, type FROM titles WHERE tmdb_id = ?", (tmdb_id,)
    ).fetchone()
    if title_row is None:
        return []

    title_id = int(title_row["id"])
    if title_row["type"] not in ("tv", "show"):
        return []

    episodes = connection.execute(
        "SELECT id, tmdb_id, season, episode, name, air_date FROM episodes WHERE title_id = ? ORDER BY season, episode",
        (title_id,),
    ).fetchall()

    results: List[Dict[str, Any]] = []
    for ep in episodes:
        ep_id = int(ep["id"])
        season = int(ep["season"])
        episode_num = int(ep["episode"])

        has_local = connection.execute(
            "SELECT 1 FROM sources WHERE title_id = ? AND source_type = 'local' AND status = 'available' LIMIT 1",
            (title_id,),
        ).fetchone() is not None

        results.append({
            "episode_id": ep_id,
            "tmdb_id": ep["tmdb_id"],
            "season": season,
            "episode": episode_num,
            "name": ep["name"] or f"Episode {episode_num}",
            "air_date": ep["air_date"],
            "has_local_source": has_local,
        })

    return results


def get_episode_season_episode(
    connection: sqlite3.Connection,
    tmdb_id: str,
    season: int,
    episode: int,
) -> Optional[tuple]:
    """Return (title_name, season, episode) for episode-level torrent search.

    Returns None if the episode doesn't exist.
    """
    title_row = connection.execute(
        "SELECT id, title FROM titles WHERE tmdb_id = ?", (tmdb_id,)
    ).fetchone()
    if title_row is None:
        return None

    title_id = int(title_row["id"])
    ep_row = connection.execute(
        "SELECT season, episode FROM episodes WHERE title_id = ? AND season = ? AND episode = ?",
        (title_id, season, episode),
    ).fetchone()
    if ep_row is None:
        return None

    return (title_row["title"], int(ep_row["season"]), int(ep_row["episode"]))


def get_title_id_for_file_path(
    connection: sqlite3.Connection,
    file_path: str,
) -> Optional[int]:
    """Resolve a local file path to its associated title_id."""
    row = connection.execute(
        "SELECT title_id FROM sources WHERE file_path = ? AND source_type = 'local' LIMIT 1",
        (file_path,),
    ).fetchone()
    return int(row["title_id"]) if row else None


def get_source_metadata(
    connection: sqlite3.Connection,
    file_path: str,
) -> Optional[sqlite3.Row]:
    """Return stored file metadata (size, mtime, hash) for change detection."""
    return connection.execute(
        "SELECT file_size, file_mtime, file_hash, status FROM sources WHERE file_path = ? AND source_type = 'local' LIMIT 1",
        (file_path,),
    ).fetchone()


def update_source_metadata(
    connection: sqlite3.Connection,
    file_path: str,
    *,
    file_size: Optional[int] = None,
    file_mtime: Optional[str] = None,
    file_hash: Optional[str] = None,
    status: Optional[str] = None,
) -> None:
    """Update file metadata on a source record for incremental scanning."""
    fields = []
    values = []
    if file_size is not None:
        fields.append("file_size = ?")
        values.append(file_size)
    if file_mtime is not None:
        fields.append("file_mtime = ?")
        values.append(file_mtime)
    if file_hash is not None:
        fields.append("file_hash = ?")
        values.append(file_hash)
    if status is not None:
        fields.append("status = ?")
        values.append(status)
    fields.append("last_checked = ?")
    values.append(_utcnow())
    values.append(file_path)

    connection.execute(
        f"UPDATE sources SET {', '.join(fields)} WHERE file_path = ? AND source_type = 'local'",
        values,
    )


def mark_sources_missing(
    connection: sqlite3.Connection,
    known_paths: Sequence[str],
    scan_roots: Optional[Sequence[str]] = None,
) -> int:
    """Mark local sources whose files no longer exist as 'missing'.

    When *scan_roots* is provided only sources whose file_path falls under one
    of those directories are considered.  This prevents a partial scan (e.g.
    scanning only the Hindi folder) from marking sources in other folders
    (English, Bengali …) as missing.

    Returns the count of sources marked missing.
    """
    if not known_paths:
        return 0
    placeholders = ",".join("?" for _ in known_paths)
    if scan_roots:
        # Restrict to files whose path lives under one of the scanned roots.
        root_clause = " OR ".join("file_path LIKE ?" for _ in scan_roots)
        root_params = [str(r).rstrip("/") + "/%" for r in scan_roots]
        cursor = connection.execute(
            f"UPDATE sources SET status = 'missing', last_checked = ? "
            f"WHERE source_type = 'local' "
            f"AND file_path NOT IN ({placeholders}) "
            f"AND ({root_clause})",
            [_utcnow(), *known_paths, *root_params],
        )
    else:
        cursor = connection.execute(
            f"UPDATE sources SET status = 'missing', last_checked = ? "
            f"WHERE source_type = 'local' AND file_path NOT IN ({placeholders})",
            [_utcnow(), *known_paths],
        )
    return cursor.rowcount


def remove_missing_sources(
    connection: sqlite3.Connection,
) -> int:
    """Delete all sources marked as 'missing'. Returns count removed."""
    cursor = connection.execute(
        "DELETE FROM sources WHERE status = 'missing'"
    )
    return cursor.rowcount


def find_duplicate_sources(
    connection: sqlite3.Connection,
    file_hash: str,
) -> Sequence[sqlite3.Row]:
    """Find all sources with the same file hash (potential duplicates)."""
    return connection.execute(
        "SELECT * FROM sources WHERE file_hash = ? AND source_type = 'local' AND status != 'missing'",
        (file_hash,),
    ).fetchall()


# ------------------------------------------------------------------
# Play history operations
# ------------------------------------------------------------------

def record_playback(
    connection: sqlite3.Connection,
    *,
    title_id: int,
    position: int,
    duration: int,
    device: Optional[str] = None,
) -> int:
    """Record a playback position for a title."""

    now = _utcnow()
    cursor = connection.execute(
        """
        INSERT INTO play_history (title_id, position, duration, last_played, device)
        VALUES (?, ?, ?, ?, ?)
        """,
        (title_id, position, duration, now, device),
    )
    return int(cursor.lastrowid) if cursor.lastrowid else 0


def get_play_history(
    connection: sqlite3.Connection,
    *,
    title_id: Optional[int] = None,
    limit: int = 50,
) -> Sequence[sqlite3.Row]:
    """Return playback history, optionally filtered by title."""
    if title_id:
        return connection.execute(
            "SELECT * FROM play_history WHERE title_id = ? ORDER BY last_played DESC LIMIT ?",
            (title_id, limit),
        ).fetchall()
    return connection.execute(
        "SELECT * FROM play_history ORDER BY last_played DESC LIMIT ?",
        (limit,),
    ).fetchall()


def get_latest_playback(
    connection: sqlite3.Connection,
    title_id: int,
) -> Optional[sqlite3.Row]:
    """Return the most recent playback record for a title (for resume point)."""
    return connection.execute(
        "SELECT * FROM play_history WHERE title_id = ? ORDER BY last_played DESC LIMIT 1",
        (title_id,),
    ).fetchone()


# ------------------------------------------------------------------
# Library sections
# ------------------------------------------------------------------

def create_library_section(
    connection: sqlite3.Connection,
    *,
    name: str,
    kind: str,
    paths: Sequence[str],
) -> int:
    """Create a named library section grouping scan paths."""
    now = _utcnow()
    cursor = connection.execute(
        """
        INSERT INTO library_sections (name, kind, paths_json, enabled, created_at, updated_at)
        VALUES (?, ?, ?, 1, ?, ?)
        """,
        (name, kind, json.dumps(paths), now, now),
    )
    return int(cursor.lastrowid) if cursor.lastrowid else 0


def list_library_sections(
    connection: sqlite3.Connection,
    *,
    kind: Optional[str] = None,
    enabled_only: bool = True,
) -> Sequence[sqlite3.Row]:
    """List library sections, optionally filtered by kind."""
    if kind:
        if enabled_only:
            return connection.execute(
                "SELECT * FROM library_sections WHERE kind = ? AND enabled = 1 ORDER BY name",
                (kind,),
            ).fetchall()
        return connection.execute(
            "SELECT * FROM library_sections WHERE kind = ? ORDER BY name",
            (kind,),
        ).fetchall()
    if enabled_only:
        return connection.execute(
            "SELECT * FROM library_sections WHERE enabled = 1 ORDER BY name",
        ).fetchall()
    return connection.execute(
        "SELECT * FROM library_sections ORDER BY name",
    ).fetchall()


def get_library_section(
    connection: sqlite3.Connection,
    section_id: int,
) -> Optional[sqlite3.Row]:
    """Return a library section by ID."""
    return connection.execute(
        "SELECT * FROM library_sections WHERE id = ?",
        (section_id,),
    ).fetchone()


def update_library_section(
    connection: sqlite3.Connection,
    section_id: int,
    *,
    name: Optional[str] = None,
    kind: Optional[str] = None,
    paths: Optional[Sequence[str]] = None,
    enabled: Optional[bool] = None,
) -> None:
    """Update a library section's properties."""
    fields = []
    values = []
    if name is not None:
        fields.append("name = ?")
        values.append(name)
    if kind is not None:
        fields.append("kind = ?")
        values.append(kind)
    if paths is not None:
        fields.append("paths_json = ?")
        values.append(json.dumps(paths))
    if enabled is not None:
        fields.append("enabled = ?")
        values.append(1 if enabled else 0)
    fields.append("updated_at = ?")
    values.append(_utcnow())
    values.append(section_id)

    connection.execute(
        f"UPDATE library_sections SET {', '.join(fields)} WHERE id = ?",
        values,
    )


def delete_library_section(
    connection: sqlite3.Connection,
    section_id: int,
) -> None:
    """Delete a library section."""
    connection.execute(
        "DELETE FROM library_sections WHERE id = ?",
        (section_id,),
    )


def get_section_paths(
    connection: sqlite3.Connection,
    section_id: int,
) -> Sequence[str]:
    """Return the list of paths for a library section."""
    row = get_library_section(connection, section_id)
    if row is None:
        return []
    return json.loads(row["paths_json"])


# ------------------------------------------------------------------
# Settings & widgets
# ------------------------------------------------------------------

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


# ------------------------------------------------------------------
# Torrent cache operations
# ------------------------------------------------------------------

def cache_torrent_search(
    connection: sqlite3.Connection,
    query: str,
    media_type: str,
    results_json: str,
    ttl_seconds: int = 3600,
) -> int:
    """Cache torrent search results."""
    now = _utcnow()
    cursor = connection.execute(
        """
        INSERT INTO torrent_cache (query, media_type, results_json, cached_at, ttl_seconds)
        VALUES (?, ?, ?, ?, ?)
        """,
        (query, media_type, results_json, now, ttl_seconds),
    )
    return int(cursor.lastrowid) if cursor.lastrowid else 0


def get_cached_torrent_search(
    connection: sqlite3.Connection,
    query: str,
    media_type: str,
) -> Optional[str]:
    """Return cached search results if still valid."""
    row = connection.execute(
        """
        SELECT results_json, cached_at, ttl_seconds
        FROM torrent_cache
        WHERE query = ? AND media_type = ?
        ORDER BY cached_at DESC
        LIMIT 1
        """,
        (query, media_type),
    ).fetchone()
    if row is None:
        return None

    cached_at = datetime.fromisoformat(row["cached_at"])
    ttl = int(row["ttl_seconds"])
    now = datetime.now(timezone.utc)
    if cached_at.tzinfo is None:
        now = now.replace(tzinfo=None)

    if (now - cached_at).total_seconds() > ttl:
        return None

    return row["results_json"]


def clear_expired_torrent_cache(connection: sqlite3.Connection) -> int:
    """Remove expired cache entries. Returns count removed."""
    cursor = connection.execute(
        """
        DELETE FROM torrent_cache
        WHERE datetime(cached_at, '+' || ttl_seconds || ' seconds') < datetime('now')
        """
    )
    return cursor.rowcount


def clear_all_torrent_cache(connection: sqlite3.Connection) -> int:
    """Remove all torrent search cache entries. Returns count removed."""
    cursor = connection.execute("DELETE FROM torrent_cache")
    return cursor.rowcount


# ------------------------------------------------------------------
# Debrid magnet map operations
# ------------------------------------------------------------------

def upsert_debrid_magnet_map(
    connection: sqlite3.Connection,
    magnet_hash: str,
    torrent_id: str,
) -> None:
    """Store or update magnet hash to RealDebrid torrent_id mapping."""
    now = _utcnow()
    connection.execute(
        """
        INSERT INTO debrid_magnet_map (magnet_hash, torrent_id, created_at)
        VALUES (?, ?, ?)
        ON CONFLICT(magnet_hash) DO UPDATE SET
            torrent_id=excluded.torrent_id,
            created_at=excluded.created_at
        """,
        (magnet_hash, torrent_id, now),
    )


def get_debrid_torrent_id(
    connection: sqlite3.Connection,
    magnet_hash: str,
) -> Optional[str]:
    """Return RealDebrid torrent_id for a magnet hash, if mapped."""
    row = connection.execute(
        "SELECT torrent_id FROM debrid_magnet_map WHERE magnet_hash = ?",
        (magnet_hash,),
    ).fetchone()
    return row["torrent_id"] if row else None


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


# ------------------------------------------------------------------
# User collection operations
# ------------------------------------------------------------------

def upsert_collection_item(
    connection: sqlite3.Connection,
    item: Dict[str, Any],
) -> int:
    """Insert or update a user collection item. Returns the row id."""
    cursor = connection.execute(
        """
        INSERT INTO user_collections
            (collection_type, tmdb_id, type, title, year, overview,
             poster_path, backdrop_path, rating, vote_count, genres_json, added_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(collection_type, tmdb_id) DO UPDATE SET
            type=excluded.type,
            title=excluded.title,
            year=excluded.year,
            overview=excluded.overview,
            poster_path=excluded.poster_path,
            backdrop_path=excluded.backdrop_path,
            rating=excluded.rating,
            vote_count=excluded.vote_count,
            genres_json=excluded.genres_json
        """,
        (
            item["collection_type"],
            item["tmdb_id"],
            item["type"],
            item["title"],
            item.get("year"),
            item.get("overview"),
            item.get("poster_path"),
            item.get("backdrop_path"),
            item.get("rating"),
            item.get("vote_count"),
            item.get("genres_json", "[]"),
            _utcnow(),
        ),
    )
    row = connection.execute(
        "SELECT id FROM user_collections WHERE collection_type = ? AND tmdb_id = ?",
        (item["collection_type"], item["tmdb_id"]),
    ).fetchone()
    return int(row["id"]) if row else cursor.lastrowid


def remove_collection_item(
    connection: sqlite3.Connection,
    *,
    collection_type: str,
    tmdb_id: str,
) -> bool:
    """Remove an item from a collection. Returns True if a row was deleted."""
    cursor = connection.execute(
        "DELETE FROM user_collections WHERE collection_type = ? AND tmdb_id = ?",
        (collection_type, tmdb_id),
    )
    return cursor.rowcount > 0


def is_in_collection(
    connection: sqlite3.Connection,
    *,
    collection_type: str,
    tmdb_id: str,
) -> bool:
    """Return True if the item exists in the given collection."""
    row = connection.execute(
        "SELECT 1 FROM user_collections WHERE collection_type = ? AND tmdb_id = ?",
        (collection_type, tmdb_id),
    ).fetchone()
    return row is not None


def list_collection_items(
    connection: sqlite3.Connection,
    *,
    collection_type: str,
    media_type: Optional[str] = None,
    sort: str = "added_at",
    order: str = "desc",
    genre: Optional[str] = None,
    limit: int = 20,
    offset: int = 0,
) -> Sequence[sqlite3.Row]:
    """Return paginated items from a collection with optional filters."""
    _safe_sort = sort if sort in ("added_at", "title", "rating", "vote_count") else "added_at"
    _safe_order = "DESC" if order.lower() == "desc" else "ASC"

    where_clauses = ["collection_type = ?"]
    params: List[Any] = [collection_type]

    if media_type:
        where_clauses.append("type = ?")
        params.append(media_type)

    if genre:
        where_clauses.append("genres_json LIKE ?")
        params.append(f"%{genre}%")

    where_sql = " AND ".join(where_clauses)
    query = (
        f"SELECT * FROM user_collections WHERE {where_sql} "
        f"ORDER BY {_safe_sort} {_safe_order} "
        "LIMIT ? OFFSET ?"
    )
    params.extend([limit, offset])
    return connection.execute(query, params).fetchall()


__all__ = [
    "connect",
    "connection",
    "migrate",
    "upsert_title",
    "update_title_artwork_paths",
    "get_title_by_tmdb",
    "get_title_by_id",
    "list_titles",
    "search_titles",
    "get_recently_added",
    "upsert_episode",
    "get_episodes_for_title",
    "upsert_source",
    "get_sources_for_title",
    "get_local_file_for_title",
    "has_local_source",
    "get_title_by_tmdb_with_sources",
    "get_title_seasons_episodes",
    "get_episode_season_episode",
    "get_title_id_for_file_path",
    "get_source_metadata",
    "update_source_metadata",
    "mark_sources_missing",
    "remove_missing_sources",
    "find_duplicate_sources",
    "create_library_section",
    "list_library_sections",
    "get_library_section",
    "update_library_section",
    "delete_library_section",
    "get_section_paths",
    "record_playback",
    "get_play_history",
    "get_latest_playback",
    "get_setting",
    "set_setting",
    "get_widget",
    "set_widget",
    "cache_torrent_search",
    "get_cached_torrent_search",
    "clear_expired_torrent_cache",
    "upsert_debrid_magnet_map",
    "get_debrid_torrent_id",
    "upsert_collection_item",
    "remove_collection_item",
    "is_in_collection",
    "list_collection_items",
]
