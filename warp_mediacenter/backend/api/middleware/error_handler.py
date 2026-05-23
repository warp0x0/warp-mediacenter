"""Uniform error handling middleware for Warp MediaCenter API."""

from __future__ import annotations

import time
from typing import Any, Dict

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import Response

from warp_mediacenter.backend.common.logging import get_logger

log = get_logger(__name__)


class ErrorHandlerMiddleware(BaseHTTPMiddleware):
    """Catch unhandled exceptions and return uniform JSON error responses."""

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        try:
            return await call_next(request)
        except Exception as exc:
            return _handle_exception(request, exc)


def _handle_exception(request: Request, exc: Exception) -> JSONResponse:
    """Convert an exception into a uniform JSON error response."""
    from fastapi import HTTPException
    from fastapi.exceptions import RequestValidationError
    from starlette import status

    if isinstance(exc, HTTPException):
        return JSONResponse(
            status_code=exc.status_code,
            content=_error_payload(
                code=exc.status_code,
                message=exc.detail,
                path=request.url.path,
            ),
            headers=getattr(exc, "headers", None),
        )

    if isinstance(exc, RequestValidationError):
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=_error_payload(
                code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                message="Validation error",
                path=request.url.path,
                details=exc.errors(),
            ),
        )

    log.error("unhandled_exception: %s %s", request.method, request.url.path, exc_info=exc)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=_error_payload(
            code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            message="Internal server error",
            path=request.url.path,
        ),
    )


def _error_payload(
    code: int,
    message: str,
    path: str,
    *,
    details: Any = None,
) -> Dict[str, Any]:
    """Build a uniform error response payload."""
    payload: Dict[str, Any] = {
        "error": True,
        "code": code,
        "message": message,
        "path": path,
        "timestamp": time.time(),
    }
    if details is not None:
        payload["details"] = details
    return payload


def setup_error_handler(app: FastAPI) -> None:
    """Register the error handler middleware on the FastAPI application."""
    app.add_middleware(ErrorHandlerMiddleware)
    log.info("error_handler_configured")
