"""The catalog facade.

One call site for every route that needs a browsable list, over an ordered set of
sources: the built-in TMDb integration, the user's own personalised rows, any
enabled catalog plugins, and the legacy built-in Trakt integration.

The shape mirrors ``TrackerService``, with one structural difference that matters
throughout: **catalog is not an exclusive category**.  A tracker has exactly one
active plugin and the facade dispatches to it; a catalog has as many as the user
installed, and the facade *aggregates* them.  So this reads
``registry.by_category`` and filters on ``enabled``, never ``active_for_category``,
and ``definitions()`` returns every source at once rather than resolving to one.

Shadowing is how a plugin replaces a built-in without the user migrating
anything.  A plugin declaring ``metadata.shadows == "trakt"`` hides the legacy
Trakt source while it is enabled; disable it and the built-in comes straight
back.  This is the catalog counterpart of the tracker's plugin/legacy/none
three-way dispatch, and it exists for the same reason: the default path has to
keep working untouched for anyone who never installs a plugin.
"""

from __future__ import annotations

import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any, Dict, List, Mapping, Optional, Sequence

from warp_mediacenter.backend.catalog.sources.base import SourcePage
from warp_mediacenter.backend.catalog.sources.builtin_personal import (
    BuiltinPersonalSource,
)
from warp_mediacenter.backend.catalog.sources.builtin_tmdb import BuiltinTmdbSource
from warp_mediacenter.backend.catalog.sources.legacy_trakt import LegacyTraktSource
from warp_mediacenter.backend.catalog.sources.plugin_source import PluginCatalogSource
from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.information_handlers.enrichment import (
    enrich_many,
    resolve_many,
)
from warp_mediacenter.backend.plugins.contracts.catalog import CatalogListDef
from warp_mediacenter.backend.plugins.contracts.common import CATEGORY_CATALOG
from warp_mediacenter.backend.plugins.services.catalog_cache import (
    CatalogPool,
    CatalogPoolCache,
)

log = get_logger(__name__)

#: Items block 0 aims to hold.  Matches what the old fixed pool held (5 TMDb
#: pages of 20), so home rows keep their depth.
TARGET_BLOCK_ITEMS = 100

#: Cap on pages pulled for block 0, whatever the arithmetic says.
MAX_INITIAL_BLOCK_PAGES = 5


def initial_block_pages(page_size: int) -> int:
    """How many upstream pages block 0 should pull.

    Derived from the source's page size rather than fixed, because page sizes
    differ by two orders of magnitude: TMDb serves 20 per page, TheTVDB 500.
    Five pages of each means 100 items in one case and 2500 in the other — and
    the 2500 has to be id-resolved against TMDb before any of it can render, so
    a fixed page count turned a 40-item row into thousands of lookups that could
    not finish inside any sane budget.
    """

    if page_size <= 0:
        return 1
    pages = -(-TARGET_BLOCK_ITEMS // page_size)  # ceil
    return max(1, min(pages, MAX_INITIAL_BLOCK_PAGES))

#: Wall-clock budget for one growth step.  Matches the timeout the TMDb catalog
#: route has always used for its parallel prefetch.
GROWTH_TIMEOUT = 30.0

#: Budget for filling in artwork on plugin-supplied rows.  Longer than Continue
#: Watching's 12s because a catalog block is up to 100 items rather than 25, and
#: this never sits in the playback path.
ENRICH_TIMEOUT = 20.0

#: Params every list understands regardless of what it declares.  See
#: ``CatalogService._resolve_params`` for why the set is deliberately tiny.
_HOST_PARAMS = frozenset({"language"})

#: Fields TMDb enrichment fills in.  A row missing any of them is worth a
#: lookup — not just one missing a poster.
#:
#: Getting this wrong is invisible in the obvious test: a source that supplies
#: its own poster (Simkl, TheTVDB both do) looked "already enriched" and was
#: skipped entirely, so it never gained a backdrop, and never gained an overview
#: either unless the source happened to send one.  That is why Simkl rows had no
#: synopsis and no hero image while TheTVDB rows — whose records do carry an
#: overview — were missing only the hero image.
_ENRICHED_FIELDS = ("poster_path", "backdrop_path", "overview")


def _needs_enrichment(row: Mapping[str, Any]) -> bool:
    """Whether TMDb could still add something to this row.

    TMDb-sourced rows arrive with all three fields from the catalog response and
    are skipped, so this costs nothing on the built-in path.
    """

    return not all(row.get(field) for field in _ENRICHED_FIELDS)


#: Resolve/top-up rounds allowed while serving one window.  Bounds the case
#: where nothing in a list resolves to a TMDb id.
MAX_WINDOW_PASSES = 4

#: Total wall-clock budget for resolving and enriching one window, across all
#: passes.  Sized so a row that cannot be resolved fails fast rather than
#: holding the request open for the sum of every pass's timeout.
WINDOW_BUDGET = 25.0


class CatalogService:
    def __init__(
        self,
        *,
        manager: Any,
        registry: Any,
        providers: Any = None,
        pools: Optional[CatalogPoolCache] = None,
    ) -> None:
        self._manager = manager
        self._registry = registry
        self._providers = providers
        self._pools = pools or CatalogPoolCache()

        self._tmdb = BuiltinTmdbSource(providers)
        self._personal = BuiltinPersonalSource(providers)
        self._trakt = LegacyTraktSource(providers)

        #: Definitions are expensive for plugins (a dispatch each) and static for
        #: built-ins, so they are cached and invalidated on registry change
        #: rather than re-derived per request.  The Settings picker asks for them
        #: on every open.
        self._defs_lock = threading.Lock()
        self._defs_cache: Optional[List[Dict[str, Any]]] = None
        self._defs_registry_version: Optional[int] = None

    # ------------------------------------------------------------------
    # Source resolution
    # ------------------------------------------------------------------

    def plugin_sources(self) -> List[PluginCatalogSource]:
        records = [
            record
            for record in self._registry.by_category(CATEGORY_CATALOG)
            if record.enabled
        ]
        # Stable order: the picker's source tabs must not reshuffle between
        # requests, which on a D-pad would move the user's focus under them.
        records.sort(key=lambda record: record.plugin_id)
        return [PluginCatalogSource(record, self._manager) for record in records]

    def sources(self) -> List[Any]:
        """Every source that should be visible right now, in render order."""

        plugins = self.plugin_sources()
        shadowed = {source.shadows for source in plugins if source.shadows}

        ordered: List[Any] = [self._tmdb, self._personal]
        ordered.extend(plugins)

        if self._trakt.id not in shadowed and self._trakt.is_available():
            ordered.append(self._trakt)

        return ordered

    def source_by_id(self, source_id: str) -> Optional[Any]:
        for source in self.sources():
            if source.id == source_id:
                return source
        return None

    # ------------------------------------------------------------------
    # Definitions
    # ------------------------------------------------------------------

    def definitions(self) -> Dict[str, Any]:
        """The source + list registry that drives the Settings picker."""

        version = getattr(self._registry, "version", None)
        with self._defs_lock:
            if self._defs_cache is not None and self._defs_registry_version == version:
                return {"sources": self._defs_cache}

        payload: List[Dict[str, Any]] = []
        for source in self.sources():
            try:
                defs: Sequence[CatalogListDef] = source.list_definitions()
            except Exception as exc:  # noqa: BLE001 - one bad source, not a broken picker
                log.warning(
                    "catalog_definitions_failed", source=source.id, error=str(exc)
                )
                defs = []
            payload.append(
                {
                    "id": source.id,
                    "label": source.label,
                    "kind": source.kind,
                    "icon": getattr(source, "icon", None),
                    "lists": [definition.as_dict() for definition in defs],
                }
            )

        with self._defs_lock:
            self._defs_cache = payload
            self._defs_registry_version = version
        return {"sources": payload}

    def find_list(
        self, source_id: str, list_id: str
    ) -> tuple[Optional[Any], Optional[CatalogListDef]]:
        source = self.source_by_id(source_id)
        if source is None:
            return None, None
        for definition in source.list_definitions():
            if definition.id == list_id:
                return source, definition
        return source, None

    # ------------------------------------------------------------------
    # Fetch
    # ------------------------------------------------------------------

    def fetch(
        self,
        source_id: str,
        list_id: str,
        *,
        media_type: str = "movie",
        params: Optional[Mapping[str, Any]] = None,
        limit: int = 20,
        offset: int = 0,
    ) -> Dict[str, Any]:
        """One window of one list, growing the pool as far as the window needs."""

        source, definition = self._resolve(source_id, list_id)
        if source is None:
            return self._empty(source_id, list_id, media_type, limit, offset)
        source_id = source.id

        # An unknown list id still reaches the source: ids the picker never
        # published are legitimate (a hand-edited config, an alias route), and
        # the source is the authority on whether it can serve one.
        effective_params = self._resolve_params(definition, params)
        page_size = definition.page_size if definition is not None else 20
        preserve_order = definition.preserve_order if definition is not None else False

        pool_key = CatalogPoolCache.key(
            source_id, list_id, media_type, effective_params
        )
        pool = self._pools.get_or_create(pool_key)

        needed = offset + limit
        with pool.lock:
            self._grow_until(
                pool,
                source,
                list_id,
                media_type=media_type,
                params=effective_params,
                page_size=page_size,
                preserve_order=preserve_order,
                needed=needed,
            )
            items = self._serve_window(
                pool,
                source,
                list_id,
                media_type=media_type,
                params=effective_params,
                page_size=page_size,
                preserve_order=preserve_order,
                offset=offset,
                limit=limit,
            )
            has_more = pool.has_more_after(offset, len(items))
            # Once the pool is exhausted its length *is* the total the client can
            # reach, and that is the honest number to show.  The upstream hint
            # would over-report here in both directions: it counts rows dropped
            # as unresolvable (Simkl's airing list loses the titles TMDb has
            # never heard of), and it ignores the pool's own size cap.
            if pool.exhausted or pool.total_hint is None:
                total = len(pool.items)
            else:
                total = pool.total_hint

        return {
            "source": source_id,
            "list_id": list_id,
            "category": list_id,
            "media_type": media_type,
            "items": items,
            "count": len(items),
            "total": total,
            "offset": offset,
            "limit": limit,
            "has_more": has_more,
        }

    def _resolve(
        self, source_id: str, list_id: str
    ) -> tuple[Optional[Any], Optional[CatalogListDef]]:
        """Find the source that should answer for ``(source_id, list_id)``.

        Normally that is just the named source.  Two cases redirect:

        * **Personal lists asked of another source.**  Continue Watching and
          Based on Watched used to be published under ``trakt``, and every config
          saved before they moved to their own source still names them that way.
          They are not Trakt catalog lists — Continue Watching belongs to
          whichever *tracker* is active — so rather than teaching the Trakt
          source to serve them, the request is redirected.  Without this, an
          existing user's first home row silently empties on upgrade.
        * **A shadowed built-in.**  Asking for ``trakt`` while a plugin shadows
          it lands on the plugin, which is the point of shadowing.

        An unknown list id is *not* redirected: sources are the authority on what
        they can serve, and ids the picker never published (a hand-edited config,
        an alias route) are legitimate.
        """

        source = self.source_by_id(source_id)

        if source is not None:
            for candidate in source.list_definitions():
                if candidate.id == list_id:
                    return source, candidate

        # The named source cannot serve it — is this one of the personal rows?
        for candidate in self._personal.list_definitions():
            if candidate.id == list_id:
                return self._personal, candidate

        if source is not None:
            return source, None

        # Unknown source id: follow a shadow if one claims it.
        for plugin in self.plugin_sources():
            if plugin.shadows == source_id:
                for candidate in plugin.list_definitions():
                    if candidate.id == list_id:
                        return plugin, candidate
                return plugin, None

        return None, None

    @staticmethod
    def _resolve_params(
        definition: Optional[CatalogListDef], params: Optional[Mapping[str, Any]]
    ) -> Dict[str, Any]:
        """Merge caller params onto a list's declared defaults, then narrow.

        Narrowing matters more than it looks.  Params are part of the pool key,
        so a caller that tacks on a param the list does not use would open a
        *second* pool for the same list — with a different shuffle seed, hence a
        different order.  The old ``/catalog/trakt/{category}`` alias always
        sends ``period``, even for ``trending`` where Trakt ignores it, so
        without this the home row and the browse grid could disagree about the
        order of the very same list.

        A param is kept when the list declares it (``period`` on the
        period-scoped Trakt lists) or when it is a host-level refinement every
        list understands (``language``).  Unknown lists keep everything, since
        there is no declaration to narrow against.
        """

        supplied = {k: v for k, v in (params or {}).items() if v is not None}
        if definition is None:
            return supplied

        merged = dict(definition.params)
        for key, value in supplied.items():
            if key in merged or key in _HOST_PARAMS:
                merged[key] = value
        return merged

    def _empty(
        self, source_id: str, list_id: str, media_type: str, limit: int, offset: int
    ) -> Dict[str, Any]:
        log.warning("catalog_source_unknown", source=source_id, list_id=list_id)
        return {
            "source": source_id,
            "list_id": list_id,
            "category": list_id,
            "media_type": media_type,
            "items": [],
            "count": 0,
            "total": 0,
            "offset": offset,
            "limit": limit,
            "has_more": False,
            "error": "unknown_source",
        }

    # ------------------------------------------------------------------
    # Pool growth
    # ------------------------------------------------------------------

    def _grow_until(
        self,
        pool: CatalogPool,
        source: Any,
        list_id: str,
        *,
        media_type: str,
        params: Mapping[str, Any],
        page_size: int,
        preserve_order: bool,
        needed: int,
    ) -> None:
        """Pull upstream pages until the pool covers ``needed`` items.

        Caller holds ``pool.lock``.
        """

        while len(pool.items) < needed and pool.can_grow:
            added, reached_upstream = self._fetch_block(
                pool,
                source,
                list_id,
                media_type=media_type,
                params=params,
                page_size=page_size,
                preserve_order=preserve_order,
                pages=initial_block_pages(page_size) if pool.blocks == 0 else 1,
            )

            if not reached_upstream:
                # Every request in the block failed — a bad API key, a network
                # blip, upstream down.  Stop growing for *this* request but do
                # not mark the pool exhausted: a day-scoped pool poisoned by a
                # transient failure would leave the row empty until midnight
                # even after the cause is fixed.  The next request retries.
                return

            if added == 0:
                # Upstream answered but had nothing new.  Whether it ended or is
                # repeating itself, continuing would loop.
                pool.exhausted = True
                return

    def _fetch_block(
        self,
        pool: CatalogPool,
        source: Any,
        list_id: str,
        *,
        media_type: str,
        params: Mapping[str, Any],
        page_size: int,
        preserve_order: bool,
        pages: int,
    ) -> tuple[int, bool]:
        """Fetch ``pages`` upstream pages, enrich them, append as one block.

        Returns ``(items_added, reached_upstream)``.  The second value separates
        "upstream said there is nothing more" from "we never got an answer" —
        the caller must not treat a failed request as the end of the list.
        """

        start_page = pool.next_page
        page_numbers = list(range(start_page, start_page + pages))
        results: Dict[int, SourcePage] = {}

        def _one(page_num: int) -> SourcePage:
            return source.fetch_page(
                list_id,
                media_type=media_type,
                params=params,
                page=page_num,
                page_size=page_size,
            )

        if len(page_numbers) == 1:
            try:
                results[page_numbers[0]] = _one(page_numbers[0])
            except Exception as exc:  # noqa: BLE001 - a short row beats a 500
                log.warning(
                    "catalog_page_failed",
                    source=source.id,
                    list_id=list_id,
                    page=page_numbers[0],
                    error=str(exc),
                )
        else:
            # NOT `with ThreadPoolExecutor(...)`: its `__exit__` joins every
            # worker regardless of the `as_completed` timeout, so a single
            # unresponsive upstream turns a 30s budget into an unbounded wait —
            # the exact trap `enrichment.enrich_many` documents.  Shut down
            # without waiting instead and let stragglers finish unobserved.
            executor = ThreadPoolExecutor(
                max_workers=len(page_numbers), thread_name_prefix="catalog-page"
            )
            try:
                futures = {executor.submit(_one, p): p for p in page_numbers}
                try:
                    for future in as_completed(futures, timeout=GROWTH_TIMEOUT):
                        page_num = futures[future]
                        try:
                            results[page_num] = future.result()
                        except Exception as exc:  # noqa: BLE001
                            log.warning(
                                "catalog_page_failed",
                                source=source.id,
                                list_id=list_id,
                                page=page_num,
                                error=str(exc),
                            )
                except TimeoutError:
                    # Partial results are still worth appending; the pool stays
                    # growable so the next request retries the rest.
                    log.warning(
                        "catalog_block_timeout", source=source.id, list_id=list_id
                    )
            finally:
                executor.shutdown(wait=False)

        # Merge in page order so dedupe is deterministic regardless of which
        # parallel fetch finished first.
        rows: List[Dict[str, Any]] = []
        upstream_has_more = False
        for page_num in page_numbers:
            page = results.get(page_num)
            if page is None:
                continue
            rows.extend(page.items)
            upstream_has_more = page.has_more
            if page.total is not None and pool.total_hint is None:
                pool.total_hint = page.total

        if not results:
            # Nothing came back at all.  Leave `next_page` where it was so the
            # retry re-requests these pages rather than skipping them.
            return 0, False

        pool.pages_fetched += len(results)
        pool.next_page = start_page + len(page_numbers)
        if not upstream_has_more:
            pool.exhausted = True

        if not rows:
            return 0, True

        # Deliberately NOT resolved or enriched here.  A block can be hundreds
        # of rows; resolving all of them to serve a window of 40 is work the
        # user never sees, and for a source with no TMDb ids it is hundreds of
        # lookups that cannot finish inside any sane budget.  `_serve_window`
        # does it lazily instead.
        return pool.append_block(rows, shuffle=not preserve_order), True

    def _serve_window(
        self,
        pool: CatalogPool,
        source: Any,
        list_id: str,
        *,
        media_type: str,
        params: Mapping[str, Any],
        page_size: int,
        preserve_order: bool,
        offset: int,
        limit: int,
    ) -> List[Dict[str, Any]]:
        """Resolve and enrich just the slice being served, then return it.

        Two steps, in this order, because they answer different questions:

        1. **Resolve** — a source that speaks another id namespace (TheTVDB emits
           TVDB ids, Simkl's best-of lists only a Simkl id and a title) has no
           TMDb id yet, and without one the row cannot be opened, cached or
           enriched.  Rows that stay unresolvable are removed from the pool
           entirely; a tile that does nothing when clicked is worse than a
           shorter row.
        2. **Enrich** — poster, backdrop, overview, rating and genres for
           whatever is left that has no artwork of its own.

        Doing this per *window* rather than per block is what keeps the cost
        proportional to what is displayed.  A block from TheTVDB is 500 rows and
        none of them carry a TMDb id; resolving the block meant 500 lookups to
        show 40, which timed out wholesale and left the row empty.

        Caller holds ``pool.lock``.
        """

        if self._providers is None:
            return pool.window(offset, limit)

        # One wall-clock budget for the whole thing, not per pass.  Four passes
        # each taking the full enrichment timeout is 80s of a user staring at a
        # spinner — which is exactly what happened when TMDb was unreachable and
        # every resolution attempt ran to its deadline.
        deadline = time.monotonic() + WINDOW_BUDGET

        for _ in range(MAX_WINDOW_PASSES):
            window = pool.window(offset, limit)
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                break

            unresolved = [row for row in window if not row.get("tmdb_id")]
            if unresolved:
                try:
                    resolve_many(
                        unresolved,
                        self._providers,
                        media_type,
                        timeout=min(ENRICH_TIMEOUT, remaining),
                    )
                except Exception as exc:  # noqa: BLE001
                    log.warning("catalog_resolve_failed", error=str(exc))

                dead = [row for row in unresolved if not row.get("tmdb_id")]
                # Rows that just gained an id must claim it now; two upstream
                # entries can resolve to the same TMDb title, and a duplicate
                # card in a row is immediately visible.
                duplicates = pool.claim_ids(
                    [row for row in unresolved if row.get("tmdb_id")]
                )
                if dead or duplicates:
                    pool.drop_rows(dead + duplicates)
                    # The window just shrank; pull more in behind it if we can.
                    if len(pool.items) < offset + limit and pool.can_grow:
                        added, reached = self._fetch_block(
                            pool,
                            source,
                            list_id,
                            media_type=media_type,
                            params=params,
                            page_size=page_size,
                            preserve_order=preserve_order,
                            pages=1,
                        )
                        if not reached:
                            break
                        if added == 0:
                            pool.exhausted = True
                    continue

            remaining = deadline - time.monotonic()
            pending = [row for row in window if _needs_enrichment(row)]
            if pending and remaining > 0:
                try:
                    enrich_many(
                        pending,
                        self._providers,
                        media_type,
                        timeout=min(ENRICH_TIMEOUT, remaining),
                    )
                except Exception as exc:  # noqa: BLE001 - un-enriched rows still render
                    log.warning("catalog_enrich_failed", error=str(exc))
            return window

        # Out of passes or out of budget.  Serve only what is actually usable:
        # a row with no TMDb id cannot be opened, so returning it would put a
        # tile on screen that does nothing when selected.
        return [row for row in pool.window(offset, limit) if row.get("tmdb_id")]


    # ------------------------------------------------------------------
    # Invalidation
    # ------------------------------------------------------------------

    def invalidate_definitions(self) -> None:
        with self._defs_lock:
            self._defs_cache = None
            self._defs_registry_version = None

    def on_enabled_changed(self, plugin_id: Optional[str] = None) -> None:
        """Called after a catalog plugin is installed, enabled, disabled or removed.

        Drops the definitions cache unconditionally — enabling a plugin can also
        *hide* a built-in through shadowing, so the change is never local to the
        plugin that moved.
        """

        self.invalidate_definitions()
        if plugin_id:
            self._pools.drop_source(plugin_id)
        # A shadow going up or down changes which source answers for `trakt`.
        self._pools.drop_source(self._trakt.id)

    def on_watch_state_changed(self) -> None:
        """Drop pools whose contents are derived from what the user has watched.

        Continue Watching and Based-on-Watched are served through the ordinary
        catalog pool machinery, and a pool is only rebuilt when it goes stale —
        which is *daily*. So while the tracker itself invalidated correctly
        after a scrobble, the pool in front of it kept serving the pre-watch
        window for the rest of the day, and a show finished ten minutes ago
        never appeared in the row.

        Called from TrackerService.invalidate(), i.e. after every scrobble
        stop, mark-watched and remove-from-continue-watching.
        """

        self._pools.drop_source(self._personal.id)
        # The legacy Trakt source answers the same lists when no tracker plugin
        # is active, and `trakt` may also be shadowed by a plugin source.
        self._pools.drop_source(self._trakt.id)

    def clear_pools(self) -> None:
        self._pools.clear()

    def health(self) -> Dict[str, Any]:
        plugins = self.plugin_sources()
        return {
            "sources": [source.id for source in self.sources()],
            "plugins": [source.id for source in plugins],
            "shadowed": sorted({s.shadows for s in plugins if s.shadows}),
            "pools": self._pools.stats(),
        }

    def clear_plugin_caches(self, scope: str = "all") -> None:
        for source in self.plugin_sources():
            try:
                source.clear_cache(scope)
            except Exception:  # noqa: BLE001 - best-effort
                pass


__all__ = [
    "ENRICH_TIMEOUT",
    "GROWTH_TIMEOUT",
    "MAX_INITIAL_BLOCK_PAGES",
    "TARGET_BLOCK_ITEMS",
    "CatalogService",
    "initial_block_pages",
]
