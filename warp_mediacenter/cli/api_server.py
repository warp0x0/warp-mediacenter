"""API server entry point for Warp MediaCenter.

Starts the FastAPI server with all services wired up.

Usage:
    python -m warp_mediacenter.cli.media serve
    python -m warp_mediacenter.cli.media serve --host 0.0.0.0 --port 8000
"""

from __future__ import annotations

import logging
import signal
import sys
from typing import Optional

from warp_mediacenter.backend.common.logging import get_logger, init_logging
from warp_mediacenter.backend.api.app import create_app
from warp_mediacenter.backend.api.middleware import init_container, ServiceContainer
from warp_mediacenter.backend.api.routes.torrent import set_orchestrator
from warp_mediacenter.backend.api.routes.scrobble import set_trakt_manager as set_scrobble_trakt
from warp_mediacenter.backend.api.routes.player import set_player_controller
from warp_mediacenter.backend.api.routes.subtitles import set_player_controller as set_subtitle_player, set_subtitle_service
from warp_mediacenter.backend.api.routes.trakt import set_trakt_manager as set_trakt_route
from warp_mediacenter.backend.api.routes.debrid import set_debrid_client
from warp_mediacenter.backend.information_handlers.providers import InformationProviders
from warp_mediacenter.backend.information_handlers.trakt_manager import TraktManager
from warp_mediacenter.backend.information_handlers.torrent_search import TorrentSearchService
from warp_mediacenter.backend.player.controller import PlayerController
from warp_mediacenter.backend.player.debrid.client import RealDebridClient
from warp_mediacenter.backend.player.service import PlaybackService
from warp_mediacenter.backend.player.subtitles.service import SubtitleService
from warp_mediacenter.backend.player.torrent_stream import TorrentStreamOrchestrator
from warp_mediacenter.config.settings import get_settings

log = get_logger(__name__)


def _init_services() -> ServiceContainer:
    """Initialize all backend services and wire them into the container."""
    log.info("initializing_services")

    # Core providers
    providers = InformationProviders()
    log.info("information_providers_initialized")

    # Trakt manager
    trakt_manager: Optional[TraktManager] = None
    try:
        trakt_manager = providers.trakt
        if trakt_manager:
            log.info("trakt_manager_initialized")
        else:
            log.warning("trakt_manager_unavailable: %s", providers.trakt_error)
    except Exception as exc:
        log.warning("trakt_manager_failed: %s", exc)

    # RealDebrid client
    debrid_client = RealDebridClient()
    log.info("realdebrid_client_initialized")

    # Torrent search service
    torrent_search = TorrentSearchService(debrid_client=debrid_client)
    log.info("torrent_search_service_initialized")

    # Subtitle service
    subtitle_service = SubtitleService()
    log.info("subtitle_service_initialized")

    # Player controller (desktop mode with VLC, fallback to thin_client)
    try:
        player_controller = PlayerController(
            subtitle_service=subtitle_service,
            trakt_manager=trakt_manager,
            mode="desktop",
        )
        player_mode = "desktop"
    except Exception as exc:
        log.warning("vlc_unavailable_falling_back_to_thin_client: %s", exc)
        player_controller = PlayerController(
            subtitle_service=subtitle_service,
            trakt_manager=trakt_manager,
            mode="thin_client",
        )
        player_mode = "thin_client"
    log.info("player_controller_initialized", mode=player_mode)

    # Playback service (extracted from player controller for orchestrator)
    playback_service = player_controller._service

    # Torrent stream orchestrator
    torrent_orchestrator = TorrentStreamOrchestrator(
        search_service=torrent_search,
        debrid_client=debrid_client,
        playback_service=playback_service,
    )
    log.info("torrent_orchestrator_initialized")

    # Wire into service container
    container = init_container(
        torrent_orchestrator=torrent_orchestrator,
        debrid_client=debrid_client,
        player_controller=player_controller,
        playback_service=playback_service,
        trakt_manager=trakt_manager,
        information_providers=providers,
        torrent_search_service=torrent_search,
    )

    # Wire into route modules (for backward compatibility with module-level globals)
    set_orchestrator(torrent_orchestrator)
    set_scrobble_trakt(trakt_manager) if trakt_manager else None
    set_player_controller(player_controller)
    set_subtitle_player(player_controller)
    set_subtitle_service(subtitle_service)
    set_trakt_route(trakt_manager) if trakt_manager else None
    set_debrid_client(debrid_client)

    log.info("all_services_wired")
    return container


def serve(
    host: str = "0.0.0.0",
    port: int = 8000,
    log_level: str = "info",
    reload: bool = False,
) -> None:
    """Start the API server.

    Args:
        host: Bind address (default: 0.0.0.0 for LAN access)
        port: Bind port (default: 8000)
        log_level: Uvicorn log level (debug, info, warning, error)
        reload: Enable auto-reload on code changes (dev only)
    """
    # Initialize logging
    settings = get_settings()
    init_logging(settings.log_level)

    log.info(
        "api_server_starting",
        host=host,
        port=port,
        log_level=log_level,
        reload=reload,
    )

    # Initialize services
    container = _init_services()

    # Create FastAPI app
    app = create_app(container=container)

    # Import uvicorn here to avoid import overhead during CLI parsing
    import uvicorn

    # Graceful shutdown handling
    def _shutdown(signum, frame):
        log.info("api_server_shutdown_signal", signal=signal.Signals(signum).name)
        sys.exit(0)

    signal.signal(signal.SIGINT, _shutdown)
    signal.signal(signal.SIGTERM, _shutdown)

    # Print startup info
    print()
    print("=" * 60)
    print("  Warp MediaCenter API Server")
    print("=" * 60)
    print()
    print(f"  Local:   http://localhost:{port}")
    print(f"  Network: http://{_get_local_ip()}:{port}")
    print()
    print(f"  Docs:    http://localhost:{port}/docs")
    print(f"  Health:  http://localhost:{port}/api/v1/health")
    print()
    print("  Press Ctrl+C to stop")
    print("=" * 60)
    print()

    # Start uvicorn
    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level=log_level,
        reload=reload,
    )


def _get_local_ip() -> str:
    """Get the local network IP address."""
    import socket
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"
