"""Warp startup — starts Torrent-API-Py + API server together."""

from __future__ import annotations

import signal
import sys
import threading
from typing import Optional

from warp_mediacenter.backend.common.logging import get_logger, init_logging
from warp_mediacenter.backend.common.service_manager import TorrentApiPyManager
from warp_mediacenter.cli.api_server import serve, _init_services, _get_local_ip
from warp_mediacenter.config.settings import get_settings

log = get_logger(__name__)

_torrent_api: Optional[TorrentApiPyManager] = None


def warp_startup(
    host: str = "0.0.0.0",
    port: int = 8000,
    torrent_host: str = "127.0.0.1",
    torrent_port: int = 8009,
    torrent_executable: Optional[str] = None,
    log_level: str = "info",
    reload: bool = False,
) -> None:
    """Start Torrent-API-Py + Warp MediaCenter API server together.

    Args:
        host: API server bind address
        port: API server bind port
        torrent_host: Torrent-API-Py bind address
        torrent_port: Torrent-API-Py bind port
        torrent_executable: Path to Torrent-API-Py executable (auto-detected if None)
        log_level: Uvicorn log level
        reload: Enable auto-reload (dev only, disables Torrent-API-Py)
    """
    # Initialize logging
    settings = get_settings()
    init_logging(settings.log_level)

    log.info(
        "warp_startup_starting",
        api_host=host,
        api_port=port,
        torrent_host=torrent_host,
        torrent_port=torrent_port,
    )

    # Print startup banner
    print()
    print("=" * 60)
    print("  Warp MediaCenter — Full Stack Startup")
    print("=" * 60)
    print()

    # Start Torrent-API-Py (skip if reload mode)
    if not reload:
        global _torrent_api
        _torrent_api = TorrentApiPyManager(
            host=torrent_host,
            port=torrent_port,
            executable=torrent_executable,
        )

        print(f"  Starting Torrent-API-Py on {torrent_host}:{torrent_port}...")
        try:
            _torrent_api.start()
        except FileNotFoundError:
            print()
            print(f"  WARNING: Torrent-API-Py executable not found at '{_torrent_api.executable}'")
            print("  Torrent search will be unavailable.")
            print("  Install Torrent-API-Py or set TORRENT_API_EXECUTABLE env var.")
            print()
            _torrent_api = None
        else:
            if _torrent_api.wait_for_health():
                print(f"  Torrent-API-Py: HEALTHY")
            else:
                print(f"  WARNING: Torrent-API-Py health check failed")
                print("  Torrent search may be unavailable.")
                _torrent_api = None
    else:
        print("  Reload mode: skipping Torrent-API-Py")

    print()

    # Graceful shutdown handling
    def _shutdown(signum, frame):
        log.info("warp_startup_shutdown_signal", signal=signal.Signals(signum).name)
        if _torrent_api:
            _torrent_api.stop()
        sys.exit(0)

    signal.signal(signal.SIGINT, _shutdown)
    signal.signal(signal.SIGTERM, _shutdown)

    # Start API server in main thread
    print(f"  Starting API server on {host}:{port}...")
    print()
    print(f"  Local:   http://localhost:{port}")
    print(f"  Network: http://{_get_local_ip()}:{port}")
    print()
    print(f"  Docs:    http://localhost:{port}/docs")
    print(f"  Health:  http://localhost:{port}/api/v1/health")
    print(f"  Torrent: http://{torrent_host}:{torrent_port}/api/v1/health")
    print()
    print("  Press Ctrl+C to stop")
    print("=" * 60)
    print()

    try:
        serve(host=host, port=port, log_level=log_level, reload=reload)
    finally:
        if _torrent_api:
            _torrent_api.stop()
