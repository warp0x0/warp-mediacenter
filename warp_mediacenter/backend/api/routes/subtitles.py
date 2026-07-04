"""Subtitle search, download, and management routes for Warp MediaCenter API."""

from __future__ import annotations

import asyncio
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

from dotenv import set_key
from fastapi import APIRouter, HTTPException, Query, Request
from fastapi.responses import FileResponse

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
_ENV_PATH = Path(__file__).resolve().parents[3] / ".env"


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
    """Get the raw SubtitleService for direct search/download calls."""
    container = get_container()
    if container.player_controller is not None:
        return container.player_controller._service._subtitle_service
    if _subtitle_service is not None:
        return _subtitle_service
    raise HTTPException(status_code=503, detail="Subtitle service not initialized")


def _get_player_service():
    """Get the PlayerService wrapper (has search_subtitles, load helpers)."""
    container = get_container()
    if container.player_controller is not None:
        return container.player_controller._service
    raise HTTPException(status_code=503, detail="Player service not initialized")


def _result_to_dict(result: SubtitleResult) -> Dict[str, Any]:
    """Convert SubtitleResult to a dict."""
    return result.as_dict()


def _resolve_imdb_id(tmdb_id: str, media_kind: str) -> Optional[str]:
    """Look up IMDb ID from TMDb ID using the information providers."""
    try:
        from warp_mediacenter.backend.information_handlers.providers import InformationProviders
        container = get_container()
        providers = (container.information_providers if container.information_providers else InformationProviders())
        if media_kind == 'show':
            detail = providers.show_details(tmdb_id, include_credits=False)
        else:
            detail = providers.movie_details(tmdb_id, include_credits=False)
        return detail.external_ids.get('imdb_id') or None
    except Exception as exc:
        log.debug('imdb_id_lookup_failed', tmdb_id=tmdb_id, error=str(exc))
        return None


def _subtitle_file_url(request: Request, sub_id: str, path: Path) -> str:
    return str(request.url_for("get_subtitle_file", subtitle_id=sub_id, file_name=path.name))


def _persist_env_value(key: str, value: str) -> None:
    _ENV_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not _ENV_PATH.exists():
        _ENV_PATH.touch(mode=0o600)
    set_key(str(_ENV_PATH), key, value)
    os.environ[key] = value


@router.post("/opensubtitles/refresh-token")
async def refresh_opensubtitles_token() -> Dict[str, Any]:
    """Refresh OpenSubtitles JWT using backend-side credentials."""
    try:
        payload = _get_subtitle_service().refresh_opensubtitles_token()
        token = str(payload.get("token") or "")
        expires_at = str(payload.get("expires_at") or "")
        if token:
            _persist_env_value("OPENSUBTITLES_JWT_TOKEN", token)
        if expires_at:
            _persist_env_value("OPENSUBTITLES_JWT_EXPIRES_AT", expires_at)
        return {"status": "ok", "expires_at": expires_at}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"OpenSubtitles token refresh failed: {exc}")


@router.get("/search")
async def search_subtitles(
    query: str = Query(min_length=1),
    media_kind: str = Query(default="movie", regex="^(movie|show)$"),
    language: str = Query(default="eng"),
    season: Optional[int] = Query(default=None, ge=1),
    episode: Optional[int] = Query(default=None, ge=1),
    year: Optional[int] = Query(default=None),
    imdb_id: Optional[str] = Query(default=None),
    tmdb_id: Optional[str] = Query(default=None),
    media_src: Optional[str] = Query(default=None),
) -> Dict[str, Any]:
    """Search for subtitles across providers."""
    service = _get_subtitle_service()

    # Resolve IMDb ID: use provided value, or look up from TMDb ID
    resolved_imdb_id = imdb_id or None
    if not resolved_imdb_id and tmdb_id:
        resolved_imdb_id = await asyncio.to_thread(_resolve_imdb_id, tmdb_id, media_kind)

    q = SubtitleQuery(
        title=query,
        media_kind=media_kind,
        language=language,
        season=season,
        episode=episode,
        year=year,
        imdb_id=resolved_imdb_id,
        tmdb_id=tmdb_id,
        media_path=media_src or None,
    )

    try:
        results = await asyncio.to_thread(service.search, q)
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
async def download_subtitle(payload: Dict[str, Any], request: Request) -> Dict[str, Any]:
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
        download = await asyncio.to_thread(service.download, result)
        sub_id = f"sub_{len(_temp_subtitles)}"
        _temp_subtitles[sub_id] = download.path
        return {
            "id": sub_id,
            "file_name": result.file_name,
            "path": str(download.path),
            "url": _subtitle_file_url(request, sub_id, download.path),
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
    file_path = payload.get("path") or payload.get("url")

    if sub_id and sub_id in _temp_subtitles:
        file_path = str(_temp_subtitles[sub_id])
    elif not file_path:
        raise HTTPException(status_code=400, detail="id or path required")

    try:
        svc = _get_player_service()
        svc._player.load_external_subtitle(file_path)
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


@router.get("/{subtitle_id}/file/{file_name}", name="get_subtitle_file")
async def get_subtitle_file(subtitle_id: str, file_name: str) -> FileResponse:
    """Serve a downloaded temporary subtitle file to remote players."""
    path = _temp_subtitles.get(subtitle_id)
    if not path or not path.exists() or not path.is_file():
        raise HTTPException(status_code=404, detail="Subtitle file not found")
    return FileResponse(path, media_type="text/plain; charset=utf-8", filename=path.name)


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

    try:
        _get_subtitle_service().cleanup_temp()
    except Exception as exc:
        log.debug("subtitle_temp_cleanup_failed", error=str(exc))

    return {"status": "cleaned", "deleted": deleted}
