"""Torrent stream orchestrator — wires search, RealDebrid, and playback together."""

from __future__ import annotations

import time
from typing import Any, Dict, List, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.information_handlers.torrent_models import (
    TorrentResult,
    TorrentSearchResponse,
)
from warp_mediacenter.backend.information_handlers.torrent_search import TorrentSearchService
from warp_mediacenter.backend.player.debrid.client import RealDebridClient, RealDebridAPIError
from warp_mediacenter.backend.player.debrid.models import TorrentInfo
from warp_mediacenter.backend.player.service import PlaybackService

log = get_logger(__name__)


class TorrentStreamError(RuntimeError):
    """Raised when a torrent stream operation fails."""

    pass


class TorrentStreamOrchestrator:
    """Coordinates the full torrent-to-stream flow:

    1. Search torrents via TorrentSearchService
    2. User selects a torrent
    3. Add magnet to RealDebrid
    4. Select files and wait for download
    5. Extract streamable URL
    6. Pass to PlaybackService for playback
    """

    def __init__(
        self,
        search_service: TorrentSearchService,
        debrid_client: RealDebridClient,
        playback_service: PlaybackService,
    ) -> None:
        self._search = search_service
        self._debrid = debrid_client
        self._playback = playback_service
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
    # Resolve and play
    # ------------------------------------------------------------------
    def play_selected(
        self,
        torrent: TorrentResult,
        title: str,
        media_type: str,
        season: Optional[int] = None,
        episode: Optional[int] = None,
        year: Optional[int] = None,
    ) -> str:
        """Add magnet to RealDebrid, wait for download, and start playback.

        Returns the streamable URL that was passed to the player.
        Raises TorrentStreamError on any failure.
        """
        log.info(
            "torrent_resolve_start",
            torrent_name=torrent.name,
            title=title,
            media_type=media_type,
        )

        try:
            torrent_id = self._debrid.add_magnet(torrent.magnet)
        except RealDebridAPIError as exc:
            raise TorrentStreamError(f"Failed to add magnet to RealDebrid: {exc}") from exc

        self._active_torrents[torrent_id] = {
            "name": torrent.name,
            "title": title,
            "media_type": media_type,
            "season": season,
            "episode": episode,
            "started_at": time.time(),
        }

        try:
            self._debrid.select_files(torrent_id)
        except RealDebridAPIError as exc:
            raise TorrentStreamError(f"Failed to select files: {exc}") from exc

        try:
            info = self._debrid.wait_for_download(torrent_id)
        except RealDebridAPIError as exc:
            raise TorrentStreamError(f"Download failed: {exc}") from exc

        stream_url = self._extract_stream_url(info)
        if not stream_url:
            raise TorrentStreamError(
                f"No streamable URL found for torrent '{torrent.name}'"
            )

        media_kind = "movie" if media_type == "movie" else "episode"
        try:
            self._playback.play(
                source=stream_url,
                title=title,
                media_kind=media_kind,
                season=season,
                episode=episode,
                year=year,
                is_stream=True,
                resume_from_last_position=False,
            )
        except Exception as exc:
            raise TorrentStreamError(f"Failed to start playback: {exc}") from exc

        log.info(
            "torrent_stream_started",
            torrent_id=torrent_id,
            stream_url=stream_url[:80] + "...",
            title=title,
        )

        return stream_url

    def play_best_match(
        self,
        torrents: List[TorrentResult],
        title: str,
        media_type: str,
        season: Optional[int] = None,
        episode: Optional[int] = None,
        year: Optional[int] = None,
        max_attempts: int = 3,
    ) -> str:
        """Try torrents in order until one succeeds.

        Attempts up to max_attempts torrents from the ranked list.
        Returns the streamable URL of the first successful torrent.
        Raises TorrentStreamError if all attempts fail.
        """
        errors: List[str] = []
        for i, torrent in enumerate(torrents[:max_attempts]):
            log.info(
                "torrent_attempt",
                attempt=i + 1,
                max_attempts=max_attempts,
                torrent_name=torrent.name,
                seeders=torrent.seeders,
            )
            try:
                return self.play_selected(
                    torrent=torrent,
                    title=title,
                    media_type=media_type,
                    season=season,
                    episode=episode,
                    year=year,
                )
            except TorrentStreamError as exc:
                errors.append(f"Attempt {i + 1} ({torrent.name[:50]}...): {exc}")
                log.warning("torrent_attempt_failed", attempt=i + 1, error=str(exc))
                continue

        raise TorrentStreamError(
            f"All {max_attempts} torrent attempts failed:\n" + "\n".join(errors)
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
                status["message"] = "Download complete — starting playback"
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

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    @staticmethod
    def _extract_stream_url(info: TorrentInfo) -> Optional[str]:
        """Extract the first streamable URL from torrent info links.

        Prioritizes video files by checking filename extensions.
        """
        if not info.links:
            return None

        video_extensions = (".mp4", ".mkv", ".avi", ".mov", ".webm", ".m4v", ".ts", ".m3u8")

        for link in info.links:
            link_lower = link.lower()
            if any(link_lower.endswith(ext) for ext in video_extensions):
                return link

        if any(f.path.lower().endswith(ext) for f in info.files for ext in video_extensions):
            return info.links[0]

        return info.links[0] if info.links else None
