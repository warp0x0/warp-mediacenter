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

from datetime import datetime
from typing import Any, Mapping, Optional, Sequence

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
    DeviceCode,
    HistoryEntry,
    OAuthToken,
    RateLimitInfo,
    ScrobbleResponse,
    TraktManager,
    TraktUserProfile,
    UserList,
)
from warp_mediacenter.backend.network_handlers.session import HttpSession


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
    def start_trakt_device_auth(self) -> DeviceCode:
        return self._require_trakt().start_device_auth()

    def poll_trakt_device_token(self, device_code: str) -> OAuthToken:
        return self._require_trakt().poll_device_token(device_code)

    def refresh_trakt_token(self) -> OAuthToken:
        return self._require_trakt().refresh_token()

    def get_trakt_profile(self, username: str = "me") -> TraktUserProfile:
        return self._require_trakt().get_profile(username)

    def get_trakt_user_lists(self, username: str = "me") -> Sequence[UserList]:
        return self._require_trakt().get_user_lists(username)

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
        ids: Mapping[str, Any],
        progress: float,
        action: str = "start",
    ) -> ScrobbleResponse:
        return self._require_trakt().scrobble(
            media_type=media_type,
            ids=ids,
            progress=progress,
            action=action,
        )

    def trakt_rate_limit(self) -> Optional[RateLimitInfo]:
        if self._trakt is None:
            return None
        return self._trakt.rate_limit()

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------
    def _require_trakt(self) -> TraktManager:
        if self._trakt is None:
            if self._trakt_error is not None:
                raise RuntimeError(
                    "Trakt manager is unavailable; ensure OAuth credentials are configured"
                ) from self._trakt_error
            raise RuntimeError("Trakt manager is unavailable")
        return self._trakt


__all__ = ["InformationProviders", "SourceDescriptor"]
