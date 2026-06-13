"""High-level player controller — coordinator for PlaybackService + PlayerAdapter.

This module provides the legacy ``PlayerController`` API for backwards
compatibility while delegating all work to the player-agnostic
:class:`PlaybackService` and a concrete :class:`PlayerAdapter`.

Desktop mode uses :class:`VLCAdapter`.  Thin-client mode (Phase 4) will use
:class:`HTTPAdapter`.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Dict, List, Mapping, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.information_handlers.trakt_manager import TraktManager
from warp_mediacenter.backend.player.adapter import (
    AudioTrack,
    PlaybackState,
    SubtitleTrackInfo,
)
from warp_mediacenter.backend.player.exceptions import PlayerError, SubtitleError
from warp_mediacenter.backend.player.http_adapter import HTTPAdapter
from warp_mediacenter.backend.player.playlist import Playlist, PlaylistItem
from warp_mediacenter.backend.player.service import PlaybackService
from warp_mediacenter.backend.player.subtitles.models import SubtitleQuery, SubtitleResult
from warp_mediacenter.backend.player.subtitles.service import SubtitleService
from warp_mediacenter.backend.player.vlc_adapter import VLCAdapter
from warp_mediacenter.backend.player.vlc_subprocess_adapter import SubprocessVLCAdapter

log = get_logger(__name__)


@dataclass(slots=True)
class PlayRequest:
    source: str
    title: str
    media_kind: str
    media_folder: Optional[Path] = None
    season: Optional[int] = None
    episode: Optional[int] = None
    year: Optional[int] = None
    language: str = "eng"
    start_paused: bool = False
    is_stream: bool = False
    auto_subtitles: bool = True
    resume_from_last_position: bool = True
    tmdb_id: Optional[str] = None
    media_payload: Optional[Mapping[str, Any]] = None
    show_payload: Optional[Mapping[str, Any]] = None
    source_type: str = "local"


class PlayerController:
    """Convenience façade that wraps PlaybackService + PlayerAdapter.

    Provides the same public API as the original PlayerController but
    delegates all work to the player-agnostic service layer.
    """

    def __init__(
        self,
        vlc_root: Optional[str] = None,
        *,
        mode: str = "desktop",
        subtitle_service: Optional[SubtitleService] = None,
        trakt_manager: Optional[TraktManager] = None,
    ) -> None:
        if mode == "desktop":
            # Prefer the subprocess adapter — it uses the full system VLC binary
            # which has better HTTPS/TLS support than the embedded libvlc used by
            # python-vlc.  Fall back to the python-vlc binding adapter if the
            # system VLC binary cannot be located.
            try:
                player: PlayerAdapter = SubprocessVLCAdapter()
                log.info("player_using_subprocess_vlc")
            except PlayerError as exc:
                log.warning("subprocess_vlc_unavailable_trying_python_vlc", reason=str(exc))
                player = VLCAdapter(vlc_root=vlc_root)
        elif mode == "thin_client":
            player = HTTPAdapter()
        else:
            raise ValueError(f"Unknown player mode: {mode}. Use 'desktop' or 'thin_client'")

        self._service = PlaybackService(
            player,
            subtitle_service=subtitle_service,
            trakt_manager=trakt_manager,
        )

    # ------------------------------------------------------------------
    # Playback lifecycle
    # ------------------------------------------------------------------
    def play(self, request: PlayRequest) -> None:
        self._service.play(
            source=request.source,
            title=request.title,
            media_kind=request.media_kind,
            media_folder=request.media_folder,
            season=request.season,
            episode=request.episode,
            year=request.year,
            language=request.language,
            start_paused=request.start_paused,
            is_stream=request.is_stream,
            auto_subtitles=request.auto_subtitles,
            resume_from_last_position=request.resume_from_last_position,
            tmdb_id=request.tmdb_id,
            media_payload=request.media_payload,
            show_payload=request.show_payload,
            source_type=request.source_type,
        )

    def pause(self) -> None:
        self._service.pause()

    def resume(self) -> None:
        self._service.resume()

    def stop(self) -> None:
        self._service.stop()

    def seek_ms(self, milliseconds: int) -> None:
        self._service.seek_ms(milliseconds)

    def set_volume(self, volume: int) -> None:
        self._service.set_volume(volume)

    def toggle_mute(self) -> None:
        self._service.toggle_mute()

    # ------------------------------------------------------------------
    # Playback speed
    # ------------------------------------------------------------------
    def set_rate(self, rate: float) -> None:
        self._service.set_rate(rate)

    def get_rate(self) -> float:
        return self._service.get_rate()

    # ------------------------------------------------------------------
    # Audio track selection
    # ------------------------------------------------------------------
    def list_audio_tracks(self) -> List[AudioTrack]:
        return self._service.list_audio_tracks()

    def set_audio_track(self, track_id: int) -> None:
        self._service.set_audio_track(track_id)

    def current_audio_track(self) -> Optional[int]:
        return self._service.current_audio_track()

    # ------------------------------------------------------------------
    # Subtitle track listing & switching
    # ------------------------------------------------------------------
    def list_subtitle_tracks(self) -> List[SubtitleTrackInfo]:
        return self._service.list_subtitle_tracks()

    def set_subtitle_track(self, track_id: int) -> None:
        self._service.set_subtitle_track(track_id)

    def disable_subtitles(self) -> None:
        self._service.disable_subtitles()

    def current_subtitle_track(self) -> Optional[int]:
        return self._service.current_subtitle_track()

    # ------------------------------------------------------------------
    # Subtitle delay
    # ------------------------------------------------------------------
    def set_subtitle_delay(self, delay_ms: int) -> None:
        self._service.set_subtitle_delay(delay_ms)

    def get_subtitle_delay(self) -> int:
        return self._service.get_subtitle_delay()

    def adjust_subtitle_delay(self, delta_ms: int) -> int:
        return self._service.adjust_subtitle_delay(delta_ms)

    # ------------------------------------------------------------------
    # Subtitle discovery & download
    # ------------------------------------------------------------------
    def list_subtitles(self, query: SubtitleQuery) -> List[SubtitleResult]:
        return self._service.search_subtitles(query)

    def set_subtitle(self, result: SubtitleResult, request: PlayRequest) -> None:
        self._service.download_and_apply_subtitle(
            result,
            media_folder=request.media_folder,
            source=request.source,
            is_stream=request.is_stream,
        )

    # ------------------------------------------------------------------
    # Playlist
    # ------------------------------------------------------------------
    @property
    def playlist(self) -> Playlist:
        return self._service.playlist

    def play_next(self) -> bool:
        return self._service.play_next()

    def play_previous(self) -> bool:
        return self._service.play_previous()

    # ------------------------------------------------------------------
    # State accessors
    # ------------------------------------------------------------------
    def now_playing(self) -> Optional[PlaybackState]:
        return self._service.now_playing()

    # ------------------------------------------------------------------
    # Callbacks
    # ------------------------------------------------------------------
    def on_state_change(self, callback: Callable[[PlaybackState], None]) -> None:
        self._service.on_state_change(callback)

    # ------------------------------------------------------------------
    # Stream preloading
    # ------------------------------------------------------------------
    def preload_stream(self, url: str) -> None:
        """Start pre-downloading a remote stream URL without launching VLC.

        Only effective in desktop mode (SubprocessVLCAdapter).  A no-op for
        other adapter types.
        """
        player = self._service._player
        if isinstance(player, SubprocessVLCAdapter):
            player.preload(url)

    def preload_status(self) -> dict:
        """Return current preload progress (percent, bytes, etc.)."""
        player = self._service._player
        if isinstance(player, SubprocessVLCAdapter):
            return player.preload_status()
        return {
            "url": "",
            "active": False,
            "bytes_downloaded": 0,
            "total_size": 0,
            "percent": 0.0,
            "download_complete": False,
        }

    # ------------------------------------------------------------------
    # Player mode
    # ------------------------------------------------------------------
    @property
    def player_mode(self) -> str:
        """Return ``'desktop'`` when using local VLC, ``'thin_client'`` otherwise."""
        from warp_mediacenter.backend.player.vlc_adapter import VLCAdapter
        player = self._service._player
        if isinstance(player, (SubprocessVLCAdapter, VLCAdapter)):
            return "desktop"
        return "thin_client"

    # ------------------------------------------------------------------
    # Cleanup
    # ------------------------------------------------------------------
    def close(self) -> None:
        self._service.close()
