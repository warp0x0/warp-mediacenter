"""Podnapisi subtitle provider.

Uses the Podnapisi XML API (no authentication required).
API docs: https://www.podnapisi.net/forum/viewtopic.php?f=62&t=26164

Search parameters:
  sK  - search keyword (title)
  sT  - subtitle type: 'movie' or 'tv'
  sY  - year (optional)
  sL  - language code (ISO 639-2, e.g. 'eng', 'spa')
  sTS - season (for TV, optional)
  sTE - episode (for TV, optional)
"""

from __future__ import annotations

import gzip
import re
import xml.etree.ElementTree as ET
from typing import List, Optional

import requests

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.player.subtitles.models import (
    SubtitlePayload,
    SubtitleQuery,
    SubtitleResult,
)
from warp_mediacenter.backend.player.subtitles.providers.base import SubtitleProvider

log = get_logger(__name__)

_PODNAPISI_SEARCH_URL = "https://www.podnapisi.net/subtitles/search/xml"
_PODNAPISI_DOWNLOAD_URL = "https://www.podnapisi.net/subtitles/download/"
_PODNAPISI_USER_AGENT = "WarpMediaCenter/0.0.1"

_LANG_MAP = {
    "eng": "en",
    "spa": "es",
    "fra": "fr",
    "deu": "de",
    "ita": "it",
    "por": "pt",
    "jpn": "ja",
    "kor": "ko",
    "zho": "zh",
    "rus": "ru",
    "ara": "ar",
    "hin": "hi",
    "nld": "nl",
    "swe": "sv",
    "nor": "no",
    "dan": "da",
    "fin": "fi",
    "pol": "pl",
    "ces": "cs",
    "hun": "hu",
    "ron": "ro",
    "tur": "tr",
    "ell": "el",
    "heb": "he",
    "tha": "th",
    "vie": "vi",
    "ind": "id",
    "msa": "ms",
}


class PodnapisiProvider(SubtitleProvider):
    """Podnapisi subtitle provider using the free XML API."""

    name = "podnapisi"
    retries = 2
    backoff_sec = 1.5

    def __init__(self, *, timeout: float = 15.0) -> None:
        self._timeout = timeout
        self._session = requests.Session()
        self._session.headers.update({
            "User-Agent": _PODNAPISI_USER_AGENT,
            "Accept": "application/xml",
        })

    @property
    def is_configured(self) -> bool:
        return True

    def is_available_for(self, media_kind: str) -> bool:
        return media_kind in ("movie", "show")

    def search(self, query: SubtitleQuery) -> List[SubtitleResult]:
        params = self._build_search_params(query)
        try:
            resp = self._session.get(
                _PODNAPISI_SEARCH_URL,
                params=params,
                timeout=self._timeout,
            )
            resp.raise_for_status()
        except requests.RequestException as exc:
            log.warning("podnapisi_search_failed", error=str(exc))
            return []

        return self._parse_search_response(resp.content, query)

    def download(self, result: SubtitleResult) -> SubtitlePayload:
        subtitle_id = result.extra.get("subtitle_id")
        if not subtitle_id:
            raise RuntimeError("Podnapisi result missing subtitle_id")

        download_url = f"{_PODNAPISI_DOWNLOAD_URL}{subtitle_id}"
        try:
            resp = self._session.get(
                download_url,
                timeout=self._timeout,
                allow_redirects=True,
            )
            resp.raise_for_status()
        except requests.RequestException as exc:
            raise RuntimeError(f"Podnapisi download failed: {exc}") from exc

        content = resp.content
        file_name = result.file_name or f"podnapisi_{subtitle_id}.srt"

        if content[:2] == b"\x1f\x8b":
            try:
                content = gzip.decompress(content)
            except Exception:
                pass

        return SubtitlePayload(
            content=content,
            file_name=file_name,
            encoding="utf-8",
        )

    def _build_search_params(self, query: SubtitleQuery) -> dict:
        params: dict = {"sK": query.title}

        if query.media_kind == "movie":
            params["sT"] = "movie"
        else:
            params["sT"] = "tv"

        if query.year:
            params["sY"] = str(query.year)

        lang_code = _LANG_MAP.get(query.language, query.language[:2] if query.language else "en")
        params["sL"] = lang_code

        if query.season is not None:
            params["sTS"] = str(query.season)
        if query.episode is not None:
            params["sTE"] = str(query.episode)

        return params

    def _parse_search_response(
        self,
        content: bytes,
        query: SubtitleQuery,
    ) -> List[SubtitleResult]:
        results: List[SubtitleResult] = []
        try:
            root = ET.fromstring(content)
        except ET.ParseError as exc:
            log.warning("podnapisi_xml_parse_error", error=str(exc))
            return []

        for subtitle_elem in root.findall(".//subtitle"):
            subtitle_id = self._get_text(subtitle_elem, "id")
            if not subtitle_id:
                continue

            title = self._get_text(subtitle_elem, "title") or query.title
            language = self._get_text(subtitle_elem, "language") or query.language
            release = self._get_text(subtitle_elem, "release") or ""
            year_text = self._get_text(subtitle_elem, "year") or ""
            season = self._get_text(subtitle_elem, "season") or ""
            episode = self._get_text(subtitle_elem, "episode") or ""
            downloads_text = self._get_text(subtitle_elem, "downloads") or "0"

            try:
                downloads = int(downloads_text)
            except ValueError:
                downloads = 0

            score = self._calculate_score(
                release=release,
                query_title=query.title,
                query_year=query.year,
                year_text=year_text,
                downloads=downloads,
            )

            ext = ".srt"
            file_name = f"{title.replace(' ', '.')}_{language}{ext}"

            results.append(
                SubtitleResult(
                    provider=self.name,
                    language=language or "unknown",
                    file_name=file_name,
                    score=score,
                    extra={
                        "subtitle_id": subtitle_id,
                        "release": release,
                        "downloads": downloads,
                    },
                )
            )

        return results

    def _calculate_score(
        self,
        release: str,
        query_title: str,
        query_year: Optional[int],
        year_text: str,
        downloads: int,
    ) -> float:
        score = 0.0

        if release:
            release_lower = release.lower()
            query_lower = query_title.lower()
            if query_lower in release_lower:
                score += 50.0
            elif any(word in release_lower for word in query_lower.split()):
                score += 25.0

        if query_year and year_text:
            try:
                if int(year_text) == query_year:
                    score += 20.0
            except ValueError:
                pass

        score += min(downloads / 100.0, 30.0)

        return score

    @staticmethod
    def _get_text(elem: ET.Element, tag: str) -> Optional[str]:
        child = elem.find(tag)
        if child is not None and child.text:
            return child.text.strip()
        return None
