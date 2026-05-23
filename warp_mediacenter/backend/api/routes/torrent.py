"""Torrent status, search, and resolve routes."""

from __future__ import annotations

import asyncio
import json
from typing import Any, AsyncGenerator, Dict, List, Optional

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.api.middleware import get_container
from warp_mediacenter.backend.player.torrent_stream import TorrentStreamOrchestrator, TorrentStreamError
from warp_mediacenter.backend.information_handlers.torrent_models import TorrentResult
from warp_mediacenter.backend.player.debrid.client import RealDebridClient, RealDebridAPIError

log = get_logger(__name__)

router = APIRouter()

_orchestrator: Optional[TorrentStreamOrchestrator] = None


def set_orchestrator(orchestrator: TorrentStreamOrchestrator) -> None:
    """Set the global orchestrator instance for route handlers."""
    global _orchestrator
    _orchestrator = orchestrator


def _get_orchestrator() -> TorrentStreamOrchestrator:
    """Get orchestrator from container or module-level global."""
    container = get_container()
    if container.torrent_orchestrator is not None:
        return container.torrent_orchestrator
    if _orchestrator is not None:
        return _orchestrator
    raise HTTPException(status_code=503, detail="Torrent orchestrator not initialized")


def _get_debrid_client() -> RealDebridClient:
    """Get RealDebrid client from container or create default."""
    container = get_container()
    if container.debrid_client is not None:
        return container.debrid_client
    return RealDebridClient()


def _torrent_result_to_dict(result: TorrentResult) -> Dict[str, Any]:
    """Convert TorrentResult to a dict."""
    return {
        "name": result.name,
        "hash": result.hash,
        "seeders": result.seeders,
        "leechers": result.leechers,
        "size": result.size,
        "size_bytes": result.size_bytes,
        "source_site": result.source_site,
        "quality": result.quality,
        "is_cached": result.is_cached,
        "match_score": result.match_score,
        "uploader": result.uploader,
        "date": result.date,
    }


# ------------------------------------------------------------------
# Search and resolve endpoints
# ------------------------------------------------------------------

@router.post("/search")
async def search_torrents(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Search torrents for a title.

    Request body:
    - query: Base search term (title)
    - media_type: "movie" or "tv"
    - tmdb_id: TMDb ID (optional)
    - season: Season number (optional, for TV)
    - episode: Episode number (optional, for TV)
    - year: Release year (optional)
    - limit: Max results (default from settings)
    """
    orchestrator = _get_orchestrator()

    query = payload.get("query", "")
    media_type = payload.get("media_type", "movie")
    tmdb_id = payload.get("tmdb_id")
    season = payload.get("season")
    episode = payload.get("episode")
    year = payload.get("year")
    limit = payload.get("limit")

    if not query:
        raise HTTPException(status_code=400, detail="query is required")

    try:
        response = orchestrator.search_and_resolve(
            title=query,
            media_type=media_type,
            tmdb_id=tmdb_id or "",
            season=season,
            episode=episode,
            year=year,
            limit=limit,
        )
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Torrent search failed: {exc}")

    return {
        "cached": [_torrent_result_to_dict(t) for t in response.cached],
        "uncached": [_torrent_result_to_dict(t) for t in response.uncached],
        "query": response.query,
        "media_type": response.media_type,
        "total_results": response.total_results,
    }


@router.post("/resolve")
async def resolve_torrent(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Resolve a torrent to a streamable URL.

    Request body:
    - torrent_hash: Info hash of the torrent to resolve
    - title: Media title
    - media_type: "movie" or "tv"
    - tmdb_id: TMDb ID (optional)
    - season: Season number (optional)
    - episode: Episode number (optional)
    - year: Release year (optional)

    Returns immediately with torrent_id; client should poll SSE for progress.
    """
    orchestrator = _get_orchestrator()
    debrid = _get_debrid_client()

    torrent_hash = payload.get("torrent_hash")
    title = payload.get("title", "Unknown")
    media_type = payload.get("media_type", "movie")
    season = payload.get("season")
    episode = payload.get("episode")
    year = payload.get("year")

    if not torrent_hash:
        raise HTTPException(status_code=400, detail="torrent_hash is required")

    magnet = f"magnet:?xt=urn:btih:{torrent_hash}"

    try:
        torrent_id = debrid.add_magnet(magnet)
        debrid.select_files(torrent_id)

        orchestrator._active_torrents[torrent_id] = {
            "title": title,
            "media_type": media_type,
            "season": season,
            "episode": episode,
            "year": year,
            "status": "waiting",
            "started_at": asyncio.get_event_loop().time() if hasattr(asyncio, "get_event_loop") else 0,
        }

        torrent_info = debrid.get_torrent_info(torrent_id)
        selected_file = None
        if torrent_info.files:
            video_files = [f for f in torrent_info.files if f.selected]
            if video_files:
                selected_file = video_files[0].path

        return {
            "torrent_id": torrent_id,
            "status": torrent_info.status,
            "selected_file": selected_file,
            "message": "Torrent added. Poll /status/{torrent_id}/events for progress.",
        }
    except RealDebridAPIError as exc:
        raise HTTPException(status_code=500, detail=f"RealDebrid error: {exc}")
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Resolve failed: {exc}")


# ------------------------------------------------------------------
# Status and tracking endpoints
# ------------------------------------------------------------------

@router.get("/status/{torrent_id}")
async def get_torrent_status(torrent_id: str) -> Dict[str, Any]:
    """Get current download status for a torrent."""
    orchestrator = _get_orchestrator()
    status = orchestrator.get_download_status(torrent_id)
    if status["status"] == "unknown":
        raise HTTPException(status_code=404, detail=status["message"])
    return status


@router.get("/status/{torrent_id}/events")
async def torrent_status_events(torrent_id: str) -> StreamingResponse:
    """Server-Sent Events endpoint for real-time torrent download progress.

    Streams JSON events every 2 seconds until the torrent is complete,
    errored, or dead. Clients should reconnect if the stream ends.
    """
    orchestrator = _get_orchestrator()

    async def event_generator() -> AsyncGenerator[str, None]:
        while True:
            status = orchestrator.get_download_status(torrent_id)
            event_data = json.dumps(status)
            yield f"data: {event_data}\n\n"

            current_status = status.get("status", "")
            if current_status in ("downloaded", "error", "dead", "unknown"):
                break

            await asyncio.sleep(2)

        yield f"data: {json.dumps({'status': 'stream_ended', 'torrent_id': torrent_id})}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@router.get("/active")
async def list_active_torrents() -> Dict[str, Any]:
    """List all currently tracked torrents with their status."""
    orchestrator = _get_orchestrator()
    return orchestrator.list_active_torrents()


@router.post("/active/clear")
async def clear_completed_torrents() -> Dict[str, int]:
    """Remove completed and errored torrents from tracking."""
    orchestrator = _get_orchestrator()
    removed = orchestrator.clear_completed()
    return {"removed": removed}
