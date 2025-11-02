"""Trakt.tv integration helpers."""

from __future__ import annotations

import json
import time
from dataclasses import dataclass
from collections import OrderedDict
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, Iterator, List, Mapping, Optional, Sequence

from pydantic import BaseModel, ConfigDict, ValidationError, Field

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.information_handlers.models import (
    CatalogItem,
    MediaModelFacade,
    MediaType,
)
from warp_mediacenter.backend.network_handlers.session import (
    HttpSession,
    Unauthorized,
)
from warp_mediacenter.config import settings

_SERVICE_NAME = "trakt"
_TOKEN_FILENAME = "trakt_tokens.json"


class DeviceCode(BaseModel):
    device_code: str
    user_code: str
    verification_url: str
    expires_in: int
    interval: int


class DeviceAuthPollingError(RuntimeError):
    """Raised when the device code polling endpoint indicates a terminal state."""

    def __init__(
        self,
        error: str,
        description: Optional[str] = None,
        *,
        retry_interval: Optional[int] = None,
    ) -> None:
        message = description or error
        super().__init__(message)
        self.error = error
        self.description = description
        self.retry_interval = retry_interval

    @property
    def should_retry(self) -> bool:
        return self.error in {"authorization_pending", "slow_down", "temporarily_unavailable"}


class TraktReauthRequired(RuntimeError):
    """Raised when Trakt OAuth requires user re-authentication."""

    def __init__(self, reason: str) -> None:
        super().__init__(f"Trakt requires re-authentication ({reason})")
        self.reason = reason

    @property
    def payload(self) -> Dict[str, Any]:
        return {"reauth_required": True, "reason": self.reason}


class OAuthToken(BaseModel):
    access_token: str
    token_type: str
    expires_in: int
    refresh_token: Optional[str] = None
    scope: Optional[str] = None
    created_at: Optional[int] = None

    def ensure_created_at(self) -> int:
        created = self.created_at or int(time.time())
        if self.created_at is None:
            self.created_at = created
        return created


class StoredToken(BaseModel):
    """Token persisted on disk and cached in-memory."""

    model_config = ConfigDict(extra="ignore")

    access_token: str
    refresh_token: str
    scope: Optional[str] = None
    created_at: int
    expires_in: int
    expires_at: int
    token_type: str
    last_refresh_ymd: Optional[str] = None

    @classmethod
    def from_oauth(cls, token: OAuthToken, *, last_refresh_ymd: Optional[str] = None) -> "StoredToken":
        created_at = token.ensure_created_at()
        expires_at = created_at + int(token.expires_in)
        refresh = token.refresh_token or ""
        if not refresh:
            raise RuntimeError("Trakt did not return a refresh token")
        return cls(
            access_token=token.access_token,
            refresh_token=refresh,
            scope=token.scope,
            created_at=created_at,
            expires_in=int(token.expires_in),
            expires_at=expires_at,
            token_type=token.token_type,
            last_refresh_ymd=last_refresh_ymd or date.today().isoformat(),
        )

    def to_oauth(self) -> OAuthToken:
        return OAuthToken(
            access_token=self.access_token,
            token_type=self.token_type,
            expires_in=self.expires_in,
            refresh_token=self.refresh_token,
            scope=self.scope,
            created_at=self.created_at,
        )

    def is_expired(self, now_ts: float) -> bool:
        return now_ts >= float(self.expires_at)

    def is_near_expiry(self, now_ts: float, *, threshold: int = 600) -> bool:
        return now_ts >= float(self.expires_at) - threshold

    def with_refresh_date(self, refresh_date: date) -> "StoredToken":
        return self.model_copy(update={"last_refresh_ymd": refresh_date.isoformat()})


@dataclass
class RateLimitInfo:
    limit: Optional[int]
    remaining: Optional[int]
    reset_at: Optional[datetime]


class TraktUserProfile(BaseModel):
    username: str
    name: Optional[str] = None
    vip: Optional[bool] = None
    private: Optional[bool] = None
    joined_at: Optional[datetime] = None
    location: Optional[str] = None
    about: Optional[str] = None
    images: Optional[Mapping[str, Any]] = None


class UserList(BaseModel):
    name: str
    description: Optional[str] = None
    privacy: Optional[str] = None
    display_numbers: Optional[bool] = None
    item_count: Optional[int] = None
    comment_count: Optional[int] = None
    likes: Optional[int] = None
    updated_at: Optional[datetime] = None
    ids: Mapping[str, Any]


class HistoryEntry(BaseModel):
    id: int
    action: Optional[str] = None
    watched_at: Optional[datetime] = None
    type: MediaType
    media: CatalogItem


class ScrobbleResponse(BaseModel):
    id: Optional[int] = None
    action: Optional[str] = None
    progress: Optional[float] = None
    sharing: Optional[Mapping[str, Any]] = None
    media_type: MediaType
    media: CatalogItem


class PlaybackEntry(BaseModel):
    id: int
    progress: float
    paused_at: Optional[datetime]
    type: MediaType
    media: CatalogItem


class PaginationDetails(BaseModel):
    """Metadata describing a paginated Trakt response."""

    page: int = Field(ge=1)
    per_page: int = Field(ge=1)
    page_count: Optional[int] = Field(default=None, ge=1)
    item_count: Optional[int] = Field(default=None, ge=0)
    has_next: bool = False
    pages_fetched: int = Field(default=0, ge=0)
    items_fetched: int = Field(default=0, ge=0)


class CatalogWidgetItem(BaseModel):
    """Single catalog entry with auxiliary metrics for widget displays."""

    media: CatalogItem
    metrics: Mapping[str, Any] = Field(default_factory=dict)


class CatalogWidgetPage(BaseModel):
    """Represents a single UI page slice for a catalog widget."""

    page: int = Field(ge=1)
    items: Sequence[CatalogWidgetItem] = Field(default_factory=list)
    has_next: bool = False
    next_page_card: Optional[Mapping[str, Any]] = None

    def model_post_init(self, __context: Any) -> None:  # pragma: no cover - simple guard
        if self.has_next and self.next_page_card is None:
            object.__setattr__(
                self,
                "next_page_card",
                {
                    "type": "next_page",
                    "page": self.page + 1,
                    "page_size": len(self.items),
                },
            )


class CatalogWidget(BaseModel):
    """Aggregated catalog payload along with pagination metadata."""

    items: Sequence[CatalogWidgetItem] = Field(default_factory=list)
    pagination: PaginationDetails
    page_size: int = Field(default=10, ge=1)

    def iter_pages(self, *, page_size: Optional[int] = None) -> Iterator[CatalogWidgetPage]:
        """Yield widget items in fixed-size pages for UI consumption."""

        chunk_size = max(1, page_size or self.page_size)
        total = len(self.items)
        if total == 0:
            yield CatalogWidgetPage(page=1, items=[], has_next=False)
            return

        for index, start in enumerate(range(0, total, chunk_size), start=1):
            end = min(start + chunk_size, total)
            page_items = list(self.items[start:end])
            has_next = end < total
            yield CatalogWidgetPage(page=index, items=page_items, has_next=has_next)


class ContinueWatchingMovie(BaseModel):
    """Represents a movie resume entry."""

    playback_id: int
    progress: float
    paused_at: Optional[datetime] = None
    media: CatalogItem


class EpisodeProgress(BaseModel):
    """Episode progress details used within continue watching structures."""

    episode: CatalogItem
    season: Optional[int] = Field(default=None, ge=0)
    number: Optional[int] = Field(default=None, ge=0)
    completed: bool = False
    last_watched_at: Optional[datetime] = None
    playback_id: Optional[int] = None
    progress: Optional[float] = None
    paused_at: Optional[datetime] = None
    resume_available: bool = False


class ContinueWatchingShow(BaseModel):
    """Aggregated continue watching payload for a show."""

    show: CatalogItem
    episodes: Sequence[EpisodeProgress] = Field(default_factory=list)
    next_episode: Optional[EpisodeProgress] = None
    unwatched_count: int = Field(default=0, ge=0)


class ContinueWatchingPayload(BaseModel):
    """Combined continue watching payload for movies and shows."""

    movies: Sequence[ContinueWatchingMovie] = Field(default_factory=list)
    shows: Sequence[ContinueWatchingShow] = Field(default_factory=list)
    generated_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class TraktScrobbleConflict(RuntimeError):
    """Raised when Trakt rejects a scrobble because it was recently sent."""

    def __init__(
        self,
        *,
        watched_at: Optional[datetime],
        expires_at: Optional[datetime],
    ) -> None:
        message = "Trakt scrobble conflict"
        if expires_at is not None:
            message += f"; retry after {expires_at.isoformat()}"
        super().__init__(message)
        self.watched_at = watched_at
        self.expires_at = expires_at

    @property
    def retry_after(self) -> Optional[datetime]:
        return self.expires_at


class TraktUserSettings(BaseModel):
    user: TraktUserProfile
    account: Optional[Mapping[str, Any]] = None
    connections: Optional[Mapping[str, Any]] = None
    sharing: Optional[Mapping[str, Any]] = None
    limits: Optional[Mapping[str, Any]] = None
    privacy: Optional[Mapping[str, Any]] = None
    saved_filters: Optional[Sequence[Mapping[str, Any]]] = None


class TraktSearchResult(BaseModel):
    type: MediaType
    score: Optional[float] = None
    media: CatalogItem


class TraktManager:
    """Implements the authenticated Trakt flows used by the information handlers."""

    def __init__(
        self,
        *,
        session: Optional[HttpSession] = None,
        facade: Optional[MediaModelFacade] = None,
        token_path: Optional[Path] = None,
    ) -> None:
        self._log = get_logger(__name__)
        self._session = session or HttpSession()
        # Trakt explicitly forbids proxy usage for OAuth device flow.
        self._session.proxym.enabled = False

        keys = settings.get_trakt_keys()
        self._client_id = keys.get("client_id")
        self._client_secret = keys.get("client_secret")
        if not self._client_id or not self._client_secret:
            raise RuntimeError("TRAKT_CLIENT_ID and TRAKT_CLIENT_SECRET must be configured")

        tokens_dir = Path(token_path or settings.get_tokens_dir())
        tokens_dir.mkdir(parents=True, exist_ok=True)
        self._token_file = tokens_dir / _TOKEN_FILENAME
        self._token: Optional[StoredToken] = None
        self._daily_refresh_attempted: Optional[str] = None
        self._reauth_reason: Optional[str] = None
        self._load_tokens()

        self._facade = facade or MediaModelFacade()
        self._rate_limit: Optional[RateLimitInfo] = None

        self._session.register_token_refresher(_SERVICE_NAME, self._token_refresh_callback)

    # ------------------------------------------------------------------
    # Authentication helpers
    # ------------------------------------------------------------------
    def device_code_start(self) -> Dict[str, Any]:
        device = self.start_device_auth()
        return {
            "user_code": device.user_code,
            "verification_url": device.verification_url,
            "expires_in": device.expires_in,
            "interval": device.interval,
        }

    def start_device_auth(self) -> DeviceCode:
        payload = {"client_id": self._client_id}
        response = self._session.post(
            _SERVICE_NAME, settings.get_provider_endpoints("trakt")["oauth"]["device_code"], json_body=payload
        )
        data = self._parse_json(response)

        device = DeviceCode.model_validate(data)
        self._log.info(
            "Trakt device code issued; user must visit %s and enter %s",
            device.verification_url,
            device.user_code,
        )

        return device

    def poll_device_token(self, device_code: str) -> OAuthToken:
        payload = {
            "code": device_code,
            "client_id": self._client_id,
            "client_secret": self._client_secret,
        }
        response = self._session.post(
            _SERVICE_NAME,
            settings.get_provider_endpoints("trakt")["oauth"]["poll"],
            json_body=payload,
            allowed_statuses={400, 404, 409, 410, 418, 429},
        )
        data = self._parse_json(response)
        payload_map = data if isinstance(data, Mapping) else {}
        if response.status_code >= 400:
            error = str(payload_map.get("error") or "authorization_pending")
            description = payload_map.get("error_description") if payload_map else None
            interval = self._resolve_retry_interval(payload_map, response.headers)
            self._log.debug(
                "Trakt device polling pending/failed: %s (%s)",
                error,
                description or "no description",
            )
            raise DeviceAuthPollingError(error, description, retry_interval=interval)

        token = OAuthToken.model_validate(data)
        self._store_token(token)
        self._log.info("Trakt access token granted via device flow")

        return token

    def wait_for_device_token(
        self,
        device: DeviceCode,
        *,
        timeout: Optional[int] = None,
    ) -> OAuthToken:
        """Poll for a device token until granted or the device code expires."""

        expires_in = timeout if timeout is not None else int(device.expires_in)
        deadline = time.time() + max(1, expires_in)
        base_interval = max(1, int(device.interval))

        while True:
            try:
                return self.poll_device_token(device.device_code)
            except DeviceAuthPollingError as exc:
                if not exc.should_retry:
                    raise

                now = time.time()
                retry_delay = max(1, exc.retry_interval or base_interval)
                if now + retry_delay >= deadline:
                    raise DeviceAuthPollingError(
                        "expired",
                        "Device authorization timed out",
                    ) from exc

                self._log.debug("Waiting %s seconds before next Trakt device poll", retry_delay)
                time.sleep(retry_delay)

    def refresh_tokens(self) -> OAuthToken:
        token = self._token
        if token is None or not token.refresh_token:
            raise RuntimeError("No refresh token available for Trakt")

        payload = {
            "client_id": self._client_id,
            "client_secret": self._client_secret,
            "redirect_uri": None,
            "grant_type": "refresh_token",
            "refresh_token": token.refresh_token,
        }
        response = self._session.post(
            _SERVICE_NAME, settings.get_provider_endpoints("trakt")["oauth"]["refresh"], json_body=payload
        )
        data = self._parse_json(response)
        token = OAuthToken.model_validate(data)
        self._store_token(token)
        self._log.info("Trakt access token refreshed")

        return token

    def facade_status(self) -> Dict[str, Any]:
        token = self._token
        if token is None:
            return {"reauth_required": True, "reason": "no_token"}
        if self._reauth_reason:
            return {"reauth_required": True, "reason": self._reauth_reason}

        return {
            "reauth_required": False,
            "expires_at": token.expires_at,
            "last_refresh_ymd": token.last_refresh_ymd,
        }

    def current_token(self) -> Optional[OAuthToken]:
        if self._token is None:
            return None
        try:
            return self._token.to_oauth()
        except ValidationError:
            return None

    def has_token(self) -> bool:
        return self._token is not None

    def token_expires_at(self) -> Optional[float]:
        if self._token is None:
            return None
        return float(self._token.expires_at)

    def has_valid_token(self, *, buffer_seconds: int = 120) -> bool:
        token = self._token
        if token is None:
            return False
        expires_at = float(token.expires_at)
        return expires_at > (time.time() + buffer_seconds)

    def clear_token(self) -> None:
        self._token = None
        self._reauth_reason = None
        self._daily_refresh_attempted = None
        try:
            if self._token_file.exists():
                self._token_file.unlink()
        except OSError:
            pass

    # ------------------------------------------------------------------
    # User-facing operations
    # ------------------------------------------------------------------
    def get_profile(self, username: str = "me") -> TraktUserProfile:
        payload = self._authorized_get(
            settings.get_provider_endpoints("trakt")["users"]["profile"].format(username=username)
        )

        return TraktUserProfile.model_validate(payload)

    def catalog_list(
        self,
        media_type: MediaType,
        category: str,
        *,
        period: Optional[str] = None,
        limit: int = 40,
        username: str = "me",
    ) -> Sequence[CatalogItem]:
        path = self._catalog_endpoint(media_type, category, period=period, username=username)
        params: Dict[str, Any] = {"limit": limit}
        response = self._session.get(_SERVICE_NAME, path, params=params)
        payload = self._parse_json(response)

        if not isinstance(payload, Iterable):
            return []

        items: list[CatalogItem] = []
        for entry in payload:
            if not isinstance(entry, Mapping):
                continue
            media_payload = self._extract_media_payload(entry)
            if media_payload is None and isinstance(entry, Mapping):
                media_payload = dict(entry)
                media_payload.setdefault("media_type", media_type.value)

            if media_payload is None:
                continue

            resolved_type = self._resolve_media_type(media_payload.get("media_type"), fallback=media_type)
            try:
                items.append(
                    self._facade.catalog_item(
                        media_payload,
                        source_tag=_SERVICE_NAME,
                        media_type=resolved_type,
                    )
                )
            except ValidationError:
                continue

        return items

    def get_catalog_widget(
        self,
        media_type: MediaType,
        category: str,
        *,
        period: Optional[str] = None,
        related_id: Optional[str] = None,
        per_page: int = 10,
        max_pages: int = 10,
        max_items: Optional[int] = None,
    ) -> CatalogWidget:
        """Return a paginated catalog payload suitable for widget rendering."""

        path = self._catalog_widget_endpoint(
            media_type,
            category,
            period=period,
            related_id=related_id,
        )
        if path is None:
            return CatalogWidget(
                items=[],
                pagination=self._empty_pagination(per_page),
            )

        limit = per_page * max_pages if max_items is None else max(1, min(max_items, 1000))
        per_page = max(1, min(per_page, 100))
        max_pages = max(1, max_pages)

        params: Dict[str, Any] = {}
        items: list[CatalogWidgetItem] = []
        current_page = 1
        pages_fetched = 0
        snapshot: Optional[PaginationDetails] = None

        while pages_fetched < max_pages and len(items) < limit:
            page_params = dict(params)
            page_params["page"] = current_page
            page_params["limit"] = per_page

            response = self._authorized_get_response(path, params=page_params)
            payload = self._parse_json(response)
            snapshot = self._parse_pagination_info(response, fallback_page=current_page, fallback_limit=per_page)

            if not isinstance(payload, Iterable):
                break

            page_items = self._parse_catalog_widget_items(payload, media_type)
            if not page_items:
                if snapshot and not snapshot.has_next:
                    break
                pages_fetched += 1
                current_page += 1
                continue

            for entry in page_items:
                items.append(entry)
                if len(items) >= limit:
                    break

            pages_fetched += 1

            if snapshot is None:
                break
            if not snapshot.has_next or len(items) >= limit:
                break

            current_page += 1

        if snapshot is None:
            snapshot = self._empty_pagination(per_page)

        has_next = snapshot.has_next
        snapshot = snapshot.model_copy(
            update={
                "has_next": has_next,
                "pages_fetched": pages_fetched,
                "items_fetched": len(items),
            }
        )

        return CatalogWidget(items=list(items), pagination=snapshot, page_size=per_page)

    def get_catalog_widget_bundle(
        self,
        category: str,
        *,
        period: Optional[str] = None,
        per_page: int = 10,
        max_pages: int = 10,
        max_items: Optional[int] = None,
        related_ids: Optional[Mapping[MediaType, str]] = None,
    ) -> Mapping[str, CatalogWidget]:
        """Return both movie and show catalog widgets for the requested category."""

        movie_related = None
        show_related = None
        if related_ids:
            movie_related = related_ids.get(MediaType.MOVIE)
            show_related = related_ids.get(MediaType.SHOW)

        if category.lower() == "related":
            if movie_related is None:
                movie_related = self._latest_history_trakt_id(MediaType.MOVIE)
            if show_related is None:
                show_related = self._latest_history_trakt_id(MediaType.SHOW)

        widgets: Dict[str, CatalogWidget] = {}
        widgets["movies"] = self.get_catalog_widget(
            MediaType.MOVIE,
            category,
            period=period,
            related_id=movie_related,
            per_page=per_page,
            max_pages=max_pages,
            max_items=max_items,
        )
        widgets["shows"] = self.get_catalog_widget(
            MediaType.SHOW,
            category,
            period=period,
            related_id=show_related,
            per_page=per_page,
            max_pages=max_pages,
            max_items=max_items,
        )

        return widgets

    def get_playback_resume(
        self,
        media_type: MediaType,
        *,
        start_at: Optional[datetime] = None,
        end_at: Optional[datetime] = None,
    ) -> Sequence[PlaybackEntry]:
        if media_type == MediaType.MOVIE:
            trakt_type = "movies"
            fallback_type = MediaType.MOVIE
        elif media_type in {MediaType.EPISODE, MediaType.SHOW}:
            trakt_type = "episodes"
            fallback_type = MediaType.EPISODE
        else:
            raise ValueError("Playback resume is only available for movies or episodes")

        params: Dict[str, Any] = {}
        if start_at is not None:
            params["start_at"] = start_at.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
        if end_at is not None:
            params["end_at"] = end_at.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")

        payload = self._authorized_get(
            settings.get_provider_endpoints("trakt")["sync"]["playback_by_type"].format(type=trakt_type), params=params
        )
        if not isinstance(payload, Iterable):
            return []

        entries: list[PlaybackEntry] = []
        for entry in payload:
            if not isinstance(entry, Mapping):
                continue

            entry_id = self._try_int(entry.get("id"))
            progress_value = self._try_float(entry.get("progress"))
            if entry_id is None or progress_value is None:
                continue

            paused_at = self._parse_datetime(entry.get("paused_at"))
            media_payload = self._extract_media_payload(entry)
            if media_payload is None:
                continue

            resolved_type = self._resolve_media_type(entry.get("type"), fallback=fallback_type)

            try:
                catalog_item = self._facade.catalog_item(
                    media_payload,
                    source_tag=_SERVICE_NAME,
                    media_type=resolved_type,
                )
            except ValidationError:
                continue

            entries.append(
                PlaybackEntry(
                    id=entry_id,
                    progress=progress_value,
                    paused_at=paused_at,
                    type=resolved_type,
                    media=catalog_item,
                )
            )

        return entries

    def get_in_progress(
        self,
        media_type: MediaType,
        *,
        limit: int = 50,
        max_pages: int = 10,
    ) -> Sequence[CatalogItem]:
        trakt_type = {
            MediaType.MOVIE: "movies",
            MediaType.SHOW: "episodes",
            MediaType.EPISODE: "episodes",
        }.get(media_type)
        if trakt_type is None:
            raise ValueError("Playback progress is only available for movies or shows")

        page_size = max(1, min(limit, 100))
        items: list[CatalogItem] = []
        page = 1

        while page <= max_pages:
            response = self._authorized_get_response(
                settings.get_provider_endpoints("trakt")["sync"]["playback_by_type"].format(type=trakt_type),
                params={"limit": page_size, "page": page},
            )
            payload = self._parse_json(response)

            if not isinstance(payload, Iterable):
                break

            batch_count = 0
            for entry in payload:
                if not isinstance(entry, Mapping):
                    continue
                media_payload = self._extract_media_payload(entry)
                if media_payload is None:
                    continue
                fallback = MediaType.MOVIE if trakt_type == "movies" else MediaType.EPISODE
                resolved_type = self._resolve_media_type(
                    media_payload.get("media_type"),
                    fallback=fallback,
                )
                try:
                    items.append(
                        self._facade.catalog_item(
                            media_payload,
                            source_tag=_SERVICE_NAME,
                            media_type=resolved_type,
                        )
                    )
                except ValidationError:
                    continue
                batch_count += 1

            if batch_count < page_size:
                break

            total_pages = self._try_int(response.headers.get("X-Pagination-Page-Count"))
            if total_pages is not None and page >= total_pages:
                break

            page += 1

        return items

    def get_continue_watching(
        self,
        *,
        movie_limit: int = 25,
        show_limit: int = 25,
        history_window: int = 20,
    ) -> ContinueWatchingPayload:
        """Return resume data for the Continue Watching widget."""

        movie_entries = [
            entry
            for entry in self.get_playback_resume(MediaType.MOVIE)
            if entry.id is not None and entry.progress is not None
        ]
        movies: list[ContinueWatchingMovie] = []
        for entry in movie_entries[:movie_limit]:
            movies.append(
                ContinueWatchingMovie(
                    playback_id=int(entry.id),
                    progress=float(entry.progress),
                    paused_at=entry.paused_at,
                    media=entry.media,
                )
            )

        episode_resume_entries = self.get_playback_resume(MediaType.EPISODE)
        resume_map: Dict[str, PlaybackEntry] = {}
        show_candidates: "OrderedDict[str, CatalogItem]" = OrderedDict()

        for entry in episode_resume_entries:
            episode_trakt_id = self._catalog_trakt_id(entry.media)
            if episode_trakt_id is not None:
                resume_map[episode_trakt_id] = entry

            show_payload = self._catalog_show_payload(entry.media)
            show_trakt_id = self._payload_trakt_id(show_payload) if show_payload else None
            if show_trakt_id and show_trakt_id not in show_candidates:
                show_media = self._build_show_catalog_item(show_payload)
                if show_media is not None:
                    show_candidates[show_trakt_id] = show_media

        history_entries = self.get_watched_history(MediaType.EPISODE, limit=history_window)
        for history_entry in history_entries:
            show_payload = self._catalog_show_payload(history_entry.media)
            show_trakt_id = self._payload_trakt_id(show_payload) if show_payload else None
            if not show_trakt_id or show_trakt_id in show_candidates:
                continue
            show_media = self._build_show_catalog_item(show_payload)
            if show_media is not None:
                show_candidates[show_trakt_id] = show_media

        shows: list[ContinueWatchingShow] = []
        for trakt_show_id, base_show_media in show_candidates.items():
        for entry in episode_resume_entries:
            trakt_id = self._catalog_trakt_id(entry.media)
            if trakt_id is None:
                continue
            resume_map[trakt_id] = entry

        show_history = self.get_watched_history(MediaType.SHOW, limit=history_window)
        show_map: Dict[str, CatalogItem] = {}
        for history_entry in show_history:
            trakt_id = self._catalog_trakt_id(history_entry.media)
            if trakt_id is None or trakt_id in show_map:
                continue
            show_map[trakt_id] = history_entry.media

        shows: list[ContinueWatchingShow] = []
        for trakt_show_id, show_media in show_map.items():
            progress_payload = self.get_show_watched_progress(trakt_show_id)
            if progress_payload is None:
                continue

            show_media = base_show_media
            show_payload = progress_payload.get("show") if isinstance(progress_payload, Mapping) else None
            updated_show_media = self._build_show_catalog_item(show_payload)
            if updated_show_media is not None:
                show_media = updated_show_media

            episode_progress = self._build_show_episode_progress(
                show_media,
                progress_payload,
                resume_map,
            )
            if not episode_progress:
                continue

            next_episode = next((item for item in episode_progress if not item.completed), None)
            if next_episode is None:
                continue
            shows.append(
                ContinueWatchingShow(
                    show=show_media,
                    episodes=episode_progress,
                    next_episode=next_episode,
                    unwatched_count=sum(1 for item in episode_progress if not item.completed),
                )
            )
            if len(shows) >= show_limit:
                break

        return ContinueWatchingPayload(movies=movies, shows=shows)

    def get_user_lists(self, username: str = "me") -> Sequence[UserList]:
        payload = self._authorized_get(
            settings.get_provider_endpoints("trakt")["users"]["lists"].format(username=username)
        )
        if not isinstance(payload, Iterable):
            return []

        results: list[UserList] = []
        for entry in payload:
            if not isinstance(entry, Mapping):
                continue
            try:
                results.append(UserList.model_validate(entry))
            except ValidationError:
                continue

        return results

    def get_list_items(
        self,
        list_id: str,
        *,
        username: str = "me",
        media_type: Optional[MediaType] = None,
    ) -> Sequence[CatalogItem]:
        if not list_id:
            raise ValueError("A list identifier or slug must be provided")

        if media_type is not None:
            segment = self._list_media_segment(media_type)
            path = settings.get_provider_endpoints("trakt")["users"]["list_items_by_type"].format(
                username=username, list_id=list_id, media_type=segment
            )
        else:
            path = settings.get_provider_endpoints("trakt")["users"]["list_items"].format(
                username=username, list_id=list_id
            )

        payload = self._authorized_get(path)
        if not isinstance(payload, Iterable):
            return []

        items: list[CatalogItem] = []
        for entry in payload:
            if not isinstance(entry, Mapping):
                continue
            media_payload = self._extract_media_payload(entry)
            if media_payload is None:
                continue

            fallback_type = media_type or MediaType.MOVIE
            resolved_type = self._resolve_media_type(entry.get("type"), fallback=fallback_type)
            try:
                items.append(
                    self._facade.catalog_item(
                        media_payload,
                        source_tag=_SERVICE_NAME,
                        media_type=resolved_type,
                    )
                )
            except ValidationError:
                continue

        return items

    def get_watched_history(
        self,
        media_type: MediaType,
        *,
        limit: int = 100,
        start_at: Optional[datetime] = None,
        end_at: Optional[datetime] = None,
    ) -> Sequence[HistoryEntry]:
        trakt_type = self._history_endpoint(media_type)
        params: Dict[str, Any] = {"limit": limit}
        if start_at is not None:
            params["start_at"] = start_at.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
        if end_at is not None:
            params["end_at"] = end_at.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")

        payload = self._authorized_get(
            settings.get_provider_endpoints("trakt")["sync"]["history"].format(media_type=trakt_type), params=params
        )
        if not isinstance(payload, Iterable):
            return []

        entries: list[HistoryEntry] = []
        for entry in payload:
            if not isinstance(entry, Mapping):
                continue
            watched_at = self._parse_datetime(entry.get("watched_at"))
            action = entry.get("action")
            media_payload = self._extract_media_payload(entry)
            if media_payload is None:
                continue
            overrides: Dict[str, Any] = {}
            media_type_value = media_payload.get("media_type") or media_payload.get("type")
            resolved_media_type = self._resolve_media_type(media_type_value, fallback=media_type)
            try:
                catalog_item = self._facade.catalog_item(
                    media_payload,
                    source_tag=_SERVICE_NAME,
                    media_type=resolved_media_type,
                    overrides=overrides,
                )
            except ValidationError:
                continue

            trakt_id = entry.get("id")
            if trakt_id is None:
                continue

            entries.append(
                HistoryEntry(
                    id=int(trakt_id),
                    action=action,
                    watched_at=watched_at,
                    type=resolved_media_type,
                    media=catalog_item,
                )
            )

        return entries

    def get_show_watched_progress(
        self,
        trakt_show_id: str,
        *,
        hidden: bool = False,
        specials: bool = False,
        count_specials: bool = True,
    ) -> Optional[Mapping[str, Any]]:
        if not trakt_show_id:
            return None

        params = {
            "hidden": "true" if hidden else "false",
            "specials": "true" if specials else "false",
            "count_specials": "true" if count_specials else "false",
            "extended": "full",
        }
        path = f"/shows/{trakt_show_id}/progress/watched"
        path = settings.get_provider_endpoints("trakt")["shows"]["progress_watched"].format(show_id=trakt_show_id)
        payload = self._authorized_get(path, params=params)
        if not isinstance(payload, Mapping):
            return None
        return payload

    def start_scrobble(
        self,
        *,
        media_type: MediaType,
        media: Mapping[str, Any],
        progress: float,
        show: Optional[Mapping[str, Any]] = None,
        app_version: Optional[str] = None,
        app_date: Optional[str] = None,
    ) -> ScrobbleResponse:
        return self._execute_scrobble(
            "start",
            media_type=media_type,
            media=media,
            progress=progress,
            show=show,
            app_version=app_version,
            app_date=app_date,
        )

    def pause_scrobble(
        self,
        *,
        media_type: MediaType,
        media: Mapping[str, Any],
        progress: float,
        show: Optional[Mapping[str, Any]] = None,
        app_version: Optional[str] = None,
        app_date: Optional[str] = None,
    ) -> ScrobbleResponse:
        return self._execute_scrobble(
            "pause",
            media_type=media_type,
            media=media,
            progress=progress,
            show=show,
            app_version=app_version,
            app_date=app_date,
        )

    def stop_scrobble(
        self,
        *,
        media_type: MediaType,
        media: Mapping[str, Any],
        progress: float,
        show: Optional[Mapping[str, Any]] = None,
        app_version: Optional[str] = None,
        app_date: Optional[str] = None,
    ) -> ScrobbleResponse:
        return self._execute_scrobble(
            "stop",
            media_type=media_type,
            media=media,
            progress=progress,
            show=show,
            app_version=app_version,
            app_date=app_date,
        )

    def scrobble(
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
        return self._execute_scrobble(
            action,
            media_type=media_type,
            media=media,
            progress=progress,
            show=show,
            app_version=app_version,
            app_date=app_date,
        )

    def _execute_scrobble(
        self,
        action: str,
        *,
        media_type: MediaType,
        media: Mapping[str, Any],
        progress: float,
        show: Optional[Mapping[str, Any]],
        app_version: Optional[str],
        app_date: Optional[str],
    ) -> ScrobbleResponse:
        if media_type not in {MediaType.MOVIE, MediaType.EPISODE}:
            raise ValueError("Scrobbling is only valid for movies or episodes")
        if action not in {"start", "pause", "stop"}:
            raise ValueError("Unsupported scrobble action")

        progress_value = float(progress)
        if not 0.0 <= progress_value <= 100.0:
            raise ValueError("Scrobble progress must be between 0 and 100")

        selector = self._normalize_media_selector(media)
        body: Dict[str, Any] = {"progress": progress_value}
        normalized_app_version = app_version or "WarpMC-1.0"
        normalized_app_date = app_date or datetime.utcnow().strftime("%Y-%m-%d")
        body["app_version"] = normalized_app_version
        body["app_date"] = normalized_app_date

        key = "movie" if media_type == MediaType.MOVIE else "episode"
        body[key] = selector
        if media_type == MediaType.EPISODE and show is not None:
            body["show"] = self._normalize_media_selector(show)

        response = self._authorized_post_response(
            settings.get_provider_endpoints("trakt")["scrobble"]["base"].format(action=action),
            json_body=body,
            allowed_statuses={409},
        )
        payload = self._parse_json(response)

        if response.status_code == 409:
            raise TraktScrobbleConflict(
                watched_at=self._parse_datetime(payload.get("watched_at")),
                expires_at=self._parse_datetime(payload.get("expires_at")),
            )

        media_payload = payload.get("movie") if media_type == MediaType.MOVIE else payload.get("episode")
        if not isinstance(media_payload, Mapping):
            raise RuntimeError("Unexpected Trakt scrobble payload")

        overrides: Dict[str, Any] = {}
        if media_type == MediaType.EPISODE and isinstance(payload.get("show"), Mapping):
            overrides["show"] = dict(payload["show"])  # type: ignore[index]

        try:
            catalog_item = self._facade.catalog_item(
                media_payload,
                source_tag=_SERVICE_NAME,
                media_type=media_type,
                overrides=overrides if overrides else None,
            )
        except ValidationError as exc:  # pragma: no cover - defensive
            raise RuntimeError("Invalid media data returned from Trakt") from exc

        sharing_raw = payload.get("sharing")
        sharing_payload = dict(sharing_raw) if isinstance(sharing_raw, Mapping) else None

        return ScrobbleResponse(
            id=self._try_int(payload.get("id")),
            action=str(payload.get("action") or action),
            progress=self._try_float(payload.get("progress")),
            sharing=sharing_payload,
            media_type=media_type,
            media=catalog_item,
        )

    def get_user_settings(self) -> TraktUserSettings:
        payload = self._authorized_get(settings.get_provider_endpoints("trakt")["users"]["settings"])

        return TraktUserSettings.model_validate(payload)

    def search(
        self,
        query: str,
        *,
        types: Optional[Sequence[MediaType]] = None,
        limit: int = 10,
        year: Optional[int] = None,
    ) -> Sequence[TraktSearchResult]:
        params: Dict[str, Any] = {"query": query, "limit": limit}
        if year is not None:
            params["year"] = int(year)

        chosen_types = list(types) if types else [MediaType.MOVIE, MediaType.SHOW]
        if chosen_types:
            params["type"] = ",".join(sorted({t.value for t in chosen_types}))

        payload = self._authorized_get(settings.get_provider_endpoints("trakt")["search"]["text"], params=params)
        if not isinstance(payload, Iterable):
            return []

        results: list[TraktSearchResult] = []
        for entry in payload:
            if not isinstance(entry, Mapping):
                continue
            media_payload = self._extract_media_payload(entry)
            if media_payload is None:
                continue

            fallback_type = self._resolve_media_type(
                media_payload.get("media_type"),
                fallback=MediaType.MOVIE,
            )
            resolved_type = self._resolve_media_type(entry.get("type"), fallback=fallback_type)

            try:
                catalog_item = self._facade.catalog_item(
                    media_payload,
                    source_tag=_SERVICE_NAME,
                    media_type=resolved_type,
                )
            except ValidationError:
                continue

            results.append(
                TraktSearchResult(
                    type=resolved_type,
                    score=self._try_float(entry.get("score")),
                    media=catalog_item,
                )
            )

        return results

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _catalog_endpoint(
        self,
        media_type: MediaType,
        category: str,
        *,
        period: Optional[str],
        username: str,
    ) -> str:
        base = {
            MediaType.MOVIE: "movies",
            MediaType.SHOW: "shows",
        }.get(media_type)
        if base is None:
            raise ValueError(f"Unsupported media type for Trakt catalog: {media_type}")

        normalized = category.lower()
        endpoints = settings.get_provider_endpoints("trakt")

        if normalized in endpoints[base]:
            endpoint = endpoints[base][normalized]
            if "{period}" in endpoint:
                window = (period or "weekly").lower()
                return endpoint.format(period=window)
            return endpoint
        
        if normalized == "lists":
            return endpoints["users"]["lists_by_type"].format(username=username, base=base)

        raise ValueError(f"Unsupported Trakt catalog category '{category}'")

    def _catalog_widget_endpoint(
        self,
        media_type: MediaType,
        category: str,
        *,
        period: Optional[str],
        related_id: Optional[str],
    ) -> Optional[str]:
        base = {
            MediaType.MOVIE: "movies",
            MediaType.SHOW: "shows",
        }.get(media_type)
        if base is None:
            raise ValueError(f"Unsupported media type for Trakt catalog widget: {media_type}")

        normalized = category.lower()
        endpoints = settings.get_provider_endpoints("trakt")

        if normalized in endpoints[base]:
            endpoint = endpoints[base][normalized]
            if "{period}" in endpoint:
                window = (period or "daily").lower()
                return endpoint.format(period=window)
            if "{slug}" in endpoint:
                if not related_id:
                    return None
                return endpoint.format(slug=related_id)
            return endpoint

        raise ValueError(f"Unsupported Trakt catalog widget category '{category}'")

    def _empty_pagination(self, per_page: int) -> PaginationDetails:
        normalized = max(1, per_page)
        return PaginationDetails(
            page=1,
            per_page=normalized,
            page_count=1,
            item_count=0,
            has_next=False,
            pages_fetched=0,
            items_fetched=0,
        )

    def _parse_pagination_info(
        self,
        response,
        *,
        fallback_page: int,
        fallback_limit: int,
    ) -> PaginationDetails:
        headers = getattr(response, "headers", {}) or {}
        page = self._try_int(headers.get("X-Pagination-Page")) or max(1, fallback_page)
        per_page = self._try_int(headers.get("X-Pagination-Limit")) or max(1, fallback_limit)
        page_count = self._try_int(headers.get("X-Pagination-Page-Count"))
        item_count = self._try_int(headers.get("X-Pagination-Item-Count"))

        has_next = False
        if page_count is not None:
            has_next = page < page_count
        elif item_count is not None:
            has_next = page * per_page < item_count

        return PaginationDetails(
            page=page,
            per_page=per_page,
            page_count=page_count,
            item_count=item_count,
            has_next=has_next,
            pages_fetched=0,
            items_fetched=0,
        )

    def _parse_catalog_widget_items(
        self,
        payload: Iterable[Any],
        media_type: MediaType,
    ) -> Sequence[CatalogWidgetItem]:
        items: list[CatalogWidgetItem] = []
        for entry in payload:
            if not isinstance(entry, Mapping):
                continue
            media_payload = self._extract_media_payload(entry)
            if media_payload is None and isinstance(entry, Mapping):
                media_payload = dict(entry)
                media_payload.setdefault("media_type", media_type.value)

            if media_payload is None:
                continue

            resolved_type = self._resolve_media_type(
                media_payload.get("media_type"),
                fallback=media_type,
            )
            try:
                catalog_item = self._facade.catalog_item(
                    media_payload,
                    source_tag=_SERVICE_NAME,
                    media_type=resolved_type,
                )
            except ValidationError:
                continue

            metrics = self._extract_metrics(entry)
            items.append(CatalogWidgetItem(media=catalog_item, metrics=metrics))

        return items

    def _latest_history_trakt_id(self, media_type: MediaType) -> Optional[str]:
        try:
            history = self.get_watched_history(media_type, limit=1)
        except Exception:
            return None
        if not history:
            return None
        return self._catalog_trakt_id(history[0].media)

    def _catalog_trakt_id(self, item: CatalogItem) -> Optional[str]:
        extra = item.extra or {}
        ids_payload = extra.get("ids")
        if isinstance(ids_payload, Mapping):
            trakt_id = ids_payload.get("trakt")
            if trakt_id:
                return str(trakt_id)
        raw_payload = extra.get("raw_payload")
        if isinstance(raw_payload, Mapping):
            ids_payload = raw_payload.get("ids")
            if isinstance(ids_payload, Mapping):
                trakt_id = ids_payload.get("trakt")
                if trakt_id:
                    return str(trakt_id)
        return None

    def _build_show_episode_progress(
        self,
        show_media: CatalogItem,
        payload: Mapping[str, Any],
        resume_map: Mapping[str, PlaybackEntry],
    ) -> Sequence[EpisodeProgress]:
        results: List[EpisodeProgress] = []
        seasons = payload.get("seasons")
        if not isinstance(seasons, Iterable):
            return results

        for season in seasons:
            if not isinstance(season, Mapping):
                continue
            season_number = self._try_int(season.get("number"))
            episodes = season.get("episodes")
            if not isinstance(episodes, Iterable):
                continue

            for episode in episodes:
                if not isinstance(episode, Mapping):
                    continue
                ids_payload = episode.get("ids")
                trakt_episode_id: Optional[str] = None
                if isinstance(ids_payload, Mapping):
                    raw_id = ids_payload.get("trakt")
                    if raw_id:
                        trakt_episode_id = str(raw_id)

                resume_entry = resume_map.get(trakt_episode_id) if trakt_episode_id else None
                if resume_entry is not None:
                    base_media = resume_entry.media
                    extra_payload = dict(base_media.extra or {})
                    extra_payload["raw_progress"] = {str(k): v for k, v in episode.items()}
                    catalog_item = base_media.model_copy(update={"extra": extra_payload})
                else:
                    catalog_item = self._build_episode_catalog_item(show_media, episode, season_number)

                episode_number = self._try_int(episode.get("number"))
                progress_entry = EpisodeProgress(
                    episode=catalog_item,
                    season=season_number,
                    number=episode_number,
                    completed=bool(episode.get("completed")),
                    last_watched_at=self._parse_datetime(episode.get("last_watched_at")),
                    playback_id=resume_entry.id if resume_entry else None,
                    progress=resume_entry.progress if resume_entry else None,
                    paused_at=resume_entry.paused_at if resume_entry else None,
                    resume_available=resume_entry is not None,
                )
                results.append(progress_entry)

        results.sort(key=lambda entry: ((entry.season or 0), (entry.number or 0)))
        return results

    def _build_episode_catalog_item(
        self,
        show_media: CatalogItem,
        episode_payload: Mapping[str, Any],
        season_number: Optional[int],
    ) -> CatalogItem:
        payload = dict(episode_payload)
        payload.setdefault("media_type", MediaType.EPISODE.value)
        if season_number is not None:
            payload.setdefault("season", season_number)
            payload.setdefault("season_number", season_number)

        episode_number = self._try_int(payload.get("number"))
        if episode_number is not None:
            payload.setdefault("episode", episode_number)
            payload.setdefault("episode_number", episode_number)

        ids_payload = payload.get("ids")
        if isinstance(ids_payload, Mapping):
            payload["ids"] = dict(ids_payload)
        else:
            payload["ids"] = {}

        trakt_id = payload["ids"].get("trakt")
        if trakt_id is not None:
            payload.setdefault("id", str(trakt_id))
        else:
            fallback = f"{show_media.id}-s{season_number or 0}e{episode_number or 0}"
            payload.setdefault("id", fallback)

        if not payload.get("title"):
            if season_number is not None and episode_number is not None:
                payload["title"] = f"S{season_number:02d}E{episode_number:02d}"
            else:
                payload["title"] = show_media.title

        extra_payload = dict(payload.get("extra") or {})
        extra_payload.setdefault("ids", payload.get("ids", {}))
        extra_payload["raw_progress"] = {str(k): v for k, v in episode_payload.items()}
        payload["extra"] = extra_payload

        try:
            return self._facade.catalog_item(
                payload,
                source_tag=_SERVICE_NAME,
                media_type=MediaType.EPISODE,
            )
        except ValidationError:
            return CatalogItem(
                id=str(payload.get("id")),
                title=str(payload.get("title")),
                type=MediaType.EPISODE,
                source_tag=_SERVICE_NAME,
                overview=payload.get("overview"),
                poster=show_media.poster,
                extra=extra_payload,
            )

    def _list_media_segment(self, media_type: MediaType) -> str:
        mapping = {
            MediaType.MOVIE: "movies",
            MediaType.SHOW: "shows",
            MediaType.SEASON: "seasons",
            MediaType.EPISODE: "episodes",
        }
        if media_type not in mapping:
            raise ValueError(f"Unsupported media type for Trakt list items: {media_type}")
        return mapping[media_type]

    def _authorized_get(self, path: str, params: Optional[Mapping[str, Any]] = None) -> Any:
        response = self._authorized_get_response(path, params=params)
        return self._parse_json(response)

    def _authorized_get_response(
        self, path: str, params: Optional[Mapping[str, Any]] = None
    ):
        self._ensure_valid_token()
        headers = self._auth_headers()
        try:
            response = self._session.get(
                _SERVICE_NAME,
                path,
                params=dict(params or {}),
                headers=headers,
            )
        except Unauthorized:
            # Token might have been revoked; refresh once and retry.
            self.refresh_tokens()
            response = self._session.get(
                _SERVICE_NAME,
                path,
                params=dict(params or {}),
                headers=self._auth_headers(),
            )
        return response

    def _authorized_post(
        self,
        path: str,
        *,
        json_body: Optional[Mapping[str, Any]] = None,
        allowed_statuses: Optional[Iterable[int]] = None,
    ) -> Any:
        response = self._authorized_post_response(
            path,
            json_body=json_body,
            allowed_statuses=allowed_statuses,
        )
        return self._parse_json(response)

    def _authorized_post_response(
        self,
        path: str,
        *,
        json_body: Optional[Mapping[str, Any]] = None,
        allowed_statuses: Optional[Iterable[int]] = None,
    ):
        self._ensure_valid_token()
        headers = self._auth_headers()
        allowed = set(allowed_statuses or [])

        try:
            response = self._session.post(
                _SERVICE_NAME,
                path,
                json_body=dict(json_body or {}),
                headers=headers,
                allowed_statuses=allowed,
            )
        except Unauthorized:
            self.refresh_tokens()
            response = self._session.post(
                _SERVICE_NAME,
                path,
                json_body=dict(json_body or {}),
                headers=self._auth_headers(),
                allowed_statuses=allowed,
            )
        return response

    def _parse_json(self, response) -> Any:
        self._rate_limit = self._extract_rate_limit(response)
        try:
            return response.json()
        except ValueError as exc:  # pragma: no cover - defensive
            raise RuntimeError("Trakt returned invalid JSON") from exc

    def _extract_rate_limit(self, response) -> RateLimitInfo:
        headers = response.headers or {}
        limit = self._try_int(headers.get("X-RateLimit-Limit"))
        remaining = self._try_int(headers.get("X-RateLimit-Remaining"))
        reset = headers.get("X-RateLimit-Reset")
        reset_at = None
        if reset:
            try:
                reset_at = datetime.fromtimestamp(int(reset), tz=timezone.utc)
            except (TypeError, ValueError):
                reset_at = None

        return RateLimitInfo(limit=limit, remaining=remaining, reset_at=reset_at)

    def _ensure_valid_token(self) -> None:
        token = self._token
        if token is None:
            raise RuntimeError("No Trakt token available; complete device authentication first")
        if self._reauth_reason:
            raise TraktReauthRequired(self._reauth_reason)

        now_ts = time.time()
        self._maybe_daily_refresh(now_ts)
        token = self._token
        if token is None:
            raise RuntimeError("No Trakt token available; complete device authentication first")

        if token.is_expired(now_ts):
            self._log.warning("Trakt token expired; attempting refresh")
            self._refresh_or_raise("token_expired")
            return

        if token.is_near_expiry(now_ts):
            self._log.debug("Trakt token near expiry; attempting proactive refresh")
            self._refresh_or_raise(None)

    def _refresh_or_raise(self, fatal_reason: Optional[str]) -> None:
        try:
            self.refresh_tokens()
        except Unauthorized as exc:
            self._log.warning("Trakt token refresh unauthorized: %s", exc)
            if fatal_reason:
                self._flag_reauth(fatal_reason)
                raise TraktReauthRequired(fatal_reason) from exc
        except Exception as exc:
            self._log.warning("Trakt token refresh failed: %s", exc)
            if fatal_reason:
                self._flag_reauth(fatal_reason)
                raise TraktReauthRequired(fatal_reason) from exc
        else:
            if fatal_reason:
                self._reauth_reason = None

    def _maybe_daily_refresh(self, now_ts: float) -> None:
        token = self._token
        if token is None or token.is_expired(now_ts):
            return

        today = date.today().isoformat()
        if self._daily_refresh_attempted == today:
            return
        if token.last_refresh_ymd == today:
            self._daily_refresh_attempted = today
            return

        self._daily_refresh_attempted = today
        self._log.debug("Attempting daily Trakt token refresh")
        try:
            self.refresh_tokens()
        except Exception as exc:
            self._log.warning("Daily Trakt token refresh failed: %s", exc)

    def _flag_reauth(self, reason: str) -> None:
        self._reauth_reason = reason

    def _resolve_retry_interval(
        self,
        payload: Mapping[str, Any],
        headers: Optional[Mapping[str, Any]],
    ) -> Optional[int]:
        interval = self._try_int(payload.get("interval"))
        retry_after_value: Optional[int] = None
        if headers:
            raw = headers.get("Retry-After")
            if raw is not None:
                retry_after_value = self._try_int(raw)
                if retry_after_value is None:
                    try:
                        retry_after_value = int(float(str(raw)))
                    except (TypeError, ValueError):
                        retry_after_value = None

        if retry_after_value is None:
            return interval

        if interval is None:
            return retry_after_value

        return max(interval, retry_after_value)

    def _auth_headers(self) -> Dict[str, str]:
        token = self._token.access_token if self._token else None
        if not token:
            raise RuntimeError("Missing Trakt access token")
        headers = self._session.urlm.service_headers(_SERVICE_NAME)
        headers["Authorization"] = f"Bearer {token}"

        return headers

    def _store_token(self, token: OAuthToken) -> None:
        stored = StoredToken.from_oauth(token)
        self._token = stored
        self._reauth_reason = None
        self._daily_refresh_attempted = stored.last_refresh_ymd

        payload = {
            "access_token": stored.access_token,
            "refresh_token": stored.refresh_token,
            "scope": stored.scope,
            "created_at": stored.created_at,
            "expires_in": stored.expires_in,
            "expires_at": stored.expires_at,
            "token_type": stored.token_type,
            "last_refresh_ymd": stored.last_refresh_ymd,
        }

        try:
            self._token_file.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        except OSError:  # pragma: no cover - filesystem failure
            pass

    def _load_tokens(self) -> None:
        if not self._token_file.exists():
            return
        try:
            data = json.loads(self._token_file.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            self._log.warning("Failed to load Trakt token cache; ignoring and continuing")
            return
        if not isinstance(data, Mapping):
            return

        payload = dict(data)
        try:
            created_at = int(payload.get("created_at")) if payload.get("created_at") is not None else int(time.time())
            expires_in = int(payload.get("expires_in")) if payload.get("expires_in") is not None else 0
            expires_at = int(payload.get("expires_at")) if payload.get("expires_at") is not None else 0
            stored = StoredToken.model_validate(
                {
                    "access_token": payload.get("access_token"),
                    "refresh_token": payload.get("refresh_token"),
                    "scope": payload.get("scope"),
                    "created_at": created_at,
                    "expires_in": expires_in,
                    "expires_at": expires_at,
                    "token_type": payload.get("token_type") or "bearer",
                    "last_refresh_ymd": payload.get("last_refresh_ymd"),
                }
            )
        except (ValidationError, TypeError, ValueError):
            self._log.warning("Stored Trakt token payload invalid; ignoring")
            return

        # Backfill expires_at if an older payload omitted it.
        if not stored.expires_at:
            expires_at = stored.created_at + stored.expires_in
            stored = stored.model_copy(update={"expires_at": expires_at})

        self._token = stored
        self._daily_refresh_attempted = stored.last_refresh_ymd

    def _token_refresh_callback(
        self,
        service: str,
        session: HttpSession,
        response: Optional[Any] = None,
    ) -> Optional[Mapping[str, str]]:
        request = getattr(response, "request", None)
        if request is not None:
            path = getattr(request, "path_url", "")
            if isinstance(path, str) and path.startswith("/oauth/"):
                raise Unauthorized("Trakt OAuth request returned 401")

        self.refresh_tokens()

        return self._auth_headers()

    def _history_endpoint(self, media_type: MediaType) -> str:
        mapping = {
            MediaType.MOVIE: "movies",
            MediaType.SHOW: "shows",
            MediaType.SEASON: "seasons",
            MediaType.EPISODE: "episodes",
        }
        if media_type not in mapping:
            raise ValueError(f"Unsupported media type for Trakt history: {media_type}")

        return mapping[media_type]

    def _parse_datetime(self, value: Any) -> Optional[datetime]:
        if not value:
            return None
        if isinstance(value, datetime):
            return value
        try:
            return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        except ValueError:
            return None

    def _extract_media_payload(
        self,
        entry: Mapping[str, Any],
        *,
        preferred: Optional[str] = None,
    ) -> Optional[Dict[str, Any]]:
        type_hint = preferred or entry.get("type")
        preferred_keys: Sequence[str]
        if isinstance(type_hint, str):
            normalized = type_hint.lower()
            if normalized == "episode":
                preferred_keys = ("episode", "show", "movie")
            elif normalized == "show":
                preferred_keys = ("show", "movie", "episode")
            elif normalized == "movie":
                preferred_keys = ("movie", "show", "episode")
            else:
                preferred_keys = ("movie", "show", "episode")
        else:
            preferred_keys = ("movie", "show", "episode")

        for key in preferred_keys:
            payload = entry.get(key)
            if not isinstance(payload, Mapping):
                continue

            data = dict(payload)
            existing_extra = data.get("extra")
            extra_payload: Dict[str, Any] = {}
            if isinstance(existing_extra, Mapping):
                extra_payload.update(existing_extra)

            if key == "episode":
                data.setdefault("media_type", MediaType.EPISODE.value)
                show_payload = entry.get("show")
                if isinstance(show_payload, Mapping):
                    extra_payload.setdefault("show", dict(show_payload))
            elif key == "show":
                data.setdefault("media_type", MediaType.SHOW.value)
            else:
                data.setdefault("media_type", MediaType.MOVIE.value)

            if "raw_payload" not in extra_payload:
                extra_payload["raw_payload"] = {k: v for k, v in entry.items() if isinstance(k, str)}

            if extra_payload:
                data["extra"] = extra_payload

            data.setdefault("source_tag", _SERVICE_NAME)
            return data

        return None

    def _catalog_show_payload(self, item: CatalogItem) -> Optional[Mapping[str, Any]]:
        extra = item.extra or {}
        show_payload = extra.get("show")
        if isinstance(show_payload, Mapping):
            return show_payload

        raw_payload = extra.get("raw_payload")
        if isinstance(raw_payload, Mapping):
            candidate = raw_payload.get("show")
            if isinstance(candidate, Mapping):
                return candidate

        return None

    def _payload_trakt_id(self, payload: Optional[Mapping[str, Any]]) -> Optional[str]:
        if not isinstance(payload, Mapping):
            return None
        ids_payload = payload.get("ids")
        if isinstance(ids_payload, Mapping):
            trakt_id = ids_payload.get("trakt")
            if trakt_id:
                return str(trakt_id)
        return None

    def _build_show_catalog_item(self, payload: Optional[Mapping[str, Any]]) -> Optional[CatalogItem]:
        if not isinstance(payload, Mapping):
            return None
        try:
            return self._facade.catalog_item(
                payload,
                source_tag=_SERVICE_NAME,
                media_type=MediaType.SHOW,
            )
        except ValidationError:
            return None

    def _resolve_media_type(self, value: Any, *, fallback: MediaType) -> MediaType:
        if isinstance(value, MediaType):
            return value
        if isinstance(value, str):
            normalized = value.lower()
            for item in MediaType:
                if item.value == normalized:
                    return item
        return fallback

    def _extract_metrics(self, entry: Mapping[str, Any]) -> Dict[str, Any]:
        metrics: Dict[str, Any] = {}
        for key, value in entry.items():
            if key in {"movie", "show", "episode"}:
                continue
            if isinstance(value, (str, int, float, bool)) or value is None:
                metrics[key] = value
        return metrics

    def _try_int(self, value: Any) -> Optional[int]:
        if value is None:
            return None
        try:
            return int(value)
        except (TypeError, ValueError):
            return None

    def _try_float(self, value: Any) -> Optional[float]:
        if value is None:
            return None
        try:
            return float(value)
        except (TypeError, ValueError):
            return None

    def _normalize_media_selector(self, payload: Mapping[str, Any]) -> Dict[str, Any]:
        if not isinstance(payload, Mapping):
            raise ValueError("Media selector must be a mapping")

        data = dict(payload)
        ids_payload = data.get("ids")
        if isinstance(ids_payload, Mapping):
            data["ids"] = dict(ids_payload)

        return data

    # ------------------------------------------------------------------
    # Public introspection helpers
    # ------------------------------------------------------------------
    @property
    def rate_limit(self) -> Optional[RateLimitInfo]:
        """Return information about the most recent Trakt rate limit headers."""

        return self._rate_limit


__all__ = [
    "TraktManager",
    "DeviceCode",
    "DeviceAuthPollingError",
    "TraktReauthRequired",
    "OAuthToken",
    "RateLimitInfo",
    "TraktUserProfile",
    "TraktUserSettings",
    "TraktSearchResult",
    "UserList",
    "HistoryEntry",
    "ScrobbleResponse",
    "PlaybackEntry",
    "PaginationDetails",
    "CatalogWidgetItem",
    "CatalogWidget",
    "CatalogWidgetPage",
    "ContinueWatchingMovie",
    "ContinueWatchingShow",
    "EpisodeProgress",
    "ContinueWatchingPayload",
    "TraktScrobbleConflict",
]
