"""Player control routes for Warp MediaCenter API."""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone
import json
from typing import Any, AsyncGenerator, Dict, Optional

import aiohttp
from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.api.middleware import get_container
from warp_mediacenter.backend.information_handlers.models import MediaType
from warp_mediacenter.backend.information_handlers.trakt_manager import TraktScrobbleConflict
from warp_mediacenter.backend.player.controller import PlayerController, PlayRequest
from warp_mediacenter.backend.player.adapter import PlaybackState
from warp_mediacenter.backend.player.preload_session_manager import (
    PreloadSessionCapacityError,
    PreloadSessionManager,
)

log = get_logger(__name__)

router = APIRouter()

_player_controller: Optional[PlayerController] = None


def set_player_controller(controller: PlayerController) -> None:
    """Set the global player controller instance for route handlers."""
    global _player_controller
    _player_controller = controller


def _get_player() -> PlayerController:
    """Get player controller from container or module-level global."""
    container = get_container()
    if container.player_controller is not None:
        return container.player_controller
    if _player_controller is not None:
        return _player_controller
    raise HTTPException(status_code=503, detail="Player controller not initialized")


def _state_to_dict(state: Optional[PlaybackState]) -> Dict[str, Any]:
    """Convert PlaybackState to a dict."""
    if state is None:
        return {"playing": False}
    return {
        "playing": state.state == "playing",
        "title": state.title,
        "media_kind": state.media_kind,
        "source": state.source,
        "state": state.state,
        "position_ms": state.position_ms,
        "duration_ms": state.duration_ms,
        "volume": state.volume,
        "rate": state.rate,
        "is_stream": state.is_stream,
        "subtitle_path": state.subtitle_path,
        "audio_track_id": state.audio_track_id,
        "subtitle_track_id": state.subtitle_track_id,
        "started_at": state.started_at.isoformat() if state.started_at else None,
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

    show_payload = payload.get("show")
    if show_payload is not None and not isinstance(show_payload, dict):
        raise HTTPException(status_code=400, detail="show must be an object when provided")

    media_type = _normalize_scrobble_media_type(payload.get("media_type"))
    progress = _normalize_scrobble_progress(payload.get("progress"))
    session_id = str(payload.get("session_id") or "").strip() or None

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

    return {
        "ok": True,
        "conflict": False,
        "session_id": session_id,
        "action": action,
        "media_type": media_type.value,
        "progress": progress,
        "response": result.model_dump(mode="json") if hasattr(result, "model_dump") else {},
    }


def _session_response(request: Request, session_id: str, playback_url: str) -> Dict[str, Any]:
    return {
        "session_id": session_id,
        "playback_url": playback_url,
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

    snap      = session.snapshot()
    local_url = snap.get("local_url") or getattr(session.proxy, "local_url", None)

    if magnet:
        # Libtorrent: StreamProxy loopback IS the playback URL (no FastAPI stream hop)
        playback_url = local_url or ""
    else:
        # RD/CDN: FastAPI proxy serves byte-range requests; local_url is the loopback shortcut
        playback_url = str(
            request.url_for("player_preload_session_stream", session_id=session.session_id)
        )

    response = _session_response(request, session.session_id, playback_url)
    response["created_at"] = session.created_at.isoformat()
    response["local_url"]  = local_url
    return response


@router.get("/preload/session/{session_id}/status", name="player_preload_session_status")
async def preload_session_status(session_id: str, request: Request) -> Dict[str, Any]:
    """Return preload progress and state for a session."""
    manager = _get_preload_manager()
    try:
        payload = manager.get_status(session_id)
        payload["playback_url"] = str(
            request.url_for(
                "player_preload_session_stream",
                session_id=session_id,
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


@router.get("/preload/session/{session_id}/stream", name="player_preload_session_stream")
async def preload_session_stream(session_id: str, request: Request) -> StreamingResponse:
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
        await upstream.release()
        await client.close()
        raise HTTPException(status_code=upstream.status, detail="Upstream preload stream unavailable")

    content_length = upstream.headers.get("Content-Length")
    content_range = upstream.headers.get("Content-Range")
    content_type = upstream.headers.get("Content-Type", "application/octet-stream")

    # Forward the original filename as a Content-Disposition hint so that mpv
    # (and other players) can use the file extension for demuxer selection even
    # when the endpoint URL has no extension.
    filename = getattr(session.proxy, "_filename", None) or "stream"
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

    async def chunk_iterator() -> AsyncGenerator[bytes, None]:
        try:
            async for chunk in upstream.content.iter_chunked(1024 * 1024):
                yield chunk
        finally:
            # Each cleanup step is wrapped independently: if one raises (e.g.
            # the response was already released because the client disconnected
            # mid-stream), the others still execute and no session is leaked.
            try:
                await upstream.release()
            except Exception:
                pass
            try:
                await client.close()
            except Exception:
                pass
            manager.release_stream(session_id)

    return StreamingResponse(
        chunk_iterator(),
        status_code=upstream.status,
        headers=response_headers,
    )


@router.post("/scrobble/start")
async def scrobble_start(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Send Trakt scrobble start for a playback session."""
    return _run_scrobble("start", payload)


@router.post("/scrobble/stop")
async def scrobble_stop(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Send Trakt scrobble stop for a playback session."""
    return _run_scrobble("stop", payload)


@router.post("/preload")
async def preload_stream(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Compatibility preload endpoint for legacy clients.

    NOTE:
    - This endpoint is preserved for backwards compatibility during the
      Phase 0-4 transition.
    - New thin-client/Tauri flow should migrate to
      ``POST /api/v1/player/preload/session`` once introduced.

    Begin downloading a remote stream URL into the local proxy buffer.

    The frontend calls this immediately after obtaining the CDN URL and then
    polls ``GET /preload/status`` until enough has buffered, at which point it
    calls ``POST /play``.  ``POST /play`` detects the running preload and
    reuses it so VLC opens with a large lead already built.
    """
    player = _get_player()
    url = payload.get("url", "").strip()
    if not url:
        raise HTTPException(status_code=400, detail="url required")
    player.preload_stream(url)
    return {"status": "preloading", "url": url}


@router.get("/preload/status")
async def preload_status() -> Dict[str, Any]:
    """Compatibility preload status endpoint for legacy clients.

    NOTE:
    - This endpoint is preserved for backwards compatibility during the
      Phase 0-4 transition.
    - New thin-client/Tauri flow should migrate to
      ``GET /api/v1/player/preload/session/{session_id}/status`` once introduced.
    """
    player = _get_player()
    return player.preload_status()


@router.post("/play")
async def play_media(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Start playback of a media source."""
    player = _get_player()

    request = PlayRequest(
        source=payload["source"],
        title=payload.get("title", "Unknown"),
        media_kind=payload.get("media_kind", "movie"),
        season=payload.get("season"),
        episode=payload.get("episode"),
        year=payload.get("year"),
        language=payload.get("language", "eng"),
        start_paused=payload.get("start_paused", False),
        is_stream=payload.get("is_stream", False),
        auto_subtitles=payload.get("auto_subtitles", True),
        resume_from_last_position=payload.get("resume_from_last_position", True),
        tmdb_id=payload.get("tmdb_id"),
        media_payload=payload.get("media_payload"),
        show_payload=payload.get("show_payload"),
        source_type=payload.get("source_type", "local"),
    )

    try:
        player.play(request)
        return {
            "status": "playing",
            "title": request.title,
            "player_mode": player.player_mode,
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Playback failed: {exc}")


@router.post("/pause")
async def pause_media() -> Dict[str, Any]:
    """Pause playback."""
    player = _get_player()
    player.pause()
    return {"status": "paused"}


@router.post("/resume")
async def resume_media() -> Dict[str, Any]:
    """Resume playback."""
    player = _get_player()
    player.resume()
    return {"status": "playing"}


@router.post("/stop")
async def stop_media() -> Dict[str, Any]:
    """Stop playback."""
    player = _get_player()
    player.stop()
    return {"status": "stopped"}


@router.post("/seek")
async def seek_media(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Seek to position in milliseconds."""
    player = _get_player()
    position = payload.get("position")
    if position is None:
        raise HTTPException(status_code=400, detail="position (ms) required")
    player.seek_ms(int(position))
    return {"status": "seeked", "position_ms": position}


@router.post("/volume")
async def set_volume(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Set volume (0-100)."""
    player = _get_player()
    volume = payload.get("volume")
    if volume is None:
        raise HTTPException(status_code=400, detail="volume (0-100) required")
    player.set_volume(int(volume))
    return {"status": "volume_set", "volume": volume}


@router.post("/mute")
async def toggle_mute() -> Dict[str, Any]:
    """Toggle mute."""
    player = _get_player()
    player.toggle_mute()
    return {"status": "mute_toggled"}


@router.post("/rate")
async def set_rate(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Set playback rate (0.25-4.0)."""
    player = _get_player()
    rate = payload.get("rate")
    if rate is None:
        raise HTTPException(status_code=400, detail="rate (0.25-4.0) required")
    player.set_rate(float(rate))
    return {"status": "rate_set", "rate": rate}


@router.get("/status")
async def player_status() -> Dict[str, Any]:
    """Get current player status."""
    player = _get_player()
    state = player.now_playing()
    return _state_to_dict(state)


@router.get("/status/events")
async def player_status_events() -> StreamingResponse:
    """Server-Sent Events endpoint for real-time player status."""
    player = _get_player()

    async def event_generator() -> AsyncGenerator[str, None]:
        last_state = None
        while True:
            state = player.now_playing()
            state_dict = _state_to_dict(state)

            if state_dict != last_state:
                event_data = json.dumps(state_dict)
                yield f"data: {event_data}\n\n"
                last_state = state_dict

            if state is None:
                yield f"data: {json.dumps({'status': 'idle'})}\n\n"
                break

            await asyncio.sleep(1)

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@router.get("/playlist")
async def get_playlist() -> Dict[str, Any]:
    """Get current playlist."""
    player = _get_player()
    playlist = player.playlist
    items = []
    for item in playlist.items:
        items.append({
            "source": item.source,
            "title": item.title,
            "media_kind": item.media_kind,
        })

    return {
        "items": items,
        "current_index": playlist.current_index,
        "count": len(items),
    }


@router.post("/next")
async def play_next() -> Dict[str, Any]:
    """Play next item in playlist."""
    player = _get_player()
    success = player.play_next()
    return {"status": "next" if success else "end_of_playlist"}


@router.post("/previous")
async def play_previous() -> Dict[str, Any]:
    """Play previous item in playlist."""
    player = _get_player()
    success = player.play_previous()
    return {"status": "previous" if success else "start_of_playlist"}
