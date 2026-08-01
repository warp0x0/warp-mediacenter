"""Assembles the service bundle a plugin receives on every call.

The previous implementation handed plugins the live ``ResourceManager`` singleton
and the entire settings dictionary — library paths, the plugin registry, the
resource profile.  That is far more than any plugin needs and gives a careless
one plenty of ways to disturb the host.

What a plugin gets now is exactly six things, all of them scoped to that plugin:
an HTTP client restricted to its declared hosts, its own database namespace, its
own secrets, its own cache, a logger, and a clock.  Nothing else — no paths, no
host objects, no way to reach another plugin.

Instances are cached per plugin so a session, connection pool and authenticator
survive between calls instead of being rebuilt on every scrobble.
"""

from __future__ import annotations

import threading
import time
from pathlib import Path
from typing import Any, Dict, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.plugins.host.cache import PluginCache
from warp_mediacenter.backend.plugins.host.db import PluginDatabase
from warp_mediacenter.backend.plugins.host.http import PluginHttpClient
from warp_mediacenter.backend.plugins.host.logging import PluginLogger
from warp_mediacenter.backend.plugins.host.oauth import DeviceCodeAuthenticator
from warp_mediacenter.backend.plugins.host.secrets import PluginSecrets
from warp_mediacenter.backend.plugins.registry import PluginRecord, PluginRegistry
from warp_mediacenter.config.settings import get_plugins_root

log = get_logger(__name__)

#: Host contract version handed to plugins, so a plugin can branch on it.
PLUGIN_CONTEXT_API_VERSION = 1


class _PluginServices:
    """Everything the host holds on behalf of one plugin."""

    def __init__(
        self,
        record: PluginRecord,
        *,
        registry: PluginRegistry,
        plugins_root: Path,
        db_path: Optional[Path],
    ) -> None:
        self.plugin_id = record.plugin_id
        self.version = record.version

        self.log = PluginLogger(record.plugin_id)
        self.cache = PluginCache()
        self.secrets = PluginSecrets(registry, record.plugin_id)
        self.database = PluginDatabase(
            plugin_id=record.plugin_id, slug=record.slug, db_path=db_path
        )

        self.data_dir = plugins_root / record.plugin_id / "data"
        self.data_dir.mkdir(parents=True, exist_ok=True)

        manifest = record.manifest
        self.authenticator: Optional[DeviceCodeAuthenticator] = None
        if manifest.auth.is_device_code:
            self.authenticator = DeviceCodeAuthenticator(
                plugin_id=record.plugin_id,
                auth=manifest.auth,
                secrets=self.secrets,
                http_factory=self._unauthenticated_client,
            )

        self.http = PluginHttpClient(
            plugin_id=record.plugin_id,
            allowed_hosts=manifest.network.allowed_hosts,
            base_url=manifest.auth.base_url,
            rate_limit_per_minute=manifest.network.rate_limit_per_minute,
            respect_retry_after=manifest.network.respect_retry_after,
            auth_headers=(
                self.authenticator.auth_headers if self.authenticator else None
            ),
            on_unauthorized=(
                self.authenticator.handle_unauthorized if self.authenticator else None
            ),
        )
        self._manifest = manifest

    def _unauthenticated_client(self) -> PluginHttpClient:
        """Client for the token endpoints themselves.

        Deliberately separate: minting or refreshing a token must not carry the
        Authorization header we are in the middle of replacing, and must not
        recurse into the 401 refresh hook.
        """

        return PluginHttpClient(
            plugin_id=self.plugin_id,
            allowed_hosts=self._manifest.network.allowed_hosts,
            base_url=self._manifest.auth.base_url,
            rate_limit_per_minute=self._manifest.network.rate_limit_per_minute,
            respect_retry_after=self._manifest.network.respect_retry_after,
        )

    def close(self) -> None:
        try:
            self.http.close()
        finally:
            self.database.close()
            self.cache.clear()


class PluginHost:
    """Owns the per-plugin service instances and builds call contexts."""

    def __init__(
        self,
        registry: PluginRegistry,
        *,
        plugins_root: Optional[Path] = None,
        db_path: Optional[Path] = None,
    ) -> None:
        self._registry = registry
        self._plugins_root = Path(plugins_root or get_plugins_root())
        self._db_path = db_path
        self._lock = threading.RLock()
        self._services: Dict[str, _PluginServices] = {}

    @property
    def db_path(self) -> Optional[Path]:
        """Database every plugin service is bound to (None means the app default)."""

        return self._db_path

    @property
    def plugins_root(self) -> Path:
        return self._plugins_root

    def _services_for(self, record: PluginRecord) -> _PluginServices:
        with self._lock:
            existing = self._services.get(record.plugin_id)
            # Rebuild after an upgrade — the manifest may declare different hosts,
            # auth endpoints or tables.
            if existing is not None and existing.version == record.version:
                return existing
            if existing is not None:
                existing.close()
            services = _PluginServices(
                record,
                registry=self._registry,
                plugins_root=self._plugins_root,
                db_path=self._db_path,
            )
            self._services[record.plugin_id] = services
            return services

    # -- public API -----------------------------------------------------

    def context_for(self, record: PluginRecord) -> Dict[str, Any]:
        services = self._services_for(record)
        return {
            "api_version": PLUGIN_CONTEXT_API_VERSION,
            "plugin": {
                "id": record.plugin_id,
                "name": record.name,
                "version": record.version,
                "category": record.category,
                "data_dir": str(services.data_dir),
                "table_prefix": services.database.table_prefix,
            },
            "http": services.http,
            "db": services.database,
            "secrets": services.secrets,
            "cache": services.cache,
            "log": services.log,
            "now": time.time,
        }

    def secrets_for(self, record: PluginRecord) -> PluginSecrets:
        return self._services_for(record).secrets

    def cache_for(self, record: PluginRecord) -> PluginCache:
        return self._services_for(record).cache

    def database_for(self, record: PluginRecord) -> PluginDatabase:
        return self._services_for(record).database

    def authenticator_for(
        self, record: PluginRecord
    ) -> Optional[DeviceCodeAuthenticator]:
        return self._services_for(record).authenticator

    def release(self, plugin_id: str) -> None:
        """Drop a plugin's services — on uninstall, disable or upgrade."""

        with self._lock:
            services = self._services.pop(plugin_id, None)
        if services is not None:
            services.close()
            log.debug("plugin_services_released", plugin_id=plugin_id)

    def close(self) -> None:
        with self._lock:
            services = list(self._services.values())
            self._services.clear()
        for entry in services:
            entry.close()


__all__ = ["PLUGIN_CONTEXT_API_VERSION", "PluginHost"]
