"""Resource awareness utilities for adaptive tuning."""

from __future__ import annotations

from dataclasses import dataclass
import os
import threading
import time
from typing import Optional

import psutil

from warp_mediacenter.backend.common.logging import get_logger

log = get_logger(__name__)

_MB = 1024 * 1024


@dataclass(frozen=True)
class SystemSnapshot:
    """Lightweight capture of relevant system resource metrics."""

    total_ram_mb: float
    available_ram_mb: float
    used_ram_mb: float
    percent_used: float
    cpu_count: int
    load_average_1m: Optional[float]

    def as_dict(self) -> dict[str, float | int | None]:
        return {
            "total_ram_mb": round(self.total_ram_mb, 2),
            "available_ram_mb": round(self.available_ram_mb, 2),
            "used_ram_mb": round(self.used_ram_mb, 2),
            "percent_used": round(self.percent_used, 2),
            "cpu_count": self.cpu_count,
            "load_average_1m": round(self.load_average_1m, 2) if self.load_average_1m is not None else None,
        }


@dataclass(frozen=True)
class ResourceProfile:
    """Computed guidance derived from a :class:`SystemSnapshot`."""

    snapshot: SystemSnapshot
    memory_reserve_mb: float
    recommended_task_workers: int

    def as_dict(self) -> dict[str, object]:
        return {
            "snapshot": self.snapshot.as_dict(),
            "memory_reserve_mb": round(self.memory_reserve_mb, 2),
            "recommended_task_workers": self.recommended_task_workers,
        }


class ResourceManager:
    """Compute safe operating limits using current system resources."""

    def __init__(
        self,
        *,
        memory_reserve_ratio: float = 0.15,
        poll_interval: float = 0.5,
        min_workers: int = 1,
        max_load_per_cpu: float = 1.2,
    ) -> None:
        self._memory_reserve_ratio = max(0.0, min(memory_reserve_ratio, 0.9))
        self._poll_interval = max(0.1, poll_interval)
        self._min_workers = max(1, min_workers)
        self._max_load_per_cpu = max(0.1, max_load_per_cpu)
        self._lock = threading.Lock()
        self._snapshot: Optional[SystemSnapshot] = None

    # ------------------------------------------------------------------
    # Snapshot helpers
    # ------------------------------------------------------------------
    def snapshot(self, *, refresh: bool = True) -> SystemSnapshot:
        """Return a snapshot of the current system resources."""

        with self._lock:
            if self._snapshot is None or refresh:
                vm = psutil.virtual_memory()
                total_mb = vm.total / _MB
                available_mb = vm.available / _MB
                used_mb = total_mb - available_mb
                try:
                    load_avg = os.getloadavg()[0]
                except (AttributeError, OSError):
                    load_avg = None

                self._snapshot = SystemSnapshot(
                    total_ram_mb=total_mb,
                    available_ram_mb=available_mb,
                    used_ram_mb=used_mb,
                    percent_used=float(vm.percent),
                    cpu_count=psutil.cpu_count(logical=True) or 1,
                    load_average_1m=load_avg,
                )

            return self._snapshot

    # ------------------------------------------------------------------
    # Derived calculations
    # ------------------------------------------------------------------
    def memory_reserve_mb(self, snapshot: Optional[SystemSnapshot] = None) -> float:
        snap = snapshot or self.snapshot(refresh=False)
        return snap.total_ram_mb * self._memory_reserve_ratio

    def _safe_available_memory(self, snapshot: Optional[SystemSnapshot] = None) -> float:
        snap = snapshot or self.snapshot()
        reserve = self.memory_reserve_mb(snap)
        return max(0.0, snap.available_ram_mb - reserve)

    def recommend_worker_count(
        self,
        requested_workers: int,
        *,
        min_mem_per_worker_mb: float = 256.0,
        context: str | None = None,
    ) -> int:
        """Return a safe worker cap based on RAM and CPU load."""

        snap = self.snapshot()
        safe_available = self._safe_available_memory(snap)
        if min_mem_per_worker_mb <= 0:
            mem_bound = requested_workers
        else:
            mem_bound = int(max(self._min_workers, safe_available // min_mem_per_worker_mb))

        cpu_bound = max(self._min_workers, snap.cpu_count)
        if snap.load_average_1m is not None and snap.cpu_count:
            load_ratio = snap.load_average_1m / max(snap.cpu_count, 1)
            if load_ratio > self._max_load_per_cpu:
                cpu_bound = max(
                    self._min_workers,
                    int(cpu_bound / (load_ratio / self._max_load_per_cpu)),
                )

        recommended = max(self._min_workers, min(requested_workers, mem_bound, cpu_bound))
        if recommended < requested_workers:
            log.info(
                "resource_workers_adjusted",
                context=context or "tasks",
                requested=requested_workers,
                recommended=recommended,
                safe_available_mb=round(safe_available, 2),
                cpu_bound=cpu_bound,
            )

        return recommended

    def wait_for_headroom(
        self,
        required_memory_mb: float,
        *,
        context: str,
        timeout: float = 30.0,
    ) -> bool:
        """Block until sufficient free memory is available.

        Returns ``True`` if headroom was achieved, ``False`` otherwise.
        """

        deadline = time.monotonic() + timeout
        while True:
            snap = self.snapshot()
            safe_available = self._safe_available_memory(snap)
            if safe_available >= required_memory_mb:
                return True

            if time.monotonic() >= deadline:
                log.warning(
                    "resource_headroom_timeout",
                    context=context,
                    required_mb=required_memory_mb,
                    available_mb=round(safe_available, 2),
                )
                return False

            log.debug(
                "resource_headroom_wait",
                context=context,
                required_mb=required_memory_mb,
                available_mb=round(safe_available, 2),
            )
            time.sleep(self._poll_interval)

    # ------------------------------------------------------------------
    # Profiles
    # ------------------------------------------------------------------
    def build_profile(
        self,
        *,
        requested_workers: int,
        min_mem_per_worker_mb: float = 256.0,
    ) -> ResourceProfile:
        snap = self.snapshot()
        recommended = self.recommend_worker_count(
            requested_workers,
            min_mem_per_worker_mb=min_mem_per_worker_mb,
        )

        return ResourceProfile(
            snapshot=snap,
            memory_reserve_mb=self.memory_reserve_mb(snap),
            recommended_task_workers=recommended,
        )


_RESOURCE_MANAGER: Optional[ResourceManager] = None
_RESOURCE_MANAGER_LOCK = threading.Lock()


def get_resource_manager() -> ResourceManager:
    """Return a process-wide :class:`ResourceManager` singleton."""

    global _RESOURCE_MANAGER
    with _RESOURCE_MANAGER_LOCK:
        if _RESOURCE_MANAGER is None:
            _RESOURCE_MANAGER = ResourceManager()
        return _RESOURCE_MANAGER
