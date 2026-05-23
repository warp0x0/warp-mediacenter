"""Subtitle search, download, and management routes for Warp MediaCenter API."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException, Query

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.api.middleware import get_container
from warp_mediacenter.backend.player.controller import PlayerController
from warp_mediacenter.backend.player.subtitles.models import SubtitleQuery, SubtitleResult
from warp_mediacenter.backend.player.subtitles.service import SubtitleService

log = get_logger(__name__)

router = APIRouter()

_player_controller: Optional[PlayerController] = None
_subtitle_service: Optional[SubtitleService] = None
_temp_subtitles: Dict[str, Path] = {}


def set_player_controller(controller: PlayerController) -> None:
    """Set the global player controller instance for route handlers."""
    global _player_controller
    _player_controller = controller


def set_subtitle_service(service: SubtitleService) -> None:
    """Set the global subtitle service instance for route handlers."""
    global _subtitle_service
    _subtitle_service = service


def _get_player() -> PlayerController:
    """Get player controller from container or module-level global."""
    container = get_container()
    if container.player_controller is not None:
        return container.player_controller
    if _player_controller is not None:
        return _player_controller
    raise HTTPException(status_code=503, detail="Player controller not initialized")


def _get_subtitle_service() -> SubtitleService:
    """Get subtitle service from player controller or module-level global."""
    container = get_container()
    if container.player_controller is not None:
        return container.player_controller._service._subtitle_service
    if _subtitle_service is not None:
        return _subtitle_service
    raise HTTPException(status_code=503, detail="Subtitle service not initialized")


def _result_to_dict(result: SubtitleResult) -> Dict[str, Any]:
    """Convert SubtitleResult to a dict."""
    return result.as_dict()


@router.get("/search")
async def search_subtitles(
    query: str = Query(min_length=1),
    media_kind: str = Query(default="movie", regex="^(movie|show)$"),
    language: str = Query(default="eng"),
    season: Optional[int] = Query(default=None, ge=1),
    episode: Optional[int] = Query(default=None, ge=1),
    year: Optional[int] = Query(default=None),
) -> Dict[str, Any]:
    """Search for subtitles across providers (OpenSubtitles, Podnapisi, etc.)."""
    service = _get_subtitle_service()

    q = SubtitleQuery(
        title=query,
        media_kind=media_kind,
        language=language,
        season=season,
        episode=episode,
        year=year,
    )

    try:
        results = service.search_subtitles(q)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Subtitle search failed: {exc}")

    return {
        "query": query,
        "media_kind": media_kind,
        "language": language,
        "results": [_result_to_dict(r) for r in results],
        "count": len(results),
    }


@router.post("/download")
async def download_subtitle(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Download a subtitle file by result data.

    Returns the local file path where the subtitle was saved.
    """
    service = _get_subtitle_service()

    result = SubtitleResult(
        provider=payload["provider"],
        language=payload["language"],
        score=payload.get("score", 0.0),
        release=payload.get("release", ""),
        download_link=payload["download_link"],
        file_name=payload["file_name"],
        hearing_impaired=payload.get("hearing_impaired", False),
        rating=payload.get("rating"),
        metadata=payload.get("metadata", {}),
    )

    try:
        subtitle_path = service.download_subtitle(result)
        sub_id = f"sub_{len(_temp_subtitles)}"
        _temp_subtitles[sub_id] = subtitle_path
        return {
            "id": sub_id,
            "file_name": result.file_name,
            "path": str(subtitle_path),
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Subtitle download failed: {exc}")


@router.post("/load")
async def load_subtitle(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Load a subtitle file into active playback.

    Accepts either a subtitle ID (from download) or a direct file path.
    """
    player = _get_player()

    sub_id = payload.get("id")
    file_path = payload.get("path")

    if sub_id and sub_id in _temp_subtitles:
        file_path = str(_temp_subtitles[sub_id])
    elif not file_path:
        raise HTTPException(status_code=400, detail="id or path required")

    try:
        player._service.load_subtitle_file(file_path)
        return {"status": "loaded", "path": file_path}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Subtitle load failed: {exc}")


@router.get("/active")
async def list_active_subtitles() -> Dict[str, Any]:
    """List currently loaded/temp subtitle files."""
    items = []
    for sub_id, path in _temp_subtitles.items():
        items.append({
            "id": sub_id,
            "file_name": path.name,
            "path": str(path),
        })

    player = _get_player()
    state = player.now_playing()
    current_subtitle = state.subtitle_path if state else None

    return {
        "temp_subtitles": items,
        "current_subtitle": current_subtitle,
        "count": len(items),
    }


@router.delete("/{subtitle_id}")
async def delete_subtitle(subtitle_id: str) -> Dict[str, Any]:
    """Delete a downloaded subtitle file."""
    if subtitle_id not in _temp_subtitles:
        raise HTTPException(status_code=404, detail="Subtitle not found")

    path = _temp_subtitles.pop(subtitle_id)
    try:
        if path.exists():
            path.unlink()
        return {"status": "deleted", "id": subtitle_id}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Delete failed: {exc}")


@router.post("/cleanup")
async def cleanup_subtitles() -> Dict[str, Any]:
    """Clean up all temporary subtitle files."""
    deleted = 0
    for sub_id, path in list(_temp_subtitles.items()):
        try:
            if path.exists():
                path.unlink()
                deleted += 1
        except Exception:
            pass
        del _temp_subtitles[sub_id]

    return {"status": "cleaned", "deleted": deleted}
