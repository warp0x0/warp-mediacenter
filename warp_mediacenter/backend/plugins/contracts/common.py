"""Types shared by every plugin category.

Everything in this module crosses the host/plugin boundary, so it is deliberately
built out of plain JSON-compatible structures.  Plugins never see ``CatalogItem``,
``MediaType``, Pydantic models, or any other host-internal type — if a value is
not expressible as JSON it does not belong here.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Mapping, Optional

# ---------------------------------------------------------------------------
# Categories
# ---------------------------------------------------------------------------

CATEGORY_TRACKER = "tracker"
CATEGORY_PROVIDER = "provider"
CATEGORY_CATALOG = "catalog"
CATEGORY_SKIN = "skin"


@dataclass(frozen=True)
class PluginCategory:
    id: str
    label: str
    description: str
    #: Whether enabling one plugin in this category disables the others.
    exclusive: bool

    def as_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "label": self.label,
            "description": self.description,
            "exclusive": self.exclusive,
        }


#: Ordered — the Settings UI renders category groups in this order.
PLUGIN_CATEGORIES: tuple[PluginCategory, ...] = (
    PluginCategory(
        id=CATEGORY_TRACKER,
        label="Trackers",
        description="Sync watch history, scrobbling and Continue Watching.",
        exclusive=True,
    ),
    PluginCategory(
        id=CATEGORY_PROVIDER,
        label="Providers",
        description="Source and resolve playable streams.",
        exclusive=False,
    ),
    PluginCategory(
        id=CATEGORY_CATALOG,
        label="Catalogs",
        description="Browse rows, discovery lists and search results.",
        exclusive=False,
    ),
    PluginCategory(
        id=CATEGORY_SKIN,
        label="Skins",
        description="Themes and visual styling.",
        exclusive=True,
    ),
)

_CATEGORIES_BY_ID = {category.id: category for category in PLUGIN_CATEGORIES}


def get_category(category_id: str) -> Optional[PluginCategory]:
    return _CATEGORIES_BY_ID.get(str(category_id or "").strip().lower())


def is_exclusive_category(category_id: str) -> bool:
    category = get_category(category_id)
    return bool(category and category.exclusive)


def known_category_ids() -> tuple[str, ...]:
    return tuple(category.id for category in PLUGIN_CATEGORIES)


# ---------------------------------------------------------------------------
# Response envelope
# ---------------------------------------------------------------------------


class ErrorCode:
    """Error codes a plugin may return, and the host maps onto HTTP status."""

    INVALID_REQUEST = "invalid_request"
    UNSUPPORTED_ACTION = "unsupported_action"
    NOT_CONFIGURED = "not_configured"
    NOT_AUTHENTICATED = "not_authenticated"
    REAUTH_REQUIRED = "reauth_required"
    CONFLICT = "conflict"
    RATE_LIMITED = "rate_limited"
    NOT_FOUND = "not_found"
    UPSTREAM_ERROR = "upstream_error"
    INTERNAL_ERROR = "internal_error"


#: Error code -> HTTP status.  Routes that need different handling for a code
#: (scrobble treats ``not_authenticated`` as a skip, not a failure) override it
#: locally rather than changing this table.
ERROR_HTTP_STATUS: Dict[str, int] = {
    ErrorCode.INVALID_REQUEST: 400,
    ErrorCode.UNSUPPORTED_ACTION: 501,
    ErrorCode.NOT_CONFIGURED: 409,
    ErrorCode.NOT_AUTHENTICATED: 401,
    ErrorCode.REAUTH_REQUIRED: 401,
    ErrorCode.CONFLICT: 200,
    ErrorCode.RATE_LIMITED: 429,
    ErrorCode.NOT_FOUND: 404,
    ErrorCode.UPSTREAM_ERROR: 502,
    ErrorCode.INTERNAL_ERROR: 500,
}


def ok(data: Optional[Mapping[str, Any]] = None, **extra: Any) -> Dict[str, Any]:
    """Build a success envelope."""

    payload: Dict[str, Any] = {"ok": True, "data": dict(data or {})}
    if extra:
        payload["data"].update(extra)
    return payload


def err(
    code: str,
    message: str = "",
    *,
    retry_after: Optional[float] = None,
    details: Optional[Mapping[str, Any]] = None,
) -> Dict[str, Any]:
    """Build a failure envelope."""

    return {
        "ok": False,
        "error": {
            "code": code,
            "message": message or code,
            "retry_after": retry_after,
            "details": dict(details or {}),
        },
    }


def is_ok(response: Any) -> bool:
    return isinstance(response, Mapping) and bool(response.get("ok"))


def error_code(response: Any) -> Optional[str]:
    if not isinstance(response, Mapping):
        return None
    error = response.get("error")
    if not isinstance(error, Mapping):
        return None
    code = error.get("code")
    return str(code) if code else None


def response_data(response: Any) -> Dict[str, Any]:
    if not isinstance(response, Mapping):
        return {}
    data = response.get("data")
    return dict(data) if isinstance(data, Mapping) else {}


# ---------------------------------------------------------------------------
# MediaRef
# ---------------------------------------------------------------------------

#: Id keys carried in ``MediaRef.ids``.  ``tmdb``/``trakt``/``tvdb``/``simkl`` are
#: ints when known; ``imdb``/``slug`` are strings.  Absent keys are omitted rather
#: than set to null, so a plugin can use plain ``"tmdb" in ids`` checks.
_INT_ID_KEYS = ("tmdb", "trakt", "tvdb", "simkl", "tvrage")
_STR_ID_KEYS = ("imdb", "slug")


def _clean_ids(raw: Any) -> Dict[str, Any]:
    if not isinstance(raw, Mapping):
        return {}
    ids: Dict[str, Any] = {}
    for key in _INT_ID_KEYS:
        value = raw.get(key)
        if value is None or value == "":
            continue
        try:
            ids[key] = int(value)
        except (TypeError, ValueError):
            continue
    for key in _STR_ID_KEYS:
        value = raw.get(key)
        if value is None:
            continue
        text = str(value).strip()
        if text:
            ids[key] = text
    return ids


def _try_int(value: Any) -> Optional[int]:
    if value is None or value == "":
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


@dataclass
class MediaRef:
    """Normalised media descriptor — the only media type crossing the boundary.

    ``type`` values match the host's ``MediaType`` enum so host-side conversion is
    a plain ``MediaType(ref["type"])``.

    For ``type == "episode"``, ``ids`` describes the *episode* and ``show`` carries
    the parent show, with ``season``/``episode`` always populated.  That removes
    the ambiguity the Flutter payload has today, where the show travels under the
    ``media`` key and only the season/number live under ``episode``.
    """

    type: str
    ids: Dict[str, Any] = field(default_factory=dict)
    title: Optional[str] = None
    year: Optional[int] = None
    runtime_minutes: Optional[int] = None
    season: Optional[int] = None
    episode: Optional[int] = None
    episode_title: Optional[str] = None
    show: Optional[Dict[str, Any]] = None

    # -- construction ---------------------------------------------------

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "MediaRef":
        if not isinstance(data, Mapping):
            raise ValueError("MediaRef payload must be an object")
        media_type = str(data.get("type") or "").strip().lower()
        if media_type not in {"movie", "show", "season", "episode"}:
            raise ValueError(f"Unsupported media type '{media_type}'")

        show_raw = data.get("show")
        show: Optional[Dict[str, Any]] = None
        if isinstance(show_raw, Mapping):
            show = {
                "ids": _clean_ids(show_raw.get("ids")),
                "title": (str(show_raw["title"]) if show_raw.get("title") else None),
                "year": _try_int(show_raw.get("year")),
            }

        return cls(
            type=media_type,
            ids=_clean_ids(data.get("ids")),
            title=(str(data["title"]) if data.get("title") else None),
            year=_try_int(data.get("year")),
            runtime_minutes=_try_int(data.get("runtime_minutes")),
            season=_try_int(data.get("season")),
            episode=_try_int(data.get("episode")),
            episode_title=(
                str(data["episode_title"]) if data.get("episode_title") else None
            ),
            show=show,
        )

    @classmethod
    def from_flutter_scrobble_payload(cls, payload: Mapping[str, Any]) -> "MediaRef":
        """Build a ``MediaRef`` from the scrobble body the Flutter client sends.

        The client posts the *show* under ``media`` and only ``{season, number}``
        under ``episode`` — see ``pages/playback_page.dart:_sendScrobble``.  Every
        consumer used to redo that shuffle; the host now does it once, here, so
        plugins receive an unambiguous ref and the client payload is unchanged.
        """

        media_payload = payload.get("media")
        if not isinstance(media_payload, Mapping):
            raise ValueError("media payload is required")

        raw_type = str(payload.get("media_type") or "").strip().lower()
        if raw_type == "tv":
            raw_type = "episode"
        if raw_type not in {"movie", "episode"}:
            raise ValueError("media_type must be 'movie' or 'episode'")

        media_ids = _clean_ids(media_payload.get("ids"))
        media_title = (
            str(media_payload["title"]) if media_payload.get("title") else None
        )
        media_year = _try_int(media_payload.get("year"))

        if raw_type == "movie":
            return cls(
                type="movie",
                ids=media_ids,
                title=media_title,
                year=media_year,
                runtime_minutes=_try_int(payload.get("runtime_minutes")),
            )

        episode_payload = payload.get("episode")
        episode_payload = (
            episode_payload if isinstance(episode_payload, Mapping) else {}
        )

        # An explicit "show" key wins; otherwise the show info is what arrived
        # under "media" (the client's shape).
        show_payload = payload.get("show")
        if not isinstance(show_payload, Mapping):
            show_payload = media_payload

        return cls(
            type="episode",
            ids=_clean_ids(episode_payload.get("ids")),
            title=(
                str(episode_payload["title"]) if episode_payload.get("title") else None
            ),
            runtime_minutes=_try_int(payload.get("runtime_minutes")),
            season=_try_int(episode_payload.get("season")),
            episode=_try_int(
                episode_payload.get("number")
                if episode_payload.get("number") is not None
                else episode_payload.get("episode")
            ),
            episode_title=(
                str(episode_payload["title"]) if episode_payload.get("title") else None
            ),
            show={
                "ids": _clean_ids(show_payload.get("ids")),
                "title": (
                    str(show_payload["title"]) if show_payload.get("title") else None
                ),
                "year": _try_int(show_payload.get("year")),
            },
        )

    @classmethod
    def from_mark_watched_payload(cls, payload: Mapping[str, Any]) -> "MediaRef":
        """Build a ``MediaRef`` from the ``/library/mark-watched`` body.

        That route accepts either a movie/show tmdb id, or a show plus explicit
        ``season``/``episode`` for the per-episode path.
        """

        raw_type = str(payload.get("media_type") or payload.get("type") or "").strip().lower()
        if raw_type in {"tv", "series"}:
            raw_type = "show"
        if raw_type not in {"movie", "show", "episode"}:
            raise ValueError("media_type must be 'movie', 'show' or 'episode'")

        ids = _clean_ids(payload.get("ids"))
        tmdb_id = _try_int(payload.get("tmdb_id"))
        if tmdb_id is not None:
            ids.setdefault("tmdb", tmdb_id)

        title = str(payload["title"]) if payload.get("title") else None
        year = _try_int(payload.get("year"))
        season = _try_int(payload.get("season"))
        episode = _try_int(payload.get("episode"))

        if raw_type == "show" and season is not None and episode is not None:
            raw_type = "episode"

        if raw_type == "episode":
            return cls(
                type="episode",
                ids={},
                season=season,
                episode=episode,
                show={"ids": ids, "title": title, "year": year},
            )

        return cls(type=raw_type, ids=ids, title=title, year=year)

    # -- accessors ------------------------------------------------------

    @property
    def show_ids(self) -> Dict[str, Any]:
        """Ids of the parent show for episodes, or of the item itself otherwise."""

        if self.type == "episode" and self.show:
            return dict(self.show.get("ids") or {})
        return dict(self.ids)

    @property
    def tmdb_id(self) -> Optional[int]:
        """The tmdb id that identifies this item in the app's own catalog.

        For episodes this is the *show's* tmdb id — the app keys shows, not
        individual episodes, and every cache/route here is show-scoped.
        """

        value = self.show_ids.get("tmdb")
        return int(value) if value is not None else None

    def as_dict(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {"type": self.type, "ids": dict(self.ids)}
        if self.title:
            payload["title"] = self.title
        if self.year is not None:
            payload["year"] = self.year
        if self.runtime_minutes is not None:
            payload["runtime_minutes"] = self.runtime_minutes
        if self.season is not None:
            payload["season"] = self.season
        if self.episode is not None:
            payload["episode"] = self.episode
        if self.episode_title:
            payload["episode_title"] = self.episode_title
        if self.show:
            show: Dict[str, Any] = {"ids": dict(self.show.get("ids") or {})}
            if self.show.get("title"):
                show["title"] = self.show["title"]
            if self.show.get("year") is not None:
                show["year"] = self.show["year"]
            payload["show"] = show
        return payload


__all__ = [
    "CATEGORY_CATALOG",
    "CATEGORY_PROVIDER",
    "CATEGORY_SKIN",
    "CATEGORY_TRACKER",
    "ERROR_HTTP_STATUS",
    "ErrorCode",
    "MediaRef",
    "PLUGIN_CATEGORIES",
    "PluginCategory",
    "err",
    "error_code",
    "get_category",
    "is_exclusive_category",
    "is_ok",
    "known_category_ids",
    "ok",
    "response_data",
]
