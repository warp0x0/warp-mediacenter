from __future__ import annotations

"""High-level subtitle discovery and download orchestration."""

from concurrent.futures import Future
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Optional
import gzip
import tempfile
import zipfile
import io

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.common.tasks import TaskRunner, TaskSpec
from warp_mediacenter.backend.player.exceptions import (
    SubtitleDownloadError,
    SubtitleError,
)
from warp_mediacenter.backend.player.subtitles.models import (
    PREFERRED_EXTENSIONS,
    SubtitlePayload,
    SubtitleQuery,
    SubtitleResult,
    pick_best_subtitle_file,
)
from warp_mediacenter.backend.player.subtitles.ranking import parse_release, ranked
from warp_mediacenter.backend.player.subtitles.providers.base import SubtitleProvider
from warp_mediacenter.backend.player.subtitles.providers.opensubtitles_com import OpenSubtitlesComProvider
from warp_mediacenter.backend.player.subtitles.providers.subdl import SubDLProvider
from warp_mediacenter.backend.player.subtitles.providers.subsource import SubSourceProvider
from warp_mediacenter.backend.player.subtitles.providers.subliminal_provider import SubliminalProvider
from warp_mediacenter.backend.resource_management import get_resource_manager

log = get_logger(__name__)


@dataclass(slots=True)
class SubtitleDownload:
    path: Path
    provider: str
    language: str


class SubtitleService:
    """Coordinates subtitle providers and handles extraction/cleanup."""

    def __init__(
        self,
        task_runner: Optional[TaskRunner] = None,
        providers: Optional[Iterable[SubtitleProvider]] = None,
        temp_dir: Optional[Path] = None,
    ) -> None:
        self._task_runner = task_runner or TaskRunner(
            max_workers=4,
            resource_manager=get_resource_manager(),
            estimated_task_memory_mb=64.0,
            context="subtitle_service",
            resource_wait_timeout=20.0,
        )
        self._providers = list(providers) if providers else self._default_providers()
        self._provider_map = {p.name: p for p in self._providers}
        self._temp_dir = temp_dir or Path(tempfile.gettempdir()) / "warp-mediacenter" / "subtitles"
        self._temp_dir.mkdir(parents=True, exist_ok=True)

    def _default_providers(self) -> List[SubtitleProvider]:
        return [
            SubliminalProvider(),
            SubDLProvider(),
            SubSourceProvider(),
            OpenSubtitlesComProvider(),
        ]

    def search(self, query: SubtitleQuery) -> List[SubtitleResult]:
        futures: List[Future] = []
        for provider in self._providers:
            if not provider.is_available_for(query.media_kind):
                continue
            futures.append(
                self._task_runner.submit(
                    TaskSpec(
                        fn=provider.search,
                        args=(query,),
                        retries=provider.retries,
                        backoff_sec=provider.backoff_sec,
                        name=f"subtitle_search_{provider.name}",
                        estimated_memory_mb=48.0,
                    )
                )
            )
        results: List[SubtitleResult] = []
        for future in futures:
            try:
                payload = future.result()
                if payload:
                    results.extend(payload)
            except Exception as exc:  # noqa: BLE001
                log.warning("subtitle_provider_failed", error=str(exc))
        results = self._filter_episode_results(query, results)
        subliminal_results = [item for item in results if item.provider == SubliminalProvider.name][: SubliminalProvider.max_results]
        ranked_results = ranked(query, [item for item in results if item.provider != SubliminalProvider.name])
        return subliminal_results + ranked_results

    def _filter_episode_results(self, query: SubtitleQuery, results: list[SubtitleResult]) -> list[SubtitleResult]:
        if query.media_kind != "show" or not (query.season or query.episode):
            return results
        filtered: list[SubtitleResult] = []
        for result in results:
            parsed = parse_release(result.release or result.file_name)
            season = self._int_or_none(result.metadata.get("season")) or parsed.get("season")
            episode = self._int_or_none(result.metadata.get("episode")) or parsed.get("episode")
            if query.season and season and int(season) != int(query.season):
                continue
            if query.episode and episode and int(episode) != int(query.episode):
                continue
            if self._has_conflicting_external_id(query, result):
                continue
            filtered.append(result)
        return filtered

    def _has_conflicting_external_id(self, query: SubtitleQuery, result: SubtitleResult) -> bool:
        expected_imdb = str(query.imdb_id or "").lower().removeprefix("tt")
        if expected_imdb:
            ids = {
                str(result.metadata.get("imdb_id") or "").lower().removeprefix("tt"),
                str(result.metadata.get("parent_imdb_id") or "").lower().removeprefix("tt"),
                str(result.metadata.get("series_imdb_id") or "").lower().removeprefix("tt"),
            }
            ids.discard("")
            if ids and expected_imdb not in ids:
                return True

        expected_tmdb = str(query.tmdb_id or "").strip()
        if expected_tmdb:
            ids = {
                str(result.metadata.get("tmdb_id") or "").strip(),
                str(result.metadata.get("parent_tmdb_id") or "").strip(),
                str(result.metadata.get("series_tmdb_id") or "").strip(),
            }
            ids.discard("")
            if ids and expected_tmdb not in ids:
                return True

        return False

    def _int_or_none(self, value: object) -> int | None:
        try:
            return int(value)  # type: ignore[arg-type]
        except (TypeError, ValueError):
            return None

    def download(self, result: SubtitleResult, destination: Optional[Path] = None) -> SubtitleDownload:
        provider = self._provider_map.get(result.provider)
        if not provider:
            raise SubtitleError(f"Unknown provider {result.provider}")
        payload = provider.download(result)
        dest_dir = destination or self._temp_dir
        dest_dir.mkdir(parents=True, exist_ok=True)
        path = self._write_payload(dest_dir, payload)
        return SubtitleDownload(path=path, provider=result.provider, language=result.language)

    def refresh_opensubtitles_token(self) -> dict[str, object]:
        provider = self._provider_map.get(OpenSubtitlesComProvider.name)
        if not isinstance(provider, OpenSubtitlesComProvider):
            provider = OpenSubtitlesComProvider()
            self._provider_map[provider.name] = provider
        return provider.refresh_token()

    def _write_payload(self, dest_dir: Path, payload: SubtitlePayload) -> Path:
        buffer = io.BytesIO(payload.content)
        if zipfile.is_zipfile(buffer):
            buffer.seek(0)
            return self._extract_zip_bytes(buffer, dest_dir)
        if payload.content.startswith(b"\x1f\x8b"):
            return self._extract_gzip_bytes(payload, dest_dir)
        target = dest_dir / payload.file_name
        target.write_bytes(payload.content)
        return target

    def _extract_gzip_bytes(self, payload: SubtitlePayload, dest_dir: Path) -> Path:
        file_name = payload.file_name
        if file_name.endswith(".gz"):
            file_name = file_name[:-3]
        if Path(file_name).suffix.lower() not in PREFERRED_EXTENSIONS:
            file_name = f"{Path(file_name).stem or 'subtitle'}.srt"
        target = dest_dir / file_name
        target.write_bytes(gzip.decompress(payload.content))
        return target

    def _extract_zip_bytes(self, buffer: io.BytesIO, dest_dir: Path) -> Path:
        with zipfile.ZipFile(buffer, "r") as zf:
            members = [Path(zf.extract(member, dest_dir)) for member in zf.namelist() if not member.endswith("/")]
        candidates = [p for p in members if p.suffix.lower() in PREFERRED_EXTENSIONS]
        if not candidates:
            candidates = members
        selected = pick_best_subtitle_file(candidates)
        if not selected:
            raise SubtitleDownloadError("Zip archive did not contain subtitle files")
        for member in members:
            if member != selected:
                try:
                    member.unlink()
                except OSError:
                    pass
        return selected

    def cleanup_temp(self) -> None:
        items = sorted(
            self._temp_dir.glob("**/*"),
            key=lambda item: len(item.relative_to(self._temp_dir).parts),
            reverse=True,
        )
        for item in items:
            try:
                if item.is_file():
                    item.unlink()
                elif item.is_dir():
                    item.rmdir()
            except OSError:
                log.debug("subtitle_cleanup_failed", path=str(item))
