"""Plugin management interfaces."""

from warp_mediacenter.backend.plugins.exceptions import PluginError
from warp_mediacenter.backend.plugins.manager import PluginManager
from warp_mediacenter.backend.plugins.manifest import PluginManifest, plugin_slug
from warp_mediacenter.backend.plugins.registry import PluginRecord, PluginRegistry

__all__ = [
    "PluginError",
    "PluginManager",
    "PluginManifest",
    "PluginRecord",
    "PluginRegistry",
    "plugin_slug",
]
