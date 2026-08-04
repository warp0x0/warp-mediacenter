"""The adapter between an installed catalog plugin and the source interface.

Everything JSON-shaped stops here.  Above this line ``CatalogService`` deals in
plain dicts and ``SourcePage``; below it, envelopes, capability gates, timeouts
and a plugin that may return anything at all.

Two rules borrowed from ``TrackerService``, for the same reasons:

* **Capability-gate before dispatch.**  A plugin that does not declare
  ``catalog.paginate`` is never asked for page 2, whatever its list defs claim.
  Checking here means a mis-declared list costs one short row, not a loop.
* **Never raise.**  A failing plugin yields an empty page and a log line.  An
  exception escaping into a route would take out the whole Movies tab, and one
  broken catalog should cost the user one row.
"""

from __future__ import annotations

from typing import Any, Dict, List, Mapping, Optional, Sequence

from warp_mediacenter.backend.catalog.normalize import media_block
from warp_mediacenter.backend.catalog.sources.base import KIND_PLUGIN, SourcePage
from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.plugins.contracts.catalog import (
    ACTION_CAPABILITY,
    CatalogAction,
    CatalogCapability,
    CatalogItem,
    CatalogListDef,
    fetch_payload,
    parse_catalog_lists,
    parse_catalog_page,
)
from warp_mediacenter.backend.plugins.contracts.common import (
    ErrorCode,
    err,
    error_code,
    is_ok,
    response_data,
)

log = get_logger(__name__)


def catalog_item_to_row(item: CatalogItem, media_type: str, source_id: str) -> Dict[str, Any]:
    """Project a contract item onto the wire shape the client renders.

    The counterpart of ``TrackerService._cw_item_to_catalog_dict``.  Items land
    here with ids and little else — artwork and overview are filled in afterwards
    by the host's TMDb enrichment — so the fields it cannot know are set to
    ``None`` rather than omitted, keeping the shape identical to a TMDb row.
    """

    media = item.media
    ids: Dict[str, Any] = dict(media.ids)
    tmdb_id = ids.get("tmdb")
    title = media.title or ""

    row: Dict[str, Any] = {
        "id": str(tmdb_id) if tmdb_id is not None else None,
        "title": title,
        "type": media_type,
        "source_tag": source_id,
        "year": media.year,
        "overview": item.overview,
        "poster_path": item.artwork.get("poster"),
        "backdrop_path": item.artwork.get("backdrop"),
        "rating": item.rating,
        "genres": list(item.genres),
        "tmdb_id": str(tmdb_id) if tmdb_id is not None else None,
        "trakt_id": ids.get("trakt") or ids.get("slug"),
        "extra": {"ids": {k: str(v) for k, v in ids.items()}},
    }
    row["media"] = media_block(row)
    return row


class PluginCatalogSource:
    """Wraps one installed, enabled catalog plugin."""

    kind = KIND_PLUGIN

    def __init__(self, record: Any, manager: Any) -> None:
        self._record = record
        self._manager = manager
        self.id = record.plugin_id
        self.label = record.name or record.plugin_id
        self.icon = getattr(record.manifest, "icon", None)

    @property
    def record(self) -> Any:
        return self._record

    @property
    def shadows(self) -> Optional[str]:
        """The built-in source this plugin replaces, if it claims one.

        Read from the manifest's free-form ``metadata`` block rather than a
        dedicated field, so declaring a replacement needs no manifest schema
        change and an unknown value is simply ignored.
        """

        metadata = getattr(self._record.manifest, "metadata", None)
        if not isinstance(metadata, Mapping):
            return None
        value = metadata.get("shadows")
        return str(value) if value else None

    # ------------------------------------------------------------------
    # Dispatch
    # ------------------------------------------------------------------

    def _invoke(
        self,
        action: str,
        payload: Optional[Dict[str, Any]] = None,
        *,
        timeout: Optional[float] = None,
    ) -> Dict[str, Any]:
        capability = ACTION_CAPABILITY.get(action)
        if capability is not None and not self._record.supports(capability):
            return err(
                ErrorCode.UNSUPPORTED_ACTION,
                f"Plugin '{self.id}' does not declare '{capability}'",
            )
        return self._manager.execute(self.id, action, payload or {}, timeout=timeout)

    def supports_pagination(self) -> bool:
        return bool(self._record.supports(CatalogCapability.PAGINATE))

    # ------------------------------------------------------------------
    # Source interface
    # ------------------------------------------------------------------

    def list_definitions(self) -> Sequence[CatalogListDef]:
        result = self._invoke(CatalogAction.LISTS)
        if not is_ok(result):
            log.warning(
                "catalog_plugin_lists_failed",
                plugin_id=self.id,
                error=error_code(result),
            )
            return []

        defs = parse_catalog_lists(response_data(result))
        if not self.supports_pagination():
            # The manifest is the authority.  A list claiming to paginate under a
            # plugin that never declared the capability would have the host ask
            # for pages it will not dispatch, which reads to the user as a row
            # that silently stops loading.
            for definition in defs:
                definition.supports_pagination = False
        return defs

    def fetch_page(
        self,
        list_id: str,
        *,
        media_type: str,
        params: Mapping[str, Any],
        page: int,
        page_size: int,
    ) -> SourcePage:
        if page > 1 and not self.supports_pagination():
            return SourcePage(items=[], has_more=False)

        result = self._invoke(
            CatalogAction.FETCH,
            fetch_payload(
                list_id,
                media_type=media_type,
                params=params,
                page=page,
                page_size=page_size,
            ),
        )
        if not is_ok(result):
            log.warning(
                "catalog_plugin_fetch_failed",
                plugin_id=self.id,
                list_id=list_id,
                page=page,
                error=error_code(result),
            )
            return SourcePage(items=[], has_more=False)

        parsed = parse_catalog_page(response_data(result))
        rows: List[Dict[str, Any]] = [
            catalog_item_to_row(item, media_type, self.id) for item in parsed.items
        ]

        has_more = parsed.has_more and self.supports_pagination()
        # An empty page that still claims more would spin the growth loop with
        # nothing to show for it; treat it as the end regardless of the claim.
        if not rows:
            has_more = False

        return SourcePage(items=rows, has_more=has_more, total=parsed.total)

    def clear_cache(self, scope: str = "all") -> None:
        self._invoke(CatalogAction.CACHE_CLEAR, {"scope": scope})


__all__ = ["PluginCatalogSource", "catalog_item_to_row"]
