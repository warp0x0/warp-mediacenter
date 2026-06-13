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

import threading
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
        # Last known good progress percentage (updated by now_playing when VLC
        # reports non-zero position AND duration).  Used as final fallback for
        # Trakt scrobble-stop so that progress is never 0.0 after a natural end.
        self._last_progress_pct: float = 0.0

        # Last VLC position in ms as reported by now_playing().  Tracked
        # unconditionally (even when duration is 0) so that HTTP streams, where
        # VLC's RC get_length always returns 0, still have a usable position at
        # scrobble-stop time.
        self._last_position_ms: int = 0

        # Known media runtime in ms, extracted from the media_payload passed to
        # play().  Combined with _last_position_ms this gives real progress for
        # streams where VLC never reports a valid duration.
        self._media_duration_ms: int = 0

        # Set to True the first time the poll thread reports "Playing" for the
        # current item.  Used to suppress spurious "Stopped" events that the VLC
        # subprocess emits during moov-atom-seek initialisation (before playback
        # actually begins) — those would otherwise fire playback_ended_naturally
        # and clear the scrobble context before real playback starts.
        self._playback_started: bool = False

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
        log.info(
            "playback_play",
            title=title,
            media_kind=media_kind,
            source_type=source_type,
            is_stream=is_stream,
            season=season,
            episode=episode,
            source=source[:100],
        )
        self._cleanup_stream_subtitles()

        # Reset before the player starts so that any "Stopped" events emitted
        # by the VLC subprocess during its init phase (moov-atom seek) are
        # treated as pre-play noise rather than natural-end signals.
        self._playback_started = False
        self._last_position_ms = 0
        # Extract known media runtime for progress tracking on HTTP streams where
        # VLC's RC get_length always returns 0.  Checked in extra.runtime (TMDB
        # movies), extra.episode_run_time (TMDB shows), and at the top level.
        self._media_duration_ms = self._extract_media_duration(media_payload)
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
            season=season,
            episode=episode,
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
        log.info("playback_pause", progress=self._get_progress_percent())
        self._player.pause()
        self._update_state("paused")
        self._scrobble_pause()
        self._record_playback()

    def resume(self) -> None:
        log.info("playback_resume")
        self._player.resume()
        self._update_state("playing")

    def stop(self) -> None:
        log.info("playback_stop", progress=self._get_progress_percent())
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
            pos = self._player.get_position_ms()
            dur = self._player.get_duration_ms()
            # VLC returns 0 for both position and duration once it has stopped.
            # Only update the cached state when the values are meaningful so that
            # _get_progress_percent() can read the last-known position after the
            # stop event fires (preventing Trakt scrobble-stop from reporting 0%).
            if pos > 0:
                state.position_ms = pos
                # Always keep the last non-zero position so _get_progress_percent()
                # has a usable value at scrobble-stop time even when VLC's RC
                # get_length returns 0 (true for all HTTP streams).
                self._last_position_ms = pos
            if dur > 0:
                state.duration_ms = dur
            # Track percentage whenever both values are valid (local files / any
            # player that does report a valid duration).
            if pos > 0 and dur > 0:
                self._last_progress_pct = min(100.0, (pos / dur) * 100.0)
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
        # Track the first moment actual playback begins for this item.
        if vlc_state == "Playing":
            self._playback_started = True

        # The VLC subprocess fires "Stopped" (via the RC poll thread) during
        # the moov-atom seek / buffering phase — before it ever reports "Playing".
        # This window can be several seconds on an HTTPS stream (CDN latency).
        # If _playback_started is still False we have not seen a single "Playing"
        # event, so this "Stopped" is init-phase noise — drop it entirely so we
        # don't trigger a false playback_ended_naturally that clears the scrobble
        # context and prevents the real end-of-playback scrobble from firing.
        if vlc_state in ("Stopped", "EndReached") and not self._playback_started:
            log.info("vlc_early_stopped_ignored", vlc_state=vlc_state)
            return

        log.info("playback_state_change", vlc_state=vlc_state)
        self._update_state(vlc_state)

        # "EndReached" is fired by the python-vlc (VLCAdapter) binding.
        # "Stopped"    is fired by SubprocessVLCAdapter when --play-and-stop triggers.
        # Both represent natural end-of-media.  Guard on _scrobble_media being set so
        # an explicit PlaybackService.stop() (which clears context first) doesn't
        # trigger a second scrobble stop via this callback path.
        if vlc_state in ("EndReached", "Stopped") and self._scrobble_media is not None:
            progress = self._get_progress_percent()

            # For local files, VLC only fires Stopped/EndReached at actual
            # end-of-file, so 0% here is a reliable indicator of a completed
            # watch with no position data → assume 100%.
            #
            # For HTTP streams the "Stopped" event is fired by the VLC subprocess
            # whenever the TCP connection to the stream proxy closes — which happens
            # both at natural end AND when the proxy stops the download early
            # (buffer-flush, seek, CDN range exhausted, etc.).  Defaulting to 100%
            # for streams would scrobble a partially-watched item as fully watched,
            # causing a Trakt 409 Conflict on the next play.  Instead, trust the
            # Tier-4 position/duration value (or 0% if truly no data), which Trakt
            # will interpret as "pause" (< 80%) — harmless and reversible.
            with self._state_lock:
                is_stream = self._current_state.is_stream if self._current_state else False

            if progress <= 0.0 and not is_stream:
                progress = 100.0  # local file natural end → assume fully watched

            log.info("playback_ended_naturally", vlc_state=vlc_state, progress=round(progress, 1))
            self._scrobble_stop(progress=progress)
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
        season: Optional[int] = None,
        episode: Optional[int] = None,
    ) -> None:
        """Prepare scrobble context from available metadata.

        **Movies** — ``media_payload`` is the movie ``MediaItem``.  The frontend
        stores the TMDb ID at the top level (``tmdb_id``) and the full Trakt ID
        set in ``extra.ids``.  ``_to_trakt_selector`` normalises both shapes
        into ``{"ids": {"tmdb": …, "trakt": …, "slug": …, "imdb": …}, …}``.

        **TV episodes** — the frontend sends the *show's* ``MediaItem`` as
        ``media_payload`` (``type == "show"``).  The episode is identified by
        ``season`` and ``episode`` numbers that travel separately in the play
        request.  The Trakt scrobble endpoint expects:

        .. code-block:: json

            {
                "episode": {"season": 1, "number": 5},
                "show":    {"ids": {"trakt": …, "tmdb": …, …}},
                "progress": X
            }

        So for TV content we use ``media_payload`` as the *show* selector and
        build a minimal episode selector from the season/episode numbers.
        """
        if self._trakt_manager is None:
            return

        media_type = self._resolve_scrobble_media_type(media_kind)
        self._scrobble_media_type = media_type

        if media_type == MediaType.MOVIE:
            # ── Movie ────────────────────────────────────────────────────────
            if media_payload is not None:
                self._scrobble_media = self._to_trakt_selector(media_payload, tmdb_id=tmdb_id)
            elif tmdb_id:
                self._scrobble_media = {"ids": {"tmdb": tmdb_id}}
            else:
                self._scrobble_media = None
            self._scrobble_show = None

        elif media_type == MediaType.EPISODE:
            # ── TV episode ───────────────────────────────────────────────────
            # Build a minimal episode selector (season + episode number).
            # Trakt resolves the episode from season+number+show context.
            ep_selector: Dict[str, Any] = {}
            if season is not None:
                ep_selector["season"] = season
            if episode is not None:
                ep_selector["number"] = episode
            self._scrobble_media = ep_selector if ep_selector else None

            # The show selector comes from the explicit show_payload or,
            # when the frontend omits it, from media_payload (which holds the
            # show MediaItem for TV content) or from the bare tmdb_id.
            if show_payload is not None:
                self._scrobble_show = self._to_trakt_selector(show_payload, tmdb_id=tmdb_id)
            elif media_payload is not None:
                self._scrobble_show = self._to_trakt_selector(media_payload, tmdb_id=tmdb_id)
            elif tmdb_id:
                self._scrobble_show = {"ids": {"tmdb": tmdb_id}}
            else:
                self._scrobble_show = None

        else:
            self._scrobble_media = None
            self._scrobble_show = None

        log.info(
            "scrobble_context_set",
            media_type=str(media_type),
            has_media=self._scrobble_media is not None,
            media_ids=dict(self._scrobble_media.get("ids", {})) if self._scrobble_media else None,
            season=season,
            episode=episode,
            show_ids=dict(self._scrobble_show.get("ids", {})) if self._scrobble_show else None,
        )

    @staticmethod
    def _to_trakt_selector(
        payload: Mapping[str, Any],
        *,
        tmdb_id: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        """Normalise a media payload dict to the minimal Trakt selector format.

        Trakt's scrobble endpoint wants ``{"ids": {"tmdb": 12345}, "title": "…"}``.
        The frontend sends a full ``MediaItem`` (or similar) dict that keeps the
        TMDb ID under the top-level key ``tmdb_id`` rather than nested under
        ``ids``.  This helper handles both shapes.

        Priority:
        1. ``ids`` already present at the top level → use as-is (already Trakt format).
        2. ``tmdb_id`` from the explicit parameter or from ``payload["tmdb_id"]``.
        3. ``trakt_id`` from ``payload["trakt_id"]``.
        4. ``extra.ids`` (populated when the item originally came from Trakt).
        Returns *None* if no usable identifier can be found.
        """
        if not isinstance(payload, Mapping):
            return None

        # Already in Trakt format — has a top-level 'ids' dict.
        top_ids = payload.get("ids")
        if isinstance(top_ids, Mapping) and top_ids:
            result: Dict[str, Any] = {"ids": dict(top_ids)}
            if payload.get("title"):
                result["title"] = str(payload["title"])
            if payload.get("year") is not None:
                try:
                    result["year"] = int(payload["year"])  # type: ignore[arg-type]
                except (TypeError, ValueError):
                    pass
            return result

        # Build ids from whatever is available.
        ids: Dict[str, Any] = {}

        raw_tmdb = tmdb_id or payload.get("tmdb_id")
        if raw_tmdb:
            try:
                ids["tmdb"] = int(raw_tmdb)
            except (TypeError, ValueError):
                ids["tmdb"] = str(raw_tmdb)

        raw_trakt = payload.get("trakt_id")
        if raw_trakt:
            try:
                ids["trakt"] = int(raw_trakt)
            except (TypeError, ValueError):
                ids["trakt"] = str(raw_trakt)

        # Fallback: extra.ids (present when item came from Trakt API directly).
        # _normalize_ids() in models.py stringifies all values, so we re-coerce
        # known numeric keys back to int so the Trakt payload matches its schema.
        _NUMERIC_ID_KEYS = frozenset(("trakt", "tmdb", "tvdb", "tvrage"))
        extra = payload.get("extra") or {}
        if isinstance(extra, Mapping):
            extra_ids = extra.get("ids")
            if isinstance(extra_ids, Mapping):
                for k, v in extra_ids.items():
                    if k not in ids and v is not None:
                        if k in _NUMERIC_ID_KEYS:
                            try:
                                ids[k] = int(v)
                            except (TypeError, ValueError):
                                ids[k] = v
                        else:
                            ids[k] = v

        if not ids:
            return None

        selector: Dict[str, Any] = {"ids": ids}
        if payload.get("title"):
            selector["title"] = str(payload["title"])
        if payload.get("year") is not None:
            try:
                selector["year"] = int(payload["year"])  # type: ignore[arg-type]
            except (TypeError, ValueError):
                pass
        return selector

    @staticmethod
    def _extract_media_duration(payload: Optional[Mapping[str, Any]]) -> int:
        """Extract the media runtime in milliseconds from a play-request payload.

        Checks multiple locations in order of reliability:
        - ``payload["runtime_minutes"]``    — normalised field some shapes use
        - ``payload["extra"]["runtime"]``   — TMDB movie runtime (minutes)
        - ``payload["extra"]["episode_run_time"][0]`` — TMDB show average (minutes)

        Returns 0 when no usable value is found.
        """
        if not isinstance(payload, Mapping):
            return 0

        def _to_ms(minutes: Any) -> int:
            try:
                m = int(minutes)
                return m * 60 * 1000 if m > 0 else 0
            except (TypeError, ValueError):
                return 0

        # Top-level field (some normalised shapes)
        for key in ("runtime_minutes", "runtime"):
            ms = _to_ms(payload.get(key))
            if ms:
                return ms

        # Nested in extra (TMDB catalog items)
        extra = payload.get("extra") or {}
        if isinstance(extra, Mapping):
            ms = _to_ms(extra.get("runtime"))
            if ms:
                return ms
            # TV shows store a list of per-episode runtimes; use first value
            ert = extra.get("episode_run_time")
            if isinstance(ert, (list, tuple)) and ert:
                ms = _to_ms(ert[0])
                if ms:
                    return ms

        return 0

    def _clear_scrobble_context(self) -> None:
        """Reset scrobble context after playback ends."""
        self._scrobble_media = None
        self._scrobble_show = None
        self._scrobble_media_type = None
        self._last_progress_pct = 0.0
        self._last_position_ms = 0
        self._media_duration_ms = 0
        self._playback_started = False

    @staticmethod
    def _resolve_scrobble_media_type(media_kind: str) -> Optional[MediaType]:
        if media_kind == "movie":
            return MediaType.MOVIE
        if media_kind in ("episode", "show", "tv"):
            return MediaType.EPISODE
        return None

    def _scrobble_start(self) -> None:
        """Fire Trakt scrobble start event in a background daemon thread.

        Running asynchronously prevents the daily Trakt token-refresh HTTP call
        (~2–3 s) from blocking the play() HTTP response handler.  Blocking play()
        would create a window — between _scrobble_media being set and VLC
        reporting its first "Playing" state — during which the RC poll thread
        could fire a spurious "Stopped" (moov-atom seek phase) that falsely
        triggers playback_ended_naturally and wipes the scrobble context.
        """
        t = threading.Thread(
            target=lambda: self._execute_scrobble("start", progress=0.0),
            daemon=True,
            name="trakt-scrobble-start",
        )
        t.start()

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
        """Calculate current playback progress as a percentage (0–100).

        Four-tier fallback chain, from most- to least-accurate:

        1. Live RC query (position / duration) — valid while VLC is running and
           the player reports a non-zero duration (local files).
        2. Cached _current_state values (updated by now_playing) — valid for a
           short window after stop if duration was ever non-zero.
        3. _last_progress_pct — percentage computed when both position and
           duration were valid (local files).
        4. _last_position_ms / _media_duration_ms — position-only tracking
           combined with the runtime extracted from the play() media_payload.
           This is the only path that works for HTTP streams, where VLC's RC
           get_length always returns 0.
        """
        try:
            position = self._player.get_position_ms()
            # SubprocessVLCAdapter.get_position_ms() falls back to its own
            # _last_known_position_ms (polled every 500 ms while Playing) when
            # VLC's get_time returns 0 after a stop.  So `position` here is the
            # last captured position from the poll thread — no frontend polling
            # required.
            duration = self._player.get_duration_ms()
            if position > 0:
                if duration > 0:
                    return min(100.0, (position / duration) * 100.0)
                if self._media_duration_ms > 0:
                    # HTTP stream: VLC never reports a valid duration (get_length
                    # always returns 0).  Use the runtime extracted from the play
                    # request payload instead.
                    pct = min(100.0, (position / self._media_duration_ms) * 100.0)
                    log.debug(
                        "progress_from_position_media_duration",
                        position_ms=position,
                        media_duration_ms=self._media_duration_ms,
                        pct=round(pct, 1),
                    )
                    return pct
            # Tier 2 — cached state.
            if self._current_state and self._current_state.duration_ms > 0:
                cached = min(
                    100.0,
                    (self._current_state.position_ms / self._current_state.duration_ms) * 100.0,
                )
                log.debug(
                    "progress_using_state_cache",
                    cached_pct=round(cached, 1),
                    position_ms=self._current_state.position_ms,
                    duration_ms=self._current_state.duration_ms,
                )
                return cached
        except Exception:
            pass
        # Tier 3 — last running percentage observed during active playback.
        if self._last_progress_pct > 0.0:
            log.debug("progress_using_last_pct", last_pct=round(self._last_progress_pct, 1))
            return self._last_progress_pct
        # Tier 4 — position + known media duration (HTTP streams).
        # now_playing() tracks _last_position_ms on every call where pos > 0,
        # even when VLC reports 0 for duration.  Combined with the runtime
        # extracted from the media_payload at play() time this gives a real
        # percentage without needing VLC to report a valid get_length.
        if self._last_position_ms > 0 and self._media_duration_ms > 0:
            pct = min(100.0, (self._last_position_ms / self._media_duration_ms) * 100.0)
            log.debug(
                "progress_using_position_and_media_duration",
                last_position_ms=self._last_position_ms,
                media_duration_ms=self._media_duration_ms,
                pct=round(pct, 1),
            )
            return pct
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
            log.debug("trakt_scrobble_skipped_no_token", action=action)
            return
        if self._scrobble_media is None or self._scrobble_media_type is None:
            log.debug("trakt_scrobble_skipped_no_context", action=action)
            return

        log.info(
            "trakt_scrobble_attempt",
            action=action,
            progress=round(progress, 1),
            media_type=str(self._scrobble_media_type),
            media_ids=dict(self._scrobble_media.get("ids", {})),
            media_title=self._scrobble_media.get("title"),
        )

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
            log.info(
                "trakt_scrobble_sent",
                action=action,
                progress=round(progress, 1),
                media_type=str(self._scrobble_media_type),
            )
        except TraktScrobbleConflict:
            log.info("trakt_scrobble_conflict", action=action)
        except Exception as exc:
            log.warning("trakt_scrobble_failed", action=action, error=str(exc))
