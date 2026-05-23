"""RealDebrid OAuth2 device flow implementation."""

from __future__ import annotations

import time
from typing import Any, Dict, Optional

import requests

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.player.debrid.models import (
    DeviceCodeResponse,
    DeviceCredentialsResponse,
    TokenResponse,
)
from warp_mediacenter.config.settings.torrent import (
    RealDebridSettings,
    update_realdebrid_settings,
)

log = get_logger(__name__)

OAUTH_BASE = "https://api.real-debrid.com/oauth/v2"


class RealDebridOAuthError(RuntimeError):
    """Raised when an OAuth2 step fails."""

    def __init__(self, error: str, description: Optional[str] = None) -> None:
        msg = description or error
        super().__init__(f"RealDebrid OAuth error: {msg}")
        self.error = error
        self.description = description


class RealDebridOAuth:
    """Handles the full OAuth2 device authorization flow for RealDebrid.

    Flow:
    1. POST /oauth/v2/device/code?client_id=...&new_credentials=yes
    2. Display user_code + verification_url to user
    3. Poll GET /oauth/v2/device/credentials?client_id=...&code=... every 5s
    4. Receive client_id + client_secret bound to user
    5. POST /oauth/v2/token with grant_type=device to get access/refresh tokens
    6. Persist tokens via settings; auto-refresh on expiry
    """

    def __init__(self, settings: RealDebridSettings) -> None:
        self._settings = settings
        self._session = requests.Session()
        self._session.headers.update({"Content-Type": "application/json"})

    # ------------------------------------------------------------------
    # Step 1: Request device code
    # ------------------------------------------------------------------
    def request_device_code(self) -> DeviceCodeResponse:
        """Initiate device flow. Returns user_code and verification_url for display."""

        params = {
            "client_id": self._settings.oauth_client_id,
            "new_credentials": "yes",
        }
        resp = self._session.get(f"{OAUTH_BASE}/device/code", params=params, timeout=20)
        resp.raise_for_status()
        data = resp.json()
        device = DeviceCodeResponse.model_validate(data)

        log.info(
            "realdebrid_device_code_issued",
            user_code=device.user_code,
            verification_url=device.verification_url,
            expires_in=device.expires_in,
        )
        return device

    # ------------------------------------------------------------------
    # Step 2: Poll for credentials (client_id + client_secret bound to user)
    # ------------------------------------------------------------------
    def poll_credentials(
        self,
        device_code: str,
        *,
        timeout: Optional[int] = None,
    ) -> DeviceCredentialsResponse:
        """Poll until user authorizes or device code expires.

        Returns client_id and client_secret bound to the user's account.
        """

        expires_in = timeout if timeout is not None else 1800
        deadline = time.time() + max(1, expires_in)
        interval = 5

        while time.time() < deadline:
            params = {
                "client_id": self._settings.oauth_client_id,
                "code": device_code,
            }
            resp = self._session.get(
                f"{OAUTH_BASE}/device/credentials",
                params=params,
                timeout=20,
            )

            if resp.status_code == 200:
                data = resp.json()
                creds = DeviceCredentialsResponse.model_validate(data)
                log.info("realdebrid_credentials_received", client_id=creds.client_id)
                return creds

            data = self._safe_json(resp)
            error = data.get("error", "unknown")
            if error == "authorization_pending":
                time.sleep(interval)
                continue
            if error == "slow_down":
                interval = min(interval + 5, 30)
                time.sleep(interval)
                continue

            raise RealDebridOAuthError(
                error,
                data.get("error_description", "Credential polling failed"),
            )

        raise RealDebridOAuthError("expired", "Device authorization timed out")

    # ------------------------------------------------------------------
    # Step 3: Exchange device code for access token
    # ------------------------------------------------------------------
    def exchange_token(
        self,
        device_code: str,
        client_id: str,
        client_secret: str,
    ) -> TokenResponse:
        """Exchange the device code for access/refresh tokens."""

        data = {
            "client_id": client_id,
            "client_secret": client_secret,
            "code": device_code,
            "grant_type": "http://oauth.net/grant_type/device/1.0",
        }
        resp = self._session.post(f"{OAUTH_BASE}/token", data=data, timeout=20)
        resp.raise_for_status()
        token = TokenResponse.model_validate(resp.json())

        log.info("realdebrid_token_obtained", expires_in=token.expires_in)
        return token

    # ------------------------------------------------------------------
    # Full flow convenience method
    # ------------------------------------------------------------------
    def full_device_flow(
        self,
        *,
        timeout: int = 1800,
    ) -> Dict[str, Any]:
        """Run the complete device flow and persist tokens.

        Returns a dict with user_code, verification_url for display.
        Caller must show these to the user before calling this method,
        or use request_device_code + poll_credentials + exchange_token separately.

        For interactive use, call request_device_code(), show the code to user,
        then call complete_flow(device_code).
        """

        device = self.request_device_code()
        return {
            "user_code": device.user_code,
            "verification_url": device.verification_url,
            "expires_in": device.expires_in,
            "interval": device.interval,
            "device_code": device.device_code,
        }

    def complete_flow(self, device_code: str) -> TokenResponse:
        """Poll for credentials and exchange for tokens. Persist to settings."""

        creds = self.poll_credentials(device_code)
        token = self.exchange_token(device_code, creds.client_id, creds.client_secret)

        now = time.time()
        update_realdebrid_settings(
            oauth_client_id=creds.client_id,
            oauth_client_secret=creds.client_secret,
            access_token=token.access_token,
            refresh_token=token.refresh_token,
            token_expires_at=now + token.expires_in,
        )

        log.info("realdebrid_auth_complete", client_id=creds.client_id)
        return token

    # ------------------------------------------------------------------
    # Token refresh
    # ------------------------------------------------------------------
    def refresh_token(self) -> TokenResponse:
        """Refresh an expired access token using the stored refresh_token."""

        if not self._settings.refresh_token:
            raise RealDebridOAuthError("no_refresh_token", "No refresh token available")

        data = {
            "client_id": self._settings.oauth_client_id,
            "client_secret": self._settings.oauth_client_secret or "",
            "grant_type": "refresh_token",
            "refresh_token": self._settings.refresh_token,
        }
        resp = self._session.post(f"{OAUTH_BASE}/token", data=data, timeout=20)
        resp.raise_for_status()
        token = TokenResponse.model_validate(resp.json())

        now = time.time()
        update_realdebrid_settings(
            access_token=token.access_token,
            refresh_token=token.refresh_token,
            token_expires_at=now + token.expires_in,
        )

        log.info("realdebrid_token_refreshed", expires_in=token.expires_in)
        return token

    def ensure_valid_token(self) -> str:
        """Return a valid access token, refreshing if necessary."""

        if self._settings.has_valid_token:
            return self._settings.access_token

        if self._settings.refresh_token:
            token = self.refresh_token()
            return token.access_token

        raise RealDebridOAuthError(
            "no_valid_token",
            "No valid token and no refresh token. Run device auth flow first.",
        )

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    @staticmethod
    def _safe_json(resp: requests.Response) -> Dict[str, Any]:
        try:
            return resp.json()
        except (ValueError, KeyError):
            return {}
