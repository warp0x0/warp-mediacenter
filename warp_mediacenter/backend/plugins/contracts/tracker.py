"""The Tracker plugin contract.

A tracker keeps the user's watch state: what they are part-way through, what they
have finished, and it receives scrobbles as playback starts and stops.  Trakt,
Simkl, Letterboxd and friends all expose roughly this, in wildly different
shapes — normalising them is the whole point of this module.

Catalog rows (trending, discover, popular) are explicitly **not** a tracker's
job, even when the same service offers them.  Those belong to the Catalog
category.  The one exception is Continue Watching, which is watch *state* that
happens to be rendered as a row.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Mapping, Optional

from warp_mediacenter.backend.plugins.contracts.common import MediaRef


class TrackerAction:
    """Action names the host dispatches to a tracker plugin."""

    #: Self-report — capabilities, service name, account shape.
    DESCRIBE = "tracker.describe"

    SCROBBLE_START = "tracker.scrobble.start"
    SCROBBLE_STOP = "tracker.scrobble.stop"
    #: Defined so plugins and future host versions can agree on the name.  The
    #: host does not call these yet: the Flutter client only emits start/stop,
    #: and this pass holds strict behaviour parity.
    SCROBBLE_PAUSE = "tracker.scrobble.pause"
    SCROBBLE_PROGRESS = "tracker.scrobble.progress"

    CONTINUE_WATCHING = "tracker.continue_watching"
    ITEM_PROGRESS = "tracker.item_progress"
    MARK_WATCHED = "tracker.mark_watched"
    REMOVE_FROM_CONTINUE_WATCHING = "tracker.remove_from_continue_watching"

    ACCOUNT = "tracker.account"
    CACHE_CLEAR = "tracker.cache.clear"

    #: Only dispatched when the manifest declares ``auth.kind == "custom"``;
    #: device-code flows are run by the host.
    AUTH_START = "tracker.auth.start"
    AUTH_POLL = "tracker.auth.poll"
    AUTH_STATUS = "tracker.auth.status"
    AUTH_REFRESH = "tracker.auth.refresh"
    AUTH_CLEAR = "tracker.auth.clear"


class TrackerCapability:
    """Capability strings a tracker declares in its manifest.

    The host checks these before dispatching, so a tracker that only scrobbles
    yields an empty Continue Watching row rather than an error.
    """

    SCROBBLE_START = "scrobble.start"
    SCROBBLE_STOP = "scrobble.stop"
    SCROBBLE_PAUSE = "scrobble.pause"
    SCROBBLE_PROGRESS = "scrobble.progress"
    CONTINUE_WATCHING = "continue_watching"
    ITEM_PROGRESS = "item_progress"
    MARK_WATCHED = "mark_watched"
    REMOVE_FROM_CONTINUE_WATCHING = "remove_from_continue_watching"
    ACCOUNT = "account"


#: Action -> capability that must be declared for the host to dispatch it.
ACTION_CAPABILITY: Dict[str, str] = {
    TrackerAction.SCROBBLE_START: TrackerCapability.SCROBBLE_START,
    TrackerAction.SCROBBLE_STOP: TrackerCapability.SCROBBLE_STOP,
    TrackerAction.SCROBBLE_PAUSE: TrackerCapability.SCROBBLE_PAUSE,
    TrackerAction.SCROBBLE_PROGRESS: TrackerCapability.SCROBBLE_PROGRESS,
    TrackerAction.CONTINUE_WATCHING: TrackerCapability.CONTINUE_WATCHING,
    TrackerAction.ITEM_PROGRESS: TrackerCapability.ITEM_PROGRESS,
    TrackerAction.MARK_WATCHED: TrackerCapability.MARK_WATCHED,
    TrackerAction.REMOVE_FROM_CONTINUE_WATCHING: (
        TrackerCapability.REMOVE_FROM_CONTINUE_WATCHING
    ),
    TrackerAction.ACCOUNT: TrackerCapability.ACCOUNT,
}


def _try_float(value: Any) -> Optional[float]:
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _try_int(value: Any) -> Optional[int]:
    if value is None or value == "":
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


@dataclass
class ContinueWatchingItem:
    """One row in the Continue Watching list.

    The field names are chosen to match the ``extra`` keys the Flutter client
    already reads (``widget_section.dart`` checks ``extra['resume_available']``,
    the card widgets read ``extra['progress']``).  That makes the host→UI step a
    dict copy and means adding this whole system requires no client-side change
    to how the row renders.

    ``artwork`` is optional: a tracker that has its own images can supply them and
    the host will skip TMDb enrichment for that item.  Most trackers return ids
    only and let the host fill in the rest.
    """

    media: MediaRef
    progress: float = 0.0
    resume_available: bool = True
    playback_id: Optional[Any] = None
    resume_season: Optional[int] = None
    resume_episode: Optional[int] = None
    resume_playback_id: Optional[Any] = None
    is_scrobbled: bool = False
    last_activity_at: Optional[str] = None
    #: Descending sort key (epoch seconds).  The plugin owns ordering; the host
    #: only truncates to ``limit``.
    sort_key: Optional[float] = None
    artwork: Dict[str, Any] = field(default_factory=dict)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "ContinueWatchingItem":
        if not isinstance(data, Mapping):
            raise ValueError("Continue Watching item must be an object")
        media_raw = data.get("media")
        if not isinstance(media_raw, Mapping):
            raise ValueError("Continue Watching item is missing 'media'")

        artwork = data.get("artwork")
        return cls(
            media=MediaRef.from_dict(media_raw),
            progress=_try_float(data.get("progress")) or 0.0,
            resume_available=bool(data.get("resume_available", True)),
            playback_id=data.get("playback_id"),
            resume_season=_try_int(data.get("resume_season")),
            resume_episode=_try_int(data.get("resume_episode")),
            resume_playback_id=data.get("resume_playback_id"),
            is_scrobbled=bool(data.get("is_scrobbled", False)),
            last_activity_at=(
                str(data["last_activity_at"]) if data.get("last_activity_at") else None
            ),
            sort_key=_try_float(data.get("sort_key")),
            artwork=dict(artwork) if isinstance(artwork, Mapping) else {},
        )

    def extra_fields(self) -> Dict[str, Any]:
        """The ``extra`` block the client reads off a catalog item."""

        extra: Dict[str, Any] = {
            "progress": float(self.progress),
            "resume_available": bool(self.resume_available),
        }
        if self.playback_id is not None:
            extra["playback_id"] = self.playback_id
        if self.resume_season is not None:
            extra["resume_season"] = self.resume_season
        if self.resume_episode is not None:
            extra["resume_episode"] = self.resume_episode
        if self.resume_playback_id is not None:
            extra["resume_playback_id"] = self.resume_playback_id
        if self.is_scrobbled:
            extra["is_scrobbled"] = True
        return extra

    def as_dict(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "media": self.media.as_dict(),
            "progress": float(self.progress),
            "resume_available": bool(self.resume_available),
            "is_scrobbled": bool(self.is_scrobbled),
        }
        for key in (
            "playback_id",
            "resume_season",
            "resume_episode",
            "resume_playback_id",
            "last_activity_at",
            "sort_key",
        ):
            value = getattr(self, key)
            if value is not None:
                payload[key] = value
        if self.artwork:
            payload["artwork"] = dict(self.artwork)
        return payload


def parse_continue_watching(data: Mapping[str, Any]) -> List[ContinueWatchingItem]:
    """Read a ``tracker.continue_watching`` response body.

    A malformed item is skipped rather than failing the whole row — one bad
    entry from an upstream service should not empty the user's home screen.
    """

    raw_items = data.get("items")
    if not isinstance(raw_items, (list, tuple)):
        return []

    items: List[ContinueWatchingItem] = []
    for raw in raw_items:
        try:
            items.append(ContinueWatchingItem.from_dict(raw))
        except (ValueError, TypeError):
            continue
    return items


__all__ = [
    "ACTION_CAPABILITY",
    "ContinueWatchingItem",
    "TrackerAction",
    "TrackerCapability",
    "parse_continue_watching",
]
