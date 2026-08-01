"""HTTP client handed to plugins.

Deliberately not the app's own ``HttpSession``: that one resolves endpoints
through ``informationproviderservicesettings.json`` and cannot address a base URL
that is not already configured there, which is exactly what a plugin needs to do.

The guard that matters here is the **host allowlist**.  A plugin declares the
hosts it talks to in its manifest, and a request to anything else is refused
before a socket is opened.  It is the cheapest meaningful restriction available to
in-process code, and it makes a plugin's network reach reviewable from its
manifest alone.

Authentication is injected by the host from the plugin's stored token, so plugin
code never handles credentials — see ``host/oauth.py``.
"""

from __future__ import annotations

import random
import threading
import time
from dataclasses import dataclass
from typing import Any, Callable, Collection, Dict, Mapping, Optional
from urllib.parse import urljoin, urlparse

import requests
from requests.adapters import HTTPAdapter

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.plugins.exceptions import PluginError

log = get_logger(__name__)

DEFAULT_TIMEOUT = 20.0
MAX_ATTEMPTS = 3
_RETRY_STATUSES = frozenset({429, 500, 502, 503, 504})


class PluginHostNotAllowed(PluginError):
    """Raised when a plugin requests a host outside its declared allowlist."""


class PluginRateLimited(PluginError):
    """Raised when upstream keeps returning 429 after the retry budget."""

    def __init__(self, message: str, retry_after: Optional[float] = None) -> None:
        super().__init__(message)
        self.retry_after = retry_after


@dataclass
class RateLimit:
    limit: Optional[int] = None
    remaining: Optional[int] = None
    reset_at: Optional[float] = None

    def as_dict(self) -> Dict[str, Any]:
        return {
            "limit": self.limit,
            "remaining": self.remaining,
            "reset_at": self.reset_at,
        }


class PluginHttpResponse:
    """Thin wrapper so plugins never touch a ``requests`` object directly."""

    def __init__(self, response: requests.Response) -> None:
        self._response = response

    @property
    def status(self) -> int:
        return self._response.status_code

    @property
    def ok(self) -> bool:
        return 200 <= self._response.status_code < 300

    @property
    def headers(self) -> Mapping[str, str]:
        return dict(self._response.headers)

    @property
    def text(self) -> str:
        return self._response.text

    @property
    def content(self) -> bytes:
        return self._response.content

    def json(self, default: Any = None) -> Any:
        try:
            return self._response.json()
        except ValueError:
            return default

    @property
    def rate_limit(self) -> RateLimit:
        headers = self._response.headers

        def _int(name: str) -> Optional[int]:
            raw = headers.get(name)
            try:
                return int(raw) if raw is not None else None
            except (TypeError, ValueError):
                return None

        return RateLimit(
            limit=_int("X-RateLimit-Limit"),
            remaining=_int("X-RateLimit-Remaining"),
            reset_at=_int("X-RateLimit-Reset"),
        )


class _TokenBucket:
    """Simple per-minute limiter shared across the plugin's threads.

    Continue Watching fans out across a thread pool, so without this a single
    request can burst dozens of upstream calls and earn a 429 for the next one.
    """

    def __init__(self, per_minute: int) -> None:
        self._capacity = max(1, per_minute)
        self._tokens = float(self._capacity)
        self._rate = self._capacity / 60.0
        self._last = time.monotonic()
        self._lock = threading.Lock()

    def acquire(self, timeout: float) -> bool:
        deadline = time.monotonic() + timeout
        while True:
            with self._lock:
                now = time.monotonic()
                self._tokens = min(
                    float(self._capacity), self._tokens + (now - self._last) * self._rate
                )
                self._last = now
                if self._tokens >= 1.0:
                    self._tokens -= 1.0
                    return True
                needed = (1.0 - self._tokens) / self._rate
            if time.monotonic() + needed > deadline:
                return False
            time.sleep(min(needed, 0.5))


class PluginHttpClient:
    """Allowlisted, rate-limited HTTP for one plugin."""

    def __init__(
        self,
        *,
        plugin_id: str,
        allowed_hosts: Collection[str],
        base_url: str = "",
        rate_limit_per_minute: Optional[int] = None,
        respect_retry_after: bool = True,
        auth_headers: Optional[Callable[[], Mapping[str, str]]] = None,
        on_unauthorized: Optional[Callable[[], bool]] = None,
        user_agent: str = "WarpMediaCenter/1.0",
    ) -> None:
        self._plugin_id = plugin_id
        self._allowed_hosts = {h.strip().lower() for h in allowed_hosts if h and h.strip()}
        self._base_url = base_url.rstrip("/")
        self._respect_retry_after = respect_retry_after
        self._auth_headers = auth_headers
        self._on_unauthorized = on_unauthorized
        self._user_agent = user_agent
        self._bucket = (
            _TokenBucket(rate_limit_per_minute) if rate_limit_per_minute else None
        )

        self._session = requests.Session()
        adapter = HTTPAdapter(pool_connections=8, pool_maxsize=16, max_retries=0)
        self._session.mount("https://", adapter)
        self._session.mount("http://", adapter)

    # -- policy ---------------------------------------------------------

    def _resolve(self, url: str) -> str:
        if url.startswith(("http://", "https://")):
            return url
        if not self._base_url:
            raise PluginError(
                f"Plugin '{self._plugin_id}' used a relative URL but declares no base_url"
            )
        return urljoin(self._base_url + "/", url.lstrip("/"))

    def _check_host(self, url: str) -> None:
        parsed = urlparse(url)
        if parsed.scheme not in {"http", "https"}:
            raise PluginHostNotAllowed(
                f"Plugin '{self._plugin_id}' may only use http(s); got '{parsed.scheme}'"
            )
        host = (parsed.hostname or "").lower()
        if not self._allowed_hosts:
            raise PluginHostNotAllowed(
                f"Plugin '{self._plugin_id}' declares no allowed_hosts; network access refused"
            )
        # An exact match, or a subdomain of a declared host.
        for allowed in self._allowed_hosts:
            if host == allowed or host.endswith("." + allowed):
                return
        raise PluginHostNotAllowed(
            f"Plugin '{self._plugin_id}' is not allowed to reach '{host}'; "
            f"declared hosts: {sorted(self._allowed_hosts)}"
        )

    @staticmethod
    def _retry_after(response: requests.Response) -> Optional[float]:
        raw = response.headers.get("Retry-After")
        if not raw:
            return None
        try:
            return max(0.0, float(raw))
        except (TypeError, ValueError):
            return None

    # -- requests -------------------------------------------------------

    def request(
        self,
        method: str,
        url: str,
        *,
        params: Optional[Mapping[str, Any]] = None,
        json: Optional[Any] = None,
        data: Optional[Any] = None,
        headers: Optional[Mapping[str, str]] = None,
        timeout: Optional[float] = None,
        allowed_statuses: Collection[int] = (),
        authenticated: bool = True,
    ) -> PluginHttpResponse:
        resolved = self._resolve(url)
        self._check_host(resolved)

        timeout = timeout or DEFAULT_TIMEOUT
        allowed = set(allowed_statuses)

        request_headers: Dict[str, str] = {"User-Agent": self._user_agent}
        if authenticated and self._auth_headers is not None:
            request_headers.update(self._auth_headers())
        if headers:
            request_headers.update(headers)

        last_error: Optional[Exception] = None
        refreshed = False

        for attempt in range(1, MAX_ATTEMPTS + 1):
            if self._bucket is not None and not self._bucket.acquire(timeout):
                raise PluginRateLimited(
                    f"Plugin '{self._plugin_id}' exceeded its local rate limit"
                )

            try:
                response = self._session.request(
                    method.upper(),
                    resolved,
                    params=params,
                    json=json,
                    data=data,
                    headers=request_headers,
                    timeout=timeout,
                )
            except requests.RequestException as exc:
                last_error = exc
                if attempt >= MAX_ATTEMPTS:
                    break
                time.sleep(min(2.0 ** (attempt - 1), 4.0) + random.uniform(0, 0.3))
                continue

            status = response.status_code

            # A single transparent re-auth: the host refreshes, then we retry once.
            if (
                status == 401
                and authenticated
                and not refreshed
                and self._on_unauthorized is not None
            ):
                refreshed = True
                if self._on_unauthorized():
                    if self._auth_headers is not None:
                        request_headers.update(self._auth_headers())
                    continue

            if status in allowed or status not in _RETRY_STATUSES:
                # The only line that proves a plugin actually reached its
                # upstream — without it, "the row is empty" and "the plugin
                # was never called" are indistinguishable from the logs alone.
                log.info(
                    "plugin_http_request",
                    plugin_id=self._plugin_id,
                    method=method.upper(),
                    url=resolved,
                    status=status,
                    attempt=attempt,
                )
                return PluginHttpResponse(response)

            if attempt >= MAX_ATTEMPTS:
                if status == 429:
                    raise PluginRateLimited(
                        f"Upstream rate limit for plugin '{self._plugin_id}'",
                        retry_after=self._retry_after(response),
                    )
                return PluginHttpResponse(response)

            delay = min(2.0 ** (attempt - 1), 4.0) + random.uniform(0, 0.3)
            if status == 429 and self._respect_retry_after:
                retry_after = self._retry_after(response)
                if retry_after is not None:
                    delay = min(retry_after, 30.0)
            log.debug(
                "plugin_http_retry",
                plugin_id=self._plugin_id,
                status=status,
                attempt=attempt,
                delay=round(delay, 2),
            )
            time.sleep(delay)

        log.warning(
            "plugin_http_request_failed",
            plugin_id=self._plugin_id,
            method=method.upper(),
            url=resolved,
            error=str(last_error),
        )
        raise PluginError(
            f"Plugin '{self._plugin_id}' request to {resolved} failed: {last_error}"
        )

    def get(self, url: str, **kwargs: Any) -> PluginHttpResponse:
        return self.request("GET", url, **kwargs)

    def post(self, url: str, **kwargs: Any) -> PluginHttpResponse:
        return self.request("POST", url, **kwargs)

    def put(self, url: str, **kwargs: Any) -> PluginHttpResponse:
        return self.request("PUT", url, **kwargs)

    def delete(self, url: str, **kwargs: Any) -> PluginHttpResponse:
        return self.request("DELETE", url, **kwargs)

    def close(self) -> None:
        try:
            self._session.close()
        except Exception:  # noqa: BLE001
            pass


__all__ = [
    "DEFAULT_TIMEOUT",
    "PluginHostNotAllowed",
    "PluginHttpClient",
    "PluginHttpResponse",
    "PluginRateLimited",
    "RateLimit",
]
