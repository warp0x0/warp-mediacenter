"""User collections (Liked & Wishlist) routes."""

from __future__ import annotations

import json
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException, Query

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.persistence import (
    connection as db_connection,
    upsert_collection_item,
    remove_collection_item,
    is_in_collection,
    list_collection_items,
)

log = get_logger(__name__)

router = APIRouter()

_VALID_COLLECTIONS = {"liked", "wishlist"}
_VALID_SORTS = {"added_at", "title", "rating", "vote_count"}
_VALID_ORDERS = {"asc", "desc"}


def _validate_collection(collection_type: str) -> None:
    if collection_type not in _VALID_COLLECTIONS:
        raise HTTPException(status_code=404, detail=f"Unknown collection: {collection_type}")


def _row_to_dict(row: Any) -> Dict[str, Any]:
    d = dict(row)
    genres_json = d.pop("genres_json", "[]")
    try:
        d["genres"] = json.loads(genres_json) if genres_json else []
    except (json.JSONDecodeError, TypeError):
        d["genres"] = []
    return d


@router.get("/{collection_type}")
async def list_collection(
    collection_type: str,
    type: Optional[str] = Query(default=None),
    sort: str = Query(default="added_at"),
    order: str = Query(default="desc"),
    genre: Optional[str] = Query(default=None),
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
) -> Dict[str, Any]:
    """List items in a collection with pagination and sorting."""
    _validate_collection(collection_type)
    if type and type not in ("movie", "show"):
        type = None
    if sort not in _VALID_SORTS:
        sort = "added_at"
    if order not in _VALID_ORDERS:
        order = "desc"

    offset = (page - 1) * limit

    with db_connection() as conn:
        rows = list_collection_items(
            conn,
            collection_type=collection_type,
            media_type=type,
            sort=sort,
            order=order,
            genre=genre,
            limit=limit,
            offset=offset,
        )
        count_params: List[Any] = [collection_type]
        count_where = "collection_type = ?"
        if type:
            count_where += " AND type = ?"
            count_params.append(type)
        if genre:
            count_where += " AND genres_json LIKE ?"
            count_params.append(f"%{genre}%")
        total = conn.execute(
            f"SELECT COUNT(*) FROM user_collections WHERE {count_where}",
            count_params,
        ).fetchone()[0]

    return {
        "collection_type": collection_type,
        "items": [_row_to_dict(r) for r in rows],
        "count": total,
        "page": page,
        "limit": limit,
    }


@router.post("/{collection_type}")
async def add_to_collection(
    collection_type: str,
    payload: Dict[str, Any],
) -> Dict[str, Any]:
    """Add a media item to a collection."""
    _validate_collection(collection_type)

    tmdb_id = str(payload.get("tmdb_id", "")).strip()
    media_type = str(payload.get("type", "")).strip()
    title = str(payload.get("title", "")).strip()

    if not tmdb_id:
        raise HTTPException(status_code=400, detail="tmdb_id is required")
    if media_type not in ("movie", "show"):
        raise HTTPException(status_code=400, detail="type must be 'movie' or 'show'")
    if not title:
        raise HTTPException(status_code=400, detail="title is required")

    genres = payload.get("genres", [])
    if not isinstance(genres, list):
        genres = []

    item = {
        "collection_type": collection_type,
        "tmdb_id": tmdb_id,
        "type": media_type,
        "title": title,
        "year": payload.get("year"),
        "overview": payload.get("overview"),
        "poster_path": payload.get("poster_path"),
        "backdrop_path": payload.get("backdrop_path"),
        "rating": payload.get("rating"),
        "vote_count": payload.get("vote_count"),
        "genres_json": json.dumps(genres),
    }

    with db_connection() as conn:
        row_id = upsert_collection_item(conn, item)

    log.info("collection_item_added", collection_type=collection_type, tmdb_id=tmdb_id)
    return {"ok": True, "id": row_id, "tmdb_id": tmdb_id}


@router.delete("/{collection_type}/{tmdb_id}")
async def remove_from_collection(
    collection_type: str,
    tmdb_id: str,
) -> Dict[str, Any]:
    """Remove a media item from a collection."""
    _validate_collection(collection_type)

    with db_connection() as conn:
        removed = remove_collection_item(conn, collection_type=collection_type, tmdb_id=tmdb_id)

    if not removed:
        raise HTTPException(status_code=404, detail="Item not found in collection")

    log.info("collection_item_removed", collection_type=collection_type, tmdb_id=tmdb_id)
    return {"ok": True, "tmdb_id": tmdb_id}


@router.get("/{collection_type}/{tmdb_id}/status")
async def collection_item_status(
    collection_type: str,
    tmdb_id: str,
) -> Dict[str, Any]:
    """Check if a media item is in a collection."""
    _validate_collection(collection_type)

    with db_connection() as conn:
        in_col = is_in_collection(conn, collection_type=collection_type, tmdb_id=tmdb_id)

    return {"tmdb_id": tmdb_id, "in_collection": in_col}
