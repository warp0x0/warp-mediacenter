"""Torrent status, search, and resolve routes."""

from __future__ import annotations

import asyncio
import json
import re
from typing import Any, AsyncGenerator, Dict, List, Optional
from urllib.parse import parse_qsl, urlencode, urlparse

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.api.middleware import get_container
from warp_mediacenter.backend.player.torrent_stream import TorrentStreamOrchestrator, TorrentStreamError
from warp_mediacenter.backend.information_handlers.torrent_models import TorrentResult
from warp_mediacenter.backend.player.debrid.client import RealDebridClient, RealDebridAPIError
from warp_mediacenter.backend.player.debrid.oauth import RealDebridOAuthError
from warp_mediacenter.backend.player.libtorrent_manager import extract_info_hash_from_magnet

log = get_logger(__name__)

router = APIRouter()

_orchestrator: Optional[TorrentStreamOrchestrator] = None
_HEX_INFO_HASH_RE = re.compile(r"^[A-Fa-f0-9]{40}$")
_BASE32_INFO_HASH_RE = re.compile(r"^[A-Z2-7a-z]{32}$")


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
        "name":        result.name,
        "hash":        result.hash,
        "magnet":      result.magnet,
        "seeders":     result.seeders,
        "leechers":    result.leechers,
        "size":        result.size,
        "size_bytes":  result.size_bytes,
        "source_site": result.source_site,
        "quality":     result.quality,
        "is_cached":   result.is_cached,
        "match_score": result.match_score,
        "uploader":    result.uploader,
        "date":        result.date,
    }


def _normalise_btih(value: Any) -> Optional[str]:
    text = str(value or "").strip()
    if text.lower().startswith("urn:btih:"):
        text = text[9:]
    if _HEX_INFO_HASH_RE.fullmatch(text) or _BASE32_INFO_HASH_RE.fullmatch(text):
        return text.upper()
    return None


def _extract_btih_from_magnet(magnet: str) -> Optional[str]:
    if not magnet:
        return None
    try:
        parsed = urlparse(magnet)
        if parsed.scheme != "magnet":
            return None
        for key, value in parse_qsl(parsed.query, keep_blank_values=True):
            if key == "xt" and value.lower().startswith("urn:btih:"):
                return _normalise_btih(value)
    except Exception:
        return None
    return None


def _build_magnet(info_hash: str, source_magnet: str = "") -> str:
    pairs = [("xt", f"urn:btih:{info_hash}")]
    try:
        for key, value in parse_qsl(urlparse(source_magnet).query, keep_blank_values=True):
            if key != "xt":
                pairs.append((key, value))
    except Exception:
        pass
    return f"magnet:?{urlencode(pairs, doseq=True, safe=':/')}"


def _recover_info_hash_from_magnet(magnet: str) -> Optional[str]:
    if not magnet:
        return None
    try:
        recovered = extract_info_hash_from_magnet(magnet)
        if recovered:
            return recovered
    except Exception as exc:
        log.warning("torrent_hash_libtorrent_recovery_failed", error=str(exc)[:200])
    return _extract_btih_from_magnet(magnet)


def _is_missing_hash_error(exc: RealDebridAPIError) -> bool:
    text = f"{exc.error} {exc}".lower()
    return "torrent hash is missing" in text or ("hash" in text and "missing" in text)


def _is_rd_legal_block(exc: RealDebridAPIError) -> bool:
    text = f"{exc.error} {exc}".lower()
    return (
        exc.status_code == 451
        or exc.error_code in (22, 23)
        or "infringing" in text
        or "copyright" in text
        or "dmca" in text
        or "unavailable for legal" in text
    )


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
        "filtered":   [_torrent_result_to_dict(t) for t in response.filtered],
        "unfiltered": [_torrent_result_to_dict(t) for t in response.unfiltered],
        "query":      response.query,
        "media_type": response.media_type,
    }


@router.post("/resolve")
async def resolve_torrent(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Resolve a torrent to a streamable URL.

    Request body:
    - torrent_hash: Info hash of the torrent to resolve
    - magnet: Original magnet URI (optional fallback for missing/bad hashes)
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

    torrent_hash = _normalise_btih(payload.get("torrent_hash"))
    source_magnet = str(payload.get("magnet") or "").strip()
    title = payload.get("title", "Unknown")
    media_type = payload.get("media_type", "movie")
    season = payload.get("season")
    episode = payload.get("episode")
    year = payload.get("year")

    if not torrent_hash:
        torrent_hash = _extract_btih_from_magnet(source_magnet)
    if not torrent_hash and source_magnet:
        torrent_hash = await asyncio.to_thread(_recover_info_hash_from_magnet, source_magnet)
        if torrent_hash:
            log.info("torrent_resolve_hash_recovered", hash=torrent_hash[:12])
    if not torrent_hash:
        raise HTTPException(status_code=400, detail="torrent_hash or magnet with info hash is required")

    magnet = _build_magnet(torrent_hash, source_magnet)

    log.info("torrent_resolve_start", hash=torrent_hash[:12], title=title, media_type=media_type)

    try:
        log.info("torrent_resolve_adding_magnet", hash=torrent_hash[:12])
        try:
            torrent_id = debrid.add_magnet(magnet)
        except RealDebridAPIError as exc:
            if not source_magnet or not _is_missing_hash_error(exc):
                raise
            recovered_hash = await asyncio.to_thread(_recover_info_hash_from_magnet, source_magnet)
            if not recovered_hash or recovered_hash == torrent_hash:
                raise
            torrent_hash = recovered_hash
            magnet = _build_magnet(torrent_hash, source_magnet)
            log.info("torrent_resolve_retry_recovered_hash", hash=torrent_hash[:12])
            torrent_id = debrid.add_magnet(magnet)

        log.info("torrent_resolve_selecting_files", torrent_id=torrent_id)
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

        log.info(
            "torrent_resolve_complete",
            torrent_id=torrent_id,
            status=torrent_info.status,
            file_count=len(torrent_info.files) if torrent_info.files else 0,
            selected_file=selected_file,
        )

        return {
            "torrent_id": torrent_id,
            "status": torrent_info.status,
            "selected_file": selected_file,
            "message": "Torrent added. Poll /status/{torrent_id}/events for progress.",
        }
    except RealDebridOAuthError as exc:
        log.error("resolve_auth_error", error=str(exc)[:200])
        raise HTTPException(
            status_code=401,
            detail=f"RealDebrid not authenticated. Run 'media debrid auth' to set up. Error: {exc}",
        )
    except RealDebridAPIError as exc:
        log.error("resolve_rd_error", status=exc.status_code, error=exc.error, code=exc.error_code)
        # HTTP 451 = Unavailable for Legal Reasons (RD blocks the whole torrent).
        # Error code 22 = "Infringing file", 23 = "Copyright DMCAed file" (per RD API docs).
        # All three mean the same thing to the client: offer the local libtorrent path.
        if _is_rd_legal_block(exc):
            raise HTTPException(
                status_code=422,
                detail="RealDebrid blocked this torrent (copyright/legal). Download locally via libtorrent instead.",
            )
        raise HTTPException(status_code=500, detail=f"RealDebrid error: {exc}")
    except Exception as exc:
        log.error("resolve_unexpected_error", error=str(exc)[:200], type=type(exc).__name__)
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
