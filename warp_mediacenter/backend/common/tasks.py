"""Lightweight task execution with adaptive resource awareness."""

from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor, Future
from dataclasses import dataclass
from typing import TYPE_CHECKING, Callable, Any, Optional
import threading
import time

from warp_mediacenter.backend.common.errors import TaskError
from warp_mediacenter.backend.common.logging import get_logger

log = get_logger(__name__)

if TYPE_CHECKING:
    from warp_mediacenter.backend.resource_management import ResourceManager



@dataclass
class TaskSpec:
    fn: Callable[..., Any]
    args: tuple[Any, ...] = ()
    kwargs: dict[str, Any] = None
    retries: int = 0
    backoff_sec: float = 0.5
    name: str = "task"
    estimated_memory_mb: Optional[float] = None

    def __post_init__(self):
        if self.kwargs is None:
            self.kwargs = {}


class TaskRunner:
    """Tiny in-process task runner with retries/backoff."""
    def __init__(
        self,
        max_workers: int = 4,
        *,
        resource_manager: Optional["ResourceManager"] = None,
        estimated_task_memory_mb: float = 256.0,
        context: Optional[str] = None,
        resource_wait_timeout: float = 30.0,
    ):
        self._resource_manager = resource_manager
        self._estimated_task_memory_mb = max(0.0, estimated_task_memory_mb)
        self._resource_wait_timeout = resource_wait_timeout
        self._context = context or "task_runner"

        effective_workers = max_workers
        if self._resource_manager is not None:
            effective_workers = self._resource_manager.recommend_worker_count(
                max_workers,
                min_mem_per_worker_mb=self._estimated_task_memory_mb or 0,
                context=self._context,
            )

        self._executor = ThreadPoolExecutor(
            max_workers=effective_workers,
            thread_name_prefix="warp-task",
        )
        self._closed = False
        self._lock = threading.Lock()

    def submit(self, spec: TaskSpec) -> Future:
        if self._closed:
            raise TaskError("TaskRunner is closed")

        required_memory = spec.estimated_memory_mb or self._estimated_task_memory_mb
        if self._resource_manager is not None and required_memory:
            context = spec.name or self._context
            self._resource_manager.wait_for_headroom(
                required_memory,
                context=context,
                timeout=self._resource_wait_timeout,
            )

        def _wrapped():
            attempt = 0
            while True:
                try:
                    log.debug("task_start", task=spec.name, attempt=attempt)
                    result = spec.fn(*spec.args, **spec.kwargs)
                    log.debug("task_done", task=spec.name, attempt=attempt)
                    return result
                except Exception as e:  # noqa: BLE001
                    if attempt >= spec.retries:
                        log.error("task_fail", task=spec.name, attempt=attempt, error=str(e))
                        raise
                    sleep_for = spec.backoff_sec * (2 ** attempt)
                    log.warning("task_retry", task=spec.name, attempt=attempt, sleep_for=sleep_for, error=str(e))
                    time.sleep(sleep_for)
                    attempt += 1

        return self._executor.submit(_wrapped)

    def close(self, wait: bool = True) -> None:
        with self._lock:
            if not self._closed:
                self._executor.shutdown(wait=wait, cancel_futures=not wait)
                self._closed = True

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        self.close(wait=True)
