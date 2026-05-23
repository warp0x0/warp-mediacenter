"""Player control routes for Warp MediaCenter API."""

from __future__ import annotations

import asyncio
import json
from typing import Any, AsyncGenerator, Dict, Optional

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.api.middleware import get_container
from warp_mediacenter.backend.player.controller import PlayerController, PlayRequest
from warp_mediacenter.backend.player.adapter import PlaybackState

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
        return {"status": "playing", "title": request.title}
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
