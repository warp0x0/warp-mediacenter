"""VLC-based player adapter implementation.

Wraps python-vlc to implement the PlayerAdapter protocol.  Used when the
backend runs on a machine with a display and VLC installed (desktop mode).
"""

from __future__ import annotations

import threading
from typing import Callable, List, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.player.adapter import (
    AudioTrack,
    PlayerAdapter,
    SubtitleTrackInfo,
)
from warp_mediacenter.backend.player.exceptions import PlayerError
from warp_mediacenter.backend.player.vlc_paths import resolve_vlc_runtime

log = get_logger(__name__)


class VLCAdapter(PlayerAdapter):
    """VLC media player adapter implementing PlayerAdapter."""

    def __init__(self, vlc_root: Optional[str] = None) -> None:
        runtime = resolve_vlc_runtime(vlc_root)
        if runtime is None:
            log.warning("vlc_runtime_not_configured", extra={"hint": "Using system VLC installation"})
        try:
            import vlc  # type: ignore
        except Exception as exc:
            raise PlayerError(f"python-vlc import failed: {exc}") from exc

        self._vlc = vlc
        self._instance = vlc.Instance()
        self._player = self._instance.media_player_new()
        self._event_manager = self._player.event_manager()
        self._state_callback: Optional[Callable[[str], None]] = None
        self._subtitle_delay_ms: int = 0
        self._external_subtitle_path: Optional[str] = None
        self._register_events()

    # ------------------------------------------------------------------
    # Playback lifecycle
    # ------------------------------------------------------------------
    def play(self, source: str, *, is_stream: bool = False, start_paused: bool = False) -> None:
        if is_stream:
            media = self._instance.media_new(source)
        else:
            from pathlib import Path
            path = Path(source)
            if not path.exists():
                raise PlayerError(f"Media path not found: {source}")
            media = self._instance.media_new_path(str(path))

        self._player.set_media(media)
        if start_paused:
            self._player.set_pause(1)
        else:
            self._player.play()

    def pause(self) -> None:
        self._player.pause()

    def resume(self) -> None:
        self._player.play()

    def stop(self) -> None:
        self._player.stop()

    def seek_ms(self, milliseconds: int) -> None:
        self._player.set_time(milliseconds)

    def set_volume(self, volume: int) -> None:
        self._player.audio_set_volume(volume)

    def toggle_mute(self) -> None:
        self._player.audio_toggle_mute()

    # ------------------------------------------------------------------
    # Playback speed
    # ------------------------------------------------------------------
    def set_rate(self, rate: float) -> None:
        rate = max(0.25, min(4.0, rate))
        self._player.set_rate(rate)

    def get_rate(self) -> float:
        try:
            return float(self._player.get_rate())
        except Exception:
            return 1.0

    # ------------------------------------------------------------------
    # Position / duration / volume
    # ------------------------------------------------------------------
    def get_position_ms(self) -> int:
        try:
            return max(self._player.get_time(), 0)
        except Exception:
            return 0

    def get_duration_ms(self) -> int:
        try:
            return max(self._player.get_length(), 0)
        except Exception:
            return 0

    def get_volume(self) -> int:
        try:
            return self._player.audio_get_volume()
        except Exception:
            return 50

    # ------------------------------------------------------------------
    # Audio track selection
    # ------------------------------------------------------------------
    def list_audio_tracks(self) -> List[AudioTrack]:
        tracks: List[AudioTrack] = []
        try:
            descriptions = self._player.audio_get_track_description()
            if descriptions:
                for track_id, name in descriptions:
                    if track_id >= 0:
                        tracks.append(AudioTrack(track_id=track_id, name=name or f"Track {track_id}"))
        except Exception:
            pass
        return tracks

    def set_audio_track(self, track_id: int) -> None:
        self._player.audio_set_track(track_id)

    def get_audio_track(self) -> Optional[int]:
        try:
            return self._player.audio_get_track()
        except Exception:
            return None

    # ------------------------------------------------------------------
    # Subtitle track selection
    # ------------------------------------------------------------------
    def list_subtitle_tracks(self) -> List[SubtitleTrackInfo]:
        tracks: List[SubtitleTrackInfo] = []
        try:
            descriptions = self._player.video_get_spu_description()
            if descriptions:
                for track_id, name in descriptions:
                    if track_id >= 0:
                        tracks.append(SubtitleTrackInfo(
                            track_id=track_id,
                            name=name or f"Track {track_id}",
                            is_external=False,
                        ))
        except Exception:
            pass

        if self._external_subtitle_path:
            from pathlib import Path
            name = Path(self._external_subtitle_path).name
            tracks.append(SubtitleTrackInfo(
                track_id=-1,
                name=f"External: {name}",
                is_external=True,
            ))

        return tracks

    def set_subtitle_track(self, track_id: int) -> None:
        self._player.video_set_spu(track_id)

    def get_subtitle_track(self) -> Optional[int]:
        try:
            return self._player.video_get_spu()
        except Exception:
            return None

    def disable_subtitles(self) -> None:
        self._player.video_set_spu(-1)

    def set_subtitle_delay(self, delay_ms: int) -> None:
        self._subtitle_delay_ms = delay_ms
        self._player.video_set_spu_delay(delay_ms * 1000)

    def get_subtitle_delay(self) -> int:
        return self._subtitle_delay_ms

    def load_external_subtitle(self, path: str) -> bool:
        result = self._player.video_set_subtitle_file(path)
        if result == -1:
            return False
        self._external_subtitle_path = path
        if self._subtitle_delay_ms:
            self._player.video_set_spu_delay(self._subtitle_delay_ms * 1000)
        return True

    # ------------------------------------------------------------------
    # State
    # ------------------------------------------------------------------
    def get_state(self) -> str:
        try:
            state = self._player.get_state()
            return state.name if hasattr(state, "name") else str(state)
        except Exception:
            return "unknown"

    def on_state_change(self, callback: Callable[[str], None]) -> None:
        self._state_callback = callback

    def close(self) -> None:
        try:
            self._player.stop()
            self._player.release()
        except Exception:
            pass

    # ------------------------------------------------------------------
    # Internal
    # ------------------------------------------------------------------
    def _register_events(self) -> None:
        events = [
            self._vlc.EventType.MediaPlayerPlaying,
            self._vlc.EventType.MediaPlayerPaused,
            self._vlc.EventType.MediaPlayerStopped,
            self._vlc.EventType.MediaPlayerEndReached,
        ]
        for event in events:
            self._event_manager.event_attach(event, self._handle_event)

    def _handle_event(self, event) -> None:
        state = self.get_state()
        if self._state_callback:
            self._state_callback(state)
