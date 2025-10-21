"""Plugin manifest helpers."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, Mapping, Optional

from warp_mediacenter.backend.plugins.exceptions import PluginError
from warp_mediacenter.config.settings.plugins import InstalledPlugin


def _coerce_memory(value: Any) -> Optional[float]:
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


@dataclass
class PluginManifest:
    plugin_id: str
    name: str
    version: str
    entrypoint: str
    description: Optional[str] = None
    estimated_memory_mb: Optional[float] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    @classmethod
    def load(cls, manifest_path: Path) -> "PluginManifest":
        if not manifest_path.exists():
            raise PluginError(f"Plugin manifest not found at {manifest_path}")
        with manifest_path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
        if not isinstance(data, Mapping):
            raise PluginError("Plugin manifest must be a JSON object")
        return cls.from_dict(data)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "PluginManifest":
        plugin_id = str(data.get("id") or data.get("plugin_id") or "").strip()
        if not plugin_id:
            raise PluginError("Plugin manifest missing 'id'")
        name = str(data.get("name") or plugin_id)
        version = str(data.get("version") or "0.0.0")
        entrypoint = str(data.get("entrypoint") or data.get("main") or "").strip()
        if not entrypoint:
            raise PluginError("Plugin manifest missing 'entrypoint'")
        description = data.get("description")
        if description is not None:
            description = str(description)
        metadata = data.get("metadata")
        metadata_dict = dict(metadata) if isinstance(metadata, Mapping) else {}
        estimated_memory = _coerce_memory(
            data.get("estimated_memory_mb") or data.get("memory_requirement_mb")
        )
        return cls(
            plugin_id=plugin_id,
            name=name,
            version=version,
            entrypoint=entrypoint,
            description=description,
            estimated_memory_mb=estimated_memory,
            metadata=metadata_dict,
        )

    @property
    def module(self) -> str:
        if ":" not in self.entrypoint:
            raise PluginError(
                "Plugin entrypoint must be in 'module:function' format"
            )
        return self.entrypoint.split(":", 1)[0]

    @property
    def callable_name(self) -> str:
        if ":" not in self.entrypoint:
            raise PluginError(
                "Plugin entrypoint must be in 'module:function' format"
            )
        return self.entrypoint.split(":", 1)[1]

    def to_installed_plugin(self, install_path: Path, *, installed_at: str) -> InstalledPlugin:
        return InstalledPlugin(
            plugin_id=self.plugin_id,
            name=self.name,
            version=self.version,
            entrypoint=self.entrypoint,
            path=str(install_path),
            installed_at=installed_at,
            description=self.description,
            estimated_memory_mb=self.estimated_memory_mb,
            metadata=self.metadata,
        )
