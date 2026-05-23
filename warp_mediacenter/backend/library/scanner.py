"""Local library scanner that persists metadata to SQLite.

Supports incremental scanning (mtime/size tracking), parallel file processing,
duplicate detection (SHA-256 of first 1MB), stale file cleanup, and library sections.
"""

from __future__ import annotations

import hashlib
import json
import os
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.common.tasks import TaskRunner, TaskSpec
from warp_mediacenter.backend.information_handlers.models import MediaType, Show
from warp_mediacenter.backend.information_handlers.providers import InformationProviders
from warp_mediacenter.backend.library.artwork import download_artwork
from warp_mediacenter.backend.library.filename_parser import ParsedName, parse_media_name
from warp_mediacenter.backend.network_handlers.session import NetError, RateLimited
from warp_mediacenter.backend.persistence import (
    connection as db_connection,
    create_library_section,
    delete_library_section,
    find_duplicate_sources,
    get_library_section,
    get_section_paths,
    get_setting,
    get_source_metadata,
    get_sources_for_title,
    list_library_sections,
    mark_sources_missing,
    remove_missing_sources,
    set_setting,
    update_library_section,
    update_source_metadata,
    upsert_episode,
    upsert_source,
    upsert_title,
    update_title_artwork_paths,
)
from warp_mediacenter.backend.resource_management import get_resource_manager
from warp_mediacenter.config.settings.paths import get_artwork_dir

log = get_logger(__name__)

_VIDEO_EXTENSIONS = {".mp4", ".mkv", ".avi", ".mov", ".m4v", ".ts", ".m2ts", ".webm", ".mpg", ".mpeg"}
_SETTINGS_KEY = "library_scan_paths"
_HASH_SAMPLE_BYTES = 1024 * 1024  # 1MB for duplicate detection


@dataclass(frozen=True)
class ScanResult:
    """Summary of a library scan operation."""
    total: int = 0
    skipped_unchanged: int = 0
    matched: int = 0
    unmatched: int = 0
    movies: int = 0
    shows: int = 0
    episodes: int = 0
    duplicates: int = 0
    missing_removed: int = 0
    errors: int = 0
    duration_sec: float = 0.0

    def as_dict(self) -> Dict[str, object]:
        return {
            "total": self.total,
            "skipped_unchanged": self.skipped_unchanged,
            "matched": self.matched,
            "unmatched": self.unmatched,
            "movies": self.movies,
            "shows": self.shows,
            "episodes": self.episodes,
            "duplicates": self.duplicates,
            "missing_removed": self.missing_removed,
            "errors": self.errors,
            "duration_sec": round(self.duration_sec, 2),
        }


@dataclass
class _FileMeta:
    """Cached file metadata for incremental scanning."""
    path: Path
    size: int
    mtime: str
    hash: Optional[str] = None


def _compute_file_hash(file_path: Path) -> Optional[str]:
    """Compute SHA-256 hash of the first 1MB of a file for duplicate detection."""
    try:
        h = hashlib.sha256()
        with open(file_path, "rb") as f:
            h.update(f.read(_HASH_SAMPLE_BYTES))
        return h.hexdigest()
    except OSError:
        return None


def _get_file_meta(file_path: Path) -> _FileMeta:
    """Extract file metadata for change detection."""
    stat = file_path.stat()
    mtime = datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc).isoformat()
    return _FileMeta(
        path=file_path,
        size=stat.st_size,
        mtime=mtime,
    )


def _file_changed(file_path: Path, stored_meta: Optional[object]) -> bool:
    """Check if a file has changed since last scan using mtime + size."""
    if stored_meta is None:
        return True
    try:
        current_size = stored_meta.get("file_size")
        current_mtime = stored_meta.get("file_mtime")
    except (AttributeError, TypeError):
        return True

    if current_size is None or current_mtime is None:
        return True

    try:
        stat = file_path.stat()
        current_stat_size = stat.st_size
        current_stat_mtime = datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc).isoformat()
        return current_stat_size != current_size or current_stat_mtime != current_mtime
    except OSError:
        return True


def add_scan_path(path: Path) -> Sequence[Path]:
    """Persist a scan path into the settings table, returning the full list."""

    resolved = path.expanduser().resolve()
    if not resolved.exists():
        raise ValueError(f"Scan path '{resolved}' does not exist")

    with db_connection() as conn:
        raw = get_setting(conn, _SETTINGS_KEY)
        entries: list[str]
        if raw:
            try:
                entries = [str(Path(p)) for p in json.loads(raw)]
            except json.JSONDecodeError:
                entries = []
        else:
            entries = []

        entry = str(resolved)
        if entry not in entries:
            entries.append(entry)
            set_setting(conn, _SETTINGS_KEY, json.dumps(entries, ensure_ascii=False))

        return [Path(p) for p in entries]


def _iter_media_files(paths: Iterable[Path]) -> Iterable[Path]:
    for root in paths:
        if not root.exists():
            log.warning("library_scan_missing_path", path=str(root))
            continue
        if root.is_file() and root.suffix.lower() in _VIDEO_EXTENSIONS:
            yield root
            continue
        if not root.is_dir():
            continue
        for entry in sorted(root.rglob("*")):
            if entry.is_file() and entry.suffix.lower() in _VIDEO_EXTENSIONS:
                yield entry


def _handle_movie(
    providers: InformationProviders,
    conn,
    file_path: Path,
    parsed: ParsedName,
    artwork_dir: Path,
) -> Optional[str]:
    results = providers.search_movies(parsed.title) or []
    catalog = _select_catalog_match(results, parsed.year)
    if catalog is None:
        log.debug("library_movie_not_found", title=parsed.title)
        return None

    movie = providers.movie_details(catalog.id, include_credits=False)
    year = movie.release_date.year if movie.release_date else parsed.year or catalog.year
    poster_url = movie.poster.url if movie.poster else None
    backdrop_url = movie.backdrop.url if movie.backdrop else None
    title_id = upsert_title(
        conn,
        tmdb_id=str(movie.id),
        type=MediaType.MOVIE.value,
        title=movie.title,
        year=year,
        overview=movie.overview,
        poster_url=poster_url,
        backdrop_url=backdrop_url,
    )
    poster_path, backdrop_path = download_artwork(poster_url, backdrop_url, artwork_dir)
    update_title_artwork_paths(
        conn,
        title_id,
        poster_path=str(poster_path) if poster_path else None,
        backdrop_path=str(backdrop_path) if backdrop_path else None,
    )

    file_meta = _get_file_meta(file_path)
    file_hash = _compute_file_hash(file_path)
    upsert_source(
        conn,
        title_id=title_id,
        file_path=str(file_path),
        source_type="local",
        scraper="scanner",
        file_size=file_meta.size,
        file_mtime=file_meta.mtime,
        file_hash=file_hash,
    )

    if file_hash:
        dupes = find_duplicate_sources(conn, file_hash)
        if len(dupes) > 1:
            log.warning("library_duplicate_detected", path=str(file_path), hash=file_hash)

    return str(movie.id)


def _handle_episode(
    providers: InformationProviders,
    conn,
    file_path: Path,
    parsed: ParsedName,
    artwork_dir: Path,
    show_cache: Dict[str, tuple[int, Show]],
) -> Optional[str]:
    if parsed.season is None or parsed.episode is None:
        return None

    results = providers.search_shows(parsed.title) or []
    catalog = _select_catalog_match(results, parsed.year)
    if catalog is None:
        log.debug("library_show_not_found", title=parsed.title)
        return None

    show_id = str(catalog.id)
    cached = show_cache.get(show_id)
    if cached is None:
        show = providers.show_details(show_id, include_credits=False)
        title_id = _persist_show(conn, show, parsed, artwork_dir)
        cached = (title_id, show)
        show_cache[show_id] = cached
    else:
        title_id, show = cached

    episode = providers.tmdb.episode_details(show_id, parsed.season, parsed.episode, include_credits=False)
    air_date = episode.air_date.isoformat() if episode.air_date else None
    upsert_episode(
        conn,
        tmdb_id=str(episode.id),
        title_id=title_id,
        season=parsed.season,
        episode=parsed.episode,
        name=episode.title,
        air_date=air_date,
    )

    file_meta = _get_file_meta(file_path)
    file_hash = _compute_file_hash(file_path)
    upsert_source(
        conn,
        title_id=title_id,
        file_path=str(file_path),
        source_type="local",
        scraper="scanner",
        file_size=file_meta.size,
        file_mtime=file_meta.mtime,
        file_hash=file_hash,
    )

    if file_hash:
        dupes = find_duplicate_sources(conn, file_hash)
        if len(dupes) > 1:
            log.warning("library_duplicate_detected", path=str(file_path), hash=file_hash)

    return show_id


def _persist_show(conn, show: Show, parsed: ParsedName, artwork_dir: Path) -> int:
    first_air_year = show.first_air_date.year if show.first_air_date else parsed.year
    poster_url = show.poster.url if show.poster else None
    backdrop_url = show.backdrop.url if show.backdrop else None
    title_id = upsert_title(
        conn,
        tmdb_id=str(show.id),
        type=MediaType.SHOW.value,
        title=show.title,
        year=first_air_year,
        overview=show.overview,
        poster_url=poster_url,
        backdrop_url=backdrop_url,
    )
    poster_path, backdrop_path = download_artwork(poster_url, backdrop_url, artwork_dir)
    update_title_artwork_paths(
        conn,
        title_id,
        poster_path=str(poster_path) if poster_path else None,
        backdrop_path=str(backdrop_path) if backdrop_path else None,
    )
    return title_id


def _select_catalog_match(results: Sequence, year: Optional[int]) -> Optional:
    if not results:
        return None
    if year is not None:
        for candidate in results:
            try:
                candidate_year = getattr(candidate, "year", None)
                if candidate_year and abs(int(candidate_year) - year) <= 1:
                    return candidate
            except (TypeError, ValueError):
                continue
    return results[0]


def _process_file(
    file_path: Path,
    providers: InformationProviders,
    artwork_dir: Path,
    show_cache: Dict[str, tuple[int, Show]],
) -> Dict[str, int]:
    """Process a single media file. Returns a summary dict."""
    result = {"total": 1, "skipped": 0, "matched": 0, "unmatched": 0, "error": 0, "duplicate": 0}

    with db_connection() as conn:
        stored_meta = get_source_metadata(conn, str(file_path))
        if not _file_changed(file_path, stored_meta):
            result["skipped"] = 1
            return result

        parsed = parse_media_name(file_path)
        if parsed is None:
            result["unmatched"] = 1
            return result

        try:
            if parsed.media_type == MediaType.MOVIE:
                movie_id = _handle_movie(providers, conn, file_path, parsed, artwork_dir)
                if movie_id is None:
                    result["unmatched"] = 1
                else:
                    result["matched"] = 1
            else:
                show_id = _handle_episode(providers, conn, file_path, parsed, artwork_dir, show_cache)
                if show_id is None:
                    result["unmatched"] = 1
                else:
                    result["matched"] = 1
        except RateLimited as exc:
            log.warning("library_scan_rate_limited", path=str(file_path), error=str(exc))
            result["unmatched"] = 1
        except NetError as exc:
            log.warning("library_scan_network_error", path=str(file_path), error=str(exc))
            result["unmatched"] = 1
        except Exception as exc:
            log.exception("library_scan_failure", path=str(file_path), error=str(exc))
            result["error"] = 1

    return result


def scan_once(
    paths: Sequence[Path],
    *,
    incremental: bool = True,
    parallel: bool = True,
    cleanup_missing: bool = True,
) -> ScanResult:
    """Perform a library scan and return summary statistics.

    Args:
        paths: Directories or files to scan.
        incremental: Skip files that haven't changed since last scan (mtime+size).
        parallel: Process files concurrently using TaskRunner.
        cleanup_missing: Mark sources whose files no longer exist as 'missing'.
    """
    start = time.monotonic()
    providers = InformationProviders()
    artwork_dir = get_artwork_dir()
    normalized_paths = [p.expanduser().resolve() for p in paths]

    media_files = list(_iter_media_files(normalized_paths))
    if not media_files:
        return ScanResult(duration_sec=time.monotonic() - start)

    known_paths = [str(f) for f in media_files]

    if cleanup_missing:
        with db_connection() as conn:
            removed = mark_sources_missing(conn, known_paths)
            if removed:
                log.info("library_scan_marked_missing", count=removed)

    show_cache: Dict[str, tuple[int, Show]] = {}
    result = ScanResult()

    if parallel and len(media_files) > 1:
        resource_manager = get_resource_manager()
        max_workers = min(len(media_files), 4)

        with TaskRunner(
            max_workers=max_workers,
            resource_manager=resource_manager,
            estimated_task_memory_mb=128.0,
            context="library_scan",
            resource_wait_timeout=30.0,
        ) as runner:
            futures = []
            for file_path in media_files:
                fut = runner.submit(
                    TaskSpec(
                        fn=_process_file,
                        args=(file_path, providers, artwork_dir, show_cache),
                        name=f"scan_{file_path.name}",
                        estimated_memory_mb=64.0,
                    )
                )
                futures.append(fut)

            for fut in futures:
                file_result = fut.result(timeout=120)
                result.total += file_result["total"]
                result.skipped_unchanged += file_result["skipped"]
                result.matched += file_result["matched"]
                result.unmatched += file_result["unmatched"]
                result.errors += file_result["error"]
    else:
        for file_path in media_files:
            file_result = _process_file(file_path, providers, artwork_dir, show_cache)
            result.total += file_result["total"]
            result.skipped_unchanged += file_result["skipped"]
            result.matched += file_result["matched"]
            result.unmatched += file_result["unmatched"]
            result.errors += file_result["error"]

    with db_connection() as conn:
        for row in conn.execute(
            "SELECT COUNT(*) as cnt FROM titles WHERE type = ?", ("movie",)
        ).fetchall():
            result.movies = row["cnt"]
        for row in conn.execute(
            "SELECT COUNT(DISTINCT title_id) as cnt FROM episodes"
        ).fetchall():
            result.shows = row["cnt"]
        for row in conn.execute(
            "SELECT COUNT(*) as cnt FROM episodes"
        ).fetchall():
            result.episodes = row["cnt"]

    result.duration_sec = time.monotonic() - start
    log.info(
        "library_scan_complete",
        total=result.total,
        matched=result.matched,
        skipped=result.skipped_unchanged,
        unmatched=result.unmatched,
        errors=result.errors,
        duration=result.duration_sec,
    )
    return result


def scan_library_sections(
    *,
    incremental: bool = True,
    parallel: bool = True,
    cleanup_missing: bool = True,
) -> Dict[str, ScanResult]:
    """Scan all enabled library sections and return per-section results."""
    results = {}
    with db_connection() as conn:
        sections = list_library_sections(conn, enabled_only=True)

    for section in sections:
        paths = [Path(p) for p in json.loads(section["paths_json"])]
        results[section["name"]] = scan_once(
            paths,
            incremental=incremental,
            parallel=parallel,
            cleanup_missing=cleanup_missing,
        )

    return results


def create_section(
    name: str,
    kind: str,
    paths: Sequence[str],
) -> int:
    """Create a named library section."""
    with db_connection() as conn:
        return create_library_section(conn, name=name, kind=kind, paths=paths)


def list_sections(kind: Optional[str] = None) -> Sequence[dict]:
    """List library sections."""
    with db_connection() as conn:
        rows = list_library_sections(conn, kind=kind, enabled_only=False)
    return [dict(r) for r in rows]


def update_section(
    section_id: int,
    *,
    name: Optional[str] = None,
    kind: Optional[str] = None,
    paths: Optional[Sequence[str]] = None,
    enabled: Optional[bool] = None,
) -> None:
    """Update a library section."""
    with db_connection() as conn:
        update_library_section(conn, section_id, name=name, kind=kind, paths=paths, enabled=enabled)


def delete_section(section_id: int) -> None:
    """Delete a library section."""
    with db_connection() as conn:
        delete_library_section(conn, section_id)


def clean_missing_sources() -> int:
    """Remove all sources marked as 'missing' from the database."""
    with db_connection() as conn:
        return remove_missing_sources(conn)


__all__ = [
    "ScanResult",
    "add_scan_path",
    "scan_once",
    "scan_library_sections",
    "create_section",
    "list_sections",
    "update_section",
    "delete_section",
    "clean_missing_sources",
]
