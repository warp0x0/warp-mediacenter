"""Library and catalog routes for Warp MediaCenter API."""

from __future__ import annotations

import json
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException, Query

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.persistence import (
    connection as db_connection,
    list_titles,
    search_titles,
    get_recently_added,
    get_title_by_id,
    get_title_by_tmdb,
    get_episodes_for_title,
    get_sources_for_title,
    get_title_by_tmdb_with_sources,
    list_library_sections,
    get_library_section,
)

log = get_logger(__name__)

router = APIRouter()


def _paginate(items: List[Dict[str, Any]], limit: int, offset: int, total: Optional[int] = None) -> Dict[str, Any]:
    """Wrap items in a pagination envelope."""
    actual_total = total if total is not None else len(items)
    sliced = items[offset : offset + limit]
    return {
        "items": sliced,
        "total": actual_total,
        "limit": limit,
        "offset": offset,
        "has_next": offset + limit < actual_total,
    }


def _row_to_dict(row) -> Dict[str, Any]:
    """Convert a sqlite3.Row to a dict."""
    return dict(row)


@router.get("/movies")
async def list_movies(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> Dict[str, Any]:
    """List movies with pagination."""
    with db_connection() as conn:
        rows = list_titles(conn, type="movie", limit=limit + 1, offset=offset)
        total_row = conn.execute("SELECT COUNT(*) as cnt FROM titles WHERE type = 'movie'").fetchone()
        total = total_row["cnt"] if total_row else 0

    items = [_row_to_dict(r) for r in rows]
    return _paginate(items, limit, offset, total)


@router.get("/shows")
async def list_shows(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
) -> Dict[str, Any]:
    """List shows with pagination."""
    with db_connection() as conn:
        rows = list_titles(conn, type="tv", limit=limit + 1, offset=offset)
        total_row = conn.execute("SELECT COUNT(*) as cnt FROM titles WHERE type = 'tv'").fetchone()
        total = total_row["cnt"] if total_row else 0

    items = [_row_to_dict(r) for r in rows]
    return _paginate(items, limit, offset, total)


@router.get("/recent")
async def list_recent(
    limit: int = Query(default=20, ge=1, le=100),
) -> Dict[str, Any]:
    """List recently added titles."""
    with db_connection() as conn:
        rows = get_recently_added(conn, limit=limit)

    items = [_row_to_dict(r) for r in rows]
    return {"items": items, "count": len(items)}


@router.get("/title/{title_id}")
async def get_title(title_id: str) -> Dict[str, Any]:
    """Get title details by ID (numeric) or TMDb ID."""
    with db_connection() as conn:
        if title_id.isdigit():
            row = get_title_by_id(conn, int(title_id))
        else:
            row = get_title_by_tmdb(conn, title_id)

        if row is None:
            raise HTTPException(status_code=404, detail="Title not found")

        result = _row_to_dict(row)
        source_info = get_title_by_tmdb_with_sources(conn, result.get("tmdb_id", ""))
        if source_info:
            result["has_local_source"] = source_info.get("has_local_source", False)
            result["source_count"] = source_info.get("source_count", 0)
            result["source_types"] = source_info.get("source_types", [])

    return result


@router.get("/title/{title_id}/episodes")
async def get_title_episodes(
    title_id: str,
    season: Optional[int] = Query(default=None, ge=1),
) -> Dict[str, Any]:
    """Get episodes for a show, optionally filtered by season."""
    with db_connection() as conn:
        if title_id.isdigit():
            row = get_title_by_id(conn, int(title_id))
        else:
            row = get_title_by_tmdb(conn, title_id)

        if row is None:
            raise HTTPException(status_code=404, detail="Title not found")

        if row["type"] not in ("tv", "show"):
            raise HTTPException(status_code=400, detail="Title is not a TV show")

        title_id_int = int(row["id"])
        episodes = get_episodes_for_title(conn, title_id_int, season=season)

    items = [_row_to_dict(e) for e in episodes]
    return {
        "title_id": title_id_int,
        "title": row["title"],
        "season_filter": season,
        "episodes": items,
        "count": len(items),
    }


@router.get("/title/{title_id}/sources")
async def get_title_sources(
    title_id: str,
    source_type: Optional[str] = Query(default=None),
) -> Dict[str, Any]:
    """Get sources for a title, optionally filtered by source_type."""
    with db_connection() as conn:
        if title_id.isdigit():
            row = get_title_by_id(conn, int(title_id))
        else:
            row = get_title_by_tmdb(conn, title_id)

        if row is None:
            raise HTTPException(status_code=404, detail="Title not found")

        title_id_int = int(row["id"])
        sources = get_sources_for_title(conn, title_id_int, source_type=source_type)

    items = [_row_to_dict(s) for s in sources]
    return {
        "title_id": title_id_int,
        "title": row["title"],
        "source_type_filter": source_type,
        "sources": items,
        "count": len(items),
    }


@router.get("/sections")
async def list_sections(
    kind: Optional[str] = Query(default=None),
    enabled_only: bool = Query(default=True),
) -> Dict[str, Any]:
    """List library sections."""
    with db_connection() as conn:
        rows = list_library_sections(conn, kind=kind, enabled_only=enabled_only)

    items = []
    for r in rows:
        d = _row_to_dict(r)
        d["paths"] = json.loads(d.pop("paths_json", "[]"))
        items.append(d)

    return {"sections": items, "count": len(items)}


@router.get("/sections/{section_id}")
async def get_section(section_id: int) -> Dict[str, Any]:
    """Get a library section by ID."""
    with db_connection() as conn:
        row = get_library_section(conn, section_id)
        if row is None:
            raise HTTPException(status_code=404, detail="Section not found")

        d = _row_to_dict(row)
        d["paths"] = json.loads(d.pop("paths_json", "[]"))

    return d


@router.get("/search")
async def search_library(
    q: str = Query(min_length=1),
    limit: int = Query(default=20, ge=1, le=100),
) -> Dict[str, Any]:
    """Search local library by title."""
    with db_connection() as conn:
        rows = search_titles(conn, q, limit=limit)

    items = [_row_to_dict(r) for r in rows]
    return {
        "query": q,
        "items": items,
        "count": len(items),
    }
