from __future__ import annotations

"""SubDL API v2 subtitle provider."""

import os
from typing import Any, List

from warp_mediacenter.backend.player.exceptions import SubtitleDownloadError
from warp_mediacenter.backend.player.subtitles.models import SubtitlePayload, SubtitleQuery, SubtitleResult
from warp_mediacenter.backend.player.subtitles.providers.base import SubtitleProvider
from warp_mediacenter.backend.player.subtitles.providers.client import bytes_request, iso1_language, json_request, require_status


class SubDLProvider(SubtitleProvider):
    name = "subdl"
    retries = 1
    backoff_sec = 1.0

    def __init__(self, api_key: str | None = None) -> None:
        self._api_key = (api_key or os.environ.get("SUBDL_API_KEY") or "").strip()

    @property
    def is_configured(self) -> bool:
        return bool(self._api_key)

    def search(self, query: SubtitleQuery) -> List[SubtitleResult]:
        if not self._api_key:
            return []

        lang = iso1_language(query.language)
        media_type = "tv" if query.media_kind == "show" else "movie"
        params: dict[str, Any] = {
            "type": media_type,
            "languages": lang,
            "unpack": "1",
            "subs_per_page": 30,
        }
        if query.imdb_id:
            params["imdb_id"] = query.imdb_id
        elif query.tmdb_id:
            params["tmdb_id"] = query.tmdb_id
        else:
            params["film_name"] = query.title
        if query.year:
            params["year"] = query.year
        if query.media_kind == "show":
            if query.season:
                params["season"] = query.season
            if query.episode:
                params["episode"] = query.episode

        status, _, payload = json_request(
            "GET",
            "https://api.subdl.com/api/v2/subtitles/search",
            params=params,
            headers={"Authorization": f"Bearer {self._api_key}", "Accept": "application/json"},
        )
        require_status("SubDL", "search", status, payload)

        subtitles = payload.get("subtitles", []) if isinstance(payload, dict) else []
        results: list[SubtitleResult] = []
        for item in subtitles:
            results.extend(self._map_item(item, query, lang))
        return results

    def download(self, result: SubtitleResult) -> SubtitlePayload:
        url = str(result.metadata.get("download_url") or result.download_link or "")
        if not url:
            raise SubtitleDownloadError("SubDL result has no download URL")
        if url.startswith("/"):
            url = "https://dl.subdl.com" + url
        status, _, content = bytes_request(
            url,
            headers={"X-API-Key": self._api_key, "Accept": "*/*"},
        )
        if status != 200:
            raise SubtitleDownloadError(f"SubDL download failed with status {status}")
        return SubtitlePayload(file_name=result.file_name or "subdl-subtitle", content=content)

    def _map_item(self, item: dict[str, Any], query: SubtitleQuery, lang: str) -> list[SubtitleResult]:
        release = str(item.get("release_name") or item.get("name") or "SubDL subtitle")
        base_metadata = {
            "provider_display": "SubDL",
            "exact_id_match": bool(query.imdb_id or query.tmdb_id),
            "season": item.get("season"),
            "episode": item.get("episode"),
            "year": query.year,
            "fps": item.get("fps"),
            "downloads": item.get("downloads"),
        }

        unpack_files = item.get("unpack_files") if isinstance(item.get("unpack_files"), list) else []
        if unpack_files:
            mapped: list[SubtitleResult] = []
            for file_item in unpack_files:
                if query.media_kind == "show":
                    season = file_item.get("season")
                    episode = file_item.get("episode")
                    if query.season and season and int(season) != int(query.season):
                        continue
                    if query.episode and episode and int(episode) != int(query.episode):
                        continue
                file_release = str(file_item.get("release_name") or file_item.get("name") or release)
                url = str(file_item.get("url") or item.get("url") or "")
                mapped.append(SubtitleResult(
                    provider=self.name,
                    language=str(file_item.get("language") or item.get("language") or lang),
                    score=0.0,
                    release=file_release,
                    download_link=url,
                    file_name=str(file_item.get("name") or item.get("name") or file_release),
                    hearing_impaired=bool(file_item.get("hi", item.get("hi", False))),
                    metadata={
                        **base_metadata,
                        "download_url": url,
                        "release_info": file_release,
                        "season": file_item.get("season") or item.get("season"),
                        "episode": file_item.get("episode") or item.get("episode"),
                        "format": file_item.get("format"),
                        "size": file_item.get("size"),
                    },
                ))
            if mapped:
                return mapped

        url = str(item.get("url") or "")
        return [SubtitleResult(
            provider=self.name,
            language=str(item.get("language") or item.get("lang") or lang),
            score=0.0,
            release=release,
            download_link=url,
            file_name=str(item.get("name") or release),
            hearing_impaired=bool(item.get("hi", False)),
            metadata={**base_metadata, "download_url": url, "release_info": release},
        )]
