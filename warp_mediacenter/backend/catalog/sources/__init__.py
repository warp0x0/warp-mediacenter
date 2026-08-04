"""Catalog sources — one module per thing that publishes browsable lists."""

from warp_mediacenter.backend.catalog.sources.base import (
    KIND_BUILTIN,
    KIND_LEGACY,
    KIND_PLUGIN,
    CatalogSource,
    SourcePage,
)
from warp_mediacenter.backend.catalog.sources.builtin_personal import (
    BuiltinPersonalSource,
)
from warp_mediacenter.backend.catalog.sources.builtin_tmdb import BuiltinTmdbSource
from warp_mediacenter.backend.catalog.sources.legacy_trakt import LegacyTraktSource
from warp_mediacenter.backend.catalog.sources.plugin_source import PluginCatalogSource

__all__ = [
    "KIND_BUILTIN",
    "KIND_LEGACY",
    "KIND_PLUGIN",
    "BuiltinPersonalSource",
    "BuiltinTmdbSource",
    "CatalogSource",
    "LegacyTraktSource",
    "PluginCatalogSource",
    "SourcePage",
]
