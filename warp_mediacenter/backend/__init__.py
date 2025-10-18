"""Backend public interfaces."""

from warp_mediacenter.backend.player import (
    PlayRequest,
    PlaybackState,
    PlayerController,
)
from warp_mediacenter.backend.player.subtitles import (
    SubtitleQuery,
    SubtitleResult,
)
from warp_mediacenter.backend.plugins import (
    PluginError,
    PluginManifest,
    PluginManager,
)
from warp_mediacenter.backend.resource_management import (
    ResourceManager,
    ResourceProfile,
    SystemSnapshot,
    get_resource_manager,
)

__all__ = [
    "PlayerController",
    "PlayRequest",
    "PlaybackState",
    "SubtitleQuery",
    "SubtitleResult",
    "PluginError",
    "PluginManifest",
    "PluginManager",
    "ResourceManager",
    "ResourceProfile",
    "SystemSnapshot",
    "get_resource_manager",
]
