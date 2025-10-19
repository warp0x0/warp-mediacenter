from __future__ import annotations

from typing import Any, Dict, Iterable, Mapping, MutableMapping, Optional

from dotenv import load_dotenv
from pathlib import Path
import json
import os
import re
import threading
from dataclasses import dataclass, field
from dataclasses import dataclass
from datetime import datetime

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.resource_management import (
    ResourceProfile,
    get_resource_manager,
)

# local logger
log = get_logger(__name__)

_THIS_DIR = Path(__file__).resolve().parent
_PACKAGE_ROOT = _THIS_DIR.parent  # warp_mediacenter/
_PROJECT_ROOT = _PACKAGE_ROOT.parent

# Include progressively higher parents so relative config paths resolve even if
# the package is imported from a nested working directory (e.g. notebooks).
_PATH_BASES = [_PACKAGE_ROOT, *_PACKAGE_ROOT.parents]

# --- Optional .env support (won't fail if python-dotenv isn't installed) ---
try:
    load_dotenv(_PACKAGE_ROOT / ".env")
except Exception:
    pass

# Path resolution and loaders
_DEFAULT_CONFIG_PATHS = {
    "information_provider_settings": str(_THIS_DIR / "informationproviderservicesettings.json"),
    "proxy_settings": str(_THIS_DIR / "proxysettings.json"),
    "proxy_pool": str(_PACKAGE_ROOT / "Resources" / "webshare_proxies.txt"),
    "cache_root": str(_PACKAGE_ROOT / "var" / "cache"),
    "info_providers_cache": str(_PACKAGE_ROOT / "var" / "cache" / "info_providers"),
    "public_domain_catalogs": str(_PACKAGE_ROOT / "var" / "public_domain_catalogs"),
    "tokens": str(_PACKAGE_ROOT / "var" / "tokens"),
    "user_settings": str(_PACKAGE_ROOT / "var" / "user_settings.json"),
    "library_index": str(_PACKAGE_ROOT / "var" / "library_index.json"),
    "player_temp": str(_PACKAGE_ROOT / "var" / "player" / "temp"),
    "vlc_runtime_root": str(_PACKAGE_ROOT / "Resources" / "vlc"),
    "plugins_root": str(_PACKAGE_ROOT / "var" / "plugins"),
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

    # Make absolute relative to the nearest parent that actually contains the
    # referenced resource (works even when the runtime CWD is inside notebooks).
    def _resolve(value: str) -> str:
        candidate = Path(value)
        if candidate.is_absolute():
            return str(candidate.resolve())

        for base in _PATH_BASES:
            resolved = (base / candidate).resolve()
            if resolved.exists() or resolved.parent.exists():
                return str(resolved)

        # Fallback to the package root even if the path does not exist yet.
        return str((_PACKAGE_ROOT / candidate).resolve())

    for key, value in list(merged.items()):
        merged[key] = _resolve(value)

    return merged

# ---------------------------
# Public API
# ---------------------------

# Centralized absolute paths
PATHS: Dict[str, str] = _load_config_paths()

_USER_SETTINGS_PATH = Path(PATHS["user_settings"])
_LIBRARY_INDEX_PATH = Path(PATHS["library_index"])
_PLUGINS_ROOT_PATH = Path(PATHS["plugins_root"])

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


def get_player_temp_dir() -> str:
    """Directory where downloaded/temporary player files should live."""

    path = Path(PATHS["player_temp"])
    path.mkdir(parents=True, exist_ok=True)

    return str(path)


def get_vlc_runtime_root() -> str:
    """Root directory where bundled VLC binaries are stored."""

    return PATHS["vlc_runtime_root"]


def get_plugins_root() -> str:
    """Directory where third-party plugins should be installed."""

    _PLUGINS_ROOT_PATH.mkdir(parents=True, exist_ok=True)

    return str(_PLUGINS_ROOT_PATH)

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


def list_provider_configs() -> Dict[str, Dict[str, Any]]:
    """Return a shallow copy of all configured information provider sections."""

    providers = _provider_settings()
    result: Dict[str, Dict[str, Any]] = {}
    for name, cfg in providers.items():
        if isinstance(cfg, Mapping):
            result[name] = dict(cfg)
        else:
            result[name] = {}

    return result


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


# ---------------------------------------------------------------------------
# Runtime settings + persistence for mutable bits (local libraries, etc.)
# ---------------------------------------------------------------------------

LibraryMediaKind = str


def _normalize_media_kind(kind: LibraryMediaKind) -> str:
    value = (kind or "").strip().lower()
    if value in {"movie", "movies"}:
        return "movie"
    if value in {"show", "shows", "tv", "tv_show", "tv_shows"}:
        return "show"
    raise ValueError(f"Unsupported media kind '{kind}'")


def _coerce_path(value: Optional[str]) -> Optional[str]:
    if not value:
        return None
    path = Path(value).expanduser()
    try:
        return str(path.resolve())
    except Exception:
        return str(path)


def _ensure_parent(path: Path) -> None:
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
    except Exception:
        # Fall back silently; callers can handle write errors separately.
        pass


def _load_user_settings() -> Dict[str, Any]:
    if not _USER_SETTINGS_PATH.exists():
        return {}
    try:
        with _USER_SETTINGS_PATH.open("r", encoding="utf-8") as fh:
            return json.load(fh)
    except Exception:
        return {}


def _write_user_settings(payload: Mapping[str, Any]) -> None:
    _ensure_parent(_USER_SETTINGS_PATH)
    with _USER_SETTINGS_PATH.open("w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2, ensure_ascii=False, sort_keys=True)


def _load_library_index() -> Dict[str, Any]:
    if not _LIBRARY_INDEX_PATH.exists():
        return {"movies": {}, "shows": {}}
    try:
        with _LIBRARY_INDEX_PATH.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
    except Exception:
        return {"movies": {}, "shows": {}}

    if not isinstance(data, MutableMapping):
        return {"movies": {}, "shows": {}}

    movies = data.get("movies") if isinstance(data.get("movies"), Mapping) else {}
    shows = data.get("shows") if isinstance(data.get("shows"), Mapping) else {}

    return {"movies": dict(movies), "shows": dict(shows)}


def load_library_index() -> Dict[str, Any]:
    """Return the persisted library index, defaulting to empty structure."""

    return _load_library_index()


def save_library_index(index: Mapping[str, Any]) -> None:
    """Persist the given library index structure to disk."""

    serializable = {
        "movies": dict(index.get("movies") or {}),
        "shows": dict(index.get("shows") or {}),
    }
    _ensure_parent(_LIBRARY_INDEX_PATH)
    with _LIBRARY_INDEX_PATH.open("w", encoding="utf-8") as fh:
        json.dump(serializable, fh, indent=2, ensure_ascii=False, sort_keys=True)


def get_library_index_path() -> Path:
    return _LIBRARY_INDEX_PATH


@dataclass
class LibraryPaths:
    movies: Optional[str] = None
    shows: Optional[str] = None

    def get(self, kind: LibraryMediaKind) -> Optional[str]:
        normalized = _normalize_media_kind(kind)
        return self.movies if normalized == "movie" else self.shows

    def set(self, kind: LibraryMediaKind, path: Optional[str]) -> None:
        normalized = _normalize_media_kind(kind)
        if normalized == "movie":
            self.movies = _coerce_path(path) if path else None
        else:
            self.shows = _coerce_path(path) if path else None

    def as_dict(self) -> Dict[str, Optional[str]]:
        return {
            "movie": self.movies,
            "show": self.shows,
        }


def _normalize_estimated_memory(value: Any) -> Optional[float]:
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


@dataclass
class InstalledPlugin:
    plugin_id: str
    name: str
    version: str
    entrypoint: str
    path: str
    installed_at: str
    description: Optional[str] = None
    estimated_memory_mb: Optional[float] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def as_dict(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "plugin_id": self.plugin_id,
            "name": self.name,
            "version": self.version,
            "entrypoint": self.entrypoint,
            "path": self.path,
            "installed_at": self.installed_at,
        }
        if self.description:
            payload["description"] = self.description
        if self.estimated_memory_mb is not None:
            payload["estimated_memory_mb"] = self.estimated_memory_mb
        if self.metadata:
            payload["metadata"] = dict(self.metadata)

        return payload


def _load_installed_plugins(payload: Mapping[str, Any]) -> Dict[str, InstalledPlugin]:
    raw = payload.get("plugins")
    if not isinstance(raw, Mapping):
        return {}

    plugins: Dict[str, InstalledPlugin] = {}
    for key, data in raw.items():
        if not isinstance(data, Mapping):
            continue
        plugin_id = str(data.get("plugin_id") or key or "").strip()
        if not plugin_id:
            continue
        entrypoint = str(data.get("entrypoint") or "").strip()
        if not entrypoint:
            continue
        path = _coerce_path(data.get("path"))
        if not path:
            continue
        metadata = data.get("metadata")
        if isinstance(metadata, Mapping):
            metadata_dict = dict(metadata)
        else:
            metadata_dict = {}
        description = data.get("description")
        if description is not None:
            description = str(description)
        plugins[plugin_id] = InstalledPlugin(
            plugin_id=plugin_id,
            name=str(data.get("name") or plugin_id),
            version=str(data.get("version") or "0.0.0"),
            entrypoint=entrypoint,
            path=path,
            installed_at=str(data.get("installed_at") or ""),
            description=description,
            estimated_memory_mb=_normalize_estimated_memory(data.get("estimated_memory_mb")),
            metadata=metadata_dict,
        )

    return plugins


def _serialize_plugins(plugins: Mapping[str, InstalledPlugin]) -> Dict[str, Any]:
    return {plugin_id: plugin.as_dict() for plugin_id, plugin in plugins.items()}


@dataclass
class Settings:
    app_name: str
    env: str
    log_level: str
    task_workers: int
    library_paths: LibraryPaths
    user_settings_path: Path
    library_index_path: Path
    resource_profile: ResourceProfile
    plugins: Dict[str, "InstalledPlugin"] = field(default_factory=dict)

    def library_path(self, kind: LibraryMediaKind) -> Optional[str]:
        return self.library_paths.get(kind)

    def plugin(self, plugin_id: str) -> Optional["InstalledPlugin"]:
        return self.plugins.get(plugin_id)

    def as_dict(self) -> Dict[str, Any]:
        return {
            "app_name": self.app_name,
            "env": self.env,
            "log_level": self.log_level,
            "task_workers": self.task_workers,
            "library_paths": self.library_paths.as_dict(),
            "resource_profile": self.resource_profile.as_dict(),
            "plugins": {pid: plugin.as_dict() for pid, plugin in self.plugins.items()},
        }


_SETTINGS_LOCK = threading.Lock()
_SETTINGS_SINGLETON: Optional[Settings] = None


def _build_settings() -> Settings:
    user_cfg = _load_user_settings()
    app_name = os.getenv("WARP_APP_NAME", user_cfg.get("app_name", "Warp MediaCenter"))
    env = os.getenv("WARP_ENV", user_cfg.get("env", "development"))
    log_level = os.getenv("WARP_LOG_LEVEL", user_cfg.get("log_level", "INFO")).upper()

    task_workers_raw = os.getenv("WARP_TASK_WORKERS") or user_cfg.get("task_workers", 4)
    try:
        task_workers = max(1, int(task_workers_raw))
    except (TypeError, ValueError):
        task_workers = 4

    resource_manager = get_resource_manager()
    profile = resource_manager.build_profile(requested_workers=task_workers)
    if profile.recommended_task_workers != task_workers:
        log.info(
            "settings_task_workers_adjusted",
            requested=task_workers,
            recommended=profile.recommended_task_workers,
        )
        task_workers = profile.recommended_task_workers

    libs_cfg = user_cfg.get("library_paths") or {}
    movies_path = _coerce_path(libs_cfg.get("movie") or libs_cfg.get("movies"))
    shows_path = _coerce_path(
        libs_cfg.get("show")
        or libs_cfg.get("shows")
        or libs_cfg.get("tv")
        or libs_cfg.get("tv_show")
        or libs_cfg.get("tv_shows")
    )
    library_paths = LibraryPaths(movies=movies_path, shows=shows_path)
    plugins = _load_installed_plugins(user_cfg)

    return Settings(
        app_name=app_name,
        env=env,
        log_level=log_level,
        task_workers=task_workers,
        library_paths=library_paths,
        user_settings_path=_USER_SETTINGS_PATH,
        library_index_path=_LIBRARY_INDEX_PATH,
        resource_profile=profile,
        plugins=plugins,
    )


def get_settings(*, reload: bool = False) -> Settings:
    """Return the cached :class:`Settings` singleton, optionally reloading."""

    global _SETTINGS_SINGLETON
    with _SETTINGS_LOCK:
        if _SETTINGS_SINGLETON is None or reload:
            _SETTINGS_SINGLETON = _build_settings()

        return _SETTINGS_SINGLETON


def update_library_path(kind: LibraryMediaKind, path: str) -> Settings:
    """Persist and return settings with the updated library path."""

    normalized = _normalize_media_kind(kind)
    current = get_settings()
    current.library_paths.set(normalized, path)

    payload = _load_user_settings()
    payload["library_paths"] = current.library_paths.as_dict()
    payload["plugins"] = _serialize_plugins(current.plugins)
    payload["app_name"] = current.app_name
    payload["env"] = current.env
    payload["log_level"] = current.log_level
    payload["task_workers"] = current.task_workers
    payload["updated_at"] = datetime.utcnow().isoformat() + "Z"
    _write_user_settings(payload)

    # Refresh singleton to ensure callers observe the change
    return get_settings(reload=True)


def get_installed_plugins() -> Dict[str, InstalledPlugin]:
    """Return the installed plugin registry."""

    return dict(get_settings().plugins)


def register_installed_plugin(plugin: InstalledPlugin) -> Settings:
    """Persist a plugin installation and refresh settings."""

    current = get_settings()
    plugins = dict(current.plugins)
    plugins[plugin.plugin_id] = plugin

    payload = _load_user_settings()
    payload["library_paths"] = current.library_paths.as_dict()
    payload["plugins"] = _serialize_plugins(plugins)
    payload["app_name"] = current.app_name
    payload["env"] = current.env
    payload["log_level"] = current.log_level
    payload["task_workers"] = current.task_workers
    payload["updated_at"] = datetime.utcnow().isoformat() + "Z"
    _write_user_settings(payload)

    return get_settings(reload=True)


def remove_installed_plugin(plugin_id: str) -> Settings:
    """Remove a plugin from the registry and refresh settings."""

    current = get_settings()
    if plugin_id not in current.plugins:
        return current

    plugins = dict(current.plugins)
    plugins.pop(plugin_id, None)

    payload = _load_user_settings()
    payload["library_paths"] = current.library_paths.as_dict()
    payload["plugins"] = _serialize_plugins(plugins)
    payload["app_name"] = current.app_name
    payload["env"] = current.env
    payload["log_level"] = current.log_level
    payload["task_workers"] = current.task_workers
    payload["updated_at"] = datetime.utcnow().isoformat() + "Z"
    _write_user_settings(payload)

    return get_settings(reload=True)


__all__ = [
    "PATHS",
    "INFORMATION_PROVIDER_SETTINGS",
    "PROXY_SETTINGS",
    "load_information_provider_settings",
    "load_proxy_settings",
    "get_proxy_pool_path",
    "get_cache_root",
    "get_info_providers_cache_dir",
    "get_public_domain_catalog_dir",
    "get_tokens_dir",
    "get_service_config",
    "list_provider_configs",
    "get_rate_limits",
    "get_default_headers",
    "get_base_url",
    "get_api_key_tmdb",
    "get_tmdb_image_config",
    "get_trakt_keys",
    "get_provider_endpoints",
    "get_pipeline_config",
    "iter_pipeline_public_domain_sources",
    "get_content_list_config",
    "list_content_lists",
    "get_public_domain_sources",
    "get_public_domain_source_config",
    "Settings",
    "LibraryPaths",
    "InstalledPlugin",
    "ResourceProfile",
    "get_settings",
    "update_library_path",
    "load_library_index",
    "save_library_index",
    "get_library_index_path",
    "get_plugins_root",
    "get_installed_plugins",
    "register_installed_plugin",
    "remove_installed_plugin",
]
