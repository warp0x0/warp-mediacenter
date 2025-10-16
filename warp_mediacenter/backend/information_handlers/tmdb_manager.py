"""Higher level TMDb helper built on top of :mod:`network_handlers`.

The manager focuses on read-only access patterns that the rest of the
information-handlers package depends on:

* text searches for movies and shows
* detailed payload lookups (movies, shows, seasons, episodes)
* auxiliary metadata such as genre maps, images configuration, and credits
* normalized model construction via :class:`MediaModelFacade`

Every network request is routed through :class:`HttpSession`, providing the
configured retry/backoff behaviour and proxy support.  Results are memoized via
the :class:`InformationProviderCache` (in-memory LRU + disk TTL persistence),
which keeps the TMDb endpoints that we repeatedly call extremely fast while
avoiding unnecessary upstream traffic.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, Mapping, Optional, Sequence

from pydantic import ValidationError

from warp_mediacenter.backend.information_handlers.cache import (
    InformationProviderCache,
)
from warp_mediacenter.backend.information_handlers.models import (
    CatalogItem,
    CastMember,
    Credits,
    CrewMember,
    ImageAsset,
    MediaModelFacade,
    MediaType,
    Movie,
    Season,
    SeasonSummary,
    Show,
    Episode,
)
from warp_mediacenter.backend.network_handlers.session import HttpSession
from warp_mediacenter.config import settings

_SERVICE_NAME = "tmdb"


@dataclass(frozen=True)
class GenreMap:
    """Container with the genre identifier-to-name mapping."""

    media_type: MediaType
    language: str
    values: Dict[int, str]


class TMDbManager:
    """Thin wrapper around TMDb's REST API returning normalized models."""

    def __init__(
        self,
        *,
        session: Optional[HttpSession] = None,
        cache: Optional[InformationProviderCache] = None,
        facade: Optional[MediaModelFacade] = None,
        default_language: str = "en-US",
    ) -> None:
        self._session = session or HttpSession()
        self._cache = cache or InformationProviderCache()
        self._facade = facade or MediaModelFacade()
        self._default_language = default_language
        self._configuration: Optional[Dict[str, Any]] = None
        self._image_config: Dict[str, Any] = settings.get_tmdb_image_config() or {}

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------
    def search_movies(
        self,
        query: str,
        *,
        language: Optional[str] = None,
        page: int = 1,
        include_adult: bool = False,
    ) -> Sequence[CatalogItem]:
        payload = self._request_json(
            "/search/movie",
            params={
                "query": query,
                "language": self._normalize_language(language),
                "page": page,
                "include_adult": include_adult,
            },
        )

        results = []
        for result in payload.get("results", []) or []:
            if not isinstance(result, Mapping):
                continue
            overrides = self._image_overrides(result)
            try:
                results.append(
                    self._facade.catalog_item(
                        result,
                        source_tag=_SERVICE_NAME,
                        media_type=MediaType.MOVIE,
                        overrides=overrides,
                    )
                )
            except ValidationError:
                continue

        return results

    def search_shows(
        self,
        query: str,
        *,
        language: Optional[str] = None,
        page: int = 1,
    ) -> Sequence[CatalogItem]:
        payload = self._request_json(
            "/search/tv",
            params={
                "query": query,
                "language": self._normalize_language(language),
                "page": page,
            },
        )

        results = []
        for result in payload.get("results", []) or []:
            if not isinstance(result, Mapping):
                continue
            overrides = self._image_overrides(result)
            try:
                results.append(
                    self._facade.catalog_item(
                        result,
                        source_tag=_SERVICE_NAME,
                        media_type=MediaType.SHOW,
                        overrides=overrides,
                    )
                )
            except ValidationError:
                continue

        return results

    def movie_details(
        self,
        movie_id: int | str,
        *,
        language: Optional[str] = None,
        include_credits: bool = True,
    ) -> Movie:
        params: Dict[str, Any] = {"language": self._normalize_language(language)}
        if include_credits:
            params["append_to_response"] = "credits,keywords,release_dates"

        payload = self._request_json(f"/movie/{movie_id}", params=params)
        credits_payload = payload.get("credits") if include_credits else None
        credits = self._build_credits(credits_payload) if credits_payload else None

        overrides = self._image_overrides(payload)

        return self._facade.movie(payload, source=_SERVICE_NAME, overrides=overrides, credits=credits)

    def show_details(
        self,
        show_id: int | str,
        *,
        language: Optional[str] = None,
        include_credits: bool = True,
    ) -> Show:
        params: Dict[str, Any] = {"language": self._normalize_language(language)}
        if include_credits:
            params["append_to_response"] = "credits,keywords"

        payload = self._request_json(f"/tv/{show_id}", params=params)
        credits_payload = payload.get("credits") if include_credits else None
        credits = self._build_credits(credits_payload) if credits_payload else None

        seasons_payload = [s for s in payload.get("seasons", []) if isinstance(s, Mapping)]
        seasons: list[SeasonSummary] = []
        for season in seasons_payload:
            overrides = self._image_overrides(season)
            try:
                seasons.append(
                    SeasonSummary(
                        season_number=int(season.get("season_number") or 0),
                        episode_count=season.get("episode_count"),
                        title=season.get("name"),
                        overview=season.get("overview"),
                        poster=overrides.get("poster"),
                    )
                )
            except (ValidationError, ValueError):
                continue

        overrides = self._image_overrides(payload)

        return self._facade.show(
            payload,
            source=_SERVICE_NAME,
            overrides=overrides,
            credits=credits,
            seasons=seasons,
        )

    def season_details(
        self,
        show_id: int | str,
        season_number: int,
        *,
        language: Optional[str] = None,
        include_episodes: bool = True,
    ) -> Season:
        payload = self._request_json(
            f"/tv/{show_id}/season/{season_number}",
            params={"language": self._normalize_language(language)},
        )

        episodes: list[Episode] = []
        if include_episodes:
            for episode in payload.get("episodes", []) or []:
                if not isinstance(episode, Mapping):
                    continue
                overrides = self._image_overrides(episode)
                credits = self._build_credits(episode.get("credits")) if episode.get("credits") else None
                try:
                    episodes.append(
                        self._facade.episode(
                            episode,
                            source=_SERVICE_NAME,
                            overrides=overrides,
                            credits=credits,
                        )
                    )
                except ValidationError:
                    continue

        overrides = self._image_overrides(payload)

        return self._facade.season(
            payload,
            source=_SERVICE_NAME,
            overrides=overrides,
            episodes=episodes,
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
        params = {"language": self._normalize_language(language)}
        if include_credits:
            params["append_to_response"] = "credits"

        payload = self._request_json(
            f"/tv/{show_id}/season/{season_number}/episode/{episode_number}",
            params=params,
        )
        credits_payload = payload.get("credits") if include_credits else None
        credits = self._build_credits(credits_payload) if credits_payload else None
        overrides = self._image_overrides(payload)

        return self._facade.episode(
            payload,
            source=_SERVICE_NAME,
            overrides=overrides,
            credits=credits,
        )

    def movie_credits(self, movie_id: int | str) -> Credits:
        payload = self._request_json(f"/movie/{movie_id}/credits")

        return self._build_credits(payload)

    def show_credits(self, show_id: int | str) -> Credits:
        payload = self._request_json(f"/tv/{show_id}/credits")

        return self._build_credits(payload)

    def get_configuration(self, *, force_refresh: bool = False) -> Mapping[str, Any]:
        if self._configuration is not None and not force_refresh:
            return self._configuration

        payload = self._request_json("/configuration")
        if isinstance(payload, Mapping):
            images = payload.get("images")
            if isinstance(images, Mapping):
                self._image_config = dict(images)
        self._configuration = payload

        return payload

    def get_genre_map(
        self,
        media_type: MediaType,
        *,
        language: Optional[str] = None,
    ) -> GenreMap:
        if media_type not in {MediaType.MOVIE, MediaType.SHOW}:
            raise ValueError("Genre maps are only available for movies or shows")

        key = "movie" if media_type == MediaType.MOVIE else "tv"
        payload = self._request_json(
            f"/genre/{key}/list",
            params={"language": self._normalize_language(language)},
        )

        values: Dict[int, str] = {}
        for entry in payload.get("genres", []) or []:
            if not isinstance(entry, Mapping):
                continue
            try:
                genre_id = int(entry.get("id"))
            except (TypeError, ValueError):
                continue
            name = entry.get("name")
            if name:
                values[genre_id] = str(name)

        return GenreMap(media_type=media_type, language=self._normalize_language(language), values=values)

    def get_videos(
        self,
        media_type: MediaType,
        tmdb_id: int | str,
        *,
        language: Optional[str] = None,
    ) -> Sequence[Mapping[str, Any]]:
        if media_type not in {MediaType.MOVIE, MediaType.SHOW}:
            raise ValueError("Videos are only available for movies or shows")

        path = "/movie/{tmdb_id}/videos" if media_type == MediaType.MOVIE else "/tv/{tmdb_id}/videos"
        payload = self._request_json(
            path.format(tmdb_id=tmdb_id),
            params={"language": self._normalize_language(language)},
        )

        videos = payload.get("results", []) or []
        return [v for v in videos if isinstance(v, Mapping)]

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------
    def _normalize_language(self, language: Optional[str]) -> str:
        return language or self._default_language

    def _request_json(self, path: str, *, params: Optional[Mapping[str, Any]] = None) -> Dict[str, Any]:
        cached = self._cache.get(_SERVICE_NAME, path, params)
        if cached is not None:
            if isinstance(cached, Mapping):
                return dict(cached)
            return cached  # type: ignore[return-value]

        response = self._session.get(_SERVICE_NAME, path, params=dict(params or {}))
        try:
            payload = response.json()
        except ValueError as exc:  # pragma: no cover - defensive
            raise RuntimeError("TMDb returned a non-JSON payload") from exc

        self._cache.set(
            _SERVICE_NAME,
            path,
            params,
            payload,
            status_code=response.status_code,
        )

        if isinstance(payload, Mapping):
            return dict(payload)

        raise RuntimeError("Unexpected TMDb payload structure")

    def _image_overrides(self, payload: Mapping[str, Any]) -> Dict[str, Any]:
        overrides: Dict[str, Any] = {}

        poster = self._build_image_asset(payload.get("poster_path"), category="poster")
        if poster is not None:
            overrides["poster"] = poster

        backdrop = self._build_image_asset(payload.get("backdrop_path"), category="backdrop")
        if backdrop is not None:
            overrides["backdrop"] = backdrop

        still = self._build_image_asset(payload.get("still_path"), category="still")
        if still is not None:
            overrides.setdefault("still_frame", still)

        return overrides

    def _build_credits(self, payload: Optional[Mapping[str, Any]]) -> Credits:
        cast_entries: list[CastMember] = []
        crew_entries: list[CrewMember] = []
        if not isinstance(payload, Mapping):
            return Credits(cast=[], crew=[])

        cast_payload = payload.get("cast") or []
        for entry in cast_payload:
            if not isinstance(entry, Mapping):
                continue
            image = self._build_image_asset(entry.get("profile_path"), category="profile")
            try:
                cast_entries.append(
                    CastMember(
                        name=str(entry.get("name") or entry.get("original_name") or ""),
                        person_id=str(entry.get("id")) if entry.get("id") is not None else None,
                        profile_image=image,
                        character=entry.get("character"),
                        order=entry.get("order"),
                    )
                )
            except ValidationError:
                continue

        crew_payload = payload.get("crew") or []
        for entry in crew_payload:
            if not isinstance(entry, Mapping):
                continue
            image = self._build_image_asset(entry.get("profile_path"), category="profile")
            try:
                crew_entries.append(
                    CrewMember(
                        name=str(entry.get("name") or entry.get("original_name") or ""),
                        person_id=str(entry.get("id")) if entry.get("id") is not None else None,
                        profile_image=image,
                        department=entry.get("department"),
                        job=entry.get("job"),
                    )
                )
            except ValidationError:
                continue

        return Credits(cast=cast_entries, crew=crew_entries)

    def _build_image_asset(self, path: Any, *, category: str) -> Optional[ImageAsset]:
        if not path:
            return None

        base_url = self._image_config.get("secure_base_url") or self._image_config.get("base_url")
        if not base_url:
            return None

        base_url = base_url.rstrip("/")
        size_key = {
            "poster": "poster_sizes",
            "backdrop": "backdrop_sizes",
            "profile": "profile_sizes",
            "still": "still_sizes",
        }.get(category, "poster_sizes")

        sizes: Sequence[str] = self._image_config.get(size_key) or []
        preferred = self._preferred_size(sizes)
        full_url = f"{base_url}/{preferred}{path}"

        try:
            return ImageAsset(url=full_url)
        except ValidationError:
            return None

    def _preferred_size(self, sizes: Sequence[str]) -> str:
        if not sizes:
            return "original"
        preferred_order = ("w780", "w500", "w342", "w300", "w185", "original")
        for candidate in preferred_order:
            if candidate in sizes:
                return candidate
        return sizes[-1]


__all__ = ["TMDbManager", "GenreMap"]