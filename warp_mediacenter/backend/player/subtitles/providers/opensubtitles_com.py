from __future__ import annotations

"""OpenSubtitles.com API v1 provider."""

import os
import time
from typing import Any, List
from urllib.parse import unquote, urlparse

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.player.exceptions import SubtitleDownloadError
from warp_mediacenter.backend.player.subtitles.models import SubtitlePayload, SubtitleQuery, SubtitleResult
from warp_mediacenter.backend.player.subtitles.providers.base import SubtitleProvider
from warp_mediacenter.backend.player.subtitles.providers.client import bytes_request, iso1_language, json_request, require_status

log = get_logger(__name__)


class OpenSubtitlesComProvider(SubtitleProvider):
    name = "opensubtitles"
    retries = 1
    backoff_sec = 2.0
    _api = "https://api.opensubtitles.com/api/v1"

    def __init__(
        self,
        api_key: str | None = None,
        username: str | None = None,
        password: str | None = None,
        user_agent: str | None = None,
    ) -> None:
        self._api_key = (api_key or os.environ.get("OPENSUBTITLES_CONSUMER_API") or os.environ.get("OPENSUBTITLES_API_KEY") or "").strip()
        self._username = (username or os.environ.get("OPENSUBTITLES_USERNAME") or "").strip()
        self._password = (password or os.environ.get("OPENSUBTITLES_PASSWORD") or "").strip()
        app_name = os.environ.get("WARP_APP_NAME") or "WarpMediaCenter"
        self._user_agent = (user_agent or f"{app_name} v0.0.1").strip()
        self._token: str | None = (os.environ.get("OPENSUBTITLES_JWT_TOKEN") or os.environ.get("OPENSUBTITLES_JWT") or "").strip() or None
        self._token_expires_at = self._parse_expires_at(os.environ.get("OPENSUBTITLES_JWT_EXPIRES_AT"))

    @property
    def is_configured(self) -> bool:
        return bool(self._api_key)

    def search(self, query: SubtitleQuery) -> List[SubtitleResult]:
        if not self._api_key:
            return []
        headers = self._headers(auth=True)
        lang = iso1_language(query.language)
        params: dict[str, Any] = {
            "languages": lang,
            "type": "episode" if query.media_kind == "show" else "movie",
            "query": query.title,
        }
        if query.imdb_id:
            params["imdb_id"] = query.imdb_id.lower().removeprefix("tt")
        if query.year and query.media_kind != "show":
            params["year"] = query.year
        if query.media_kind == "show":
            if query.season:
                params["season_number"] = query.season
            if query.episode:
                params["episode_number"] = query.episode

        items = self._search_items(params, headers)
        if query.media_kind == "show" and len(items) < 20:
            fallback_query = self._fallback_episode_query(query)
            if fallback_query:
                items.extend(self._search_items({"languages": lang, "query": fallback_query}, headers))

        results: list[SubtitleResult] = []
        seen: set[tuple[str, str]] = set()
        for item in items:
            if not self._has_file(item):
                continue
            result = self._map_item(item, query, lang)
            key = (str(result.metadata.get("file_id") or ""), result.release)
            if key in seen:
                continue
            seen.add(key)
            results.append(result)
        return results

    def _search_items(self, params: dict[str, Any], headers: dict[str, str]) -> list[dict[str, Any]]:
        status, _, payload = json_request("GET", f"{self._api}/subtitles", params=params, headers=headers)
        require_status("OpenSubtitles", "search", status, payload)
        return payload.get("data", []) if isinstance(payload, dict) else []

    def _fallback_episode_query(self, query: SubtitleQuery) -> str:
        if query.media_path:
            text = unquote(str(query.media_path))
            parsed = urlparse(text)
            if parsed.scheme and parsed.path:
                text = parsed.path.rsplit("/", 1)[-1]
            return text.rsplit("\\", 1)[-1]
        if query.title and query.season and query.episode:
            return f"{query.title} S{query.season:02d}E{query.episode:02d}"
        return ""

    def download(self, result: SubtitleResult) -> SubtitlePayload:
        file_id = result.metadata.get("file_id")
        if not file_id:
            raise SubtitleDownloadError("OpenSubtitles result has no file id")
        status, _, payload = json_request(
            "POST",
            f"{self._api}/download",
            headers=self._headers(auth=True),
            body={"file_id": file_id},
        )
        require_status("OpenSubtitles", "download link", status, payload)
        link = payload.get("link") if isinstance(payload, dict) else None
        if not link:
            raise SubtitleDownloadError("OpenSubtitles download response did not include a link")
        status, _, content = bytes_request(str(link), headers={"User-Agent": self._user_agent})
        if status != 200:
            raise SubtitleDownloadError(f"OpenSubtitles file download failed with status {status}")
        file_name = str(payload.get("file_name") or result.file_name or "opensubtitles-subtitle")
        return SubtitlePayload(file_name=file_name, content=content)

    def refresh_token(self) -> dict[str, Any]:
        if not (self._api_key and self._username and self._password):
            raise SubtitleDownloadError("OpenSubtitles credentials missing")
        status, _, payload = json_request(
            "POST",
            f"{self._api}/login",
            headers=self._headers(auth=False),
            body={"username": self._username, "password": self._password},
        )
        require_status("OpenSubtitles", "login", status, payload)
        token = payload.get("token") if isinstance(payload, dict) else None
        if not token:
            raise SubtitleDownloadError("OpenSubtitles login did not return a token")
        self._token = str(token)
        self._token_expires_at = time.time() + (23 * 60 * 60)
        os.environ["OPENSUBTITLES_JWT_TOKEN"] = self._token
        os.environ["OPENSUBTITLES_JWT_EXPIRES_AT"] = str(int(self._token_expires_at))
        return {"token": self._token, "expires_at": int(self._token_expires_at)}

    def _headers(self, *, auth: bool) -> dict[str, str]:
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Api-Key": self._api_key,
            "User-Agent": self._user_agent,
        }
        if auth:
            self._ensure_token()
            if self._token:
                headers["Authorization"] = f"Bearer {self._token}"
        return headers

    def _ensure_token(self) -> None:
        if not (self._username and self._password):
            return
        if self._token and time.time() < self._token_expires_at:
            return
        self.refresh_token()

    def _parse_expires_at(self, value: str | None) -> float:
        try:
            return float(value or 0)
        except (TypeError, ValueError):
            return 0.0

    def _has_file(self, item: dict[str, Any]) -> bool:
        attrs = item.get("attributes") if isinstance(item, dict) else {}
        files = attrs.get("files") if isinstance(attrs, dict) else []
        return bool(files)

    def _map_item(self, item: dict[str, Any], query: SubtitleQuery, lang: str) -> SubtitleResult:
        attrs = item.get("attributes") or {}
        file_item = (attrs.get("files") or [{}])[0]
        feature = attrs.get("feature_details") or {}
        imdb_id = str(feature.get("imdb_id") or "")
        parent_imdb_id = str(feature.get("parent_imdb_id") or "")
        expected_imdb = (query.imdb_id or "").lower().removeprefix("tt")
        file_name = str(file_item.get("file_name") or attrs.get("release") or "OpenSubtitles subtitle")
        file_id = file_item.get("file_id")
        rating = float(attrs.get("ratings") or 0.0)
        return SubtitleResult(
            provider=self.name,
            language=str(attrs.get("language") or lang),
            score=0.0,
            release=file_name,
            download_link=f"opensubtitles://{file_id}" if file_id else "",
            file_name=file_name,
            hearing_impaired=bool(attrs.get("hearing_impaired", False)),
            rating=rating if rating else None,
            metadata={
                "provider_display": "OpenSubtitles",
                "file_id": file_id,
                "release_info": file_name,
                "imdb_id": imdb_id,
                "parent_imdb_id": parent_imdb_id,
                "tmdb_id": feature.get("tmdb_id"),
                "parent_tmdb_id": feature.get("parent_tmdb_id"),
                "parent_title": feature.get("parent_title"),
                "year": feature.get("year") or query.year,
                "season": feature.get("season_number"),
                "episode": feature.get("episode_number"),
                "downloads": attrs.get("download_count") or attrs.get("downloads") or 0,
                "rating": rating,
                "moviehash_match": attrs.get("moviehash_match"),
                "exact_id_match": bool(expected_imdb and expected_imdb in {imdb_id.lower().removeprefix("tt"), parent_imdb_id.lower().removeprefix("tt")}),
            },
        )
