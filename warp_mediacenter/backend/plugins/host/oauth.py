"""Host-owned OAuth device-code flow.

Every tracker worth supporting — Trakt, Simkl, and the Trakt-compatible forks —
authenticates the same way: request a device code, show the user a short code and
a URL, poll until they approve, then refresh a rotating token forever.  Making
each plugin reimplement that would duplicate ~200 lines of fiddly, security-
relevant code per plugin, and every copy would get the refresh race slightly
wrong.

So the host owns it.  A plugin declares the endpoint shape in its manifest and
ships no auth code at all; the ``Authorization`` header is injected into its HTTP
client on the way out.  A service with a genuinely bespoke flow sets
``"auth": {"kind": "custom"}`` and handles ``tracker.auth.*`` itself.

The flow logic here is ported from the Trakt implementation in
``information_handlers/trakt_manager.py`` (device poll loop, terminal states,
near-expiry and once-daily refresh), which has been in production and is the
behaviour worth preserving.
"""

from __future__ import annotations

import threading
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Dict, Mapping, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.plugins.host.http import PluginHttpClient
from warp_mediacenter.backend.plugins.host.secrets import PluginSecrets
from warp_mediacenter.backend.plugins.manifest import PluginAuth

log = get_logger(__name__)

#: Secret key the token record is stored under.
TOKEN_SECRET_KEY = "oauth_token"

#: Poll responses that mean "keep waiting" rather than "give up".
_PENDING_ERRORS = {"authorization_pending", "slow_down", "temporarily_unavailable"}
#: Poll responses that end the flow.
_EXPIRED_ERRORS = {"expired", "expired_token", "410"}
_DENIED_ERRORS = {"denied", "access_denied", "418", "already_used", "409"}

_MIN_POLL_INTERVAL = 5


@dataclass
class DeviceCodeState:
    """In-memory state of an in-flight device authorisation."""

    status: str = "none"  # none | pending | authorized | denied | expired | error
    error: Optional[str] = None
    user_code: Optional[str] = None
    verification_url: Optional[str] = None
    expires_at: Optional[float] = None
    interval: int = 5
    device_code: Optional[str] = field(default=None, repr=False)

    def as_dict(self) -> Dict[str, Any]:
        return {
            "status": self.status,
            "error": self.error,
            "user_code": self.user_code,
            "verification_url": self.verification_url,
            "expires_at": self.expires_at,
            "interval": self.interval,
        }


class DeviceCodeAuthenticator:
    """Runs and maintains one plugin's OAuth session."""

    def __init__(
        self,
        *,
        plugin_id: str,
        auth: PluginAuth,
        secrets: PluginSecrets,
        http_factory: Any,
    ) -> None:
        self._plugin_id = plugin_id
        self._auth = auth
        self._secrets = secrets
        #: Callable returning an *unauthenticated* client for the auth host — the
        #: token endpoints must not carry the Bearer header we are trying to mint.
        self._http_factory = http_factory
        self._lock = threading.RLock()
        self._state = DeviceCodeState()
        self._thread: Optional[threading.Thread] = None
        self._daily_refresh_day: Optional[str] = None

    # -- credentials ----------------------------------------------------

    @property
    def client_id(self) -> Optional[str]:
        return self._secrets.get(self._auth.client_id_secret_key)

    @property
    def client_secret(self) -> Optional[str]:
        return self._secrets.get(self._auth.client_secret_secret_key)

    @property
    def is_configured(self) -> bool:
        return bool(self.client_id)

    # -- token record ---------------------------------------------------

    def read_token(self) -> Optional[Dict[str, Any]]:
        return self._secrets.get_json(TOKEN_SECRET_KEY)

    def _write_token(self, data: Mapping[str, Any]) -> Dict[str, Any]:
        now = time.time()
        expires_in = data.get("expires_in")
        try:
            expires_in_f = float(expires_in) if expires_in is not None else None
        except (TypeError, ValueError):
            expires_in_f = None
        created_at = data.get("created_at")
        try:
            created_at_f = float(created_at) if created_at is not None else now
        except (TypeError, ValueError):
            created_at_f = now

        record = {
            "access_token": str(data.get("access_token") or ""),
            "refresh_token": str(data.get("refresh_token") or ""),
            "token_type": str(data.get("token_type") or "bearer"),
            "scope": str(data.get("scope") or ""),
            "created_at": created_at_f,
            "expires_in": expires_in_f,
            "expires_at": (created_at_f + expires_in_f) if expires_in_f else None,
            "updated_at": now,
            "reauth_required": False,
            "reauth_reason": None,
        }
        self._secrets.set_json(TOKEN_SECRET_KEY, record)
        return record

    def clear_token(self) -> None:
        self._secrets.delete(TOKEN_SECRET_KEY)
        with self._lock:
            self._state = DeviceCodeState()
        log.info("plugin_auth_cleared", plugin_id=self._plugin_id)

    def _flag_reauth(self, reason: str) -> None:
        record = self.read_token() or {}
        record["reauth_required"] = True
        record["reauth_reason"] = reason
        self._secrets.set_json(TOKEN_SECRET_KEY, record)
        log.warning("plugin_auth_reauth_required", plugin_id=self._plugin_id, reason=reason)

    # -- status ---------------------------------------------------------

    def status(self) -> Dict[str, Any]:
        """Current auth state.  Never makes a network call."""

        record = self.read_token()
        with self._lock:
            flow = self._state.as_dict()

        if not self.is_configured:
            return {
                "connected": False,
                "configured": False,
                "status": "not_configured",
                "flow": flow,
            }

        if not record or not record.get("access_token"):
            return {
                "connected": False,
                "configured": True,
                "status": flow.get("status") or "disconnected",
                "flow": flow,
            }

        return {
            "connected": not record.get("reauth_required"),
            "configured": True,
            "status": "reauth_required" if record.get("reauth_required") else "connected",
            "reauth_required": bool(record.get("reauth_required")),
            "reauth_reason": record.get("reauth_reason"),
            "expires_at": record.get("expires_at"),
            "scope": record.get("scope"),
            "flow": flow,
        }

    # -- device flow ----------------------------------------------------

    def start(self) -> Dict[str, Any]:
        """Request a device code and begin polling in the background."""

        if not self.is_configured:
            raise ValueError(
                f"Plugin '{self._plugin_id}' has no client_id configured"
            )

        client = self._http_factory()
        payload: Dict[str, Any] = {"client_id": self.client_id}
        if self._auth.scope:
            payload["scope"] = self._auth.scope

        response = client.post(
            self._auth.base_url + self._auth.device_code_path,
            json=payload,
            authenticated=False,
        )
        if not response.ok:
            raise RuntimeError(
                f"Device code request failed with HTTP {response.status}: {response.text[:200]}"
            )

        data = response.json({}) or {}
        device_code = str(data.get("device_code") or "")
        if not device_code:
            raise RuntimeError("Device code response contained no device_code")

        try:
            expires_in = int(data.get("expires_in") or 600)
        except (TypeError, ValueError):
            expires_in = 600
        try:
            interval = max(_MIN_POLL_INTERVAL, int(data.get("interval") or _MIN_POLL_INTERVAL))
        except (TypeError, ValueError):
            interval = _MIN_POLL_INTERVAL

        with self._lock:
            self._state = DeviceCodeState(
                status="pending",
                user_code=str(data.get("user_code") or ""),
                verification_url=str(
                    data.get("verification_url") or data.get("verification_uri") or ""
                ),
                expires_at=time.time() + expires_in,
                interval=interval,
                device_code=device_code,
            )
            # A previous flow may still be polling; it will notice the state
            # change and stop, but do not start a second one on top of it.
            if self._thread is not None and self._thread.is_alive():
                log.info("plugin_auth_flow_restarted", plugin_id=self._plugin_id)
            self._thread = threading.Thread(
                target=self._poll_loop,
                args=(device_code, expires_in, interval),
                daemon=True,
                name=f"plugin-auth-{self._plugin_id}",
            )
            self._thread.start()

        log.info(
            "plugin_auth_device_code_issued",
            plugin_id=self._plugin_id,
            expires_in=expires_in,
            interval=interval,
        )
        with self._lock:
            return self._state.as_dict()

    def _poll_loop(self, device_code: str, expires_in: int, interval: int) -> None:
        deadline = time.time() + expires_in
        polls = 0

        while time.time() < deadline:
            # Abandon if a newer flow replaced this one.
            with self._lock:
                if self._state.device_code != device_code:
                    return

            time.sleep(interval)
            polls += 1

            try:
                outcome, payload = self._poll_once(device_code)
            except Exception as exc:  # noqa: BLE001 - a poll failure must not kill the thread
                log.warning(
                    "plugin_auth_poll_error",
                    plugin_id=self._plugin_id,
                    poll=polls,
                    error=str(exc),
                )
                continue

            if outcome == "authorized":
                self._write_token(payload)
                with self._lock:
                    self._state.status = "authorized"
                    self._state.error = None
                    self._state.device_code = None
                log.info(
                    "plugin_auth_authorized", plugin_id=self._plugin_id, polls=polls
                )
                return

            if outcome in {"denied", "expired"}:
                with self._lock:
                    self._state.status = outcome
                    self._state.error = str(payload.get("error") or outcome)
                    self._state.device_code = None
                log.warning(
                    "plugin_auth_flow_ended",
                    plugin_id=self._plugin_id,
                    outcome=outcome,
                    polls=polls,
                )
                return

            if outcome == "slow_down":
                interval += 5

        with self._lock:
            if self._state.device_code == device_code:
                self._state.status = "expired"
                self._state.error = "Polling deadline exceeded"
                self._state.device_code = None
        log.warning("plugin_auth_deadline", plugin_id=self._plugin_id, polls=polls)

    def _poll_once(self, device_code: str) -> tuple[str, Dict[str, Any]]:
        client = self._http_factory()
        path = self._auth.poll_path.replace("{device_code}", device_code)
        body = {
            "code": device_code,
            "client_id": self.client_id,
            "client_secret": self.client_secret,
        }
        response = client.post(
            self._auth.base_url + path,
            json=body,
            authenticated=False,
            allowed_statuses={400, 401, 403, 404, 409, 410, 418, 429},
        )
        data = response.json({}) or {}

        if response.ok and data.get("access_token"):
            return "authorized", data

        error = str(data.get("error") or response.status or "").lower()
        if error in _EXPIRED_ERRORS or response.status == 410:
            return "expired", data
        if error in _DENIED_ERRORS or response.status in {409, 418}:
            return "denied", data
        if error == "slow_down" or response.status == 429:
            return "slow_down", data
        if error in _PENDING_ERRORS or response.status in {400, 404}:
            return "pending", data
        return "pending", data

    # -- refresh --------------------------------------------------------

    def _needs_refresh(self, record: Mapping[str, Any]) -> bool:
        expires_at = record.get("expires_at")
        if not expires_at:
            return False
        try:
            return float(expires_at) - time.time() <= self._auth.near_expiry_seconds
        except (TypeError, ValueError):
            return False

    def ensure_valid(self) -> Optional[Dict[str, Any]]:
        """Return a usable token record, refreshing it if it is near expiry."""

        record = self.read_token()
        if not record or not record.get("access_token"):
            return None
        if record.get("reauth_required"):
            return None

        if self._needs_refresh(record):
            return self.refresh() or record

        if self._auth.daily_refresh:
            today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
            if self._daily_refresh_day != today:
                self._daily_refresh_day = today
                refreshed = self.refresh(best_effort=True)
                if refreshed:
                    return refreshed

        return record

    def refresh(self, *, best_effort: bool = False) -> Optional[Dict[str, Any]]:
        """Exchange the refresh token for a new access token.

        Serialised process-wide, and the on-disk record is re-read inside the
        lock: if another caller refreshed while we waited, that result is adopted
        instead of burning our now-stale refresh token.  Rotating refresh tokens
        invalidate the previous one, so an unguarded double refresh is exactly
        what logs users out at random.
        """

        if not self._auth.refresh_path:
            return None

        with self._secrets.refresh_lock():
            record = self.read_token()
            if not record or not record.get("refresh_token"):
                return None
            if not self._needs_refresh(record) and not best_effort:
                return record

            client = self._http_factory()
            body = {
                "client_id": self.client_id,
                "client_secret": self.client_secret,
                "grant_type": "refresh_token",
                "refresh_token": record["refresh_token"],
            }
            try:
                response = client.post(
                    self._auth.base_url + self._auth.refresh_path,
                    json=body,
                    authenticated=False,
                    allowed_statuses={400, 401, 403},
                )
            except Exception as exc:  # noqa: BLE001
                if best_effort:
                    log.warning(
                        "plugin_auth_refresh_failed",
                        plugin_id=self._plugin_id,
                        error=str(exc),
                    )
                    return None
                raise

            if not response.ok:
                if response.status in {400, 401, 403}:
                    self._flag_reauth(f"refresh_rejected_{response.status}")
                    return None
                if best_effort:
                    return None
                raise RuntimeError(
                    f"Token refresh failed with HTTP {response.status}"
                )

            data = response.json({}) or {}
            if not data.get("access_token"):
                if best_effort:
                    return None
                raise RuntimeError("Token refresh returned no access_token")

            updated = self._write_token(data)
            log.info("plugin_auth_refreshed", plugin_id=self._plugin_id)
            return updated

    # -- header injection ------------------------------------------------

    def auth_headers(self) -> Dict[str, str]:
        """Headers to attach to an authenticated plugin request."""

        headers: Dict[str, str] = {}
        client_id = self.client_id or ""

        for key, template in self._auth.extra_headers.items():
            headers[key] = template.replace("{client_id}", client_id)

        record = self.ensure_valid()
        if record and record.get("access_token"):
            headers["Authorization"] = self._auth.auth_header.replace(
                "{access_token}", str(record["access_token"])
            )
        return headers

    def handle_unauthorized(self) -> bool:
        """Called by the HTTP client on a 401; True means "retry the request"."""

        refreshed = self.refresh(best_effort=True)
        if refreshed:
            return True
        self._flag_reauth("unauthorized")
        return False


__all__ = ["TOKEN_SECRET_KEY", "DeviceCodeAuthenticator", "DeviceCodeState"]
