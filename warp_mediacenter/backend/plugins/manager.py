"""Plugin installation and execution.

Isolation model
---------------
Plugins run **in-process**.  That buys speed and simplicity and costs true
sandboxing, so the guards that do exist are the ones that matter most:

* archives are extracted with an explicit path-traversal check;
* each plugin's code is imported under a synthetic, version-qualified root
  package, so two plugins shipping ``main.py`` cannot shadow each other and an
  upgrade cannot serve stale modules;
* every call runs under a wall-clock deadline, so a wedged plugin leaks a logged
  thread instead of hanging playback;
* network and database access are mediated by the host (see ``plugins.host``);
* no exception can escape ``execute`` — a plugin can never crash a request.
"""

from __future__ import annotations

import importlib
import importlib.util
import shutil
import sys
import threading
import zipfile
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeout
from datetime import datetime, timezone
from pathlib import Path
from types import ModuleType
from typing import Any, Callable, Dict, Mapping, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.plugins.contracts.common import (
    ErrorCode,
    err,
    is_ok,
)
from warp_mediacenter.backend.plugins.contracts.lifecycle import LifecycleAction
from warp_mediacenter.backend.plugins.exceptions import PluginError
from warp_mediacenter.backend.plugins.host.context import PluginHost
from warp_mediacenter.backend.plugins.host.db import (
    drop_plugin_tables,
    run_plugin_migrations,
)
from warp_mediacenter.backend.plugins.manifest import PluginManifest
from warp_mediacenter.backend.plugins.registry import PluginRecord, PluginRegistry
from warp_mediacenter.backend.resource_management import (
    ResourceManager,
    get_resource_manager,
)
from warp_mediacenter.config.settings import get_plugins_root

log = get_logger(__name__)

#: Prefix for the synthetic root package each plugin is imported under.
MODULE_NAMESPACE = "warpmc_plugin"

#: Refuse absurd archives outright rather than filling the disk discovering it.
_MAX_ARCHIVE_MEMBERS = 5_000
_MAX_MEMBER_BYTES = 64 * 1024 * 1024
_MAX_TOTAL_BYTES = 256 * 1024 * 1024

#: Default wall-clock deadline for a plugin call.  Scrobbles use a much tighter
#: one — they sit in the playback exit path and must never delay it.
DEFAULT_CALL_TIMEOUT = 20.0
FAST_CALL_TIMEOUT = 5.0


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _ensure_payload(payload: Optional[Mapping[str, Any]]) -> Dict[str, Any]:
    if not payload:
        return {}
    return dict(payload)


def safe_extract(archive: Path, destination: Path) -> None:
    """Extract a zip, refusing anything that would write outside ``destination``.

    ``ZipFile.extractall`` happily follows ``../`` in member names, so an archive
    can overwrite arbitrary files.  Every member is resolved against the target
    root and rejected if it escapes.
    """

    destination.mkdir(parents=True, exist_ok=True)
    root = destination.resolve()

    with zipfile.ZipFile(archive, "r") as zf:
        members = zf.infolist()
        if len(members) > _MAX_ARCHIVE_MEMBERS:
            raise PluginError(
                f"Plugin archive has {len(members)} entries; limit is {_MAX_ARCHIVE_MEMBERS}"
            )

        total = 0
        for member in members:
            name = member.filename

            if name.startswith("/") or name.startswith("\\"):
                raise PluginError(f"Plugin archive contains an absolute path: {name}")
            if ".." in Path(name).parts:
                raise PluginError(f"Plugin archive contains a traversal path: {name}")

            # Symlinks are stored in the high 16 bits of external_attr; a symlink
            # pointing outside the tree defeats the path check above.
            mode = member.external_attr >> 16
            if mode and (mode & 0o170000) == 0o120000:
                raise PluginError(f"Plugin archive contains a symlink: {name}")

            if member.file_size > _MAX_MEMBER_BYTES:
                raise PluginError(f"Plugin archive entry '{name}' is too large")
            total += member.file_size
            if total > _MAX_TOTAL_BYTES:
                raise PluginError("Plugin archive expands beyond the size limit")

            target = (root / name).resolve()
            if target != root and root not in target.parents:
                raise PluginError(f"Plugin archive entry escapes the target: {name}")

        zf.extractall(root)


class PluginManager:
    """Install, load and execute plugins."""

    def __init__(
        self,
        *,
        registry: Optional[PluginRegistry] = None,
        host: Optional[PluginHost] = None,
        plugins_root: Optional[str] = None,
        resource_manager: Optional[ResourceManager] = None,
        default_memory_mb: float = 512.0,
        install_memory_mb: float = 256.0,
        resource_wait_timeout: float = 60.0,
        max_workers: int = 4,
    ) -> None:
        self._plugins_root = Path(plugins_root or get_plugins_root())
        self._plugins_root.mkdir(parents=True, exist_ok=True)
        self._registry = registry or PluginRegistry()
        self._resource_manager = resource_manager or get_resource_manager()
        self._host = host or PluginHost(self._registry, plugins_root=self._plugins_root)
        self._default_memory_mb = max(0.0, default_memory_mb)
        self._install_memory_mb = max(0.0, install_memory_mb)
        self._resource_wait_timeout = max(1.0, resource_wait_timeout)
        self._lock = threading.RLock()
        self._executor = ThreadPoolExecutor(
            max_workers=max_workers, thread_name_prefix="plugin-exec"
        )

    @property
    def registry(self) -> PluginRegistry:
        return self._registry

    @property
    def host(self) -> PluginHost:
        return self._host

    @property
    def plugins_root(self) -> Path:
        return self._plugins_root

    def set_enabled(self, plugin_id: str, enabled: bool) -> PluginRecord:
        """Enable or disable a plugin, notifying it and releasing its services."""

        record = self._registry.require(plugin_id)
        hook = LifecycleAction.ENABLE if enabled else LifecycleAction.DISABLE
        if record.supports(hook):
            self.execute(plugin_id, hook, timeout=FAST_CALL_TIMEOUT)

        # An exclusive category switch turns siblings off; every plugin that
        # changed state should drop its cached services so nothing stale is
        # served after the switch.
        before = {r.plugin_id: r.enabled for r in self._registry.by_category(record.category)}
        updated = self._registry.set_enabled(plugin_id, enabled)
        for sibling in self._registry.by_category(record.category):
            if before.get(sibling.plugin_id) != sibling.enabled:
                self._host.release(sibling.plugin_id)
        return updated

    # ------------------------------------------------------------------
    # Installation
    # ------------------------------------------------------------------

    def install(self, source: str | Path) -> PluginRecord:
        """Install a plugin from a directory or zip archive.

        The new version is staged and swapped into place *before* the old one is
        removed.  The previous implementation uninstalled first, so a failure
        partway through left the user with nothing.
        """

        source_path = Path(source).expanduser()
        if not source_path.exists():
            raise PluginError(f"Plugin source '{source}' not found")
        source_path = source_path.resolve()

        if self._resource_manager and self._install_memory_mb:
            ok_headroom = self._resource_manager.wait_for_headroom(
                self._install_memory_mb,
                context="plugin_install",
                timeout=self._resource_wait_timeout,
            )
            if not ok_headroom:
                raise PluginError("Insufficient resources to install plugin")

        staging_root = self._plugins_root / ".staging"
        staging_root.mkdir(parents=True, exist_ok=True)
        stamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S%f")
        staging_dir = staging_root / f"install-{stamp}"

        try:
            extract_root = staging_dir / "extracted"
            if source_path.is_dir():
                shutil.copytree(source_path, extract_root, symlinks=False)
            elif zipfile.is_zipfile(source_path):
                safe_extract(source_path, extract_root)
            else:
                raise PluginError(
                    "Unsupported plugin package format; expected a directory or zip archive"
                )

            plugin_root = self._discover_plugin_root(extract_root)
            manifest = PluginManifest.load(plugin_root / "plugin.json")

            previous = self._registry.get(manifest.plugin_id)
            install_path = self._plugins_root / manifest.plugin_id / manifest.version
            install_path.parent.mkdir(parents=True, exist_ok=True)

            # Stage beside the destination, then swap.  A crash before the swap
            # leaves the existing install untouched.
            incoming = install_path.parent / f".incoming-{manifest.version}-{stamp}"
            if incoming.exists():
                shutil.rmtree(incoming, ignore_errors=True)
            shutil.copytree(plugin_root, incoming, symlinks=False)

            retired: Optional[Path] = None
            if install_path.exists():
                retired = install_path.parent / f".retired-{manifest.version}-{stamp}"
                install_path.rename(retired)
            incoming.rename(install_path)
            if retired is not None:
                shutil.rmtree(retired, ignore_errors=True)

            # Drop any previously imported modules so the new files are the ones
            # that load, and clear stale versions off disk.
            self._purge_modules(manifest.plugin_id)
            if self._host is not None:
                self._host.release(manifest.plugin_id)
            if previous is not None:
                previous_path = Path(previous.path)
                if previous_path.exists() and previous_path != install_path:
                    shutil.rmtree(previous_path, ignore_errors=True)

            # Bring the plugin's own tables up to date before the record lands,
            # so a failed migration leaves the previous install registered.
            db_version = run_plugin_migrations(
                plugin_id=manifest.plugin_id,
                slug=manifest.slug,
                migrations=manifest.database.migrations,
                current_version=previous.db_version if previous else 0,
                db_path=self._host.db_path,
            )

            record = self._registry.upsert(
                manifest,
                install_path=install_path,
                db_version=db_version,
            )

            # Give the plugin a chance to seed defaults now that its schema exists.
            if manifest.supports(LifecycleAction.INSTALL):
                self.execute(record.plugin_id, LifecycleAction.INSTALL)

            log.info(
                "plugin_installed",
                plugin_id=record.plugin_id,
                category=record.category,
                version=record.version,
                path=str(install_path),
                upgrade=previous is not None,
            )
            return record
        finally:
            shutil.rmtree(staging_dir, ignore_errors=True)

    def uninstall(self, plugin_id: str) -> None:
        """Remove a plugin's files, tables, secrets, modules and registry row."""

        record = self._registry.get(plugin_id)

        # Let the plugin tidy up while its code and tables still exist.
        if record is not None and record.supports(LifecycleAction.UNINSTALL):
            self.execute(plugin_id, LifecycleAction.UNINSTALL, timeout=FAST_CALL_TIMEOUT)

        self._purge_modules(plugin_id)
        if self._host is not None:
            self._host.release(plugin_id)

        if record is not None:
            try:
                drop_plugin_tables(slug=record.slug, db_path=self._host.db_path)
            except Exception as exc:  # noqa: BLE001 - never block an uninstall
                log.warning(
                    "plugin_table_cleanup_failed", plugin_id=plugin_id, error=str(exc)
                )

        plugin_dir = Path(record.path) if record else (self._plugins_root / plugin_id)
        # Remove the whole <plugins_root>/<plugin_id> tree, not just the version.
        if record and plugin_dir.parent.parent == self._plugins_root:
            plugin_dir = plugin_dir.parent
        if plugin_dir.exists() and self._plugins_root in plugin_dir.parents:
            shutil.rmtree(plugin_dir, ignore_errors=True)

        self._registry.remove(plugin_id)
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
    ) -> Dict[str, Any]:
        """Run ``action`` against a plugin and return its response envelope.

        Always returns an envelope — never raises.  A plugin that throws, hangs,
        or returns nonsense becomes a well-formed error the caller can branch on.
        """

        record = self._registry.get(plugin_id)
        if record is None:
            return err(
                ErrorCode.NOT_FOUND, f"Plugin '{plugin_id}' is not installed"
            )

        deadline = timeout if timeout is not None else DEFAULT_CALL_TIMEOUT

        required_memory = record.estimated_memory_mb or self._default_memory_mb
        if self._resource_manager and required_memory:
            has_headroom = self._resource_manager.wait_for_headroom(
                required_memory,
                context=f"plugin:{plugin_id}",
                timeout=deadline,
            )
            if not has_headroom:
                return err(
                    ErrorCode.INTERNAL_ERROR,
                    f"Insufficient resources to execute plugin '{plugin_id}'",
                )

        body = _ensure_payload(payload)

        try:
            future = self._executor.submit(self._invoke, record, action, body)
        except RuntimeError as exc:  # executor already shut down
            return err(ErrorCode.INTERNAL_ERROR, str(exc))

        try:
            result = future.result(timeout=deadline)
        except FuturesTimeout:
            # The worker thread cannot be killed from here.  Abandon it, keep the
            # request moving, and make the leak loud enough to notice.
            future.cancel()
            log.error(
                "plugin_call_timeout",
                plugin_id=plugin_id,
                action=action,
                timeout=deadline,
            )
            return err(
                ErrorCode.INTERNAL_ERROR,
                f"Plugin '{plugin_id}' timed out after {deadline:.0f}s",
            )
        except PluginError as exc:
            log.warning("plugin_call_failed", plugin_id=plugin_id, action=action, error=str(exc))
            return err(ErrorCode.INTERNAL_ERROR, str(exc))
        except Exception as exc:  # noqa: BLE001 - a plugin must not break the caller
            log.exception(
                "plugin_call_crashed", plugin_id=plugin_id, action=action, error=str(exc)
            )
            return err(ErrorCode.INTERNAL_ERROR, f"{type(exc).__name__}: {exc}")

        return self._normalize_response(plugin_id, action, result)

    def _normalize_response(
        self, plugin_id: str, action: str, result: Any
    ) -> Dict[str, Any]:
        """Coerce whatever the plugin returned into a valid envelope."""

        if isinstance(result, Mapping) and "ok" in result:
            if is_ok(result):
                data = result.get("data")
                return {
                    "ok": True,
                    "data": dict(data) if isinstance(data, Mapping) else {},
                }
            error = result.get("error")
            if isinstance(error, Mapping) and error.get("code"):
                return {"ok": False, "error": dict(error)}
            return err(ErrorCode.INTERNAL_ERROR, "Plugin returned a malformed error")

        if result is None:
            return {"ok": True, "data": {}}

        if isinstance(result, Mapping):
            # Tolerate a bare data dict — plugins forget the envelope constantly
            # and failing the call over it helps nobody.
            return {"ok": True, "data": dict(result)}

        log.warning(
            "plugin_response_invalid",
            plugin_id=plugin_id,
            action=action,
            result_type=type(result).__name__,
        )
        return err(
            ErrorCode.INTERNAL_ERROR,
            f"Plugin returned {type(result).__name__}; expected an object",
        )

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    def _discover_plugin_root(self, extract_root: Path) -> Path:
        manifest = extract_root / "plugin.json"
        if manifest.exists():
            return extract_root

        for candidate in sorted(extract_root.rglob("plugin.json")):
            parent = candidate.parent
            if any(
                part.startswith("__") or part.startswith(".")
                for part in parent.relative_to(extract_root).parts
            ):
                continue
            return parent

        raise PluginError("Plugin manifest 'plugin.json' not found in package")

    def _root_module_name(self, record: PluginRecord) -> str:
        """Synthetic package name a plugin's code is imported under.

        Version-qualified so upgrading a plugin cannot serve modules cached from
        the previous build, and plugin-qualified so two plugins shipping the same
        top-level module name stay separate.
        """

        version = record.version.replace(".", "_").replace("-", "_")
        return f"{MODULE_NAMESPACE}_{record.slug}_{version}"

    def _purge_modules(self, plugin_id: str) -> None:
        """Drop every imported module belonging to a plugin."""

        from warp_mediacenter.backend.plugins.manifest import plugin_slug

        prefix = f"{MODULE_NAMESPACE}_{plugin_slug(plugin_id)}_"
        with self._lock:
            for name in [n for n in sys.modules if n.startswith(prefix)]:
                sys.modules.pop(name, None)
            record = self._registry.get(plugin_id)
            if record is not None:
                record.module = None

    def _load_module(self, record: PluginRecord) -> ModuleType:
        """Import the plugin's entrypoint module under its synthetic root.

        The plugin directory is registered as the ``__path__`` of a synthetic
        package rather than being pushed onto ``sys.path``.  Nothing leaks into
        the global import namespace, so plugin code must use relative imports
        (``from . import client``) or fully-qualified ones within its own package.
        """

        cached = record.module
        if isinstance(cached, ModuleType):
            return cached

        plugin_path = Path(record.path)
        if not plugin_path.exists():
            raise PluginError(
                f"Plugin path '{plugin_path}' does not exist; try reinstalling"
            )

        root_name = self._root_module_name(record)
        module_name = record.manifest.module

        with self._lock:
            root = sys.modules.get(root_name)
            if root is None:
                spec = importlib.util.spec_from_loader(root_name, loader=None)
                if spec is None:  # pragma: no cover - defensive
                    raise PluginError(f"Could not create module namespace for {root_name}")
                root = importlib.util.module_from_spec(spec)
                root.__path__ = [str(plugin_path)]  # type: ignore[attr-defined]
                sys.modules[root_name] = root

            try:
                importlib.invalidate_caches()
                module = importlib.import_module(f"{root_name}.{module_name}")
            except ModuleNotFoundError as exc:
                raise PluginError(
                    f"Could not import '{module_name}' from plugin "
                    f"'{record.plugin_id}': {exc}. Plugin code must use relative "
                    "imports for its own modules."
                ) from exc
            except Exception as exc:  # noqa: BLE001
                raise PluginError(
                    f"Importing '{module_name}' from plugin '{record.plugin_id}' "
                    f"failed: {exc}"
                ) from exc

            record.module = module
            return module

    def _invoke(
        self, record: PluginRecord, action: str, payload: Dict[str, Any]
    ) -> Any:
        module = self._load_module(record)
        func_name = record.manifest.callable_name
        func = getattr(module, func_name, None)
        if not callable(func):
            raise PluginError(
                f"Entrypoint '{record.entrypoint}' could not be resolved in plugin "
                f"'{record.plugin_id}'"
            )

        return func(
            action=action, payload=payload, context=self._host.context_for(record)
        )

    def shutdown(self) -> None:
        self._executor.shutdown(wait=False, cancel_futures=True)
        self._host.close()


__all__ = [
    "DEFAULT_CALL_TIMEOUT",
    "FAST_CALL_TIMEOUT",
    "MODULE_NAMESPACE",
    "PluginManager",
    "safe_extract",
]
