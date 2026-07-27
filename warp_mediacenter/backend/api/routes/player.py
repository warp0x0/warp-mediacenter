"""Preload-session and playback scrobble routes for Warp MediaCenter API."""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone
import os
import re
from typing import Any, AsyncGenerator, Dict, Optional

import aiohttp
from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse
from starlette.background import BackgroundTask

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.api.middleware import get_container
from warp_mediacenter.backend.information_handlers.models import MediaType
from warp_mediacenter.backend.information_handlers.trakt_manager import TraktScrobbleConflict
from warp_mediacenter.backend.player.preload_session_manager import (
    PreloadSessionCapacityError,
    PreloadSessionManager,
)

log = get_logger(__name__)

router = APIRouter()

_EXT_TO_EXTERNAL_MIME = {
    ".mkv": "video/x-matroska",
    ".mp4": "video/mp4",
    ".m4v": "video/mp4",
    ".mov": "video/quicktime",
    ".webm": "video/webm",
    ".avi": "video/x-msvideo",
    ".ts": "video/mp2t",
    ".m2ts": "video/mp2t",
}


def _get_preload_manager() -> PreloadSessionManager:
    container = get_container()
    manager = container.preload_session_manager
    if manager is None:
        raise HTTPException(status_code=503, detail="Preload session manager not initialized")
    return manager


def _get_trakt_manager() -> Any:
    container = get_container()
    manager = container.trakt_manager
    if manager is None:
        raise HTTPException(status_code=503, detail="Trakt manager not initialized")
    return manager


def _normalize_scrobble_media_type(value: Any) -> MediaType:
    raw = str(value or "").strip().lower()
    if raw == "tv":
        raw = "episode"
    try:
        media_type = MediaType(raw)
    except Exception:
        raise HTTPException(status_code=400, detail="media_type must be 'movie' or 'episode'")

    if media_type not in {MediaType.MOVIE, MediaType.EPISODE}:
        raise HTTPException(status_code=400, detail="media_type must be 'movie' or 'episode'")
    return media_type


def _normalize_scrobble_progress(value: Any) -> float:
    try:
        progress = float(value)
    except (TypeError, ValueError):
        raise HTTPException(status_code=400, detail="progress must be a number between 0 and 100")
    if progress < 0.0 or progress > 100.0:
        raise HTTPException(status_code=400, detail="progress must be a number between 0 and 100")
    return progress


def _run_scrobble(action: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    media_payload = payload.get("media")
    if not isinstance(media_payload, dict):
        raise HTTPException(status_code=400, detail="media payload is required")

    media_type = _normalize_scrobble_media_type(payload.get("media_type"))
    progress = _normalize_scrobble_progress(payload.get("progress"))
    session_id = str(payload.get("session_id") or "").strip() or None

    # Episode scrobble: Flutter sends show info as "media" and the episode's
    # season/number under an "episode" key.  The Trakt manager expects
    #   media  = episode payload  (season, number, ids)
    #   show   = show payload     (title, ids with tmdb)
    # Remap so the manager builds the correct Trakt request body.
    show_payload = payload.get("show")
    if media_type == MediaType.EPISODE:
        episode_key_payload = payload.get("episode")
        if isinstance(episode_key_payload, dict):
            show_payload = show_payload or media_payload   # show info was in "media"
            media_payload = episode_key_payload            # episode season/number

    manager = _get_trakt_manager()
    try:
        result = manager.scrobble(
            media_type=media_type,
            media=media_payload,
            progress=progress,
            action=action,
            show=show_payload,
        )
    except TraktScrobbleConflict as exc:
        return {
            "ok": False,
            "conflict": True,
            "session_id": session_id,
            "action": action,
            "media_type": media_type.value,
            "progress": progress,
            "watched_at": exc.watched_at.isoformat() if exc.watched_at else None,
            "expires_at": exc.expires_at.isoformat() if exc.expires_at else None,
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Scrobble {action} failed: {exc}")

    # After a stop scrobble, the continue-watching + show-progress caches are stale.
    # Clear them so the next Flutter fetch returns fresh Trakt data immediately.
    if action == "stop":
        try:
            from warp_mediacenter.backend.api.routes.discovery import (  # noqa: PLC0415
                invalidate_trakt_continue_watching_caches,
            )
            invalidate_trakt_continue_watching_caches()
        except Exception:
            pass

    return {
        "ok": True,
        "conflict": False,
        "session_id": session_id,
        "action": action,
        "media_type": media_type.value,
        "progress": progress,
        "response": result.model_dump(mode="json") if hasattr(result, "model_dump") else {},
    }


def _safe_stream_filename(value: Any) -> str:
    name = os.path.basename(str(value or "").strip()) or "stream"
    name = re.sub(r"[^A-Za-z0-9._ -]+", "_", name).strip(" .")
    return name or "stream"


def _session_stream_filename(session: Any) -> str:
    proxy_name = getattr(session.proxy, "_filename", None)
    if proxy_name:
        return _safe_stream_filename(proxy_name)

    snapshot_fn = getattr(session, "snapshot", None)
    if callable(snapshot_fn):
        snapshot = snapshot_fn()
        file_path = snapshot.get("file_path")
        if file_path:
            return _safe_stream_filename(file_path)

    return _safe_stream_filename(session.title)


def _external_content_type(filename: str) -> Optional[str]:
    return _EXT_TO_EXTERNAL_MIME.get(os.path.splitext(filename)[1].lower())


def _require_preload_session(manager: PreloadSessionManager, session_id: str) -> Any:
    require_session = getattr(manager, "require_session", None)
    if callable(require_session):
        return require_session(session_id)
    return manager.acquire_stream(session_id)


def _session_response(
    request: Request,
    session_id: str,
    playback_url: str,
    external_playback_url: Optional[str] = None,
) -> Dict[str, Any]:
    return {
        "session_id": session_id,
        "playback_url": playback_url,
        "external_playback_url": external_playback_url or playback_url,
        "status_url": str(
            request.url_for(
                "player_preload_session_status",
                session_id=session_id,
            )
        ),
        "cleanup_url": str(
            request.url_for(
                "player_preload_session_delete",
                session_id=session_id,
            )
        ),
        "created_at": datetime.now(timezone.utc).isoformat(),
    }


@router.post("/preload/session")
async def create_preload_session(payload: Dict[str, Any], request: Request) -> Dict[str, Any]:
    """Create a buffered preload session for a remote stream URL or local torrent.

    Accepts either:
      - ``stream_url``: CDN/RD URL — downloaded via StreamProxy in a thread
      - ``magnet``:     Magnet URI  — downloaded locally via libtorrent
    """
    stream_url    = str(payload.get("stream_url", "")).strip()
    magnet        = str(payload.get("magnet",     "")).strip()
    title         = payload.get("title")
    media_kind    = payload.get("media_kind")
    start_percent_raw = payload.get("start_percent")
    start_percent = float(start_percent_raw) if start_percent_raw is not None else 0.0

    if not stream_url and not magnet:
        raise HTTPException(status_code=400, detail="stream_url or magnet is required")

    manager = _get_preload_manager()
    try:
        if magnet:
            # Blocking call: waits for libtorrent metadata + StreamProxy start (~seconds).
            # Wrapped in asyncio.to_thread so FastAPI's event loop stays responsive.
            session = await asyncio.to_thread(
                manager.create_libtorrent_session,
                magnet,
                title=title,
                media_kind=media_kind,
                start_percent=start_percent,
            )
        else:
            # Blocking call: waits for CDN headers (~seconds).
            session = await asyncio.to_thread(
                manager.create_session,
                stream_url,
                title=title,
                media_kind=media_kind,
                start_percent=start_percent,
            )
    except TimeoutError as exc:
        raise HTTPException(status_code=504, detail=str(exc))
    except PreloadSessionCapacityError as exc:
        raise HTTPException(status_code=429, detail=str(exc))
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to create preload session: {exc}")

    # Both CDN and libtorrent sessions use the FastAPI stream endpoint as the
    # playback URL.  The StreamProxy loopback is an internal server-side detail
    # proxied by that endpoint — clients (mpv) never need to know about it, and
    # it won't be reachable when the backend is on a separate server.
    filename = _session_stream_filename(session)
    playback_url = str(
        request.url_for("player_preload_session_stream", session_id=session.session_id)
    )
    external_playback_url = str(
        request.url_for(
            "player_preload_session_stream_named",
            session_id=session.session_id,
            filename=filename,
        )
    )

    response = _session_response(
        request,
        session.session_id,
        playback_url,
        external_playback_url,
    )
    response["created_at"] = session.created_at.isoformat()
    return response


@router.get("/preload/session/{session_id}/status", name="player_preload_session_status")
async def preload_session_status(session_id: str, request: Request) -> Dict[str, Any]:
    """Return preload progress and state for a session."""
    manager = _get_preload_manager()
    try:
        payload = manager.get_status(session_id)
        filename = _session_stream_filename(_require_preload_session(manager, session_id))
        payload["playback_url"] = str(
            request.url_for(
                "player_preload_session_stream",
                session_id=session_id,
            )
        )
        payload["external_playback_url"] = str(
            request.url_for(
                "player_preload_session_stream_named",
                session_id=session_id,
                filename=filename,
            )
        )
        return payload
    except KeyError:
        raise HTTPException(status_code=404, detail=f"Unknown preload session '{session_id}'")


@router.delete("/preload/session/{session_id}", name="player_preload_session_delete")
async def delete_preload_session(session_id: str) -> Dict[str, Any]:
    """Stop and remove a preload session."""
    manager = _get_preload_manager()
    removed = manager.stop_session(session_id)
    if not removed:
        raise HTTPException(status_code=404, detail=f"Unknown preload session '{session_id}'")
    return {"session_id": session_id, "removed": True}


@router.get(
    "/preload/session/{session_id}/stream/{filename:path}",
    name="player_preload_session_stream_named",
)
@router.get("/preload/session/{session_id}/stream", name="player_preload_session_stream")
async def preload_session_stream(
    session_id: str,
    request: Request,
    filename: str = "",
) -> StreamingResponse:
    """Proxy bytes from a preload session's local stream URL."""
    manager = _get_preload_manager()
    try:
        session = manager.acquire_stream(session_id)
    except KeyError:
        raise HTTPException(status_code=404, detail=f"Unknown preload session '{session_id}'")

    range_header = request.headers.get("range")
    forward_headers: Dict[str, str] = {}
    if range_header:
        forward_headers["Range"] = range_header

    client = aiohttp.ClientSession()
    try:
        upstream = await client.get(
            session.proxy.local_url,
            headers=forward_headers,
            timeout=aiohttp.ClientTimeout(total=3600),
        )
    except Exception:
        manager.release_stream(session_id)
        await client.close()
        raise

    if upstream.status >= 400:
        manager.release_stream(session_id)
        upstream.release()
        await client.close()
        raise HTTPException(status_code=upstream.status, detail="Upstream preload stream unavailable")

    content_length = upstream.headers.get("Content-Length")
    content_range = upstream.headers.get("Content-Range")
    content_type = upstream.headers.get("Content-Type", "application/octet-stream")

    # Forward the original filename as a Content-Disposition hint so that mpv
    # (and other players) can use the file extension for demuxer selection even
    # when the endpoint URL has no extension.
    named_stream_requested = bool(filename)
    filename = _safe_stream_filename(
        filename or getattr(session.proxy, "_filename", None) or "stream"
    )
    if named_stream_requested:
        content_type = _external_content_type(filename) or content_type
    response_headers: Dict[str, str] = {
        "Accept-Ranges": "bytes",
        "Content-Type": content_type,
        "Content-Disposition": f'inline; filename="{filename}"',
    }
    if content_range:
        response_headers["Content-Range"] = content_range
        response_headers["Content-Length"] = upstream.headers.get("Content-Length", "0")
    elif content_length:
        response_headers["Content-Length"] = content_length

    cleanup_done = False

    async def cleanup_upstream() -> None:
        nonlocal cleanup_done
        if cleanup_done:
            return
        cleanup_done = True
        try:
            upstream.release()
        except Exception:
            pass
        try:
            await client.close()
        except Exception:
            pass
        manager.release_stream(session_id)

    async def chunk_iterator() -> AsyncGenerator[bytes, None]:
        try:
            async for chunk in upstream.content.iter_chunked(1024 * 1024):
                yield chunk
        finally:
            await cleanup_upstream()

    return StreamingResponse(
        chunk_iterator(),
        status_code=upstream.status,
        headers=response_headers,
        background=BackgroundTask(cleanup_upstream),
    )


@router.post("/scrobble/start")
async def scrobble_start(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Send Trakt scrobble start for a playback session."""
    return _run_scrobble("start", payload)


@router.post("/scrobble/stop")
async def scrobble_stop(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Send Trakt scrobble stop for a playback session."""
    return _run_scrobble("stop", payload)
