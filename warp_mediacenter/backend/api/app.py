"""FastAPI application factory for Warp MediaCenter."""

from __future__ import annotations

from contextlib import asynccontextmanager
from typing import Any, AsyncIterator, Dict, Optional

from fastapi import FastAPI

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.api.routes import torrent, stream, images, scrobble, library, player, subtitles, trakt, debrid, settings
from warp_mediacenter.backend.api.routes.discovery import search_router, catalog_router
from warp_mediacenter.backend.api.middleware import (
    setup_cors,
    setup_error_handler,
    setup_request_logging,
    get_container,
    ServiceContainer,
)
from warp_mediacenter.backend.persistence import connection as db_connection

log = get_logger(__name__)

_api_app: Optional[FastAPI] = None


def create_app(
    *,
    container: Optional[ServiceContainer] = None,
    cors_origins: Optional[list] = None,
) -> FastAPI:
    """Create and configure the FastAPI application.

    Args:
        container: Service container with shared dependencies. Created if not provided.
        cors_origins: List of allowed CORS origins. Defaults to ["*"].
    """
    global _api_app

    if container is None:
        container = get_container()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        log.info("api_server_started")
        yield
        log.info("api_server_stopped")

    app = FastAPI(
        title="Warp MediaCenter",
        description="Media center backend API for thin clients.",
        version="0.1.0",
        lifespan=lifespan,
    )

    # Middleware (order matters: logging first, then error handler, then CORS)
    setup_request_logging(app)
    setup_error_handler(app)
    setup_cors(app, allow_origins=cors_origins)

    # Routes
    app.include_router(torrent.router, prefix="/api/v1/torrent", tags=["torrent"])
    app.include_router(stream.router, prefix="/api/v1/stream", tags=["stream"])
    app.include_router(images.router, prefix="/api/v1/images", tags=["images"])
    app.include_router(scrobble.router, prefix="/api/v1/scrobble", tags=["scrobble"])
    app.include_router(library.router, prefix="/api/v1/library", tags=["library"])
    app.include_router(search_router, prefix="/api/v1/search", tags=["search"])
    app.include_router(catalog_router, prefix="/api/v1/catalog", tags=["catalog"])
    app.include_router(player.router, prefix="/api/v1/player", tags=["player"])
    app.include_router(subtitles.router, prefix="/api/v1/subtitles", tags=["subtitles"])
    app.include_router(trakt.router, prefix="/api/v1/trakt", tags=["trakt"])
    app.include_router(debrid.router, prefix="/api/v1/debrid", tags=["debrid"])
    app.include_router(settings.router, prefix="/api/v1/settings", tags=["settings"])

    # Health check
    @app.get("/api/v1/health")
    async def health_check() -> Dict[str, Any]:
        return _build_health_response()

    _api_app = app
    return app


def _build_health_response() -> Dict[str, Any]:
    """Build health check response with subsystem status."""
    status: Dict[str, Any] = {
        "status": "ok",
        "service": "warp-mediacenter",
        "subsystems": {},
    }

    # Database
    try:
        with db_connection() as conn:
            row = conn.execute("SELECT MAX(version) FROM schema_version").fetchone()
            db_version = row[0] if row and row[0] is not None else 0
            status["subsystems"]["database"] = {"status": "ok", "schema_version": db_version}
    except Exception as exc:
        status["subsystems"]["database"] = {"status": "error", "message": str(exc)}
        status["status"] = "degraded"

    # Container services
    container = get_container()
    services = {}
    if container.torrent_orchestrator is not None:
        services["torrent_orchestrator"] = "ok"
    if container.debrid_client is not None:
        services["debrid_client"] = "ok"
    if container.player_controller is not None:
        services["player_controller"] = "ok"
    if container.trakt_manager is not None:
        services["trakt_manager"] = "ok"
    if container.information_providers is not None:
        services["information_providers"] = "ok"
    status["subsystems"]["services"] = services

    return status


def get_app() -> Optional[FastAPI]:
    """Return the current FastAPI application instance."""
    return _api_app
