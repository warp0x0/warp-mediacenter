from concurrent.futures import ThreadPoolExecutor, Future
from typing import Callable, Any, Optional
from __future__ import annotations
from dataclasses import dataclass
import threading
import time

from .logging import get_logger
from .errors import TaskError

log = get_logger(__name__)



@dataclass
class TaskSpec:
    fn: Callable[..., Any]
    args: tuple[Any, ...] = ()
    kwargs: dict[str, Any] = None
    retries: int = 0
    backoff_sec: float = 0.5
    name: str = "task"

    def __post_init__(self):
        if self.kwargs is None:
            self.kwargs = {}


class TaskRunner:
    """Tiny in-process task runner with retries/backoff."""
    def __init__(self, max_workers: int = 4):
        self._executor = ThreadPoolExecutor(max_workers=max_workers, thread_name_prefix="warp-task")
        self._closed = False
        self._lock = threading.Lock()

    def submit(self, spec: TaskSpec) -> Future:
        if self._closed:
            raise TaskError("TaskRunner is closed")

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
