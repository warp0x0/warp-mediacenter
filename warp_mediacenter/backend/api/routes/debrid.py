"""RealDebrid OAuth, account, and torrent management routes."""

from __future__ import annotations

import time
from typing import Any, Dict, List, Optional

import requests as _requests
from fastapi import APIRouter, HTTPException, Query

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.api.middleware import get_container
from warp_mediacenter.backend.player.debrid.client import RealDebridClient, RealDebridAPIError
from warp_mediacenter.backend.player.debrid.oauth import RealDebridOAuthError

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


@router.post("/auth/refresh")
async def debrid_auth_refresh() -> Dict[str, Any]:
    """Try to silently refresh an expired RealDebrid token.

    Does NOT start the device flow. Returns refreshed/failed/should-reauth.
    Respects the same in-process backoff used by ensure_valid_token() so that
    repeated frontend calls (AppShell startup, Settings panel) cannot hammer the
    RealDebrid token endpoint.
    """
    client = _get_debrid()
    try:
        client._reload_settings()
        # Use the same buffer-aware check as ensure_valid_token() / refresh_token()
        # so all three paths agree on when a refresh is actually warranted.
        if not client._oauth._token_needs_refresh():
            remaining = int(client._oauth._settings.token_expires_at - time.time())
            return {
                "refreshed": False,
                "authenticated": True,
                "message": f"Token is still valid ({remaining}s remaining). No refresh needed.",
            }
    except Exception:
        pass

    if not client._oauth._settings.refresh_token:
        return {
            "refreshed": False,
            "authenticated": False,
            "reason": "no_refresh_token",
            "message": "No refresh token available. Full device auth required.",
        }

    # Honour the same backoff that ensure_valid_token() uses so we never
    # hammer RD after a recent failure regardless of how often the frontend
    # calls this endpoint.
    now = time.time()  # must match the time.time() used inside ensure_valid_token()
    failed_at = client._oauth._refresh_failed_at
    if failed_at is not None:
        elapsed = now - failed_at
        if elapsed < client._oauth._REFRESH_BACKOFF_S:
            remaining = int(client._oauth._REFRESH_BACKOFF_S - elapsed)
            log.info("rd_refresh_endpoint_backoff", retry_in_s=remaining)
            return {
                "refreshed": False,
                "authenticated": False,
                "reason": "refresh_backoff",
                "message": (
                    f"Recent token refresh failed — retrying in ~{remaining}s. "
                    "If this persists, re-authenticate in Settings → Authentication."
                ),
            }

    try:
        token = client._oauth.refresh_token()
        client._oauth._refresh_failed_at = None  # clear backoff on success
        client._reload_settings()
        return {
            "refreshed": True,
            "authenticated": True,
            "message": "Token refreshed successfully.",
            "expires_in": token.expires_in,
        }
    except _requests.HTTPError as exc:
        # refresh_token() calls resp.raise_for_status() — we get HTTPError for
        # 400 wrong_parameter, 401, etc.  Mirror what ensure_valid_token() does:
        # arm the backoff and clear the dead access token from disk.
        client._oauth._refresh_failed_at = time.time()
        client._oauth._clear_dead_tokens(exc)
        reason = "refresh_failed"
        detail: Optional[str] = None
        if exc.response is not None:
            try:
                body = exc.response.json()
                if body.get("error") == "wrong_parameter" or body.get("error_code") == 2:
                    reason = "token_revoked"
                    detail = (
                        "The stored refresh token is no longer valid (RealDebrid returned "
                        "'wrong_parameter'). This usually means the token was revoked or "
                        "has expired. Please re-authenticate."
                    )
            except Exception:
                pass
        log.warning("rd_refresh_endpoint_http_error", status=exc.response.status_code if exc.response is not None else None, reason=reason)
        return {
            "refreshed": False,
            "authenticated": False,
            "reason": reason,
            "error": str(exc),
            "message": detail or "Token refresh failed. Full device auth required.",
        }
    except RealDebridOAuthError as exc:
        client._oauth._refresh_failed_at = time.time()
        return {
            "refreshed": False,
            "authenticated": False,
            "reason": "refresh_failed",
            "error": str(exc),
            "message": "Token refresh failed. Full device auth required.",
        }
    except Exception as exc:
        client._oauth._refresh_failed_at = time.time()
        return {
            "refreshed": False,
            "authenticated": False,
            "reason": "refresh_error",
            "error": str(exc),
            "message": f"Unexpected error during refresh: {exc}",
        }


@router.post("/auth/clear")
async def debrid_auth_clear() -> Dict[str, Any]:
    """Clear Real Debrid authentication tokens (Disconnect button).

    Deletes ``var/tokens/realdebrid_tokens.json`` and strips any residual token
    fields from ``user_settings.json``.  This mirrors what Trakt's ``/auth/clear``
    does for Trakt tokens.

    NOTE: this endpoint is only for the UI Disconnect button.  Silent token
    refresh, backoff, and the access_token-only cleanup on a bad refresh are
    unaffected.
    """
    from warp_mediacenter.config.settings.torrent import clear_realdebrid_tokens
    try:
        clear_realdebrid_tokens()
        # Reload the singleton so the live client reflects the cleared state
        client = _get_debrid()
        client._reload_settings()
        log.info("rd_auth_cleared")
    except Exception as exc:
        log.warning("rd_auth_clear_error", error=str(exc))
    return {"authenticated": False}


@router.get("/auth/status")
async def debrid_auth_status() -> Dict[str, Any]:
    """Get RealDebrid authentication status.

    Response fields:
      authenticated — access token is present and not expired
      can_refresh   — a refresh_token exists (silent refresh is possible)
      pending       — device auth flow is in progress
      expired       — token existed but has expired (refresh may save it)
      denied        — user denied the device auth request
    """
    client = _get_debrid()

    # Always reload from disk so we reflect the latest persisted state,
    # including tokens written by other requests (e.g. a just-completed refresh).
    try:
        client._reload_settings()
    except Exception:
        pass

    # If a device auth flow is actively running, surface that state first.
    state = client.poll_device_auth_status()
    flow_status = state.get("status", "none")
    log.debug(
        "rd_auth_status_check",
        flow=flow_status,
        has_access=bool(client._settings.access_token),
        has_refresh=bool(client._settings.refresh_token),
    )

    if flow_status == "authorized":
        return {
            "authenticated": True,
            "can_refresh": True,
            "pending": False,
            "expired": False,
            "denied": False,
        }
    if flow_status == "expired":
        return {
            "authenticated": False,
            "can_refresh": bool(client._settings.refresh_token),
            "pending": False,
            "expired": True,
            "denied": False,
            "error": state.get("error"),
        }
    if flow_status == "denied":
        return {
            "authenticated": False,
            "can_refresh": bool(client._settings.refresh_token),
            "pending": False,
            "expired": False,
            "denied": True,
            "error": state.get("error"),
        }
    if flow_status == "pending":
        return {
            "authenticated": False,
            "can_refresh": bool(client._settings.refresh_token),
            "pending": True,
            "expired": False,
            "denied": False,
        }

    # No active device flow — report current token state from settings.
    has_valid = client._settings.has_valid_token
    can_refresh = bool(client._settings.refresh_token)
    token_expired = bool(client._settings.access_token) and not has_valid

    return {
        "authenticated": has_valid,
        "can_refresh": can_refresh,
        "pending": False,
        "expired": token_expired,
        "denied": False,
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
    except RealDebridOAuthError as exc:
        raise HTTPException(status_code=401, detail=f"RealDebrid not authenticated: {exc}")
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
    except RealDebridOAuthError as exc:
        raise HTTPException(status_code=401, detail=f"RealDebrid not authenticated: {exc}")
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
    except RealDebridOAuthError as exc:
        raise HTTPException(status_code=401, detail=f"RealDebrid not authenticated: {exc}")
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
    except RealDebridOAuthError as exc:
        raise HTTPException(status_code=401, detail=f"RealDebrid not authenticated: {exc}")
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
    except RealDebridOAuthError as exc:
        raise HTTPException(status_code=401, detail=f"RealDebrid not authenticated: {exc}")
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
    except RealDebridOAuthError as exc:
        raise HTTPException(status_code=401, detail=f"RealDebrid not authenticated: {exc}")
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
    except RealDebridOAuthError as exc:
        raise HTTPException(status_code=401, detail=f"RealDebrid not authenticated: {exc}")
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
        target_idx = -1
        for idx, f in enumerate(info.files):
            if f.id == file_id:
                target_file = f
                target_idx = idx
                break

        if target_file is None:
            raise HTTPException(status_code=404, detail=f"File {file_id} not found")

        if info.links and target_idx < len(info.links):
            raw_link = info.links[target_idx]
        elif info.links:
            raw_link = info.links[0]
        else:
            raise HTTPException(status_code=400, detail="No download links available yet")

        # info.links contains pre-unrestricted RD torrent links (https://real-debrid.com/d/HASH).
        # These cannot be streamed directly — VLC cannot authenticate to them.
        # We must call unrestrict_link() to get the actual CDN download URL.
        unrestricted = client.unrestrict_link(raw_link)
        stream_url = unrestricted.download
        if not stream_url:
            raise HTTPException(status_code=502, detail="RealDebrid did not return a download URL")

        log.info(
            "debrid_stream_url_resolved",
            torrent_id=torrent_id,
            file_id=file_id,
            host=unrestricted.host,
            streamable=unrestricted.streamable,
        )

        return {
            "torrent_id": torrent_id,
            "file_id": file_id,
            "file_name": target_file.path,
            "stream_url": stream_url,
            "mime_type": unrestricted.mimeType,
            "filesize": unrestricted.filesize,
        }
    except RealDebridOAuthError as exc:
        raise HTTPException(status_code=401, detail=f"RealDebrid not authenticated: {exc}")
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
    except RealDebridOAuthError as exc:
        raise HTTPException(status_code=401, detail=f"RealDebrid not authenticated: {exc}")
    except RealDebridAPIError as exc:
        raise HTTPException(status_code=500, detail=f"Cache check failed: {exc}")
