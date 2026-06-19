"""Library and catalog routes for Warp MediaCenter API."""

from __future__ import annotations

import json
import mimetypes
import re
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException, Query, Request
from fastapi.responses import FileResponse, Response, StreamingResponse

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


def _resolve_title(conn, title_id: str):
    """Look up a title by DB id or TMDb id.

    Numeric strings are tried as a DB auto-increment id first; if that returns
    nothing (e.g. the caller passed a large TMDb id like '97630') we fall back
    to a TMDb id lookup so both id formats work transparently.
    """
    row = None
    if title_id.isdigit():
        row = get_title_by_id(conn, int(title_id))
    if row is None:
        row = get_title_by_tmdb(conn, title_id)
    return row


_VALID_LIBRARY_SORTS = {"title", "added_at", "year"}


_LOCAL_FILTER = (
    " AND EXISTS ("
    "SELECT 1 FROM sources"
    " WHERE sources.title_id = titles.id"
    " AND sources.source_type = 'local'"
    " AND sources.status != 'missing'"
    ")"
)


@router.get("/movies")
async def list_movies(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    sort: str = Query(default="added_at"),
    order: str = Query(default="desc"),
    local_only: bool = Query(default=False),
) -> Dict[str, Any]:
    """List movies with pagination and sorting."""
    sort_col = sort if sort in _VALID_LIBRARY_SORTS else "added_at"
    order_dir = "ASC" if order.lower() == "asc" else "DESC"
    extra = _LOCAL_FILTER if local_only else ""

    with db_connection() as conn:
        total_row = conn.execute(
            f"SELECT COUNT(*) as cnt FROM titles WHERE type = 'movie'{extra}"
        ).fetchone()
        total = total_row["cnt"] if total_row else 0
        rows = conn.execute(
            f"SELECT * FROM titles WHERE type = 'movie'{extra}"
            f" ORDER BY {sort_col} {order_dir} LIMIT ? OFFSET ?",
            (limit + 1, offset),
        ).fetchall()

    items = [_row_to_dict(r) for r in rows]
    has_next = len(items) > limit
    return {"items": items[:limit], "total": total, "limit": limit, "offset": offset, "has_next": has_next}


@router.get("/shows")
async def list_shows(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    sort: str = Query(default="added_at"),
    order: str = Query(default="desc"),
    local_only: bool = Query(default=False),
) -> Dict[str, Any]:
    """List shows with pagination and sorting."""
    sort_col = sort if sort in _VALID_LIBRARY_SORTS else "added_at"
    order_dir = "ASC" if order.lower() == "asc" else "DESC"
    extra = _LOCAL_FILTER if local_only else ""

    with db_connection() as conn:
        total_row = conn.execute(
            f"SELECT COUNT(*) as cnt FROM titles WHERE type IN ('tv', 'show'){extra}"
        ).fetchone()
        total = total_row["cnt"] if total_row else 0
        rows = conn.execute(
            f"SELECT * FROM titles WHERE type IN ('tv', 'show'){extra}"
            f" ORDER BY {sort_col} {order_dir} LIMIT ? OFFSET ?",
            (limit + 1, offset),
        ).fetchall()

    items = [_row_to_dict(r) for r in rows]
    has_next = len(items) > limit
    return {"items": items[:limit], "total": total, "limit": limit, "offset": offset, "has_next": has_next}


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
        row = _resolve_title(conn, title_id)

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
        row = _resolve_title(conn, title_id)

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


@router.get("/sources/{source_id}/stream/{filename:path}")
async def stream_local_source(source_id: int, filename: str, request: Request) -> Response:
    """Stream a local file with full HTTP Range support for mpv seeking and resume.

    The {filename} path suffix is ignored by the backend — it exists solely so
    mpv sees the real file extension in the URL and picks the right demuxer.
    The backend resolves the actual file from the source_id in the database.
    """
    with db_connection() as conn:
        row = conn.execute(
            "SELECT s.file_path "
            "FROM sources s "
            "WHERE s.id = ? AND s.source_type = 'local' AND s.status != 'missing'",
            (source_id,),
        ).fetchone()

    if row is None or not row["file_path"]:
        raise HTTPException(status_code=404, detail="Local source not found")

    file_path = Path(row["file_path"])
    if not file_path.is_file():
        raise HTTPException(status_code=404, detail="File not found on disk")

    file_size = file_path.stat().st_size
    mime_type, _ = mimetypes.guess_type(file_path.name)
    content_type = mime_type or "application/octet-stream"
    disposition = f'inline; filename="{file_path.name}"'

    range_header = request.headers.get("Range")
    if range_header:
        m = re.match(r"bytes=(\d+)-(\d*)", range_header)
        if m:
            start = int(m.group(1))
            end = int(m.group(2)) if m.group(2) else file_size - 1
            end = min(end, file_size - 1)
            length = end - start + 1

            async def _range_iter():
                with open(file_path, "rb") as f:
                    f.seek(start)
                    remaining = length
                    while remaining > 0:
                        chunk = f.read(min(65536, remaining))
                        if not chunk:
                            break
                        remaining -= len(chunk)
                        yield chunk

            return StreamingResponse(
                _range_iter(),
                status_code=206,
                media_type=content_type,
                headers={
                    "Accept-Ranges": "bytes",
                    "Content-Range": f"bytes {start}-{end}/{file_size}",
                    "Content-Length": str(length),
                    "Content-Disposition": disposition,
                },
            )

    # Full-file response — still streams in chunks but reports full Content-Length
    # so mpv can calculate seek positions for --start=X%.
    async def _full_iter():
        with open(file_path, "rb") as f:
            while True:
                chunk = f.read(65536)
                if not chunk:
                    break
                yield chunk

    return StreamingResponse(
        _full_iter(),
        media_type=content_type,
        headers={
            "Accept-Ranges": "bytes",
            "Content-Length": str(file_size),
            "Content-Disposition": disposition,
        },
    )


@router.get("/title/{title_id}/sources")
async def get_title_sources(
    title_id: str,
    source_type: Optional[str] = Query(default=None),
) -> Dict[str, Any]:
    """Get sources for a title, optionally filtered by source_type."""
    with db_connection() as conn:
        row = _resolve_title(conn, title_id)

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
