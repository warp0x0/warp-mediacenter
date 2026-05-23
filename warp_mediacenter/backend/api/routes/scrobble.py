"""Trakt scrobble status and control routes."""

from __future__ import annotations

from typing import Any, Dict, Optional

from fastapi import APIRouter, HTTPException

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.api.middleware import get_container
from warp_mediacenter.backend.information_handlers.trakt_manager import TraktManager

log = get_logger(__name__)

router = APIRouter()

_trakt_manager: Optional[TraktManager] = None


def set_trakt_manager(manager: TraktManager) -> None:
    """Set the global Trakt manager instance for route handlers."""
    global _trakt_manager
    _trakt_manager = manager


def _get_trakt() -> TraktManager:
    """Get Trakt manager from container or module-level global."""
    container = get_container()
    if container.trakt_manager is not None:
        return container.trakt_manager
    if _trakt_manager is not None:
        return _trakt_manager
    raise HTTPException(status_code=503, detail="Trakt manager not initialized")


@router.get("/status")
async def scrobble_status() -> Dict[str, Any]:
    """Get Trakt scrobble authentication status."""
    manager = _get_trakt()
    status = manager.facade_status()
    return {
        "authenticated": not status.get("reauth_required", True),
        "reason": status.get("reason"),
        "expires_at": status.get("expires_at"),
        "last_refresh_ymd": status.get("last_refresh_ymd"),
    }


@router.get("/user")
async def scrobble_user() -> Dict[str, Any]:
    """Get authenticated Trakt user profile."""
    manager = _get_trakt()
    try:
        profile = manager.get_profile()
        return {
            "username": profile.username,
            "name": profile.name,
            "vip": profile.vip,
            "joined_at": profile.joined_at.isoformat() if profile.joined_at else None,
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))


@router.get("/resume")
async def get_resume_entries(
    media_type: str = "movie",
    limit: int = 25,
) -> Dict[str, Any]:
    """Get playback resume entries from Trakt."""
    from warp_mediacenter.backend.information_handlers.models import MediaType

    manager = _get_trakt()
    try:
        mt = MediaType(media_type)
        entries = manager.get_playback_resume(mt)
        return {
            "media_type": media_type,
            "count": len(entries),
            "entries": [
                {
                    "id": e.id,
                    "progress": e.progress,
                    "paused_at": e.paused_at.isoformat() if e.paused_at else None,
                    "media": e.media.model_dump() if hasattr(e.media, "model_dump") else {},
                }
                for e in entries[:limit]
            ],
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))
