"""Top level interface for media information providers.

This module exposes a single convenience façade, :class:`InformationProviders`,
that wires together the lower-level managers implemented in the sibling
modules.  The goal is to give the rest of the application a compact entry
point that yields normalized models regardless of the upstream service used to
source the information.

The façade is intentionally synchronous and thin: it simply delegates to the
specialised managers while handling shared concerns such as cache reuse and
optional Trakt availability.  Converting the façade to asyncio in the future
should only require adjusting these delegation methods.
"""

from __future__ import annotations

import hashlib
import random
from datetime import date, datetime, timezone
from typing import Any, Mapping, Optional, Sequence, Tuple

from pydantic import ValidationError

from warp_mediacenter.backend.information_handlers.cache import InformationProviderCache
from warp_mediacenter.backend.information_handlers.models import (
    CatalogItem,
    Credits,
    MediaModelFacade,
    MediaType,
    Movie,
    Season,
    Episode,
    Show,
    StreamSource,
)
from warp_mediacenter.backend.information_handlers.public_archives_manager import (
    PublicArchivesManager,
    SourceDescriptor,
)
from warp_mediacenter.backend.information_handlers.tmdb_manager import (
    GenreMap,
    TMDbManager,
)
from warp_mediacenter.backend.information_handlers.trailers_manager import TrailersManager
from warp_mediacenter.backend.information_handlers.trakt_manager import (
    CatalogWidget,
    CatalogWidgetItem,
    ContinueWatchingPayload,
    DeviceCode,
    HistoryEntry,
    OAuthToken,
    PaginationDetails,
    RateLimitInfo,
    PlaybackEntry,
    ScrobbleResponse,
    TraktManager,
    TraktUserProfile,
    TraktUserSettings,
    TraktSearchResult,
    UserList,
)
from warp_mediacenter.backend.network_handlers.session import HttpSession
from warp_mediacenter.backend.persistence import (
    connection as db_connection,
    get_widget as db_get_widget,
    set_widget as db_set_widget,
    upsert_title,
)
from warp_mediacenter.backend.common.logging import get_logger


class InformationProviders:
    """Aggregate façade that exposes the supported information providers.

    Parameters
    ----------
    cache:
        Optional shared :class:`InformationProviderCache` instance.  When not
        provided a new cache is created so TMDb and public archives can reuse
        both the in-memory and disk tiers.
    facade:
        Optional :class:`MediaModelFacade` used to build the normalized Pydantic
        models.  Sharing the facade keeps customisation hooks (if any are added
        later) consistent across providers.
    http_session:
        Optional :class:`HttpSession` injected into :class:`TMDbManager`.  This
        makes it trivial for callers to customise retry/proxy behaviour.  When
        omitted a default session is created.
    tmdb, trakt, public_archives, trailers:
        Pre-built manager instances can be supplied for testing.  When omitted
        the façade will construct default managers while sharing cache/facade
        instances when appropriate.
    allow_missing_trakt:
        When ``True`` (default) failure to construct a :class:`TraktManager`
        because of missing OAuth credentials is swallowed so that the rest of
        the providers remain usable.  Callers can inspect :attr:`trakt_error`
        to determine why Trakt is unavailable.  When ``False`` the constructor
        re-raises the error.
    """

    def __init__(
        self,
        *,
        cache: Optional[InformationProviderCache] = None,
        facade: Optional[MediaModelFacade] = None,
        http_session: Optional[HttpSession] = None,
        tmdb: Optional[TMDbManager] = None,
        trakt: Optional[TraktManager] = None,
        public_archives: Optional[PublicArchivesManager] = None,
        trailers: Optional[TrailersManager] = None,
        allow_missing_trakt: bool = True,
    ) -> None:
        self._log = get_logger(__name__)
        self._cache = cache or InformationProviderCache()
        self._facade = facade or MediaModelFacade()

        if tmdb is not None:
            self._tmdb = tmdb
        else:
            session = http_session or HttpSession()
            self._tmdb = TMDbManager(session=session, cache=self._cache, facade=self._facade)

        self._public_archives = public_archives or PublicArchivesManager(
            facade=self._facade,
            cache=self._cache,
        )
        self._trailers = trailers or TrailersManager(tmdb=self._tmdb, facade=self._facade)

        self._trakt_error: Optional[Exception] = None
        if trakt is not None:
            self._trakt = trakt
        else:
            if allow_missing_trakt:
                try:
                    self._trakt = TraktManager(facade=self._facade)
                except Exception as exc:  # pragma: no cover - environment dependent
                    self._trakt = None
                    self._trakt_error = exc
            else:
                self._trakt = TraktManager(facade=self._facade)

        self._continue_watching_cache: Optional[ContinueWatchingPayload] = None
        self._continue_watching_cache_params: Optional[Tuple[int, int, int]] = None
        self._continue_watching_cache_ts: Optional[datetime] = None

    # ------------------------------------------------------------------
    # Shared accessors
    # ------------------------------------------------------------------
    @property
    def cache(self) -> InformationProviderCache:
        return self._cache

    @property
    def facade(self) -> MediaModelFacade:
        return self._facade

    @property
    def tmdb(self) -> TMDbManager:
        return self._tmdb

    @property
    def public_archives(self) -> PublicArchivesManager:
        return self._public_archives

    @property
    def trailers(self) -> TrailersManager:
        return self._trailers

    @property
    def trakt(self) -> Optional[TraktManager]:
        return self._trakt

    @property
    def trakt_error(self) -> Optional[Exception]:
        return self._trakt_error

    def trakt_available(self) -> bool:
        return self._trakt is not None

    # ------------------------------------------------------------------
    # TMDb delegates
    # ------------------------------------------------------------------
    def search_movies(
        self,
        query: str,
        *,
        language: Optional[str] = None,
        page: int = 1,
        include_adult: bool = False,
    ) -> Sequence[CatalogItem]:
        return self._tmdb.search_movies(
            query,
            language=language,
            page=page,
            include_adult=include_adult,
        )

    def search_shows(
        self,
        query: str,
        *,
        language: Optional[str] = None,
        page: int = 1,
    ) -> Sequence[CatalogItem]:
        return self._tmdb.search_shows(query, language=language, page=page)

    def tmdb_catalog(
        self,
        media_type: MediaType,
        category: str,
        *,
        language: Optional[str] = None,
        page: int = 1,
    ) -> Sequence[CatalogItem]:
        return self._tmdb.catalog_list(
            media_type,
            category,
            language=language,
            page=page,
        )

    def movie_details(
        self,
        movie_id: int | str,
        *,
        language: Optional[str] = None,
        include_credits: bool = True,
    ) -> Movie:
        return self._tmdb.movie_details(
            movie_id,
            language=language,
            include_credits=include_credits,
        )

    def show_details(
        self,
        show_id: int | str,
        *,
        language: Optional[str] = None,
        include_credits: bool = True,
    ) -> Show:
        return self._tmdb.show_details(
            show_id,
            language=language,
            include_credits=include_credits,
        )

    def season_details(
        self,
        show_id: int | str,
        season_number: int,
        *,
        language: Optional[str] = None,
        include_episodes: bool = True,
    ) -> Season:
        return self._tmdb.season_details(
            show_id,
            season_number,
            language=language,
            include_episodes=include_episodes,
        )

    def episode_details(
        self,
        show_id: int | str,
        season_number: int,
        episode_number: int,
        *,
        language: Optional[str] = None,
        include_credits: bool = True,
    ) -> Episode:
        return self._tmdb.episode_details(
            show_id,
            season_number,
            episode_number,
            language=language,
            include_credits=include_credits,
        )

    def movie_credits(self, movie_id: int | str) -> Credits:
        return self._tmdb.movie_credits(movie_id)

    def show_credits(self, show_id: int | str) -> Credits:
        return self._tmdb.show_credits(show_id)

    def tmdb_configuration(self, *, force_refresh: bool = False) -> Mapping[str, Any]:
        return self._tmdb.get_configuration(force_refresh=force_refresh)

    def tmdb_genre_map(
        self,
        media_type: MediaType,
        *,
        language: Optional[str] = None,
    ) -> GenreMap:
        return self._tmdb.get_genre_map(media_type, language=language)

    # ------------------------------------------------------------------
    # Trailers delegates
    # ------------------------------------------------------------------
    def movie_trailers(
        self,
        movie_id: int | str,
        *,
        language: Optional[str] = None,
    ) -> Sequence[StreamSource]:
        return self._trailers.movie_trailers(movie_id, language=language)

    def show_trailers(
        self,
        show_id: int | str,
        *,
        language: Optional[str] = None,
    ) -> Sequence[StreamSource]:
        return self._trailers.show_trailers(show_id, language=language)

    # ------------------------------------------------------------------
    # Public archives delegates
    # ------------------------------------------------------------------
    def list_public_domain_sources(self) -> Sequence[SourceDescriptor]:
        return self._public_archives.list_sources()

    def fetch_public_domain_catalog(
        self,
        key: str,
        *,
        params: Optional[Mapping[str, Any]] = None,
    ) -> Sequence[CatalogItem]:
        return self._public_archives.fetch(key, params=params)

    def list_curated_catalogs(self) -> Sequence[str]:
        return self._public_archives.list_curated_catalogs()

    def load_curated_catalog(self, key: str) -> Sequence[CatalogItem]:
        return self._public_archives.load_curated_catalog(key)

    # ------------------------------------------------------------------
    # Trakt delegates
    # ------------------------------------------------------------------
    def trakt_device_code_start(self) -> Mapping[str, Any]:
        return self._require_trakt().device_code_start()

    def trakt_facade_status(self) -> Mapping[str, Any]:
        return self._require_trakt().facade_status()

    def start_trakt_device_auth(self) -> DeviceCode:
        return self._require_trakt().start_device_auth()

    def poll_trakt_device_token(self, device_code: str) -> OAuthToken:
        return self._require_trakt().poll_device_token(device_code)

    def wait_for_trakt_device_token(
        self,
        device: DeviceCode,
        *,
        timeout: Optional[int] = None,
    ) -> OAuthToken:
        return self._require_trakt().wait_for_device_token(device, timeout=timeout)

    def refresh_trakt_token(self) -> OAuthToken:
        return self._require_trakt().refresh_tokens()

    def trakt_has_token(self) -> bool:
        if self._trakt is None:
            return False
        return self._trakt.has_token()

    def trakt_has_valid_token(self, *, buffer_seconds: int = 120) -> bool:
        if self._trakt is None:
            return False
        return self._trakt.has_valid_token(buffer_seconds=buffer_seconds)

    def trakt_current_token(self) -> Optional[OAuthToken]:
        if self._trakt is None:
            return None
        return self._trakt.current_token()

    def trakt_token_expires_at(self) -> Optional[float]:
        if self._trakt is None:
            return None
        return self._trakt.token_expires_at()

    def trakt_clear_token(self) -> None:
        if self._trakt is None:
            return
        self._trakt.clear_token()

    def get_trakt_profile(self, username: str = "me") -> TraktUserProfile:
        return self._require_trakt().get_profile(username)

    def get_trakt_user_settings(self) -> TraktUserSettings:
        return self._require_trakt().get_user_settings()

    def get_trakt_user_lists(self, username: str = "me") -> Sequence[UserList]:
        return self._require_trakt().get_user_lists(username)

    def get_trakt_list_items(
        self,
        list_id: str,
        *,
        username: str = "me",
        media_type: Optional[MediaType] = None,
    ) -> Sequence[CatalogItem]:
        return self._require_trakt().get_list_items(
            list_id,
            username=username,
            media_type=media_type,
        )

    def get_trakt_history(
        self,
        media_type: MediaType,
        *,
        limit: int = 100,
        start_at: Optional[datetime] = None,
        end_at: Optional[datetime] = None,
    ) -> Sequence[HistoryEntry]:
        return self._require_trakt().get_watched_history(
            media_type,
            limit=limit,
            start_at=start_at,
            end_at=end_at,
        )

    def trakt_scrobble(
        self,
        *,
        media_type: MediaType,
        media: Mapping[str, Any],
        progress: float,
        action: str = "start",
        show: Optional[Mapping[str, Any]] = None,
        app_version: Optional[str] = None,
        app_date: Optional[str] = None,
    ) -> ScrobbleResponse:
        response = self._require_trakt().scrobble(
            media_type=media_type,
            media=media,
            progress=progress,
            action=action,
            show=show,
            app_version=app_version,
            app_date=app_date,
        )
        if str(action).lower() in {"pause", "stop"}:
            self._refresh_continue_watching_cache()
        return response

    def trakt_scrobble_start(
        self,
        *,
        media_type: MediaType,
        media: Mapping[str, Any],
        progress: float,
        show: Optional[Mapping[str, Any]] = None,
        app_version: Optional[str] = None,
        app_date: Optional[str] = None,
    ) -> ScrobbleResponse:
        return self._require_trakt().start_scrobble(
            media_type=media_type,
            media=media,
            progress=progress,
            show=show,
            app_version=app_version,
            app_date=app_date,
        )

    def trakt_scrobble_pause(
        self,
        *,
        media_type: MediaType,
        media: Mapping[str, Any],
        progress: float,
        show: Optional[Mapping[str, Any]] = None,
        app_version: Optional[str] = None,
        app_date: Optional[str] = None,
    ) -> ScrobbleResponse:
        response = self._require_trakt().pause_scrobble(
            media_type=media_type,
            media=media,
            progress=progress,
            show=show,
            app_version=app_version,
            app_date=app_date,
        )
        self._refresh_continue_watching_cache()
        return response

    def trakt_scrobble_stop(
        self,
        *,
        media_type: MediaType,
        media: Mapping[str, Any],
        progress: float,
        show: Optional[Mapping[str, Any]] = None,
        app_version: Optional[str] = None,
        app_date: Optional[str] = None,
    ) -> ScrobbleResponse:
        response = self._require_trakt().stop_scrobble(
            media_type=media_type,
            media=media,
            progress=progress,
            show=show,
            app_version=app_version,
            app_date=app_date,
        )
        self._refresh_continue_watching_cache()
        return response

    def get_trakt_playback_resume(
        self,
        media_type: MediaType,
        *,
        start_at: Optional[datetime] = None,
        end_at: Optional[datetime] = None,
    ) -> Sequence[PlaybackEntry]:
        return self._require_trakt().get_playback_resume(
            media_type,
            start_at=start_at,
            end_at=end_at,
        )

    def trakt_rate_limit(self) -> Optional[RateLimitInfo]:
        if self._trakt is None:
            return None
        return self._trakt.rate_limit()

    def trakt_catalog(
        self,
        media_type: MediaType,
        category: str,
        *,
        period: Optional[str] = None,
        limit: int = 40,
        username: str = "me",
    ) -> Sequence[CatalogItem]:
        if self._trakt is None:
            return []
        return self._trakt.catalog_list(
            media_type,
            category,
            period=period,
            limit=limit,
            username=username,
        )

    def trakt_playback(
        self,
        media_type: MediaType,
        *,
        limit: int = 50,
    ) -> Sequence[CatalogItem]:
        if self._trakt is None:
            return []
        return self._trakt.get_in_progress(media_type, limit=limit)

    def search_trakt(
        self,
        query: str,
        *,
        types: Optional[Sequence[MediaType]] = None,
        limit: int = 10,
        year: Optional[int] = None,
    ) -> Sequence[TraktSearchResult]:
        return self._require_trakt().search(
            query,
            types=types,
            limit=limit,
            year=year,
        )

    # ------------------------------------------------------------------
    # Widget caching
    # ------------------------------------------------------------------
    def get_widget(self, widget_key: str) -> Optional[Any]:
        record = self.get_widget_record(widget_key)
        return None if record is None else record["payload"]

    def get_widget_record(self, widget_key: str) -> Optional[Mapping[str, Any]]:
        with db_connection() as conn:
            record = db_get_widget(conn, widget_key)
        if record is None:
            return None
        return {
            "payload": record["payload"],
            "last_updated": record["last_updated"],
            "ttl_seconds": record["ttl_seconds"],
        }

    def cache_widget(self, widget_key: str, payload: Any, *, ttl_seconds: int) -> None:
        serializable = _to_serializable(payload)
        randomized = _apply_daily_randomization(widget_key, serializable)
        with db_connection() as conn:
            db_set_widget(conn, widget_key, randomized, ttl_seconds)

    def ensure_trakt_catalog_widget(
        self,
        category: str,
        *,
        period: str = "daily",
        per_page: int = 10,
        max_pages: int = 10,
        max_items: Optional[int] = None,
        related_ids: Optional[Mapping[MediaType, str]] = None,
    ) -> Mapping[str, Any]:
        widget_key = _trakt_widget_key(category)
        record = self.get_widget_record(widget_key)
        if record is not None:
            return record["payload"]

        return self.refresh_trakt_catalog_widget(
            category,
            period=period,
            per_page=per_page,
            max_pages=max_pages,
            max_items=max_items,
            related_ids=related_ids,
        )

    def refresh_trakt_catalog_widget(
        self,
        category: str,
        *,
        period: str = "daily",
        per_page: int = 10,
        max_pages: int = 10,
        max_items: Optional[int] = None,
        related_ids: Optional[Mapping[MediaType, str]] = None,
    ) -> Mapping[str, Any]:
        trakt = self._require_trakt()
        widgets = trakt.get_catalog_widget_bundle(
            category,
            period=period,
            per_page=per_page,
            max_pages=max_pages,
            max_items=max_items,
            related_ids=related_ids,
        )

        movies = widgets.get("movies") or CatalogWidget(
            items=[],
            pagination=PaginationDetails(page=1, per_page=per_page, has_next=False),
        )
        shows = widgets.get("shows") or CatalogWidget(
            items=[],
            pagination=PaginationDetails(page=1, per_page=per_page, has_next=False),
        )

        self._persist_catalog_titles(movies.items)
        self._persist_catalog_titles(shows.items)

        movie_pages = [page.model_dump(mode="json") for page in movies.iter_pages()]
        show_pages = [page.model_dump(mode="json") for page in shows.iter_pages()]

        payload = {
            "category": category.lower(),
            "period": period,
            "movies": movies.model_dump(mode="json"),
            "movies_pages": movie_pages,
            "shows": shows.model_dump(mode="json"),
            "shows_pages": show_pages,
        }

        self.cache_widget(_trakt_widget_key(category), payload, ttl_seconds=60 * 60 * 24)
        return payload

    def get_trakt_continue_watching(
        self,
        *,
        movie_limit: int = 25,
        show_limit: int = 25,
        history_window: int = 20,
    ) -> Mapping[str, Any]:
        self._require_trakt()
        params = (int(movie_limit), int(show_limit), int(history_window))
        if self._continue_watching_cache is not None and self._continue_watching_cache_params == params:
            ts = self._continue_watching_cache_ts
            if ts is not None and ts.astimezone().date() == date.today():
                return self._continue_watching_cache.model_dump(mode="json")

        self._refresh_continue_watching_cache(params)

        payload = self._continue_watching_cache or ContinueWatchingPayload()
        return payload.model_dump(mode="json")

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------
    def _persist_catalog_titles(self, items: Sequence[CatalogWidgetItem]) -> None:
        if not items:
            return

        seen_ids: set[str] = set()
        with db_connection() as conn:
            for entry in items:
                media = entry.media
                tmdb_id = _catalog_item_tmdb_id(media)
                if not tmdb_id or tmdb_id in seen_ids:
                    continue
                seen_ids.add(tmdb_id)
                try:
                    upsert_title(
                        conn,
                        tmdb_id=tmdb_id,
                        type=media.type.value,
                        title=media.title,
                        year=media.year,
                        overview=media.overview,
                        poster_url=_catalog_item_poster_url(media),
                        backdrop_url=_catalog_item_backdrop_url(media),
                    )
                except Exception as exc:  # pragma: no cover - persistence guard
                    self._log.debug(
                        "Failed to persist Trakt widget title %s: %s",
                        media.title,
                        exc,
                    )
                    continue

    def _require_trakt(self) -> TraktManager:
        if self._trakt is None:
            if self._trakt_error is not None:
                raise RuntimeError(
                    "Trakt manager is unavailable; ensure OAuth credentials are configured"
                ) from self._trakt_error
            raise RuntimeError("Trakt manager is unavailable")
        return self._trakt

    def _refresh_continue_watching_cache(
        self,
        params: Optional[Tuple[int, int, int]] = None,
    ) -> None:
        if self._trakt is None:
            self._continue_watching_cache = None
            self._continue_watching_cache_ts = None
            return

        limits = params or self._continue_watching_cache_params or (25, 25, 20)
        try:
            payload = self._trakt.get_continue_watching(
                movie_limit=limits[0],
                show_limit=limits[1],
                history_window=limits[2],
            )
        except Exception as exc:  # pragma: no cover - network variability
            self._log.debug("trakt_continue_watching_refresh_failed", exc_info=exc)
            self._continue_watching_cache = None
            self._continue_watching_cache_ts = None
            return

        if not isinstance(payload, ContinueWatchingPayload):
            try:
                payload = ContinueWatchingPayload.model_validate(payload)
            except ValidationError:
                self._continue_watching_cache = None
                self._continue_watching_cache_ts = None
                return

        self._continue_watching_cache = payload
        self._continue_watching_cache_params = limits
        self._continue_watching_cache_ts = datetime.now(timezone.utc)


def _to_serializable(payload: Any) -> Any:
    if hasattr(payload, "model_dump"):
        return payload.model_dump(mode="json")  # type: ignore[no-any-return]
    if isinstance(payload, Mapping):
        return {k: _to_serializable(v) for k, v in payload.items()}
    if isinstance(payload, Sequence) and not isinstance(payload, (str, bytes, bytearray)):
        return [_to_serializable(item) for item in payload]
    return payload


def _apply_daily_randomization(widget_key: str, payload: Any) -> Any:
    day_key = date.today().isoformat()
    seed = _daily_seed(widget_key, day_key)
    if isinstance(payload, Mapping):
        data = {k: _to_serializable(v) for k, v in payload.items()}
        items = payload.get("items")
        if isinstance(items, Sequence) and not isinstance(items, (str, bytes, bytearray, Mapping)):
            shuffled = list(_to_serializable(i) for i in items)
            random.Random(seed).shuffle(shuffled)
            data["items"] = shuffled
        return data
    if isinstance(payload, Sequence) and not isinstance(payload, (str, bytes, bytearray, Mapping)):
        items = list(_to_serializable(item) for item in payload)
        random.Random(seed).shuffle(items)
        return items
    return payload


def _daily_seed(widget_key: str, day_key: str) -> int:
    digest = hashlib.sha256(f"{widget_key}:{day_key}".encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big")


def _trakt_widget_key(category: str) -> str:
    normalized = category.strip().lower().replace(" ", "_")
    return f"trakt_{normalized}"


def _catalog_item_tmdb_id(item: CatalogItem) -> Optional[str]:
    extra = item.extra or {}
    ids_payload = extra.get("ids")
    if isinstance(ids_payload, Mapping):
        tmdb_id = ids_payload.get("tmdb")
        if tmdb_id:
            return str(tmdb_id)
    return None


def _catalog_item_poster_url(item: CatalogItem) -> Optional[str]:
    if item.poster and item.poster.url:
        return str(item.poster.url)

    extra = item.extra or {}
    raw_payload = extra.get("raw_payload")
    if isinstance(raw_payload, Mapping):
        images = raw_payload.get("images")
        if isinstance(images, Mapping):
            poster = images.get("poster")
            if isinstance(poster, Mapping):
                for key in ("full", "medium", "thumb"):
                    value = poster.get(key)
                    if isinstance(value, str) and value:
                        return value
        poster_url = raw_payload.get("poster") or raw_payload.get("poster_path")
        if isinstance(poster_url, str) and poster_url:
            return poster_url
    return None


def _catalog_item_backdrop_url(item: CatalogItem) -> Optional[str]:
    extra = item.extra or {}
    raw_payload = extra.get("raw_payload")
    if isinstance(raw_payload, Mapping):
        for key in ("backdrop", "background", "fanart"):
            value = raw_payload.get(key)
            if isinstance(value, str) and value:
                return value
        images = raw_payload.get("images")
        if isinstance(images, Mapping):
            for key in ("fanart", "screenshot", "background", "banner"):
                image_entry = images.get(key)
                if isinstance(image_entry, Mapping):
                    for variant in ("full", "medium", "thumb"):
                        candidate = image_entry.get(variant)
                        if isinstance(candidate, str) and candidate:
                            return candidate
        backdrop_path = raw_payload.get("backdrop_path")
        if isinstance(backdrop_path, str) and backdrop_path:
            return backdrop_path
    return None


__all__ = ["InformationProviders", "SourceDescriptor"]
