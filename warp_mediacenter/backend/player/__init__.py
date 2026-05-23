"""VLC-based playback primitives and subtitle orchestration."""

from warp_mediacenter.backend.player.adapter import (
    AudioTrack,
    PlayerAdapter,
    PlaybackState,
    SubtitleTrackInfo,
)
from warp_mediacenter.backend.player.controller import (
    PlayRequest,
    PlayerController,
)
from warp_mediacenter.backend.player.exceptions import PlayerError, SubtitleError
from warp_mediacenter.backend.player.http_adapter import HTTPAdapter
from warp_mediacenter.backend.player.playlist import Playlist, PlaylistItem
from warp_mediacenter.backend.player.service import PlaybackService
from warp_mediacenter.backend.player.subtitles.models import (
    SubtitleQuery,
    SubtitleResult,
)
from warp_mediacenter.backend.player.vlc_adapter import VLCAdapter

__all__ = [
    "AudioTrack",
    "HTTPAdapter",
    "PlayerAdapter",
    "PlayerController",
    "PlaybackService",
    "PlaybackState",
    "PlayRequest",
    "Playlist",
    "PlaylistItem",
    "PlayerError",
    "SubtitleError",
    "SubtitleQuery",
    "SubtitleResult",
    "SubtitleTrackInfo",
    "VLCAdapter",
]
