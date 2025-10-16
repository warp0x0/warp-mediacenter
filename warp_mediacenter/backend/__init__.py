"""Backend public interfaces."""

from .player import PlayerController, PlayRequest, PlaybackState
from .player.subtitles import SubtitleQuery, SubtitleResult
from .resource_management import (
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
    "ResourceManager",
    "ResourceProfile",
    "SystemSnapshot",
    "get_resource_manager",
]
