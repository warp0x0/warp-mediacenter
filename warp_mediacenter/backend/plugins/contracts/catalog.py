"""The Catalog plugin contract.

A catalog *publishes lists* — trending, popular, anticipated, by genre, by decade
— and hands back the media in them.  It owns no watch state and no playable
streams: those are the Tracker and Provider categories.  The one thing every
catalog service shares is that it can enumerate its own lists, which is why
``catalog.lists`` exists at all.  The host cannot know what Simkl or Trakt offer,
so it asks, and the Settings picker is generated from the answers.

Two shapes cross the boundary:

``CatalogListDef``
    What a plugin *offers*.  Returned from ``catalog.lists`` once and cached by
    the host until the plugin set changes.  ``params`` is opaque to the host — it
    is stored in the user's widget config and handed back verbatim on fetch, so a
    plugin can encode a genre slug or a period without the host parsing strings.

``CatalogItem``
    One entry in a list.  Deliberately thin: ids, title, year.  The host enriches
    from TMDb (``enrichment.enrich_many``), so a plugin that only knows ids still
    produces a row with artwork.  Supply ``artwork`` yourself only if you want to
    skip that.

Fetching is **page-based, not offset-based**.  The host owns offsets — it keeps a
day-scoped pool per list and grows it by pulling successive upstream pages — while
the plugin only ever answers "give me page N".  That split is what lets a row
paginate over an entire upstream list without every plugin reimplementing
windowing, and it maps directly onto how Trakt, TMDb and Simkl actually page.

    payload  -> {list_id, media_type, params, page, page_size}
    response -> ok({items: [...], page: 3, has_more: true, total: 812})

``has_more`` is authoritative.  ``total`` is a hint and may be absent: Simkl's
genre browse reports no count at all, and TMDb caps ``total_pages`` at 500.  A
list that cannot page past its first response declares
``supports_pagination: False`` and returns ``has_more: False``.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Mapping, Optional, Sequence

from warp_mediacenter.backend.plugins.contracts.common import MediaRef

#: Groups the Settings picker renders as headers, in this order.  A plugin may
#: send anything; unknown groups fall through to ``other`` client-side rather
#: than being dropped, so a newer plugin degrades instead of vanishing.
GROUP_STANDARD = "standard"
GROUP_DISCOVER = "discover"
GROUP_GENRE = "genre"
GROUP_DECADE = "decade"
GROUP_NETWORK = "network"
GROUP_OTHER = "other"

CATALOG_GROUPS: tuple[str, ...] = (
    GROUP_STANDARD,
    GROUP_DISCOVER,
    GROUP_GENRE,
    GROUP_DECADE,
    GROUP_NETWORK,
    GROUP_OTHER,
)

#: Media types a catalog list may serve.  Matches the host's ``MediaType`` values
#: and the ``media_type`` query param the client already sends.
MEDIA_TYPES: tuple[str, ...] = ("movie", "show")

#: Fallback page size when a list does not declare one.
DEFAULT_PAGE_SIZE = 20


class CatalogAction:
    """Action names the host dispatches to a catalog plugin."""

    #: Self-report — service name, capabilities, whether it needs configuring.
    DESCRIBE = "catalog.describe"

    #: Enumerate every list this plugin publishes.  Called on demand and cached
    #: by the host; a plugin may return different lists once configured.
    LISTS = "catalog.lists"

    #: Fetch one page of one list.
    FETCH = "catalog.fetch"

    CACHE_CLEAR = "catalog.cache.clear"


class CatalogCapability:
    """Capability strings a catalog declares in its manifest.

    Checked before dispatch, so a catalog that cannot page yields a single page
    rather than an error, and one that publishes nothing yields an empty picker
    group rather than a failed Settings load.
    """

    LISTS = "catalog.lists"
    FETCH = "catalog.fetch"
    #: Declared when ``catalog.fetch`` honours ``page`` > 1.  Without it the host
    #: never asks for a second page, whatever a list def claims.
    PAGINATE = "catalog.paginate"
    #: Defined so plugins and future host versions agree on the name.  The host
    #: does not dispatch search yet — unified search still runs host-side.
    SEARCH = "catalog.search"


#: Action -> capability that must be declared for the host to dispatch it.
ACTION_CAPABILITY: Dict[str, str] = {
    CatalogAction.LISTS: CatalogCapability.LISTS,
    CatalogAction.FETCH: CatalogCapability.FETCH,
}


def _try_int(value: Any) -> Optional[int]:
    if value is None or value == "":
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _try_float(value: Any) -> Optional[float]:
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _clean_media_types(raw: Any) -> List[str]:
    """Keep only media types the app can render, preserving declared order."""

    if isinstance(raw, str):
        raw = [raw]
    if not isinstance(raw, (list, tuple)):
        return list(MEDIA_TYPES)
    seen: List[str] = []
    for value in raw:
        text = str(value or "").strip().lower()
        if text == "tv":
            text = "show"
        if text in MEDIA_TYPES and text not in seen:
            seen.append(text)
    return seen or list(MEDIA_TYPES)


def _clean_params(raw: Any) -> Dict[str, Any]:
    """Params are opaque, but they round-trip through JSON and a URL query.

    Anything not JSON-scalar is dropped rather than carried, because a value the
    host cannot serialise into the saved widget config would come back as a
    different value on the next fetch — a silently wrong row is worse than a
    missing filter.
    """

    if not isinstance(raw, Mapping):
        return {}
    params: Dict[str, Any] = {}
    for key, value in raw.items():
        name = str(key or "").strip()
        if not name:
            continue
        if value is None or isinstance(value, (str, int, float, bool)):
            params[name] = value
    return params


@dataclass
class CatalogListDef:
    """One list a catalog publishes — an entry in the Settings picker.

    ``id`` is namespaced by the host with the source id when it reaches the
    client (``simkl-catalog/genre_horror``), so a plugin only needs ids unique
    within itself.
    """

    id: str
    title: str
    media_types: List[str] = field(default_factory=lambda: list(MEDIA_TYPES))
    group: str = GROUP_OTHER
    description: Optional[str] = None
    supports_pagination: bool = False
    page_size: int = DEFAULT_PAGE_SIZE
    #: Keep upstream's order instead of applying the host's daily shuffle.
    #:
    #: The shuffle exists to give browse lists — trending, popular, by genre —
    #: some day-to-day variety, which they otherwise lack because the underlying
    #: list barely moves.  For a list whose *order is the information*, that is
    #: destructive: Continue Watching sorted by recency is the whole point of
    #: the row, and a "recently added" list shuffled is just a random list.
    preserve_order: bool = False
    #: Opaque to the host: stored in the widget config, handed back on fetch.
    params: Dict[str, Any] = field(default_factory=dict)
    sort_hint: Optional[str] = None

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "CatalogListDef":
        if not isinstance(data, Mapping):
            raise ValueError("Catalog list definition must be an object")
        list_id = str(data.get("id") or "").strip()
        if not list_id:
            raise ValueError("Catalog list definition is missing 'id'")

        group = str(data.get("group") or GROUP_OTHER).strip().lower()
        if group not in CATALOG_GROUPS:
            group = GROUP_OTHER

        page_size = _try_int(data.get("page_size")) or DEFAULT_PAGE_SIZE
        # A zero or negative page size would make the host's growth loop spin
        # without ever advancing, so it is corrected rather than trusted.
        if page_size < 1:
            page_size = DEFAULT_PAGE_SIZE

        return cls(
            id=list_id,
            title=str(data.get("title") or list_id),
            media_types=_clean_media_types(data.get("media_types")),
            group=group,
            description=(
                str(data["description"]) if data.get("description") else None
            ),
            supports_pagination=bool(data.get("supports_pagination", False)),
            page_size=page_size,
            preserve_order=bool(data.get("preserve_order", False)),
            params=_clean_params(data.get("params")),
            sort_hint=(str(data["sort_hint"]) if data.get("sort_hint") else None),
        )

    def serves(self, media_type: str) -> bool:
        return str(media_type or "").strip().lower() in self.media_types

    def as_dict(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "id": self.id,
            "title": self.title,
            "media_types": list(self.media_types),
            "group": self.group,
            "supports_pagination": bool(self.supports_pagination),
            "page_size": int(self.page_size),
        }
        if self.preserve_order:
            payload["preserve_order"] = True
        if self.description:
            payload["description"] = self.description
        if self.params:
            payload["params"] = dict(self.params)
        if self.sort_hint:
            payload["sort_hint"] = self.sort_hint
        return payload


@dataclass
class CatalogItem:
    """One entry in a catalog list.

    ``media`` is the only required part.  Everything else is optional enrichment
    a plugin may already have on hand — supplying it saves the host a TMDb round
    trip, omitting it costs nothing but that trip.
    """

    media: MediaRef
    overview: Optional[str] = None
    rating: Optional[float] = None
    genres: List[str] = field(default_factory=list)
    #: ``{"poster": ..., "backdrop": ...}``.  A poster here skips TMDb enrichment
    #: for this item.
    artwork: Dict[str, Any] = field(default_factory=dict)
    #: Descending sort key.  Optional — most lists arrive already ordered and the
    #: host preserves upstream order when this is absent.
    sort_key: Optional[float] = None

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "CatalogItem":
        if not isinstance(data, Mapping):
            raise ValueError("Catalog item must be an object")

        # A plugin may send the ref inline or nested under "media"; both are
        # unambiguous because MediaRef always carries "type".
        media_raw = data.get("media")
        if not isinstance(media_raw, Mapping):
            media_raw = data
        media = MediaRef.from_dict(media_raw)

        genres_raw = data.get("genres")
        genres: List[str] = []
        if isinstance(genres_raw, (list, tuple)):
            for value in genres_raw:
                if isinstance(value, Mapping):
                    value = value.get("name")
                text = str(value or "").strip()
                if text:
                    genres.append(text)

        artwork_raw = data.get("artwork")
        artwork: Dict[str, Any] = {}
        if isinstance(artwork_raw, Mapping):
            for key in ("poster", "backdrop"):
                value = artwork_raw.get(key)
                if value:
                    artwork[key] = str(value)

        return cls(
            media=media,
            overview=(str(data["overview"]) if data.get("overview") else None),
            rating=_try_float(data.get("rating")),
            genres=genres,
            artwork=artwork,
            sort_key=_try_float(data.get("sort_key")),
        )

    def as_dict(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {"media": self.media.as_dict()}
        if self.overview:
            payload["overview"] = self.overview
        if self.rating is not None:
            payload["rating"] = float(self.rating)
        if self.genres:
            payload["genres"] = list(self.genres)
        if self.artwork:
            payload["artwork"] = dict(self.artwork)
        if self.sort_key is not None:
            payload["sort_key"] = float(self.sort_key)
        return payload


@dataclass
class CatalogPage:
    """A ``catalog.fetch`` response, parsed.

    ``has_more`` is what the host paginates on.  It is read strictly: a plugin
    that omits it gets ``False``, because looping forever on an ambiguous
    response is the worse failure — a short row is visible and recoverable, a
    runaway fetch loop is neither.
    """

    items: List[CatalogItem] = field(default_factory=list)
    page: int = 1
    has_more: bool = False
    total: Optional[int] = None


def parse_catalog_lists(data: Mapping[str, Any]) -> List[CatalogListDef]:
    """Read a ``catalog.lists`` response body.

    A malformed definition is skipped rather than failing the whole set — one bad
    entry should cost the user that one list in the picker, not every list the
    plugin offers.
    """

    raw_lists = data.get("lists") if isinstance(data, Mapping) else None
    if not isinstance(raw_lists, (list, tuple)):
        return []

    defs: List[CatalogListDef] = []
    seen: set[str] = set()
    for raw in raw_lists:
        try:
            definition = CatalogListDef.from_dict(raw)
        except (ValueError, TypeError):
            continue
        # Duplicate ids would make the picker ambiguous and the widget config
        # unresolvable; first declaration wins.
        if definition.id in seen:
            continue
        seen.add(definition.id)
        defs.append(definition)
    return defs


def parse_catalog_items(raw_items: Any) -> List[CatalogItem]:
    """Read a list of catalog items, skipping malformed entries.

    Same rule as ``parse_continue_watching``: one upstream field failing to parse
    must never empty a home row.
    """

    if not isinstance(raw_items, (list, tuple)):
        return []

    items: List[CatalogItem] = []
    for raw in raw_items:
        try:
            items.append(CatalogItem.from_dict(raw))
        except (ValueError, TypeError):
            continue
    return items


def parse_catalog_page(data: Mapping[str, Any]) -> CatalogPage:
    """Read a ``catalog.fetch`` response body."""

    if not isinstance(data, Mapping):
        return CatalogPage()

    page = _try_int(data.get("page")) or 1
    total = _try_int(data.get("total"))
    if total is not None and total < 0:
        total = None

    return CatalogPage(
        items=parse_catalog_items(data.get("items")),
        page=page if page >= 1 else 1,
        has_more=bool(data.get("has_more", False)),
        total=total,
    )


def fetch_payload(
    list_id: str,
    *,
    media_type: str,
    params: Optional[Mapping[str, Any]] = None,
    page: int = 1,
    page_size: int = DEFAULT_PAGE_SIZE,
) -> Dict[str, Any]:
    """Build the ``catalog.fetch`` payload — one construction site, host-side."""

    return {
        "list_id": str(list_id),
        "media_type": str(media_type),
        "params": _clean_params(params),
        "page": max(1, int(page)),
        "page_size": max(1, int(page_size)),
    }


def lists_as_dicts(defs: Sequence[CatalogListDef]) -> List[Dict[str, Any]]:
    return [definition.as_dict() for definition in defs]


__all__ = [
    "ACTION_CAPABILITY",
    "CATALOG_GROUPS",
    "DEFAULT_PAGE_SIZE",
    "GROUP_DECADE",
    "GROUP_DISCOVER",
    "GROUP_GENRE",
    "GROUP_NETWORK",
    "GROUP_OTHER",
    "GROUP_STANDARD",
    "MEDIA_TYPES",
    "CatalogAction",
    "CatalogCapability",
    "CatalogItem",
    "CatalogListDef",
    "CatalogPage",
    "fetch_payload",
    "lists_as_dicts",
    "parse_catalog_items",
    "parse_catalog_lists",
    "parse_catalog_page",
]
