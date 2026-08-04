"""Catalog sources — the things that publish browsable lists.

A *source* is anything that can enumerate lists and return a page of one:
the built-in TMDb integration, the built-in (legacy) Trakt integration, or an
installed catalog plugin.  ``CatalogService``
(``backend/plugins/services/catalog_service.py``) is the only caller; routes talk
to the service, never to a source directly.

The distinction from ``backend/plugins/contracts/catalog.py`` matters: that
module is the *plugin* boundary and is JSON-only, while sources here are ordinary
in-process Python and may hold on to ``InformationProviders``.  A plugin reaches
the service through ``PluginCatalogSource``, which is the adapter between the two.
"""

from warp_mediacenter.backend.catalog.normalize import (
    catalog_item_to_dict,
    media_block,
    tmdb_result_to_dict,
)

__all__ = ["catalog_item_to_dict", "media_block", "tmdb_result_to_dict"]
