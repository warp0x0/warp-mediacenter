"""Request logging middleware for Warp MediaCenter API."""

from __future__ import annotations

import time
from typing import Optional

from fastapi import FastAPI, Request
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import Response

from warp_mediacenter.backend.common.logging import get_logger

log = get_logger(__name__)


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Log every request with method, path, status code, and duration."""

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        start = time.monotonic()
        response = await call_next(request)
        duration_ms = (time.monotonic() - start) * 1000

        log.info(
            "http_request",
            method=request.method,
            path=request.url.path,
            status_code=response.status_code,
            duration_ms=round(duration_ms, 2),
        )

        return response


def setup_request_logging(app: FastAPI) -> None:
    """Register the request logging middleware on the FastAPI application."""
    app.add_middleware(RequestLoggingMiddleware)
    log.info("request_logging_configured")
