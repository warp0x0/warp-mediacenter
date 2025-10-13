from typing import Any, Dict, Optional, Tuple
from requests.adapters import HTTPAdapter
from __future__ import annotations
from urllib.parse import urlparse
import requests
import socket
import random
import time

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

    # -------- public API --------

    def get(self, service: str, path: str, *,
            params: Optional[Dict[str, Any]] = None,
            headers: Optional[Dict[str, str]] = None) -> requests.Response:

        return self._request("GET", service, path, params=params, headers=headers)

    def post(self, service: str, path: str, *,
             json_body: Optional[Dict[str, Any]] = None,
             params: Optional[Dict[str, Any]] = None,
             headers: Optional[Dict[str, str]] = None) -> requests.Response:

        return self._request("POST", service, path, params=params, json_body=json_body, headers=headers)

    # -------- internals --------

    def _request(self, method: str, service: str, path: str, *,
                 params: Optional[Dict[str, Any]],
                 json_body: Optional[Dict[str, Any]] = None,
                 headers: Optional[Dict[str, str]] = None) -> requests.Response:

        url, base_headers = self.urlm.build(service, path, params)
        hdrs = dict(base_headers or {})
        if headers:
            hdrs.update(headers)

        domain = urlparse(url).hostname or ""
        attempt = 1
        last_exc: Optional[Exception] = None

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

                if resp.status_code < 400:
                    self.proxym.mark_good(proxies)

                    return resp

                # 429: optionally respect Retry-After
                if resp.status_code == 429:
                    self.proxym.mark_bad(proxies)
                    if self.urlm.should_respect_retry_after(service):
                        ra = resp.headers.get("Retry-After")
                        if ra:
                            try:
                                time.sleep(min(int(ra), 30))
                            except ValueError:
                                pass  # ignore HTTP-date

                # Retryables
                if 500 <= resp.status_code < 600 or resp.status_code in (408, 429):
                    if resp.status_code != 429:
                        self.proxym.mark_bad(proxies)
                    if attempt == self.retry_max_attempts:
                        raise _map_http_error(resp.status_code)
                else:
                    # Non-retryable 4xx
                    raise _map_http_error(resp.status_code)

            except requests.exceptions.Timeout as e:
                last_exc = e
                self.proxym.mark_bad(proxies)
                if attempt == self.retry_max_attempts:
                    raise TimeoutError(str(e)) from e

            except requests.exceptions.ConnectionError as e:
                last_exc = e
                self.proxym.mark_bad(proxies)
                if isinstance(getattr(e, "__cause__", None), socket.gaierror):
                    if attempt == self.retry_max_attempts:
                        raise DNSFailure(str(e)) from e
                if attempt == self.retry_max_attempts:
                    raise ConnectionFailed(str(e)) from e

            except Exception as e:
                last_exc = e
                self.proxym.mark_bad(proxies)
                if attempt == self.retry_max_attempts:
                    raise NetError(str(e)) from e

            attempt += 1
            _sleep_with_jitter(self.base_backoff_ms, attempt, self.max_backoff_ms, self.jitter_ms)

        raise NetError(f"Request failed after retries: {last_exc}")
