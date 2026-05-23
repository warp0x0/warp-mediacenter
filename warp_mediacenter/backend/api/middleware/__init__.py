"""API middleware package for Warp MediaCenter."""

from warp_mediacenter.backend.api.middleware.cors import setup_cors
from warp_mediacenter.backend.api.middleware.error_handler import setup_error_handler
from warp_mediacenter.backend.api.middleware.request_logging import setup_request_logging
from warp_mediacenter.backend.api.middleware.container import (
    ServiceContainer,
    get_container,
    set_container,
    init_container,
)

__all__ = [
    "setup_cors",
    "setup_error_handler",
    "setup_request_logging",
    "ServiceContainer",
    "get_container",
    "set_container",
    "init_container",
]
