"""The user's own rows — Continue Watching and Based on What You Watched.

These two have always been listed in the picker under "Trakt", which was never
accurate and becomes actively wrong once Trakt is a plugin:

* **Continue Watching** is watch *state*, owned by whichever tracker is active.
  With the Simkl tracker enabled it is Simkl's data; the row must not vanish
  because a *Trakt catalog* plugin shadowed the legacy Trakt catalog source.
  ``contracts/tracker.py`` says this outright — Continue Watching is the one row
  a tracker owns.
* **Based on Watched** is a host-side blend: it takes recent history from the
  tracker and fans out over TMDb recommendations and similar titles.  No single
  external service produces it.

So they live in their own always-present source that no plugin can shadow.
Neither paginates — both are short, personal, and re-derived per request.

Fetching delegates back into ``routes/discovery``.  That import is deliberately
function-local: ``discovery`` imports this package for the normaliser, so a
module-level import here would close the cycle.
"""

from __future__ import annotations

from typing import Any, Dict, List, Mapping, Sequence

from warp_mediacenter.backend.catalog.sources.base import KIND_BUILTIN, SourcePage
from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.plugins.contracts.catalog import (
    GROUP_STANDARD,
    CatalogListDef,
)

log = get_logger(__name__)

SOURCE_ID = "warp"

LIST_CONTINUE_WATCHING = "continue_watching"
LIST_BASED_ON_WATCHED = "based_on_watched"

LIST_DEFS: tuple[CatalogListDef, ...] = (
    CatalogListDef(
        id=LIST_CONTINUE_WATCHING,
        title="Continue Watching",
        description="Pick up where you left off, from your active tracker",
        group=GROUP_STANDARD,
        media_types=["movie", "show"],
        supports_pagination=False,
        page_size=25,
        # Ordered by recency by the tracker.  Shuffling it would put a show you
        # finished last month above the episode you paused ten minutes ago.
        preserve_order=True,
    ),
    CatalogListDef(
        id=LIST_BASED_ON_WATCHED,
        title="Based on What You Watched",
        description="Recommendations drawn from your recent history",
        group=GROUP_STANDARD,
        media_types=["movie", "show"],
        supports_pagination=False,
        page_size=40,
        # Already shuffled per request by the builder itself.
        preserve_order=True,
    ),
)


class BuiltinPersonalSource:
    """The host's own personalised rows."""

    id = SOURCE_ID
    label = "My Library"
    kind = KIND_BUILTIN
    icon = "bookmark_outline"

    def __init__(self, providers: Any) -> None:
        self._providers = providers

    def list_definitions(self) -> Sequence[CatalogListDef]:
        return LIST_DEFS

    def fetch_page(
        self,
        list_id: str,
        *,
        media_type: str,
        params: Mapping[str, Any],
        page: int,
        page_size: int = 40,
    ) -> SourcePage:
        # Neither list pages, so anything past the first is empty by definition.
        # Answering honestly here stops the pool growth loop dead rather than
        # letting it re-request the same first page forever.
        if page > 1:
            return SourcePage(items=[], has_more=False)

        from warp_mediacenter.backend.api.routes import discovery  # noqa: PLC0415

        if list_id == LIST_CONTINUE_WATCHING:
            response = discovery._tracker_service().continue_watching(
                media_type=media_type, limit=page_size
            )
        elif list_id == LIST_BASED_ON_WATCHED:
            response = discovery.build_trakt_based_on_watched(
                media_type=media_type, limit=page_size
            )
        else:
            return SourcePage(items=[], has_more=False)

        items: List[Dict[str, Any]] = list(response.get("items") or [])
        return SourcePage(items=items, has_more=False, total=len(items))


__all__ = [
    "LIST_BASED_ON_WATCHED",
    "LIST_CONTINUE_WATCHING",
    "LIST_DEFS",
    "SOURCE_ID",
    "BuiltinPersonalSource",
]
