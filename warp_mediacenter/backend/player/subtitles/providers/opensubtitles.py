from __future__ import annotations

"""Integration with the OpenSubtitles v1 API."""

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
import json

import requests

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.player.exceptions import SubtitleProviderUnavailable
from warp_mediacenter.backend.player.subtitles.models import (
    SubtitlePayload,
    SubtitleQuery,
    SubtitleResult,
)
from warp_mediacenter.backend.player.subtitles.providers.base import (
    SubtitleProvider,
    ensure_api_key,
)
from warp_mediacenter.config import settings

log = get_logger(__name__)

_API_URL = "https://api.opensubtitles.com/api/v1"


@dataclass(slots=True)
class OpenSubtitlesConfig:
    api_key: Optional[str]
    user_agent: str = "warp-mediacenter"
    download_timeout: int = 20

    @classmethod
    def from_settings(cls) -> "OpenSubtitlesConfig":
        tokens_dir = Path(settings.get_tokens_dir())
        token_path = tokens_dir / "opensubtitles.json"
        api_key: Optional[str] = None
        user_agent = "warp-mediacenter"
        if token_path.exists():
            try:
                with token_path.open("r", encoding="utf-8") as fh:
                    data = json.load(fh)
                api_key = data.get("api_key")
                user_agent = data.get("user_agent", user_agent)
            except Exception:  # noqa: BLE001
                log.warning("opensubtitles_token_load_failed", path=str(token_path))
        if not api_key:
            cfg = settings.get_service_config("opensubtitles") or {}
            api_key = cfg.get("api_key")
            user_agent = cfg.get("user_agent", user_agent)
        return cls(api_key=api_key, user_agent=user_agent)


class OpenSubtitlesProvider(SubtitleProvider):
    name = "opensubtitles"

    def __init__(self, config: Optional[OpenSubtitlesConfig] = None) -> None:
        self.config = config or OpenSubtitlesConfig(api_key=None)

    @property
    def is_configured(self) -> bool:  # type: ignore[override]
        return bool(self.config.api_key)

    @classmethod
    def from_settings(cls) -> "OpenSubtitlesProvider":
        config = OpenSubtitlesConfig.from_settings()
        return cls(config=config)

    def _headers(self) -> Dict[str, str]:
        api_key = ensure_api_key("OpenSubtitles", self.config.api_key)
        return {
            "Api-Key": api_key,
            "Content-Type": "application/json",
            "User-Agent": self.config.user_agent,
        }

    def search(self, query: SubtitleQuery) -> List[SubtitleResult]:  # type: ignore[override]
        params: Dict[str, object] = {
            "query": query.title,
            "languages": query.language,
        }
        if query.media_kind == "show":
            if query.season:
                params["season_number"] = query.season
            if query.episode:
                params["episode_number"] = query.episode
        if query.year:
            params["year"] = query.year
        response = requests.get(f"{_API_URL}/subtitles", headers=self._headers(), params=params, timeout=10)
        if response.status_code == 401:
            raise SubtitleProviderUnavailable("OpenSubtitles authentication failed")
        response.raise_for_status()
        data = response.json()
        results: List[SubtitleResult] = []
        for item in data.get("data", []):
            attributes = item.get("attributes", {})
            upload_date = attributes.get("upload_date")
            uploaded_at = None
            if upload_date:
                try:
                    uploaded_at = datetime.fromisoformat(upload_date.replace("Z", "+00:00"))
                except ValueError:
                    uploaded_at = None
            score = attributes.get("score", 0) or 0
            release = attributes.get("release", "")
            results.append(
                SubtitleResult(
                    provider=self.name,
                    language=attributes.get("language", query.language),
                    score=float(score),
                    release=release,
                    download_link=attributes.get("url"),
                    file_name=attributes.get("files", [{}])[0].get("file_name", f"{release or query.title}.srt"),
                    hearing_impaired=bool(attributes.get("hearing_impaired")),
                    rating=attributes.get("rating"),
                    uploaded_at=uploaded_at,
                    metadata={"feature_details": attributes.get("feature_details", {})},
                )
            )
        return results

    def download(self, result: SubtitleResult) -> SubtitlePayload:  # type: ignore[override]
        headers = self._headers()
        response = requests.get(result.download_link, headers=headers, timeout=self.config.download_timeout)
        if response.status_code == 401:
            raise SubtitleProviderUnavailable("OpenSubtitles download unauthorized")
        response.raise_for_status()
        disposition = response.headers.get("Content-Disposition", "")
        file_name = result.file_name
        if "filename=" in disposition:
            file_name = disposition.split("filename=")[-1].strip('"')
        content_type = response.headers.get("Content-Type")
        return SubtitlePayload(file_name=file_name, content=response.content, mime_type=content_type)
