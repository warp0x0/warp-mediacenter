"""Discovery and search routes for Warp MediaCenter API."""

from __future__ import annotations

import random
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock
from typing import Any, Dict, List, Optional, Tuple

from fastapi import APIRouter, HTTPException, Query

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.api.middleware import get_container
from warp_mediacenter.backend.information_handlers.models import MediaType
from warp_mediacenter.backend.information_handlers.providers import InformationProviders
from warp_mediacenter.backend.information_handlers.models import (
    CastMember,
    CrewMember,
    StreamSource,
    SeasonSummary,
)
from warp_mediacenter.backend.persistence import (
    connection as db_connection,
    search_titles,
)

log = get_logger(__name__)

# ---------------------------------------------------------------------------
# Lightweight in-process TTL cache for Trakt API data.
# Trakt calls have no caching in TraktManager._authorized_get, so we layer
# one here at the route level.  Values are plain Python objects — no
# serialization — and the cache is scoped to this process/server lifetime.
# ---------------------------------------------------------------------------
_TTL_PLAYBACK: float = 120.0    # /sync/playback/* — refresh every 2 min
_TTL_WATCHED_LIST: float = 120.0  # /sync/watched/shows
_TTL_SHOW_PROG: float = 300.0   # /shows/{id}/progress/watched — 5 min
_TTL_FULL_RESP: float = 120.0   # entire endpoint response — 2 min

_tcache: Dict[str, Tuple[float, Any]] = {}
_tcache_lock = Lock()


def _tc_get(key: str, ttl: float) -> Optional[Any]:
    """Return cached value if still within TTL, else None."""
    with _tcache_lock:
        entry = _tcache.get(key)
    if entry is not None and (time.monotonic() - entry[0]) < ttl:
        return entry[1]
    return None


def _tc_set(key: str, value: Any) -> None:
    """Store value in cache with current timestamp."""
    with _tcache_lock:
        _tcache[key] = (time.monotonic(), value)


# Max watched-show candidates to fetch progress for in parallel.
# Entries beyond this are unlikely to be needed before we hit `limit` non-completed shows.
_MAX_SHOW_CANDIDATES = 14

search_router = APIRouter()
catalog_router = APIRouter()


def _get_providers() -> InformationProviders:
    """Get InformationProviders from container or create default."""
    container = get_container()
    if container.information_providers is not None:
        return container.information_providers
    return InformationProviders()


def _catalog_item_to_dict(item) -> Dict[str, Any]:
    """Convert a CatalogItem to a dict with UI-friendly fields."""
    if hasattr(item, "model_dump"):
        d = item.model_dump(mode="json")
    else:
        d = dict(item) if hasattr(item, "__iter__") else {}

    extra = d.get("extra", {})
    if isinstance(extra, dict):
        raw = extra.get("raw_payload", {})
        if isinstance(raw, dict):
            if raw.get("poster_path"):
                d["poster_path"] = raw.get("poster_path")
            if raw.get("backdrop_path"):
                d["backdrop_path"] = raw.get("backdrop_path")

    poster = d.get("poster")
    if isinstance(poster, dict):
        if not d.get("poster_path"):
            d["poster_path"] = poster.get("medium") or poster.get("large") or poster.get("original")
        if not d.get("backdrop_path"):
            d["backdrop_path"] = poster.get("original")
    elif isinstance(poster, str) and not d.get("poster_path"):
        d["poster_path"] = poster

    if isinstance(extra, dict):
        ids = extra.get("ids", {})
        raw = extra.get("raw_payload", {})
        if isinstance(ids, dict):
            d["tmdb_id"] = ids.get("tmdb")
            d["trakt_id"] = ids.get("trakt")
        # Fallback: extract tmdb_id from raw_payload.id when ids dict is missing
        if not d.get("tmdb_id") and isinstance(raw, dict) and raw.get("id"):
            d["tmdb_id"] = str(raw.get("id"))
        if not d.get("trakt_id") and isinstance(raw, dict):
            d["trakt_id"] = raw.get("trakt_slug") or raw.get("slug")
        d["media"] = {
            "id": d.get("id"),
            "title": d.get("title"),
            "name": d.get("title"),
            "year": d.get("year"),
            "overview": d.get("overview"),
            "poster_path": d.get("poster_path"),
            "backdrop_path": d.get("backdrop_path"),
            "rating": d.get("rating"),
            "genres": [{"name": g} for g in d.get("genres", [])],
        }

    return d


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
        items = providers.tmdb.catalog_list(mt, category, language=language, page=page)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"TMDb catalog error: {exc}")

    return {
        "category": category,
        "media_type": media_type,
        "page": page,
        "items": [_catalog_item_to_dict(i) for i in items],
        "count": len(items),
    }


def _tmdb_result_to_catalog_item(result: Dict[str, Any], media_type: str) -> Dict[str, Any]:
    """Convert a raw TMDb API result dict to a frontend-compatible catalog item dict."""
    tmdb_id = str(result.get("id") or "")
    title = result.get("title") or result.get("name") or ""
    year: Optional[int] = None
    date_str = result.get("release_date") or result.get("first_air_date") or ""
    if date_str:
        try:
            year = int(str(date_str)[:4])
        except (ValueError, IndexError):
            pass
    return {
        "id": tmdb_id,
        "title": title,
        "type": media_type,
        "year": year,
        "overview": result.get("overview"),
        "poster_path": result.get("poster_path"),
        "backdrop_path": result.get("backdrop_path"),
        "rating": result.get("vote_average"),
        "genres": [],
        "tmdb_id": tmdb_id,
        "trakt_id": None,
        "source_tag": "tmdb",
        "extra": {
            "raw_payload": result,
            "ids": {"tmdb": tmdb_id},
        },
        "media": {
            "id": tmdb_id,
            "title": title,
            "name": title,
            "year": year,
            "overview": result.get("overview"),
            "poster_path": result.get("poster_path"),
            "backdrop_path": result.get("backdrop_path"),
            "rating": result.get("vote_average"),
            "genres": [],
        },
    }


def _enrich_item_with_tmdb_images(
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


def _full_enrich_from_tmdb(
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


# ------------------------------------------------------------------
# Continue Watching — must be registered BEFORE /trakt/{category}
# ------------------------------------------------------------------

@catalog_router.get("/trakt/continue_watching")
async def trakt_continue_watching_catalog(
    media_type: str = Query(default="movie", regex="^(movie|show)$"),
    limit: int = Query(default=20, ge=1, le=50),
) -> Dict[str, Any]:
    """Return a flat Continue Watching catalog enriched with full TMDb metadata.

    Movies: reads /sync/playback/movies (cached 2 min) + parallel TMDb enrichment.
    Shows:  reads /sync/watched/shows (cached 2 min), fetches per-show progress in
            parallel (each cached 5 min), then parallel TMDb enrichment.
            Full response is also cached at the endpoint level for 2 min.
    """
    providers = _get_providers()

    # ── Endpoint-level response cache ──────────────────────────────────────
    resp_key = f"cw:{media_type}:{limit}"
    cached_resp = _tc_get(resp_key, _TTL_FULL_RESP)
    if cached_resp is not None:
        return cached_resp

    items: List[Dict[str, Any]] = []

    if media_type == "movie":
        # ── Movies ─────────────────────────────────────────────────────────
        pb_key = "trakt:pb:movies"
        entries = _tc_get(pb_key, _TTL_PLAYBACK)
        if entries is None:
            try:
                entries = providers.get_trakt_playback_resume(MediaType.MOVIE)
            except Exception as exc:
                raise HTTPException(status_code=500, detail=f"Continue watching (movies) error: {exc}")
            _tc_set(pb_key, entries)

        # Build stub dicts first (cheap, no network)
        stubs: List[Dict[str, Any]] = []
        for entry in entries[:limit]:
            item = _catalog_item_to_dict(entry.media)
            extra = dict(item.get("extra") or {})
            extra["progress"] = float(entry.progress)
            extra["resume_available"] = True
            item["extra"] = extra
            stubs.append(item)

        # Parallel TMDb enrichment — each call is independently cached by TMDbManager
        if stubs:
            with ThreadPoolExecutor(max_workers=min(len(stubs), 6)) as ex:
                futs = [ex.submit(_full_enrich_from_tmdb, s, providers, "movie") for s in stubs]
                for f in as_completed(futs, timeout=30):
                    try:
                        f.result()
                    except Exception:
                        pass  # enrichment is best-effort; stub already has title/year

        items = stubs

    else:
        # ── Shows ──────────────────────────────────────────────────────────
        # Step A: scrobble map (cached) — show_tmdb_id → {progress, season, episode}
        ep_pb_key = "trakt:pb:episodes"
        episode_entries = _tc_get(ep_pb_key, _TTL_PLAYBACK)
        if episode_entries is None:
            try:
                episode_entries = providers.get_trakt_playback_resume(MediaType.EPISODE)
            except Exception:
                episode_entries = []
            _tc_set(ep_pb_key, episode_entries)

        scrobble_map: Dict[str, Dict[str, Any]] = {}
        for pb_entry in episode_entries:
            pb_media = pb_entry.media.model_dump(mode="json")
            pb_extra = pb_media.get("extra") or {}
            pb_raw = pb_extra.get("raw_payload") or {}
            pb_show = pb_raw.get("show") or {}
            pb_show_ids = (pb_show.get("ids") or {}) if isinstance(pb_show, dict) else {}
            pb_tmdb = str(pb_show_ids.get("tmdb") or "")
            pb_ep = pb_raw.get("episode") or {}
            if pb_tmdb and pb_tmdb not in scrobble_map:
                scrobble_map[pb_tmdb] = {
                    "progress": float(pb_entry.progress),
                    "season": pb_ep.get("season") if isinstance(pb_ep, dict) else None,
                    "episode": pb_ep.get("number") if isinstance(pb_ep, dict) else None,
                }

        # Step B: watched shows list (cached)
        ws_key = "trakt:watched_shows"
        watched_shows = _tc_get(ws_key, _TTL_WATCHED_LIST)
        if watched_shows is None:
            try:
                watched_shows = providers.get_trakt_watched_shows()
            except Exception as exc:
                raise HTTPException(status_code=500, detail=f"Trakt watched shows error: {exc}")
            _tc_set(ws_key, watched_shows)

        watched_shows = sorted(
            watched_shows,
            key=lambda x: x.get("last_watched_at") or "",
            reverse=True,
        )

        # Step C: extract candidate (trakt_id, watched_entry) pairs for parallel fetch
        candidates: List[Tuple[str, Any]] = []
        for watched_entry in watched_shows:
            if len(candidates) >= _MAX_SHOW_CANDIDATES:
                break
            show_payload = watched_entry.get("show") or {}
            if not isinstance(show_payload, dict):
                continue
            show_ids = show_payload.get("ids") or {}
            if not isinstance(show_ids, dict):
                continue
            trakt_id = str(show_ids.get("slug") or show_ids.get("trakt") or "")
            show_tmdb_id = str(show_ids.get("tmdb") or "")
            if not trakt_id or not show_tmdb_id:
                continue
            candidates.append((trakt_id, watched_entry))

        # Step D: fetch all show progress IN PARALLEL (each result individually cached)
        def _fetch_progress(trakt_id: str) -> Optional[Any]:
            prog_key = f"show_prog:{trakt_id}"
            cached = _tc_get(prog_key, _TTL_SHOW_PROG)
            if cached is not None:
                return cached
            result = providers.trakt_get_show_watched_progress(trakt_id)
            if result is not None:
                _tc_set(prog_key, result)
            return result

        progress_map: Dict[str, Any] = {}
        if candidates:
            with ThreadPoolExecutor(max_workers=min(len(candidates), 6)) as ex:
                fut_to_id = {ex.submit(_fetch_progress, tid): tid for tid, _ in candidates}
                for fut in as_completed(fut_to_id, timeout=40):
                    tid = fut_to_id[fut]
                    try:
                        result = fut.result()
                        if result:
                            progress_map[tid] = result
                    except Exception:
                        pass

        # Step E: build show stubs from progress results
        show_stubs: List[Dict[str, Any]] = []

        for trakt_id, watched_entry in candidates:
            if len(show_stubs) >= limit:
                break
            prog = progress_map.get(trakt_id)
            if not prog:
                continue

            aired = int(prog.get("aired") or 0)
            completed = int(prog.get("completed") or 0)
            if aired > 0 and completed >= aired:
                continue  # fully watched — skip

            overall_progress = round((completed / aired * 100), 2) if aired > 0 else 0.0

            show_payload = watched_entry.get("show") or {}
            show_ids = show_payload.get("ids") or {}
            show_tmdb_id = str(show_ids.get("tmdb") or "")
            show_title = show_payload.get("title") or ""
            show_year_val = show_payload.get("year")
            show_trakt_id = str(show_ids.get("slug") or show_ids.get("trakt") or "")

            # Determine resume point: scrobbled mid-episode → else first unwatched
            scrobble = scrobble_map.get(show_tmdb_id)
            if scrobble:
                resume_season = scrobble["season"]
                resume_episode = scrobble["episode"]
                is_scrobbled = True
            else:
                resume_season = None
                resume_episode = None
                is_scrobbled = False
                for season_d in (prog.get("seasons") or []):
                    if not isinstance(season_d, dict):
                        continue
                    snum = season_d.get("number", 0)
                    if snum == 0:
                        continue
                    for ep_d in (season_d.get("episodes") or []):
                        if not isinstance(ep_d, dict):
                            continue
                        if not ep_d.get("completed"):
                            resume_season = snum
                            resume_episode = ep_d.get("number")
                            break
                    if resume_season is not None:
                        break

            show_stubs.append({
                "id": show_tmdb_id,
                "title": show_title,
                "type": "show",
                "year": show_year_val,
                "overview": None,
                "poster_path": None,
                "backdrop_path": None,
                "rating": None,
                "genres": [],
                "tmdb_id": show_tmdb_id,
                "trakt_id": show_trakt_id,
                "source_tag": "trakt",
                "extra": {
                    "ids": {
                        "tmdb": show_tmdb_id,
                        "trakt": show_ids.get("trakt"),
                        "slug": show_ids.get("slug"),
                    },
                    "progress": overall_progress,
                    "resume_available": True,
                    "resume_season": int(resume_season) if resume_season is not None else None,
                    "resume_episode": int(resume_episode) if resume_episode is not None else None,
                    "is_scrobbled": is_scrobbled,
                },
                "media": {
                    "id": show_tmdb_id,
                    "title": show_title,
                    "name": show_title,
                    "year": show_year_val,
                    "overview": None,
                    "poster_path": None,
                    "backdrop_path": None,
                    "rating": None,
                    "genres": [],
                },
            })

        # Step F: parallel TMDb enrichment for all show stubs
        if show_stubs:
            with ThreadPoolExecutor(max_workers=min(len(show_stubs), 6)) as ex:
                futs = [ex.submit(_full_enrich_from_tmdb, s, providers, "show") for s in show_stubs]
                for f in as_completed(futs, timeout=30):
                    try:
                        f.result()
                    except Exception:
                        pass

        items = show_stubs

    result: Dict[str, Any] = {
        "category": "continue_watching",
        "media_type": media_type,
        "items": items,
        "count": len(items),
    }
    _tc_set(resp_key, result)
    return result


# ------------------------------------------------------------------
# Based on Recently Watched — must be registered BEFORE /trakt/{category}
# ------------------------------------------------------------------

@catalog_router.get("/trakt/based_on_watched")
async def trakt_based_on_watched_catalog(
    media_type: str = Query(default="movie", regex="^(movie|show)$"),
    limit: int = Query(default=20, ge=1, le=50),
) -> Dict[str, Any]:
    """Return recommendations seeded from recent watch history via TMDb recommendations+similar."""
    providers = _get_providers()
    mt = MediaType.MOVIE if media_type == "movie" else MediaType.SHOW
    seg = "movie" if media_type == "movie" else "tv"

    # Step 1: get recent watch history to use as seeds
    try:
        history = providers.get_trakt_history(mt, limit=30)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Trakt history error: {exc}")

    # Collect unique seed tmdb_ids (top 5 most recent)
    seen_seed_ids: set = set()
    seed_tmdb_ids: List[str] = []
    watched_tmdb_ids: set = set()

    for entry in history:
        media = entry.media
        extra = media.extra if hasattr(media, "extra") and isinstance(media.extra, dict) else {}
        ids = extra.get("ids") or {}
        tmdb_id = str(ids.get("tmdb") or "")
        if not tmdb_id:
            # Try raw_payload
            raw = extra.get("raw_payload") or {}
            tmdb_id = str(raw.get("id") or "")
        if tmdb_id:
            watched_tmdb_ids.add(tmdb_id)
            if tmdb_id not in seen_seed_ids and len(seed_tmdb_ids) < 5:
                seed_tmdb_ids.append(tmdb_id)
                seen_seed_ids.add(tmdb_id)

    if not seed_tmdb_ids:
        return {"category": "based_on_watched", "media_type": media_type, "items": [], "count": 0}

    # Step 2: for each seed, fetch TMDb recommendations + similar
    items: List[Dict[str, Any]] = []
    seen_tmdb_ids: set = set(watched_tmdb_ids)

    for seed_id in seed_tmdb_ids:
        for endpoint in ("recommendations", "similar"):
            try:
                raw = providers.tmdb._request_json(
                    f"/{seg}/{seed_id}/{endpoint}",
                    params={"page": 1, "language": "en-US"},
                )
                for result in (raw.get("results") or [])[:8]:
                    if not isinstance(result, dict):
                        continue
                    tmdb_id = str(result.get("id") or "")
                    if not tmdb_id or tmdb_id in seen_tmdb_ids:
                        continue
                    seen_tmdb_ids.add(tmdb_id)
                    items.append(_tmdb_result_to_catalog_item(result, media_type))
            except Exception:
                continue

    # Shuffle and cap
    random.shuffle(items)
    items = items[:limit]

    return {
        "category": "based_on_watched",
        "media_type": media_type,
        "items": items,
        "count": len(items),
    }


# ------------------------------------------------------------------
# Show watched progress — path has 3 segments, no conflict with /trakt/{category}
# ------------------------------------------------------------------

@catalog_router.get("/trakt/show_progress/{tmdb_id}")
async def trakt_show_progress(tmdb_id: str) -> Dict[str, Any]:
    """Return episode-level watched progress for a show (looked up via Trakt).

    Each episode includes:
    - ``completed``: fully watched (scrobbled to 100% or manually marked)
    - ``scrobble_progress``: 0–100 float if the episode is paused mid-way, else null
    """
    providers = _get_providers()

    # Step 1: resolve TMDb ID → Trakt slug (cheap lookup, no caching needed)
    trakt_slug = providers.trakt_lookup_by_tmdb_id(tmdb_id, MediaType.SHOW)
    if not trakt_slug:
        raise HTTPException(
            status_code=404,
            detail=f"Could not find Trakt entry for TMDb show ID {tmdb_id}",
        )

    # Step 2: fetch watched progress — reuse per-show cache populated by continue_watching
    prog_key = f"show_prog:{trakt_slug}"
    progress = _tc_get(prog_key, _TTL_SHOW_PROG)
    if progress is None:
        try:
            progress = providers.trakt_get_show_watched_progress(trakt_slug)
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"Trakt show progress error: {exc}")
        if progress is not None:
            _tc_set(prog_key, progress)

    if progress is None:
        raise HTTPException(status_code=404, detail="No watched progress found")

    # Step 3: fetch paused/scrobbled episodes — reuse playback cache from continue_watching
    scrobble_ep_map: Dict[tuple, float] = {}
    try:
        ep_entries = _tc_get("trakt:pb:episodes", _TTL_PLAYBACK)
        if ep_entries is None:
            ep_entries = providers.get_trakt_playback_resume(MediaType.EPISODE)
            _tc_set("trakt:pb:episodes", ep_entries)
        for pb in ep_entries:
            pb_media = pb.media.model_dump(mode="json")
            pb_extra = pb_media.get("extra") or {}
            pb_raw = pb_extra.get("raw_payload") or {}
            # Confirm this entry belongs to the right show
            pb_show = pb_raw.get("show") or {}
            pb_show_ids = (pb_show.get("ids") or {}) if isinstance(pb_show, dict) else {}
            pb_show_tmdb = str(pb_show_ids.get("tmdb") or "")
            if pb_show_tmdb != tmdb_id:
                continue
            pb_ep = pb_raw.get("episode") or {}
            if not isinstance(pb_ep, dict):
                continue
            s = pb_ep.get("season")
            e = pb_ep.get("number")
            if s is not None and e is not None:
                scrobble_ep_map[(int(s), int(e))] = float(pb.progress)
    except Exception:
        pass  # scrobble data is best-effort

    # Step 4: normalise: seasons → episodes with completed + scrobble_progress
    seasons_out: List[Dict[str, Any]] = []
    for season in (progress.get("seasons") or []):
        if not isinstance(season, dict):
            continue
        snum = season.get("number")
        episodes_out: List[Dict[str, Any]] = []
        for ep in (season.get("episodes") or []):
            if not isinstance(ep, dict):
                continue
            enum = ep.get("number")
            scrobble_pct: Optional[float] = None
            if snum is not None and enum is not None:
                scrobble_pct = scrobble_ep_map.get((int(snum), int(enum)))
            episodes_out.append({
                "number": enum,
                "completed": bool(ep.get("completed", False)),
                "last_watched_at": ep.get("last_watched_at"),
                "scrobble_progress": scrobble_pct,
            })
        seasons_out.append({
            "number": snum,
            "aired": season.get("aired"),
            "completed": season.get("completed"),
            "episodes": episodes_out,
        })

    return {
        "trakt_id": trakt_slug,
        "tmdb_id": tmdb_id,
        "aired": progress.get("aired"),
        "completed": progress.get("completed"),
        "seasons": seasons_out,
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


# ------------------------------------------------------------------
# Detail routes (with credits + trailers)
# ------------------------------------------------------------------

def _credits_to_dict(credits) -> Dict[str, Any]:
    """Serialize Credits model for API response."""
    if credits is None:
        return {"cast": [], "crew": []}
    if hasattr(credits, "model_dump"):
        return credits.model_dump(mode="json")
    return {"cast": [], "crew": []}


def _trailer_to_dict(trailer: StreamSource) -> Dict[str, Any]:
    return trailer.model_dump(mode="json")


@catalog_router.get("/detail/movie/{movie_id}")
async def movie_detail(
    movie_id: str,
    language: Optional[str] = Query(default=None),
) -> Dict[str, Any]:
    """Get full movie detail with credits and trailers from TMDb."""
    providers = _get_providers()

    try:
        movie = providers.movie_details(movie_id, language=language, include_credits=True)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Movie detail error: {exc}")

    trailers: list = []
    try:
        trailers = [_trailer_to_dict(t) for t in providers.movie_trailers(movie_id, language=language)]
    except Exception:
        pass

    result = movie.model_dump(mode="json")
    result["credits"] = _credits_to_dict(movie.credits)
    result["trailers"] = trailers
    result["imdb_id"] = (result.get("external_ids") or {}).get("imdb_id")

    return result


@catalog_router.get("/detail/show/{show_id}")
async def show_detail(
    show_id: str,
    language: Optional[str] = Query(default=None),
) -> Dict[str, Any]:
    """Get full show detail with credits, trailers, and seasons from TMDb."""
    providers = _get_providers()

    try:
        show = providers.show_details(show_id, language=language, include_credits=True)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Show detail error: {exc}")

    trailers: list = []
    try:
        trailers = [_trailer_to_dict(t) for t in providers.show_trailers(show_id, language=language)]
    except Exception:
        pass

    result = show.model_dump(mode="json")
    result["credits"] = _credits_to_dict(show.credits)
    result["trailers"] = trailers
    result["imdb_id"] = (result.get("external_ids") or {}).get("imdb_id")

    return result


@catalog_router.get("/show/{show_id}/seasons")
async def show_seasons(
    show_id: str,
    language: Optional[str] = Query(default=None),
) -> Dict[str, Any]:
    """Get all seasons with episode data for a show from TMDb."""
    providers = _get_providers()

    try:
        show = providers.show_details(show_id, language=language, include_credits=False)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Show detail error: {exc}")

    seasons_data: list = []
    if show.seasons:
        for s in show.seasons:
            sd = s.model_dump(mode="json")
            episodes: list = []
            try:
                season_detail = providers.season_details(show_id, s.season_number, language=language)
                for ep in season_detail.episodes:
                    episodes.append(ep.model_dump(mode="json"))
            except Exception:
                pass
            sd["episodes"] = episodes
            seasons_data.append(sd)

    return {
        "show_id": show_id,
        "title": show.title,
        "seasons_count": len(seasons_data),
        "seasons": seasons_data,
    }


@catalog_router.get("/imdb-rating/{imdb_id}")
async def get_imdb_rating(imdb_id: str) -> Dict[str, Any]:
    """Proxy IMDB rating from imdbapi.dev (free, no key required)."""
    import aiohttp
    url = f"https://api.imdbapi.dev/titles/{imdb_id}"
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(url, timeout=aiohttp.ClientTimeout(total=5)) as resp:
                if resp.status != 200:
                    return {"imdb_id": imdb_id, "rating": None, "vote_count": None}
                data = await resp.json(content_type=None)
                rating_data = data.get("rating") or {}
                return {
                    "imdb_id": imdb_id,
                    "rating": rating_data.get("aggregateRating"),
                    "vote_count": rating_data.get("voteCount"),
                }
    except Exception:
        return {"imdb_id": imdb_id, "rating": None, "vote_count": None}


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


# ------------------------------------------------------------------
# Watch providers route
# ------------------------------------------------------------------

@catalog_router.get("/detail/movie/{movie_id}/providers")
async def movie_watch_providers(movie_id: str) -> Dict[str, Any]:
    """Get watch/providers for a movie (flatrate, rent, buy)."""
    providers = _get_providers()
    try:
        payload = providers.tmdb._request_json(f"/movie/{movie_id}/watch/providers")
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Watch providers error: {exc}")

    results = payload.get("results", {})
    sg = results.get("SG", results.get("US", {}))
    flatrate = sg.get("flatrate", [])
    rent = sg.get("rent", [])
    buy = sg.get("buy", [])

    def _provider_dict(p):
        return {
            "provider_id": p.get("provider_id"),
            "provider_name": p.get("provider_name"),
            "logo_path": p.get("logo_path"),
        }

    return {
        "movie_id": movie_id,
        "streaming": [_provider_dict(p) for p in flatrate],
        "rent": [_provider_dict(p) for p in rent],
        "buy": [_provider_dict(p) for p in buy],
    }


@catalog_router.get("/detail/show/{show_id}/providers")
async def show_watch_providers(show_id: str) -> Dict[str, Any]:
    """Get watch/providers for a TV show (flatrate, rent, buy)."""
    providers = _get_providers()
    try:
        payload = providers.tmdb._request_json(f"/tv/{show_id}/watch/providers")
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Watch providers error: {exc}")

    results = payload.get("results", {})
    sg = results.get("SG", results.get("US", {}))
    flatrate = sg.get("flatrate", [])
    rent = sg.get("rent", [])
    buy = sg.get("buy", [])

    def _provider_dict(p):
        return {
            "provider_id": p.get("provider_id"),
            "provider_name": p.get("provider_name"),
            "logo_path": p.get("logo_path"),
        }

    return {
        "show_id": show_id,
        "streaming": [_provider_dict(p) for p in flatrate],
        "rent": [_provider_dict(p) for p in rent],
        "buy": [_provider_dict(p) for p in buy],
    }
