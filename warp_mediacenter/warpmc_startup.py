from __future__ import annotations
import time
import sys

from warp_mediacenter.backend.common.logging import get_logger, init_logging
from warp_mediacenter.backend.common.tasks import TaskRunner, TaskSpec
from warp_mediacenter.backend.common.types import HealthReport
from warp_mediacenter.backend.resource_management import get_resource_manager
from warp_mediacenter.config.settings import get_settings



def quick_self_check() -> HealthReport:
    # Keep this minimal now; expand as subsystems land.
    components = {
        "python": "ok" if sys.version_info >= (3, 10) else "degraded",
        "logging": "ok",
        "config": "ok",
        "tasks": "ok",
    }

    status = "ok" if all(v == "ok" for v in components.values()) else "degraded"
    
    return {"status": status, "components": components}

def _sample_task(x: int, y: int) -> int:
    time.sleep(0.05)  # pretend work
    
    return x + y

def main() -> int:
    settings = get_settings()
    
    init_logging(settings.log_level)
    log = get_logger("warpmc.startup")

    log.info("boot_begin", app=settings.app_name, env=settings.env, log_level=settings.log_level)

    # health check
    health = quick_self_check()
    log.info("health_report", **health)

    # tiny task runner smoke test
    resource_manager = get_resource_manager()
    profile = resource_manager.build_profile(requested_workers=settings.task_workers)
    log.info("resource_profile", **profile.as_dict())

    with TaskRunner(
        max_workers=settings.task_workers,
        resource_manager=resource_manager,
        estimated_task_memory_mb=128.0,
        context="startup",
        resource_wait_timeout=15.0,
    ) as runner:
        fut = runner.submit(
            TaskSpec(
                fn=_sample_task,
                args=(2, 3),
                name="sum",
                estimated_memory_mb=64.0,
            )
        )
        result = fut.result(timeout=2)
        log.info("task_result", task="sum", result=result)

    log.info("boot_ready", version=__import__("warp_mediacenter").__version__)
    
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
