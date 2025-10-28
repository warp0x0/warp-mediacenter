"""Normalized media metadata models used across provider integrations.

The goal of this module is to keep the rest of the application source agnostic by
providing typed structures that represent the core media concepts consumed by the
UI. Provider specific payloads are adapted into these models through the
:class:`MediaModelFacade` helpers defined at the bottom of the module.
"""

from __future__ import annotations

from datetime import date
from enum import Enum
from typing import Any, Dict, Iterable, Mapping, Optional, Sequence

from pydantic import AnyHttpUrl, BaseModel, Field, TypeAdapter, ValidationError


_ANY_HTTP_URL = TypeAdapter(AnyHttpUrl)


class MediaType(str, Enum):
    """Normalized set of media categories supported by the application."""

    MOVIE = "movie"
    SHOW = "show"
    SEASON = "season"
    EPISODE = "episode"


class QualityTag(str, Enum):
    """Rough quality buckets used when exposing stream sources to the UI."""

    SD = "sd"  # 480p and below
    HD = "hd"  # 720p
    FHD = "fhd"  # 1080p
    UHD_4K = "uhd_4k"
    UHD_8K = "uhd_8k"
    AUDIO_ONLY = "audio_only"


class LicenseTag(str, Enum):
    """Represents public domain or Creative Commons style licenses."""

    PUBLIC_DOMAIN = "public_domain"
    CC0 = "cc0"
    CC_BY = "cc_by"
    CC_BY_SA = "cc_by_sa"
    CC_BY_NC = "cc_by_nc"
    CC_BY_NC_SA = "cc_by_nc_sa"
    CC_BY_ND = "cc_by_nd"
    CC_BY_NC_ND = "cc_by_nc_nd"
    UNKNOWN = "unknown"


class ImageAsset(BaseModel):
    """Metadata about an image associated with a media entity."""

    url: str
    width: Optional[int] = None
    height: Optional[int] = None
    aspect_ratio: Optional[float] = Field(default=None, ge=0)
    language: Optional[str] = Field(default=None, description="BCP-47 language tag")


class CaptionTrack(BaseModel):
    """Represents a caption or subtitle track for a stream source."""

    url: AnyHttpUrl
    language: str = Field(description="Human readable language, e.g. 'en-US'.")
    mime_type: Optional[str] = None
    is_default: bool = False


class PersonCredit(BaseModel):
    """Base credit information shared by cast and crew entries."""

    name: str
    person_id: Optional[str] = Field(default=None, description="Provider specific identifier")
    profile_image: Optional[ImageAsset] = None


class CastMember(PersonCredit):
    """A performer credit within :class:`Credits`."""

    character: Optional[str] = None
    order: Optional[int] = Field(default=None, ge=0)


class CrewMember(PersonCredit):
    """A production or crew credit within :class:`Credits`."""

    department: Optional[str] = None
    job: Optional[str] = None


class Credits(BaseModel):
    """Collection of cast and crew information for a media entity."""

    cast: Sequence[CastMember] = Field(default_factory=list)
    crew: Sequence[CrewMember] = Field(default_factory=list)


class MediaBase(BaseModel):
    """Common fields for movies, shows, seasons, and episodes."""

    id: str
    source: str = Field(description="Identifier of the upstream provider (tmdb, trakt, etc.)")
    type: MediaType
    title: str
    overview: Optional[str] = None
    original_language: Optional[str] = None
    poster: Optional[ImageAsset] = None
    backdrop: Optional[ImageAsset] = None
    genres: Sequence[str] = Field(default_factory=list)
    keywords: Sequence[str] = Field(default_factory=list)
    external_ids: Mapping[str, str] = Field(default_factory=dict)
    homepage: Optional[AnyHttpUrl] = None
    popularity: Optional[float] = None
    vote_average: Optional[float] = None
    vote_count: Optional[int] = Field(default=None, ge=0)
    credits: Optional[Credits] = None


class SeasonSummary(BaseModel):
    """Shallow representation of a season used when embedding in shows."""

    season_number: int = Field(ge=0)
    episode_count: Optional[int] = Field(default=None, ge=0)
    title: Optional[str] = None
    overview: Optional[str] = None
    poster: Optional[ImageAsset] = None


class Episode(MediaBase):
    type: MediaType = Field(default=MediaType.EPISODE, frozen=True)
    season_number: Optional[int] = Field(default=None, ge=0)
    episode_number: Optional[int] = Field(default=None, ge=0)
    runtime_minutes: Optional[int] = Field(default=None, ge=0)
    air_date: Optional[date] = None
    still_frame: Optional[ImageAsset] = None


class Season(MediaBase):
    type: MediaType = Field(default=MediaType.SEASON, frozen=True)
    season_number: int = Field(ge=0)
    air_date: Optional[date] = None
    episodes: Sequence[Episode] = Field(default_factory=list)


class Movie(MediaBase):
    type: MediaType = Field(default=MediaType.MOVIE, frozen=True)
    release_date: Optional[date] = None
    runtime_minutes: Optional[int] = Field(default=None, ge=0)
    tagline: Optional[str] = None
    status: Optional[str] = None


class Show(MediaBase):
    type: MediaType = Field(default=MediaType.SHOW, frozen=True)
    first_air_date: Optional[date] = None
    last_air_date: Optional[date] = None
    in_production: Optional[bool] = None
    number_of_seasons: Optional[int] = Field(default=None, ge=0)
    number_of_episodes: Optional[int] = Field(default=None, ge=0)
    episode_run_time: Sequence[int] = Field(default_factory=list)
    networks: Sequence[str] = Field(default_factory=list)
    seasons: Sequence[SeasonSummary] = Field(default_factory=list)


class CatalogItem(BaseModel):
    """Generic item returned when browsing curated or aggregated catalogs."""

    id: str
    title: str
    type: MediaType
    source_tag: str
    year: Optional[int] = Field(default=None, ge=1800)
    overview: Optional[str] = None
    poster: Optional[ImageAsset] = None
    license: Optional[LicenseTag] = None
    rating: Optional[float] = None
    genres: Sequence[str] = Field(default_factory=list)
    origin_country: Optional[str] = None
    external_url: Optional[AnyHttpUrl] = None
    extra: Mapping[str, Any] = Field(default_factory=dict)


class StreamSource(BaseModel):
    """Represents a single playback option for a catalog item."""

    url: AnyHttpUrl
    quality: Optional[QualityTag] = None
    mime_type: Optional[str] = None
    size_bytes: Optional[int] = Field(default=None, ge=0)
    license: Optional[LicenseTag] = None
    captions: Sequence[CaptionTrack] = Field(default_factory=list)
    is_download: bool = False
    source_tag: Optional[str] = None


def _stringify(value: Any) -> Optional[str]:
    if value is None:
        return None
    if isinstance(value, str):
        return value

    return str(value)


def _extract_id(payload: Mapping[str, Any]) -> str:
    """Resolve the most appropriate identifier from provider payloads."""

    for key in ("id", "tmdb_id", "trakt_id", "imdb_id"):
        value = payload.get(key)
        if value:
            return str(value)

    ids = payload.get("ids")
    if isinstance(ids, Mapping):
        for key in ("tmdb", "trakt", "imdb", "slug"):
            value = ids.get(key)
            if value:
                return str(value)

    raise ValueError("Unable to determine identifier from payload")


def _extract_title(payload: Mapping[str, Any]) -> str:
    for key in ("title", "name"):
        value = payload.get(key)
        if value:
            return str(value)

    raise ValueError("Missing title in payload")


def _extract_overview(payload: Mapping[str, Any]) -> Optional[str]:
    for key in ("overview", "description", "summary"):
        value = payload.get(key)
        if value:
            return str(value)

    return None


def _build_image(url: Optional[str], **extra: Any) -> Optional[ImageAsset]:
    if not url:
        return None

    try:
        return ImageAsset(url=str(url), **extra)
    except ValidationError:
        return None


def _normalize_ids(payload: Mapping[str, Any]) -> Dict[str, str]:
    ids = payload.get("ids")
    if isinstance(ids, Mapping):
        return {str(k): str(v) for k, v in ids.items() if v is not None}

    return {}


def _normalize_external_ids(payload: Mapping[str, Any]) -> Dict[str, str]:
    external = payload.get("external_ids")
    if isinstance(external, Mapping):
        return {str(k): str(v) for k, v in external.items() if v is not None}

    return _normalize_ids(payload)


def _extract_keywords(payload: Mapping[str, Any]) -> Sequence[str]:
    keywords = payload.get("keywords")
    if isinstance(keywords, Mapping):
        names = keywords.get("names")
        if isinstance(names, Iterable):
            return [str(v) for v in names if v]

        return [str(v) for v in keywords.values() if isinstance(v, str)]
    if isinstance(keywords, Iterable) and not isinstance(keywords, (str, bytes)):
        return [str(v) for v in keywords if v]

    return []


def _extract_genres(payload: Mapping[str, Any]) -> Sequence[str]:
    genres = payload.get("genres")
    if isinstance(genres, Iterable) and not isinstance(genres, (str, bytes)):
        values: list[str] = []
        for item in genres:
            if isinstance(item, Mapping):
                name = item.get("name")
                if name:
                    values.append(str(name))
            elif item:
                values.append(str(item))

        return values

    return []


def _extract_year(payload: Mapping[str, Any]) -> Optional[int]:
    """Attempt to normalize a release year from common payload fields."""

    year_fields = (
        "year",
        "release_year",
        "first_air_year",
        "air_year",
    )

    for key in year_fields:
        value = payload.get(key)
        if value is None:
            continue
        try:
            year = int(value)
        except (TypeError, ValueError):
            continue
        if year >= 1800:
            return year

    date_fields = (
        "release_date",
        "first_air_date",
        "air_date",
        "premiered",
    )

    for key in date_fields:
        value = payload.get(key)
        if not value:
            continue
        try:
            # ``fromisoformat`` supports the YYYY-MM-DD format returned by TMDb
            parsed = date.fromisoformat(str(value))
        except ValueError:
            continue
        if parsed.year >= 1800:
            return parsed.year

    return None


def _extract_media_dates(payload: Mapping[str, Any]) -> Dict[str, Optional[date]]:
    def _parse(value: Any) -> Optional[date]:
        if not value:
            return None
        if isinstance(value, date):
            return value
        try:
            return date.fromisoformat(str(value))
        except ValueError:
            return None

    return {
        "release_date": _parse(payload.get("release_date") or payload.get("premiered")),
        "first_air_date": _parse(payload.get("first_air_date") or payload.get("firstAired")),
        "last_air_date": _parse(payload.get("last_air_date") or payload.get("lastAired")),
        "air_date": _parse(payload.get("air_date")),
    }


def _extract_runtime(payload: Mapping[str, Any]) -> Optional[int]:
    runtime = payload.get("runtime") or payload.get("runtime_minutes")
    if runtime is None:
        return None
    try:
        value = int(runtime)
        return value if value >= 0 else None
    except (TypeError, ValueError):
        return None


def _extract_episode_runtimes(payload: Mapping[str, Any]) -> Sequence[int]:
    runtimes = payload.get("episode_run_time") or payload.get("runtime")
    if isinstance(runtimes, Iterable) and not isinstance(runtimes, (str, bytes)):
        values: list[int] = []
        for entry in runtimes:
            try:
                ivalue = int(entry)
            except (TypeError, ValueError):
                continue
            if ivalue >= 0:
                values.append(ivalue)
        return values

    if runtimes is not None:
        runtime = _extract_runtime({"runtime": runtimes})
        if runtime is not None:
            return [runtime]

    runtime_single = _extract_runtime(payload)
    return [runtime_single] if runtime_single is not None else []


def _extract_networks(payload: Mapping[str, Any]) -> Sequence[str]:
    networks = payload.get("networks")
    if isinstance(networks, Iterable) and not isinstance(networks, (str, bytes)):
        values: list[str] = []
        for entry in networks:
            if isinstance(entry, Mapping):
                name = entry.get("name")
                if name:
                    values.append(str(name))
            elif entry:
                values.append(str(entry))
        return values

    return []


def _validate_homepage(url: Any) -> Optional[AnyHttpUrl]:
    if not url:
        return None
    try:
        return _ANY_HTTP_URL.validate_python(url)
    except ValidationError:
        return None


def _build_common_fields(
    payload: Mapping[str, Any],
    *,
    source: str,
    media_type: MediaType,
    overrides: Optional[Mapping[str, Any]] = None,
) -> Dict[str, Any]:
    data: Dict[str, Any] = {
        "id": _extract_id(payload),
        "source": source,
        "type": media_type,
        "title": _extract_title(payload),
        "overview": _extract_overview(payload),
        "original_language": _stringify(payload.get("original_language") or payload.get("language")),
        "poster": _build_image(
            payload.get("poster_url") or payload.get("poster_path") or payload.get("image"),
            width=payload.get("poster_width"),
            height=payload.get("poster_height"),
        ),
        "backdrop": _build_image(
            payload.get("backdrop_url") or payload.get("backdrop_path") or payload.get("background"),
            width=payload.get("backdrop_width"),
            height=payload.get("backdrop_height"),
        ),
        "genres": _extract_genres(payload),
        "keywords": _extract_keywords(payload),
        "external_ids": _normalize_external_ids(payload),
        "popularity": payload.get("popularity"),
        "vote_average": payload.get("vote_average"),
        "vote_count": payload.get("vote_count"),
    }

    homepage = _validate_homepage(payload.get("homepage"))
    if homepage is not None:
        data["homepage"] = homepage

    if overrides:
        data.update({k: v for k, v in overrides.items() if v is not None})

    return data


class MediaModelFacade:
    """Thin façade to create normalized media models from provider payloads."""

    def movie(
        self,
        payload: Mapping[str, Any],
        *,
        source: str,
        overrides: Optional[Mapping[str, Any]] = None,
        credits: Optional[Credits] = None,
    ) -> Movie:
        dates = _extract_media_dates(payload)
        runtime = _extract_runtime(payload)
        data = _build_common_fields(payload, source=source, media_type=MediaType.MOVIE, overrides=overrides)
        data.update(
            {
                "release_date": dates["release_date"],
                "runtime_minutes": runtime,
                "tagline": payload.get("tagline"),
                "status": payload.get("status"),
                "credits": credits,
            }
        )

        return Movie.model_validate(data)

    def show(
        self,
        payload: Mapping[str, Any],
        *,
        source: str,
        overrides: Optional[Mapping[str, Any]] = None,
        credits: Optional[Credits] = None,
        seasons: Optional[Sequence[SeasonSummary]] = None,
    ) -> Show:
        dates = _extract_media_dates(payload)
        data = _build_common_fields(payload, source=source, media_type=MediaType.SHOW, overrides=overrides)
        data.update(
            {
                "first_air_date": dates["first_air_date"],
                "last_air_date": dates["last_air_date"],
                "in_production": payload.get("in_production"),
                "number_of_seasons": payload.get("number_of_seasons"),
                "number_of_episodes": payload.get("number_of_episodes"),
                "episode_run_time": _extract_episode_runtimes(payload),
                "networks": _extract_networks(payload),
                "seasons": seasons or [],
                "credits": credits,
            }
        )

        return Show.model_validate(data)

    def season(
        self,
        payload: Mapping[str, Any],
        *,
        source: str,
        overrides: Optional[Mapping[str, Any]] = None,
        episodes: Optional[Sequence[Episode]] = None,
    ) -> Season:
        dates = _extract_media_dates(payload)
        data = _build_common_fields(payload, source=source, media_type=MediaType.SEASON, overrides=overrides)
        data.update(
            {
                "season_number": payload.get("season_number") or payload.get("number") or 0,
                "air_date": dates["air_date"],
                "episodes": episodes or [],
            }
        )

        return Season.model_validate(data)

    def episode(
        self,
        payload: Mapping[str, Any],
        *,
        source: str,
        overrides: Optional[Mapping[str, Any]] = None,
        credits: Optional[Credits] = None,
    ) -> Episode:
        dates = _extract_media_dates(payload)
        runtime = _extract_runtime(payload)
        data = _build_common_fields(payload, source=source, media_type=MediaType.EPISODE, overrides=overrides)
        data.update(
            {
                "season_number": payload.get("season") or payload.get("season_number"),
                "episode_number": payload.get("episode") or payload.get("episode_number"),
                "runtime_minutes": runtime,
                "air_date": dates["air_date"],
                "still_frame": _build_image(payload.get("still_path") or payload.get("still")),
                "credits": credits,
            }
        )

        return Episode.model_validate(data)

    def catalog_item(
        self,
        payload: Mapping[str, Any],
        *,
        source_tag: str,
        media_type: MediaType,
        overrides: Optional[Mapping[str, Any]] = None,
    ) -> CatalogItem:
        extra_payload: Dict[str, Any] = {}
        raw_extra = payload.get("extra")
        if isinstance(raw_extra, Mapping):
            extra_payload.update(raw_extra)

        ids_payload = _normalize_ids(payload)
        if ids_payload and "ids" not in extra_payload:
            extra_payload["ids"] = ids_payload

        data: Dict[str, Any] = {
            "id": _extract_id(payload),
            "title": _extract_title(payload),
            "type": media_type,
            "source_tag": source_tag,
            "overview": _extract_overview(payload),
            "poster": _build_image(payload.get("poster") or payload.get("poster_url")),
            "genres": _extract_genres(payload),
            "extra": extra_payload,
        }

        year = _extract_year(payload)
        if year is not None:
            data["year"] = year

        origin_country = payload.get("origin_country") or payload.get("country")
        if origin_country:
            if isinstance(origin_country, Iterable) and not isinstance(origin_country, (str, bytes)):
                countries = [str(entry) for entry in origin_country if entry]
                if countries:
                    data["origin_country"] = ",".join(countries)
            else:
                data["origin_country"] = str(origin_country)

        rating = payload.get("rating")
        if rating is None:
            rating = payload.get("vote_average")
        if rating is not None:
            try:
                data["rating"] = float(rating)
            except (TypeError, ValueError):
                pass

        external_url = payload.get("external_url") or payload.get("url")
        validated_url = _validate_homepage(external_url)
        if validated_url is not None:
            data["external_url"] = validated_url

        license_tag = payload.get("license") or payload.get("license_tag")
        if isinstance(license_tag, str):
            try:
                data["license"] = LicenseTag(license_tag.lower())
            except ValueError:
                data["license"] = LicenseTag.UNKNOWN
        elif isinstance(license_tag, LicenseTag):
            data["license"] = license_tag

        # Preserve the original payload so that downstream consumers do not lose
        # any metadata fields that were not normalized explicitly above.
        extra_payload.setdefault(
            "raw_payload", {str(key): value for key, value in payload.items()}
        )

        if overrides:
            data.update({k: v for k, v in overrides.items() if v is not None})

        return CatalogItem.model_validate(data)

    def stream_source(
        self,
        payload: Mapping[str, Any],
        *,
        source_tag: str,
        overrides: Optional[Mapping[str, Any]] = None,
    ) -> StreamSource:
        quality = payload.get("quality")
        quality_tag: Optional[QualityTag] = None
        if isinstance(quality, str):
            normalized = quality.lower().replace("-", "_")
            try:
                quality_tag = QualityTag(normalized)
            except ValueError:
                quality_tag = None
        elif isinstance(quality, QualityTag):
            quality_tag = quality

        license_tag = payload.get("license")
        license_value: Optional[LicenseTag] = None
        if isinstance(license_tag, str):
            normalized = license_tag.lower()
            try:
                license_value = LicenseTag(normalized)
            except ValueError:
                license_value = LicenseTag.UNKNOWN
        elif isinstance(license_tag, LicenseTag):
            license_value = license_tag

        captions_payload = payload.get("captions")
        captions: list[CaptionTrack] = []
        if isinstance(captions_payload, Iterable) and not isinstance(captions_payload, (str, bytes)):
            for item in captions_payload:
                if not isinstance(item, Mapping):
                    continue
                try:
                    captions.append(
                        CaptionTrack(
                            url=item.get("url"),
                            language=item.get("language", "und"),
                            mime_type=item.get("mime_type"),
                            is_default=bool(item.get("default")),
                        )
                    )
                except ValidationError:
                    continue

        data: Dict[str, Any] = {
            "url": payload.get("url"),
            "quality": quality_tag,
            "mime_type": payload.get("mime_type"),
            "size_bytes": payload.get("size") or payload.get("size_bytes"),
            "license": license_value,
            "captions": captions,
            "is_download": bool(payload.get("is_download")),
            "source_tag": source_tag,
        }

        if overrides:
            data.update({k: v for k, v in overrides.items() if v is not None})

        return StreamSource.model_validate(data)


__all__ = [
    "MediaType",
    "QualityTag",
    "LicenseTag",
    "ImageAsset",
    "CaptionTrack",
    "PersonCredit",
    "CastMember",
    "CrewMember",
    "Credits",
    "MediaBase",
    "SeasonSummary",
    "Episode",
    "Season",
    "Movie",
    "Show",
    "CatalogItem",
    "StreamSource",
    "MediaModelFacade",
]
