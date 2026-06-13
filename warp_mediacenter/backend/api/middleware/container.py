"""Dependency injection container for Warp MediaCenter API services."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Optional

from warp_mediacenter.backend.common.logging import get_logger

log = get_logger(__name__)


@dataclass
class ServiceContainer:
    """Central registry for API service dependencies.

    All route modules access shared services through this container
    instead of using module-level globals.
    """

    # Torrent / Debrid
    torrent_orchestrator: Any = None
    debrid_client: Any = None

    # Playback
    player_controller: Any = None
    playback_service: Any = None
    preload_session_manager: Any = None

    # Information providers
    trakt_manager: Any = None
    information_providers: Any = None

    # Library
    torrent_search_service: Any = None

    # Custom services by name
    _extras: Dict[str, Any] = field(default_factory=dict)

    def get(self, name: str) -> Optional[Any]:
        """Get a service by name."""
        return self._extras.get(name)

    def set(self, name: str, service: Any) -> None:
        """Register a service by name."""
        self._extras[name] = service
        log.info("service_registered", name=name)

    def has(self, name: str) -> bool:
        """Check if a service is registered."""
        return name in self._extras

    def require(self, name: str) -> Any:
        """Get a service by name, raising if not registered."""
        service = self._extras.get(name)
        if service is None:
            raise RuntimeError(f"Service '{name}' not registered")
        return service


_container: Optional[ServiceContainer] = None


def get_container() -> ServiceContainer:
    """Get the global service container, creating one if needed."""
    global _container
    if _container is None:
        _container = ServiceContainer()
    return _container


def set_container(container: ServiceContainer) -> None:
    """Replace the global service container."""
    global _container
    _container = container
    log.info("service_container_replaced")


def init_container(
    *,
    torrent_orchestrator: Any = None,
    debrid_client: Any = None,
    player_controller: Any = None,
    playback_service: Any = None,
    preload_session_manager: Any = None,
    trakt_manager: Any = None,
    information_providers: Any = None,
    torrent_search_service: Any = None,
    **extras: Any,
) -> ServiceContainer:
    """Create and register the global service container with all services."""
    global _container
    _container = ServiceContainer(
        torrent_orchestrator=torrent_orchestrator,
        debrid_client=debrid_client,
        player_controller=player_controller,
        playback_service=playback_service,
        preload_session_manager=preload_session_manager,
        trakt_manager=trakt_manager,
        information_providers=information_providers,
        torrent_search_service=torrent_search_service,
        _extras=extras,
    )
    log.info("service_container_initialized")
    return _container
