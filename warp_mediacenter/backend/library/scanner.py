"""Local library scanner that persists metadata to SQLite.

Supports incremental scanning (mtime/size tracking), parallel file processing,
duplicate detection (SHA-256 of first 1MB), stale file cleanup, and library sections.
"""

from __future__ import annotations

import concurrent.futures
import hashlib
import json
import os
import re
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable, Dict, Iterable, List, Optional, Sequence

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

# Callables set by the API layer to stream scan progress to the UI.
# Only one scan runs at a time, so module-level variables are safe.
_ui_log_fn: Optional[Callable[[str], None]] = None
_progress_fn: Optional[Callable[[int, int], None]] = None  # (done, total)


def _ui_log(msg: str) -> None:
    fn = _ui_log_fn
    if fn is not None:
        try:
            fn(msg)
        except Exception:
            pass


def _report_progress(done: int, total: int) -> None:
    fn = _progress_fn
    if fn is not None:
        try:
            fn(done, total)
        except Exception:
            pass


_VIDEO_EXTENSIONS = {".mp4", ".mkv", ".avi", ".mov", ".m4v", ".ts", ".m2ts", ".webm", ".mpg", ".mpeg"}
_SETTINGS_KEY = "library_scan_paths"
_HASH_SAMPLE_BYTES = 1024 * 1024  # 1MB for duplicate detection

# Filenames whose exact stem (lowercased) should always be skipped.
_SKIP_STEMS = frozenset({"output", "sample", "trailer", "featurette"})

# Detects a split-part suffix: Movie_2.2023... — single digit only.
_SPLIT_PART_RE = re.compile(r'^(.+)_(\d{1,2})(\..+)$')

# Matches folder names that START with a season token (Season 1, S01, s2…).
# No $ anchor — allows suffixes like "Season 1 - The Adventures of Sherlock Holmes".
_SEASON_DIR_RE = re.compile(r'^(season\s*\d+|s\d{1,2})\b', re.IGNORECASE)


@dataclass
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


@dataclass
class _NfoData:
    """Metadata extracted from a Kodi-compatible .nfo sidecar file."""
    tmdb_id: Optional[str] = None
    title: Optional[str] = None
    year: Optional[int] = None
    overview: Optional[str] = None
    rating: Optional[float] = None
    genres: List[str] = field(default_factory=list)
    premiered: Optional[str] = None


@dataclass
class _EpisodeNfoData:
    """Metadata from an episode-specific .nfo file (<episodedetails> root tag)."""
    tmdb_id: Optional[str] = None
    title: Optional[str] = None
    season: Optional[int] = None
    episode: Optional[int] = None
    air_date: Optional[str] = None
    overview: Optional[str] = None


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


def _parse_nfo(file_path: Path) -> Optional[_NfoData]:
    """Find and parse a .nfo sidecar adjacent to *file_path*.

    Search order: <stem>.nfo → movie.nfo → tvshow.nfo (same dir) →
    tvshow.nfo (parent dir, for season-subfolder layouts).
    Returns None if no readable .nfo exists.
    """
    import xml.etree.ElementTree as ET

    candidates = [
        file_path.with_suffix(".nfo"),
        file_path.parent / "movie.nfo",
        file_path.parent / "tvshow.nfo",
        file_path.parent.parent / "tvshow.nfo",
    ]
    nfo_path = next((c for c in candidates if c.is_file()), None)
    if nfo_path is None:
        return None

    try:
        root = ET.parse(nfo_path).getroot()

        tmdb_id: Optional[str] = None
        for uid in root.findall("uniqueid"):
            if uid.get("type") == "tmdb":
                tmdb_id = (uid.text or "").strip() or None
                break

        title = (root.findtext("title") or "").strip() or None
        year_str = (root.findtext("year") or "").strip()
        year = int(year_str) if year_str.isdigit() else None
        overview = (root.findtext("plot") or "").strip() or None
        premiered = (root.findtext("premiered") or "").strip() or None

        # Nested rating: <ratings><rating name="themoviedb"><value>7.598</value></rating></ratings>
        rating: Optional[float] = None
        for rating_el in root.findall("ratings/rating"):
            value_el = rating_el.find("value")
            if value_el is not None and value_el.text:
                try:
                    rating = float(value_el.text.strip())
                    break
                except ValueError:
                    pass

        genres = [g.text.strip() for g in root.findall("genre") if g.text and g.text.strip()]

        return _NfoData(
            tmdb_id=tmdb_id, title=title, year=year, overview=overview,
            rating=rating, genres=genres, premiered=premiered,
        )
    except Exception as exc:
        log.warning("nfo_parse_error", nfo=str(nfo_path), error=str(exc))
        return None


def _show_root(file_path: Path) -> Path:
    """Return the show's root folder (where tvshow.nfo belongs).

    Season-subfolder layout (/Show/Season 1/ep.mkv) → returns /Show/.
    Flat layout (/Show/ep.mkv) → returns /Show/ (same as parent).
    """
    if _SEASON_DIR_RE.match(file_path.parent.name):
        return file_path.parent.parent
    return file_path.parent


def _parse_tvshow_nfo(file_path: Path) -> Optional[_NfoData]:
    """Parse tvshow.nfo from the show's root folder (1st-level check only).

    Uses _show_root() to locate tvshow.nfo. Returns None if absent or unreadable.
    """
    import xml.etree.ElementTree as ET

    nfo_path = _show_root(file_path) / "tvshow.nfo"
    if not nfo_path.is_file():
        return None

    try:
        root = ET.parse(nfo_path).getroot()

        tmdb_id: Optional[str] = None
        for uid in root.findall("uniqueid"):
            if uid.get("type") == "tmdb":
                tmdb_id = (uid.text or "").strip() or None
                break

        title = (root.findtext("title") or "").strip() or None
        premiered = (root.findtext("premiered") or "").strip() or None

        year: Optional[int] = None
        if premiered:
            try:
                year = int(premiered[:4])
            except (ValueError, IndexError):
                pass
        if year is None:
            year_str = (root.findtext("year") or "").strip()
            if year_str.isdigit():
                year = int(year_str)

        overview = (root.findtext("plot") or "").strip() or None

        rating: Optional[float] = None
        for rating_el in root.findall("ratings/rating"):
            value_el = rating_el.find("value")
            if value_el is not None and value_el.text:
                try:
                    rating = float(value_el.text.strip())
                    break
                except ValueError:
                    pass

        genres = [g.text.strip() for g in root.findall("genre") if g.text and g.text.strip()]

        return _NfoData(
            tmdb_id=tmdb_id, title=title, year=year, overview=overview,
            rating=rating, genres=genres, premiered=premiered,
        )
    except Exception as exc:
        log.warning("tvshow_nfo_parse_error", nfo=str(nfo_path), error=str(exc))
        return None


def _parse_episode_nfo(file_path: Path) -> Optional[_EpisodeNfoData]:
    """Parse an episode-specific .nfo sidecar co-located with the video file.

    Only checks file_path.with_suffix(".nfo"). Root tag must be <episodedetails>.
    Returns None if absent, unreadable, or has a different root tag.
    """
    import xml.etree.ElementTree as ET

    nfo_path = file_path.with_suffix(".nfo")
    if not nfo_path.is_file():
        return None

    try:
        root = ET.parse(nfo_path).getroot()
        if root.tag != "episodedetails":
            return None

        tmdb_id: Optional[str] = None
        for uid in root.findall("uniqueid"):
            if uid.get("type") == "tmdb":
                tmdb_id = (uid.text or "").strip() or None
                break

        title = (root.findtext("title") or "").strip() or None

        season_str = (root.findtext("season") or "").strip()
        season: Optional[int] = int(season_str) if season_str.isdigit() else None

        episode_str = (root.findtext("episode") or "").strip()
        episode: Optional[int] = int(episode_str) if episode_str.isdigit() else None

        air_date = (root.findtext("aired") or "").strip() or None
        overview = (root.findtext("plot") or "").strip() or None

        return _EpisodeNfoData(
            tmdb_id=tmdb_id, title=title, season=season, episode=episode,
            air_date=air_date, overview=overview,
        )
    except Exception as exc:
        log.warning("episode_nfo_parse_error", nfo=str(nfo_path), error=str(exc))
        return None


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


def _is_split_part(path: Path) -> bool:
    """True when *path* is a split-part copy whose primary file exists alongside it.

    Matches Movie_2.2023.mkv only when Movie.2023.mkv is present in the same
    directory.  This avoids filtering genuine sequels named The_Matrix_2.mkv
    that don't have a sibling The_Matrix.mkv.
    """
    m = _SPLIT_PART_RE.match(path.name)
    if not m:
        return False
    base_stem, _part, rest = m.group(1), m.group(2), m.group(3)
    sibling = path.parent / f"{base_stem}{rest}"
    return sibling.is_file()


def _should_skip_file(path: Path) -> bool:
    stem_lower = path.stem.lower()
    if stem_lower in _SKIP_STEMS:
        return True
    if re.search(r'\bsample\b', stem_lower):  # "Downfall Sample", "movie.(Sample)"
        return True
    if _is_split_part(path):
        return True
    return False


def _iter_media_files(paths: Iterable[Path]) -> Iterable[Path]:
    for root in paths:
        if not root.exists():
            log.warning("library_scan_missing_path", path=str(root))
            continue
        if root.is_file() and root.suffix.lower() in _VIDEO_EXTENSIONS:
            if not _should_skip_file(root):
                yield root
            continue
        if not root.is_dir():
            continue
        for entry in sorted(root.rglob("*")):
            if entry.is_file() and entry.suffix.lower() in _VIDEO_EXTENSIONS:
                if not _should_skip_file(entry):
                    yield entry


# ---------------------------------------------------------------------------
# Data containers — hold everything gathered from network before any DB write
# ---------------------------------------------------------------------------

@dataclass
class _MovieData:
    tmdb_id: str
    title: str
    year: Optional[int]
    overview: Optional[str]
    poster_url: Optional[str]
    backdrop_url: Optional[str]
    poster_path: Optional[Path]
    backdrop_path: Optional[Path]
    rating: Optional[float] = None
    genres: List[str] = field(default_factory=list)
    premiered: Optional[str] = None


@dataclass
class _EpisodeData:
    show_tmdb_id: str
    show_title: str
    show_year: Optional[int]
    show_overview: Optional[str]
    show_poster_url: Optional[str]
    show_backdrop_url: Optional[str]
    show_poster_path: Optional[Path]
    show_backdrop_path: Optional[Path]
    episode_tmdb_id: str
    season: int
    episode: int
    episode_name: Optional[str]
    air_date: Optional[str]


def _write_nfo_movie(file_path: Path, data: _MovieData) -> None:
    """Write a minimal Kodi-compatible .nfo sidecar for a movie.

    Called after a successful TMDb lookup when no pre-existing .nfo was found.
    Writes only the fields needed for future re-scans to skip the TMDb API call.
    """
    import xml.etree.ElementTree as ET

    nfo_path = file_path.with_suffix(".nfo")
    root = ET.Element("movie")

    ET.SubElement(root, "title").text = data.title
    if data.year:
        ET.SubElement(root, "year").text = str(data.year)
    if data.overview:
        ET.SubElement(root, "plot").text = data.overview

    uid = ET.SubElement(root, "uniqueid")
    uid.set("type", "tmdb")
    uid.set("default", "true")
    uid.text = data.tmdb_id

    if data.rating is not None:
        ratings_el = ET.SubElement(root, "ratings")
        rating_el = ET.SubElement(ratings_el, "rating")
        rating_el.set("name", "themoviedb")
        rating_el.set("default", "true")
        rating_el.set("max", "10")
        ET.SubElement(rating_el, "value").text = f"{data.rating:.3f}"

    for genre in data.genres:
        ET.SubElement(root, "genre").text = genre

    if data.premiered:
        ET.SubElement(root, "premiered").text = data.premiered

    gen_el = ET.SubElement(root, "generator")
    ET.SubElement(gen_el, "appname").text = "WarpMediaCenter"

    ET.indent(root, space="    ")
    try:
        with open(nfo_path, "w", encoding="utf-8") as f:
            f.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n')
            f.write(ET.tostring(root, encoding="unicode"))
            f.write("\n")
        log.info("nfo_written", nfo=nfo_path.name)
    except OSError as exc:
        log.warning("nfo_write_error", nfo=str(nfo_path), error=str(exc))


def _write_nfo_show(file_path: Path, show: Show, show_id: str) -> None:
    """Write a minimal tvshow.nfo in the show's root folder.

    Called after a successful TMDb lookup when no tvshow.nfo was found.
    """
    import xml.etree.ElementTree as ET

    nfo_path = _show_root(file_path) / "tvshow.nfo"
    root = ET.Element("tvshow")

    ET.SubElement(root, "title").text = show.title
    if show.first_air_date:
        ET.SubElement(root, "premiered").text = show.first_air_date.isoformat()
    if show.overview:
        ET.SubElement(root, "plot").text = show.overview

    uid = ET.SubElement(root, "uniqueid")
    uid.set("type", "tmdb")
    uid.set("default", "true")
    uid.text = show_id

    vote_avg = getattr(show, "vote_average", None)
    if vote_avg is not None:
        ratings_el = ET.SubElement(root, "ratings")
        rating_el = ET.SubElement(ratings_el, "rating")
        rating_el.set("name", "themoviedb")
        rating_el.set("default", "true")
        rating_el.set("max", "10")
        ET.SubElement(rating_el, "value").text = f"{vote_avg:.3f}"

    for genre in getattr(show, "genres", []):
        ET.SubElement(root, "genre").text = genre

    gen_el = ET.SubElement(root, "generator")
    ET.SubElement(gen_el, "appname").text = "WarpMediaCenter"

    ET.indent(root, space="    ")
    try:
        with open(nfo_path, "w", encoding="utf-8") as f:
            f.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n')
            f.write(ET.tostring(root, encoding="unicode"))
            f.write("\n")
        log.info("tvshow_nfo_written", nfo=str(nfo_path))
    except OSError as exc:
        log.warning("tvshow_nfo_write_error", nfo=str(nfo_path), error=str(exc))


def _write_nfo_episode(
    file_path: Path,
    tmdb_id: str,
    title: Optional[str],
    season: int,
    episode: int,
    air_date: Optional[str],
) -> None:
    """Write a minimal episode .nfo sidecar co-located with the video file."""
    import xml.etree.ElementTree as ET

    nfo_path = file_path.with_suffix(".nfo")
    root = ET.Element("episodedetails")

    if title:
        ET.SubElement(root, "title").text = title
    ET.SubElement(root, "season").text = str(season)
    ET.SubElement(root, "episode").text = str(episode)
    if air_date:
        ET.SubElement(root, "aired").text = air_date

    uid = ET.SubElement(root, "uniqueid")
    uid.set("type", "tmdb")
    uid.set("default", "true")
    uid.text = tmdb_id

    gen_el = ET.SubElement(root, "generator")
    ET.SubElement(gen_el, "appname").text = "WarpMediaCenter"

    ET.indent(root, space="    ")
    try:
        with open(nfo_path, "w", encoding="utf-8") as f:
            f.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n')
            f.write(ET.tostring(root, encoding="unicode"))
            f.write("\n")
        log.info("episode_nfo_written", nfo=nfo_path.name)
    except OSError as exc:
        log.warning("episode_nfo_write_error", nfo=str(nfo_path), error=str(exc))


# ---------------------------------------------------------------------------
# Network-only "gather" functions — open NO database connections
# ---------------------------------------------------------------------------

def _gather_movie_data(
    providers: InformationProviders,
    file_path: Path,
    parsed: ParsedName,
    artwork_dir: Path,
) -> Optional[_MovieData]:
    nfo = _parse_nfo(file_path)

    # Fast path: NFO carries a TMDb ID — skip search, fetch details only.
    if nfo and nfo.tmdb_id:
        log.info("nfo_found", file=file_path.name, tmdb_id=nfo.tmdb_id)
        _ui_log(f"[NFO] {file_path.name} → tmdb:{nfo.tmdb_id}")
        movie = providers.movie_details(nfo.tmdb_id, include_credits=False)
        year = movie.release_date.year if movie.release_date else nfo.year or parsed.year
        poster_url = movie.poster.url if movie.poster else None
        backdrop_url = movie.backdrop.url if movie.backdrop else None
        poster_path, backdrop_path = download_artwork(poster_url, backdrop_url, artwork_dir)
        return _MovieData(
            tmdb_id=str(movie.id),
            title=movie.title,
            year=year,
            overview=movie.overview,
            poster_url=poster_url,
            backdrop_url=backdrop_url,
            poster_path=poster_path,
            backdrop_path=backdrop_path,
            rating=movie.vote_average,
            genres=list(movie.genres),
            premiered=movie.release_date.isoformat() if movie.release_date else None,
        )

    # No TMDb ID in NFO: prefer NFO title/year over guessit, but fall back.
    search_title = (nfo.title if nfo and nfo.title else None) or parsed.title
    search_year = (nfo.year if nfo and nfo.year else None) or parsed.year

    if nfo:
        log.info("nfo_found_no_id", file=file_path.name, title=search_title, year=search_year)
        _ui_log(f"[NFO] {file_path.name} → title from NFO: '{search_title}'")
    else:
        log.info("nfo_not_found", file=file_path.name, title=search_title, year=search_year)
        _ui_log(f"[Search] '{search_title}' ({search_year or '?'})")

    log.info("tmdb_lookup", title=search_title, year=search_year, media_type="movie")
    results = providers.search_movies(search_title) or []
    catalog = _select_catalog_match(results, search_year)
    if catalog is None:
        log.info("tmdb_no_match", title=search_title, year=search_year, media_type="movie")
        _ui_log(f"[Skip] '{search_title}' — no TMDb match")
        return None

    catalog_title = getattr(catalog, "title", "") or ""
    if not _titles_similar(search_title, catalog_title):
        log.info("tmdb_title_mismatch", search=search_title, result=catalog_title)
        _ui_log(f"[Skip] '{search_title}' — TMDb match '{catalog_title}' is too different")
        return None

    movie = providers.movie_details(catalog.id, include_credits=False)
    year = movie.release_date.year if movie.release_date else search_year or catalog.year
    poster_url = movie.poster.url if movie.poster else None
    backdrop_url = movie.backdrop.url if movie.backdrop else None
    poster_path, backdrop_path = download_artwork(poster_url, backdrop_url, artwork_dir)
    data = _MovieData(
        tmdb_id=str(movie.id),
        title=movie.title,
        year=year,
        overview=movie.overview,
        poster_url=poster_url,
        backdrop_url=backdrop_url,
        poster_path=poster_path,
        backdrop_path=backdrop_path,
        rating=movie.vote_average,
        genres=list(movie.genres),
        premiered=movie.release_date.isoformat() if movie.release_date else None,
    )
    # Write a sidecar so future re-scans skip the TMDb API call entirely.
    _write_nfo_movie(file_path, data)
    return data


def _gather_episode_data(
    providers: InformationProviders,
    file_path: Path,
    parsed: ParsedName,
    artwork_dir: Path,
    show_cache: Dict[str, tuple[Optional[int], Show]],
) -> Optional[_EpisodeData]:
    # Parse both NFOs upfront — episode NFO can supply season/episode when
    # guessit couldn't extract them from the filename.
    show_nfo = _parse_tvshow_nfo(file_path)   # tvshow.nfo in show root
    ep_nfo = _parse_episode_nfo(file_path)     # SxxExx.nfo alongside video

    season_num = parsed.season if parsed.season is not None else (ep_nfo.season if ep_nfo else None)
    episode_num = parsed.episode if parsed.episode is not None else (ep_nfo.episode if ep_nfo else None)
    if season_num is None or episode_num is None:
        return None

    tvshow_nfo_absent = show_nfo is None  # used to decide whether to write tvshow.nfo
    ep_nfo_absent = ep_nfo is None        # used to decide whether to write episode NFO

    # ---------- Determine show_id ----------
    if show_nfo and show_nfo.tmdb_id:
        log.info("tvshow_nfo_found", file=file_path.name, tmdb_id=show_nfo.tmdb_id)
        _ui_log(f"[NFO] Show → tmdb:{show_nfo.tmdb_id}")
        show_id = show_nfo.tmdb_id
    else:
        # Prefer NFO title → show-root folder name → parsed (episode) title.
        # Using the episode title (e.g. "A Scandal in Bohemia") as the show
        # search term almost never produces a correct TMDb show match.
        nfo_title = show_nfo.title if show_nfo and show_nfo.title else None
        folder_title = _show_root(file_path).name  # e.g. "Sherlock Holmes (1984)"
        search_title = nfo_title or folder_title or parsed.title
        search_year = (show_nfo.year if show_nfo and show_nfo.year else None) or parsed.year

        if show_nfo:
            log.info("tvshow_nfo_no_id", file=file_path.name, title=search_title)
            _ui_log(f"[NFO] {file_path.name} → title from NFO: '{search_title}'")
        else:
            log.info("tvshow_nfo_absent", file=file_path.name, title=search_title, year=search_year)
            _ui_log(f"[Search] '{search_title}' ({search_year or '?'})")

        log.info("tmdb_lookup", title=search_title, year=search_year, media_type="show")
        results = providers.search_shows(search_title) or []
        catalog = _select_catalog_match(results, search_year)
        if catalog is None:
            log.info("tmdb_no_match", title=search_title, year=search_year, media_type="show")
            _ui_log(f"[Skip] '{search_title}' — no TMDb match")
            return None

        catalog_title = getattr(catalog, "title", "") or ""
        if not _titles_similar(search_title, catalog_title):
            log.info("tmdb_title_mismatch", search=search_title, result=catalog_title)
            _ui_log(f"[Skip] '{search_title}' — TMDb match '{catalog_title}' is too different")
            return None

        show_id = str(catalog.id)

    # ---------- Fetch/cache show details ----------
    cached = show_cache.get(show_id)
    if cached is None:
        show = providers.show_details(show_id, include_credits=False)
        first_air_year = show.first_air_date.year if show.first_air_date else parsed.year
        poster_url = show.poster.url if show.poster else None
        backdrop_url = show.backdrop.url if show.backdrop else None
        poster_path, backdrop_path = download_artwork(poster_url, backdrop_url, artwork_dir)
        show_cache[show_id] = (None, show)
        if tvshow_nfo_absent:
            _write_nfo_show(file_path, show, show_id)
    else:
        _, show = cached
        first_air_year = show.first_air_date.year if show.first_air_date else parsed.year
        poster_url = show.poster.url if show.poster else None
        backdrop_url = show.backdrop.url if show.backdrop else None
        poster_path = None
        backdrop_path = None

    # ---------- Get episode data ----------
    # Fast path: episode NFO already has tmdb_id + season + episode — skip API call.
    can_use_ep_nfo = (
        ep_nfo is not None
        and ep_nfo.tmdb_id is not None
        and ep_nfo.season is not None
        and ep_nfo.episode is not None
    )
    if can_use_ep_nfo:
        log.info("episode_nfo_found", file=file_path.name, tmdb_id=ep_nfo.tmdb_id)
        _ui_log(
            f"[NFO] {file_path.name} → "
            f"S{ep_nfo.season:02d}E{ep_nfo.episode:02d} tmdb:{ep_nfo.tmdb_id}"
        )
        episode_tmdb_id = ep_nfo.tmdb_id
        episode_name = ep_nfo.title
        air_date = ep_nfo.air_date
        season_num = ep_nfo.season
        episode_num = ep_nfo.episode
    else:
        ep_detail = providers.tmdb.episode_details(
            show_id, season_num, episode_num, include_credits=False
        )
        episode_tmdb_id = str(ep_detail.id)
        episode_name = ep_detail.title
        air_date = ep_detail.air_date.isoformat() if ep_detail.air_date else None
        if ep_nfo_absent:
            _write_nfo_episode(file_path, episode_tmdb_id, episode_name, season_num, episode_num, air_date)

    return _EpisodeData(
        show_tmdb_id=show_id,
        show_title=show.title,
        show_year=first_air_year,
        show_overview=show.overview,
        show_poster_url=poster_url,
        show_backdrop_url=backdrop_url,
        show_poster_path=poster_path,
        show_backdrop_path=backdrop_path,
        episode_tmdb_id=episode_tmdb_id,
        season=season_num,
        episode=episode_num,
        episode_name=episode_name,
        air_date=air_date,
    )


# ---------------------------------------------------------------------------
# DB-only "write" functions — do NO network I/O
# ---------------------------------------------------------------------------

def _write_movie(conn, data: _MovieData, file_path: Path, file_meta: _FileMeta, file_hash: Optional[str]) -> None:
    log.info("db_upsert", type="movie", title=data.title, year=data.year, tmdb_id=data.tmdb_id, file=file_path.name)
    _ui_log(f"[Saved] {data.title} ({data.year}) [movie]")
    title_id = upsert_title(
        conn,
        tmdb_id=data.tmdb_id,
        type=MediaType.MOVIE.value,
        title=data.title,
        year=data.year,
        overview=data.overview,
        poster_url=data.poster_url,
        backdrop_url=data.backdrop_url,
    )
    update_title_artwork_paths(
        conn,
        title_id,
        poster_path=str(data.poster_path) if data.poster_path else None,
        backdrop_path=str(data.backdrop_path) if data.backdrop_path else None,
    )
    # Skip adding a duplicate source record when the same file content is
    # already registered under a different path (e.g. the movie exists in two
    # library folders).  The title still gets upserted above so it remains
    # discoverable; we just avoid polluting sources with redundant entries.
    if file_hash:
        dupes = find_duplicate_sources(conn, file_hash)
        existing_paths = [d["file_path"] for d in dupes]
        if any(p != str(file_path) for p in existing_paths):
            log.info("library_duplicate_skipped", path=str(file_path), hash=file_hash)
            _ui_log(f"[Duplicate] {file_path.name} — same content already in library")
            return
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


def _write_episode(
    conn,
    data: _EpisodeData,
    file_path: Path,
    file_meta: _FileMeta,
    file_hash: Optional[str],
    show_cache: Dict[str, tuple[Optional[int], Show]],
) -> None:
    log.info(
        "db_upsert",
        type="episode",
        show=data.show_title,
        season=data.season,
        episode=data.episode,
        tmdb_id=data.show_tmdb_id,
        file=file_path.name,
    )
    _ui_log(f"[Saved] {data.show_title} S{data.season:02d}E{data.episode:02d} [episode]")
    title_id = upsert_title(
        conn,
        tmdb_id=data.show_tmdb_id,
        type=MediaType.SHOW.value,
        title=data.show_title,
        year=data.show_year,
        overview=data.show_overview,
        poster_url=data.show_poster_url,
        backdrop_url=data.show_backdrop_url,
    )
    if data.show_poster_path or data.show_backdrop_path:
        update_title_artwork_paths(
            conn,
            title_id,
            poster_path=str(data.show_poster_path) if data.show_poster_path else None,
            backdrop_path=str(data.show_backdrop_path) if data.show_backdrop_path else None,
        )
    # Update show_cache with the resolved title_id for this worker
    cached = show_cache.get(data.show_tmdb_id)
    if cached is not None:
        show_cache[data.show_tmdb_id] = (title_id, cached[1])

    upsert_episode(
        conn,
        tmdb_id=data.episode_tmdb_id,
        title_id=title_id,
        season=data.season,
        episode=data.episode,
        name=data.episode_name,
        air_date=data.air_date,
    )
    if file_hash:
        dupes = find_duplicate_sources(conn, file_hash)
        existing_paths = [d["file_path"] for d in dupes]
        if any(p != str(file_path) for p in existing_paths):
            log.info("library_duplicate_skipped", path=str(file_path), hash=file_hash)
            _ui_log(f"[Duplicate] {file_path.name} — same content already in library")
            return
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


def _select_catalog_match(results: Sequence, year: Optional[int]) -> Optional:
    if not results:
        return None
    if year is not None:
        # Pass 1: exact year
        for candidate in results:
            try:
                if getattr(candidate, "year", None) == year:
                    return candidate
            except Exception:
                continue
        # Pass 2: ±1 year tolerance
        for candidate in results:
            try:
                candidate_year = getattr(candidate, "year", None)
                if candidate_year and abs(int(candidate_year) - year) <= 1:
                    return candidate
            except (TypeError, ValueError):
                continue
        # Year is known but nothing matched — reject rather than silently
        # accepting results[0], which is often the most-popular film with a
        # completely different release year.
        return None
    return results[0]


def _titles_similar(search: str, result: str) -> bool:
    """True when *result* is a plausible TMDb match for *search*.

    Rejects cases like "Once" → "Once Upon a Time in America" where the search
    title is a short prefix of a much longer result title.
    """
    import unicodedata

    def _words(s: str) -> set:
        s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
        return {w for w in re.sub(r"[^\w\s]", " ", s.lower()).split() if w}

    a = _words(search)
    b = _words(result)
    if not a or not b:
        return False
    overlap = a & b
    # Require ≥80 % of the search words to appear in the result
    if len(overlap) / len(a) < 0.8:
        return False
    # Reject when result is more than 3× longer in word count than search
    if len(b) > len(a) * 3:
        return False
    return True


def _process_file(
    file_path: Path,
    providers: InformationProviders,
    artwork_dir: Path,
    show_cache: Dict[str, tuple[Optional[int], Show]],
    cancel_event: Optional[threading.Event] = None,
    incremental: bool = True,
) -> Dict[str, int]:
    """Process a single media file. Returns a summary dict.

    Structured in three phases so DB connections are never held during network I/O:
      1. Brief DB read  — check whether the file has changed.
      2. Network phase  — TMDb lookups + artwork download (no connection open).
      3. Brief DB write — persist gathered data (no network I/O inside).
    """
    _zero = {"total": 0, "skipped": 0, "matched": 0, "unmatched": 0, "error": 0, "duplicate": 0}
    if cancel_event and cancel_event.is_set():
        return _zero

    result = {"total": 1, "skipped": 0, "matched": 0, "unmatched": 0, "error": 0, "duplicate": 0}

    # Phase 1: quick read — is this file new or changed?
    with db_connection() as conn:
        stored_meta = get_source_metadata(conn, str(file_path))

    if cancel_event and cancel_event.is_set():
        return _zero

    if incremental and not _file_changed(file_path, stored_meta):
        result["skipped"] = 1
        return result

    parsed = parse_media_name(file_path)
    if parsed is None:
        result["unmatched"] = 1
        return result

    try:
        file_meta = _get_file_meta(file_path)
        file_hash = _compute_file_hash(file_path)

        # Phase 2: network — no DB connection held here
        if cancel_event and cancel_event.is_set():
            return _zero
        if parsed.media_type == MediaType.MOVIE:
            data = _gather_movie_data(providers, file_path, parsed, artwork_dir)
        else:
            data = _gather_episode_data(providers, file_path, parsed, artwork_dir, show_cache)

        if data is None:
            result["unmatched"] = 1
            return result

        # Phase 3: write — brief DB connection, zero network I/O
        with db_connection() as conn:
            if isinstance(data, _MovieData):
                _write_movie(conn, data, file_path, file_meta, file_hash)
            else:
                _write_episode(conn, data, file_path, file_meta, file_hash, show_cache)

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
    cancel_event: Optional[threading.Event] = None,
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
            scan_root_strs = [str(p) for p in normalized_paths]
            removed = mark_sources_missing(conn, known_paths, scan_roots=scan_root_strs)
            if removed:
                log.info("library_scan_marked_missing", count=removed)

    show_cache: Dict[str, tuple[Optional[int], Show]] = {}
    result = ScanResult()
    total_files = len(media_files)
    _report_progress(0, total_files)

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
                        args=(file_path, providers, artwork_dir, show_cache, cancel_event, incremental),
                        name=f"scan_{file_path.name}",
                        estimated_memory_mb=64.0,
                    )
                )
                futures.append(fut)

            files_done = 0
            for fut in futures:
                if cancel_event and cancel_event.is_set():
                    fut.cancel()
                files_done += 1
                _report_progress(files_done, total_files)
                if cancel_event and cancel_event.is_set():
                    continue
                try:
                    file_result = fut.result(timeout=120)
                    result.total += file_result["total"]
                    result.skipped_unchanged += file_result["skipped"]
                    result.matched += file_result["matched"]
                    result.unmatched += file_result["unmatched"]
                    result.errors += file_result["error"]
                except concurrent.futures.CancelledError:
                    pass
                except Exception as exc:
                    log.warning("library_scan_future_error", error=str(exc))
                    result.errors += 1
    else:
        for i, file_path in enumerate(media_files):
            if cancel_event and cancel_event.is_set():
                break
            file_result = _process_file(file_path, providers, artwork_dir, show_cache, cancel_event, incremental)
            result.total += file_result["total"]
            result.skipped_unchanged += file_result["skipped"]
            result.matched += file_result["matched"]
            result.unmatched += file_result["unmatched"]
            result.errors += file_result["error"]
            _report_progress(i + 1, total_files)

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
