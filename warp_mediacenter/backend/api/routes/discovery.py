"""Discovery and search routes for Warp MediaCenter API."""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException, Query

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.api.middleware import get_container
from warp_mediacenter.backend.information_handlers.models import MediaType
from warp_mediacenter.backend.information_handlers.providers import InformationProviders
from warp_mediacenter.backend.persistence import (
    connection as db_connection,
    search_titles,
)

log = get_logger(__name__)

search_router = APIRouter()
catalog_router = APIRouter()


def _get_providers() -> InformationProviders:
    """Get InformationProviders from container or create default."""
    container = get_container()
    if container.information_providers is not None:
        return container.information_providers
    return InformationProviders()


def _catalog_item_to_dict(item) -> Dict[str, Any]:
    """Convert a CatalogItem to a dict."""
    if hasattr(item, "model_dump"):
        return item.model_dump(mode="json")
    return dict(item) if hasattr(item, "__iter__") else {}


def _trakt_search_to_dict(result) -> Dict[str, Any]:
    """Convert a TraktSearchResult to a dict."""
    if hasattr(result, "model_dump"):
        return result.model_dump(mode="json")
    return {}


# ------------------------------------------------------------------
# Search routes
# ------------------------------------------------------------------

@search_router.get("/tmdb")
async def search_tmdb(
    q: str = Query(min_length=1),
    type: str = Query(default="all", regex="^(movie|show|all)$"),
    page: int = Query(default=1, ge=1),
    language: Optional[str] = Query(default=None),
) -> Dict[str, Any]:
    """Search TMDb for movies and/or shows."""
    providers = _get_providers()
    results: List[Dict[str, Any]] = []

    if type in ("movie", "all"):
        movies = providers.search_movies(q, language=language, page=page)
        results.extend([_catalog_item_to_dict(m) for m in movies])

    if type in ("show", "all"):
        shows = providers.search_shows(q, language=language, page=page)
        results.extend([_catalog_item_to_dict(s) for s in shows])

    return {
        "query": q,
        "type": type,
        "page": page,
        "results": results,
        "count": len(results),
    }


@search_router.get("/trakt")
async def search_trakt(
    q: str = Query(min_length=1),
    type: str = Query(default="all", regex="^(movie|show|all)$"),
    limit: int = Query(default=10, ge=1, le=50),
    year: Optional[int] = Query(default=None),
) -> Dict[str, Any]:
    """Search Trakt for movies and/or shows."""
    providers = _get_providers()

    types = []
    if type in ("movie", "all"):
        types.append(MediaType.MOVIE)
    if type in ("show", "all"):
        types.append(MediaType.SHOW)

    results = providers.search_trakt(q, types=types if types else None, limit=limit, year=year)

    return {
        "query": q,
        "type": type,
        "limit": limit,
        "year": year,
        "results": [_trakt_search_to_dict(r) for r in results],
        "count": len(results),
    }


@search_router.get("/unified")
async def search_unified(
    q: str = Query(min_length=1),
    limit: int = Query(default=10, ge=1, le=50),
) -> Dict[str, Any]:
    """Unified search across local library, TMDb, and Trakt.

    Deduplicates by TMDb ID. Local results take priority, then TMDb, then Trakt.
    """
    results: List[Dict[str, Any]] = []
    seen_tmdb_ids: set = set()

    # 1. Local library search
    with db_connection() as conn:
        local_rows = search_titles(conn, q, limit=limit)
        for row in local_rows:
            d = dict(row)
            d["source"] = "local"
            results.append(d)
            tmdb_id = d.get("tmdb_id")
            if tmdb_id:
                seen_tmdb_ids.add(str(tmdb_id))

    # 2. TMDb search (fill remaining slots)
    remaining = limit - len(results)
    if remaining > 0:
        try:
            providers = _get_providers()
            tmdb_movies = providers.search_movies(q, page=1)
            for item in tmdb_movies:
                if len(results) >= limit:
                    break
                d = _catalog_item_to_dict(item)
                tmdb_id = d.get("id") or d.get("tmdb_id")
                if tmdb_id and str(tmdb_id) not in seen_tmdb_ids:
                    d["source"] = "tmdb"
                    results.append(d)
                    seen_tmdb_ids.add(str(tmdb_id))
        except Exception as exc:
            log.warning("unified_search_tmdb_failed: %s", str(exc))

    # 3. Trakt search (fill remaining slots)
    remaining = limit - len(results)
    if remaining > 0:
        try:
            providers = _get_providers()
            trakt_results = providers.search_trakt(q, limit=remaining)
            for result in trakt_results:
                if len(results) >= limit:
                    break
                d = _trakt_search_to_dict(result)
                ids = d.get("ids", {})
                tmdb_id = ids.get("tmdb")
                if tmdb_id and str(tmdb_id) not in seen_tmdb_ids:
                    d["source"] = "trakt"
                    results.append(d)
                    seen_tmdb_ids.add(str(tmdb_id))
        except Exception as exc:
            log.warning("unified_search_trakt_failed: %s", str(exc))

    return {
        "query": q,
        "results": results,
        "count": len(results),
        "sources": {
            "local": sum(1 for r in results if r.get("source") == "local"),
            "tmdb": sum(1 for r in results if r.get("source") == "tmdb"),
            "trakt": sum(1 for r in results if r.get("source") == "trakt"),
        },
    }


# ------------------------------------------------------------------
# Catalog routes
# ------------------------------------------------------------------

@catalog_router.get("/tmdb/{category}")
async def tmdb_catalog(
    category: str,
    media_type: str = Query(default="movie", regex="^(movie|show)$"),
    page: int = Query(default=1, ge=1),
    language: Optional[str] = Query(default=None),
) -> Dict[str, Any]:
    """Get a TMDb catalog (trending, popular, top_rated, upcoming, now_playing)."""
    providers = _get_providers()
    mt = MediaType.MOVIE if media_type == "movie" else MediaType.SHOW

    try:
        items = providers.tmdb.catalog(mt, category, language=language, page=page)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"TMDb catalog error: {exc}")

    return {
        "category": category,
        "media_type": media_type,
        "page": page,
        "items": [_catalog_item_to_dict(i) for i in items],
        "count": len(items),
    }


@catalog_router.get("/trakt/{category}")
async def trakt_catalog(
    category: str,
    media_type: str = Query(default="movie", regex="^(movie|show)$"),
    period: str = Query(default="daily", regex="^(daily|weekly|monthly|yearly|all)$"),
    limit: int = Query(default=40, ge=1, le=100),
) -> Dict[str, Any]:
    """Get a Trakt catalog (trending, popular, anticipated, watched, played)."""
    providers = _get_providers()
    mt = MediaType.MOVIE if media_type == "movie" else MediaType.SHOW

    try:
        items = providers.trakt_catalog(mt, category, period=period, limit=limit)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Trakt catalog error: {exc}")

    return {
        "category": category,
        "media_type": media_type,
        "period": period,
        "items": [_catalog_item_to_dict(i) for i in items],
        "count": len(items),
    }


@catalog_router.get("/continue-watching")
async def continue_watching(
    movie_limit: int = Query(default=25, ge=1, le=50),
    show_limit: int = Query(default=25, ge=1, le=50),
    history_window: int = Query(default=20, ge=1, le=100),
) -> Dict[str, Any]:
    """Get continue watching widget from Trakt."""
    providers = _get_providers()

    try:
        payload = providers.get_trakt_continue_watching(
            movie_limit=movie_limit,
            show_limit=show_limit,
            history_window=history_window,
        )
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Continue watching error: {exc}")

    return payload


@catalog_router.get("/public-domain")
async def public_domain_catalog(
    key: Optional[str] = Query(default=None),
) -> Dict[str, Any]:
    """Get public domain sources or catalog.

    If key is provided, returns catalog items for that source.
    If key is omitted, returns list of available public domain sources.
    """
    providers = _get_providers()

    if key:
        try:
            items = providers.fetch_public_domain_catalog(key)
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Public domain catalog error: {exc}")

        return {
            "source": key,
            "items": [_catalog_item_to_dict(i) for i in items],
            "count": len(items),
        }
    else:
        sources = providers.list_public_domain_sources()
        curated = providers.list_curated_catalogs()

        return {
            "sources": [
                {
                    "key": s.key,
                    "label": s.label,
                    "base_url": s.base_url,
                    "path": s.path,
                }
                for s in sources
            ],
            "curated_catalogs": curated,
            "count": len(sources),
        }
