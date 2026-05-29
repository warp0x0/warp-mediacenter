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
_QUALITY_RE = re.compile(r"(2160p|4K|UHD|1080p|720p|480p|HDR|SDR|WEBRip|BluRay|BRRip|WEB-DL|HDTV|CAM|TS|TC|SCR)", re.IGNORECASE)

# TV-show patterns — used to exclude TV content when searching for movies
_TV_PATTERN_RE = re.compile(
    r"\bS\d{1,2}E\d{1,2}\b"         # S01E01
    r"|\bSeason[\s._-]?\d+\b"        # Season 1 / Season.1
    r"|\bEpisode[\s._-]?\d+\b"       # Episode 1
    r"|\bComplete[\s._-]Series\b"    # Complete Series
    r"|\bMini[\s._-]Series\b",       # Mini-Series
    re.IGNORECASE,
)

# Real Debrid blocked/problematic tags (May 2026 French FNEF law compliance)
# Sources: RD community reports, FNEF notices, public tracker announcements
#
# "WEB" source family — all three forms must be blocked:
#   WEB-DL / WEBDL / WEB.DL       → explicit download rip
#   WEBRip / WEB-Rip / WEB.Rip    → re-encoded web download
#   WEB <codec>  (no DL/Rip)      → standalone WEB source tag, e.g.
#                                    "1080p WEB H264-GROUP", "720p WEB x265"
#                                    This is the form the old filter MISSED.
_RD_BLOCKED_PATTERNS: List[re.Pattern] = [
    # WEB-DL variants
    re.compile(r"\bWEB[-.]?DL\b", re.IGNORECASE),
    # WEBRip variants
    re.compile(r"\bWEB[-.]?Rip\b", re.IGNORECASE),
    # Standalone WEB source tag followed by a video codec.
    # Matches: "WEB H264", "WEB-H264", "WEB.H265", "WEB x265", "WEB HEVC", etc.
    # Uses a word-boundary after the codec so "WEB H264-GROUP" also matches.
    re.compile(r"\bWEB[\s._-]+(?:H26[45]|x26[45]|HEVC|AVC)\b", re.IGNORECASE),
    # Release groups blocked by RD
    re.compile(r"\bYTS\b", re.IGNORECASE),
    re.compile(r"\[?RARBG\]?", re.IGNORECASE),
    re.compile(r"\[?EZTV\]?", re.IGNORECASE),
    re.compile(r"\[?RARTV\]?", re.IGNORECASE),
    # Streaming-platform origin tags blocked by RD
    re.compile(r"\bAMZN\b", re.IGNORECASE),   # Amazon
    re.compile(r"\bNF\b", re.IGNORECASE),     # Netflix
    re.compile(r"\bCR\b", re.IGNORECASE),     # Crunchyroll
    re.compile(r"\bDSNP\b", re.IGNORECASE),   # Disney+
    re.compile(r"\bATVP\b", re.IGNORECASE),   # Apple TV+
    re.compile(r"\bHMAX\b", re.IGNORECASE),   # HBO Max / Max
]

# ── Non-video content filters ─────────────────────────────────────────────────
# Executable / installer file extensions embedded in the torrent name
_EXEC_EXT_RE = re.compile(
    r"\.(exe|msi|sh|bat|cmd|dmg|pkg|apk|deb|rpm|run|bin|appimage)\b",
    re.IGNORECASE,
)

# Game scene release groups — these almost never appear in movie/TV torrents
_GAME_GROUP_RE = re.compile(
    r"\b(SKIDROW|CODEX|RELOADED|EMPRESS|PLAZA|CPY|FLT|DODI|GOG|HOODLUM|PROPHET|RAZOR|TiNYiSO|TENOKE|P2P\.GAME|FitGirl)\b",
    re.IGNORECASE,
)

# Software / game content keywords — matched as whole words or clear phrases.
# Patterns are deliberately specific to avoid false-positives on movie titles.
_NON_VIDEO_KEYWORD_RE = re.compile(
    # Classic warez / crack tools — rarely appear in movie/show names
    r"\b(keygen|key\.gen|key-gen|cheat[\s._-]?engine|serial[\s._-]?key|activat(?:or|ion))\b"
    # "crack" only when it is a trailing tag, not a title word:
    # e.g. "GameName.crack.only"  →  blocked
    #      "Cracked.2024.BluRay"  →  passed (crack is the first word / title)
    r"|(?<=[._\-\s])crack(?:ed|\.only|[\s._-]only)?\b"
    # "Patch.Only" or "NoPatch" style — clearly a software patch, not a movie
    r"|\bno[\s._-]?patch\b|\bpatch[\s._-]?only\b"
    # Portable software: "Portable v1.2" or "Portable.v3" — version number required
    r"|\bportable[\s._-]v\d"
    # Installer: "Setup v3" — version number required to avoid "The Setup (2019)"
    r"|\bsetup[\s._-]v\d"
    # Video game content markers
    r"|\bfull[\s._-]game\b"
    r"|\bGOTY\b|game[\s._-]of[\s._-]the[\s._-]year"
    r"|\btrainer\b(?:[\s._-]?\+\d)"  # "+15 Trainer" — cheat trainer with feature count
    # Software version targeting a specific OS: "v2.3.Windows" / "v1.0.x64"
    r"|v\d+\.\d+[\s._-](?:win(?:dows)?|linux|mac(?:os)?|x64|x86|32bit|64bit)\b",
    re.IGNORECASE,
)

# Resolution rank — lower number = higher priority
_RESOLUTION_RANK: Dict[str, int] = {
    "2160p": 0,
    "4K":    0,
    "1080p": 1,
    "720p":  2,
    "480p":  3,
}


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
    """Extract quality tag from torrent name.

    Normalises '4K' and 'UHD' to '2160p' so the resolution-rank lookup
    always uses a canonical key.
    """
    match = _QUALITY_RE.search(name)
    if not match:
        return "unknown"
    tag = match.group(1)
    # Normalise aliases so _RESOLUTION_RANK has a single key to check
    if tag.upper() in ("4K", "UHD"):
        return "2160p"
    return tag


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

        cached_json = self._get_cached_results(search_query, media_type)
        if cached_json is not None:
            log.info("torrent_search_cache_hit", query=search_query)
            return self._rebuild_response(cached_json, media_type)

        raw_results = self._fetch_torrents(search_query)
        if not raw_results:
            log.info("torrent_search_no_results", query=search_query)
            return TorrentSearchResponse(query=search_query, media_type=media_type)

        # ── filtering pipeline ──────────────────────────────────────────────
        parsed   = self._parse_results(raw_results, search_query)
        filtered = self._filter_non_video(parsed)            # drop games/apps/exes first
        filtered = self._filter_by_min_seeders(filtered)
        filtered = self._filter_by_fuzzy_match(filtered, query, year)
        filtered = self._filter_by_media_type(filtered, media_type)
        filtered = self._filter_rd_exclusions(filtered)

        # ── sort: resolution first, then file size ─────────────────────────
        sorted_results = self._sort_results(filtered)

        # ── RD cache check (best-effort, non-blocking) ─────────────────────
        hashes = [r.hash for r in sorted_results if r.hash]
        cached_hashes, cache_check_ok = (
            self._check_cache_availability(hashes) if hashes else (set(), False)
        )

        rd_cached: List[TorrentResult] = []
        rd_uncached: List[TorrentResult] = []
        for r in sorted_results:
            r.is_cached = r.hash in cached_hashes
            if r.is_cached:
                rd_cached.append(r)
            else:
                rd_uncached.append(r)

        response = TorrentSearchResponse(
            cached=rd_cached,
            uncached=rd_uncached,
            query=search_query,
            media_type=media_type,
            total_results=len(rd_cached) + len(rd_uncached),
        )

        if cache_check_ok:
            self._cache_results(search_query, media_type, response)

        log.info(
            "torrent_search_complete",
            query=search_query,
            total=len(sorted_results),
            rd_cached=len(rd_cached),
            rd_uncached=len(rd_uncached),
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
        if media_type == "tv" and season is not None and episode is not None:
            parts.append(f"S{season:02d}E{episode:02d}")
        elif year is not None:
            # Append year for movies so the tracker search is more precise
            parts.append(str(year))
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

    def _fetch_torrents(self, query: str) -> List[Dict[str, Any]]:
        """Fetch raw torrent results from Torrent-API-Py combo search endpoint.

        No limit is passed so we get the full result set from every site —
        post-fetch filtering and sorting will narrow it down.
        """
        import requests

        base_url = self._settings.api_base_url.rstrip("/")
        url = f"{base_url}/api/v1/all/search"
        params: Dict[str, Any] = {"query": query}

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

    # ------------------------------------------------------------------
    # Filtering pipeline
    # ------------------------------------------------------------------

    def _filter_by_min_seeders(self, results: List[TorrentResult]) -> List[TorrentResult]:
        """Drop results below the configured minimum seeders threshold."""
        min_seeders = self._settings.min_seeders
        return [r for r in results if r.seeders >= min_seeders]

    @staticmethod
    def _filter_by_fuzzy_match(
        results: List[TorrentResult],
        title: str,
        year: Optional[int],
        threshold: float = 0.45,
    ) -> List[TorrentResult]:
        """Keep results whose name fuzzy-matches the expected title (+ year).

        We build a reference string like "Inception 2010" and accept anything
        that scores above `threshold` (0–1).  The bar is intentionally loose
        because torrent names include extra tags — we just want obvious
        off-topic results gone.
        """
        reference = f"{title} {year}" if year else title
        kept: List[TorrentResult] = []
        for r in results:
            score = _fuzzy_score(r.name, reference)
            r.match_score = score
            if score >= threshold:
                kept.append(r)
        log.debug(
            "fuzzy_filter",
            reference=reference,
            before=len(results),
            after=len(kept),
            threshold=threshold,
        )
        return kept

    @staticmethod
    def _filter_by_media_type(
        results: List[TorrentResult], media_type: str
    ) -> List[TorrentResult]:
        """For movie searches, remove results that look like TV episodes/seasons."""
        if media_type != "movie":
            return results
        kept = [r for r in results if not _TV_PATTERN_RE.search(r.name)]
        log.debug("media_type_filter", before=len(results), after=len(kept))
        return kept

    @staticmethod
    def _filter_non_video(results: List[TorrentResult]) -> List[TorrentResult]:
        """Remove torrents that are clearly games, software, or executable bundles.

        Checks three independent signals — any one is enough to drop the result:
          1. Executable file extensions in the torrent name (.exe, .msi, .sh, etc.)
          2. Known game scene release-group tags (SKIDROW, CODEX, EMPRESS, …)
          3. Software/game-specific keywords (keygen, crack, Full Game, GOTY, …)
        """
        kept: List[TorrentResult] = []
        for r in results:
            if (
                _EXEC_EXT_RE.search(r.name)
                or _GAME_GROUP_RE.search(r.name)
                or _NON_VIDEO_KEYWORD_RE.search(r.name)
            ):
                continue
            kept.append(r)
        log.debug("non_video_filter", before=len(results), after=len(kept))
        return kept

    @staticmethod
    def _filter_rd_exclusions(results: List[TorrentResult]) -> List[TorrentResult]:
        """Remove torrents that match Real Debrid blocked tags/groups.

        RD started blocking a broad set of web-sourced and streaming-platform
        releases under French FNEF law pressure (May 2026).  Keeping these in
        the results would lead to add-to-debrid failures at play time.
        """
        kept: List[TorrentResult] = []
        for r in results:
            blocked = any(pat.search(r.name) for pat in _RD_BLOCKED_PATTERNS)
            if not blocked:
                kept.append(r)
        log.debug("rd_exclusion_filter", before=len(results), after=len(kept))
        return kept

    # ------------------------------------------------------------------
    # Sorting
    # ------------------------------------------------------------------

    @staticmethod
    def _sort_results(results: List[TorrentResult]) -> List[TorrentResult]:
        """Sort results: primary = resolution (4K first), secondary = file size (larger first).

        Resolution priority: 2160p/4K → 1080p → 720p → 480p → unknown
        Within each resolution bucket, prefer larger files (better encode quality).
        """
        def _sort_key(r: TorrentResult):
            # Normalise the quality tag to get a rank (unknown → worst)
            quality_norm = r.quality.upper().strip() if r.quality else ""
            rank = _RESOLUTION_RANK.get(quality_norm, len(_RESOLUTION_RANK))
            # Negate size_bytes so that sort ascending == size descending
            return (rank, -r.size_bytes)

        return sorted(results, key=_sort_key)

    def _check_cache_availability(self, hashes: List[str]) -> tuple:
        """Check which hashes are cached on RealDebrid.

        Returns a (cached_set, check_ok) tuple. check_ok is False
        if the API call failed (e.g., auth error), meaning results
        should not be cached.
        """
        if not self._debrid_client or not hashes:
            return set(), False

        log.info("cache_check_start", hash_count=len(hashes))

        try:
            norm_hashes = [h.upper().strip() for h in hashes]
            availability = self._debrid_client.get_instant_availability(norm_hashes)
            log.info("cache_check_response", entries=len(availability) if isinstance(availability, dict) else type(availability).__name__)
            cached: set = set()
            for h in hashes:
                h_norm = h.upper().strip()
                entry = availability.get(h_norm)
                if entry and isinstance(entry, dict):
                    rd_info = entry.get("rd")
                    if rd_info:
                        cached.add(h)
            log.info("cache_check_result", cached=len(cached), total=len(hashes))
            return cached, True
        except Exception as exc:
            log.warning("cache_check_failed", error=str(exc)[:200])
            return set(), False
