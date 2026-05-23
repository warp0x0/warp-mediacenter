"""Abstract player adapter interface and concrete implementations.

The PlayerAdapter protocol decouples playback control from the specific
media engine (VLC, ExoPlayer, HTML5, etc.).  Each platform provides its own
adapter that implements the protocol, allowing the PlaybackService to remain
entirely player-agnostic.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Callable, List, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.player.exceptions import PlayerError
from warp_mediacenter.backend.player.vlc_paths import resolve_vlc_runtime

log = get_logger(__name__)


@dataclass(slots=True)
class AudioTrack:
    track_id: int
    name: str


@dataclass(slots=True)
class SubtitleTrackInfo:
    track_id: int
    name: str
    is_external: bool = False


@dataclass(slots=True)
class PlaybackState:
    title: str
    media_kind: str
    source: str
    state: str
    position_ms: int
    duration_ms: int
    volume: int
    subtitle_path: Optional[str]
    is_stream: bool
    media_folder: Optional[str]
    rate: float = 1.0
    audio_track_id: Optional[int] = None
    subtitle_track_id: Optional[int] = None
    started_at: datetime = field(default_factory=datetime.utcnow)


class PlayerAdapter(ABC):
    """Abstract interface for media playback operations.

    Concrete implementations wrap specific players (VLC, ExoPlayer via HTTP,
    HTML5 video, etc.) and translate the abstract operations into player-
    specific calls.
    """

    @abstractmethod
    def play(self, source: str, *, is_stream: bool = False, start_paused: bool = False) -> None:
        """Load and start playback of the given source."""

    @abstractmethod
    def pause(self) -> None:
        """Pause playback."""

    @abstractmethod
    def resume(self) -> None:
        """Resume playback."""

    @abstractmethod
    def stop(self) -> None:
        """Stop playback."""

    @abstractmethod
    def seek_ms(self, milliseconds: int) -> None:
        """Seek to the given position in milliseconds."""

    @abstractmethod
    def set_volume(self, volume: int) -> None:
        """Set audio volume (0-100)."""

    @abstractmethod
    def toggle_mute(self) -> None:
        """Toggle audio mute."""

    @abstractmethod
    def set_rate(self, rate: float) -> None:
        """Set playback rate (0.25-4.0)."""

    @abstractmethod
    def get_rate(self) -> float:
        """Get current playback rate."""

    @abstractmethod
    def get_position_ms(self) -> int:
        """Get current playback position in milliseconds."""

    @abstractmethod
    def get_duration_ms(self) -> int:
        """Get total media duration in milliseconds."""

    @abstractmethod
    def get_volume(self) -> int:
        """Get current audio volume (0-100)."""

    # ------------------------------------------------------------------
    # Audio track selection
    # ------------------------------------------------------------------
    @abstractmethod
    def list_audio_tracks(self) -> List[AudioTrack]:
        """List available audio tracks."""

    @abstractmethod
    def set_audio_track(self, track_id: int) -> None:
        """Switch to the given audio track."""

    @abstractmethod
    def get_audio_track(self) -> Optional[int]:
        """Get current audio track ID."""

    # ------------------------------------------------------------------
    # Subtitle track selection
    # ------------------------------------------------------------------
    @abstractmethod
    def list_subtitle_tracks(self) -> List[SubtitleTrackInfo]:
        """List available subtitle tracks (embedded + external)."""

    @abstractmethod
    def set_subtitle_track(self, track_id: int) -> None:
        """Switch to the given subtitle track."""

    @abstractmethod
    def get_subtitle_track(self) -> Optional[int]:
        """Get current subtitle track ID."""

    @abstractmethod
    def disable_subtitles(self) -> None:
        """Disable subtitle display."""

    @abstractmethod
    def set_subtitle_delay(self, delay_ms: int) -> None:
        """Set subtitle delay in milliseconds."""

    @abstractmethod
    def get_subtitle_delay(self) -> int:
        """Get current subtitle delay in milliseconds."""

    @abstractmethod
    def load_external_subtitle(self, path: str) -> bool:
        """Load an external subtitle file. Returns True on success."""

    # ------------------------------------------------------------------
    # State
    # ------------------------------------------------------------------
    @abstractmethod
    def get_state(self) -> str:
        """Get current playback state string."""

    @abstractmethod
    def on_state_change(self, callback: Callable[[str], None]) -> None:
        """Register a callback for playback state changes."""

    @abstractmethod
    def close(self) -> None:
        """Release player resources."""
