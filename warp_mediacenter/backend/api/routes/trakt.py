"""Trakt OAuth, data, and account routes for Warp MediaCenter API."""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException, Query

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.api.middleware import get_container
from warp_mediacenter.backend.information_handlers.models import MediaType
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


def _catalog_item_to_dict(item) -> Dict[str, Any]:
    """Convert a CatalogItem to a dict."""
    if hasattr(item, "model_dump"):
        return item.model_dump(mode="json")
    return dict(item) if hasattr(item, "__iter__") else {}


# ------------------------------------------------------------------
# Auth endpoints
# ------------------------------------------------------------------

@router.post("/auth/start")
async def trakt_auth_start() -> Dict[str, Any]:
    """Start Trakt OAuth device flow.

    Returns user_code and verification_url for the user to authorize.
    """
    manager = _get_trakt()
    try:
        device = manager.start_device_auth()
        return {
            "device_code": device.device_code,
            "user_code": device.user_code,
            "verification_url": device.verification_url,
            "expires_in": device.expires_in,
            "interval": device.interval,
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Auth start failed: {exc}")


@router.post("/auth/complete")
async def trakt_auth_complete(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Complete Trakt OAuth device flow with device code."""
    manager = _get_trakt()
    device_code = payload.get("device_code")
    if not device_code:
        raise HTTPException(status_code=400, detail="device_code is required")

    try:
        token = manager.wait_for_device_token(
            manager.start_device_auth().__class__(
                device_code=device_code,
                user_code="",
                verification_url="",
                expires_in=600,
                interval=5,
            ),
            timeout=600,
        )
        return {
            "authenticated": True,
            "token_type": token.token_type,
            "access_token": token.access_token[:20] + "...",
            "expires_in": token.expires_in,
            "refresh_token": token.refresh_token[:20] + "...",
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Auth complete failed: {exc}")


@router.get("/auth/status")
async def trakt_auth_status() -> Dict[str, Any]:
    """Get Trakt authentication status."""
    manager = _get_trakt()
    status = manager.facade_status()
    return {
        "authenticated": not status.get("reauth_required", True),
        "reason": status.get("reason"),
        "expires_at": status.get("expires_at"),
        "last_refresh_ymd": status.get("last_refresh_ymd"),
    }


# ------------------------------------------------------------------
# Data endpoints
# ------------------------------------------------------------------

@router.get("/history")
async def trakt_history(
    media_type: str = Query(default="movie", regex="^(movie|episode)$"),
    limit: int = Query(default=100, ge=1, le=500),
) -> Dict[str, Any]:
    """Get watch history from Trakt."""
    manager = _get_trakt()
    mt = MediaType.MOVIE if media_type == "movie" else MediaType.EPISODE

    try:
        entries = manager.get_watched_history(mt, limit=limit)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"History fetch failed: {exc}")

    items = []
    for e in entries:
        d = {}
        if hasattr(e, "model_dump"):
            d = e.model_dump(mode="json")
        items.append(d)

    return {
        "media_type": media_type,
        "items": items,
        "count": len(items),
    }


@router.get("/lists")
async def trakt_lists(
    username: str = Query(default="me"),
) -> Dict[str, Any]:
    """Get user lists from Trakt."""
    manager = _get_trakt()

    try:
        lists = manager.get_user_lists(username)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Lists fetch failed: {exc}")

    items = []
    for lst in lists:
        d = {}
        if hasattr(lst, "model_dump"):
            d = lst.model_dump(mode="json")
        items.append(d)

    return {
        "username": username,
        "lists": items,
        "count": len(items),
    }


@router.get("/lists/{list_id}/items")
async def trakt_list_items(
    list_id: str,
    username: str = Query(default="me"),
    media_type: Optional[str] = Query(default=None, regex="^(movie|show)$"),
) -> Dict[str, Any]:
    """Get items from a Trakt list."""
    manager = _get_trakt()
    mt = None
    if media_type:
        mt = MediaType.MOVIE if media_type == "movie" else MediaType.SHOW

    try:
        items = manager.get_list_items(list_id, username=username, media_type=mt)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"List items fetch failed: {exc}")

    return {
        "list_id": list_id,
        "username": username,
        "items": [_catalog_item_to_dict(i) for i in items],
        "count": len(items),
    }


@router.get("/recommendations")
async def trakt_recommendations(
    media_type: str = Query(default="movie", regex="^(movie|show)$"),
    limit: int = Query(default=40, ge=1, le=100),
) -> Dict[str, Any]:
    """Get recommendations from Trakt."""
    manager = _get_trakt()
    mt = MediaType.MOVIE if media_type == "movie" else MediaType.SHOW

    try:
        items = manager.catalog_list(mt, "recommendations", limit=limit)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Recommendations fetch failed: {exc}")

    return {
        "media_type": media_type,
        "items": [_catalog_item_to_dict(i) for i in items],
        "count": len(items),
    }


@router.get("/collection")
async def trakt_collection(
    media_type: str = Query(default="movie", regex="^(movie|show)$"),
) -> Dict[str, Any]:
    """Get collection from Trakt."""
    manager = _get_trakt()
    mt = MediaType.MOVIE if media_type == "movie" else MediaType.SHOW

    try:
        items = manager.catalog_list(mt, "collection")
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Collection fetch failed: {exc}")

    return {
        "media_type": media_type,
        "items": [_catalog_item_to_dict(i) for i in items],
        "count": len(items),
    }


@router.get("/watchlist")
async def trakt_watchlist(
    media_type: str = Query(default="movie", regex="^(movie|show)$"),
    limit: int = Query(default=50, ge=1, le=200),
) -> Dict[str, Any]:
    """Get watchlist from Trakt."""
    manager = _get_trakt()
    mt = MediaType.MOVIE if media_type == "movie" else MediaType.SHOW

    try:
        items = manager.catalog_list(mt, "watchlist", limit=limit)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Watchlist fetch failed: {exc}")

    return {
        "media_type": media_type,
        "items": [_catalog_item_to_dict(i) for i in items],
        "count": len(items),
    }
