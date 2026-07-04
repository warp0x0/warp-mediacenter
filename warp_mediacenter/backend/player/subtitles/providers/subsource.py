from __future__ import annotations

"""SubSource API subtitle provider."""

import os
from typing import Any, List

from warp_mediacenter.backend.player.exceptions import SubtitleDownloadError
from warp_mediacenter.backend.player.subtitles.models import SubtitlePayload, SubtitleQuery, SubtitleResult
from warp_mediacenter.backend.player.subtitles.providers.base import SubtitleProvider
from warp_mediacenter.backend.player.subtitles.providers.client import bytes_request, english_language, json_request, require_status


class SubSourceProvider(SubtitleProvider):
    name = "subsource"
    retries = 1
    backoff_sec = 1.0
    _api = "https://api.subsource.net/api/v1"

    def __init__(self, api_key: str | None = None) -> None:
        self._api_key = (api_key or os.environ.get("SUBSOURCE_API_KEY") or "").strip()

    @property
    def is_configured(self) -> bool:
        return bool(self._api_key)

    def search(self, query: SubtitleQuery) -> List[SubtitleResult]:
        if not self._api_key:
            return []
        movie = self._find_movie(query)
        if not movie:
            return []
        movie_id = movie.get("movieId")
        if not movie_id:
            return []
        params: dict[str, Any] = {
            "movieId": movie_id,
            "language": english_language(query.language),
            "sort": "popular",
            "limit": 50,
        }
        status, _, payload = json_request("GET", f"{self._api}/subtitles", params=params, headers=self._headers())
        require_status("SubSource", "subtitle search", status, payload)
        return [self._map_item(item, query, movie) for item in (payload.get("data", []) if isinstance(payload, dict) else [])]

    def download(self, result: SubtitleResult) -> SubtitlePayload:
        subtitle_id = result.metadata.get("subtitle_id")
        if not subtitle_id:
            raise SubtitleDownloadError("SubSource result has no subtitle id")
        status, _, content = bytes_request(f"{self._api}/subtitles/{subtitle_id}/download", headers=self._headers())
        if status != 200:
            raise SubtitleDownloadError(f"SubSource download failed with status {status}")
        return SubtitlePayload(file_name=f"subsource-{subtitle_id}.zip", content=content)

    def _headers(self) -> dict[str, str]:
        return {"X-API-Key": self._api_key, "Accept": "application/json"}

    def _find_movie(self, query: SubtitleQuery) -> dict[str, Any] | None:
        media_type = "series" if query.media_kind == "show" else "movie"
        if query.imdb_id:
            params: dict[str, Any] = {"searchType": "imdb", "imdb": query.imdb_id, "type": media_type}
        else:
            params = {"searchType": "text", "q": query.title, "type": media_type}
        if query.year:
            params["year"] = query.year
        if query.media_kind == "show" and query.season:
            params["season"] = query.season

        status, _, payload = json_request("GET", f"{self._api}/movies/search", params=params, headers=self._headers())
        require_status("SubSource", "movie search", status, payload)
        items = payload.get("data", []) if isinstance(payload, dict) else []
        if not items:
            return None
        expected_imdb = (query.imdb_id or "").lower()
        expected_tmdb = str(query.tmdb_id or "")
        for item in items:
            if expected_imdb and str(item.get("imdbId") or "").lower() == expected_imdb:
                return item
            if expected_tmdb and str(item.get("tmdbId") or "") == expected_tmdb:
                return item
        return items[0]

    def _map_item(self, item: dict[str, Any], query: SubtitleQuery, movie: dict[str, Any]) -> SubtitleResult:
        release_info = item.get("releaseInfo") or []
        release = " ".join(str(part) for part in release_info) if isinstance(release_info, list) else str(release_info or "SubSource subtitle")
        rating_payload = item.get("rating") if isinstance(item.get("rating"), dict) else {}
        rating = float(rating_payload.get("total") or rating_payload.get("good") or 0.0)
        subtitle_id = item.get("subtitleId")
        return SubtitleResult(
            provider=self.name,
            language=str(item.get("language") or english_language(query.language)),
            score=0.0,
            release=release,
            download_link=f"{self._api}/subtitles/{subtitle_id}/download" if subtitle_id else "",
            file_name=f"subsource-{subtitle_id}.zip" if subtitle_id else "subsource-subtitle.zip",
            hearing_impaired=bool(item.get("hearingImpaired", False)),
            rating=rating if rating else None,
            metadata={
                "provider_display": "SubSource",
                "subtitle_id": subtitle_id,
                "release_info": release,
                "downloads": item.get("downloads") or 0,
                "rating": rating,
                "framerate": item.get("framerate"),
                "imdb_id": movie.get("imdbId"),
                "tmdb_id": movie.get("tmdbId"),
                "year": movie.get("releaseYear"),
                "season": movie.get("season"),
                "exact_id_match": bool(query.imdb_id or query.tmdb_id),
            },
        )
