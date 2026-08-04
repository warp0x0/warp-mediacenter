"""Trakt — the built-in catalog source, kept as a fallback.

This is the catalog twin of ``plugins/services/legacy_trakt.py``: the original
in-tree Trakt integration, still the default, and shadowed the moment a Trakt
catalog plugin is enabled.  Nobody has to migrate — a user with a working Trakt
setup keeps it, and installing the plugin swaps the implementation without
touching their saved rows.

Two things the Dart constants never exposed are published here, because the
endpoint table always supported them: ``played``, ``collected`` and ``favorited``.
They cost nothing to declare and were already reachable by hand-editing
``user_settings.json``.

``continue_watching`` and ``based_on_watched`` deliberately do **not** live here.
They are not Trakt catalog lists — one is watch state owned by whichever tracker
is active, the other is a host-side blend of TMDb recommendations — so they are
published by ``builtin_personal`` and survive this source being shadowed.
"""

from __future__ import annotations

from typing import Any, Dict, List, Mapping, Optional, Sequence

from warp_mediacenter.backend.catalog.normalize import catalog_item_to_dict
from warp_mediacenter.backend.catalog.sources.base import KIND_LEGACY, SourcePage
from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.information_handlers.models import MediaType
from warp_mediacenter.backend.plugins.contracts.catalog import (
    GROUP_DISCOVER,
    GROUP_STANDARD,
    CatalogListDef,
)

log = get_logger(__name__)

SOURCE_ID = "trakt"

#: Trakt's own default is 10; 40 fills a home row in one call without paging.
PAGE_SIZE = 40

_BOTH = ["movie", "show"]

#: Periods Trakt accepts on the ``{period}`` lists.  Exposed as one list def per
#: period rather than a period parameter, because the picker is a flat menu and
#: "Most Watched (Weekly)" reads better than a list plus a hidden setting.
_PERIODS: tuple[tuple[str, str], ...] = (
    ("daily", "Today"),
    ("weekly", "This Week"),
    ("monthly", "This Month"),
    ("yearly", "This Year"),
    ("all", "All Time"),
)

_PERIOD_LISTS: tuple[tuple[str, str, str], ...] = (
    ("watched", "Most Watched", "Most unique viewers on Trakt"),
    ("played", "Most Played", "Most total plays on Trakt"),
    ("collected", "Most Collected", "Most added to Trakt collections"),
    ("favorited", "Most Favorited", "Most favourited by Trakt users"),
)


#: list id -> (trakt category, period).  Populated alongside the definitions so
#: the two can never disagree, and so ``fetch_page`` never re-parses an id.
_LIST_INDEX: Dict[str, tuple[str, Optional[str]]] = {}


def _build_list_defs() -> tuple[CatalogListDef, ...]:
    defs: List[CatalogListDef] = [
        CatalogListDef(
            id="trending",
            title="Trending",
            description="What Trakt users are watching right now",
            group=GROUP_STANDARD,
            media_types=list(_BOTH),
            supports_pagination=True,
            page_size=PAGE_SIZE,
        ),
        CatalogListDef(
            id="popular",
            title="Popular",
            description="Most popular on Trakt",
            group=GROUP_STANDARD,
            media_types=list(_BOTH),
            supports_pagination=True,
            page_size=PAGE_SIZE,
        ),
        CatalogListDef(
            id="anticipated",
            title="Anticipated",
            description="Most anticipated upcoming titles",
            group=GROUP_STANDARD,
            media_types=list(_BOTH),
            supports_pagination=True,
            page_size=PAGE_SIZE,
        ),
    ]

    for definition in defs:
        _LIST_INDEX[definition.id] = (definition.id, None)

    for base_id, base_title, description in _PERIOD_LISTS:
        for period, period_label in _PERIODS:
            # The bare id (no suffix) keeps its historical meaning — the routes
            # have always defaulted `period` to daily — so an old saved config
            # naming `watched` resolves to exactly what it resolved to before.
            list_id = base_id if period == "daily" else f"{base_id}_{period}"
            defs.append(
                CatalogListDef(
                    id=list_id,
                    title=f"{base_title} ({period_label})",
                    description=description,
                    group=GROUP_DISCOVER,
                    media_types=list(_BOTH),
                    supports_pagination=True,
                    page_size=PAGE_SIZE,
                    params={"period": period},
                )
            )
            _LIST_INDEX[list_id] = (base_id, period)

    return tuple(defs)


LIST_DEFS: tuple[CatalogListDef, ...] = _build_list_defs()


class LegacyTraktSource:
    """Adapts ``InformationProviders.trakt_catalog_page`` to the source interface."""

    id = SOURCE_ID
    label = "Trakt"
    kind = KIND_LEGACY
    icon = "live_tv_outlined"

    def __init__(self, providers: Any) -> None:
        self._providers = providers

    def is_available(self) -> bool:
        """Whether Trakt is configured at all.

        An unconfigured Trakt should not put a source full of lists in the picker
        that every one of which will come back empty.
        """

        trakt = getattr(self._providers, "trakt", None)
        return trakt is not None

    def list_definitions(self) -> Sequence[CatalogListDef]:
        return LIST_DEFS

    def fetch_page(
        self,
        list_id: str,
        *,
        media_type: str,
        params: Mapping[str, Any],
        page: int,
        page_size: int = PAGE_SIZE,
    ) -> SourcePage:
        mt = MediaType.MOVIE if media_type == "movie" else MediaType.SHOW

        category, period = _LIST_INDEX.get(list_id, (list_id, None))
        # An explicit param wins over the id-derived default, so the older
        # `?period=` query on /catalog/trakt/{category} keeps working.
        if isinstance(params, Mapping) and params.get("period"):
            period = str(params["period"])

        items, pagination = self._providers.trakt_catalog_page(
            mt, category, period=period, page=page, limit=page_size
        )
        dicts: List[Dict[str, Any]] = [catalog_item_to_dict(item) for item in items]

        if pagination is None:
            # Trakt is not configured — an empty row, not an error.
            return SourcePage(items=[], has_more=False, total=0)

        return SourcePage(
            items=dicts,
            has_more=bool(pagination.has_next),
            total=pagination.item_count,
        )


__all__ = ["LIST_DEFS", "PAGE_SIZE", "SOURCE_ID", "LegacyTraktSource"]
