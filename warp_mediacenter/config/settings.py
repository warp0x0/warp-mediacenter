from typing import Any, Dict, Optional
from __future__ import annotations
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

# Eager, cached singletons (safe for small JSONs)
try:
    INFORMATION_PROVIDER_SETTINGS: Dict[str, Any] = load_information_provider_settings()
except Exception as e:
    # Keep import from crashing; consumer modules can handle missing configs at runtime
    INFORMATION_PROVIDER_SETTINGS = {}
    # Optional: print or log here if you have a logger
    # print(f"[settings] Failed to load information provider settings: {e}")

try:
    PROXY_SETTINGS: Dict[str, Any] = load_proxy_settings()
except Exception as e:
    PROXY_SETTINGS = {}
    # Optional: print or log here if you have a logger
    # print(f"[settings] Failed to load proxy settings: {e}")

def get_service_config(service: str) -> Optional[Dict[str, Any]]:
    """
    Convenience accessor for 'tmdb', 'trakt', 'real_debrid', etc.
    Returns None if settings failed to load or service not found.
    """
    if not INFORMATION_PROVIDER_SETTINGS:
        return None
    
    return INFORMATION_PROVIDER_SETTINGS.get(service)

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
    
    return cfg.get("base_url") if cfg else None

def get_api_key_tmdb() -> Optional[str]:
    cfg = get_service_config("tmdb")
    
    return cfg.get("api_key") if cfg else None

def get_trakt_keys() -> Dict[str, Optional[str]]:
    cfg = get_service_config("trakt") or {}
    
    return {
        "client_id": cfg.get("client_id"),
        "client_secret": cfg.get("client_secret"),
    }

def get_realdebrid_keys() -> Dict[str, Optional[str]]:
    cfg = get_service_config("real_debrid") or {}
    
    return {
        "temp_client_id": cfg.get("temp_client_id"),
        "client_id": cfg.get("client_id"),
        "client_secret": cfg.get("client_secret"),
    }
