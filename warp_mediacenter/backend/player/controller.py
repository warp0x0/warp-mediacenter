from __future__ import annotations

"""High-level wrapper for VLC playback operations."""

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional
import threading

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.common.tasks import TaskRunner, TaskSpec
from warp_mediacenter.backend.player.exceptions import PlayerError, SubtitleError
from warp_mediacenter.backend.player.subtitles.models import SubtitleQuery, SubtitleResult
from warp_mediacenter.backend.player.subtitles.service import (
    SubtitleDownload,
    SubtitleService,
)
from warp_mediacenter.backend.player.vlc_paths import resolve_vlc_runtime
from warp_mediacenter.backend.resource_management import get_resource_manager
from warp_mediacenter.config import settings

log = get_logger(__name__)


@dataclass(slots=True)
class PlayRequest:
    source: str
    title: str
    media_kind: str  # "movie" or "show"
    media_folder: Optional[Path] = None
    season: Optional[int] = None
    episode: Optional[int] = None
    year: Optional[int] = None
    language: str = "eng"
    start_paused: bool = False
    is_stream: bool = False
    auto_subtitles: bool = True


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
    started_at: datetime = field(default_factory=datetime.utcnow)


class PlayerController:
    """Manages VLC playback and subtitle orchestration."""

    def __init__(
        self,
        vlc_root: Optional[str] = None,
        task_runner: Optional[TaskRunner] = None,
        subtitle_service: Optional[SubtitleService] = None,
    ) -> None:
        runtime = resolve_vlc_runtime(vlc_root)
        if runtime is None:
            log.warning("vlc_runtime_not_configured", hint="Using system VLC installation")
        try:
            import vlc  # type: ignore
        except Exception as exc:  # noqa: BLE001
            raise PlayerError(f"python-vlc import failed: {exc}") from exc
        self._vlc = vlc
        self._instance = vlc.Instance()
        self._player = self._instance.media_player_new()
        self._event_manager = self._player.event_manager()
        self._task_runner = task_runner or TaskRunner(
            max_workers=4,
            resource_manager=get_resource_manager(),
            estimated_task_memory_mb=64.0,
            context="player",
            resource_wait_timeout=15.0,
        )
        self._task_runner = task_runner or TaskRunner(max_workers=4)
        temp_dir = Path(settings.get_player_temp_dir())
        self._subtitle_service = subtitle_service or SubtitleService(
            task_runner=self._task_runner,
            temp_dir=temp_dir,
        )
        self._state_lock = threading.Lock()
        self._current_state: Optional[PlaybackState] = None
        self._current_subtitle: Optional[SubtitleDownload] = None
        self._register_events()

    # ------------------------------------------------------------------
    # Playback lifecycle
    # ------------------------------------------------------------------
    def play(self, request: PlayRequest) -> None:
        self._cleanup_stream_subtitles()
        media = self._create_media(request)
        self._player.set_media(media)
        if request.start_paused:
            self._player.set_pause(1)
        else:
            self._player.play()
        with self._state_lock:
            self._current_state = PlaybackState(
                title=request.title,
                media_kind=request.media_kind,
                source=request.source,
                state="paused" if request.start_paused else "playing",
                position_ms=0,
                duration_ms=0,
                volume=self._player.audio_get_volume(),
                subtitle_path=None,
                is_stream=request.is_stream,
                media_folder=str(request.media_folder) if request.media_folder else None,
            )
        self._current_subtitle = None
        if request.auto_subtitles:
            self._task_runner.submit(
                TaskSpec(
                    fn=self._load_default_subtitle,
                    args=(request,),
                    name="subtitle_autoload",
                    retries=1,
                    backoff_sec=2.0,
                    estimated_memory_mb=64.0,
                )
            )

    def pause(self) -> None:
        self._player.pause()
        self._update_state("paused")

    def resume(self) -> None:
        self._player.play()
        self._update_state("playing")

    def stop(self) -> None:
        self._player.stop()
        self._update_state("stopped")
        self._cleanup_stream_subtitles()

    def seek_ms(self, milliseconds: int) -> None:
        self._player.set_time(milliseconds)

    def set_volume(self, volume: int) -> None:
        self._player.audio_set_volume(volume)
        with self._state_lock:
            if self._current_state:
                self._current_state.volume = volume

    def toggle_mute(self) -> None:
        self._player.audio_toggle_mute()

    # ------------------------------------------------------------------
    # State accessors
    # ------------------------------------------------------------------
    def now_playing(self) -> Optional[PlaybackState]:
        with self._state_lock:
            if not self._current_state:
                return None
            state = self._current_state
            state.position_ms = max(self._player.get_time(), 0)
            state.duration_ms = max(self._player.get_length(), 0)
            state.volume = self._player.audio_get_volume()
            return state

    # ------------------------------------------------------------------
    # Subtitle orchestration
    # ------------------------------------------------------------------
    def list_subtitles(self, query: SubtitleQuery):  # noqa: ANN001
        return self._subtitle_service.search(query)

    def set_subtitle(self, result: SubtitleResult, request: PlayRequest) -> None:
        subtitle_dest = self._resolve_subtitle_destination(request)
        download = self._subtitle_service.download(result, subtitle_dest)
        self._apply_subtitle(download)

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------
    def _create_media(self, request: PlayRequest):  # noqa: ANN001
        if request.is_stream:
            return self._instance.media_new(request.source)
        path = Path(request.source)
        if not path.exists():
            raise PlayerError(f"Media path not found: {request.source}")
        return self._instance.media_new_path(str(path))

    def _load_default_subtitle(self, request: PlayRequest) -> None:
        try:
            subtitle_query = SubtitleQuery(
                title=request.title,
                media_kind=request.media_kind,
                language=request.language,
                season=request.season,
                episode=request.episode,
                year=request.year,
                media_path=request.media_folder,
                is_stream=request.is_stream,
            )
            results = self._subtitle_service.search(subtitle_query)
            if not results:
                log.info("subtitle_not_found", title=request.title)
                return
            best = results[0]
            subtitle_dest = self._resolve_subtitle_destination(request)
            download = self._subtitle_service.download(best, subtitle_dest)
            self._apply_subtitle(download)
        except SubtitleError as exc:
            log.warning("subtitle_load_failed", error=str(exc))

    def _apply_subtitle(self, download: SubtitleDownload) -> None:
        if self._player.video_set_subtitle_file(str(download.path)) == -1:
            raise SubtitleError(f"Unable to load subtitle file {download.path}")
        with self._state_lock:
            if self._current_state:
                self._current_state.subtitle_path = str(download.path)
        self._current_subtitle = download

    def _resolve_subtitle_destination(self, request: PlayRequest) -> Path:
        if not request.is_stream:
            if request.media_folder and request.media_folder.exists():
                return request.media_folder
            path = Path(request.source)
            if path.exists():
                return path.parent
        return Path(settings.get_player_temp_dir())

    def _update_state(self, new_state: str) -> None:
        with self._state_lock:
            if self._current_state:
                self._current_state.state = new_state

    def _register_events(self) -> None:
        events = [
            self._vlc.EventType.MediaPlayerPlaying,
            self._vlc.EventType.MediaPlayerPaused,
            self._vlc.EventType.MediaPlayerStopped,
            self._vlc.EventType.MediaPlayerEndReached,
        ]
        for event in events:
            self._event_manager.event_attach(event, self._handle_event)

    def _handle_event(self, event) -> None:  # noqa: ANN001
        state = self._player.get_state()
        status = state.name if hasattr(state, "name") else str(state)
        self._update_state(status)
        if event.type == self._vlc.EventType.MediaPlayerEndReached:
            self._cleanup_stream_subtitles()

    def _cleanup_stream_subtitles(self) -> None:
        download = self._current_subtitle
        with self._state_lock:
            state = self._current_state
        if not download or not state:
            return
        if state.is_stream:
            try:
                download.path.unlink()
            except OSError:
                pass
            self._subtitle_service.cleanup_temp()
        self._current_subtitle = None
