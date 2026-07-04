from __future__ import annotations

"""Subliminal high-level API subtitle provider."""

from pathlib import Path
from typing import Any, List
from urllib.parse import unquote, urlparse
import os
import queue
import re
import tempfile
import threading

from warp_mediacenter.backend.player.exceptions import SubtitleDownloadError
from warp_mediacenter.backend.player.subtitles.models import SubtitlePayload, SubtitleQuery, SubtitleResult
from warp_mediacenter.backend.player.subtitles.providers.base import SubtitleProvider
from warp_mediacenter.backend.player.subtitles.providers.client import bytes_request


class SubliminalProvider(SubtitleProvider):
    name = "subliminal"
    retries = 1
    backoff_sec = 1.0
    max_results = 5
    download_timeout_sec = 30.0
    _cache_configured = False

    @property
    def is_configured(self) -> bool:
        return self._imports_available()

    def search(self, query: SubtitleQuery) -> List[SubtitleResult]:
        api = self._imports()
        if api is None:
            return []

        video_name = self._video_name(query)
        video = self._video_from_name(api, query, video_name)
        language = api["Language"](self._language_code(query.language))
        found = api["list_subtitles"](
            {video},
            {language},
            providers=self._provider_names(),
            pool_class=api["AsyncProviderPool"],
            provider_configs=self._provider_configs(),
        ).get(video, [])

        scored: list[tuple[int, Any]] = []
        for subtitle in found:
            try:
                score = int(api["compute_score"](subtitle, video))
            except Exception:
                score = 0
            scored.append((score, subtitle))
        scored.sort(key=lambda item: item[0], reverse=True)
        scored = self._dedupe_scored(scored)

        max_score = self._max_score(api, video)
        results = [
            self._map_subtitle(subtitle, query, video, video_name, score, max_score, index == 0)
            for index, (score, subtitle) in enumerate(scored[: self.max_results])
        ]
        return results

    def download(self, result: SubtitleResult) -> SubtitlePayload:
        api = self._imports()
        if api is None:
            raise SubtitleDownloadError("Subliminal is not installed")

        video_name = str(result.metadata.get("video_name") or result.release or result.file_name)
        video = self._video_from_name(api, None, video_name)
        language_code = str(result.metadata.get("language_code") or result.language or "eng")
        language = api["Language"](self._language_code(language_code))
        provider_name = str(result.metadata.get("subliminal_provider") or "")
        subtitle_id = str(result.metadata.get("subliminal_id") or "")
        if not provider_name or not subtitle_id:
            raise SubtitleDownloadError("Subliminal result is missing provider/id metadata")

        if provider_name in {"opensubtitles", "opensubtitlesvip"}:
            direct = self._download_legacy_opensubtitles(subtitle_id, result.file_name)
            if direct is not None:
                return direct

        selected = self._download_selected(api, video, language, provider_name, subtitle_id)
        content = getattr(selected, "content", None)
        if not content:
            raise SubtitleDownloadError("Subliminal did not return subtitle content")

        return SubtitlePayload(file_name=result.file_name or "subliminal-subtitle.srt", content=content)

    def _download_legacy_opensubtitles(self, subtitle_id: str, file_name: str) -> SubtitlePayload | None:
        try:
            status, headers, content = bytes_request(
                f"https://dl.opensubtitles.org/en/download/file/{subtitle_id}",
                headers={"User-Agent": "VLSub 0.11.1", "Accept": "*/*"},
            )
        except SubtitleDownloadError:
            return None
        if status != 200 or content.lstrip().startswith(b"<!doctype html"):
            return None
        lower_headers = {key.lower(): value for key, value in headers.items()} if isinstance(headers, dict) else {}
        header_name = lower_headers.get("content-disposition", "")
        name = file_name or self._filename_from_disposition(header_name) or f"opensubtitles-{subtitle_id}.srt"
        return SubtitlePayload(file_name=name, content=content)

    def _download_selected(self, api: dict[str, Any], video: Any, language: Any, provider_name: str, subtitle_id: str) -> Any:
        result_queue: queue.Queue[tuple[bool, Any]] = queue.Queue(maxsize=1)

        def run() -> None:
            try:
                found = api["list_subtitles"](
                    {video},
                    {language},
                    providers=[provider_name],
                    provider_configs=self._provider_configs(),
                ).get(video, [])
                selected = next((subtitle for subtitle in found if str(subtitle.id) == subtitle_id), None)
                if selected is None:
                    raise SubtitleDownloadError("Subliminal subtitle result is no longer available")
                api["download_subtitles"]([selected], providers=[provider_name])
                result_queue.put((True, selected))
            except Exception as exc:  # noqa: BLE001
                result_queue.put((False, exc))

        thread = threading.Thread(target=run, name="subliminal-download", daemon=True)
        thread.start()
        thread.join(self.download_timeout_sec)
        if thread.is_alive():
            raise SubtitleDownloadError("Subliminal download timed out")
        ok, value = result_queue.get_nowait()
        if ok:
            return value
        if isinstance(value, SubtitleDownloadError):
            raise value
        raise SubtitleDownloadError(f"Subliminal download failed: {value}")

    def _filename_from_disposition(self, value: str) -> str:
        match = re.search(r'filename="?([^";]+)', value or "")
        return match.group(1) if match else ""

    def _map_subtitle(
        self,
        subtitle: Any,
        query: SubtitleQuery,
        video: Any,
        video_name: str,
        raw_score: int,
        max_score: int,
        best_match: bool,
    ) -> SubtitleResult:
        provider_name = str(getattr(subtitle, "provider_name", "subliminal") or "subliminal")
        subtitle_id = str(getattr(subtitle, "id", "") or "")
        info = str(getattr(subtitle, "info", "") or subtitle_id or "Subliminal subtitle")
        file_name = self._file_name(info, provider_name, subtitle_id)
        try:
            matches = sorted(subtitle.get_matches(video))
        except Exception:
            matches = []
        normalized = raw_score / max_score if max_score else 0.0
        return SubtitleResult(
            provider=self.name,
            language=str(getattr(getattr(subtitle, "language", None), "alpha3", None) or query.language),
            score=min(1.0, max(0.0, normalized)),
            release=info,
            download_link=f"subliminal://{provider_name}/{subtitle_id}",
            file_name=file_name,
            hearing_impaired=bool(getattr(subtitle, "hearing_impaired", False)),
            metadata={
                "provider_display": f"Subliminal/{provider_name}",
                "subliminal_provider": provider_name,
                "subliminal_id": subtitle_id,
                "subliminal_score": raw_score,
                "subliminal_max_score": max_score,
                "best_match": best_match,
                "language_code": str(getattr(getattr(subtitle, "language", None), "alpha3", None) or query.language),
                "video_name": video_name,
                "release_info": info,
                "matches": matches,
                "rank": {
                    "raw_score": raw_score,
                    "reasons": ["best_match"] + matches[:4] if best_match else matches[:5],
                },
            },
        )

    def _imports_available(self) -> bool:
        return self._imports() is not None

    def _imports(self) -> dict[str, Any] | None:
        try:
            from babelfish import Language
            from subliminal import AsyncProviderPool, Video, compute_score, download_subtitles, get_scores, list_subtitles, region
        except Exception:
            return None

        if not self.__class__._cache_configured:
            cache_path = Path(tempfile.gettempdir()) / "warp-mediacenter" / "subliminal-cache.dbm"
            cache_path.parent.mkdir(parents=True, exist_ok=True)
            try:
                region.configure("dogpile.cache.dbm", arguments={"filename": str(cache_path)})
            except Exception as exc:
                if exc.__class__.__name__ != "RegionAlreadyConfigured":
                    region.configure("dogpile.cache.memory")
            self.__class__._cache_configured = True
        return {
            "AsyncProviderPool": AsyncProviderPool,
            "Language": Language,
            "Video": Video,
            "compute_score": compute_score,
            "download_subtitles": download_subtitles,
            "get_scores": get_scores,
            "list_subtitles": list_subtitles,
        }

    def _provider_configs(self) -> dict[str, dict[str, object]]:
        return {
            "opensubtitles": {"timeout": 8},
            "opensubtitlesvip": {"timeout": 8},
        }

    def _provider_names(self) -> list[str] | None:
        raw = os.environ.get("SUBLIMINAL_PROVIDERS", "all")
        if raw.strip().lower() in {"", "all", "*"}:
            return None
        return [item.strip() for item in raw.split(",") if item.strip()]

    def _dedupe_scored(self, scored: list[tuple[int, Any]]) -> list[tuple[int, Any]]:
        seen: set[tuple[str, str]] = set()
        deduped: list[tuple[int, Any]] = []
        for score, subtitle in scored:
            provider_name = str(getattr(subtitle, "provider_name", "") or "")
            info = str(getattr(subtitle, "info", "") or getattr(subtitle, "id", "") or "").lower()
            key = (provider_name, re.sub(r"\s+", " ", info))
            if key in seen:
                continue
            seen.add(key)
            deduped.append((score, subtitle))
        return deduped

    def _video_from_name(self, api: dict[str, Any], query: SubtitleQuery | None, video_name: str) -> Any:
        video = api["Video"].fromname(video_name)
        if query is not None:
            if query.imdb_id:
                video.imdb_id = query.imdb_id.lower().removeprefix("tt")
            if query.tmdb_id:
                try:
                    video.tmdb_id = int(query.tmdb_id)
                except (TypeError, ValueError):
                    pass
            if query.year:
                video.year = query.year
        return video

    def _video_name(self, query: SubtitleQuery) -> str:
        media_name = self._basename(query.media_path)
        if media_name and media_name.lower() not in {"stream", "download", "file"}:
            return media_name

        title = re.sub(r"[^A-Za-z0-9]+", ".", query.title).strip(".") or "video"
        if query.media_kind == "show":
            season = query.season or 1
            episode = query.episode or 1
            return f"{title}.S{season:02d}E{episode:02d}.mkv"
        year = f".{query.year}" if query.year else ""
        return f"{title}{year}.mkv"

    def _basename(self, value: str | None) -> str:
        if not value:
            return ""
        text = unquote(value)
        parsed = urlparse(text)
        if parsed.scheme and parsed.path:
            text = parsed.path
        return text.rsplit("/", 1)[-1].rsplit("\\", 1)[-1]

    def _language_code(self, language: str) -> str:
        value = (language or "eng").strip().lower()
        return {"en": "eng", "fre": "fra", "fr": "fra", "de": "deu", "ger": "deu", "es": "spa"}.get(value, value)

    def _max_score(self, api: dict[str, Any], video: Any) -> int:
        try:
            scores = api["get_scores"](video)
            return int(scores.get("hash") or sum(scores.values()) or 1)
        except Exception:
            return 1

    def _file_name(self, info: str, provider_name: str, subtitle_id: str) -> str:
        value = re.sub(r"[^A-Za-z0-9._-]+", ".", info).strip(".")
        if not value or len(value) < 4:
            value = f"subliminal-{provider_name}-{subtitle_id or 'subtitle'}"
        if Path(value).suffix.lower() not in {".srt", ".ass", ".ssa", ".vtt", ".sub", ".txt"}:
            value = f"{value}.srt"
        return value
