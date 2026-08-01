"""Per-plugin secret storage.

Tokens live in the ``plugin_secrets`` table rather than a JSON file on disk, so
they participate in the same database, the same backup and the same lifecycle as
the rest of the app's state, and uninstalling a plugin removes its credentials
with it.

Values are stored in plaintext, matching the existing ``settings`` table which
already holds API keys the same way.  Encrypting them here would mean keeping the
key beside the database, which stops casual copying and nothing else — the honest
boundary is filesystem access to ``warpmc.db``.

Isolation comes from the *view*: a plugin receives a ``PluginSecrets`` bound to
its own id and has no way to name another plugin.  The ``plugin_secrets`` table
is also outside every plugin's SQL namespace, so it cannot be reached with a
query either.
"""

from __future__ import annotations

import json
import threading
from contextlib import contextmanager
from typing import Any, Dict, Iterator, List, Optional, TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover
    from warp_mediacenter.backend.plugins.registry import PluginRegistry

#: Refresh locks are process-wide per plugin so a token refresh cannot race
#: itself.  That matters for rotating refresh tokens (Trakt, Simkl): two
#: simultaneous refreshes invalidate each other and log the user out.
_REFRESH_LOCKS: Dict[str, threading.Lock] = {}
_REFRESH_LOCKS_GUARD = threading.Lock()


def _refresh_lock_for(plugin_id: str) -> threading.Lock:
    with _REFRESH_LOCKS_GUARD:
        lock = _REFRESH_LOCKS.get(plugin_id)
        if lock is None:
            lock = threading.Lock()
            _REFRESH_LOCKS[plugin_id] = lock
        return lock


class PluginSecrets:
    """A plugin's own credential store."""

    def __init__(self, registry: "PluginRegistry", plugin_id: str) -> None:
        self._registry = registry
        self._plugin_id = plugin_id

    def get(self, key: str, default: Optional[str] = None) -> Optional[str]:
        value = self._registry.secret_get(self._plugin_id, str(key))
        return default if value is None else value

    def set(self, key: str, value: Optional[str]) -> None:
        self._registry.secret_set(
            self._plugin_id, str(key), None if value is None else str(value)
        )

    def delete(self, key: str) -> None:
        self._registry.secret_delete(self._plugin_id, str(key))

    def keys(self) -> List[str]:
        return self._registry.secret_keys(self._plugin_id)

    def has(self, key: str) -> bool:
        return self._registry.secret_get(self._plugin_id, str(key)) is not None

    def clear(self) -> None:
        self._registry.secrets_clear(self._plugin_id)

    # -- JSON helpers ---------------------------------------------------
    #
    # Token records are structured; storing them as JSON under one key keeps a
    # refresh atomic instead of spread across several rows.

    def get_json(self, key: str) -> Optional[Dict[str, Any]]:
        raw = self.get(key)
        if not raw:
            return None
        try:
            value = json.loads(raw)
        except json.JSONDecodeError:
            return None
        return value if isinstance(value, dict) else None

    def set_json(self, key: str, value: Optional[Dict[str, Any]]) -> None:
        if value is None:
            self.delete(key)
            return
        self.set(key, json.dumps(value, separators=(",", ":")))

    @contextmanager
    def refresh_lock(self) -> Iterator[None]:
        """Serialise token refresh for this plugin across the process."""

        lock = _refresh_lock_for(self._plugin_id)
        lock.acquire()
        try:
            yield
        finally:
            lock.release()


__all__ = ["PluginSecrets"]
