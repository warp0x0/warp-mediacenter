from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, Iterable, Mapping, Optional

from .paths import PATHS, expand_env, read_json


def load_information_provider_settings() -> Dict[str, Any]:
    path = Path(PATHS["information_provider_settings"])
    data = read_json(path)

    return expand_env(data)


def load_proxy_settings() -> Dict[str, Any]:
    path = Path(PATHS["proxy_settings"])
    data = read_json(path)

    return expand_env(data)


try:  # pragma: no cover - guard against missing files at import time
    INFORMATION_PROVIDER_SETTINGS: Dict[str, Any] = load_information_provider_settings()
except Exception:
    INFORMATION_PROVIDER_SETTINGS = {}

try:  # pragma: no cover - guard against missing files at import time
    PROXY_SETTINGS: Dict[str, Any] = load_proxy_settings()
except Exception:
    PROXY_SETTINGS = {}


def _provider_settings() -> Dict[str, Any]:
    return INFORMATION_PROVIDER_SETTINGS.get("providers", {}) if INFORMATION_PROVIDER_SETTINGS else {}


def _pipeline_settings() -> Dict[str, Any]:
    return INFORMATION_PROVIDER_SETTINGS.get("pipelines", {}) if INFORMATION_PROVIDER_SETTINGS else {}


def _content_lists_settings() -> Dict[str, Any]:
    return INFORMATION_PROVIDER_SETTINGS.get("content_lists", {}) if INFORMATION_PROVIDER_SETTINGS else {}


def list_provider_configs() -> Dict[str, Dict[str, Any]]:
    providers = _provider_settings()
    result: Dict[str, Dict[str, Any]] = {}
    for name, cfg in providers.items():
        if isinstance(cfg, Mapping):
            result[name] = dict(cfg)
        else:
            result[name] = {}

    return result


def get_service_config(service: str) -> Optional[Dict[str, Any]]:
    providers = _provider_settings()
    if not providers:
        return None

    return providers.get(service)


def get_rate_limits(service: str) -> Optional[Dict[str, Any]]:
    cfg = get_service_config(service)
    if not cfg:
        return None

    return cfg.get("rate_limits")


def get_default_headers(service: str) -> Dict[str, str]:
    cfg = get_service_config(service) or {}
    headers = cfg.get("default_headers", {}) or {}

    return {k: expand_env(v) for k, v in headers.items()} if headers else {}


def get_base_url(service: str) -> Optional[str]:
    cfg = get_service_config(service)
    if not cfg:
        return None

    return cfg.get("base_url")


def get_api_key_tmdb() -> Optional[str]:
    cfg = get_service_config("tmdb")

    return cfg.get("api_key") if cfg else None


def get_tmdb_image_config() -> Dict[str, Any]:
    cfg = get_service_config("tmdb") or {}

    return cfg.get("images", {}) or {}


def get_trakt_keys() -> Dict[str, Optional[str]]:
    cfg = get_service_config("trakt") or {}

    return {
        "client_id": cfg.get("client_id"),
        "client_secret": cfg.get("client_secret"),
    }


def get_provider_endpoints(service: str) -> Mapping[str, Any]:
    cfg = get_service_config(service) or {}

    return cfg.get("endpoints", {}) or {}


def get_pipeline_config(pipeline: str) -> Optional[Dict[str, Any]]:
    pipelines = _pipeline_settings()
    if not pipelines:
        return None

    return pipelines.get(pipeline)


def iter_pipeline_public_domain_sources(pipeline: str) -> Iterable[str]:
    cfg = get_pipeline_config(pipeline) or {}
    sources = cfg.get("public_domain_sources", []) or []

    return list(sources)


def get_content_list_config(list_key: str) -> Optional[Dict[str, Any]]:
    content_lists = _content_lists_settings()
    if not content_lists:
        return None

    return content_lists.get(list_key)


def list_content_lists() -> Dict[str, Dict[str, Any]]:
    return _content_lists_settings()


def get_public_domain_sources() -> Dict[str, Dict[str, Any]]:
    provider = get_service_config("public_domain") or {}
    sources = provider.get("sources", {}) or {}
    base_headers = provider.get("default_headers", {}) or {}
    base_url = provider.get("base_url")

    combined: Dict[str, Dict[str, Any]] = {}
    for key, config in sources.items():
        merged = dict(config)
        headers = dict(base_headers)
        headers.update(config.get("headers", {}) or {})
        if headers:
            merged["headers"] = headers
        if "base_url" not in merged and base_url:
            merged["base_url"] = base_url
        combined[key] = merged

    return combined


def get_public_domain_source_config(source_key: str) -> Optional[Dict[str, Any]]:
    sources = get_public_domain_sources()
    if not sources:
        return None

    return sources.get(source_key)


__all__ = [
    "INFORMATION_PROVIDER_SETTINGS",
    "PROXY_SETTINGS",
    "get_api_key_tmdb",
    "get_base_url",
    "get_content_list_config",
    "get_default_headers",
    "get_pipeline_config",
    "get_provider_endpoints",
    "get_public_domain_source_config",
    "get_public_domain_sources",
    "get_rate_limits",
    "get_service_config",
    "get_tmdb_image_config",
    "get_trakt_keys",
    "iter_pipeline_public_domain_sources",
    "list_content_lists",
    "list_provider_configs",
    "load_information_provider_settings",
    "load_proxy_settings",
]
