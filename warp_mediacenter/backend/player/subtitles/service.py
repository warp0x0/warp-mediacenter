from __future__ import annotations

"""High-level subtitle discovery and download orchestration."""

from concurrent.futures import Future
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Optional
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
from warp_mediacenter.backend.player.subtitles.providers.base import SubtitleProvider
from warp_mediacenter.backend.player.subtitles.providers.opensubtitles import (
    OpenSubtitlesProvider,
)
from warp_mediacenter.backend.player.subtitles.providers.stub import (
    Addic7edProvider,
    BSPlayerProvider,
    PodnapisiProvider,
    SubsceneProvider,
)
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
        self._task_runner = task_runner or TaskRunner(max_workers=4)
        self._providers = list(providers) if providers else self._default_providers()
        self._provider_map = {p.name: p for p in self._providers}
        self._temp_dir = temp_dir or Path(tempfile.gettempdir()) / "warp-mediacenter" / "subtitles"
        self._temp_dir.mkdir(parents=True, exist_ok=True)

    def _default_providers(self) -> List[SubtitleProvider]:
        providers: List[SubtitleProvider] = [
            OpenSubtitlesProvider.from_settings(),
            PodnapisiProvider(),
            BSPlayerProvider(),
            SubsceneProvider(),
            Addic7edProvider(),
        ]
        return providers

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
        results.sort(key=lambda r: (-r.score, r.provider))
        return results

    def download(self, result: SubtitleResult, destination: Optional[Path] = None) -> SubtitleDownload:
        provider = self._provider_map.get(result.provider)
        if not provider:
            raise SubtitleError(f"Unknown provider {result.provider}")
        payload = provider.download(result)
        dest_dir = destination or self._temp_dir
        dest_dir.mkdir(parents=True, exist_ok=True)
        path = self._write_payload(dest_dir, payload)
        return SubtitleDownload(path=path, provider=result.provider, language=result.language)

    def _write_payload(self, dest_dir: Path, payload: SubtitlePayload) -> Path:
        buffer = io.BytesIO(payload.content)
        if zipfile.is_zipfile(buffer):
            buffer.seek(0)
            return self._extract_zip_bytes(buffer, dest_dir)
        target = dest_dir / payload.file_name
        target.write_bytes(payload.content)
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
        for item in self._temp_dir.glob("**/*"):
            try:
                if item.is_file():
                    item.unlink()
            except OSError:
                log.debug("subtitle_cleanup_failed", path=str(item))
