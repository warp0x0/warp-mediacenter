from __future__ import annotations

import json
import os
import re
from pathlib import Path
from typing import Any, Dict

try:
    from dotenv import load_dotenv
except Exception:  # pragma: no cover - optional dependency
    load_dotenv = None  # type: ignore[assignment]

_CONFIG_DIR = Path(__file__).resolve().parent.parent
_PACKAGE_ROOT = _CONFIG_DIR.parent
_PATH_BASES = [_PACKAGE_ROOT, *_PACKAGE_ROOT.parents]

if load_dotenv is not None:
    try:  # pragma: no cover - avoid failing if dotenv misbehaves
        load_dotenv(_PACKAGE_ROOT / ".env")
    except Exception:
        pass

_DEFAULT_CONFIG_PATHS = {
    "information_provider_settings": str(_CONFIG_DIR / "informationproviderservicesettings.json"),
    "proxy_settings": str(_CONFIG_DIR / "proxysettings.json"),
    "proxy_pool": str(_PACKAGE_ROOT / "Resources" / "webshare_proxies.txt"),
    "cache_root": str(_PACKAGE_ROOT / "var" / "cache"),
    "info_providers_cache": str(_PACKAGE_ROOT / "var" / "cache" / "info_providers"),
    "artwork_cache": str(_PACKAGE_ROOT / "var" / "artwork"),
    "database": str(_PACKAGE_ROOT / "var" / "warpmc.db"),
    "public_domain_catalogs": str(_PACKAGE_ROOT / "var" / "public_domain_catalogs"),
    "tokens": str(_PACKAGE_ROOT / "var" / "tokens"),
    "user_settings": str(_PACKAGE_ROOT / "var" / "user_settings.json"),
    "library_index": str(_PACKAGE_ROOT / "var" / "library_index.json"),
    "player_temp": str(_PACKAGE_ROOT / "var" / "player" / "temp"),
    "vlc_runtime_root": str(_PACKAGE_ROOT / "Resources" / "vlc"),
    "plugins_root": str(_PACKAGE_ROOT / "var" / "plugins"),
}

_ENV_PATTERN = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}")


def expand_env_in_str(value: str) -> str:
    """Expand ``${VAR}`` tokens within a string."""

    def _repl(match: re.Match[str]) -> str:
        var = match.group(1)
        return os.getenv(var, "")

    return _ENV_PATTERN.sub(_repl, value)


def expand_env(obj: Any) -> Any:
    """Recursively expand environment variables in nested structures."""
    if isinstance(obj, str):
        return expand_env_in_str(obj)
    if isinstance(obj, list):
        return [expand_env(v) for v in obj]
    if isinstance(obj, dict):
        return {k: expand_env(v) for k, v in obj.items()}

    return obj


def read_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def _resolve_candidate(value: str) -> str:
    candidate = Path(value)
    if candidate.is_absolute():
        return str(candidate.resolve())

    for base in _PATH_BASES:
        resolved = (base / candidate).resolve()
        if resolved.exists() or resolved.parent.exists():
            return str(resolved)

    return str((_PACKAGE_ROOT / candidate).resolve())


def load_config_paths() -> Dict[str, str]:
    cfg_path = _CONFIG_DIR / "config_paths.json"
    if not cfg_path.exists():
        return {k: str(Path(v).resolve()) for k, v in _DEFAULT_CONFIG_PATHS.items()}

    raw = read_json(cfg_path)
    merged = {**_DEFAULT_CONFIG_PATHS, **(raw or {})}

    for key, value in list(merged.items()):
        merged[key] = _resolve_candidate(value)

    return merged


PATHS: Dict[str, str] = load_config_paths()


def get_proxy_pool_path() -> str:
    return PATHS["proxy_pool"]


def get_cache_root() -> str:
    return PATHS["cache_root"]


def get_info_providers_cache_dir() -> str:
    return PATHS["info_providers_cache"]


def get_artwork_dir() -> Path:
    path = Path(PATHS["artwork_cache"])
    path.mkdir(parents=True, exist_ok=True)

    return path


def get_artwork_cache_dir() -> str:
    return str(get_artwork_dir())


def get_public_domain_catalog_dir() -> str:
    return PATHS["public_domain_catalogs"]


def get_tokens_dir() -> str:
    return PATHS["tokens"]


def get_player_temp_dir() -> str:
    path = Path(PATHS["player_temp"])
    path.mkdir(parents=True, exist_ok=True)

    return str(path)


def get_vlc_runtime_root() -> str:
    return PATHS["vlc_runtime_root"]


def get_plugins_root() -> str:
    path = Path(PATHS["plugins_root"])
    path.mkdir(parents=True, exist_ok=True)

    return str(path)


def get_user_settings_path() -> Path:
    return Path(PATHS["user_settings"])


def get_library_index_path() -> Path:
    return Path(PATHS["library_index"])


def get_database_path() -> Path:
    path = Path(PATHS["database"])
    path.parent.mkdir(parents=True, exist_ok=True)

    return path


__all__ = [
    "PATHS",
    "expand_env",
    "expand_env_in_str",
    "get_cache_root",
    "get_info_providers_cache_dir",
    "get_library_index_path",
    "get_player_temp_dir",
    "get_plugins_root",
    "get_proxy_pool_path",
    "get_public_domain_catalog_dir",
    "get_tokens_dir",
    "get_user_settings_path",
    "get_vlc_runtime_root",
    "get_artwork_dir",
    "get_artwork_cache_dir",
    "get_database_path",
    "load_config_paths",
    "read_json",
]
