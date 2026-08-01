"""Fallback tracker: the built-in Trakt integration.

Until a tracker plugin is installed and enabled, the app's original Trakt code
remains the tracker.  This adapter lets ``TrackerService`` reach it through the
same method names the plugin path uses, so the routes have a single call site.

**It deliberately does not re-shape anything.**  Continue Watching and the
progress endpoints hand back exactly the dicts the existing builders in
``routes/discovery.py`` produce, and scrobbles go straight to ``TraktManager``
with the arguments the old route passed.  Normalising through
``ContinueWatchingItem`` here would risk a subtle behaviour change in the one path
that is currently working, for no benefit — the contract is proved by the plugin
path and its fixture tests instead.

Everything here disappears the day Trakt itself becomes a plugin.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.information_handlers.models import MediaType
from warp_mediacenter.backend.plugins.contracts.common import (
    ErrorCode,
    MediaRef,
    err,
    ok,
)

log = get_logger(__name__)


class LegacyTraktTracker:
    """Adapts the built-in Trakt integration to the tracker facade's shape."""

    id = "builtin-trakt"
    name = "Trakt (built-in)"

    def __init__(self, providers: Any) -> None:
        self._providers = providers

    # -- availability ---------------------------------------------------

    def is_available(self) -> bool:
        """True when built-in Trakt is present and holds a usable token."""

        providers = self._providers
        if providers is None:
            return False
        try:
            return bool(
                providers.trakt_available() and providers.trakt_has_valid_token()
            )
        except Exception:  # noqa: BLE001 - availability must never raise
            return False

    def account(self) -> Dict[str, Any]:
        try:
            profile = self._providers.trakt_profile()
        except Exception as exc:  # noqa: BLE001
            return err(ErrorCode.UPSTREAM_ERROR, str(exc))
        payload = (
            profile.model_dump(mode="json") if hasattr(profile, "model_dump") else profile
        )
        return ok({"account": payload})

    # -- reads (verbatim pass-through) ----------------------------------

    def continue_watching(self, *, media_type: str, limit: int) -> Dict[str, Any]:
        # Imported here rather than at module scope: discovery.py calls into the
        # facade, which would make this a circular import.
        from warp_mediacenter.backend.api.routes.discovery import (  # noqa: PLC0415
            build_trakt_continue_watching,
        )

        return build_trakt_continue_watching(media_type=media_type, limit=limit)

    def movie_progress(self, tmdb_id: str) -> Dict[str, Any]:
        from warp_mediacenter.backend.api.routes.discovery import (  # noqa: PLC0415
            build_trakt_movie_progress,
        )

        return build_trakt_movie_progress(tmdb_id)

    def show_progress(self, tmdb_id: str) -> Dict[str, Any]:
        from warp_mediacenter.backend.api.routes.discovery import (  # noqa: PLC0415
            build_trakt_show_progress,
        )

        return build_trakt_show_progress(tmdb_id)

    # -- writes ---------------------------------------------------------

    def scrobble(
        self, action: str, *, media: MediaRef, progress: float
    ) -> Dict[str, Any]:
        """Send a scrobble, rebuilding the argument shape the manager expects.

        ``TraktManager.scrobble`` wants the episode under ``media`` and the show
        under ``show`` — the inverse of what the client sends.  ``MediaRef``
        already untangled that, so this just projects it back out.
        """

        manager = getattr(self._providers, "trakt", None) or getattr(
            self._providers, "_trakt", None
        )
        if manager is None:
            return err(ErrorCode.NOT_CONFIGURED, "Trakt manager unavailable")

        if media.type == "movie":
            trakt_type = MediaType.MOVIE
            media_payload: Dict[str, Any] = {"ids": dict(media.ids)}
            if media.title:
                media_payload["title"] = media.title
            if media.year is not None:
                media_payload["year"] = media.year
            show_payload = None
        else:
            trakt_type = MediaType.EPISODE
            media_payload = {"season": media.season, "number": media.episode}
            if media.ids:
                media_payload["ids"] = dict(media.ids)
            show_source = media.show or {}
            show_payload = {"ids": dict(show_source.get("ids") or {})}
            if show_source.get("title"):
                show_payload["title"] = show_source["title"]
            if show_source.get("year") is not None:
                show_payload["year"] = show_source["year"]

        from warp_mediacenter.backend.information_handlers.trakt_manager import (  # noqa: PLC0415
            TraktScrobbleConflict,
        )

        try:
            result = manager.scrobble(
                media_type=trakt_type,
                media=media_payload,
                progress=progress,
                action=action,
                show=show_payload,
            )
        except TraktScrobbleConflict as exc:
            return err(
                ErrorCode.CONFLICT,
                "Scrobble already recorded",
                details={
                    "watched_at": exc.watched_at.isoformat() if exc.watched_at else None,
                    "expires_at": exc.expires_at.isoformat() if exc.expires_at else None,
                },
            )
        except Exception as exc:  # noqa: BLE001
            return err(ErrorCode.UPSTREAM_ERROR, str(exc))

        return ok(
            {
                "response": (
                    result.model_dump(mode="json")
                    if hasattr(result, "model_dump")
                    else {}
                )
            }
        )

    def mark_watched(
        self, media: MediaRef, *, watched_at: Optional[str] = None
    ) -> Dict[str, Any]:
        """Add an item to Trakt history.

        Mirrors the payload construction in ``routes/library.py`` so behaviour is
        identical whichever path a caller takes.
        """

        stamp = watched_at or datetime.now(timezone.utc).isoformat().replace(
            "+00:00", "Z"
        )
        tmdb_id = media.tmdb_id
        if tmdb_id is None:
            return err(ErrorCode.INVALID_REQUEST, "mark_watched requires a tmdb id")

        try:
            if media.type == "movie":
                self._providers.trakt_add_to_history(
                    media_type=MediaType.MOVIE,
                    items=[{"watched_at": stamp, "ids": {"tmdb": tmdb_id}}],
                )
            elif media.type == "show":
                self._providers.trakt_add_to_history(
                    media_type=MediaType.SHOW,
                    items=[{"watched_at": stamp, "ids": {"tmdb": tmdb_id}}],
                )
            else:
                self._providers.trakt_add_to_history(
                    media_type=MediaType.SHOW,
                    items=[
                        {
                            "watched_at": stamp,
                            "ids": {"tmdb": tmdb_id},
                            "seasons": [
                                {
                                    "number": media.season,
                                    "episodes": [
                                        {
                                            "number": media.episode,
                                            "watched_at": stamp,
                                        }
                                    ],
                                }
                            ],
                        }
                    ],
                )
        except Exception as exc:  # noqa: BLE001
            return err(ErrorCode.UPSTREAM_ERROR, str(exc))

        return ok({"synced": True})

    def remove_from_continue_watching(
        self, media: MediaRef, *, playback_id: Optional[Any] = None
    ) -> Dict[str, Any]:
        if playback_id is None:
            return err(
                ErrorCode.INVALID_REQUEST,
                "Built-in Trakt needs a playback_id to clear a resume point",
            )
        try:
            removed = self._providers.trakt_delete_playback(playback_id)
        except Exception as exc:  # noqa: BLE001
            return err(ErrorCode.UPSTREAM_ERROR, str(exc))
        return ok({"removed": bool(removed)})


__all__ = ["LegacyTraktTracker"]
