"""Utilities to discover and enrich a user's local media library."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Iterable, List, Mapping, Optional, Sequence
import json
import re
import threading

import requests

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.common.tasks import TaskRunner, TaskSpec
from warp_mediacenter.backend.information_handlers.models import ImageAsset, MediaType, Movie, Season, Show
from warp_mediacenter.backend.information_handlers.providers import InformationProviders
from warp_mediacenter.backend.resource_management import get_resource_manager
from warp_mediacenter.config.settings import (
    Settings,
    get_settings,
    load_library_index,
    save_library_index,
    update_library_path,
)

log = get_logger(__name__)

_VIDEO_EXTENSIONS = {
    ".avi",
    ".mkv",
    ".mp4",
    ".mov",
    ".mpg",
    ".mpeg",
    ".wmv",
    ".flv",
    ".m4v",
    ".ts",
    ".m2ts",
    ".webm",
}

_TITLE_SANITIZE_RE = re.compile(r"[._]+")
_EPISODE_TAG_RE = re.compile(r"s\d{1,2}e\d{1,2}", re.IGNORECASE)
_YEAR_SUFFIX_RE = re.compile(r"\b(19|20)\d{2}\b")


@dataclass
class LibraryItem:
    """Simple value object representing an indexed library entry."""

    path: Path
    title: str
    media_type: MediaType
    metadata_file: Path
    poster_path: Optional[Path] = None
    backdrop_path: Optional[Path] = None
    trailer_urls: Sequence[str] = field(default_factory=list)
    tmdb_id: Optional[str] = None
    last_scanned: datetime = field(default_factory=lambda: datetime.utcnow().replace(microsecond=0))

    def to_index_payload(self) -> Dict[str, Any]:
        return {
            "title": self.title,
            "path": str(self.path),
            "media_type": self.media_type.value,
            "metadata_file": str(self.metadata_file),
            "poster_path": str(self.poster_path) if self.poster_path else None,
            "backdrop_path": str(self.backdrop_path) if self.backdrop_path else None,
            "trailer_urls": list(self.trailer_urls),
            "tmdb_id": self.tmdb_id,
            "last_scanned": self.last_scanned.isoformat() + "Z",
        }


class LocalLibraryScanner:
    """Coordinates filesystem discovery and TMDb enrichment for local media."""

    def __init__(
        self,
        *,
        settings: Optional[Settings] = None,
        providers: Optional[InformationProviders] = None,
    ) -> None:
        self._settings = settings or get_settings()
        self._providers = providers or InformationProviders()
        self._index = load_library_index()
        self._index_lock = threading.Lock()
        self._resource_manager = get_resource_manager()

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------
    def scan(self, root: Path, media_type: MediaType, *, refresh: bool = False) -> Sequence[LibraryItem]:
        root = root.expanduser().resolve()
        if not root.exists() or not root.is_dir():
            raise ValueError(f"Library root '{root}' does not exist or is not a directory")

        entries = list(self._discover_entries(root, media_type))
        results: list[LibraryItem] = []
        if not entries:
            log.info("library_scan_empty", root=str(root), media_type=media_type.value)
            return results

        context = f"library_scan_{media_type.value}"
        with TaskRunner(
            max_workers=self._settings.task_workers,
            resource_manager=self._resource_manager,
            estimated_task_memory_mb=512.0,
            context=context,
            resource_wait_timeout=90.0,
        ) as runner:
        with TaskRunner(max_workers=self._settings.task_workers) as runner:
            futures = [
                runner.submit(
                    TaskSpec(
                        fn=self._process_entry,
                        args=(entry, media_type, refresh),
                        name=f"library_scan_{media_type.value}_{entry.name}",
                        estimated_memory_mb=512.0,
                    )
                )
                for entry in entries
            ]

            for future in futures:
                try:
                    item = future.result()
                except Exception as exc:  # noqa: BLE001 - log and continue
                    log.error(
                        "library_scan_failed",
                        error=str(exc),
                        media_type=media_type.value,
                    )
                    continue

                if item is not None:
                    results.append(item)

        save_library_index(self._index)

        return results

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _process_entry(self, entry: Path, media_type: MediaType, refresh: bool) -> Optional[LibraryItem]:
        if media_type == MediaType.MOVIE:
            return self._process_movie(entry, refresh=refresh)
        if media_type == MediaType.SHOW:
            return self._process_show(entry, refresh=refresh)
        raise ValueError(f"Unsupported media type: {media_type}")

    def _discover_entries(self, root: Path, media_type: MediaType) -> Iterable[Path]:
        if media_type == MediaType.MOVIE:
            yield from self._discover_movie_entries(root)
        elif media_type == MediaType.SHOW:
            yield from self._discover_show_entries(root)
        else:
            return []

    def _discover_movie_entries(self, root: Path) -> Iterable[Path]:
        seen: set[Path] = set()
        for path in root.rglob("*"):
            if path.is_file() and path.suffix.lower() in _VIDEO_EXTENSIONS:
                parent = path.parent
                if parent not in seen:
                    seen.add(parent)
                    yield parent
            elif path.is_dir():
                if self._contains_video(path) and path not in seen:
                    seen.add(path)
                    yield path

    def _discover_show_entries(self, root: Path) -> Iterable[Path]:
        shows: dict[Path, None] = {}
        for file in root.rglob("*"):
            if file.is_file() and file.suffix.lower() in _VIDEO_EXTENSIONS:
                try:
                    rel = file.relative_to(root)
                except ValueError:
                    continue
                if not rel.parts:
                    continue
                show_dir = root / rel.parts[0]
                shows.setdefault(show_dir, None)
        return shows.keys()

    def _contains_video(self, directory: Path) -> bool:
        for child in directory.iterdir():
            if child.is_file() and child.suffix.lower() in _VIDEO_EXTENSIONS:
                return True
        return False

    def _process_movie(self, container: Path, *, refresh: bool) -> Optional[LibraryItem]:
        self._resource_manager.wait_for_headroom(
            256.0,
            context="library_movie_prepare",
            timeout=90.0,
        )
        metadata_file = container / "warp_metadata.json"
        if metadata_file.exists() and not refresh:
            existing = self._load_existing_item(metadata_file, MediaType.MOVIE)
            if existing:
                self._store_index(existing)
                return existing

        title = self._infer_title(container)
        if not title:
            log.debug("movie_title_unresolved", path=str(container))
            return None

        movie: Optional[Movie] = None
        poster_path: Optional[Path] = None
        backdrop_path: Optional[Path] = None
        trailer_urls: list[str] = []
        tmdb_id: Optional[str] = None

        try:
            candidates = self._providers.tmdb.search_movies(title)
            if candidates:
                tmdb_id = candidates[0].id
                movie = self._providers.tmdb.movie_details(candidates[0].id)
                poster_path = self._download_asset(movie.poster, container, "poster", refresh=refresh)
                backdrop_path = self._download_asset(movie.backdrop, container, "backdrop", refresh=refresh)
                trailer_urls = self._extract_trailer_urls(MediaType.MOVIE, tmdb_id)
        except Exception as exc:  # noqa: BLE001
            log.warning("movie_lookup_failed", title=title, error=str(exc))

        metadata = self._build_metadata_payload(
            container=container,
            media_type=MediaType.MOVIE,
            title=title,
            tmdb_id=tmdb_id,
            details=movie.model_dump(mode="json") if movie else None,
            poster=poster_path,
            backdrop=backdrop_path,
            trailer_urls=trailer_urls,
            local_files=self._collect_local_files(container),
        )
        self._write_metadata(metadata_file, metadata)

        item = LibraryItem(
            path=container,
            title=title,
            media_type=MediaType.MOVIE,
            metadata_file=metadata_file,
            poster_path=poster_path,
            backdrop_path=backdrop_path,
            trailer_urls=trailer_urls,
            tmdb_id=tmdb_id,
        )
        self._store_index(item)

        return item

    def _process_show(self, show_dir: Path, *, refresh: bool) -> Optional[LibraryItem]:
        self._resource_manager.wait_for_headroom(
            384.0,
            context="library_show_prepare",
            timeout=90.0,
        )
        metadata_file = show_dir / "warp_metadata.json"
        if metadata_file.exists() and not refresh:
            existing = self._load_existing_item(metadata_file, MediaType.SHOW)
            if existing:
                self._store_index(existing)
                return existing

        title = self._infer_title(show_dir)
        if not title:
            log.debug("show_title_unresolved", path=str(show_dir))
            return None

        show: Optional[Show] = None
        seasons_payload: list[Mapping[str, Any]] = []
        poster_path: Optional[Path] = None
        backdrop_path: Optional[Path] = None
        trailer_urls: list[str] = []
        tmdb_id: Optional[str] = None

        try:
            candidates = self._providers.tmdb.search_shows(title)
            if candidates:
                tmdb_id = candidates[0].id
                show = self._providers.tmdb.show_details(candidates[0].id)
                poster_path = self._download_asset(show.poster, show_dir, "poster", refresh=refresh)
                backdrop_path = self._download_asset(show.backdrop, show_dir, "backdrop", refresh=refresh)
                trailer_urls = self._extract_trailer_urls(MediaType.SHOW, tmdb_id)

                local_seasons = self._collect_season_numbers(show_dir)
                for season_number in sorted(local_seasons):
                    try:
                        season = self._providers.tmdb.season_details(tmdb_id, season_number)
                    except Exception as exc:  # noqa: BLE001
                        log.warning(
                            "season_lookup_failed",
                            show=title,
                            season=season_number,
                            error=str(exc),
                        )
                        continue
                    seasons_payload.append(self._prepare_season_payload(show_dir, season, refresh=refresh))
        except Exception as exc:  # noqa: BLE001
            log.warning("show_lookup_failed", title=title, error=str(exc))

        metadata = self._build_metadata_payload(
            container=show_dir,
            media_type=MediaType.SHOW,
            title=title,
            tmdb_id=tmdb_id,
            details=show.model_dump(mode="json") if show else None,
            poster=poster_path,
            backdrop=backdrop_path,
            trailer_urls=trailer_urls,
            local_files=self._collect_local_files(show_dir),
            seasons=seasons_payload,
        )
        self._write_metadata(metadata_file, metadata)

        item = LibraryItem(
            path=show_dir,
            title=title,
            media_type=MediaType.SHOW,
            metadata_file=metadata_file,
            poster_path=poster_path,
            backdrop_path=backdrop_path,
            trailer_urls=trailer_urls,
            tmdb_id=tmdb_id,
        )
        self._store_index(item)

        return item

    def _load_existing_item(self, metadata_file: Path, media_type: MediaType) -> Optional[LibraryItem]:
        try:
            with metadata_file.open("r", encoding="utf-8") as fh:
                payload = json.load(fh)
        except Exception:
            return None

        title = payload.get("title") or metadata_file.parent.name
        poster = payload.get("poster", {}) if isinstance(payload.get("poster"), Mapping) else {}
        backdrop = payload.get("backdrop", {}) if isinstance(payload.get("backdrop"), Mapping) else {}
        trailer_urls = payload.get("trailer_urls") or payload.get("trailers") or []
        if isinstance(trailer_urls, str):
            trailer_urls = [trailer_urls]

        last_scanned_raw = payload.get("last_scanned")
        try:
            last_scanned = datetime.fromisoformat(last_scanned_raw.rstrip("Z")) if last_scanned_raw else datetime.utcnow()
        except Exception:
            last_scanned = datetime.utcnow()

        poster_path = self._resolve_relative(metadata_file.parent, poster.get("path"))
        backdrop_path = self._resolve_relative(metadata_file.parent, backdrop.get("path"))
        tmdb_id = payload.get("tmdb_id")

        return LibraryItem(
            path=metadata_file.parent,
            title=title,
            media_type=media_type,
            metadata_file=metadata_file,
            poster_path=poster_path,
            backdrop_path=backdrop_path,
            trailer_urls=list(trailer_urls) if isinstance(trailer_urls, list) else [],
            tmdb_id=tmdb_id,
            last_scanned=last_scanned,
        )

    def _store_index(self, item: LibraryItem) -> None:
        bucket_key = "movies" if item.media_type == MediaType.MOVIE else "shows"
        with self._index_lock:
            bucket = self._index.setdefault(bucket_key, {})
            bucket[str(item.path)] = item.to_index_payload()

    def _collect_local_files(self, root: Path) -> Sequence[str]:
        files: List[str] = []
        for file in root.rglob("*"):
            if file.is_file() and file.suffix.lower() in _VIDEO_EXTENSIONS:
                try:
                    files.append(str(file.relative_to(root)))
                except ValueError:
                    files.append(str(file))
        return sorted(set(files))

    def _collect_season_numbers(self, show_dir: Path) -> Sequence[int]:
        seasons: set[int] = set()
        for file in show_dir.rglob("*"):
            if not (file.is_file() and file.suffix.lower() in _VIDEO_EXTENSIONS):
                continue
            try:
                rel = file.relative_to(show_dir)
            except ValueError:
                continue
            parts = rel.parts
            if len(parts) >= 2:
                season_text = parts[0]
            else:
                season_text = file.stem

            match = re.search(r"(season|s)(\s*)?(\d{1,2})", season_text, re.IGNORECASE)
            if match:
                try:
                    seasons.add(int(match.group(3)))
                    continue
                except ValueError:
                    pass
            episode_match = re.search(r"s(\d{1,2})e\d{1,2}", file.stem, re.IGNORECASE)
            if episode_match:
                try:
                    seasons.add(int(episode_match.group(1)))
                except ValueError:
                    continue
        return sorted(seasons)

    def _infer_title(self, entry: Path) -> str:
        name = entry.name if entry.is_dir() else entry.stem
        name = _TITLE_SANITIZE_RE.sub(" ", name)
        name = _EPISODE_TAG_RE.sub("", name)
        name = self._strip_year_suffix(name)
        return name.strip()

    def _strip_year_suffix(self, value: str) -> str:
        parts = value.split()
        if parts and _YEAR_SUFFIX_RE.fullmatch(parts[-1]):
            parts = parts[:-1]
        return " ".join(parts)

    def _download_asset(
        self,
        asset: Optional[ImageAsset],
        root: Path,
        name_hint: str,
        *,
        refresh: bool,
    ) -> Optional[Path]:
        if asset is None or not asset.url:
            return None

        suffix = Path(asset.url).suffix or ".jpg"
        destination = root / f"{name_hint}{suffix}"
        if destination.exists() and not refresh:
            return destination

        try:
            response = requests.get(asset.url, timeout=30)
            response.raise_for_status()
        except Exception as exc:  # noqa: BLE001
            log.warning("asset_download_failed", url=asset.url, error=str(exc))
            return None

        try:
            with destination.open("wb") as fh:
                fh.write(response.content)
        except Exception as exc:  # noqa: BLE001
            log.error("asset_write_failed", path=str(destination), error=str(exc))
            return None

        return destination

    def _extract_trailer_urls(self, media_type: MediaType, tmdb_id: Optional[str]) -> list[str]:
        if not tmdb_id:
            return []

        try:
            videos = self._providers.tmdb.get_videos(media_type, tmdb_id)
        except Exception as exc:  # noqa: BLE001
            log.warning("videos_lookup_failed", media_type=media_type.value, error=str(exc))
            return []

        urls: list[str] = []
        for video in videos:
            if not isinstance(video, Mapping):
                continue
            if video.get("type") not in {"Trailer", "Teaser"}:
                continue
            site = (video.get("site") or "").lower()
            key = video.get("key")
            if site == "youtube" and key:
                urls.append(f"https://www.youtube.com/watch?v={key}")
            elif video.get("url"):
                urls.append(str(video["url"]))
        return urls

    def _prepare_season_payload(self, show_dir: Path, season: Season, *, refresh: bool) -> Mapping[str, Any]:
        payload = season.model_dump(mode="json")
        poster_path = self._download_asset(
            season.poster,
            show_dir,
            f"season_{season.season_number}_poster",
            refresh=refresh,
        )
        payload["poster_local_path"] = (
            self._relative_path(show_dir, poster_path)
            if poster_path is not None
            else None
        )
        return payload

    def _build_metadata_payload(
        self,
        *,
        container: Path,
        media_type: MediaType,
        title: str,
        tmdb_id: Optional[str],
        details: Optional[Mapping[str, Any]],
        poster: Optional[Path],
        backdrop: Optional[Path],
        trailer_urls: Sequence[str],
        local_files: Sequence[str],
        seasons: Optional[Sequence[Mapping[str, Any]]] = None,
    ) -> Dict[str, Any]:
        metadata: Dict[str, Any] = {
            "title": title,
            "media_type": media_type.value,
            "tmdb_id": tmdb_id,
            "local_files": list(local_files),
            "trailer_urls": list(trailer_urls),
            "last_scanned": datetime.utcnow().replace(microsecond=0).isoformat() + "Z",
        }
        if details is not None:
            metadata["details"] = details
        poster_url = None
        backdrop_url = None
        if isinstance(details, Mapping):
            poster_payload = details.get("poster")
            if isinstance(poster_payload, Mapping):
                poster_url = poster_payload.get("url")
            backdrop_payload = details.get("backdrop")
            if isinstance(backdrop_payload, Mapping):
                backdrop_url = backdrop_payload.get("url")

        if poster:
            metadata["poster"] = {
                "path": self._relative_path(container, poster),
                "url": poster_url,
            }
        if backdrop:
            metadata["backdrop"] = {
                "path": self._relative_path(container, backdrop),
                "url": backdrop_url,
            }
        if seasons is not None:
            metadata["seasons"] = list(seasons)
        return metadata

    def _write_metadata(self, path: Path, payload: Mapping[str, Any]) -> None:
        try:
            with path.open("w", encoding="utf-8") as fh:
                json.dump(payload, fh, indent=2, ensure_ascii=False)
        except Exception as exc:  # noqa: BLE001
            log.error("metadata_write_failed", path=str(path), error=str(exc))

    def _resolve_relative(self, base: Path, value: Optional[str]) -> Optional[Path]:
        if not value:
            return None
        candidate = Path(value)
        if not candidate.is_absolute():
            candidate = base / candidate
        return candidate

    def _relative_path(self, base: Path, target: Path) -> str:
        try:
            return str(target.relative_to(base))
        except ValueError:
            return str(target)


def scan_to_library(path: str, media_kind: str, *, refresh: bool = False) -> Sequence[LibraryItem]:
    """Entry point invoked by the UI when a folder should be scanned."""

    normalized = media_kind.lower()
    if normalized in {"movies", "movie"}:
        media_type = MediaType.MOVIE
    elif normalized in {"shows", "show", "tv", "tv_shows", "tv_show"}:
        media_type = MediaType.SHOW
    else:
        raise ValueError(f"Unsupported media kind '{media_kind}'")

    settings = update_library_path(media_type.value, path)
    scanner = LocalLibraryScanner(settings=settings)

    return scanner.scan(Path(settings.library_path(media_type.value) or path), media_type, refresh=refresh)


__all__ = ["LocalLibraryScanner", "scan_to_library", "LibraryItem"]
