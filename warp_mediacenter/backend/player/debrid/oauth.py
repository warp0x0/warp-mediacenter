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
APP_CLIENT_ID = "X245A4XAIBGVM"


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

    # How long to wait before retrying a failed token refresh (seconds).
    # Prevents hammering the RD API after a bad response.
    _REFRESH_BACKOFF_S: float = 60.0

    # Proactive-refresh window: if the token expires within this many seconds,
    # treat it as needing a refresh even before it has technically expired.
    # Guards against clock skew, in-flight request latency, and back-to-back
    # API calls that could race a token right at its expiry boundary.
    _EXPIRY_BUFFER_S: float = 300.0  # 5 minutes

    def __init__(self, settings: RealDebridSettings) -> None:
        self._settings = settings
        self._session = requests.Session()
        self._session.headers.update({"Content-Type": "application/json"})
        # Timestamp of the last failed refresh attempt (in-process only).
        # Reset to None on success so the next expiry triggers a fresh attempt.
        self._refresh_failed_at: Optional[float] = None

    # ------------------------------------------------------------------
    # Token-state helpers
    # ------------------------------------------------------------------
    def _token_needs_refresh(self) -> bool:
        """Return True when a token refresh is warranted.

        A refresh is needed when:
        - There is no access token at all, OR
        - The token has already expired, OR
        - The token will expire within ``_EXPIRY_BUFFER_S`` seconds.

        Using a buffer (default 5 min) prevents races where a token expires
        between the validity check and the API call that uses it, and handles
        typical clock-skew between client and RealDebrid servers.
        """
        if not self._settings.access_token:
            return True
        return time.time() + self._EXPIRY_BUFFER_S >= self._settings.token_expires_at

    # ------------------------------------------------------------------
    # Step 1: Request device code
    # ------------------------------------------------------------------
    def request_device_code(self) -> DeviceCodeResponse:
        """Initiate device flow. Returns user_code and verification_url for display."""

        params = {
            "client_id": APP_CLIENT_ID,
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
        poll_count = 0
        consecutive_errors = 0

        log.info("realdebrid_poll_start", device_code_len=len(device_code), expires_in=expires_in)

        while time.time() < deadline:
            poll_count += 1
            if poll_count % 5 == 1:
                log.info("realdebrid_polling", poll=poll_count, remaining_s=int(deadline - time.time()))

            params = {
                "client_id": APP_CLIENT_ID,
                "code": device_code,
            }

            try:
                resp = self._session.get(
                    f"{OAUTH_BASE}/device/credentials",
                    params=params,
                    timeout=20,
                )
            except Exception as exc:
                consecutive_errors += 1
                log.warning("realdebrid_poll_%d network_error consecutive=%d: %s", poll_count, consecutive_errors, exc)
                if consecutive_errors > 10:
                    raise RealDebridOAuthError("network_error", f"Too many network errors ({consecutive_errors}): {exc}")
                time.sleep(interval)
                continue

            consecutive_errors = 0
            log.info("realdebrid_poll_%d status=%s", poll_count, resp.status_code)

            if resp.status_code == 200:
                try:
                    data = resp.json()
                    log.info("realdebrid_credentials_raw", keys=list(data.keys()) if isinstance(data, dict) else type(data).__name__)
                    if not data.get("client_id") or not data.get("client_secret"):
                        log.info("realdebrid_poll_%d still_pending (null credentials)", poll_count)
                        time.sleep(interval)
                        continue
                    creds = DeviceCredentialsResponse.model_validate(data)
                    log.info("realdebrid_credentials_received", client_id=creds.client_id)
                    return creds
                except Exception as exc:
                    log.error("realdebrid_credentials_parse_failed", error=str(exc), raw=str(resp.text)[:500])
                    raise RealDebridOAuthError("bad_response", f"Failed to parse credentials: {exc}")

            data = self._safe_json(resp)
            error = data.get("error") or "authorization_pending"
            log.info("realdebrid_poll_%d error=%s", poll_count, error)

            if error == "authorization_pending":
                time.sleep(interval)
                continue
            if error == "slow_down":
                interval = min(interval + 5, 30)
                log.info("realdebrid_slow_down", new_interval=interval)
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
        log.info("realdebrid_exchange_token_start", client_id=client_id)
        resp = self._session.post(
            f"{OAUTH_BASE}/token",
            data=data,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            timeout=20,
        )
        log.info("realdebrid_exchange_token_status", status=resp.status_code)
        if resp.status_code != 200:
            log.error("realdebrid_exchange_token_error", status=resp.status_code, body=resp.text[:500])
        resp.raise_for_status()
        raw = resp.json()
        log.info("realdebrid_exchange_token_raw", keys=list(raw.keys()) if isinstance(raw, dict) else type(raw).__name__)
        token = TokenResponse.model_validate(raw)

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

        log.info("realdebrid_complete_flow_start")
        creds = self.poll_credentials(device_code)
        log.info("realdebrid_complete_flow_credentials_ok")
        token = self.exchange_token(device_code, creds.client_id, creds.client_secret)
        log.info("realdebrid_complete_flow_token_ok")

        now = time.time()
        update_realdebrid_settings(
            oauth_client_id=creds.client_id,
            oauth_client_secret=creds.client_secret,
            access_token=token.access_token,
            refresh_token=token.refresh_token,
            token_expires_at=now + token.expires_in,
        )

        log.info("realdebrid_auth_complete", client_id=creds.client_id)
        _clear_search_cache()
        return token

    # ------------------------------------------------------------------
    # Token refresh
    # ------------------------------------------------------------------
    def refresh_token(self) -> TokenResponse:
        """Refresh an expired access token using the stored refresh_token.

        No-op if the current token still has more than ``_EXPIRY_BUFFER_S``
        seconds remaining — returns a synthetic TokenResponse backed by the
        current stored values so callers never need to special-case this.
        """
        # Guard: skip the network round-trip when the token is still healthy.
        # This makes every callsite safe — no need for each caller to check
        # token_expires_at independently before calling refresh_token().
        if not self._token_needs_refresh():
            remaining = int(self._settings.token_expires_at - time.time())
            log.debug("rd_refresh_skipped_token_still_valid", remaining_s=remaining)
            return TokenResponse(
                access_token=self._settings.access_token,
                refresh_token=self._settings.refresh_token or "",
                expires_in=remaining,
            )

        if not self._settings.refresh_token:
            raise RealDebridOAuthError("no_refresh_token", "No refresh token available")

        data = {
            "client_id": self._settings.oauth_client_id,
            "client_secret": self._settings.oauth_client_secret or "",
            "grant_type": "refresh_token",
            "refresh_token": self._settings.refresh_token,
        }
        log.info("rd_refresh_request", client_id=self._settings.oauth_client_id[:6] if self._settings.oauth_client_id else "none")
        resp = self._session.post(
            f"{OAUTH_BASE}/token",
            data=data,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            timeout=20,
        )
        if resp.status_code != 200:
            log.error("rd_refresh_response", status=resp.status_code, body=resp.text[:500])
        resp.raise_for_status()
        token = TokenResponse.model_validate(resp.json())

        now = time.time()
        update_realdebrid_settings(
            access_token=token.access_token,
            refresh_token=token.refresh_token,
            token_expires_at=now + token.expires_in,
        )

        log.info("realdebrid_token_refreshed", expires_in=token.expires_in)
        _clear_search_cache()
        return token

    def ensure_valid_token(self) -> str:
        """Return a valid access token, refreshing silently if necessary.

        Uses ``_token_needs_refresh()`` (buffer-aware) rather than a bare
        expiry comparison so the token is proactively refreshed before it
        reaches the hard expiry boundary.

        Refresh is also guarded by a short in-process backoff so a dead token
        does not cause a storm of requests to RD on every API call.
        """
        if not self._token_needs_refresh():
            remaining = int(self._settings.token_expires_at - time.time())
            log.debug("rd_token_valid", remaining_s=remaining)
            return self._settings.access_token

        log.info(
            "rd_token_expired_or_missing",
            has_access=bool(self._settings.access_token),
            has_refresh=bool(self._settings.refresh_token),
            expires_at=self._settings.token_expires_at,
            expired_by_s=int(time.time() - self._settings.token_expires_at) if self._settings.access_token else None,
        )

        if self._settings.refresh_token:
            # Backoff: if a refresh attempt just failed, don't hammer RD again
            # immediately — wait until the backoff window expires.
            now = time.time()
            if self._refresh_failed_at is not None:
                elapsed = now - self._refresh_failed_at
                if elapsed < self._REFRESH_BACKOFF_S:
                    remaining = int(self._REFRESH_BACKOFF_S - elapsed)
                    log.info("rd_refresh_backoff", retry_in_s=remaining)
                    raise RealDebridOAuthError(
                        "refresh_backoff",
                        f"Recent token refresh failed — retrying in ~{remaining}s. "
                        "If this persists, re-authenticate in Settings → Authentication.",
                    )

            log.info("rd_token_refresh_attempt", client_id=self._settings.oauth_client_id[:6] if self._settings.oauth_client_id else "none")
            try:
                token = self.refresh_token()
                self._refresh_failed_at = None  # clear backoff on success
                log.info("rd_token_refresh_success")
                return token.access_token
            except Exception as exc:
                self._refresh_failed_at = time.time()  # arm backoff
                log.error("rd_token_refresh_failed", error=str(exc)[:200])
                self._clear_dead_tokens(exc)
                raise

        raise RealDebridOAuthError(
            "no_valid_token",
            "No valid token and no refresh token. "
            "Re-authenticate in Settings → Authentication → Real Debrid.",
        )

    # ------------------------------------------------------------------
    # Token cleanup after failed refresh
    # ------------------------------------------------------------------
    @staticmethod
    def _clear_dead_tokens(exc: Exception) -> None:
        """Clear the expired access token if RD says the credentials are wrong.

        When RD returns error_code=2 (wrong_parameter) we know the access_token
        is definitely invalid, so we zero it out and reset the expiry.

        IMPORTANT: we intentionally do NOT nullify the refresh_token even when
        RD says wrong_parameter.  Nullifying it would permanently block silent
        refresh and force the user to manually re-authenticate from Settings.
        The backoff in ensure_valid_token prevents immediate retry loops while
        still allowing the next attempt after the backoff window expires.
        If the refresh_token really is dead, the next attempt will fail again and
        the user will receive a clear 401 / "re-authenticate" prompt.
        """
        import requests as _requests
        if not isinstance(exc, _requests.HTTPError):
            return
        resp = exc.response
        if resp is None or resp.status_code != 400:
            return
        try:
            body = resp.json()
        except (ValueError, KeyError):
            return
        if body.get("error_code") == 2 or body.get("error") == "wrong_parameter":
            log.warning(
                "rd_access_token_invalid",
                note="Clearing access_token only; refresh_token preserved for future attempts",
            )
            update_realdebrid_settings(
                access_token=None,
                token_expires_at=0.0,
                # refresh_token is intentionally NOT included here
            )
            _clear_search_cache()

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    @staticmethod
    def _safe_json(resp: requests.Response) -> Dict[str, Any]:
        try:
            return resp.json()
        except (ValueError, KeyError):
            return {}


def _clear_search_cache() -> None:
    """Clear the torrent search cache so stale cached/uncached splits don't persist."""
    try:
        from warp_mediacenter.backend.persistence import connection, clear_all_torrent_cache
        with connection() as conn:
            removed = clear_all_torrent_cache(conn)
            if removed:
                log.info("torrent_search_cache_cleared", count=removed)
    except Exception:
        pass  # non-fatal — search cache is best-effort
