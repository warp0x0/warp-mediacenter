"""RealDebrid OAuth, account, and torrent management routes."""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException, Query

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.api.middleware import get_container
from warp_mediacenter.backend.player.debrid.client import RealDebridClient, RealDebridAPIError

log = get_logger(__name__)

router = APIRouter()

_debrid_client: Optional[RealDebridClient] = None


def set_debrid_client(client: RealDebridClient) -> None:
    """Set the global RealDebrid client instance for route handlers."""
    global _debrid_client
    _debrid_client = client


def _get_debrid() -> RealDebridClient:
    """Get RealDebrid client from container or module-level global."""
    container = get_container()
    if container.debrid_client is not None:
        return container.debrid_client
    if _debrid_client is not None:
        return _debrid_client
    raise HTTPException(status_code=503, detail="RealDebrid client not initialized")


# ------------------------------------------------------------------
# Auth endpoints
# ------------------------------------------------------------------

@router.post("/auth/start")
async def debrid_auth_start() -> Dict[str, Any]:
    """Start RealDebrid OAuth device flow.

    Returns user_code and verification_url for the user to authorize.
    """
    client = _get_debrid()
    try:
        info = client.start_device_auth()
        return {
            "user_code": info.get("user_code"),
            "verification_url": info.get("verification_url"),
            "device_code": info.get("device_code"),
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Auth start failed: {exc}")


@router.post("/auth/complete")
async def debrid_auth_complete(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Complete RealDebrid OAuth device flow with device code."""
    client = _get_debrid()
    device_code = payload.get("device_code")
    if not device_code:
        raise HTTPException(status_code=400, detail="device_code is required")

    try:
        token_info = client.complete_device_auth(device_code)
        return {
            "authenticated": True,
            "token_type": token_info.get("token_type"),
            "access_token": token_info.get("access_token", "")[:20] + "...",
            "expires_in": token_info.get("expires_in"),
            "refresh_token": token_info.get("refresh_token", "")[:20] + "...",
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Auth complete failed: {exc}")


@router.get("/auth/status")
async def debrid_auth_status() -> Dict[str, Any]:
    """Get RealDebrid authentication status."""
    client = _get_debrid()
    has_token = False
    try:
        has_token = client._oauth.has_token() if client._oauth else False
    except Exception:
        pass

    return {
        "authenticated": has_token,
    }


# ------------------------------------------------------------------
# Account endpoints
# ------------------------------------------------------------------

@router.get("/account")
async def debrid_account() -> Dict[str, Any]:
    """Get RealDebrid account info."""
    client = _get_debrid()
    try:
        user = client.get_user()
        return user
    except RealDebridAPIError as exc:
        raise HTTPException(status_code=500, detail=f"Account fetch failed: {exc}")


# ------------------------------------------------------------------
# Torrent management endpoints
# ------------------------------------------------------------------

@router.post("/magnet/add")
async def debrid_add_magnet(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Add a magnet link to RealDebrid.

    Request body:
    - magnet: Magnet URI
    - host: Optional host to use (default: automatic)
    """
    client = _get_debrid()
    magnet = payload.get("magnet")
    if not magnet:
        raise HTTPException(status_code=400, detail="magnet is required")

    try:
        torrent_id = client.add_magnet(magnet, host=payload.get("host"))
        return {
            "torrent_id": torrent_id,
            "status": "added",
        }
    except RealDebridAPIError as exc:
        raise HTTPException(status_code=500, detail=f"Magnet add failed: {exc}")


@router.get("/torrent/{torrent_id}")
async def debrid_torrent_info(torrent_id: str) -> Dict[str, Any]:
    """Get torrent info from RealDebrid."""
    client = _get_debrid()
    try:
        info = client.get_torrent_info(torrent_id)
        result = {}
        if hasattr(info, "model_dump"):
            result = info.model_dump(mode="json")
        return result
    except RealDebridAPIError as exc:
        raise HTTPException(status_code=404, detail=f"Torrent not found: {exc}")


@router.get("/torrent/{torrent_id}/files")
async def debrid_torrent_files(torrent_id: str) -> Dict[str, Any]:
    """Get file list for a torrent."""
    client = _get_debrid()
    try:
        info = client.get_torrent_info(torrent_id)
        files = []
        for f in info.files:
            fd = {}
            if hasattr(f, "model_dump"):
                fd = f.model_dump(mode="json")
            files.append(fd)

        return {
            "torrent_id": torrent_id,
            "status": info.status,
            "files": files,
            "count": len(files),
        }
    except RealDebridAPIError as exc:
        raise HTTPException(status_code=404, detail=f"Torrent not found: {exc}")


@router.post("/torrent/{torrent_id}/select")
async def debrid_select_files(torrent_id: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    """Select files for download from a torrent.

    Request body:
    - file_ids: List of file IDs or "all"
    """
    client = _get_debrid()
    file_ids = payload.get("file_ids", "all")

    try:
        if isinstance(file_ids, list):
            file_ids_str = ",".join(str(fid) for fid in file_ids)
        else:
            file_ids_str = str(file_ids)

        success = client.select_files(torrent_id, file_ids=file_ids_str)
        return {
            "torrent_id": torrent_id,
            "selected": success,
        }
    except RealDebridAPIError as exc:
        raise HTTPException(status_code=500, detail=f"File selection failed: {exc}")


@router.delete("/torrent/{torrent_id}")
async def debrid_delete_torrent(torrent_id: str) -> Dict[str, Any]:
    """Delete a torrent from RealDebrid."""
    client = _get_debrid()
    try:
        success = client.delete_torrent(torrent_id)
        return {
            "torrent_id": torrent_id,
            "deleted": success,
        }
    except RealDebridAPIError as exc:
        raise HTTPException(status_code=500, detail=f"Delete failed: {exc}")


@router.get("/torrents")
async def debrid_list_torrents(
    offset: int = Query(default=0, ge=0),
    limit: int = Query(default=100, ge=1, le=1000),
    filter_active: bool = Query(default=False),
) -> Dict[str, Any]:
    """List torrents from RealDebrid."""
    client = _get_debrid()
    try:
        torrents = client.list_torrents(
            offset=offset,
            limit=limit,
            filter_active=filter_active,
        )
        items = []
        for t in torrents:
            td = {}
            if hasattr(t, "model_dump"):
                td = t.model_dump(mode="json")
            items.append(td)

        return {
            "items": items,
            "count": len(items),
            "offset": offset,
            "limit": limit,
        }
    except RealDebridAPIError as exc:
        raise HTTPException(status_code=500, detail=f"List failed: {exc}")


# ------------------------------------------------------------------
# Stream and availability endpoints
# ------------------------------------------------------------------

@router.get("/stream/{torrent_id}/{file_id}")
async def debrid_stream_url(
    torrent_id: str,
    file_id: int,
) -> Dict[str, Any]:
    """Get a streamable URL for a specific file in a torrent."""
    client = _get_debrid()
    try:
        info = client.get_torrent_info(torrent_id)

        target_file = None
        for f in info.files:
            if f.id == file_id:
                target_file = f
                break

        if target_file is None:
            raise HTTPException(status_code=404, detail=f"File {file_id} not found")

        if not target_file.link:
            raise HTTPException(status_code=400, detail="File link not available yet")

        return {
            "torrent_id": torrent_id,
            "file_id": file_id,
            "file_name": target_file.path,
            "stream_url": target_file.link,
        }
    except RealDebridAPIError as exc:
        raise HTTPException(status_code=500, detail=f"Stream URL fetch failed: {exc}")


@router.get("/cache/check")
async def debrid_cache_check(
    hashes: str = Query(description="Comma-separated torrent info hashes"),
) -> Dict[str, Any]:
    """Check instant availability for torrent hashes."""
    client = _get_debrid()
    hash_list = [h.strip() for h in hashes.split(",") if h.strip()]

    if not hash_list:
        raise HTTPException(status_code=400, detail="hashes is required")

    try:
        availability = client.get_instant_availability(hash_list)
        cached = [h for h in hash_list if h in availability and availability[h].get("rd")]
        uncached = [h for h in hash_list if h not in availability or not availability[h].get("rd")]

        return {
            "cached": cached,
            "uncached": uncached,
            "cached_count": len(cached),
            "total": len(hash_list),
            "details": availability,
        }
    except RealDebridAPIError as exc:
        raise HTTPException(status_code=500, detail=f"Cache check failed: {exc}")
