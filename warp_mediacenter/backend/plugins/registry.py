"""Plugin registry — installed plugin state, backed by SQLite.

State lives in the ``plugin_state`` table rather than ``user_settings.json``
because that file is rewritten wholesale and non-atomically by several unrelated
writers.  Plugin enable/disable is a user-facing toggle, so a lost write there
would be a real bug, not a theoretical one.

"Exactly one enabled plugin per exclusive category" is enforced by a partial
unique index in the schema (see ``_apply_v7``), not by the code here.  This class
still clears siblings inside the same transaction so the common path never trips
the index, but the database is what guarantees the invariant under concurrency.
"""

from __future__ import annotations

import json
import sqlite3
import threading
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Mapping, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.persistence.sqlite import connection as db_connection
from warp_mediacenter.backend.plugins.contracts.common import is_exclusive_category
from warp_mediacenter.backend.plugins.exceptions import PluginError
from warp_mediacenter.backend.plugins.manifest import PluginManifest, plugin_slug

log = get_logger(__name__)


def _utcnow() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


@dataclass
class PluginRecord:
    """An installed plugin as persisted in ``plugin_state``."""

    plugin_id: str
    category: str
    name: str
    version: str
    path: str
    manifest: PluginManifest
    enabled: bool = False
    exclusive: bool = False
    db_version: int = 0
    installed_at: str = ""
    updated_at: str = ""
    #: Populated by the manager after a successful import; not persisted.
    module: Any = field(default=None, repr=False, compare=False)

    @property
    def slug(self) -> str:
        return plugin_slug(self.plugin_id)

    @property
    def entrypoint(self) -> str:
        return self.manifest.entrypoint

    @property
    def estimated_memory_mb(self) -> Optional[float]:
        return self.manifest.estimated_memory_mb

    def supports(self, capability: str) -> bool:
        return self.manifest.supports(capability)

    def as_dict(self, *, include_manifest: bool = False) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "plugin_id": self.plugin_id,
            "category": self.category,
            "name": self.name,
            "version": self.version,
            "path": self.path,
            "enabled": self.enabled,
            "exclusive": self.exclusive,
            "db_version": self.db_version,
            "installed_at": self.installed_at,
            "updated_at": self.updated_at,
            "capabilities": list(self.manifest.capabilities),
            "has_settings": self.manifest.has_settings_ui,
            "auth_kind": self.manifest.auth.kind,
        }
        if self.manifest.description:
            payload["description"] = self.manifest.description
        if self.manifest.icon:
            payload["icon"] = self.manifest.icon
        if self.manifest.author:
            payload["author"] = self.manifest.author
        if self.manifest.homepage:
            payload["homepage"] = self.manifest.homepage
        if include_manifest:
            payload["manifest"] = self.manifest.as_dict()
        return payload


def _row_to_record(row: sqlite3.Row) -> Optional[PluginRecord]:
    try:
        manifest = PluginManifest.from_dict(json.loads(row["manifest_json"]))
    except Exception as exc:  # noqa: BLE001 - a bad row must not kill the registry
        log.warning(
            "plugin_record_unreadable", plugin_id=row["plugin_id"], error=str(exc)
        )
        return None
    return PluginRecord(
        plugin_id=row["plugin_id"],
        category=row["category"],
        name=row["name"],
        version=row["version"],
        path=row["path"],
        manifest=manifest,
        enabled=bool(row["enabled"]),
        exclusive=bool(row["exclusive"]),
        db_version=int(row["db_version"] or 0),
        installed_at=row["installed_at"],
        updated_at=row["updated_at"],
    )


class PluginRegistry:
    """Read/write access to installed-plugin state.

    Reads are served from an in-memory snapshot guarded by a version counter, so
    resolving "which tracker is active" on every scrobble costs a dict lookup
    rather than a query.  Any write bumps the counter and reloads.
    """

    def __init__(self, *, db_path: Optional[Path] = None) -> None:
        self._db_path = db_path
        self._lock = threading.RLock()
        self._records: Dict[str, PluginRecord] = {}
        self._version = 0
        self.reload()

    # -- snapshot -------------------------------------------------------

    @property
    def version(self) -> int:
        """Bumped on every mutation; use it to invalidate derived caches."""

        with self._lock:
            return self._version

    def reload(self) -> Dict[str, PluginRecord]:
        with db_connection(self._db_path) as conn:
            rows = conn.execute(
                "SELECT * FROM plugin_state ORDER BY category, name"
            ).fetchall()

        records: Dict[str, PluginRecord] = {}
        for row in rows:
            record = _row_to_record(row)
            if record is not None:
                records[record.plugin_id] = record

        with self._lock:
            # Preserve already-imported module objects across a reload so a
            # settings write does not force every plugin to be re-imported.
            for plugin_id, record in records.items():
                previous = self._records.get(plugin_id)
                if previous is not None and previous.version == record.version:
                    record.module = previous.module
            self._records = records
            self._version += 1
            return dict(self._records)

    def all(self) -> List[PluginRecord]:
        with self._lock:
            return list(self._records.values())

    def get(self, plugin_id: str) -> Optional[PluginRecord]:
        with self._lock:
            return self._records.get(plugin_id)

    def require(self, plugin_id: str) -> PluginRecord:
        record = self.get(plugin_id)
        if record is None:
            raise PluginError(f"Plugin '{plugin_id}' is not installed")
        return record

    def by_category(self, category: str) -> List[PluginRecord]:
        with self._lock:
            return [r for r in self._records.values() if r.category == category]

    def active_for_category(self, category: str) -> Optional[PluginRecord]:
        with self._lock:
            for record in self._records.values():
                if record.category == category and record.enabled:
                    return record
            return None

    def enabled(self) -> List[PluginRecord]:
        with self._lock:
            return [r for r in self._records.values() if r.enabled]

    # -- mutation -------------------------------------------------------

    def upsert(
        self,
        manifest: PluginManifest,
        *,
        install_path: Path,
        db_version: int = 0,
        keep_enabled: bool = True,
    ) -> PluginRecord:
        """Insert or update a plugin's registry row.

        ``keep_enabled`` preserves the enabled flag across a version upgrade —
        reinstalling a newer build of the active tracker should not silently turn
        tracking off.
        """

        now = _utcnow()
        exclusive = is_exclusive_category(manifest.category)
        manifest_json = json.dumps(manifest.as_dict(), separators=(",", ":"))

        with db_connection(self._db_path) as conn:
            existing = conn.execute(
                "SELECT enabled, installed_at FROM plugin_state WHERE plugin_id = ?",
                (manifest.plugin_id,),
            ).fetchone()

            enabled = bool(existing["enabled"]) if (existing and keep_enabled) else False
            installed_at = existing["installed_at"] if existing else now

            conn.execute(
                """
                INSERT INTO plugin_state (
                    plugin_id, category, name, version, path, manifest_json,
                    exclusive, enabled, db_version, installed_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(plugin_id) DO UPDATE SET
                    category = excluded.category,
                    name = excluded.name,
                    version = excluded.version,
                    path = excluded.path,
                    manifest_json = excluded.manifest_json,
                    exclusive = excluded.exclusive,
                    enabled = excluded.enabled,
                    db_version = excluded.db_version,
                    updated_at = excluded.updated_at
                """,
                (
                    manifest.plugin_id,
                    manifest.category,
                    manifest.name,
                    manifest.version,
                    str(install_path),
                    manifest_json,
                    1 if exclusive else 0,
                    1 if enabled else 0,
                    int(db_version),
                    installed_at,
                    now,
                ),
            )

        self.reload()
        return self.require(manifest.plugin_id)

    def remove(self, plugin_id: str) -> None:
        with db_connection(self._db_path) as conn:
            conn.execute("DELETE FROM plugin_state WHERE plugin_id = ?", (plugin_id,))
            conn.execute("DELETE FROM plugin_secrets WHERE plugin_id = ?", (plugin_id,))
        self.reload()

    def set_db_version(self, plugin_id: str, version: int) -> None:
        with db_connection(self._db_path) as conn:
            conn.execute(
                "UPDATE plugin_state SET db_version = ?, updated_at = ? WHERE plugin_id = ?",
                (int(version), _utcnow(), plugin_id),
            )
        self.reload()

    def set_enabled(self, plugin_id: str, enabled: bool) -> PluginRecord:
        """Enable or disable a plugin.

        For an exclusive category, disabling the siblings and enabling the target
        happen in **one transaction**, so there is never a moment where two
        trackers are both active or none is.
        """

        record = self.require(plugin_id)
        now = _utcnow()

        with db_connection(self._db_path) as conn:
            if enabled and record.exclusive:
                conn.execute(
                    """
                    UPDATE plugin_state SET enabled = 0, updated_at = ?
                    WHERE category = ? AND enabled = 1 AND plugin_id != ?
                    """,
                    (now, record.category, plugin_id),
                )
            conn.execute(
                "UPDATE plugin_state SET enabled = ?, updated_at = ? WHERE plugin_id = ?",
                (1 if enabled else 0, now, plugin_id),
            )

        self.reload()
        updated = self.require(plugin_id)
        log.info(
            "plugin_enabled_changed",
            plugin_id=plugin_id,
            category=updated.category,
            enabled=updated.enabled,
        )
        return updated

    def set_active_for_category(
        self, category: str, plugin_id: Optional[str]
    ) -> Optional[PluginRecord]:
        """Make exactly ``plugin_id`` active in ``category``, or none at all."""

        now = _utcnow()
        if plugin_id is not None:
            record = self.require(plugin_id)
            if record.category != category:
                raise PluginError(
                    f"Plugin '{plugin_id}' is not in category '{category}'"
                )

        with db_connection(self._db_path) as conn:
            conn.execute(
                "UPDATE plugin_state SET enabled = 0, updated_at = ? WHERE category = ? AND enabled = 1",
                (now, category),
            )
            if plugin_id is not None:
                conn.execute(
                    "UPDATE plugin_state SET enabled = 1, updated_at = ? WHERE plugin_id = ?",
                    (now, plugin_id),
                )

        self.reload()
        return self.active_for_category(category)

    # -- secrets --------------------------------------------------------
    #
    # Exposed here so the host (OAuth, uninstall) can reach a plugin's secrets.
    # Plugins themselves never touch these methods — they get a PluginSecrets
    # view that supplies the plugin_id for them and cannot name another plugin.

    def secret_get(self, plugin_id: str, key: str) -> Optional[str]:
        with db_connection(self._db_path) as conn:
            row = conn.execute(
                "SELECT v FROM plugin_secrets WHERE plugin_id = ? AND k = ?",
                (plugin_id, key),
            ).fetchone()
        return row["v"] if row else None

    def secret_set(self, plugin_id: str, key: str, value: Optional[str]) -> None:
        with db_connection(self._db_path) as conn:
            conn.execute(
                """
                INSERT INTO plugin_secrets (plugin_id, k, v, updated_at)
                VALUES (?, ?, ?, ?)
                ON CONFLICT(plugin_id, k) DO UPDATE SET
                    v = excluded.v, updated_at = excluded.updated_at
                """,
                (plugin_id, key, value, _utcnow()),
            )

    def secret_delete(self, plugin_id: str, key: str) -> None:
        with db_connection(self._db_path) as conn:
            conn.execute(
                "DELETE FROM plugin_secrets WHERE plugin_id = ? AND k = ?",
                (plugin_id, key),
            )

    def secret_keys(self, plugin_id: str) -> List[str]:
        with db_connection(self._db_path) as conn:
            rows = conn.execute(
                "SELECT k FROM plugin_secrets WHERE plugin_id = ? ORDER BY k",
                (plugin_id,),
            ).fetchall()
        return [row["k"] for row in rows]

    def secrets_clear(self, plugin_id: str) -> None:
        with db_connection(self._db_path) as conn:
            conn.execute("DELETE FROM plugin_secrets WHERE plugin_id = ?", (plugin_id,))


__all__ = ["PluginRecord", "PluginRegistry"]
