"""Caching helpers for information provider HTTP responses.

The cache uses a two-tier approach:

* An in-memory LRU with a ~6 hour TTL for the most frequently accessed routes.
* A JSON-on-disk store with a ~24 hour TTL to survive process restarts.

Only successful (HTTP < 400) responses are cached, and caching is further gated by
simple allow lists for each provider to make sure we do not retain responses that
are unlikely to be reused.
"""

from __future__ import annotations

import hashlib
import json
import threading
import time
from dataclasses import asdict, dataclass, is_dataclass
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Optional, Tuple

from warp_mediacenter.config import settings

_MEMORY_TTL_SECONDS = 60 * 60 * 6  # ~6 hours
_DISK_TTL_SECONDS = 60 * 60 * 24  # ~24 hours
_MEMORY_CAPACITY = 512

# Paths with these prefixes are considered high value for caching.
_DEFAULT_CACHEABLE_PREFIXES: Mapping[str, Tuple[str, ...]] = {
    "tmdb": ("configuration", "search", "movie", "tv"),
    "trakt": ("users", "shows", "movies", "lists"),
}


@dataclass
class _MemoryEntry:
    value: Any
    expires_at: float


class _LRUCache:
    """Small LRU cache with TTL semantics."""

    def __init__(self, capacity: int, ttl_seconds: int) -> None:
        self._capacity = max(capacity, 1)
        self._ttl = max(ttl_seconds, 1)
        self._store: MutableMapping[str, _MemoryEntry] = {}
        self._order: list[str] = []

    def _evict_if_needed(self) -> None:
        while len(self._order) > self._capacity:
            oldest_key = self._order.pop(0)
            self._store.pop(oldest_key, None)

    def _prune_expired(self) -> None:
        now = time.time()
        expired = [key for key, entry in self._store.items() if entry.expires_at <= now]
        for key in expired:
            self._store.pop(key, None)
            try:
                self._order.remove(key)
            except ValueError:
                continue

    def get(self, key: str) -> Optional[Any]:
        entry = self._store.get(key)
        if not entry:
            return None

        if entry.expires_at <= time.time():
            self.delete(key)
            return None

        try:
            self._order.remove(key)
        except ValueError:
            pass
        self._order.append(key)

        return entry.value

    def set(self, key: str, value: Any) -> None:
        expires_at = time.time() + self._ttl
        self._store[key] = _MemoryEntry(value=value, expires_at=expires_at)
        try:
            self._order.remove(key)
        except ValueError:
            pass
        self._order.append(key)
        self._evict_if_needed()

    def delete(self, key: str) -> None:
        self._store.pop(key, None)
        try:
            self._order.remove(key)
        except ValueError:
            pass

    def clear(self) -> None:
        self._store.clear()
        self._order.clear()

    def prune(self) -> None:
        self._prune_expired()


def _normalize_value(value: Any) -> Any:
    if isinstance(value, Mapping):
        return tuple(sorted((str(k), _normalize_value(v)) for k, v in value.items()))
    if isinstance(value, (list, tuple, set)):
        return tuple(_normalize_value(v) for v in value)
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value

    return str(value)


def _stable_params_repr(params: Optional[Mapping[str, Any]]) -> Tuple[Any, ...]:
    if not params:
        return tuple()

    return tuple(sorted((str(k), _normalize_value(v)) for k, v in params.items()))


def _key_to_string(service: str, path: str, params: Optional[Mapping[str, Any]]) -> str:
    normalized = {
        "service": service.lower(),
        "path": path.lstrip("/"),
        "params": _stable_params_repr(params),
    }

    return json.dumps(normalized, sort_keys=True, separators=(",", ":"))


def _key_to_filename(key: str) -> str:
    digest = hashlib.sha256(key.encode("utf-8")).hexdigest()

    return f"{digest}.json"


def _prepare_payload(payload: Any) -> Any:
    if payload is None:
        return None
    if isinstance(payload, (str, int, float, bool)):
        return payload
    if isinstance(payload, Mapping):
        return {str(k): _prepare_payload(v) for k, v in payload.items()}
    if isinstance(payload, (list, tuple, set)):
        return [_prepare_payload(v) for v in payload]
    if hasattr(payload, "model_dump"):
        return _prepare_payload(payload.model_dump())
    if hasattr(payload, "dict"):
        try:
            return _prepare_payload(payload.dict())  # type: ignore[call-arg]
        except TypeError:
            pass
    if is_dataclass(payload):
        return _prepare_payload(asdict(payload))

    return str(payload)


class InformationProviderCache:
    """Unified cache service for information provider HTTP responses."""

    def __init__(
        self,
        *,
        cache_dir: Optional[Path] = None,
        memory_capacity: int = _MEMORY_CAPACITY,
        memory_ttl: int = _MEMORY_TTL_SECONDS,
        disk_ttl: int = _DISK_TTL_SECONDS,
        cacheable_prefixes: Optional[Mapping[str, Tuple[str, ...]]] = None,
    ) -> None:
        self._cache_dir = cache_dir or Path(settings.get_info_providers_cache_dir())
        self._cache_dir.mkdir(parents=True, exist_ok=True)
        self._memory = _LRUCache(capacity=memory_capacity, ttl_seconds=memory_ttl)
        self._disk_ttl = max(disk_ttl, 1)
        self._lock = threading.RLock()
        self._cacheable_prefixes = cacheable_prefixes or _DEFAULT_CACHEABLE_PREFIXES

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------
    def get(self, service: str, path: str, params: Optional[Mapping[str, Any]] = None) -> Optional[Any]:
        """Fetch a cached payload for the provided service/path combination."""

        cache_key = _key_to_string(service, path, params)
        with self._lock:
            value = self._memory.get(cache_key)
            if value is not None:
                return value

            disk_value = self._load_from_disk(cache_key)
            if disk_value is not None:
                self._memory.set(cache_key, disk_value)

            return disk_value

    def set(
        self,
        service: str,
        path: str,
        params: Optional[Mapping[str, Any]],
        payload: Any,
        *,
        status_code: int,
    ) -> None:
        """Persist a payload into the cache tiers when the response is cacheable."""

        if status_code >= 400:
            return
        if status_code in (401, 403):
            return
        if payload is None:
            return
        if not self._is_cacheable(service, path):
            return

        prepared = _prepare_payload(payload)
        cache_key = _key_to_string(service, path, params)
        with self._lock:
            self._memory.set(cache_key, prepared)
            self._store_on_disk(cache_key, prepared)

    def clear_memory(self) -> None:
        with self._lock:
            self._memory.clear()

    def clear_disk(self) -> None:
        with self._lock:
            for file in self._cache_dir.glob("*.json"):
                try:
                    file.unlink()
                except OSError:
                    continue

    def prune(self) -> None:
        """Remove expired entries from both tiers."""

        with self._lock:
            self._memory.prune()
            self._prune_disk()

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------
    def _is_cacheable(self, service: str, path: str) -> bool:
        normalized_path = path.lstrip("/").lower()
        prefixes = self._cacheable_prefixes.get(service.lower())
        if not prefixes:
            return True

        for prefix in prefixes:
            if normalized_path.startswith(prefix):
                return True

        return False

    def _store_on_disk(self, cache_key: str, payload: Any) -> None:
        expires_at = time.time() + self._disk_ttl
        data = {"expires_at": expires_at, "payload": payload}
        try:
            encoded = json.dumps(data)
        except (TypeError, ValueError):
            return

        filename = self._cache_dir / _key_to_filename(cache_key)
        temp_file = filename.with_suffix(".tmp")
        try:
            temp_file.write_text(encoded, encoding="utf-8")
            temp_file.replace(filename)
        except OSError:
            try:
                temp_file.unlink(missing_ok=True)
            except OSError:
                pass

    def _load_from_disk(self, cache_key: str) -> Optional[Any]:
        filename = self._cache_dir / _key_to_filename(cache_key)
        if not filename.exists():
            return None
        try:
            data = json.loads(filename.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            try:
                filename.unlink()
            except OSError:
                pass
            return None

        expires_at = data.get("expires_at")
        if expires_at is None or expires_at <= time.time():
            try:
                filename.unlink()
            except OSError:
                pass
            return None

        return data.get("payload")

    def _prune_disk(self) -> None:
        now = time.time()
        for file in self._cache_dir.glob("*.json"):
            try:
                data = json.loads(file.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                try:
                    file.unlink()
                except OSError:
                    pass
                continue

            expires_at = data.get("expires_at")
            if expires_at is None or expires_at <= now:
                try:
                    file.unlink()
                except OSError:
                    continue


__all__ = ["InformationProviderCache"]
