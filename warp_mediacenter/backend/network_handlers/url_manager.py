from typing import Any, Dict, Optional, Tuple, Iterable
from urllib.parse import urlencode, urljoin
from __future__ import annotations
from dataclasses import dataclass

from warp_mediacenter.config.settings import (
    INFORMATION_PROVIDER_SETTINGS,
    get_service_config,
    get_default_headers,
    get_base_url,
)



# ----------------------------
# Data views (read-only access)
# ----------------------------

@dataclass(frozen=True)
class ServiceView:
    name: str
    base_url: str
    default_headers: Dict[str, str]
    rate_limits: Dict[str, Any]
    endpoints: Dict[str, str]
    raw: Dict[str, Any]  # full raw dict for service (in case callers need misc extras)


# ----------------------------
# URL Manager
# ----------------------------

class URLManager:
    """
    Builds service URLs and injects per-service defaults (headers, auth in query/header),
    without doing any network I/O. Pure config-driven.

    - TMDb: appends `api_key` from settings (already env-expanded) into query
    - Trakt: relies on default headers containing `trakt-api-key` (env-expanded)
    """

    def __init__(self, service_overrides: Optional[Dict[str, Dict[str, Any]]] = None):
        self._services_raw: Dict[str, Dict[str, Any]] = {}
        base_cfg = INFORMATION_PROVIDER_SETTINGS or {}
        for svc, cfg in base_cfg.items():
            merged = dict(cfg)
            if service_overrides and svc in service_overrides:
                merged.update(service_overrides[svc] or {})
            self._services_raw[svc] = merged

        # cached views
        self._views: Dict[str, ServiceView] = {}
        for name in self._services_raw.keys():
            self._views[name] = self._build_view(name)

    # -------- Public API --------

    def build(self, service: str, path: str, params: Optional[Dict[str, Any]] = None
              ) -> Tuple[str, Dict[str, str]]:
        """
        Build a full URL for an absolute/relative path for a given service.
        Returns (url, headers).
        """
        view = self._require_view(service)
        params = dict(params or {})
        headers = dict(view.default_headers or {})

        # Service-specific auth injection (query/header) kept minimal on purpose.
        if service == "tmdb":
            api_key = (self._services_raw.get("tmdb") or {}).get("api_key")
            if api_key and "api_key" not in params:
                params["api_key"] = api_key

        # Compose base + path
        base = _ensure_trailing_slash(view.base_url)
        url = urljoin(base, path.lstrip("/"))

        if params:
            url = f"{url}?{urlencode(params, doseq=True)}"

        return url, headers

    def build_from_endpoint(self, service: str, endpoint_key: str,
                            fmt_args: Optional[Iterable[Any]] = None,
                            params: Optional[Dict[str, Any]] = None
                            ) -> Tuple[str, Dict[str, str]]:
        """
        Convenience: resolve an endpoint by key, format placeholders, and build.
        Example:
            build_from_endpoint("tmdb", "movie_details", fmt_args=(550,), params={"language":"en-US"})
        """
        
        path_tmpl = self.get_endpoint(service, endpoint_key)
        if path_tmpl is None:
            raise ValueError(f"Unknown endpoint '{endpoint_key}' for service '{service}'")
        path = path_tmpl.format(*(fmt_args or ()))
        
        return self.build(service, path, params=params)

    def get_endpoint(self, service: str, key: str) -> Optional[str]:
        view = self._require_view(service)
        
        return view.endpoints.get(key)

    def rate_limits(self, service: str) -> Dict[str, Any]:
        view = self._require_view(service)
        
        return dict(view.rate_limits or {})

    def should_respect_retry_after(self, service: str) -> bool:
        rl = self.rate_limits(service)
        val = rl.get("respect_retry_after")
        
        return True if val is None else bool(val)

    def service_headers(self, service: str) -> Dict[str, str]:
        """Return the default headers for a service (already env-expanded)."""
        view = self._require_view(service)
        
        return dict(view.default_headers or {})

    # -------- Internals --------

    def _require_view(self, service: str) -> ServiceView:
        if service not in self._views:
            raise ValueError(f"Unknown service '{service}'. Known: {list(self._views.keys())}")
        
        return self._views[service]

    def _build_view(self, service: str) -> ServiceView:
        raw = dict(self._services_raw.get(service) or {})
        base_url = raw.get("base_url") or ""
        default_headers = get_default_headers(service)  # env-expanded
        rate_limits = dict(raw.get("rate_limits") or {})
        endpoints = dict(raw.get("endpoints") or {})
        
        return ServiceView(
            name=service,
            base_url=base_url,
            default_headers=default_headers,
            rate_limits=rate_limits,
            endpoints=endpoints,
            raw=raw,
        )


# ----------------------------
# Helpers
# ----------------------------

def _ensure_trailing_slash(u: str) -> str:
    return u if u.endswith("/") else (u + "/")
