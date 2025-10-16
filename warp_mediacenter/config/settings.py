from __future__ import annotations

from typing import Any, Dict, Iterable, Mapping, Optional

from dotenv import load_dotenv
from pathlib import Path
import json
import os
import re

# --- Optional .env support (won't fail if python-dotenv isn't installed) ---
try:
    load_dotenv()
except Exception:
    pass

# Path resolution and loaders
_THIS_DIR = Path(__file__).resolve().parent
_PROJECT_ROOT = _THIS_DIR.parent  # warp_mediacenter/
_DEFAULT_CONFIG_PATHS = {
    "information_provider_settings": str(_THIS_DIR / "informationproviderservicesettings.json"),
    "proxy_settings": str(_THIS_DIR / "proxysettings.json"),
    "proxy_pool": str(_PROJECT_ROOT / "Resources" / "webshare_proxies.txt"),
    "cache_root": str(_PROJECT_ROOT / "var" / "cache"),
    "info_providers_cache": str(_PROJECT_ROOT / "var" / "cache" / "info_providers"),
    "public_domain_catalogs": str(_PROJECT_ROOT / "var" / "public_domain_catalogs"),
    "tokens": str(_PROJECT_ROOT / "var" / "tokens"),
}

_ENV_PATTERN = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}")

def _expand_env_in_str(value: str) -> str:
    """Expand ${VAR} from environment within a string."""
    def _repl(match: re.Match[str]) -> str:
        var = match.group(1)
        return os.getenv(var, "")
    
    return _ENV_PATTERN.sub(_repl, value)

def _expand_env(obj: Any) -> Any:
    """Recursively expand ${VAR} in dict/list/str structures."""
    if isinstance(obj, str):
        return _expand_env_in_str(obj)
    if isinstance(obj, list):
        return [_expand_env(v) for v in obj]
    if isinstance(obj, dict):
        return {k: _expand_env(v) for k, v in obj.items()}
    
    return obj

def _read_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)

def _load_config_paths() -> Dict[str, str]:
    """
    Load config_paths.json if present; otherwise fall back to defaults.
    All returned paths are absolute.
    """
    cfg_path = _THIS_DIR / "config_paths.json"
    if not cfg_path.exists():
        # Defaults
        resolved = {k: str(Path(v).resolve()) for k, v in _DEFAULT_CONFIG_PATHS.items()}
    
        return resolved

    raw = _read_json(cfg_path)
    merged = {**_DEFAULT_CONFIG_PATHS, **(raw or {})}
    # Make absolute
    for k, v in list(merged.items()):
        merged[k] = str(Path(v).resolve())
    
    return merged

# ---------------------------
# Public API
# ---------------------------

# Centralized absolute paths
PATHS: Dict[str, str] = _load_config_paths()

def load_information_provider_settings() -> Dict[str, Any]:
    """Load and return informationproviderservicesettings.json with env expansion."""
    p = Path(PATHS["information_provider_settings"])
    data = _read_json(p)

    return _expand_env(data)

def load_proxy_settings() -> Dict[str, Any]:
    """Load and return proxysettings.json with env expansion (if any)."""
    p = Path(PATHS["proxy_settings"])
    data = _read_json(p)
    
    return _expand_env(data)

def get_proxy_pool_path() -> str:
    """Absolute path to the proxy pool text file."""

    return PATHS["proxy_pool"]


def get_cache_root() -> str:
    """Root directory for cache data."""

    return PATHS["cache_root"]


def get_info_providers_cache_dir() -> str:
    """Directory where information provider cache entries should be stored."""

    return PATHS["info_providers_cache"]


def get_public_domain_catalog_dir() -> str:
    """Directory containing static public domain catalog payloads."""

    return PATHS["public_domain_catalogs"]


def get_tokens_dir() -> str:
    """Directory that stores token payloads and secrets."""

    return PATHS["tokens"]

# Eager, cached singletons (safe for small JSONs)
try:
    INFORMATION_PROVIDER_SETTINGS: Dict[str, Any] = load_information_provider_settings()
except Exception:
    # Keep import from crashing; consumer modules can handle missing configs at runtime
    INFORMATION_PROVIDER_SETTINGS = {}

try:
    PROXY_SETTINGS: Dict[str, Any] = load_proxy_settings()
except Exception:
    PROXY_SETTINGS = {}


def _provider_settings() -> Dict[str, Any]:
    return INFORMATION_PROVIDER_SETTINGS.get("providers", {}) if INFORMATION_PROVIDER_SETTINGS else {}


def _pipeline_settings() -> Dict[str, Any]:
    return INFORMATION_PROVIDER_SETTINGS.get("pipelines", {}) if INFORMATION_PROVIDER_SETTINGS else {}


def _content_lists_settings() -> Dict[str, Any]:
    return INFORMATION_PROVIDER_SETTINGS.get("content_lists", {}) if INFORMATION_PROVIDER_SETTINGS else {}


def get_service_config(service: str) -> Optional[Dict[str, Any]]:
    """Convenience accessor for provider configuration sections."""
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

    return {k: _expand_env(v) for k, v in headers.items()} if headers else {}


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
