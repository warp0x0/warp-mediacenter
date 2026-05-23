"""CORS middleware configuration for Warp MediaCenter API."""

from __future__ import annotations

from typing import List, Optional

from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI

from warp_mediacenter.backend.common.logging import get_logger

log = get_logger(__name__)

DEFAULT_ALLOW_ORIGINS = ["*"]
DEFAULT_ALLOW_METHODS = ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"]
DEFAULT_ALLOW_HEADERS = ["*"]
DEFAULT_ALLOW_CREDENTIALS = False
DEFAULT_EXPOSE_HEADERS = ["Content-Range", "Content-Length", "Accept-Ranges"]
DEFAULT_MAX_AGE = 600


def setup_cors(
    app: FastAPI,
    *,
    allow_origins: Optional[List[str]] = None,
    allow_methods: Optional[List[str]] = None,
    allow_headers: Optional[List[str]] = None,
    allow_credentials: Optional[bool] = None,
    expose_headers: Optional[List[str]] = None,
    max_age: Optional[int] = None,
) -> None:
    """Configure CORS middleware on the FastAPI application.

    Defaults are permissive for local network use. Override for production.
    """
    origins = allow_origins or DEFAULT_ALLOW_ORIGINS
    methods = allow_methods or DEFAULT_ALLOW_METHODS
    headers = allow_headers or DEFAULT_ALLOW_HEADERS
    credentials = allow_credentials if allow_credentials is not None else DEFAULT_ALLOW_CREDENTIALS
    exposed = expose_headers or DEFAULT_EXPOSE_HEADERS
    age = max_age or DEFAULT_MAX_AGE

    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=credentials,
        allow_methods=methods,
        allow_headers=headers,
        expose_headers=exposed,
        max_age=age,
    )

    log.info("cors_configured", origins=origins, methods=methods)
