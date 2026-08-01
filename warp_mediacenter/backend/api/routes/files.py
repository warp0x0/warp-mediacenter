"""Filesystem browse endpoint for the folder-picker UI."""

from __future__ import annotations

import asyncio
import re
from pathlib import Path
from typing import Any, Dict, List
from urllib.parse import unquote, urlsplit

import requests

from fastapi import APIRouter, HTTPException, Query

from warp_mediacenter.backend.common.logging import get_logger

log = get_logger(__name__)

router = APIRouter()


@router.get("/browse")
async def browse_directory(
    path: str = Query(default=""),
    ext: str = Query(default=""),
) -> Dict[str, Any]:
    """List immediate children of a directory.

    Defaults to the user home directory when no path is given.
    Hidden entries (starting with '.') are skipped.

    ``ext`` filters files to a comma-separated list of extensions ("zip" or
    "zip,tar.gz").  Directories are always listed regardless, otherwise the
    picker could not navigate to the file it is filtering for.
    """
    target = Path(path).expanduser().resolve() if path else Path.home()

    if not target.exists():
        raise HTTPException(status_code=404, detail="Path does not exist")
    if not target.is_dir():
        raise HTTPException(status_code=400, detail="Path is not a directory")

    suffixes = {
        f".{part.strip().lstrip('.').lower()}"
        for part in ext.split(",")
        if part.strip()
    }

    entries: List[Dict[str, Any]] = []
    try:
        for child in sorted(target.iterdir(), key=lambda p: (not p.is_dir(), p.name.lower())):
            if child.name.startswith("."):
                continue
            is_dir = child.is_dir()
            if suffixes and not is_dir:
                if not any(child.name.lower().endswith(s) for s in suffixes):
                    continue
            entries.append(
                {
                    "name": child.name,
                    "path": str(child),
                    "is_dir": is_dir,
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


_DISPOSITION_FILENAME = re.compile(r'filename\*?=(?:UTF-8\'\')?"?([^";]+)"?', re.IGNORECASE)


def _filename_from(url: str, headers: Any) -> str:
    disposition = headers.get("content-disposition") or ""
    match = _DISPOSITION_FILENAME.search(disposition)
    if match:
        return unquote(match.group(1)).strip()
    name = unquote(Path(urlsplit(url).path).name)
    return name or "download"


def _probe_remote(url: str) -> requests.Response:
    """Resolve just enough of the URL to describe it — no body is downloaded.

    Tries HEAD first (cheap); some hosts (GitHub Pages among them) reject or
    mishandle HEAD, so a ranged GET for the first byte is the fallback.
    """
    resp = requests.head(url, allow_redirects=True, timeout=15)
    if resp.status_code >= 400 or resp.status_code == 405:
        resp = requests.get(
            url, allow_redirects=True, timeout=15, headers={"Range": "bytes=0-0"}, stream=True
        )
        resp.close()
    return resp


@router.get("/browse-remote")
async def browse_remote(url: str = Query(...)) -> Dict[str, Any]:
    """Resolve a remote http(s) URL to a single pickable entry.

    Deliberately narrow in scope: there is no universal protocol for listing
    an arbitrary URL's "directory" the way a filesystem can be listed, so this
    does not attempt to crawl one — it resolves the given URL (e.g. a plugin
    .zip published on GitHub Pages) to one file entry, in the same shape
    ``/browse`` returns, so the picker's existing entry list and "tap to
    choose" flow work unmodified. A network-mounted filesystem path (SMB/NFS
    already mounted on this host) is not "remote" from this process's point
    of view at all — that goes through ``/browse`` above, which already
    handles any path the OS can stat.
    """
    parsed = urlsplit(url)
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        raise HTTPException(
            status_code=400, detail="Enter a full http:// or https:// URL"
        )

    try:
        resp = await asyncio.to_thread(_probe_remote, url)
    except requests.RequestException as exc:
        raise HTTPException(status_code=502, detail=f"Could not reach that URL: {exc}") from exc

    if resp.status_code >= 400:
        raise HTTPException(
            status_code=404, detail=f"URL returned HTTP {resp.status_code}"
        )

    name = _filename_from(url, resp.headers)
    return {
        "path": url,
        "parent": None,
        "entries": [{"name": name, "path": url, "is_dir": False}],
    }
