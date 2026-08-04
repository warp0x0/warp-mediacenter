"""Category facades — the app-facing side of the plugin system.

One service per plugin category.  Routes talk to these, never to
``PluginManager`` directly, so "which plugin is active, and what happens when
none is" is decided in exactly one place per category.

``tracker`` and ``catalog`` exist today; ``provider`` and ``skin`` follow the same
shape when their passes land.

The two differ in one structural way worth knowing before reading either.
``tracker`` is an *exclusive* category: one plugin is active, and the facade
resolves to it, to the built-in Trakt integration, or to nothing.  ``catalog`` is
not: every enabled catalog plugin contributes lists at once, alongside the
built-in TMDb source, and the facade aggregates rather than resolves.  A plugin
may still *shadow* a built-in by name, which is how the Trakt catalog plugin
replaces the in-tree Trakt integration without anyone migrating a saved row.
"""

from warp_mediacenter.backend.plugins.services.catalog_cache import (
    CatalogPool,
    CatalogPoolCache,
)
from warp_mediacenter.backend.plugins.services.catalog_service import CatalogService
from warp_mediacenter.backend.plugins.services.legacy_trakt import LegacyTraktTracker
from warp_mediacenter.backend.plugins.services.tracker_cache import TrackerCache
from warp_mediacenter.backend.plugins.services.tracker_service import (
    MODE_LEGACY,
    MODE_NONE,
    MODE_PLUGIN,
    TrackerService,
)

__all__ = [
    "MODE_LEGACY",
    "MODE_NONE",
    "MODE_PLUGIN",
    "CatalogPool",
    "CatalogPoolCache",
    "CatalogService",
    "LegacyTraktTracker",
    "TrackerCache",
    "TrackerService",
]
