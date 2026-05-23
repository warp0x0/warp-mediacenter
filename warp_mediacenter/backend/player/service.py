"""Player-agnostic playback service.

This module contains all playback logic that is independent of the underlying
media engine (VLC, ExoPlayer, HTML5, etc.):

- Playlist management
- Subtitle discovery and download orchestration
- Playback state tracking
- Play history persistence
- Resume-from-last-position logic
- Subtitle delay management
- Trakt scrobbling integration

The service talks to a PlayerAdapter for actual media operations, making it
trivial to swap between desktop (VLC) and thin client (HTTP) modes.
"""

from __future__ import annotations

from datetime import datetime
from pathlib import Path
from typing import Any, Callable, Dict, List, Mapping, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.common.tasks import TaskRunner, TaskSpec
from warp_mediacenter.backend.information_handlers.models import MediaType
from warp_mediacenter.backend.information_handlers.trakt_manager import TraktManager, TraktScrobbleConflict
from warp_mediacenter.backend.persistence import (
    connection as db_connection,
    get_latest_playback,
    get_title_id_for_file_path,
    record_playback,
)
from warp_mediacenter.backend.player.adapter import (
    AudioTrack,
    PlayerAdapter,
    PlaybackState,
    SubtitleTrackInfo,
)
from warp_mediacenter.backend.player.exceptions import PlayerError, SubtitleError
from warp_mediacenter.backend.player.playlist import Playlist, PlaylistItem
from warp_mediacenter.backend.player.subtitles.models import SubtitleQuery, SubtitleResult
from warp_mediacenter.backend.player.subtitles.service import SubtitleDownload, SubtitleService
from warp_mediacenter.backend.resource_management import get_resource_manager
from warp_mediacenter.config import settings

log = get_logger(__name__)


class PlaybackService:
    """Player-agnostic playback orchestration.

    Holds a PlayerAdapter for media operations and manages all higher-level
    playback concerns (playlist, subtitles, history, state, scrobbling).
    """

    def __init__(
        self,
        player: PlayerAdapter,
        task_runner: Optional[TaskRunner] = None,
        subtitle_service: Optional[SubtitleService] = None,
        trakt_manager: Optional[TraktManager] = None,
    ) -> None:
        self._player = player
        self._task_runner = task_runner or TaskRunner(
            max_workers=4,
            resource_manager=get_resource_manager(),
            estimated_task_memory_mb=64.0,
            context="playback_service",
            resource_wait_timeout=15.0,
        )
        temp_dir = Path(settings.get_player_temp_dir())
        self._subtitle_service = subtitle_service or SubtitleService(
            task_runner=self._task_runner,
            temp_dir=temp_dir,
        )
        self._trakt_manager = trakt_manager
        self._playlist = Playlist()
        self._state_lock = __import__("threading").Lock()
        self._current_state: Optional[PlaybackState] = None
        self._current_subtitle: Optional[SubtitleDownload] = None
        self._subtitle_delay_ms: int = 0
        self._on_state_change: Optional[Callable[[PlaybackState], None]] = None

        self._scrobble_media: Optional[Mapping[str, Any]] = None
        self._scrobble_show: Optional[Mapping[str, Any]] = None
        self._scrobble_media_type: Optional[MediaType] = None
        self._source_type: str = "local"

        self._player.on_state_change(self._on_player_state_change)

    # ------------------------------------------------------------------
    # Callbacks
    # ------------------------------------------------------------------
    def on_state_change(self, callback: Callable[[PlaybackState], None]) -> None:
        """Register a callback for playback state changes."""
        self._on_state_change = callback

    # ------------------------------------------------------------------
    # Playback lifecycle
    # ------------------------------------------------------------------
    def play(
        self,
        source: str,
        title: str,
        media_kind: str,
        *,
        media_folder: Optional[Path] = None,
        season: Optional[int] = None,
        episode: Optional[int] = None,
        year: Optional[int] = None,
        language: str = "eng",
        start_paused: bool = False,
        is_stream: bool = False,
        auto_subtitles: bool = True,
        resume_from_last_position: bool = True,
        tmdb_id: Optional[str] = None,
        media_payload: Optional[Mapping[str, Any]] = None,
        show_payload: Optional[Mapping[str, Any]] = None,
        source_type: str = "local",
    ) -> None:
        """Start playback of the given source."""
        self._cleanup_stream_subtitles()

        self._player.play(source, is_stream=is_stream, start_paused=start_paused)

        with self._state_lock:
            self._current_state = PlaybackState(
                title=title,
                media_kind=media_kind,
                source=source,
                state="paused" if start_paused else "playing",
                position_ms=0,
                duration_ms=0,
                volume=self._player.get_volume(),
                subtitle_path=None,
                is_stream=is_stream,
                media_folder=str(media_folder) if media_folder else None,
            )
        self._current_subtitle = None
        self._source_type = source_type

        if resume_from_last_position and not is_stream:
            self._try_resume(source)

        self._setup_scrobble_context(
            media_kind=media_kind,
            tmdb_id=tmdb_id,
            media_payload=media_payload,
            show_payload=show_payload,
        )
        self._scrobble_start()

        if auto_subtitles:
            query = SubtitleQuery(
                title=title,
                media_kind=media_kind,
                language=language,
                season=season,
                episode=episode,
                year=year,
                media_path=media_folder,
                is_stream=is_stream,
            )
            self._task_runner.submit(
                TaskSpec(
                    fn=self._load_default_subtitle,
                    args=(query,),
                    name="subtitle_autoload",
                    retries=1,
                    backoff_sec=2.0,
                    estimated_memory_mb=64.0,
                )
            )

    def pause(self) -> None:
        self._player.pause()
        self._update_state("paused")
        self._scrobble_pause()
        self._record_playback()

    def resume(self) -> None:
        self._player.resume()
        self._update_state("playing")

    def stop(self) -> None:
        self._player.stop()
        self._update_state("stopped")
        self._scrobble_stop()
        self._record_playback()
        self._cleanup_stream_subtitles()
        self._clear_scrobble_context()

    def seek_ms(self, milliseconds: int) -> None:
        self._player.seek_ms(milliseconds)

    def set_volume(self, volume: int) -> None:
        self._player.set_volume(volume)
        with self._state_lock:
            if self._current_state:
                self._current_state.volume = volume

    def toggle_mute(self) -> None:
        self._player.toggle_mute()

    # ------------------------------------------------------------------
    # Playback speed
    # ------------------------------------------------------------------
    def set_rate(self, rate: float) -> None:
        self._player.set_rate(rate)
        with self._state_lock:
            if self._current_state:
                self._current_state.rate = rate

    def get_rate(self) -> float:
        return self._player.get_rate()

    # ------------------------------------------------------------------
    # Audio track selection
    # ------------------------------------------------------------------
    def list_audio_tracks(self) -> List[AudioTrack]:
        return self._player.list_audio_tracks()

    def set_audio_track(self, track_id: int) -> None:
        self._player.set_audio_track(track_id)
        with self._state_lock:
            if self._current_state:
                self._current_state.audio_track_id = track_id

    def current_audio_track(self) -> Optional[int]:
        return self._player.get_audio_track()

    # ------------------------------------------------------------------
    # Subtitle track listing & switching
    # ------------------------------------------------------------------
    def list_subtitle_tracks(self) -> List[SubtitleTrackInfo]:
        return self._player.list_subtitle_tracks()

    def set_subtitle_track(self, track_id: int) -> None:
        self._player.set_subtitle_track(track_id)
        with self._state_lock:
            if self._current_state:
                self._current_state.subtitle_track_id = track_id

    def disable_subtitles(self) -> None:
        self._player.disable_subtitles()
        with self._state_lock:
            if self._current_state:
                self._current_state.subtitle_track_id = -1

    def current_subtitle_track(self) -> Optional[int]:
        return self._player.get_subtitle_track()

    # ------------------------------------------------------------------
    # Subtitle delay
    # ------------------------------------------------------------------
    def set_subtitle_delay(self, delay_ms: int) -> None:
        self._subtitle_delay_ms = delay_ms
        self._player.set_subtitle_delay(delay_ms)

    def get_subtitle_delay(self) -> int:
        return self._subtitle_delay_ms

    def adjust_subtitle_delay(self, delta_ms: int) -> int:
        self._subtitle_delay_ms += delta_ms
        self._player.set_subtitle_delay(self._subtitle_delay_ms)
        return self._subtitle_delay_ms

    # ------------------------------------------------------------------
    # Subtitle discovery & download
    # ------------------------------------------------------------------
    def search_subtitles(self, query: SubtitleQuery) -> List[SubtitleResult]:
        """Search for subtitles across all providers."""
        return self._subtitle_service.search(query)

    def download_and_apply_subtitle(
        self,
        result: SubtitleResult,
        *,
        media_folder: Optional[Path] = None,
        source: Optional[str] = None,
        is_stream: bool = False,
    ) -> Optional[str]:
        """Download a subtitle and apply it to current playback.

        Returns the path of the downloaded subtitle file, or None on failure.
        """
        dest_dir = self._resolve_subtitle_destination(
            media_folder=media_folder,
            source=source,
            is_stream=is_stream,
        )
        try:
            download = self._subtitle_service.download(result, dest_dir)
        except SubtitleError as exc:
            log.warning("subtitle_download_failed", error=str(exc))
            return None

        success = self._player.load_external_subtitle(str(download.path))
        if not success:
            log.warning("subtitle_load_failed", path=str(download.path))
            return None

        if self._subtitle_delay_ms:
            self._player.set_subtitle_delay(self._subtitle_delay_ms)

        with self._state_lock:
            if self._current_state:
                self._current_state.subtitle_path = str(download.path)
        self._current_subtitle = download
        return str(download.path)

    # ------------------------------------------------------------------
    # Playlist
    # ------------------------------------------------------------------
    @property
    def playlist(self) -> Playlist:
        return self._playlist

    def play_next(self) -> bool:
        item = self._playlist.next()
        if item is None:
            return False
        self._play_playlist_item(item)
        return True

    def play_previous(self) -> bool:
        item = self._playlist.previous()
        if item is None:
            return False
        self._play_playlist_item(item)
        return True

    def _play_playlist_item(self, item: PlaylistItem) -> None:
        self.play(
            source=item.source,
            title=item.title,
            media_kind=item.media_kind,
            media_folder=item.media_folder,
            season=item.season,
            episode=item.episode,
            year=item.year,
            language=item.language,
        )

    # ------------------------------------------------------------------
    # State accessors
    # ------------------------------------------------------------------
    def now_playing(self) -> Optional[PlaybackState]:
        with self._state_lock:
            if not self._current_state:
                return None
            state = self._current_state
            state.position_ms = self._player.get_position_ms()
            state.duration_ms = self._player.get_duration_ms()
            state.volume = self._player.get_volume()
            state.rate = self._player.get_rate()
            return state

    def close(self) -> None:
        """Release player resources."""
        self._player.close()

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------
    def _try_resume(self, source: str) -> None:
        title_id = None
        try:
            with db_connection() as conn:
                title_id = get_title_id_for_file_path(conn, source)
        except Exception:
            log.debug("resume_title_lookup_failed", source=source)

        if title_id is None:
            return

        try:
            with db_connection() as conn:
                record = get_latest_playback(conn, title_id)
            if record is None:
                return
            position = int(record["position"])
            duration = int(record["duration"])
            if duration > 0 and position > 0 and position < duration * 0.9:
                self._player.seek_ms(position)
                log.info("playback_resumed", title_id=title_id, position_ms=position)
                with self._state_lock:
                    if self._current_state:
                        self._current_state.position_ms = position
        except Exception:
            log.debug("resume_failed", title_id=title_id)

    def _load_default_subtitle(self, query: SubtitleQuery) -> None:
        try:
            results = self._subtitle_service.search(query)
            if not results:
                log.info("subtitle_not_found", title=query.title)
                return
            best = results[0]
            self.download_and_apply_subtitle(
                best,
                media_folder=query.media_path,
                source=None,
                is_stream=query.is_stream,
            )
        except SubtitleError as exc:
            log.warning("subtitle_load_failed", error=str(exc))

    def _resolve_subtitle_destination(
        self,
        *,
        media_folder: Optional[Path] = None,
        source: Optional[str] = None,
        is_stream: bool = False,
    ) -> Path:
        if not is_stream:
            if media_folder and media_folder.exists():
                return media_folder
            if source:
                path = Path(source)
                if path.exists():
                    return path.parent
        return Path(settings.get_player_temp_dir())

    def _update_state(self, new_state: str) -> None:
        with self._state_lock:
            if self._current_state:
                self._current_state.state = new_state
                if self._on_state_change:
                    self._on_state_change(self._current_state)

    def _record_playback(self) -> None:
        with self._state_lock:
            state = self._current_state
        if not state:
            return

        position_ms = self._player.get_position_ms()
        duration_ms = self._player.get_duration_ms()

        title_id = None
        if not state.is_stream:
            try:
                with db_connection() as conn:
                    title_id = get_title_id_for_file_path(conn, state.source)
            except Exception:
                log.debug("playback_title_lookup_failed", source=state.source)

        if title_id is None:
            return

        try:
            with db_connection() as conn:
                record_playback(
                    conn,
                    title_id=title_id,
                    position=position_ms,
                    duration=duration_ms,
                )
        except Exception:
            log.debug("playback_record_failed", title_id=title_id)

    def _on_player_state_change(self, vlc_state: str) -> None:
        self._update_state(vlc_state)
        if vlc_state == "EndReached":
            self._scrobble_stop(progress=100.0)
            self._record_playback()
            self._cleanup_stream_subtitles()
            self._clear_scrobble_context()
            if self._playlist.repeat_mode != "none":
                self.play_next()

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

    # ------------------------------------------------------------------
    # Trakt scrobbling
    # ------------------------------------------------------------------
    def _setup_scrobble_context(
        self,
        *,
        media_kind: str,
        tmdb_id: Optional[str] = None,
        media_payload: Optional[Mapping[str, Any]] = None,
        show_payload: Optional[Mapping[str, Any]] = None,
    ) -> None:
        """Prepare scrobble context from available metadata.

        Prefers explicit media_payload (from TMDb/Trakt). Falls back to
        building a minimal payload from title/year if no payload provided.
        """
        if self._trakt_manager is None:
            return

        if media_payload is not None:
            self._scrobble_media = media_payload
        elif tmdb_id:
            self._scrobble_media = {"ids": {"tmdb": tmdb_id}}
        else:
            self._scrobble_media = None

        self._scrobble_show = show_payload
        self._scrobble_media_type = self._resolve_scrobble_media_type(media_kind)

    def _clear_scrobble_context(self) -> None:
        """Reset scrobble context after playback ends."""
        self._scrobble_media = None
        self._scrobble_show = None
        self._scrobble_media_type = None

    @staticmethod
    def _resolve_scrobble_media_type(media_kind: str) -> Optional[MediaType]:
        if media_kind == "movie":
            return MediaType.MOVIE
        if media_kind in ("episode", "show", "tv"):
            return MediaType.EPISODE
        return None

    def _scrobble_start(self) -> None:
        """Fire Trakt scrobble start event."""
        self._execute_scrobble("start", progress=0.0)

    def _scrobble_pause(self) -> None:
        """Fire Trakt scrobble pause event with current progress."""
        progress = self._get_progress_percent()
        self._execute_scrobble("pause", progress=progress)

    def _scrobble_stop(self, progress: Optional[float] = None) -> None:
        """Fire Trakt scrobble stop event.

        If progress is None, calculates from current playback position.
        If progress >= 80%, Trakt may mark as watched.
        """
        if progress is None:
            progress = self._get_progress_percent()
        self._execute_scrobble("stop", progress=progress)

    def _get_progress_percent(self) -> float:
        """Calculate current playback progress as a percentage."""
        try:
            position = self._player.get_position_ms()
            duration = self._player.get_duration_ms()
            if duration > 0:
                return min(100.0, (position / duration) * 100.0)
        except Exception:
            pass
        return 0.0

    def _execute_scrobble(self, action: str, progress: float) -> None:
        """Execute a Trakt scrobble call with error handling.

        Silently skips if:
        - No Trakt manager configured
        - No valid Trakt token
        - No scrobble media context
        - TraktScrobbleConflict (409) is raised
        """
        if self._trakt_manager is None:
            return
        if not self._trakt_manager.has_valid_token():
            return
        if self._scrobble_media is None or self._scrobble_media_type is None:
            return

        try:
            if self._scrobble_media_type == MediaType.MOVIE:
                self._trakt_manager.scrobble(
                    media_type=self._scrobble_media_type,
                    media=self._scrobble_media,
                    progress=progress,
                    action=action,
                )
            elif self._scrobble_media_type == MediaType.EPISODE:
                self._trakt_manager.scrobble(
                    media_type=self._scrobble_media_type,
                    media=self._scrobble_media,
                    progress=progress,
                    action=action,
                    show=self._scrobble_show,
                )
            log.debug("trakt_scrobble_sent", action=action, progress=round(progress, 1))
        except TraktScrobbleConflict:
            log.debug("trakt_scrobble_conflict", action=action)
        except Exception as exc:
            log.warning("trakt_scrobble_failed", action=action, error=str(exc))
