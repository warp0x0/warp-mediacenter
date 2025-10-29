from __future__ import annotations

import importlib
from typing import TYPE_CHECKING, Any

__all__ = [
    "PATHS",
    "INFORMATION_PROVIDER_SETTINGS",
    "PROXY_SETTINGS",
    "InstalledPlugin",
    "LibraryMediaKind",
    "LibraryPaths",
    "ResourceProfile",
    "Settings",
    "core",
    "library",
    "paths",
    "plugins",
    "providers",
    "get_api_key_tmdb",
    "get_base_url",
    "get_cache_root",
    "get_content_list_config",
    "get_default_headers",
    "get_info_providers_cache_dir",
    "get_database_path",
    "get_installed_plugins",
    "get_library_index_path",
    "get_player_temp_dir",
    "get_pipeline_config",
    "get_plugins_root",
    "get_proxy_pool_path",
    "get_provider_endpoints",
    "get_public_domain_catalog_dir",
    "get_public_domain_source_config",
    "get_public_domain_sources",
    "get_rate_limits",
    "get_service_config",
    "get_settings",
    "get_tmdb_image_config",
    "get_tokens_dir",
    "get_trakt_keys",
    "get_user_settings_path",
    "get_vlc_runtime_root",
    "iter_pipeline_public_domain_sources",
    "list_content_lists",
    "list_provider_configs",
    "load_information_provider_settings",
    "load_library_index",
    "load_proxy_settings",
    "register_installed_plugin",
    "remove_installed_plugin",
    "save_library_index",
    "update_library_path",
]

_MODULE_EXPORTS = {
    "core": {
        "ResourceProfile",
        "Settings",
        "get_installed_plugins",
        "get_settings",
        "register_installed_plugin",
        "remove_installed_plugin",
        "update_library_path",
    },
    "library": {
        "LibraryMediaKind",
        "LibraryPaths",
        "load_library_index",
        "save_library_index",
    },
    "paths": {
        "PATHS",
        "get_cache_root",
        "get_info_providers_cache_dir",
        "get_database_path",
        "get_library_index_path",
        "get_player_temp_dir",
        "get_plugins_root",
        "get_proxy_pool_path",
        "get_public_domain_catalog_dir",
        "get_tokens_dir",
        "get_user_settings_path",
        "get_vlc_runtime_root",
    },
    "plugins": {
        "InstalledPlugin",
    },
    "providers": {
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
    },
}

_SUBMODULE_NAMES = {"core", "library", "paths", "plugins", "providers"}

if TYPE_CHECKING:  # pragma: no cover - only for static analysis
    from . import core, library, paths, plugins, providers
    from .core import ResourceProfile, Settings, get_installed_plugins, get_settings, register_installed_plugin, remove_installed_plugin, update_library_path
    from .library import LibraryMediaKind, LibraryPaths, load_library_index, save_library_index
    from .paths import (
        PATHS,
        get_cache_root,
        get_info_providers_cache_dir,
        get_library_index_path,
        get_player_temp_dir,
        get_plugins_root,
        get_proxy_pool_path,
        get_public_domain_catalog_dir,
        get_tokens_dir,
        get_user_settings_path,
        get_vlc_runtime_root,
    )
    from .plugins import InstalledPlugin
    from .providers import (
        INFORMATION_PROVIDER_SETTINGS,
        PROXY_SETTINGS,
        get_api_key_tmdb,
        get_base_url,
        get_content_list_config,
        get_default_headers,
        get_pipeline_config,
        get_provider_endpoints,
        get_public_domain_source_config,
        get_public_domain_sources,
        get_rate_limits,
        get_service_config,
        get_tmdb_image_config,
        get_trakt_keys,
        iter_pipeline_public_domain_sources,
        list_content_lists,
        list_provider_configs,
        load_information_provider_settings,
        load_proxy_settings,
    )


def __getattr__(name: str) -> Any:
    if name in _SUBMODULE_NAMES:
        module = importlib.import_module(f"{__name__}.{name}")
        globals()[name] = module
        return module

    for module_name, symbols in _MODULE_EXPORTS.items():
        if name in symbols:
            module = importlib.import_module(f"{__name__}.{module_name}")
            value = getattr(module, name)
            globals()[name] = value
            return value

    raise AttributeError(f"module '{__name__}' has no attribute '{name}'")


def __dir__() -> list[str]:
    exported = set(__all__)
    exported.update(_SUBMODULE_NAMES)
    for symbols in _MODULE_EXPORTS.values():
        exported.update(symbols)
    exported.update(globals().keys())
    return sorted(exported)
