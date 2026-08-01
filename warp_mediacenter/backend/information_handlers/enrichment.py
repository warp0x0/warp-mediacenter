"""TMDb enrichment for items that arrive carrying little more than an id.

Trackers return watch *state*.  A Trakt or Simkl playback entry has a title, a
year and a handful of ids — no artwork, no overview, no genres — which is not
enough to draw a card.

Enrichment stays on the host side rather than inside each tracker plugin, for
three reasons: the app already owns the TMDb key and its response cache; every
tracker would otherwise reimplement this and need its own key; and doing it here
means a plugin that can only produce ids still yields a fully-rendered row.  That
last property is what makes adding a new tracker cheap.

Extracted verbatim from ``api/routes/discovery.py`` so the catalog routes and the
tracker facade share one implementation; ``discovery.py`` imports these back
under their original names.
"""

from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor, wait
from typing import TYPE_CHECKING, Any, Dict, List, Sequence

from warp_mediacenter.backend.common.logging import get_logger

if TYPE_CHECKING:  # pragma: no cover
    from warp_mediacenter.backend.information_handlers.providers import (
        InformationProviders,
    )

log = get_logger(__name__)

#: Matches the fan-out the Continue Watching route has always used.
MAX_ENRICH_WORKERS = 6
ENRICH_TIMEOUT_SECONDS = 30.0


def enrich_item_with_tmdb_images(
    item: Dict[str, Any],
    providers: "InformationProviders",
    media_type: str,
) -> None:
    """Fetch poster/backdrop from TMDb if the item is missing them (mutates item in place)."""
    tmdb_id = item.get("tmdb_id")
    if not tmdb_id:
        return
    if item.get("poster_path") and item.get("backdrop_path"):
        return
    try:
        seg = "movie" if media_type == "movie" else "tv"
        raw = providers.tmdb._request_json(f"/{seg}/{tmdb_id}")
        if not item.get("poster_path") and raw.get("poster_path"):
            item["poster_path"] = raw["poster_path"]
            if isinstance(item.get("media"), dict):
                item["media"]["poster_path"] = raw["poster_path"]
        if not item.get("backdrop_path") and raw.get("backdrop_path"):
            item["backdrop_path"] = raw["backdrop_path"]
            if isinstance(item.get("media"), dict):
                item["media"]["backdrop_path"] = raw["backdrop_path"]
    except Exception:
        pass


def full_enrich_from_tmdb(
    item: Dict[str, Any],
    providers: "InformationProviders",
    media_type: str,
) -> None:
    """Fetch full TMDb metadata and populate ALL missing fields (mutates item in place).

    Trakt playback entries only carry title+year+ids.  This fills overview,
    poster_path, backdrop_path, genres, rating, and year from the TMDb record
    so the frontend has everything it needs to render the card.
    """
    tmdb_id = item.get("tmdb_id")
    if not tmdb_id:
        return
    try:
        seg = "movie" if media_type == "movie" else "tv"
        raw = providers.tmdb._request_json(f"/{seg}/{tmdb_id}")

        # Images (always update — TMDb is authoritative)
        if raw.get("poster_path"):
            item["poster_path"] = raw["poster_path"]
        if raw.get("backdrop_path"):
            item["backdrop_path"] = raw["backdrop_path"]

        # Textual metadata (fill gaps; Trakt payload has almost nothing)
        if raw.get("overview"):
            item["overview"] = raw["overview"]
        if raw.get("vote_average") is not None:
            item["rating"] = float(raw["vote_average"])
        if not item.get("year"):
            date_str = raw.get("release_date") or raw.get("first_air_date") or ""
            if date_str:
                try:
                    item["year"] = int(str(date_str)[:4])
                except (ValueError, IndexError):
                    pass
        if raw.get("genres"):
            item["genres"] = [g["name"] for g in raw["genres"] if g.get("name")]

        # Mirror into the nested `media` dict used by the frontend
        media = item.get("media")
        if isinstance(media, dict):
            if raw.get("poster_path"):
                media["poster_path"] = raw["poster_path"]
            if raw.get("backdrop_path"):
                media["backdrop_path"] = raw["backdrop_path"]
            if raw.get("overview"):
                media["overview"] = raw["overview"]
            if raw.get("vote_average") is not None:
                media["rating"] = float(raw["vote_average"])
            if raw.get("genres"):
                media["genres"] = [{"name": g["name"]} for g in raw["genres"] if g.get("name")]

    except Exception:
        pass


def enrich_many(
    items: Sequence[Dict[str, Any]],
    providers: "InformationProviders",
    media_type: str,
    *,
    timeout: float = ENRICH_TIMEOUT_SECONDS,
    max_workers: int = MAX_ENRICH_WORKERS,
) -> List[Dict[str, Any]]:
    """Enrich a batch in parallel, mutating in place and returning the same list.

    Each TMDb call is independently cached by ``TMDbManager``, so a warm cache
    makes this nearly free.  Failures are swallowed per item — a missing poster
    is not a reason to fail the row.

    ``timeout`` is a real wall-clock budget for the whole batch.  The executor is
    shut down without waiting once it expires, so slow or unreachable TMDb calls
    finish in the background and the row renders with whatever came back in time.
    Using ``with ThreadPoolExecutor(...)`` here would defeat that: its ``__exit__``
    joins every worker regardless of any per-future timeout, which is exactly how
    an unconfigured or unreachable TMDb turns into a minutes-long request.
    """

    pending = [item for item in items if item.get("tmdb_id")]
    if not pending:
        return list(items)

    workers = max(1, min(len(pending), max_workers))
    pool = ThreadPoolExecutor(max_workers=workers, thread_name_prefix="tmdb-enrich")
    try:
        futures = [
            pool.submit(full_enrich_from_tmdb, item, providers, media_type)
            for item in pending
        ]
        done, not_done = wait(futures, timeout=timeout)
        if not_done:
            log.warning(
                "tmdb_enrichment_timeout",
                pending=len(not_done),
                total=len(futures),
                timeout=timeout,
            )
        for future in done:
            try:
                future.result()
            except Exception:  # noqa: BLE001 - a missing poster is not fatal
                continue
    except Exception as exc:  # noqa: BLE001
        log.warning("tmdb_enrichment_failed", error=str(exc), count=len(pending))
    finally:
        pool.shutdown(wait=False)

    return list(items)


__all__ = [
    "ENRICH_TIMEOUT_SECONDS",
    "MAX_ENRICH_WORKERS",
    "enrich_item_with_tmdb_images",
    "enrich_many",
    "full_enrich_from_tmdb",
]
