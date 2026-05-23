"""RealDebrid API client for torrent and link operations."""

from __future__ import annotations

import random
import time
from typing import Any, Dict, List, Optional

import requests

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.player.debrid.models import (
    HostEntry,
    TorrentInfo,
    UnrestrictLink,
)
from warp_mediacenter.backend.player.debrid.oauth import RealDebridOAuth, RealDebridOAuthError
from warp_mediacenter.config.settings.torrent import RealDebridSettings, get_torrent_debrid_settings

log = get_logger(__name__)

RATE_LIMIT_429_MAX_RETRIES = 3
RATE_LIMIT_BASE_DELAY = 2.0


class RealDebridAPIError(RuntimeError):
    """Raised when a RealDebrid API call fails."""

    def __init__(self, status_code: int, error: str, error_code: Optional[int] = None) -> None:
        msg = f"RealDebrid API error {status_code}: {error}"
        if error_code is not None:
            msg += f" (code: {error_code})"
        super().__init__(msg)
        self.status_code = status_code
        self.error = error
        self.error_code = error_code


class RealDebridClient:
    """Client for the RealDebrid REST API.

    Handles torrent management (add magnet, select files, poll status)
    and link unrestricting. Uses OAuth2 for authentication.
    """

    def __init__(
        self,
        settings: Optional[RealDebridSettings] = None,
        timeout: int = 20,
    ) -> None:
        self._settings = settings or get_torrent_debrid_settings().realdebrid
        self._oauth = RealDebridOAuth(self._settings)
        self._session = requests.Session()
        self._timeout = timeout

    # ------------------------------------------------------------------
    # Authentication
    # ------------------------------------------------------------------
    def start_device_auth(self) -> Dict[str, Any]:
        """Start OAuth2 device flow. Returns display info for the user."""
        return self._oauth.full_device_flow()

    def complete_device_auth(self, device_code: str) -> Dict[str, Any]:
        """Complete device flow: poll credentials, exchange tokens, persist."""
        token = self._oauth.complete_flow(device_code)
        return {
            "access_token": token.access_token,
            "expires_in": token.expires_in,
            "token_type": token.token_type,
        }

    def _get_auth_header(self) -> Dict[str, str]:
        """Return Authorization header with a valid token."""
        token = self._oauth.ensure_valid_token()
        return {"Authorization": f"Bearer {token}"}

    # ------------------------------------------------------------------
    # Torrent operations
    # ------------------------------------------------------------------
    def add_magnet(self, magnet: str, host: Optional[str] = None) -> str:
        """Add a magnet link to RealDebrid.

        Checks magnet hash map first. If already mapped, verifies the
        torrent still exists on RD before returning the cached ID.
        Returns the torrent ID.
        """
        magnet_hash = self._extract_magnet_hash(magnet)
        if magnet_hash:
            cached_id = self._get_cached_torrent_id(magnet_hash)
            if cached_id:
                try:
                    info = self.get_torrent_info(cached_id)
                    if not info.is_error:
                        log.info("realdebrid_magnet_cache_hit", magnet_hash=magnet_hash[:8], torrent_id=cached_id)
                        return cached_id
                except RealDebridAPIError:
                    pass

        self._reload_settings()
        data = {"magnet": magnet}
        if host:
            data["host"] = host

        resp = self._post("/torrents/addMagnet", data=data)
        torrent_id = resp.get("id")
        if not torrent_id:
            raise RealDebridAPIError(0, "No torrent ID returned from addMagnet")

        if magnet_hash:
            self._store_magnet_map(magnet_hash, torrent_id)

        log.info("realdebrid_magnet_added", torrent_id=torrent_id, magnet_hash=magnet_hash[:8] if magnet_hash else "unknown")
        return torrent_id

    def select_files(self, torrent_id: str, file_ids: str = "all") -> bool:
        """Select files to start downloading a torrent.

        file_ids: comma-separated file IDs or "all"
        Returns True on success.
        """
        self._reload_settings()
        self._post(f"/torrents/selectFiles/{torrent_id}", data={"files": file_ids}, expected_status=204)
        log.info("realdebrid_files_selected", torrent_id=torrent_id, files=file_ids)
        return True

    def get_torrent_info(self, torrent_id: str) -> TorrentInfo:
        """Get detailed information about a torrent."""
        self._reload_settings()
        resp = self._get(f"/torrents/info/{torrent_id}")
        return TorrentInfo.model_validate(resp)

    def wait_for_download(
        self,
        torrent_id: str,
        *,
        poll_interval: Optional[float] = None,
        timeout: Optional[float] = None,
    ) -> TorrentInfo:
        """Poll torrent status until download completes or times out.

        Returns the final TorrentInfo.
        Raises RealDebridAPIError on timeout or error status.
        """
        interval = poll_interval or self._settings.poll_interval
        max_timeout = timeout or self._settings.download_timeout
        deadline = time.time() + max_timeout

        while time.time() < deadline:
            info = self.get_torrent_info(torrent_id)

            if info.is_complete:
                log.info("realdebrid_download_complete", torrent_id=torrent_id)
                return info

            if info.is_error:
                raise RealDebridAPIError(
                    0,
                    f"Torrent entered error state: {info.status}",
                )

            if info.is_waiting_selection:
                log.info("realdebrid_waiting_selection", torrent_id=torrent_id)
                return info

            log.debug(
                "realdebrid_download_progress",
                torrent_id=torrent_id,
                status=info.status,
                progress=info.progress,
                seeders=info.seeders,
            )

            time.sleep(interval)

        raise RealDebridAPIError(0, f"Download timed out after {max_timeout}s")

    def delete_torrent(self, torrent_id: str) -> bool:
        """Delete a torrent from the user's list."""
        self._reload_settings()
        self._delete(f"/torrents/delete/{torrent_id}", expected_status=204)
        log.info("realdebrid_torrent_deleted", torrent_id=torrent_id)
        return True

    def list_torrents(
        self,
        *,
        offset: int = 0,
        limit: int = 100,
        filter_active: bool = False,
    ) -> List[Dict[str, Any]]:
        """Get the user's torrent list."""
        self._reload_settings()
        params: Dict[str, Any] = {"offset": offset, "limit": min(limit, 5000)}
        if filter_active:
            params["filter"] = "active"
        resp = self._get("/torrents", params=params)
        return resp if isinstance(resp, list) else []

    def get_active_count(self) -> Dict[str, int]:
        """Get currently active torrents count and limit."""
        self._reload_settings()
        return self._get("/torrents/activeCount")

    # ------------------------------------------------------------------
    # Instant availability
    # ------------------------------------------------------------------
    def get_instant_availability(self, hashes: List[str]) -> Dict[str, Any]:
        """Check if torrents are already cached on RealDebrid.

        hashes: list of torrent info hashes (SHA1)
        Returns dict mapping hash -> availability info.
        """
        self._reload_settings()
        if not hashes:
            return {}
        hash_path = "/".join(hashes[:100])
        resp = self._get(f"/torrents/instantAvailability/{hash_path}")
        return resp if isinstance(resp, dict) else {}

    # ------------------------------------------------------------------
    # Host operations
    # ------------------------------------------------------------------
    def get_available_hosts(self) -> List[HostEntry]:
        """Get available hosts to upload torrents to."""
        self._reload_settings()
        resp = self._get("/torrents/availableHosts")
        if not isinstance(resp, list):
            return []
        return [HostEntry.model_validate(item) for item in resp if isinstance(item, dict)]

    # ------------------------------------------------------------------
    # Link unrestricting
    # ------------------------------------------------------------------
    def unrestrict_link(self, link: str, remote: int = 0) -> UnrestrictLink:
        """Unrestrict a hoster link and get a direct download URL."""
        self._reload_settings()
        resp = self._post("/unrestrict/link", data={"link": link, "remote": remote})
        return UnrestrictLink.model_validate(resp)

    def check_link(self, link: str) -> Dict[str, Any]:
        """Check if a file is downloadable."""
        resp = self._post("/unrestrict/check", data={"link": link})
        return resp if isinstance(resp, dict) else {}

    # ------------------------------------------------------------------
    # User info
    # ------------------------------------------------------------------
    def get_user(self) -> Dict[str, Any]:
        """Get current user info."""
        self._reload_settings()
        return self._get("/user")

    # ------------------------------------------------------------------
    # Internal HTTP helpers
    # ------------------------------------------------------------------
    def _get(
        self,
        path: str,
        params: Optional[Dict[str, Any]] = None,
    ) -> Any:
        headers = self._get_auth_header()
        url = f"{self._settings.base_url}{path}"

        for attempt in range(1, RATE_LIMIT_429_MAX_RETRIES + 1):
            resp = self._session.get(url, headers=headers, params=params, timeout=self._timeout)

            if resp.status_code == 429:
                if attempt < RATE_LIMIT_429_MAX_RETRIES:
                    delay = self._get_retry_delay(resp, attempt)
                    log.warning("realdebrid_rate_limited", attempt=attempt, delay=delay)
                    time.sleep(delay)
                    continue
                raise RealDebridAPIError(429, "Rate limit exceeded")

            return self._handle_response(resp)

        raise RealDebridAPIError(429, "Rate limit exceeded after retries")

    def _post(
        self,
        path: str,
        data: Optional[Dict[str, Any]] = None,
        expected_status: int = 200,
    ) -> Any:
        headers = self._get_auth_header()
        url = f"{self._settings.base_url}{path}"

        for attempt in range(1, RATE_LIMIT_429_MAX_RETRIES + 1):
            resp = self._session.post(url, headers=headers, data=data, timeout=self._timeout)

            if resp.status_code == 429:
                if attempt < RATE_LIMIT_429_MAX_RETRIES:
                    delay = self._get_retry_delay(resp, attempt)
                    log.warning("realdebrid_rate_limited", attempt=attempt, delay=delay)
                    time.sleep(delay)
                    continue
                raise RealDebridAPIError(429, "Rate limit exceeded")

            if resp.status_code == expected_status or (expected_status == 204 and resp.status_code == 204):
                if resp.status_code == 204:
                    return {}
                return self._parse_json(resp)

            return self._handle_response(resp)

        raise RealDebridAPIError(429, "Rate limit exceeded after retries")

    def _delete(
        self,
        path: str,
        expected_status: int = 204,
    ) -> Any:
        headers = self._get_auth_header()
        url = f"{self._settings.base_url}{path}"
        resp = self._session.delete(url, headers=headers, timeout=self._timeout)

        if resp.status_code == expected_status:
            return {}
        return self._handle_response(resp)

    def _handle_response(self, resp: requests.Response) -> Any:
        if resp.status_code < 400:
            return self._parse_json(resp)

        data = self._parse_json(resp)
        error = data.get("error", f"HTTP {resp.status_code}")
        error_code = data.get("error_code")
        raise RealDebridAPIError(resp.status_code, error, error_code)

    @staticmethod
    def _parse_json(resp: requests.Response) -> Any:
        try:
            return resp.json()
        except (ValueError, KeyError):
            return {}

    @staticmethod
    def _get_retry_delay(resp: requests.Response, attempt: int) -> float:
        retry_after = resp.headers.get("Retry-After")
        if retry_after:
            try:
                return min(float(retry_after), 30)
            except (ValueError, TypeError):
                pass
        backoff = min(30, RATE_LIMIT_BASE_DELAY * (2 ** (attempt - 1)))
        jitter = random.uniform(0, 1)
        return backoff + jitter

    def _reload_settings(self) -> None:
        self._settings = get_torrent_debrid_settings().realdebrid

    # ------------------------------------------------------------------
    # Magnet hash mapping
    # ------------------------------------------------------------------
    @staticmethod
    def _extract_magnet_hash(magnet: str) -> Optional[str]:
        """Extract info hash from magnet link."""
        if "btih:" not in magnet:
            return None
        try:
            start = magnet.index("btih:") + 5
            end = magnet.index("&", start) if "&" in magnet[start:] else len(magnet)
            return magnet[start:end].upper()
        except ValueError:
            return None

    @staticmethod
    def _get_cached_torrent_id(magnet_hash: str) -> Optional[str]:
        """Look up cached torrent ID for a magnet hash."""
        try:
            from warp_mediacenter.backend.persistence import connection, get_debrid_torrent_id
            with connection() as conn:
                return get_debrid_torrent_id(conn, magnet_hash)
        except Exception:
            return None

    @staticmethod
    def _store_magnet_map(magnet_hash: str, torrent_id: str) -> None:
        """Store magnet hash to torrent ID mapping."""
        try:
            from warp_mediacenter.backend.persistence import connection, upsert_debrid_magnet_map
            with connection() as conn:
                upsert_debrid_magnet_map(conn, magnet_hash, torrent_id)
        except Exception:
            log.debug("debrid_magnet_map_store_failed", magnet_hash=magnet_hash[:8])
