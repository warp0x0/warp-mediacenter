"""Category facades — the app-facing side of the plugin system.

One service per plugin category.  Routes talk to these, never to
``PluginManager`` directly, so "which plugin is active, and what happens when
none is" is decided in exactly one place per category.

Only ``tracker`` exists today; ``provider``, ``catalog`` and ``skin`` follow the
same shape when their passes land.
"""

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
    "LegacyTraktTracker",
    "TrackerCache",
    "TrackerService",
]
