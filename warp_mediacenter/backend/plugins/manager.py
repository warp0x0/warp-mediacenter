"""Plugin installation and execution manager."""

from __future__ import annotations

import importlib
import shutil
import sys
import threading
import zipfile
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import Any, Dict, Mapping, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.resource_management import ResourceManager, get_resource_manager
from warp_mediacenter.config import settings as settings_module
from warp_mediacenter.config.settings import (
    InstalledPlugin,
    get_installed_plugins,
    get_plugins_root,
    register_installed_plugin,
    remove_installed_plugin,
)

from .exceptions import PluginError
from .manifest import PluginManifest

log = get_logger(__name__)


@contextmanager
def _temp_sys_path(path: Path):
    """Temporarily prepend a path to ``sys.path`` during plugin execution."""

    path_str = str(path)
    already_present = path_str in sys.path
    if not already_present:
        sys.path.insert(0, path_str)
    try:
        yield
    finally:
        if not already_present and path_str in sys.path:
            sys.path.remove(path_str)


def _ensure_payload(payload: Optional[Mapping[str, Any]]) -> Dict[str, Any]:
    if not payload:
        return {}
    if isinstance(payload, dict):
        return dict(payload)
    return {k: payload[k] for k in payload}


class PluginManager:
    """Manage plugin lifecycle and execution with resource awareness."""

    def __init__(
        self,
        *,
        plugins_root: Optional[str] = None,
        resource_manager: Optional[ResourceManager] = None,
        default_memory_mb: float = 512.0,
        install_memory_mb: float = 256.0,
        resource_wait_timeout: float = 60.0,
    ) -> None:
        self._plugins_root = Path(plugins_root or get_plugins_root())
        self._plugins_root.mkdir(parents=True, exist_ok=True)
        self._resource_manager = resource_manager or get_resource_manager()
        self._default_memory_mb = max(0.0, default_memory_mb)
        self._install_memory_mb = max(0.0, install_memory_mb)
        self._resource_wait_timeout = max(1.0, resource_wait_timeout)
        self._lock = threading.RLock()
        self._registry: Dict[str, InstalledPlugin] = get_installed_plugins()

    # ------------------------------------------------------------------
    # Registry helpers
    # ------------------------------------------------------------------
    def refresh(self) -> Dict[str, InstalledPlugin]:
        """Reload plugin registry from settings."""

        with self._lock:
            self._registry = get_installed_plugins()
            return dict(self._registry)

    def list_plugins(self) -> Dict[str, InstalledPlugin]:
        with self._lock:
            return dict(self._registry)

    def get_plugin(self, plugin_id: str) -> Optional[InstalledPlugin]:
        with self._lock:
            return self._registry.get(plugin_id)

    # ------------------------------------------------------------------
    # Installation
    # ------------------------------------------------------------------
    def install(self, source: str | Path) -> InstalledPlugin:
        """Install a plugin from a directory or zip file."""

        source_path = Path(source).expanduser()
        if not source_path.exists():
            raise PluginError(f"Plugin source '{source}' not found")
        source_path = source_path.resolve()

        if self._resource_manager and self._install_memory_mb:
            ok = self._resource_manager.wait_for_headroom(
                self._install_memory_mb,
                context="plugin_install",
                timeout=self._resource_wait_timeout,
            )
            if not ok:
                raise PluginError("Insufficient resources to install plugin")

        with TemporaryDirectory() as tmpdir:
            staging_dir = Path(tmpdir)
            extract_root = staging_dir / "extracted"
            if source_path.is_dir():
                shutil.copytree(source_path, extract_root)
            elif zipfile.is_zipfile(source_path):
                with zipfile.ZipFile(source_path, "r") as zf:
                    zf.extractall(extract_root)
            else:
                raise PluginError("Unsupported plugin package format; expected directory or zip archive")

            plugin_root = self._discover_plugin_root(extract_root)
            manifest_path = plugin_root / "plugin.json"
            manifest = PluginManifest.load(manifest_path)

            # Remove existing installs of this plugin
            self.uninstall(manifest.plugin_id)

            install_path = self._plugins_root / manifest.plugin_id / manifest.version
            if install_path.exists():
                shutil.rmtree(install_path)
            install_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copytree(plugin_root, install_path)

            installed_at = datetime.utcnow().isoformat() + "Z"
            record = manifest.to_installed_plugin(install_path, installed_at=installed_at)
            register_installed_plugin(record)

            with self._lock:
                self._registry = get_installed_plugins()

            log.info(
                "plugin_installed",
                plugin_id=record.plugin_id,
                version=record.version,
                path=str(install_path),
            )

            return record

    def uninstall(self, plugin_id: str) -> None:
        """Uninstall the specified plugin if present."""

        with self._lock:
            record = self._registry.get(plugin_id)

        plugin_dir = None
        if record:
            plugin_dir = Path(record.path)
        else:
            plugin_dir = self._plugins_root / plugin_id

        if plugin_dir and plugin_dir.exists():
            shutil.rmtree(plugin_dir, ignore_errors=True)
            parent = plugin_dir.parent
            if parent.exists() and parent != self._plugins_root:
                try:
                    next(parent.iterdir())
                except StopIteration:
                    try:
                        parent.rmdir()
                    except OSError:
                        pass
                except OSError:
                    pass

        remove_installed_plugin(plugin_id)
        with self._lock:
            self._registry = get_installed_plugins()

        log.info("plugin_uninstalled", plugin_id=plugin_id)

    # ------------------------------------------------------------------
    # Execution
    # ------------------------------------------------------------------
    def execute(
        self,
        plugin_id: str,
        action: str,
        payload: Optional[Mapping[str, Any]] = None,
        *,
        timeout: Optional[float] = None,
    ) -> Any:
        """Execute an action against an installed plugin."""

        record = self.get_plugin(plugin_id)
        if not record:
            raise PluginError(f"Plugin '{plugin_id}' is not installed")

        required_memory = record.estimated_memory_mb or self._default_memory_mb
        if self._resource_manager and required_memory:
            ok = self._resource_manager.wait_for_headroom(
                required_memory,
                context=f"plugin:{plugin_id}",
                timeout=timeout or self._resource_wait_timeout,
            )
            if not ok:
                raise PluginError(
                    f"Insufficient resources to execute plugin '{plugin_id}'"
                )

        try:
            return self._invoke_plugin(record, action, _ensure_payload(payload))
        except PluginError:
            raise
        except Exception as exc:  # noqa: BLE001
            raise PluginError(
                f"Plugin '{plugin_id}' execution failed: {exc}"
            ) from exc

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _discover_plugin_root(self, extract_root: Path) -> Path:
        manifest = extract_root / "plugin.json"
        if manifest.exists():
            return extract_root

        for candidate in extract_root.rglob("plugin.json"):
            parent = candidate.parent
            if any(part.startswith("__") or part.startswith(".") for part in parent.parts):
                continue
            return parent

        raise PluginError("Plugin manifest 'plugin.json' not found in package")

    def _invoke_plugin(self, record: InstalledPlugin, action: str, payload: Dict[str, Any]) -> Any:
        if ":" not in record.entrypoint:
            raise PluginError(
                "Plugin entrypoint must be in 'module:function' format"
            )
        module_name, func_name = record.entrypoint.split(":", 1)
        plugin_path = Path(record.path)
        if not plugin_path.exists():
            raise PluginError(
                f"Plugin path '{plugin_path}' does not exist; try reinstalling"
            )

        with _temp_sys_path(plugin_path):
            importlib.invalidate_caches()
            module = importlib.import_module(module_name)
            func = getattr(module, func_name, None)
            if func is None:
                raise PluginError(
                    f"Entrypoint '{record.entrypoint}' could not be resolved"
                )

            context = {
                "plugin": record.as_dict(),
                "plugins_root": str(self._plugins_root),
                "resource_manager": self._resource_manager,
                "settings": settings_module.get_settings().as_dict(),
            }

            return func(action=action, payload=payload, context=context)
