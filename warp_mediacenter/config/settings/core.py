from __future__ import annotations

import os
import threading
from datetime import datetime
from typing import Any, Dict, Optional

from dataclasses import dataclass, field

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.resource_management import (
    ResourceProfile,
    get_resource_manager,
)

from .library import (
    LibraryMediaKind,
    LibraryPaths,
    coerce_path,
    load_user_settings,
    write_user_settings,
)
from .paths import get_library_index_path, get_user_settings_path
from .plugins import InstalledPlugin, load_installed_plugins, serialize_plugins

log = get_logger(__name__)

_SETTINGS_LOCK = threading.Lock()
_SETTINGS_SINGLETON: Optional["Settings"] = None


@dataclass
class Settings:
    app_name: str
    env: str
    log_level: str
    task_workers: int
    library_paths: LibraryPaths
    user_settings_path: os.PathLike[str]
    library_index_path: os.PathLike[str]
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


def _build_settings() -> Settings:
    user_cfg = load_user_settings()
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
    movies_path = coerce_path(libs_cfg.get("movie") or libs_cfg.get("movies"))
    shows_path = coerce_path(
        libs_cfg.get("show")
        or libs_cfg.get("shows")
        or libs_cfg.get("tv")
        or libs_cfg.get("tv_show")
        or libs_cfg.get("tv_shows")
    )
    library_paths = LibraryPaths(movies=movies_path, shows=shows_path)
    plugins = load_installed_plugins(user_cfg)

    return Settings(
        app_name=app_name,
        env=env,
        log_level=log_level,
        task_workers=task_workers,
        library_paths=library_paths,
        user_settings_path=get_user_settings_path(),
        library_index_path=get_library_index_path(),
        resource_profile=profile,
        plugins=plugins,
    )


def get_settings(*, reload: bool = False) -> Settings:
    global _SETTINGS_SINGLETON
    with _SETTINGS_LOCK:
        if _SETTINGS_SINGLETON is None or reload:
            _SETTINGS_SINGLETON = _build_settings()

        return _SETTINGS_SINGLETON


def update_library_path(kind: LibraryMediaKind, path: str) -> Settings:
    current = get_settings()
    current.library_paths.set(kind, path)

    payload = load_user_settings()
    payload["library_paths"] = current.library_paths.as_dict()
    payload["plugins"] = serialize_plugins(current.plugins)
    payload["app_name"] = current.app_name
    payload["env"] = current.env
    payload["log_level"] = current.log_level
    payload["task_workers"] = current.task_workers
    payload["updated_at"] = datetime.utcnow().isoformat() + "Z"
    write_user_settings(payload)

    return get_settings(reload=True)


def get_installed_plugins() -> Dict[str, InstalledPlugin]:
    return dict(get_settings().plugins)


def register_installed_plugin(plugin: InstalledPlugin) -> Settings:
    current = get_settings()
    plugins = dict(current.plugins)
    plugins[plugin.plugin_id] = plugin

    payload = load_user_settings()
    payload["library_paths"] = current.library_paths.as_dict()
    payload["plugins"] = serialize_plugins(plugins)
    payload["app_name"] = current.app_name
    payload["env"] = current.env
    payload["log_level"] = current.log_level
    payload["task_workers"] = current.task_workers
    payload["updated_at"] = datetime.utcnow().isoformat() + "Z"
    write_user_settings(payload)

    return get_settings(reload=True)


def remove_installed_plugin(plugin_id: str) -> Settings:
    current = get_settings()
    if plugin_id not in current.plugins:
        return current

    plugins = dict(current.plugins)
    plugins.pop(plugin_id, None)

    payload = load_user_settings()
    payload["library_paths"] = current.library_paths.as_dict()
    payload["plugins"] = serialize_plugins(plugins)
    payload["app_name"] = current.app_name
    payload["env"] = current.env
    payload["log_level"] = current.log_level
    payload["task_workers"] = current.task_workers
    payload["updated_at"] = datetime.utcnow().isoformat() + "Z"
    write_user_settings(payload)

    return get_settings(reload=True)


__all__ = [
    "InstalledPlugin",
    "LibraryMediaKind",
    "LibraryPaths",
    "ResourceProfile",
    "Settings",
    "get_installed_plugins",
    "get_settings",
    "register_installed_plugin",
    "remove_installed_plugin",
    "update_library_path",
]
