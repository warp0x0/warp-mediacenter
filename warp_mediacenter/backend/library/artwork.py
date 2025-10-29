"""Helpers to download and store artwork assets locally."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path
from typing import Optional, Tuple
from urllib.parse import urlsplit, urlunsplit

import requests

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.network_handlers.session import HttpSession

log = get_logger(__name__)

_SIZE_RE = re.compile(r"/w\d+/")


def download_artwork(
    poster_url: Optional[str],
    backdrop_url: Optional[str],
    dest_dir: Path,
    *,
    session: Optional[HttpSession] = None,
) -> Tuple[Optional[Path], Optional[Path]]:
    """Download poster/backdrop artwork and return local filesystem paths."""

    if poster_url is None and backdrop_url is None:
        return None, None

    dest_dir.mkdir(parents=True, exist_ok=True)
    http = session or HttpSession()

    poster_path = _download_single(http, poster_url, dest_dir, preferred_size="w342") if poster_url else None
    backdrop_path = _download_single(http, backdrop_url, dest_dir, preferred_size="w780") if backdrop_url else None

    return poster_path, backdrop_path


def _download_single(
    session: HttpSession,
    url: str,
    dest_dir: Path,
    *,
    preferred_size: str,
) -> Optional[Path]:
    sized_url = _ensure_size(url, preferred_size)
    digest = hashlib.sha1(sized_url.encode("utf-8")).hexdigest()
    suffix = Path(urlsplit(sized_url).path).suffix or ".jpg"
    filename = f"{digest}{suffix}"
    target = dest_dir / filename
    if target.exists():
        return target

    try:
        response = session._session.get(sized_url, timeout=session.timeout)
        response.raise_for_status()
    except requests.RequestException as exc:  # pragma: no cover - network conditions
        log.warning("artwork_download_failed", url=sized_url, error=str(exc))
        return None

    target.write_bytes(response.content)
    return target


def _ensure_size(url: str, preferred_size: str) -> str:
    parts = urlsplit(url)
    path = parts.path
    if _SIZE_RE.search(path):
        path = _SIZE_RE.sub(f"/{preferred_size}/", path, count=1)
    elif preferred_size and not path.startswith("/" + preferred_size):
        # Insert the preferred size between the base and filename when the path ends with the image key.
        segments = path.split("/")
        if len(segments) > 2:
            base = "/".join(segments[:-1])
            filename = segments[-1]
            path = "/".join([base, preferred_size, filename])
    rebuilt = parts._replace(path=path)
    return urlunsplit(rebuilt)


__all__ = ["download_artwork"]
