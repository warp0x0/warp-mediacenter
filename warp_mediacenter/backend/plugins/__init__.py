"""Plugin management interfaces."""

from warp_mediacenter.backend.plugins.exceptions import PluginError
from warp_mediacenter.backend.plugins.manifest import PluginManifest
from warp_mediacenter.backend.plugins.manager import PluginManager

__all__ = [
    "PluginError",
    "PluginManifest",
    "PluginManager",
]
