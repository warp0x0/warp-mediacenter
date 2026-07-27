"""Torrent stream orchestrator — wires search and RealDebrid status tracking."""

from __future__ import annotations

import time
from typing import Any, Dict, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.information_handlers.torrent_models import (
    TorrentSearchResponse,
)
from warp_mediacenter.backend.information_handlers.torrent_search import TorrentSearchService
from warp_mediacenter.backend.player.debrid.client import RealDebridClient, RealDebridAPIError

log = get_logger(__name__)


class TorrentStreamError(RuntimeError):
    """Raised when a torrent stream operation fails."""

    pass


class TorrentStreamOrchestrator:
    """Coordinates torrent search and RealDebrid status tracking:

    1. Search torrents via TorrentSearchService
    2. User selects a torrent
    3. Route handlers add/select files in RealDebrid
    4. Client polls status and opens the resolved stream itself
    """

    def __init__(
        self,
        search_service: TorrentSearchService,
        debrid_client: RealDebridClient,
    ) -> None:
        self._search = search_service
        self._debrid = debrid_client
        self._active_torrents: Dict[str, Dict[str, Any]] = {}

    # ------------------------------------------------------------------
    # Search
    # ------------------------------------------------------------------
    def search_and_resolve(
        self,
        title: str,
        media_type: str,
        tmdb_id: str,
        season: Optional[int] = None,
        episode: Optional[int] = None,
        year: Optional[int] = None,
        limit: Optional[int] = None,
    ) -> TorrentSearchResponse:
        """Search for torrents and return ranked results split by cache status.

        This is the entry point when a user clicks a media item that is not
        available locally. It queries Torrent-API-Py, checks RealDebrid
        instant availability, filters, ranks, and returns results.
        """
        log.info(
            "torrent_search_start",
            title=title,
            media_type=media_type,
            season=season,
            episode=episode,
            year=year,
        )

        return self._search.search(
            query=title,
            media_type=media_type,
            season=season,
            episode=episode,
            year=year,
            limit=limit,
        )

    # ------------------------------------------------------------------
    # Status tracking
    # ------------------------------------------------------------------
    def get_download_status(self, torrent_id: str) -> Dict[str, Any]:
        """Return progress and status for a torrent download.

        Used by UI for real-time progress updates (SSE polling).
        """
        active = self._active_torrents.get(torrent_id)
        if active is None:
            return {
                "torrent_id": torrent_id,
                "status": "unknown",
                "progress": 0,
                "message": "Torrent not tracked by orchestrator",
            }

        try:
            info = self._debrid.get_torrent_info(torrent_id)
            status = {
                "torrent_id": torrent_id,
                "name": info.filename,
                "status": info.status,
                "progress": info.progress,
                "speed": info.speed,
                "seeders": info.seeders,
                "links_count": len(info.links),
                "title": active["title"],
                "media_type": active["media_type"],
                "season": active.get("season"),
                "episode": active.get("episode"),
                "elapsed_seconds": round(time.time() - active["started_at"], 1),
            }

            if info.is_complete:
                status["message"] = "Download complete — stream ready"
            elif info.is_error:
                status["message"] = f"Error: {info.status}"
            elif info.is_downloading:
                status["message"] = f"Downloading... {info.progress}%"
            elif info.is_waiting_selection:
                status["message"] = "Waiting for file selection"
            else:
                status["message"] = f"Status: {info.status}"

            return status

        except RealDebridAPIError as exc:
            return {
                "torrent_id": torrent_id,
                "status": "error",
                "progress": 0,
                "message": str(exc),
                "title": active.get("title", ""),
            }

    def list_active_torrents(self) -> Dict[str, Dict[str, Any]]:
        """Return all currently tracked torrents with their latest status."""
        result = {}
        for torrent_id in list(self._active_torrents.keys()):
            result[torrent_id] = self.get_download_status(torrent_id)
        return result

    def clear_completed(self) -> int:
        """Remove completed/errored torrents from tracking. Returns count removed."""
        removed = 0
        for torrent_id in list(self._active_torrents.keys()):
            try:
                info = self._debrid.get_torrent_info(torrent_id)
                if info.is_complete or info.is_error:
                    del self._active_torrents[torrent_id]
                    removed += 1
            except Exception:
                del self._active_torrents[torrent_id]
                removed += 1
        return removed
