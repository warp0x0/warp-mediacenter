"""Local library scanner that persists metadata to SQLite."""

from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Dict, Iterable, Optional, Sequence

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.information_handlers.models import MediaType, Show
from warp_mediacenter.backend.information_handlers.providers import InformationProviders
from warp_mediacenter.backend.library.artwork import download_artwork
from warp_mediacenter.backend.library.filename_parser import ParsedName, parse_media_name
from warp_mediacenter.backend.network_handlers.session import NetError, RateLimited
from warp_mediacenter.backend.persistence import (
    connection as db_connection,
    get_setting,
    set_setting,
    upsert_episode,
    upsert_title,
    update_title_artwork_paths,
)
from warp_mediacenter.config.settings.paths import get_artwork_dir

log = get_logger(__name__)
_VIDEO_EXTENSIONS = {".mp4", ".mkv", ".avi", ".mov", ".m4v", ".ts", ".m2ts", ".webm", ".mpg", ".mpeg"}
_SETTINGS_KEY = "library_scan_paths"


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


def scan_once(paths: Sequence[Path]) -> Dict[str, int]:
    """Perform a single library scan and return summary statistics."""

    providers = InformationProviders()
    artwork_dir = get_artwork_dir()
    seen_files: set[Path] = set()
    normalized_paths = [p.expanduser().resolve() for p in paths]
    summary = {"total": 0, "matched": 0, "unmatched": 0, "movies": 0, "shows": 0, "episodes": 0}
    matched_movies: set[str] = set()
    matched_shows: set[str] = set()
    show_cache: Dict[str, tuple[int, Show]] = {}

    media_files = list(_iter_media_files(normalized_paths))
    if not media_files:
        return summary

    with db_connection() as conn:
        for file_path in media_files:
            if file_path in seen_files:
                continue
            seen_files.add(file_path)
            summary["total"] += 1

            parsed = parse_media_name(file_path)
            if parsed is None:
                summary["unmatched"] += 1
                continue

            try:
                if parsed.media_type == MediaType.MOVIE:
                    movie_id = _handle_movie(providers, conn, parsed, artwork_dir)
                    if movie_id is None:
                        summary["unmatched"] += 1
                        continue
                    summary["matched"] += 1
                    matched_movies.add(movie_id)
                    summary["movies"] = len(matched_movies)
                else:
                    show_id = _handle_episode(providers, conn, parsed, artwork_dir, show_cache)
                    if show_id is None:
                        summary["unmatched"] += 1
                        continue
                    summary["matched"] += 1
                    summary["episodes"] += 1
                    matched_shows.add(show_id)
                    summary["shows"] = len(matched_shows)
            except RateLimited as exc:
                log.warning("library_scan_rate_limited", path=str(file_path), error=str(exc))
                summary["unmatched"] += 1
            except NetError as exc:  # pragma: no cover - network dependant
                log.warning("library_scan_network_error", path=str(file_path), error=str(exc))
                summary["unmatched"] += 1
            except Exception as exc:  # noqa: BLE001 - defensive logging only
                log.exception("library_scan_failure", path=str(file_path), error=str(exc))
                summary["unmatched"] += 1

    return summary


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
    return str(movie.id)


def _handle_episode(
    providers: InformationProviders,
    conn,
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


__all__ = ["add_scan_path", "scan_once"]
