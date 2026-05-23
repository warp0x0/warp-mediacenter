"""Image/artwork serving routes."""

from __future__ import annotations

from pathlib import Path
from typing import Optional

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.persistence import (
    connection as db_connection,
    get_title_by_tmdb,
)
from warp_mediacenter.config.settings import get_cache_root

log = get_logger(__name__)

router = APIRouter()

_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".tiff"}


@router.get("/tmdb/{tmdb_id}/{image_type}")
async def get_tmdb_artwork(
    tmdb_id: str,
    image_type: str,
) -> FileResponse:
    """Serve cached TMDb artwork for a title.

    image_type: 'poster' or 'backdrop'
    """
    if image_type not in ("poster", "backdrop"):
        raise HTTPException(status_code=400, detail="image_type must be 'poster' or 'backdrop'")

    image_path = _find_artwork(tmdb_id, image_type)
    if image_path is None or not image_path.exists():
        raise HTTPException(status_code=404, detail="Artwork not found")

    return FileResponse(
        str(image_path),
        media_type=_guess_image_type(image_path),
        headers={"Cache-Control": "public, max-age=86400"},
    )


@router.get("/path/{path:path}")
async def serve_image_by_path(path: str) -> FileResponse:
    """Serve an image by absolute or relative path.

    Useful for serving downloaded artwork or thumbnails.
    """
    image_path = Path(path)
    if not image_path.exists():
        raise HTTPException(status_code=404, detail="Image not found")

    if image_path.suffix.lower() not in _IMAGE_EXTENSIONS:
        raise HTTPException(status_code=400, detail="Not an image file")

    return FileResponse(
        str(image_path),
        media_type=_guess_image_type(image_path),
        headers={"Cache-Control": "public, max-age=86400"},
    )


def _find_artwork(tmdb_id: str, image_type: str) -> Optional[Path]:
    """Find cached artwork file for a TMDb ID."""
    cache_root = Path(get_cache_root())
    artwork_dir = cache_root / "artwork" / tmdb_id

    if not artwork_dir.exists():
        with db_connection() as conn:
            title_row = get_title_by_tmdb(conn, tmdb_id)
            if title_row is None:
                return None
            poster_path = title_row.get("poster_path")
            backdrop_path = title_row.get("backdrop_path")
            if image_type == "poster" and poster_path:
                return Path(poster_path)
            if image_type == "backdrop" and backdrop_path:
                return Path(backdrop_path)
        return None

    prefix = "poster" if image_type == "poster" else "backdrop"
    for ext in _IMAGE_EXTENSIONS:
        candidate = artwork_dir / f"{prefix}{ext}"
        if candidate.exists():
            return candidate
        candidate = artwork_dir / f"{prefix}_original{ext}"
        if candidate.exists():
            return candidate

    return None


def _guess_image_type(image_path: Path) -> str:
    """Guess MIME type from file extension."""
    ext = image_path.suffix.lower()
    mapping = {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".webp": "image/webp",
        ".gif": "image/gif",
        ".bmp": "image/bmp",
        ".tiff": "image/tiff",
    }
    return mapping.get(ext, "application/octet-stream")
