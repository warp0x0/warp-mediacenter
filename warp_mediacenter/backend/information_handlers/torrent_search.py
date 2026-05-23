"""Torrent search service that queries Torrent-API-Py and ranks results."""

from __future__ import annotations

import json
import re
from typing import Any, Dict, List, Optional

from thefuzz import fuzz

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.information_handlers.torrent_models import (
    TorrentResult,
    TorrentSearchResponse,
)
from warp_mediacenter.backend.player.debrid.client import RealDebridClient
from warp_mediacenter.config.settings.torrent import (
    TorrentSettings,
    get_torrent_debrid_settings,
)

log = get_logger(__name__)

_SIZE_RE = re.compile(r"([\d.]+)\s*(GB|MB|TB|KB)", re.IGNORECASE)
_QUALITY_RE = re.compile(r"(2160p|1080p|720p|480p|4K|HDR|SDR|WEBRip|BluRay|BRRip|WEB-DL|HDTV|CAM|TS|TC|SCR)", re.IGNORECASE)


def _parse_size_bytes(size_str: str) -> int:
    """Parse human-readable size string to bytes."""
    match = _SIZE_RE.search(size_str)
    if not match:
        return 0
    value = float(match.group(1))
    unit = match.group(2).upper()
    multipliers = {"KB": 1024, "MB": 1024 ** 2, "GB": 1024 ** 3, "TB": 1024 ** 4}
    return int(value * multipliers.get(unit, 1))


def _extract_quality(name: str) -> str:
    """Extract quality tag from torrent name."""
    match = _QUALITY_RE.search(name)
    return match.group(1) if match else "unknown"


def _fuzzy_score(torrent_name: str, query: str) -> float:
    """Compute fuzzy match score between torrent name and search query."""
    name_lower = torrent_name.lower()
    query_lower = query.lower()

    token_ratio = fuzz.token_sort_ratio(name_lower, query_lower) / 100.0
    partial_ratio = fuzz.partial_ratio(query_lower, name_lower) / 100.0

    return max(token_ratio, partial_ratio)


class TorrentSearchService:
    """Searches torrents via Torrent-API-Py, checks RealDebrid cache availability,
    filters, ranks, and returns structured results."""

    def __init__(
        self,
        settings: Optional[TorrentSettings] = None,
        debrid_client: Optional[RealDebridClient] = None,
    ) -> None:
        self._settings = settings or get_torrent_debrid_settings().torrent
        self._debrid_client = debrid_client

    def search(
        self,
        query: str,
        media_type: str = "movie",
        season: Optional[int] = None,
        episode: Optional[int] = None,
        year: Optional[int] = None,
        limit: Optional[int] = None,
    ) -> TorrentSearchResponse:
        """Search for torrents and return ranked results split by cache status.

        Args:
            query: Base search term (title)
            media_type: "movie" or "tv"
            season: Season number for TV episodes
            episode: Episode number for TV episodes
            year: Release year for movies
            limit: Max results per site (0 = site default)

        Returns:
            TorrentSearchResponse with cached and uncached results.
        """
        search_query = self._build_query(query, media_type, season, episode, year)
        max_results = limit or self._settings.max_results

        cached_json = self._get_cached_results(search_query, media_type)
        if cached_json is not None:
            log.info("torrent_search_cache_hit", query=search_query)
            return self._rebuild_response(cached_json, media_type)

        raw_results = self._fetch_torrents(search_query, max_results)
        if not raw_results:
            log.info("torrent_search_no_results", query=search_query)
            return TorrentSearchResponse(query=search_query, media_type=media_type)

        parsed = self._parse_results(raw_results, search_query)
        filtered = self._filter_results(parsed)
        ranked = self._rank_results(filtered, search_query)

        hashes = [r.hash for r in ranked if r.hash]
        cached_hashes = self._check_cache_availability(hashes) if hashes else set()

        cached: List[TorrentResult] = []
        uncached: List[TorrentResult] = []
        for r in ranked:
            r.is_cached = r.hash in cached_hashes
            if r.is_cached:
                cached.append(r)
            else:
                uncached.append(r)

        response = TorrentSearchResponse(
            cached=cached,
            uncached=uncached,
            query=search_query,
            media_type=media_type,
            total_results=len(cached) + len(uncached),
        )

        self._cache_results(search_query, media_type, response)

        log.info(
            "torrent_search_complete",
            query=search_query,
            cached=len(cached),
            uncached=len(uncached),
        )
        return response

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    @staticmethod
    def _build_query(
        title: str,
        media_type: str,
        season: Optional[int] = None,
        episode: Optional[int] = None,
        year: Optional[int] = None,
    ) -> str:
        parts = [title]
        if year and media_type == "movie":
            parts.append(str(year))
        if media_type == "tv" and season is not None and episode is not None:
            parts.append(f"S{season:02d}E{episode:02d}")
        return " ".join(parts)

    # ------------------------------------------------------------------
    # Cache helpers
    # ------------------------------------------------------------------
    @staticmethod
    def _get_cached_results(query: str, media_type: str) -> Optional[str]:
        """Check for cached search results."""
        try:
            from warp_mediacenter.backend.persistence import connection, get_cached_torrent_search
            with connection() as conn:
                return get_cached_torrent_search(conn, query, media_type)
        except Exception:
            return None

    def _cache_results(self, query: str, media_type: str, response: TorrentSearchResponse) -> None:
        """Store search results in cache."""
        try:
            from warp_mediacenter.backend.persistence import connection, cache_torrent_search
            data = response.to_dict()
            with connection() as conn:
                cache_torrent_search(conn, query, media_type, json.dumps(data), ttl_seconds=3600)
        except Exception:
            log.debug("torrent_cache_store_failed", query=query)

    def _rebuild_response(self, cached_json: str, media_type: str) -> TorrentSearchResponse:
        """Rebuild TorrentSearchResponse from cached JSON."""
        data = json.loads(cached_json)
        cached = [self._dict_to_result(t) for t in data.get("cached", [])]
        uncached = [self._dict_to_result(t) for t in data.get("uncached", [])]
        return TorrentSearchResponse(
            cached=cached,
            uncached=uncached,
            query=data.get("query", ""),
            media_type=media_type,
            total_results=data.get("total_results", 0),
        )

    @staticmethod
    def _dict_to_result(d: Dict[str, Any]) -> TorrentResult:
        return TorrentResult(
            name=d.get("name", ""),
            magnet=d.get("magnet", ""),
            hash=d.get("hash", ""),
            seeders=int(d.get("seeders", 0)),
            leechers=int(d.get("leechers", 0)),
            size=d.get("size", "0"),
            size_bytes=int(d.get("size_bytes", 0)),
            source_site=d.get("source_site", ""),
            quality=d.get("quality", "unknown"),
            is_cached=bool(d.get("is_cached", False)),
            uploader=d.get("uploader", ""),
            date=d.get("date", ""),
            match_score=float(d.get("match_score", 0.0)),
        )

    def _fetch_torrents(self, query: str, limit: int) -> List[Dict[str, Any]]:
        """Fetch raw torrent results from Torrent-API-Py combo search endpoint."""
        import requests

        base_url = self._settings.api_base_url.rstrip("/")
        url = f"{base_url}/api/v1/all/search"
        params = {"query": query, "limit": limit}

        headers = {}
        if self._settings.api_key:
            headers["X-API-Key"] = self._settings.api_key

        try:
            resp = requests.get(url, params=params, headers=headers, timeout=30)
            resp.raise_for_status()
            data = resp.json()
            return data.get("data", [])
        except requests.exceptions.ConnectionError:
            log.error("torrent_api_unreachable", url=url)
            return []
        except requests.exceptions.Timeout:
            log.error("torrent_api_timeout", url=url)
            return []
        except Exception as exc:
            log.error("torrent_fetch_failed", error=str(exc))
            return []

    def _parse_results(
        self, raw_results: List[Dict[str, Any]], query: str
    ) -> List[TorrentResult]:
        """Parse raw API response into TorrentResult objects."""
        results: List[TorrentResult] = []
        for item in raw_results:
            name = item.get("name", "")
            magnet = item.get("magnet", "")
            if not name or not magnet:
                continue

            seeders_str = str(item.get("seeders", "0"))
            leechers_str = str(item.get("leechers", "0"))
            try:
                seeders = int(seeders_str)
            except (ValueError, TypeError):
                seeders = 0
            try:
                leechers = int(leechers_str)
            except (ValueError, TypeError):
                leechers = 0

            size_str = item.get("size", "0")
            size_bytes = _parse_size_bytes(size_str)
            quality = _extract_quality(name)

            result = TorrentResult(
                name=name,
                magnet=magnet,
                hash=item.get("hash", ""),
                seeders=seeders,
                leechers=leechers,
                size=size_str,
                size_bytes=size_bytes,
                source_site=item.get("source", ""),
                quality=quality,
                uploader=item.get("uploader", ""),
                date=item.get("date", ""),
            )
            results.append(result)

        return results

    def _filter_results(self, results: List[TorrentResult]) -> List[TorrentResult]:
        """Filter results by minimum seeders and preferred qualities."""
        min_seeders = self._settings.min_seeders
        preferred = self._settings.preferred_qualities

        filtered: List[TorrentResult] = []
        for r in results:
            if r.seeders < min_seeders:
                continue
            if preferred and r.quality != "unknown" and r.quality not in preferred:
                continue
            filtered.append(r)

        return filtered

    def _rank_results(
        self, results: List[TorrentResult], query: str
    ) -> List[TorrentResult]:
        """Rank results by fuzzy match score and seeders."""
        if not results:
            return []

        max_seeders = max(r.seeders for r in results) or 1

        for r in results:
            match = _fuzzy_score(r.name, query)
            normalized_seeders = r.seeders / max_seeders
            r.match_score = match * 0.6 + normalized_seeders * 0.4

        results.sort(key=lambda r: r.match_score, reverse=True)
        return results

    def _check_cache_availability(self, hashes: List[str]) -> set:
        """Check which hashes are cached on RealDebrid.

        Returns a set of cached hashes.
        """
        if not self._debrid_client or not hashes:
            return set()

        try:
            availability = self._debrid_client.get_instant_availability(hashes)
            cached: set = set()
            for h in hashes:
                entry = availability.get(h)
                if entry and isinstance(entry, dict):
                    rd_info = entry.get("rd")
                    if rd_info:
                        cached.add(h)
            return cached
        except Exception as exc:
            log.warning("cache_check_failed", error=str(exc))
            return set()
