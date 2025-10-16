"""Plugin management interfaces."""

from .exceptions import PluginError
from .manifest import PluginManifest
from .manager import PluginManager

__all__ = [
    "PluginError",
    "PluginManifest",
    "PluginManager",
]
