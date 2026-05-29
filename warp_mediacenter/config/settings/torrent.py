"""Torrent and RealDebrid configuration settings."""

from __future__ import annotations

import json
import os
import threading
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, Optional

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.config.settings.library import load_user_settings, write_user_settings

# Fields that are persisted in the dedicated token file (var/tokens/realdebrid_tokens.json).
# Everything else (non-sensitive config) stays in user_settings.json.
_RD_TOKEN_FIELDS: frozenset[str] = frozenset({
    "access_token",
    "refresh_token",
    "oauth_client_id",
    "oauth_client_secret",
    "token_expires_at",
})
_RD_CONFIG_FIELDS: frozenset[str] = frozenset({
    "base_url",
    "poll_interval",
    "download_timeout",
    "prefer_instant",
})

log = get_logger(__name__)

_SETTINGS_LOCK = threading.Lock()
_SETTINGS_SINGLETON: Optional["TorrentDebridSettings"] = None


# ---------------------------------------------------------------------------
# RealDebrid token-file helpers
# ---------------------------------------------------------------------------

def _get_rd_tokens_path() -> Path:
    """Absolute path to var/tokens/realdebrid_tokens.json."""
    from warp_mediacenter.config.settings.paths import get_tokens_dir
    return Path(get_tokens_dir()) / "realdebrid_tokens.json"


def _load_rd_tokens() -> Dict[str, Any]:
    """Read RD token data from the dedicated token file.

    Returns an empty dict when the file does not yet exist (e.g. fresh install
    or immediately after a Disconnect).  Falls back gracefully on parse errors.
    """
    path = _get_rd_tokens_path()
    if not path.exists():
        return {}
    try:
        with path.open("r", encoding="utf-8") as fh:
            return json.load(fh)
    except Exception:
        return {}


def _write_rd_tokens(data: Dict[str, Any]) -> None:
    """Persist RD token fields to var/tokens/realdebrid_tokens.json.

    Creates the tokens directory if it doesn't exist yet.
    """
    path = _get_rd_tokens_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False, sort_keys=True)


def clear_realdebrid_tokens() -> None:
    """Delete the RD token file and strip any residual token fields from
    user_settings.json.

    Called exclusively by the Disconnect button in the UI.  Does NOT touch the
    silent-refresh logic or the access_token-only cleanup performed by
    ``_clear_dead_tokens`` on a bad token response — those paths are left intact.
    """
    # Remove dedicated token file
    try:
        _get_rd_tokens_path().unlink(missing_ok=True)
    except Exception:
        pass

    # Strip any residual token fields that may still sit in user_settings.json
    # (present when disconnect is called before the first post-migration write).
    try:
        user_cfg = load_user_settings()
        rd_cfg = dict(user_cfg.get("realdebrid", {}))
        changed = any(f in rd_cfg for f in _RD_TOKEN_FIELDS)
        if changed:
            for f in _RD_TOKEN_FIELDS:
                rd_cfg.pop(f, None)
            user_cfg["realdebrid"] = rd_cfg
            write_user_settings(user_cfg)
    except Exception:
        pass

    # Reload in-memory singleton so subsequent calls see no tokens
    try:
        get_torrent_debrid_settings(reload=True)
    except Exception:
        pass


@dataclass
class TorrentSettings:
    """Configuration for the Torrent-API-Py service."""

    api_base_url: str = "http://localhost:8009"
    api_key: Optional[str] = None
    min_seeders: int = 5
    max_results: int = 20
    preferred_qualities: tuple[str, ...] = ("2160p", "1080p", "720p")
    fuzzy_match_threshold: float = 0.6

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "TorrentSettings":
        return cls(
            api_base_url=data.get("api_base_url", cls.api_base_url),
            api_key=data.get("api_key"),
            min_seeders=int(data.get("min_seeders", cls.min_seeders)),
            max_results=int(data.get("max_results", cls.max_results)),
            preferred_qualities=tuple(data.get("preferred_qualities", cls.preferred_qualities)),
            fuzzy_match_threshold=float(data.get("fuzzy_match_threshold", cls.fuzzy_match_threshold)),
        )

    def to_dict(self) -> Dict[str, Any]:
        return {
            "api_base_url": self.api_base_url,
            "api_key": self.api_key,
            "min_seeders": self.min_seeders,
            "max_results": self.max_results,
            "preferred_qualities": list(self.preferred_qualities),
            "fuzzy_match_threshold": self.fuzzy_match_threshold,
        }


@dataclass
class RealDebridSettings:
    """Configuration for RealDebrid API and OAuth2."""

    base_url: str = "https://api.real-debrid.com/rest/1.0"
    oauth_client_id: str = "X245A4XAIBGVM"
    oauth_client_secret: Optional[str] = None
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    token_expires_at: float = 0.0
    poll_interval: float = 2.0
    download_timeout: float = 300.0
    prefer_instant: bool = True

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "RealDebridSettings":
        return cls(
            base_url=data.get("base_url", cls.base_url),
            oauth_client_id=data.get("oauth_client_id", cls.oauth_client_id),
            oauth_client_secret=data.get("oauth_client_secret"),
            access_token=data.get("access_token"),
            refresh_token=data.get("refresh_token"),
            token_expires_at=float(data.get("token_expires_at", 0.0)),
            poll_interval=float(data.get("poll_interval", cls.poll_interval)),
            download_timeout=float(data.get("download_timeout", cls.download_timeout)),
            prefer_instant=bool(data.get("prefer_instant", cls.prefer_instant)),
        )

    def to_dict(self) -> Dict[str, Any]:
        return {
            "base_url": self.base_url,
            "oauth_client_id": self.oauth_client_id,
            "oauth_client_secret": self.oauth_client_secret,
            "access_token": self.access_token,
            "refresh_token": self.refresh_token,
            "token_expires_at": self.token_expires_at,
            "poll_interval": self.poll_interval,
            "download_timeout": self.download_timeout,
            "prefer_instant": self.prefer_instant,
        }

    @property
    def has_valid_token(self) -> bool:
        import time
        return bool(self.access_token) and time.time() < self.token_expires_at


@dataclass
class TorrentDebridSettings:
    """Combined container for torrent and RealDebrid settings."""

    torrent: TorrentSettings = field(default_factory=TorrentSettings)
    realdebrid: RealDebridSettings = field(default_factory=RealDebridSettings)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "torrent": self.torrent.to_dict(),
            "realdebrid": self.realdebrid.to_dict(),
        }


def _build_settings() -> TorrentDebridSettings:
    user_cfg = load_user_settings()
    torrent_cfg = user_cfg.get("torrent", {})
    rd_cfg = user_cfg.get("realdebrid", {})

    # Token fields live in a separate file (var/tokens/realdebrid_tokens.json).
    # We merge both sources so that:
    #   • New installs / post-Disconnect: token file is absent → rd_tokens = {}
    #   • Normal operation: token file exists and wins over any stale token
    #     fields still present in user_settings.json (backward-compat fallback).
    rd_tokens = _load_rd_tokens()
    rd_merged = {**rd_cfg, **rd_tokens}  # token file takes precedence

    torrent = TorrentSettings.from_dict(torrent_cfg)
    realdebrid = RealDebridSettings.from_dict(rd_merged)

    env_base_url = os.getenv("TORRENT_API_URL")
    if env_base_url:
        torrent.api_base_url = env_base_url

    env_api_key = os.getenv("TORRENT_API_KEY")
    if env_api_key:
        torrent.api_key = env_api_key

    env_rd_token = os.getenv("REALDEBRID_ACCESS_TOKEN")
    if env_rd_token:
        realdebrid.access_token = env_rd_token

    env_rd_refresh = os.getenv("REALDEBRID_REFRESH_TOKEN")
    if env_rd_refresh:
        realdebrid.refresh_token = env_rd_refresh

    env_rd_client_id = os.getenv("REALDEBRID_CLIENT_ID")
    if env_rd_client_id:
        realdebrid.oauth_client_id = env_rd_client_id

    env_rd_client_secret = os.getenv("REALDEBRID_CLIENT_SECRET")
    if env_rd_client_secret:
        realdebrid.oauth_client_secret = env_rd_client_secret

    return TorrentDebridSettings(torrent=torrent, realdebrid=realdebrid)


def get_torrent_debrid_settings(*, reload: bool = False) -> TorrentDebridSettings:
    global _SETTINGS_SINGLETON
    with _SETTINGS_LOCK:
        if _SETTINGS_SINGLETON is None or reload:
            _SETTINGS_SINGLETON = _build_settings()
        return _SETTINGS_SINGLETON


def update_torrent_settings(**kwargs: Any) -> TorrentDebridSettings:
    current = get_torrent_debrid_settings()
    for key, value in kwargs.items():
        if hasattr(current.torrent, key):
            setattr(current.torrent, key, value)
    return _save_and_reload(current)


def update_realdebrid_settings(**kwargs: Any) -> TorrentDebridSettings:
    current = get_torrent_debrid_settings()
    for key, value in kwargs.items():
        if hasattr(current.realdebrid, key):
            setattr(current.realdebrid, key, value)
    return _save_and_reload(current)


def _save_and_reload(current: TorrentDebridSettings) -> TorrentDebridSettings:
    from datetime import datetime, timezone

    rd_dict = current.realdebrid.to_dict()

    # Split: auth credentials → token file; non-sensitive config → user_settings.json
    token_dict = {k: v for k, v in rd_dict.items() if k in _RD_TOKEN_FIELDS}
    config_dict = {k: v for k, v in rd_dict.items() if k in _RD_CONFIG_FIELDS}

    _write_rd_tokens(token_dict)

    user_cfg = load_user_settings()
    user_cfg["torrent"] = current.torrent.to_dict()
    # Write only non-sensitive config; also strip any legacy token fields that
    # may have been stored here before the token-file migration.
    rd_section = {k: v for k, v in user_cfg.get("realdebrid", {}).items()
                  if k not in _RD_TOKEN_FIELDS}
    rd_section.update(config_dict)
    user_cfg["realdebrid"] = rd_section
    user_cfg["updated_at"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
    write_user_settings(user_cfg)

    return get_torrent_debrid_settings(reload=True)


__all__ = [
    "TorrentSettings",
    "RealDebridSettings",
    "TorrentDebridSettings",
    "clear_realdebrid_tokens",
    "get_torrent_debrid_settings",
    "update_torrent_settings",
    "update_realdebrid_settings",
]
