"""The in-process source interface.

Deliberately *not* the plugin contract.  A plugin talks JSON across a boundary
and is reached through ``PluginCatalogSource``; a built-in is ordinary Python and
may hold ``InformationProviders``.  Keeping the two apart means the built-ins pay
none of the serialisation cost, and the plugin adapter is the only place that has
to reason about envelopes and timeouts.

``fetch_page`` is page-based for the same reason the plugin contract is: the
service owns offsets and pooling, a source only ever answers "give me page N".
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Mapping, Optional, Protocol, Sequence

from warp_mediacenter.backend.plugins.contracts.catalog import CatalogListDef

KIND_BUILTIN = "builtin"
KIND_LEGACY = "legacy"
KIND_PLUGIN = "plugin"


@dataclass
class SourcePage:
    """One page from a source, already in client wire shape.

    ``items`` are dicts straight from ``catalog.normalize`` — not contract
    objects — because built-ins produce them natively and the plugin adapter
    converts once on the way in.  ``has_more`` is authoritative; ``total`` is a
    display hint that may be ``None``.
    """

    items: List[Dict[str, Any]] = field(default_factory=list)
    has_more: bool = False
    total: Optional[int] = None


class CatalogSource(Protocol):
    """What ``CatalogService`` needs from anything that publishes lists."""

    id: str
    label: str
    kind: str
    icon: Optional[str]

    def list_definitions(self) -> Sequence[CatalogListDef]:
        """Every list this source publishes.  Cheap and cacheable."""
        ...

    def fetch_page(
        self,
        list_id: str,
        *,
        media_type: str,
        params: Mapping[str, Any],
        page: int,
        page_size: int,
    ) -> SourcePage:
        """One page of one list.  ``page`` is 1-based."""
        ...


__all__ = [
    "KIND_BUILTIN",
    "KIND_LEGACY",
    "KIND_PLUGIN",
    "CatalogSource",
    "SourcePage",
]
