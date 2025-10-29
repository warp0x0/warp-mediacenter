"""Trakt.tv integration helpers."""

from __future__ import annotations

import json
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, Mapping, MutableMapping, Optional, Sequence

from pydantic import BaseModel, ValidationError

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
        return self.error in {"authorization_pending", "slow_down"}


class OAuthToken(BaseModel):
    access_token: str
    token_type: str
    expires_in: int
    refresh_token: Optional[str] = None
    scope: Optional[str] = None
    created_at: Optional[int] = None

    def compute_expiry(self, *, buffer_seconds: int = 120) -> float:
        created = self.created_at or int(time.time())

        return float(created + max(0, self.expires_in - buffer_seconds))


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
    action: Optional[str]
    progress: Optional[float]
    media_type: MediaType
    media: CatalogItem


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
        self._token_payload: MutableMapping[str, Any] = {}
        self._load_tokens()

        self._facade = facade or MediaModelFacade()
        self._rate_limit: Optional[RateLimitInfo] = None

        self._session.register_token_refresher(_SERVICE_NAME, self._token_refresh_callback)

    # ------------------------------------------------------------------
    # Authentication helpers
    # ------------------------------------------------------------------
    def start_device_auth(self) -> DeviceCode:
        payload = {"client_id": self._client_id}
        response = self._session.post(_SERVICE_NAME, "/oauth/device/code", json_body=payload)
        data = self._parse_json(response)

        return DeviceCode.model_validate(data)

    def poll_device_token(self, device_code: str) -> OAuthToken:
        payload = {
            "code": device_code,
            "client_id": self._client_id,
            "client_secret": self._client_secret,
        }
        response = self._session.post(
            _SERVICE_NAME,
            "/oauth/device/token",
            json_body=payload,
            allowed_statuses={400},
        )
        data = self._parse_json(response)
        if response.status_code >= 400:
            error = str(data.get("error") or "authorization_pending")
            description = data.get("error_description")
            interval = self._try_int(data.get("interval"))
            raise DeviceAuthPollingError(error, description, retry_interval=interval)

        token = OAuthToken.model_validate(data)
        self._store_token(token)

        return token

    def refresh_token(self) -> OAuthToken:
        refresh = self._token_payload.get("refresh_token")
        if not refresh:
            raise RuntimeError("No refresh token available for Trakt")

        payload = {
            "grant_type": "refresh_token",
            "refresh_token": refresh,
            "client_id": self._client_id,
            "client_secret": self._client_secret,
        }
        response = self._session.post(_SERVICE_NAME, "/oauth/token", json_body=payload)
        data = self._parse_json(response)
        token = OAuthToken.model_validate(data)
        self._store_token(token)

        return token

    def current_token(self) -> Optional[OAuthToken]:
        if not self._token_payload:
            return None
        try:
            return OAuthToken.model_validate(dict(self._token_payload))
        except ValidationError:
            return None

    def has_token(self) -> bool:
        return bool(self._token_payload.get("access_token"))

    def token_expires_at(self) -> Optional[float]:
        value = self._token_payload.get("expires_at") if self._token_payload else None
        if value is None:
            return None
        try:
            return float(value)
        except (TypeError, ValueError):
            return None

    def has_valid_token(self, *, buffer_seconds: int = 120) -> bool:
        token = self.current_token()
        if token is None:
            return False
        expires_at = self.token_expires_at()
        if expires_at is None:
            return True
        return expires_at > (time.time() + buffer_seconds)

    def clear_token(self) -> None:
        self._token_payload.clear()
        try:
            if self._token_file.exists():
                self._token_file.unlink()
        except OSError:
            pass

    # ------------------------------------------------------------------
    # User-facing operations
    # ------------------------------------------------------------------
    def get_profile(self, username: str = "me") -> TraktUserProfile:
        payload = self._authorized_get(f"/users/{username}")

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
                f"/sync/playback/{trakt_type}",
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

    def get_user_lists(self, username: str = "me") -> Sequence[UserList]:
        payload = self._authorized_get(f"/users/{username}/lists")
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

        path = f"/users/{username}/lists/{list_id}/items"
        if media_type is not None:
            segment = self._list_media_segment(media_type)
            path = f"{path}/{segment}"

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

        payload = self._authorized_get(f"/sync/history/{trakt_type}", params=params)
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

    def scrobble(
        self,
        *,
        media_type: MediaType,
        ids: Mapping[str, Any],
        progress: float,
        action: str = "start",
    ) -> ScrobbleResponse:
        if media_type not in {MediaType.MOVIE, MediaType.EPISODE}:
            raise ValueError("Scrobbling is only valid for movies or episodes")
        if action not in {"start", "pause", "stop"}:
            raise ValueError("Unsupported scrobble action")

        body: Dict[str, Any] = {
            "progress": float(progress),
            "app_version": "WarpMC-1.0",
            "app_date": datetime.utcnow().strftime("%Y-%m-%d"),
        }
        body["movie" if media_type == MediaType.MOVIE else "episode"] = {"ids": dict(ids)}

        payload = self._authorized_post(f"/scrobble/{action}", json_body=body)
        media_payload = payload.get("movie") if media_type == MediaType.MOVIE else payload.get("episode")
        if not isinstance(media_payload, Mapping):
            raise RuntimeError("Unexpected Trakt scrobble payload")

        try:
            catalog_item = self._facade.catalog_item(
                media_payload,
                source_tag=_SERVICE_NAME,
                media_type=media_type,
            )
        except ValidationError as exc:  # pragma: no cover - defensive
            raise RuntimeError("Invalid media data returned from Trakt") from exc

        return ScrobbleResponse(
            action=payload.get("action"),
            progress=payload.get("progress"),
            media_type=media_type,
            media=catalog_item,
        )

    def get_user_settings(self) -> TraktUserSettings:
        payload = self._authorized_get("/users/settings")

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

        payload = self._authorized_get("/search", params=params)
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
        if normalized == "trending":
            return f"/{base}/trending"
        if normalized == "popular":
            return f"/{base}/popular"
        if normalized == "anticipated":
            return f"/{base}/anticipated"
        if normalized in {"watched", "played", "collected"}:
            window = (period or "weekly").lower()
            return f"/{base}/{normalized}/{window}"
        if normalized == "lists":
            return f"/users/{username}/lists/{base}"

        raise ValueError(f"Unsupported Trakt catalog category '{category}'")

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
            self.refresh_token()
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
    ) -> Any:
        self._ensure_valid_token()
        headers = self._auth_headers()

        try:
            response = self._session.post(
                _SERVICE_NAME,
                path,
                json_body=dict(json_body or {}),
                headers=headers,
            )
        except Unauthorized:
            self.refresh_token()
            response = self._session.post(
                _SERVICE_NAME,
                path,
                json_body=dict(json_body or {}),
                headers=self._auth_headers(),
            )
        return self._parse_json(response)

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
        if not self._token_payload:
            raise RuntimeError("No Trakt token available; complete device authentication first")

        expires_at = self._token_payload.get("expires_at")
        if expires_at and float(expires_at) > time.time():
            return

        try:
            self.refresh_token()
        except Unauthorized as exc:  # pragma: no cover - requires live API
            raise RuntimeError("Stored Trakt refresh token is no longer valid") from exc

    def _auth_headers(self) -> Dict[str, str]:
        token = self._token_payload.get("access_token")
        if not token:
            raise RuntimeError("Missing Trakt access token")
        headers = self._session.urlm.service_headers(_SERVICE_NAME)
        headers["Authorization"] = f"Bearer {token}"

        return headers

    def _store_token(self, token: OAuthToken) -> None:
        payload = token.model_dump()
        payload["expires_at"] = token.compute_expiry()
        self._token_payload = payload

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
            return
        if isinstance(data, Mapping):
            self._token_payload.update(data)

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

        self.refresh_token()

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

    def _extract_media_payload(self, entry: Mapping[str, Any]) -> Optional[Dict[str, Any]]:
        for key in ("movie", "show", "episode"):
            payload = entry.get(key)
            if isinstance(payload, Mapping):
                data = dict(payload)
                data.setdefault("source_tag", _SERVICE_NAME)
                if key == "episode":
                    data.setdefault("media_type", MediaType.EPISODE.value)
                elif key == "show":
                    data.setdefault("media_type", MediaType.SHOW.value)
                else:
                    data.setdefault("media_type", MediaType.MOVIE.value)
                return data

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
    "OAuthToken",
    "RateLimitInfo",
    "TraktUserProfile",
    "TraktUserSettings",
    "TraktSearchResult",
    "UserList",
    "HistoryEntry",
    "ScrobbleResponse",
]
