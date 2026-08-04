"""Day-scoped, growable pools — one per catalog list.

The problem this solves
-----------------------
The old model prefetched a fixed slab (5 TMDb pages, or ``limit=100`` from
Trakt), shuffled it once per day, and reported ``total = len(pool)``.  That gave
the home rows their daily variety, but it also meant "See More → Load More" hit a
wall at ~100 items on a list that upstream might have ten thousand entries in,
and the wall was invisible: the response looked complete.

The fix keeps the variety and removes the wall.

How it works
------------
A pool is a list that only ever grows at the tail, built out of *blocks*:

* **Block 0** is the initial slab — enough upstream pages to fill a home row
  several times over — shuffled with the seed ``{date}-{key}``.  This is exactly
  what the old code produced, so the first 40 items a Movies row shows are
  unchanged by this rewrite.
* **Block N** is fetched only when a request reaches past the current tail.  It
  is shuffled within itself (seed ``{date}-{key}:{n}``) and appended.

Shuffling *within* a block rather than across the whole pool is what makes
pagination coherent.  If the pool were re-shuffled on every growth, an item on
page 1 could reappear on page 5 and another could be skipped entirely — the user
would see duplicates and gaps while scrolling.  Append-only ordering makes that
impossible, and because the seed is derived from the date, a backend restart
mid-session rebuilds the identical order.

Bounds
------
Growth is capped three ways, because a user paging deep through several lists
must not be able to grow the process without limit, and a misreporting upstream
must not be able to spin the loop:

* ``MAX_POOL_ITEMS`` per list,
* ``MAX_UPSTREAM_PAGES`` fetches per list per day,
* ``MAX_POOLS`` live pools, evicted least-recently-used.

Hitting any of them marks the pool exhausted, which surfaces to the client as
``has_more: false`` — a list that ends early, not one that errors.
"""

from __future__ import annotations

import random
import threading
from collections import OrderedDict
from datetime import date
from typing import Any, Dict, List, Optional

from warp_mediacenter.backend.common.logging import get_logger

log = get_logger(__name__)

#: Items held per list, per day.  2000 is ~50 home-row-widths of scrolling; well
#: past any realistic browse session, and small enough that 64 of them is a few
#: tens of MB rather than a leak.
MAX_POOL_ITEMS = 2000

#: Upstream page fetches per list per day.  This is a runaway guard, not the
#: depth limit — it is set high enough that ``MAX_POOL_ITEMS`` is what actually
#: stops a deep scroll, even for a source paging 20 at a time.  Its job is only
#: to stop a source that keeps answering ``has_more: true`` with nothing new.
MAX_UPSTREAM_PAGES = 120

#: Live pools before least-recently-used eviction.
MAX_POOLS = 64


class CatalogPool:
    """The growable, day-scoped item list for one catalog list.

    Callers must hold ``lock`` while inspecting-then-growing, so two concurrent
    "Load More" requests cannot both decide to fetch the same upstream page.
    """

    def __init__(self, key: str, day: date) -> None:
        self.key = key
        self.day = day
        self.lock = threading.Lock()
        self.items: List[Dict[str, Any]] = []
        self.seen_ids: set[str] = set()
        #: Next upstream page to request.  1-based, like every source.
        self.next_page: int = 1
        self.pages_fetched: int = 0
        self.exhausted: bool = False
        self.total_hint: Optional[int] = None
        self.blocks: int = 0

    # ------------------------------------------------------------------

    def is_stale(self, today: date) -> bool:
        return self.day != today

    @property
    def can_grow(self) -> bool:
        return (
            not self.exhausted
            and len(self.items) < MAX_POOL_ITEMS
            and self.pages_fetched < MAX_UPSTREAM_PAGES
        )

    def append_block(self, rows: List[Dict[str, Any]], *, shuffle: bool = True) -> int:
        """Dedupe, shuffle within the block, append.  Returns items added.

        Deduping is against every id already in the pool, not just this block:
        upstream lists shift under pagination (a title moving from page 2 to page
        1 between two requests would otherwise arrive twice), and a duplicate
        card in a row is immediately visible to the user.
        """

        fresh: List[Dict[str, Any]] = []
        for row in rows:
            item_id = str(row.get("id") or row.get("tmdb_id") or "")
            if not item_id:
                # No id *yet*.  Sources that speak another id namespace — TheTVDB
                # emits TVDB ids only — cannot be deduped until the host has
                # resolved them, so they are admitted here and claim their id
                # later via `claim_ids`.  Skipping that second step is what let
                # the same title appear twice in one row.
                fresh.append(row)
                continue
            if item_id in self.seen_ids:
                continue
            self.seen_ids.add(item_id)
            fresh.append(row)

        if not fresh:
            return 0

        if shuffle:
            # Block 0's seed is byte-identical to the one the old fixed-pool
            # code used, so today's home rows come back in exactly the order
            # they did before this rewrite.  Later blocks salt it with the
            # block index.
            seed = f"{self.day.isoformat()}-{self.key}"
            if self.blocks > 0:
                seed = f"{seed}:{self.blocks}"
            random.Random(seed).shuffle(fresh)

        room = MAX_POOL_ITEMS - len(self.items)
        if len(fresh) > room:
            fresh = fresh[:room]
            self.exhausted = True

        self.items.extend(fresh)
        self.blocks += 1
        return len(fresh)

    def claim_ids(self, rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Register ids for rows that only learned them after resolution.

        Returns the rows whose id was already taken — duplicates the append-time
        dedupe could not have caught, because at that point the row had no id to
        compare.  Two upstream entries resolving to the same TMDb title is
        routine (a duplicate TheTVDB record, or a title+year search matching the
        same show twice), and the caller drops them.
        """

        duplicates: List[Dict[str, Any]] = []
        for row in rows:
            item_id = str(row.get("id") or row.get("tmdb_id") or "")
            if not item_id:
                continue
            if item_id in self.seen_ids:
                duplicates.append(row)
            else:
                self.seen_ids.add(item_id)
        return duplicates

    def drop_rows(self, rows: List[Dict[str, Any]]) -> int:
        """Remove specific rows, identified by object identity.

        Used for rows that could not be resolved to a TMDb id: they cannot be
        opened, so leaving them in the pool would put dead tiles in the row and
        make ``has_more`` over-report what the user can actually reach.

        Identity rather than equality, because two entries can be equal dicts
        (a title with no id, appearing twice under different upstream keys) and
        only the one that failed should go.
        """

        if not rows:
            return 0
        doomed = {id(row) for row in rows}
        before = len(self.items)
        self.items = [row for row in self.items if id(row) not in doomed]
        # Their ids stay in `seen_ids` on purpose: a row that failed to resolve
        # once will fail again, and re-admitting it on a later page would just
        # cost the same lookups to drop it a second time.
        return before - len(self.items)

    def window(self, offset: int, limit: int) -> List[Dict[str, Any]]:
        if offset < 0:
            offset = 0
        return self.items[offset : offset + limit]

    def has_more_after(self, offset: int, count: int) -> bool:
        """Whether anything follows the window just served.

        True either because the pool already holds more, or because it can still
        grow.  The second half is what lets a client keep asking without the host
        having to prefetch a page it may never need.
        """

        if offset + count < len(self.items):
            return True
        return self.can_grow

    def stats(self) -> Dict[str, Any]:
        return {
            "items": len(self.items),
            "pages_fetched": self.pages_fetched,
            "blocks": self.blocks,
            "exhausted": self.exhausted,
            "total_hint": self.total_hint,
        }


class CatalogPoolCache:
    """LRU over live pools, keyed by list identity and scoped to one day."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._pools: "OrderedDict[str, CatalogPool]" = OrderedDict()

    @staticmethod
    def key(
        source_id: str,
        list_id: str,
        media_type: str,
        params: Optional[Dict[str, Any]] = None,
    ) -> str:
        """Identity of one list as the user configured it.

        Params are part of the key: two rows differing only by ``period`` are
        different lists and must not share a pool.
        """

        base = f"{source_id}:{list_id}:{media_type}"
        if not params:
            return base
        rendered = ",".join(f"{k}={params[k]}" for k in sorted(params))
        return f"{base}:{rendered}"

    def get_or_create(self, key: str, today: Optional[date] = None) -> CatalogPool:
        today = today or date.today()
        with self._lock:
            pool = self._pools.get(key)
            if pool is not None and not pool.is_stale(today):
                self._pools.move_to_end(key)
                return pool

            pool = CatalogPool(key, today)
            self._pools[key] = pool
            self._pools.move_to_end(key)
            while len(self._pools) > MAX_POOLS:
                evicted_key, _ = self._pools.popitem(last=False)
                log.debug("catalog_pool_evicted", key=evicted_key)
            return pool

    def drop_prefix(self, prefix: str) -> int:
        with self._lock:
            keys = [k for k in self._pools if k.startswith(prefix)]
            for key in keys:
                self._pools.pop(key, None)
        return len(keys)

    def drop_source(self, source_id: str) -> int:
        return self.drop_prefix(f"{source_id}:")

    def clear(self) -> None:
        with self._lock:
            self._pools.clear()

    def stats(self) -> Dict[str, Any]:
        with self._lock:
            return {
                "pools": len(self._pools),
                "items": sum(len(p.items) for p in self._pools.values()),
            }


__all__ = [
    "MAX_POOLS",
    "MAX_POOL_ITEMS",
    "MAX_UPSTREAM_PAGES",
    "CatalogPool",
    "CatalogPoolCache",
]
