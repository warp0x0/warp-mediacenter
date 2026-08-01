"""Plugin manifest parsing and validation."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Mapping, Optional, Sequence, Tuple

from warp_mediacenter.backend.plugins.contracts.common import (
    get_category,
    is_exclusive_category,
    known_category_ids,
)
from warp_mediacenter.backend.plugins.exceptions import PluginError

#: Host contract version.  A plugin declares the range it was written against via
#: ``host_api``; the host refuses to install anything outside it, so an old plugin
#: fails loudly at install time rather than mysteriously at call time.
HOST_API_VERSION = 1

_PLUGIN_ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{1,63}$")
_TABLE_NAME_RE = re.compile(r"^[a-z][a-z0-9_]{0,47}$")


def _coerce_memory(value: Any) -> Optional[float]:
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _coerce_str_list(value: Any) -> List[str]:
    if isinstance(value, str):
        return [value.strip()] if value.strip() else []
    if not isinstance(value, Sequence):
        return []
    out: List[str] = []
    for item in value:
        text = str(item or "").strip()
        if text and text not in out:
            out.append(text)
    return out


def plugin_slug(plugin_id: str) -> str:
    """Table-name-safe form of a plugin id (``simkl-tracker`` -> ``simkl_tracker``)."""

    return re.sub(r"[^a-z0-9]+", "_", str(plugin_id).lower()).strip("_")


@dataclass
class PluginNetwork:
    """Hosts a plugin is permitted to reach, and how hard it may hammer them."""

    allowed_hosts: List[str] = field(default_factory=list)
    rate_limit_per_minute: Optional[int] = None
    respect_retry_after: bool = True

    @classmethod
    def from_dict(cls, data: Any) -> "PluginNetwork":
        if not isinstance(data, Mapping):
            return cls()
        rate = data.get("rate_limit")
        rate = rate if isinstance(rate, Mapping) else {}
        per_minute = rate.get("per_minute")
        try:
            per_minute_int = int(per_minute) if per_minute is not None else None
        except (TypeError, ValueError):
            per_minute_int = None
        return cls(
            allowed_hosts=[h.lower() for h in _coerce_str_list(data.get("allowed_hosts"))],
            rate_limit_per_minute=per_minute_int,
            respect_retry_after=bool(rate.get("respect_retry_after", True)),
        )

    def as_dict(self) -> Dict[str, Any]:
        return {
            "allowed_hosts": list(self.allowed_hosts),
            "rate_limit": {
                "per_minute": self.rate_limit_per_minute,
                "respect_retry_after": self.respect_retry_after,
            },
        }


@dataclass
class PluginAuth:
    """Declarative description of the plugin's login flow.

    ``kind == "device_code"`` means the *host* runs the whole OAuth device flow —
    the device-code request, the poll loop, token storage and refresh — so the
    plugin ships no auth code at all.  ``kind == "custom"`` is the escape hatch:
    the host stays out of the way and dispatches ``tracker.auth.*`` to the plugin.
    """

    kind: str = "none"
    base_url: str = ""
    device_code_path: str = ""
    poll_path: str = ""
    refresh_path: str = ""
    revoke_path: str = ""
    client_id_secret_key: str = "client_id"
    client_secret_secret_key: str = "client_secret"
    auth_header: str = "Bearer {access_token}"
    extra_headers: Dict[str, str] = field(default_factory=dict)
    scope: str = ""
    near_expiry_seconds: int = 600
    daily_refresh: bool = False

    @property
    def is_device_code(self) -> bool:
        return self.kind == "device_code"

    @property
    def is_custom(self) -> bool:
        return self.kind == "custom"

    @property
    def requires_auth(self) -> bool:
        return self.kind != "none"

    @classmethod
    def from_dict(cls, data: Any) -> "PluginAuth":
        if not isinstance(data, Mapping):
            return cls()
        kind = str(data.get("kind") or "none").strip().lower()
        if kind not in {"none", "device_code", "custom"}:
            raise PluginError(
                f"Unsupported auth kind '{kind}'; expected none, device_code or custom"
            )
        headers_raw = data.get("extra_headers")
        headers = (
            {str(k): str(v) for k, v in headers_raw.items()}
            if isinstance(headers_raw, Mapping)
            else {}
        )
        try:
            near_expiry = int(data.get("near_expiry_seconds") or 600)
        except (TypeError, ValueError):
            near_expiry = 600

        auth = cls(
            kind=kind,
            base_url=str(data.get("base_url") or "").rstrip("/"),
            device_code_path=str(data.get("device_code_path") or ""),
            poll_path=str(data.get("poll_path") or ""),
            refresh_path=str(data.get("refresh_path") or ""),
            revoke_path=str(data.get("revoke_path") or ""),
            client_id_secret_key=str(data.get("client_id_secret_key") or "client_id"),
            client_secret_secret_key=str(
                data.get("client_secret_secret_key") or "client_secret"
            ),
            auth_header=str(data.get("auth_header") or "Bearer {access_token}"),
            extra_headers=headers,
            scope=str(data.get("scope") or ""),
            near_expiry_seconds=max(0, near_expiry),
            daily_refresh=bool(data.get("daily_refresh", False)),
        )

        if auth.is_device_code:
            missing = [
                name
                for name, value in (
                    ("base_url", auth.base_url),
                    ("device_code_path", auth.device_code_path),
                    ("poll_path", auth.poll_path),
                )
                if not value
            ]
            if missing:
                raise PluginError(
                    "auth.kind 'device_code' requires " + ", ".join(missing)
                )
        return auth

    def as_dict(self) -> Dict[str, Any]:
        return {
            "kind": self.kind,
            "base_url": self.base_url,
            "device_code_path": self.device_code_path,
            "poll_path": self.poll_path,
            "refresh_path": self.refresh_path,
            "revoke_path": self.revoke_path,
            "client_id_secret_key": self.client_id_secret_key,
            "client_secret_secret_key": self.client_secret_secret_key,
            "auth_header": self.auth_header,
            "extra_headers": dict(self.extra_headers),
            "scope": self.scope,
            "near_expiry_seconds": self.near_expiry_seconds,
            "daily_refresh": self.daily_refresh,
        }


@dataclass
class PluginDatabaseSpec:
    """Tables the plugin owns, and the migrations that build them.

    Declared table names are unqualified (``config``); the host namespaces them to
    ``plugin_{slug}_{table}``.  Migration SQL must already use the namespaced
    names — the host verifies this at install time rather than rewriting the SQL,
    because rewriting is guesswork and a wrong guess corrupts data.
    """

    tables: List[str] = field(default_factory=list)
    migrations: List[Tuple[int, str]] = field(default_factory=list)

    @classmethod
    def from_dict(cls, data: Any, *, slug: str) -> "PluginDatabaseSpec":
        if not isinstance(data, Mapping):
            return cls()

        tables: List[str] = []
        for raw in _coerce_str_list(data.get("tables")):
            name = raw.lower()
            if not _TABLE_NAME_RE.match(name):
                raise PluginError(
                    f"Invalid table name '{raw}'; use lowercase letters, digits and underscores"
                )
            tables.append(name)

        migrations: List[Tuple[int, str]] = []
        raw_migrations = data.get("migrations")
        if isinstance(raw_migrations, Sequence) and not isinstance(raw_migrations, str):
            for entry in raw_migrations:
                if not isinstance(entry, Mapping):
                    raise PluginError("Each database migration must be an object")
                try:
                    version = int(entry.get("version"))
                except (TypeError, ValueError):
                    raise PluginError("Database migration missing integer 'version'")
                sql = str(entry.get("sql") or "").strip()
                if not sql:
                    raise PluginError(
                        f"Database migration {version} has no 'sql'"
                    )
                migrations.append((version, sql))

        migrations.sort(key=lambda item: item[0])
        versions = [version for version, _ in migrations]
        if len(set(versions)) != len(versions):
            raise PluginError("Duplicate database migration versions")

        spec = cls(tables=tables, migrations=migrations)
        spec.validate_prefix(slug)
        return spec

    def qualified_tables(self, slug: str) -> List[str]:
        return [f"plugin_{slug}_{table}" for table in self.tables]

    def validate_prefix(self, slug: str) -> None:
        """Reject migration SQL that names a table outside the plugin's prefix.

        This is a fail-fast convenience so a mistake surfaces at install time with
        a clear message.  It is *not* the security boundary — that is the SQLite
        authorizer on the plugin's connection, which cannot be talked around.
        """

        prefix = f"plugin_{slug}_"
        pattern = re.compile(
            r"\b(?:CREATE\s+(?:UNIQUE\s+)?INDEX|CREATE\s+TABLE|ALTER\s+TABLE|DROP\s+TABLE|"
            r"INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:IF\s+EXISTS\s+)?"
            r"[\"'`\[]?([A-Za-z_][A-Za-z0-9_]*)",
            re.IGNORECASE,
        )
        for version, sql in self.migrations:
            for name in pattern.findall(sql):
                lowered = name.lower()
                if lowered.startswith(prefix) or lowered.startswith("idx_" + prefix):
                    continue
                raise PluginError(
                    f"Migration {version} touches '{name}', which is outside the "
                    f"plugin's '{prefix}*' namespace"
                )

    def as_dict(self) -> Dict[str, Any]:
        return {
            "tables": list(self.tables),
            "migrations": [
                {"version": version, "sql": sql} for version, sql in self.migrations
            ],
        }

    @property
    def latest_version(self) -> int:
        return self.migrations[-1][0] if self.migrations else 0


@dataclass
class PluginManifest:
    plugin_id: str
    name: str
    version: str
    entrypoint: str
    category: str
    description: Optional[str] = None
    author: Optional[str] = None
    homepage: Optional[str] = None
    icon: Optional[str] = None
    manifest_version: int = 2
    host_api_min: int = 1
    host_api_max: int = 1
    capabilities: List[str] = field(default_factory=list)
    network: PluginNetwork = field(default_factory=PluginNetwork)
    auth: PluginAuth = field(default_factory=PluginAuth)
    database: PluginDatabaseSpec = field(default_factory=PluginDatabaseSpec)
    settings_ui: Dict[str, Any] = field(default_factory=dict)
    estimated_memory_mb: Optional[float] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    # -- loading --------------------------------------------------------

    @classmethod
    def load(cls, manifest_path: Path) -> "PluginManifest":
        if not manifest_path.exists():
            raise PluginError(f"Plugin manifest not found at {manifest_path}")
        try:
            with manifest_path.open("r", encoding="utf-8") as fh:
                data = json.load(fh)
        except json.JSONDecodeError as exc:
            raise PluginError(f"Plugin manifest is not valid JSON: {exc}") from exc
        if not isinstance(data, Mapping):
            raise PluginError("Plugin manifest must be a JSON object")
        return cls.from_dict(data)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "PluginManifest":
        plugin_id = str(data.get("id") or data.get("plugin_id") or "").strip().lower()
        if not plugin_id:
            raise PluginError("Plugin manifest missing 'id'")
        if not _PLUGIN_ID_RE.match(plugin_id):
            raise PluginError(
                f"Invalid plugin id '{plugin_id}'; use lowercase letters, digits, "
                "'.', '_' or '-' (2-64 chars)"
            )

        entrypoint = str(data.get("entrypoint") or data.get("main") or "").strip()
        if not entrypoint:
            raise PluginError("Plugin manifest missing 'entrypoint'")
        if ":" not in entrypoint:
            raise PluginError("Plugin entrypoint must be in 'module:function' format")

        category = str(data.get("category") or "").strip().lower()
        if not category:
            raise PluginError(
                "Plugin manifest missing 'category'; expected one of "
                + ", ".join(known_category_ids())
            )
        if get_category(category) is None:
            raise PluginError(
                f"Unknown plugin category '{category}'; expected one of "
                + ", ".join(known_category_ids())
            )

        try:
            manifest_version = int(data.get("manifest_version") or 2)
        except (TypeError, ValueError):
            manifest_version = 2

        host_api = data.get("host_api")
        host_api = host_api if isinstance(host_api, Mapping) else {}
        try:
            host_min = int(host_api.get("min") or 1)
            host_max = int(host_api.get("max") or host_min)
        except (TypeError, ValueError):
            raise PluginError("host_api.min/max must be integers")
        if not (host_min <= HOST_API_VERSION <= host_max):
            raise PluginError(
                f"Plugin requires host API {host_min}-{host_max}; this host is "
                f"version {HOST_API_VERSION}"
            )

        metadata = data.get("metadata")
        metadata_dict = dict(metadata) if isinstance(metadata, Mapping) else {}
        settings_ui = data.get("settings_ui")
        settings_ui_dict = dict(settings_ui) if isinstance(settings_ui, Mapping) else {}

        slug = plugin_slug(plugin_id)

        return cls(
            plugin_id=plugin_id,
            name=str(data.get("name") or plugin_id),
            version=str(data.get("version") or "0.0.0"),
            entrypoint=entrypoint,
            category=category,
            description=(str(data["description"]) if data.get("description") else None),
            author=(str(data["author"]) if data.get("author") else None),
            homepage=(str(data["homepage"]) if data.get("homepage") else None),
            icon=(str(data["icon"]) if data.get("icon") else None),
            manifest_version=manifest_version,
            host_api_min=host_min,
            host_api_max=host_max,
            capabilities=_coerce_str_list(data.get("capabilities")),
            network=PluginNetwork.from_dict(data.get("network")),
            auth=PluginAuth.from_dict(data.get("auth")),
            database=PluginDatabaseSpec.from_dict(data.get("database"), slug=slug),
            settings_ui=settings_ui_dict,
            estimated_memory_mb=_coerce_memory(
                data.get("estimated_memory_mb") or data.get("memory_requirement_mb")
            ),
            metadata=metadata_dict,
        )

    # -- accessors ------------------------------------------------------

    @property
    def module(self) -> str:
        return self.entrypoint.split(":", 1)[0]

    @property
    def callable_name(self) -> str:
        return self.entrypoint.split(":", 1)[1]

    @property
    def slug(self) -> str:
        return plugin_slug(self.plugin_id)

    @property
    def exclusive(self) -> bool:
        return is_exclusive_category(self.category)

    @property
    def has_settings_ui(self) -> bool:
        return bool(self.settings_ui)

    def supports(self, capability: str) -> bool:
        return capability in self.capabilities

    def as_dict(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "manifest_version": self.manifest_version,
            "id": self.plugin_id,
            "name": self.name,
            "version": self.version,
            "category": self.category,
            "entrypoint": self.entrypoint,
            "host_api": {"min": self.host_api_min, "max": self.host_api_max},
            "capabilities": list(self.capabilities),
            "network": self.network.as_dict(),
            "auth": self.auth.as_dict(),
            "database": self.database.as_dict(),
            "settings_ui": dict(self.settings_ui),
        }
        for key in ("description", "author", "homepage", "icon"):
            value = getattr(self, key)
            if value:
                payload[key] = value
        if self.estimated_memory_mb is not None:
            payload["estimated_memory_mb"] = self.estimated_memory_mb
        if self.metadata:
            payload["metadata"] = dict(self.metadata)
        return payload


__all__ = [
    "HOST_API_VERSION",
    "PluginAuth",
    "PluginDatabaseSpec",
    "PluginManifest",
    "PluginNetwork",
    "plugin_slug",
]
