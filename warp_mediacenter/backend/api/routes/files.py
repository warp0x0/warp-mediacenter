"""Filesystem browse endpoint for the folder-picker UI."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, List

from fastapi import APIRouter, HTTPException, Query

from warp_mediacenter.backend.common.logging import get_logger

log = get_logger(__name__)

router = APIRouter()


@router.get("/browse")
async def browse_directory(
    path: str = Query(default=""),
) -> Dict[str, Any]:
    """List immediate children of a directory.

    Defaults to the user home directory when no path is given.
    Hidden entries (starting with '.') are skipped.
    """
    target = Path(path).expanduser().resolve() if path else Path.home()

    if not target.exists():
        raise HTTPException(status_code=404, detail="Path does not exist")
    if not target.is_dir():
        raise HTTPException(status_code=400, detail="Path is not a directory")

    entries: List[Dict[str, Any]] = []
    try:
        for child in sorted(target.iterdir(), key=lambda p: (not p.is_dir(), p.name.lower())):
            if child.name.startswith("."):
                continue
            entries.append(
                {
                    "name": child.name,
                    "path": str(child),
                    "is_dir": child.is_dir(),
                }
            )
    except PermissionError:
        pass  # return empty entries for unreadable dirs

    parent = str(target.parent) if target != target.parent else None

    return {
        "path": str(target),
        "parent": parent,
        "entries": entries,
    }
