"""Settings, management, and trailer routes for Warp MediaCenter API."""

from __future__ import annotations

import json
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

_scan_status: Dict[str, Any] = {
    "running": False, "progress": 0, "message": "idle", "logs": [],
    "files_done": 0, "files_total": 0,
}
_scan_lock = threading.Lock()
_cancel_event = threading.Event()

# ---------------------------------------------------------------------------
# Default widget configurations (6 slots each)
# ---------------------------------------------------------------------------

_DEFAULT_MOVIE_WIDGETS: List[Dict[str, Any]] = [
    {"provider": "tmdb", "category": "trending_day",  "title": "Trending Today"},
    {"provider": "tmdb", "category": "popular",       "title": "Popular"},
    {"provider": "tmdb", "category": "top_rated",     "title": "Top Rated"},
    {"provider": "tmdb", "category": "now_playing",   "title": "Now Playing"},
    {"provider": "tmdb", "category": "upcoming",      "title": "Upcoming"},
    {"provider": "tmdb", "category": "trending_week", "title": "Trending This Week"},
]

_DEFAULT_SHOW_WIDGETS: List[Dict[str, Any]] = [
    {"provider": "tmdb", "category": "trending_day",  "title": "Trending Today"},
    {"provider": "tmdb", "category": "popular",       "title": "Popular"},
    {"provider": "tmdb", "category": "top_rated",     "title": "Top Rated"},
    {"provider": "tmdb", "category": "airing_today",  "title": "Airing Today"},
    {"provider": "tmdb", "category": "on_the_air",    "title": "On The Air"},
    {"provider": "tmdb", "category": "trending_week", "title": "Trending This Week"},
]


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


@router.get("/widgets")
async def get_widget_config() -> Dict[str, Any]:
    """Get the 6-slot widget configuration for Movies and Shows pages.

    Returns saved configuration from ``user_settings.json``.  Falls back to
    built-in defaults when no configuration has been saved yet.
    """
    from warp_mediacenter.config.settings.library import load_user_settings

    user_cfg = load_user_settings()
    widgets_cfg = user_cfg.get("widgets", {})
    movies = widgets_cfg.get("movies")
    shows = widgets_cfg.get("shows")

    # Validate length — fall back to defaults if the stored data is corrupt
    if not isinstance(movies, list) or len(movies) != 6:
        movies = _DEFAULT_MOVIE_WIDGETS
    if not isinstance(shows, list) or len(shows) != 6:
        shows = _DEFAULT_SHOW_WIDGETS

    return {"movies": movies, "shows": shows}


@router.put("/widgets")
async def save_widget_config(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Persist the 6-slot widget configuration for Movies and Shows pages.

    Accepts ``movies`` and/or ``shows`` arrays (each exactly 6 items) and
    writes them to ``user_settings.json`` under the ``widgets`` key.
    """
    from warp_mediacenter.config.settings.library import load_user_settings, write_user_settings
    from datetime import datetime, timezone

    movies = payload.get("movies")
    shows = payload.get("shows")

    if movies is not None and not isinstance(movies, list):
        raise HTTPException(status_code=400, detail="movies must be a list")
    if shows is not None and not isinstance(shows, list):
        raise HTTPException(status_code=400, detail="shows must be a list")

    user_cfg = load_user_settings()
    widgets_cfg = dict(user_cfg.get("widgets", {}))

    if movies is not None:
        widgets_cfg["movies"] = movies
    if shows is not None:
        widgets_cfg["shows"] = shows

    user_cfg["widgets"] = widgets_cfg
    user_cfg["updated_at"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
    write_user_settings(user_cfg)

    log.info("widget_config_saved", movies=len(movies or []), shows=len(shows or []))
    return {
        "message": "Widget configuration saved",
        "movies_count": len(movies) if movies else 0,
        "shows_count": len(shows) if shows else 0,
    }


@router.get("/search-history")
async def get_search_history() -> Dict[str, Any]:
    """Get the last 10 search queries."""
    with db_connection() as conn:
        value = get_setting(conn, "search_history")
    history: List[str] = json.loads(value) if value else []
    return {"history": history}


@router.post("/search-history")
async def add_search_query(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Add a query to search history (max 10 entries, most-recent first, deduped)."""
    query = str(payload.get("query", "")).strip()
    if not query:
        raise HTTPException(status_code=400, detail="query is required")
    with db_connection() as conn:
        existing = get_setting(conn, "search_history")
        history: List[str] = json.loads(existing) if existing else []
        history = [q for q in history if q != query]
        history.insert(0, query)
        history = history[:10]
        set_setting(conn, "search_history", json.dumps(history))
    return {"history": history}


@router.delete("/search-history")
async def delete_search_query(query: str) -> Dict[str, Any]:
    """Remove a specific query from search history by query param."""
    q = query.strip()
    if not q:
        raise HTTPException(status_code=400, detail="query is required")
    with db_connection() as conn:
        existing = get_setting(conn, "search_history")
        history: List[str] = json.loads(existing) if existing else []
        history = [item for item in history if item != q]
        set_setting(conn, "search_history", json.dumps(history))
    return {"history": history}


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
            debrid_status["authenticated"] = container.debrid_client._settings.has_valid_token
            debrid_status["api_key_configured"] = bool(
                container.debrid_client._settings.access_token
                or container.debrid_client._settings.refresh_token
            )
        else:
            debrid_status["authenticated"] = False
            debrid_status["api_key_configured"] = False
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

        _cancel_event.clear()
        _scan_status["running"] = True
        _scan_status["progress"] = 0
        _scan_status["message"] = "starting"
        _scan_status["logs"] = []
        _scan_status["files_done"] = 0
        _scan_status["files_total"] = 0
        _scan_status.pop("result", None)

    def _append_log(msg: str) -> None:
        with _scan_lock:
            _scan_status["logs"].append(msg)

    def _run_scan():
        import warp_mediacenter.backend.library.scanner as _scanner_mod
        _scanner_mod._ui_log_fn = _append_log

        def _progress_callback(done: int, total: int) -> None:
            with _scan_lock:
                _scan_status["files_done"] = done
                _scan_status["files_total"] = total
                if total > 0:
                    _scan_status["progress"] = int(done / total * 100)

        _scanner_mod._progress_fn = _progress_callback
        try:
            path_objs = [Path(p) for p in paths]
            _append_log(f"Starting scan of {len(path_objs)} path(s): {', '.join(paths)}")
            result = scan_once(path_objs, incremental=incremental, cancel_event=_cancel_event)

            if _cancel_event.is_set():
                _append_log("Scan cancelled.")
                with _scan_lock:
                    _scan_status["running"] = False
                    _scan_status["message"] = "cancelled"
                return

            summary = (
                f"Scan complete in {result.duration_sec:.1f}s — "
                f"{result.total} files, {result.movies} movies, "
                f"{result.shows} shows ({result.matched} matched, "
                f"{result.errors} errors)"
            )
            _append_log(summary)

            with _scan_lock:
                _scan_status["running"] = False
                _scan_status["progress"] = 100
                _scan_status["message"] = "complete"
                _scan_status["result"] = {
                    "total_files": result.total,
                    "new_titles": result.movies + result.shows,
                    "updated_titles": result.matched,
                    "new_episodes": result.episodes,
                    "duration_sec": round(result.duration_sec, 2),
                }
        except Exception as exc:
            _append_log(f"Error: {exc}")
            with _scan_lock:
                _scan_status["running"] = False
                _scan_status["message"] = f"error: {exc}"
        finally:
            _scanner_mod._ui_log_fn = None
            _scanner_mod._progress_fn = None

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


@router.post("/library/scan/cancel")
async def cancel_library_scan() -> Dict[str, Any]:
    """Request graceful cancellation of the running scan.

    Returns immediately — the scan threads exit at their next checkpoint
    (before starting each new file's network phase). Status transitions to
    'cancelled' once the last in-flight file finishes.
    """
    with _scan_lock:
        if not _scan_status["running"]:
            return {"status": "not_running"}
        _scan_status["message"] = "cancelling"
    _cancel_event.set()
    return {"status": "cancelling"}


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
