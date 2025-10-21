"""Backend public interfaces with lazy loading to avoid circular imports."""

from __future__ import annotations

import importlib
from typing import TYPE_CHECKING, Any

__all__ = [
    "PlayRequest",
    "PlaybackState",
    "PlayerController",
    "PluginError",
    "PluginManifest",
    "PluginManager",
    "ResourceManager",
    "ResourceProfile",
    "SubtitleQuery",
    "SubtitleResult",
    "SystemSnapshot",
    "get_resource_manager",
]

_MODULE_EXPORTS = {
    "player": {
        "PlayRequest",
        "PlaybackState",
        "PlayerController",
    },
    "player.subtitles": {
        "SubtitleQuery",
        "SubtitleResult",
    },
    "plugins": {
        "PluginError",
        "PluginManifest",
        "PluginManager",
    },
    "resource_management": {
        "ResourceManager",
        "ResourceProfile",
        "SystemSnapshot",
        "get_resource_manager",
    },
}

if TYPE_CHECKING:  # pragma: no cover - for static analysis only
    from .player import PlayRequest, PlaybackState, PlayerController
    from .player.subtitles import SubtitleQuery, SubtitleResult
    from .plugins import PluginError, PluginManifest, PluginManager
    from .resource_management import (
        ResourceManager,
        ResourceProfile,
        SystemSnapshot,
        get_resource_manager,
    )


def __getattr__(name: str) -> Any:
    for module_name, symbols in _MODULE_EXPORTS.items():
        if name in symbols:
            module = importlib.import_module(f"{__name__}.{module_name}")
            value = getattr(module, name)
            globals()[name] = value
            return value
    raise AttributeError(f"module '{__name__}' has no attribute '{name}'")


def __dir__() -> list[str]:
    exported = set(__all__)
    for symbols in _MODULE_EXPORTS.values():
        exported.update(symbols)
    exported.update(globals().keys())
    return sorted(exported)
