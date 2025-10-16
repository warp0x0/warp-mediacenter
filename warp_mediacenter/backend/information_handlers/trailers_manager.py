"""Helpers for retrieving trailer stream metadata."""

from __future__ import annotations

from typing import Any, Iterable, Mapping, Optional, Sequence

from warp_mediacenter.backend.information_handlers.models import (
    MediaModelFacade,
    MediaType,
    QualityTag,
    StreamSource,
)
from warp_mediacenter.backend.information_handlers.tmdb_manager import TMDbManager


class TrailersManager:
    """Provide normalized trailer streams using upstream provider metadata."""

    def __init__(
        self,
        *,
        tmdb: Optional[TMDbManager] = None,
        facade: Optional[MediaModelFacade] = None,
    ) -> None:
        self._tmdb = tmdb or TMDbManager()
        self._facade = facade or MediaModelFacade()

    def movie_trailers(
        self,
        movie_id: int | str,
        *,
        language: Optional[str] = None,
    ) -> Sequence[StreamSource]:
        videos = self._tmdb.get_videos(MediaType.MOVIE, movie_id, language=language)

        return self._to_stream_sources(videos, source_tag="tmdb.movie_trailer")

    def show_trailers(
        self,
        show_id: int | str,
        *,
        language: Optional[str] = None,
    ) -> Sequence[StreamSource]:
        videos = self._tmdb.get_videos(MediaType.SHOW, show_id, language=language)

        return self._to_stream_sources(videos, source_tag="tmdb.show_trailer")

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------
    def _to_stream_sources(
        self,
        videos: Iterable[Mapping[str, Any]],
        *,
        source_tag: str,
    ) -> Sequence[StreamSource]:
        sources: list[StreamSource] = []
        for video in videos:
            if not self._is_official_trailer(video):
                continue
            url = self._build_video_url(video)
            if not url:
                continue
            payload = {
                "url": url,
                "quality": self._quality_from_size(video.get("size")),
                "mime_type": self._mime_from_site(video.get("site")),
                "source_tag": source_tag,
            }
            try:
                sources.append(self._facade.stream_source(payload, source_tag=source_tag))
            except Exception:  # pragma: no cover - defensive validation
                continue

        return sources

    def _is_official_trailer(self, video: Mapping[str, Any]) -> bool:
        if video.get("type") not in {"Trailer", "Teaser"}:
            return False
        if video.get("official") is False:
            return False
        return True

    def _build_video_url(self, video: Mapping[str, Any]) -> Optional[str]:
        site = str(video.get("site") or "")
        key = video.get("key")
        if not key:
            return None
        if site.lower() == "youtube":
            return f"https://www.youtube.com/watch?v={key}"
        if site.lower() == "vimeo":
            return f"https://vimeo.com/{key}"

        return None

    def _quality_from_size(self, size: Any) -> Optional[QualityTag]:
        try:
            value = int(size)
        except (TypeError, ValueError):
            return None
        if value >= 4320:
            return QualityTag.UHD_8K
        if value >= 2160:
            return QualityTag.UHD_4K
        if value >= 1080:
            return QualityTag.FHD
        if value >= 720:
            return QualityTag.HD
        if value > 0:
            return QualityTag.SD

        return None

    def _mime_from_site(self, site: Any) -> Optional[str]:
        if not site:
            return None
        normalized = str(site).lower()
        if normalized == "youtube":
            return "video/yt"  # pseudo MIME type for UI routing
        if normalized == "vimeo":
            return "video/vimeo"

        return None


__all__ = ["TrailersManager"]