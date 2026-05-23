"""Settings, management, and trailer routes for Warp MediaCenter API."""

from __future__ import annotations

import threading
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException, Query

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.api.middleware import get_container
from warp_mediacenter.backend.information_handlers.providers import InformationProviders
from warp_mediacenter.backend.persistence import (
    connection as db_connection,
    get_setting,
    set_setting,
)

log = get_logger(__name__)

router = APIRouter()

_scan_status: Dict[str, Any] = {"running": False, "progress": 0, "message": "idle"}
_scan_lock = threading.Lock()


def _get_providers() -> InformationProviders:
    """Get InformationProviders from container or create default."""
    container = get_container()
    if container.information_providers is not None:
        return container.information_providers
    return InformationProviders()


# ------------------------------------------------------------------
# Settings endpoints
# ------------------------------------------------------------------

@router.get("")
async def get_all_settings() -> Dict[str, Any]:
    """Get all stored settings."""
    keys = [
        "tmdb_api_key",
        "trakt_client_id",
        "trakt_client_secret",
        "realdebrid_client_id",
        "realdebrid_client_secret",
        "torrent_api_url",
        "torrent_api_key",
        "library_scan_paths",
    ]

    settings = {}
    with db_connection() as conn:
        for key in keys:
            value = get_setting(conn, key)
            settings[key] = value

    return {"settings": settings}


@router.put("/{key}")
async def update_setting(key: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    """Update a setting by key.

    Request body:
    - value: The new setting value
    """
    value = payload.get("value")
    if value is None:
        raise HTTPException(status_code=400, detail="value is required")

    with db_connection() as conn:
        set_setting(conn, key, str(value))

    return {"key": key, "value": str(value)}


@router.get("/providers")
async def provider_status() -> Dict[str, Any]:
    """Get status of all information providers."""
    providers = _get_providers()

    # TMDb status
    tmdb_status = {"status": "ok"}
    try:
        config = providers.tmdb_configuration()
        tmdb_status["api_key_configured"] = True
    except Exception as exc:
        tmdb_status["status"] = "error"
        tmdb_status["error"] = str(exc)
        tmdb_status["api_key_configured"] = False

    # Trakt status
    trakt_status = {"status": "ok"}
    try:
        trakt_status["authenticated"] = providers.trakt_has_valid_token()
        trakt_status["api_key_configured"] = True
    except Exception:
        trakt_status["status"] = "error"
        trakt_status["authenticated"] = False
        trakt_status["api_key_configured"] = False

    # RealDebrid status
    debrid_status = {"status": "ok"}
    try:
        container = get_container()
        if container.debrid_client:
            debrid_status["authenticated"] = container.debrid_client._oauth.has_token() if container.debrid_client._oauth else False
        else:
            debrid_status["authenticated"] = False
        debrid_status["api_key_configured"] = True
    except Exception:
        debrid_status["status"] = "error"
        debrid_status["authenticated"] = False
        debrid_status["api_key_configured"] = False

    # Torrent API status
    torrent_status = {"status": "ok"}
    try:
        from warp_mediacenter.config.settings.torrent import get_torrent_debrid_settings
        settings = get_torrent_debrid_settings()
        torrent_status["url"] = settings.torrent.api_base_url
        torrent_status["api_key_configured"] = bool(settings.torrent.api_key)
    except Exception:
        torrent_status["status"] = "error"
        torrent_status["api_key_configured"] = False

    return {
        "tmdb": tmdb_status,
        "trakt": trakt_status,
        "realdebrid": debrid_status,
        "torrent_api": torrent_status,
    }


# ------------------------------------------------------------------
# Library scan endpoints
# ------------------------------------------------------------------

@router.post("/library/scan")
async def trigger_library_scan(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Trigger a library scan.

    Request body:
    - paths: List of paths to scan
    - section_id: Optional library section ID to use paths from
    - incremental: Whether to skip unchanged files (default: true)
    """
    from warp_mediacenter.backend.library.scanner import scan_once
    from pathlib import Path

    paths = payload.get("paths", [])
    section_id = payload.get("section_id")
    incremental = payload.get("incremental", True)

    if section_id:
        with db_connection() as conn:
            from warp_mediacenter.backend.persistence import get_section_paths
            paths = get_section_paths(conn, int(section_id))

    if not paths:
        raise HTTPException(status_code=400, detail="paths or section_id is required")

    with _scan_lock:
        if _scan_status["running"]:
            raise HTTPException(status_code=409, detail="Scan already in progress")

        _scan_status["running"] = True
        _scan_status["progress"] = 0
        _scan_status["message"] = "starting"

    def _run_scan():
        try:
            path_objs = [Path(p) for p in paths]
            result = scan_once(path_objs, incremental=incremental)

            with _scan_lock:
                _scan_status["running"] = False
                _scan_status["progress"] = 100
                _scan_status["message"] = "complete"
                _scan_status["result"] = {
                    "total_files": result.total_files,
                    "new_titles": result.new_titles,
                    "updated_titles": result.updated_titles,
                    "new_episodes": result.new_episodes,
                    "duration_sec": round(result.duration_sec, 2),
                }
        except Exception as exc:
            with _scan_lock:
                _scan_status["running"] = False
                _scan_status["message"] = f"error: {exc}"

    thread = threading.Thread(target=_run_scan, daemon=True)
    thread.start()

    return {
        "status": "started",
        "paths": paths,
        "incremental": incremental,
    }


@router.get("/library/scan/status")
async def library_scan_status() -> Dict[str, Any]:
    """Get current library scan status."""
    with _scan_lock:
        return dict(_scan_status)


# ------------------------------------------------------------------
# Trailer endpoints
# ------------------------------------------------------------------

@router.get("/trailers/movie/{movie_id}")
async def movie_trailers(
    movie_id: str,
    language: Optional[str] = Query(default=None),
) -> Dict[str, Any]:
    """Get trailers for a movie."""
    providers = _get_providers()

    try:
        trailers = providers.movie_trailers(movie_id, language=language)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Trailer fetch failed: {exc}")

    items = []
    for t in trailers:
        d = {}
        if hasattr(t, "model_dump"):
            d = t.model_dump(mode="json")
        items.append(d)

    return {
        "movie_id": movie_id,
        "trailers": items,
        "count": len(items),
    }


@router.get("/trailers/show/{show_id}")
async def show_trailers(
    show_id: str,
    language: Optional[str] = Query(default=None),
) -> Dict[str, Any]:
    """Get trailers for a show."""
    providers = _get_providers()

    try:
        trailers = providers.show_trailers(show_id, language=language)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Trailer fetch failed: {exc}")

    items = []
    for t in trailers:
        d = {}
        if hasattr(t, "model_dump"):
            d = t.model_dump(mode="json")
        items.append(d)

    return {
        "show_id": show_id,
        "trailers": items,
        "count": len(items),
    }
