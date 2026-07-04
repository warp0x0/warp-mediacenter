"""Media streaming routes with HTTP range request support."""

from __future__ import annotations

import os
import stat
from pathlib import Path
from typing import AsyncIterable, Optional

import aiohttp
from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.persistence import (
    connection as db_connection,
    get_local_file_for_title,
    get_title_by_tmdb,
)

log = get_logger(__name__)

router = APIRouter()

_CHUNK_SIZE = 1024 * 1024  # 1MB chunks for streaming


@router.get("/{source_id:path}")
async def stream_media(source_id: str, request: Request) -> StreamingResponse:
    """Stream a media file by source ID.

    Supports HTTP range requests for seeking.
    source_id can be:
    - A numeric source ID from the database
    - A TMDb ID (will use first local source)
    - A direct file path (URL-encoded)
    """
    file_path = _resolve_source_path(source_id)
    if file_path is None:
        raise HTTPException(status_code=404, detail="Source not found")

    if not file_path.exists():
        raise HTTPException(status_code=404, detail="File not found on disk")

    file_size = file_path.stat().st_size
    range_header = request.headers.get("range")

    if range_header:
        return await _handle_range_request(file_path, file_size, range_header)

    return _full_file_response(file_path, file_size)


@router.get("/remote")
async def stream_remote(url: str, request: Request) -> StreamingResponse:
    """Proxy a remote media URL (e.g., RealDebrid stream) with range support."""
    range_header = request.headers.get("range")
    headers = {}
    if range_header:
        headers["Range"] = range_header

    async with aiohttp.ClientSession() as session:
        async with session.get(url, headers=headers, timeout=aiohttp.ClientTimeout(total=3600)) as resp:
            if resp.status >= 400:
                raise HTTPException(status_code=resp.status, detail="Upstream error")

            content_length = resp.headers.get("Content-Length")
            content_range = resp.headers.get("Content-Range")
            content_type = resp.headers.get("Content-Type", "application/octet-stream")

            response_headers = {
                "Accept-Ranges": "bytes",
                "Content-Type": content_type,
            }
            if content_range:
                response_headers["Content-Range"] = content_range
                response_headers["Content-Length"] = resp.headers.get("Content-Length", "0")
            elif content_length:
                response_headers["Content-Length"] = content_length

            status_code = resp.status

            async def chunk_iterator() -> AsyncIterable[bytes]:
                async for chunk in resp.content.iter_chunked(_CHUNK_SIZE):
                    yield chunk

            return StreamingResponse(
                chunk_iterator(),
                status_code=status_code,
                headers=response_headers,
            )


def _resolve_source_path(source_id: str) -> Optional[Path]:
    """Resolve a source ID to a local file path."""
    if source_id.startswith("/"):
        return Path(source_id)

    # Leading slash stripped by URL routing (e.g. /tmp/... → tmp/...).
    # Reconstruct the absolute path and verify it exists.
    candidate = Path("/" + source_id)
    if candidate.is_file():
        return candidate

    try:
        numeric_id = int(source_id)
        with db_connection() as conn:
            rows = conn.execute(
                "SELECT file_path FROM sources WHERE id = ? AND source_type = 'local'",
                (numeric_id,),
            ).fetchall()
            if rows:
                return Path(rows[0]["file_path"])
    except ValueError:
        pass

    with db_connection() as conn:
        title_row = get_title_by_tmdb(conn, source_id)
        if title_row:
            source_row = get_local_file_for_title(conn, int(title_row["id"]))
            if source_row:
                return Path(source_row["file_path"])

    return None


def _full_file_response(file_path: Path, file_size: int) -> StreamingResponse:
    """Return full file streaming response."""
    content_type = _guess_content_type(file_path)

    async def chunk_iterator() -> AsyncIterable[bytes]:
        with open(file_path, "rb") as f:
            while True:
                chunk = f.read(_CHUNK_SIZE)
                if not chunk:
                    break
                yield chunk

    return StreamingResponse(
        chunk_iterator(),
        media_type=content_type,
        headers={
            "Content-Length": str(file_size),
            "Accept-Ranges": "bytes",
        },
    )


async def _handle_range_request(
    file_path: Path,
    file_size: int,
    range_header: str,
) -> StreamingResponse:
    """Handle HTTP range request for partial content streaming."""
    try:
        range_str = range_header.replace("bytes=", "")
        start_str, end_str = range_str.split("-", 1)
        start = int(start_str) if start_str else 0
        end = int(end_str) if end_str else file_size - 1
    except (ValueError, IndexError):
        raise HTTPException(status_code=416, detail="Invalid range header")

    if start >= file_size or end >= file_size or start > end:
        raise HTTPException(status_code=416, detail="Range not satisfiable")

    end = min(end, file_size - 1)
    content_length = end - start + 1
    content_type = _guess_content_type(file_path)

    async def range_iterator() -> AsyncIterable[bytes]:
        with open(file_path, "rb") as f:
            f.seek(start)
            remaining = content_length
            while remaining > 0:
                chunk_size = min(_CHUNK_SIZE, remaining)
                chunk = f.read(chunk_size)
                if not chunk:
                    break
                remaining -= len(chunk)
                yield chunk

    return StreamingResponse(
        range_iterator(),
        status_code=206,
        media_type=content_type,
        headers={
            "Content-Range": f"bytes {start}-{end}/{file_size}",
            "Content-Length": str(content_length),
            "Accept-Ranges": "bytes",
        },
    )


def _guess_content_type(file_path: Path) -> str:
    """Guess content type from file extension."""
    ext = file_path.suffix.lower()
    mapping = {
        ".mp4": "video/mp4",
        ".mkv": "video/x-matroska",
        ".avi": "video/x-msvideo",
        ".mov": "video/quicktime",
        ".webm": "video/webm",
        ".m4v": "video/x-m4v",
        ".mp3": "audio/mpeg",
        ".flac": "audio/flac",
        ".srt": "application/x-subrip",
        ".vtt": "text/vtt",
        ".ass": "text/x-ssa",
        ".ssa": "text/x-ssa",
    }
    return mapping.get(ext, "application/octet-stream")
