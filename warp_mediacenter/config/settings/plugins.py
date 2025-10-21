from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Mapping, Optional

from .library import coerce_path


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


def load_installed_plugins(payload: Mapping[str, Any]) -> Dict[str, InstalledPlugin]:
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
        path = coerce_path(data.get("path"))
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


def serialize_plugins(plugins: Mapping[str, InstalledPlugin]) -> Dict[str, Any]:
    return {plugin_id: plugin.as_dict() for plugin_id, plugin in plugins.items()}


__all__ = [
    "InstalledPlugin",
    "load_installed_plugins",
    "serialize_plugins",
]
