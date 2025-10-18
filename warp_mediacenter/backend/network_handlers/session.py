from __future__ import annotations

from typing import Any, Callable, Collection, Dict, Mapping, Optional, Tuple
from urllib.parse import urlparse
import random
import socket
import time

import requests
from requests.adapters import HTTPAdapter

from warp_mediacenter.backend.network_handlers.url_manager import URLManager
from warp_mediacenter.backend.network_handlers.proxy_manager import ProxyManager



# ---------------- Exceptions ----------------

class NetError(Exception): ...
class TimeoutError(NetError): ...
class DNSFailure(NetError): ...
class ConnectionFailed(NetError): ...
class BadRequest(NetError): ...
class Unauthorized(NetError): ...
class Forbidden(NetError): ...
class NotFound(NetError): ...
class RateLimited(NetError): ...
class Upstream5xx(NetError): ...
class Client4xx(NetError): ...


def _map_http_error(status: int) -> NetError:
    if status == 400: return BadRequest("400 Bad Request")
    if status == 401: return Unauthorized("401 Unauthorized")
    if status == 403: return Forbidden("403 Forbidden")
    if status == 404: return NotFound("404 Not Found")
    if status == 429: return RateLimited("429 Too Many Requests")
    if 500 <= status < 600: return Upstream5xx(f"{status} Upstream error")
    
    return Client4xx(f"{status} HTTP error")

def _sleep_with_jitter(base_ms: int, attempt: int, max_ms: int, jitter_ms: int):
    backoff = min(max_ms, int((2 ** (attempt - 1)) * base_ms))
    jitter = random.randint(0, max(0, jitter_ms))
    time.sleep((backoff + jitter) / 1000.0)


# ---------------- Main Session ----------------

TokenRefresher = Callable[[str, "HttpSession", Optional[requests.Response]], Optional[Mapping[str, str]]]


class HttpSession:
    """
    Central HTTP client:
      - URL building + per-service headers via URLManager
      - Proxy selection returns dict {"http": url, "https": url}
      - Exponential backoff + jitter
      - 429 Retry-After support
      - Typed error mapping
    """

    def __init__(self, timeout: int = 20):
        self.urlm = URLManager()
        self.proxym = ProxyManager()
        self.timeout = timeout

        self._session = requests.Session()
        self._session.mount("http://", HTTPAdapter(pool_connections=8, pool_maxsize=16))
        self._session.mount("https://", HTTPAdapter(pool_connections=8, pool_maxsize=16))

        self.retry_max_attempts = self.proxym.retry_cfg.get("max_attempts", 4)
        self.base_backoff_ms = self.proxym.retry_cfg.get("base_backoff_ms", 300)
        self.max_backoff_ms = self.proxym.retry_cfg.get("max_backoff_ms", 6000)
        self.jitter_ms = self.proxym.retry_cfg.get("jitter_ms", 250)

        # service -> callable invoked once when a 401 is encountered to refresh auth
        self._token_refreshers: Dict[str, TokenRefresher] = {}

    # -------- public API --------

    def get(
        self,
        service: str,
        path: str,
        *,
        params: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
        allowed_statuses: Optional[Collection[int]] = None,
    ) -> requests.Response:

        return self._request(
            "GET",
            service,
            path,
            params=params,
            headers=headers,
            allowed_statuses=allowed_statuses,
        )

    def post(
        self,
        service: str,
        path: str,
        *,
        json_body: Optional[Dict[str, Any]] = None,
        params: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
        allowed_statuses: Optional[Collection[int]] = None,
    ) -> requests.Response:

        return self._request(
            "POST",
            service,
            path,
            params=params,
            json_body=json_body,
            headers=headers,
            allowed_statuses=allowed_statuses,
        )

    def register_token_refresher(
        self,
        service: str,
        handler: Optional[TokenRefresher],
    ) -> None:
        """Register or remove a token refresh hook for a service."""

        if handler is None:
            self._token_refreshers.pop(service, None)
        else:
            self._token_refreshers[service] = handler

    # -------- internals --------

    def _request(
        self,
        method: str,
        service: str,
        path: str,
        *,
        params: Optional[Dict[str, Any]],
        json_body: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
        allowed_statuses: Optional[Collection[int]] = None,
    ) -> requests.Response:

        url, base_headers = self.urlm.build(service, path, params)
        hdrs = dict(base_headers or {})
        if headers:
            hdrs.update(headers)

        allowed = set(allowed_statuses or ())

        domain = urlparse(url).hostname or ""
        attempt = 1
        last_exc: Optional[Exception] = None
        token_refresh_attempted = False
        normalized_path = path or ""
        is_oauth_request = normalized_path.lstrip("/").startswith("oauth/")

        while attempt <= self.retry_max_attempts:
            proxies = self.proxym.choose(domain) if self.proxym.enabled_for_domain(domain) else None

            try:
                resp = self._session.request(
                    method=method,
                    url=url,
                    headers=hdrs,
                    json=json_body,
                    timeout=self.timeout,
                    proxies=proxies,
                )

                status = resp.status_code

                if status < 400 or status in allowed:
                    self.proxym.mark_good(proxies)

                    return resp

                if status == 401:
                    refresher = self._token_refreshers.get(service)
                    if (
                        refresher is not None
                        and not token_refresh_attempted
                        and not is_oauth_request
                    ):
                        token_refresh_attempted = True
                        updated = refresher(service, self, resp)
                        if updated:
                            hdrs.update(dict(updated))
                        continue

                    raise _map_http_error(status)

                if status == 429:
                    last_exc = _map_http_error(status)
                    if self.urlm.should_respect_retry_after(service):
                        ra = resp.headers.get("Retry-After")
                        if ra:
                            try:
                                time.sleep(min(int(float(ra)), 30))
                            except (ValueError, TypeError):
                                pass  # ignore malformed header / HTTP-date
                    if attempt == self.retry_max_attempts:
                        raise last_exc
                    attempt += 1
                    _sleep_with_jitter(self.base_backoff_ms, attempt, self.max_backoff_ms, self.jitter_ms)
                    continue

                if status == 408 or 500 <= status < 600:
                    last_exc = _map_http_error(status)
                    self.proxym.mark_bad(proxies)
                    if attempt == self.retry_max_attempts:
                        raise last_exc
                    attempt += 1
                    _sleep_with_jitter(self.base_backoff_ms, attempt, self.max_backoff_ms, self.jitter_ms)
                    continue

                # Non-retryable 4xx
                raise _map_http_error(status)

            except requests.exceptions.Timeout as e:
                last_exc = e
                self.proxym.mark_bad(proxies)
                if attempt == self.retry_max_attempts:
                    raise TimeoutError(str(e)) from e

                attempt += 1
                _sleep_with_jitter(self.base_backoff_ms, attempt, self.max_backoff_ms, self.jitter_ms)
                continue

            except requests.exceptions.ConnectionError as e:
                last_exc = e
                self.proxym.mark_bad(proxies)
                if isinstance(getattr(e, "__cause__", None), socket.gaierror):
                    if attempt == self.retry_max_attempts:
                        raise DNSFailure(str(e)) from e
                if attempt == self.retry_max_attempts:
                    raise ConnectionFailed(str(e)) from e

                attempt += 1
                _sleep_with_jitter(self.base_backoff_ms, attempt, self.max_backoff_ms, self.jitter_ms)
                continue

            except NetError as e:
                last_exc = e
                raise

            except Exception as e:
                last_exc = e
                self.proxym.mark_bad(proxies)
                if attempt == self.retry_max_attempts:
                    raise NetError(str(e)) from e

                attempt += 1
                _sleep_with_jitter(self.base_backoff_ms, attempt, self.max_backoff_ms, self.jitter_ms)
                continue

        raise NetError(f"Request failed after retries: {last_exc}")
