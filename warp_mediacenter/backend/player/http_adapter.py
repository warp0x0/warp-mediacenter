"""HTTP-based player adapter stub for thin clients.

This adapter does not control playback directly.  Instead it exposes REST
endpoints that a remote client (Android TV / Web) calls to control its own
player (ExoPlayer / HTML5 video).

The adapter acts as a bridge: PlaybackService calls adapter methods, which
translate into HTTP calls to the thin client, or vice versa.

Full implementation is deferred to Phase 4 (API layer).  This stub raises
NotImplementedError so that desktop mode is the only working path until the
API server is built.
"""

from __future__ import annotations

from typing import Callable, List, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.player.adapter import (
    AudioTrack,
    PlayerAdapter,
    SubtitleTrackInfo,
)

log = get_logger(__name__)


class HTTPAdapter(PlayerAdapter):
    """HTTP-based player adapter for thin clients.

    Used when the backend runs as a headless server and playback is handled
    by a remote client (Android TV ExoPlayer, web browser, etc.).

    All methods are stubs until Phase 4 (API layer) is implemented.
    """

    def __init__(
        self,
        *,
        client_url: str = "http://localhost:8080",
        api_base: str = "/api/v1/playback",
    ) -> None:
        self._client_url = client_url
        self._api_base = api_base
        self._state_callback: Optional[Callable[[str], None]] = None
        log.warning(
            "http_adapter_stub",
            extra={"hint": "HTTPAdapter is a stub. Use VLCAdapter for desktop mode."},
        )

    def play(self, source: str, *, is_stream: bool = False, start_paused: bool = False) -> None:
        raise NotImplementedError("HTTPAdapter requires Phase 4 API layer")

    def pause(self) -> None:
        raise NotImplementedError("HTTPAdapter requires Phase 4 API layer")

    def resume(self) -> None:
        raise NotImplementedError("HTTPAdapter requires Phase 4 API layer")

    def stop(self) -> None:
        raise NotImplementedError("HTTPAdapter requires Phase 4 API layer")

    def seek_ms(self, milliseconds: int) -> None:
        raise NotImplementedError("HTTPAdapter requires Phase 4 API layer")

    def set_volume(self, volume: int) -> None:
        raise NotImplementedError("HTTPAdapter requires Phase 4 API layer")

    def toggle_mute(self) -> None:
        raise NotImplementedError("HTTPAdapter requires Phase 4 API layer")

    def set_rate(self, rate: float) -> None:
        raise NotImplementedError("HTTPAdapter requires Phase 4 API layer")

    def get_rate(self) -> float:
        return 1.0

    def get_position_ms(self) -> int:
        return 0

    def get_duration_ms(self) -> int:
        return 0

    def get_volume(self) -> int:
        return 50

    def list_audio_tracks(self) -> List[AudioTrack]:
        return []

    def set_audio_track(self, track_id: int) -> None:
        raise NotImplementedError("HTTPAdapter requires Phase 4 API layer")

    def get_audio_track(self) -> Optional[int]:
        return None

    def list_subtitle_tracks(self) -> List[SubtitleTrackInfo]:
        return []

    def set_subtitle_track(self, track_id: int) -> None:
        raise NotImplementedError("HTTPAdapter requires Phase 4 API layer")

    def get_subtitle_track(self) -> Optional[int]:
        return None

    def disable_subtitles(self) -> None:
        raise NotImplementedError("HTTPAdapter requires Phase 4 API layer")

    def set_subtitle_delay(self, delay_ms: int) -> None:
        raise NotImplementedError("HTTPAdapter requires Phase 4 API layer")

    def get_subtitle_delay(self) -> int:
        return 0

    def load_external_subtitle(self, path: str) -> bool:
        raise NotImplementedError("HTTPAdapter requires Phase 4 API layer")

    def get_state(self) -> str:
        return "stopped"

    def on_state_change(self, callback: Callable[[str], None]) -> None:
        self._state_callback = callback

    def close(self) -> None:
        pass
