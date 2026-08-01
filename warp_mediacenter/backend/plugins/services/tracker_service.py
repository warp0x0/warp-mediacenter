"""The tracker facade.

One call site for every route that needs watch state, dispatching three ways:

1. **A tracker plugin is enabled** — normalised through the contract, with the
   host filling in artwork and metadata from TMDb.
2. **No plugin, built-in Trakt authenticated** — the original code path, passed
   through untouched.  This is the default today and must stay byte-identical.
3. **Neither** — degrade quietly.  Scrobbles are skipped, Continue Watching comes
   back empty, and nothing raises.  A user with no tracker configured should see
   an app that simply has no Continue Watching row, not an error.

The third case matters more than it looks: it is the state every new install
starts in, and the state you land in the moment you toggle a tracker off.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.information_handlers.enrichment import enrich_many
from warp_mediacenter.backend.plugins.contracts.common import (
    CATEGORY_TRACKER,
    ErrorCode,
    MediaRef,
    err,
    error_code,
    is_ok,
    ok,
    response_data,
)
from warp_mediacenter.backend.plugins.contracts.tracker import (
    ACTION_CAPABILITY,
    ContinueWatchingItem,
    TrackerAction,
    TrackerCapability,
    parse_continue_watching,
)
from warp_mediacenter.backend.plugins.manager import FAST_CALL_TIMEOUT, PluginManager
from warp_mediacenter.backend.plugins.registry import PluginRecord, PluginRegistry
from warp_mediacenter.backend.plugins.services.legacy_trakt import LegacyTraktTracker
from warp_mediacenter.backend.plugins.services.tracker_cache import (
    TTL_CONTINUE_WATCHING,
    TTL_ITEM_PROGRESS,
    TrackerCache,
)

log = get_logger(__name__)

MODE_PLUGIN = "plugin"
MODE_LEGACY = "legacy"
MODE_NONE = "none"


class TrackerService:
    def __init__(
        self,
        *,
        manager: PluginManager,
        registry: PluginRegistry,
        providers: Any = None,
        cache: Optional[TrackerCache] = None,
        legacy: Optional[LegacyTraktTracker] = None,
    ) -> None:
        self._manager = manager
        self._registry = registry
        self._providers = providers
        self._cache = cache or TrackerCache()
        self._legacy = legacy or LegacyTraktTracker(providers)
        #: Counts scrobbles that failed after reaching a tracker.  The client
        #: swallows scrobble errors by design, so without this a broken tracker
        #: is completely invisible; /health surfaces it.
        self._scrobble_failures = 0

    # ------------------------------------------------------------------
    # Resolution
    # ------------------------------------------------------------------

    @property
    def active_plugin(self) -> Optional[PluginRecord]:
        return self._registry.active_for_category(CATEGORY_TRACKER)

    @property
    def active_plugin_id(self) -> Optional[str]:
        record = self.active_plugin
        return record.plugin_id if record else None

    @property
    def mode(self) -> str:
        if self.active_plugin is not None:
            return MODE_PLUGIN
        if self._legacy.is_available():
            return MODE_LEGACY
        return MODE_NONE

    def describe(self) -> Dict[str, Any]:
        record = self.active_plugin
        if record is not None:
            return {
                "mode": MODE_PLUGIN,
                "plugin_id": record.plugin_id,
                "name": record.name,
                "version": record.version,
                "capabilities": list(record.manifest.capabilities),
            }
        if self._legacy.is_available():
            return {
                "mode": MODE_LEGACY,
                "plugin_id": None,
                "name": self._legacy.name,
                "capabilities": [
                    TrackerCapability.SCROBBLE_START,
                    TrackerCapability.SCROBBLE_STOP,
                    TrackerCapability.CONTINUE_WATCHING,
                    TrackerCapability.ITEM_PROGRESS,
                    TrackerCapability.MARK_WATCHED,
                    TrackerCapability.REMOVE_FROM_CONTINUE_WATCHING,
                ],
            }
        return {"mode": MODE_NONE, "plugin_id": None, "name": None, "capabilities": []}

    def health(self) -> Dict[str, Any]:
        record = self.active_plugin
        return {
            "mode": self.mode,
            "active_plugin_id": record.plugin_id if record else None,
            "scrobble_failures": self._scrobble_failures,
            "cache": self._cache.stats(),
        }

    # ------------------------------------------------------------------
    # Plugin dispatch
    # ------------------------------------------------------------------

    def _invoke(
        self,
        record: PluginRecord,
        action: str,
        payload: Optional[Dict[str, Any]] = None,
        *,
        timeout: Optional[float] = None,
    ) -> Dict[str, Any]:
        """Dispatch to the active plugin, gated on its declared capabilities."""

        capability = ACTION_CAPABILITY.get(action)
        if capability is not None and not record.supports(capability):
            return err(
                ErrorCode.UNSUPPORTED_ACTION,
                f"Plugin '{record.plugin_id}' does not declare '{capability}'",
            )
        return self._manager.execute(
            record.plugin_id, action, payload or {}, timeout=timeout
        )

    # ------------------------------------------------------------------
    # Scrobbling
    # ------------------------------------------------------------------

    def scrobble(
        self,
        action: str,
        *,
        media: MediaRef,
        progress: float,
        session_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Report playback start/stop.

        Runs on a tight timeout: this sits in the playback-exit path, and a slow
        tracker must never be the reason leaving a video feels sluggish.
        """

        if action not in {"start", "stop", "pause"}:
            return err(ErrorCode.INVALID_REQUEST, f"Unknown scrobble action '{action}'")

        record = self.active_plugin
        if record is not None:
            plugin_action = {
                "start": TrackerAction.SCROBBLE_START,
                "stop": TrackerAction.SCROBBLE_STOP,
                "pause": TrackerAction.SCROBBLE_PAUSE,
            }[action]
            result = self._invoke(
                record,
                plugin_action,
                {
                    "media": media.as_dict(),
                    "progress": float(progress),
                    "session_id": session_id,
                },
                timeout=FAST_CALL_TIMEOUT,
            )
        elif self._legacy.is_available():
            result = self._legacy.scrobble(action, media=media, progress=progress)
        else:
            return ok({"skipped": True, "reason": "no_tracker", "tracker": None})

        if not is_ok(result) and error_code(result) not in {ErrorCode.CONFLICT}:
            self._scrobble_failures += 1
            log.warning(
                "tracker_scrobble_failed",
                action=action,
                mode=self.mode,
                error=error_code(result),
            )

        # A stop makes every cached resume point stale.
        if action == "stop":
            self.invalidate()

        return result

    # ------------------------------------------------------------------
    # Continue Watching
    # ------------------------------------------------------------------

    def continue_watching(
        self, *, media_type: str = "movie", limit: int = 20
    ) -> Dict[str, Any]:
        record = self.active_plugin

        if record is None:
            if self._legacy.is_available():
                return self._legacy.continue_watching(
                    media_type=media_type, limit=limit
                )
            return {
                "category": "continue_watching",
                "media_type": media_type,
                "items": [],
                "count": 0,
            }

        cache_key = TrackerCache.cw_key(record.plugin_id, media_type, limit)
        cached = self._cache.get(cache_key, TTL_CONTINUE_WATCHING)
        if cached is not None:
            return cached

        result = self._invoke(
            record,
            TrackerAction.CONTINUE_WATCHING,
            {"media_type": media_type, "limit": limit},
        )
        if not is_ok(result):
            # An empty row is a better outcome than a broken home screen.
            log.warning(
                "tracker_continue_watching_failed",
                plugin_id=record.plugin_id,
                error=error_code(result),
            )
            return {
                "category": "continue_watching",
                "media_type": media_type,
                "items": [],
                "count": 0,
                "error": error_code(result),
            }

        items = parse_continue_watching(response_data(result))
        items.sort(key=lambda item: item.sort_key or 0.0, reverse=True)
        items = items[:limit]

        dicts = [self._cw_item_to_catalog_dict(item, media_type) for item in items]
        needs_enrichment = [
            payload
            for payload, item in zip(dicts, items)
            if not item.artwork.get("poster")
        ]
        if needs_enrichment and self._providers is not None:
            # Continue Watching is the first row on the home screen, so it gets a
            # tighter budget than the catalog routes.  With a working TMDb key
            # this finishes in well under a second; when TMDb is unconfigured or
            # unreachable, returning un-enriched items (which still render, just
            # without artwork) beats making the user stare at an empty screen.
            enrich_many(
                needs_enrichment, self._providers, media_type, timeout=12.0
            )

        response = {
            "category": "continue_watching",
            "media_type": media_type,
            "items": dicts,
            "count": len(dicts),
            "tracker": record.plugin_id,
        }
        self._cache.set(cache_key, response)
        return response

    def _cw_item_to_catalog_dict(
        self, item: ContinueWatchingItem, media_type: str
    ) -> Dict[str, Any]:
        """Project a contract item onto the catalog dict the client renders.

        Shape matches what the Trakt Continue Watching route has always emitted,
        including the duplicated nested ``media`` block the frontend reads — the
        point of the contract is that no client change is needed.
        """

        media = item.media
        ids = media.show_ids if media.type == "episode" else dict(media.ids)
        tmdb_id = ids.get("tmdb")
        title = media.title or (media.show or {}).get("title") or ""
        year = media.year if media.year is not None else (media.show or {}).get("year")

        payload: Dict[str, Any] = {
            "id": str(tmdb_id) if tmdb_id is not None else None,
            "title": title,
            "type": media_type,
            "source_tag": "tracker",
            "year": year,
            "overview": None,
            "poster_path": item.artwork.get("poster"),
            "backdrop_path": item.artwork.get("backdrop"),
            "rating": None,
            "genres": [],
            "tmdb_id": str(tmdb_id) if tmdb_id is not None else None,
            "trakt_id": ids.get("trakt") or ids.get("slug"),
            "extra": {**item.extra_fields(), "ids": {k: str(v) for k, v in ids.items()}},
        }
        payload["media"] = {
            "id": payload["id"],
            "title": title,
            "name": title,
            "year": year,
            "overview": None,
            "poster_path": payload["poster_path"],
            "backdrop_path": payload["backdrop_path"],
            "rating": None,
            "genres": [],
        }
        return payload

    # ------------------------------------------------------------------
    # Per-item progress
    # ------------------------------------------------------------------

    def movie_progress(self, tmdb_id: str) -> Dict[str, Any]:
        record = self.active_plugin
        if record is None:
            if self._legacy.is_available():
                return self._legacy.movie_progress(tmdb_id)
            return {"progress": 0.0, "resume_available": False}

        cache_key = TrackerCache.progress_key(record.plugin_id, "movie", str(tmdb_id))
        cached = self._cache.get(cache_key, TTL_ITEM_PROGRESS)
        if cached is not None:
            return cached

        result = self._invoke(
            record,
            TrackerAction.ITEM_PROGRESS,
            {"media": {"type": "movie", "ids": {"tmdb": int(tmdb_id)}}},
        )
        if not is_ok(result):
            return {"progress": 0.0, "resume_available": False}

        data = response_data(result)
        response = {
            "progress": float(data.get("progress") or 0.0),
            "resume_available": bool(data.get("resume_available", False)),
        }
        if data.get("playback_id") is not None:
            response["playback_id"] = data["playback_id"]
        self._cache.set(cache_key, response)
        return response

    def show_progress(self, tmdb_id: str) -> Dict[str, Any]:
        """Episode-level watched progress.

        Raises 404 when unavailable rather than returning an empty grid — the
        client already treats a failed fetch as "no progress known", and an empty
        grid would render as "nothing watched", which is a different claim.
        """

        from fastapi import HTTPException  # noqa: PLC0415 - keep this module import-light

        record = self.active_plugin
        if record is None:
            if self._legacy.is_available():
                return self._legacy.show_progress(tmdb_id)
            raise HTTPException(status_code=404, detail="No tracker configured")

        cache_key = TrackerCache.progress_key(record.plugin_id, "show", str(tmdb_id))
        cached = self._cache.get(cache_key, TTL_ITEM_PROGRESS)
        if cached is not None:
            return cached

        result = self._invoke(
            record,
            TrackerAction.ITEM_PROGRESS,
            {"media": {"type": "show", "ids": {"tmdb": int(tmdb_id)}}},
        )
        if not is_ok(result):
            raise HTTPException(
                status_code=404,
                detail=f"No watched progress found ({error_code(result)})",
            )

        data = response_data(result)
        response = {
            "trakt_id": data.get("trakt_id"),
            "tmdb_id": str(tmdb_id),
            "aired": data.get("aired"),
            "completed": data.get("completed"),
            "seasons": data.get("seasons") or [],
        }
        self._cache.set(cache_key, response)
        return response

    # ------------------------------------------------------------------
    # History
    # ------------------------------------------------------------------

    def mark_watched(
        self, media: MediaRef, *, watched_at: Optional[str] = None
    ) -> Dict[str, Any]:
        record = self.active_plugin
        if record is not None:
            result = self._invoke(
                record,
                TrackerAction.MARK_WATCHED,
                {"media": media.as_dict(), "watched_at": watched_at},
            )
        elif self._legacy.is_available():
            result = self._legacy.mark_watched(media, watched_at=watched_at)
        else:
            # The caller still records this locally; only the remote sync is skipped.
            return ok({"skipped": True, "reason": "no_tracker"})

        self.invalidate()
        return result

    def remove_from_continue_watching(
        self, media: MediaRef, *, playback_id: Optional[Any] = None
    ) -> Dict[str, Any]:
        record = self.active_plugin
        if record is not None:
            result = self._invoke(
                record,
                TrackerAction.REMOVE_FROM_CONTINUE_WATCHING,
                {"media": media.as_dict(), "playback_id": playback_id},
            )
        elif self._legacy.is_available():
            result = self._legacy.remove_from_continue_watching(
                media, playback_id=playback_id
            )
        else:
            return ok({"skipped": True, "reason": "no_tracker"})

        self.invalidate()
        return result

    # ------------------------------------------------------------------
    # Cache
    # ------------------------------------------------------------------

    def invalidate(self, *, scope: str = "all") -> None:
        """Drop cached watch state after something changed it."""

        record = self.active_plugin
        if record is not None:
            if scope == "all":
                self._cache.drop_plugin(record.plugin_id)
            else:
                self._cache.drop_scope(record.plugin_id, scope)
            if record.supports(TrackerCapability.CONTINUE_WATCHING):
                self._manager.execute(
                    record.plugin_id,
                    TrackerAction.CACHE_CLEAR,
                    {"scope": scope},
                    timeout=FAST_CALL_TIMEOUT,
                )
            return

        # Legacy path keeps its caches inside discovery.py.
        from warp_mediacenter.backend.api.routes.discovery import (  # noqa: PLC0415
            invalidate_trakt_continue_watching_caches,
        )

        try:
            invalidate_trakt_continue_watching_caches()
        except Exception:  # noqa: BLE001 - cache eviction is best-effort
            pass

    def on_active_changed(self, previous_plugin_id: Optional[str]) -> None:
        """Called after the enabled tracker changes."""

        if previous_plugin_id:
            self._cache.drop_plugin(previous_plugin_id)
        self._cache.clear()


__all__ = ["MODE_LEGACY", "MODE_NONE", "MODE_PLUGIN", "TrackerService"]
