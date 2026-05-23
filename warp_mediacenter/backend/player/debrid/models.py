"""Pydantic models for RealDebrid API responses."""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class TorrentFile(BaseModel):
    """A file inside a torrent on RealDebrid."""

    id: int
    path: str
    bytes: int
    selected: int = 0


class TorrentInfo(BaseModel):
    """Full information about a torrent on RealDebrid."""

    id: str
    filename: str
    original_filename: str = ""
    hash: str = ""
    bytes: int = 0
    original_bytes: int = 0
    host: str = ""
    split: int = 0
    progress: int = 0
    status: str = "magnet_conversion"
    added: str = ""
    files: List[TorrentFile] = Field(default_factory=list)
    links: List[str] = Field(default_factory=list)
    ended: Optional[str] = None
    speed: Optional[int] = None
    seeders: Optional[int] = None

    @property
    def is_complete(self) -> bool:
        return self.status == "downloaded"

    @property
    def is_downloading(self) -> bool:
        return self.status in ("downloading", "compressing", "uploading")

    @property
    def is_waiting_selection(self) -> bool:
        return self.status == "waiting_files_selection"

    @property
    def is_error(self) -> bool:
        return self.status in ("magnet_error", "error", "virus", "dead")


class UnrestrictLink(BaseModel):
    """Result of unrestricting a link."""

    id: str = ""
    filename: str = ""
    mimeType: str = ""
    filesize: int = 0
    link: str = ""
    host: str = ""
    chunks: int = 0
    crc: int = 0
    download: str = ""
    streamable: int = 0


class DeviceCodeResponse(BaseModel):
    """Response from POST /oauth/v2/device/code."""

    device_code: str
    user_code: str
    verification_url: str
    expires_in: int
    interval: int


class DeviceCredentialsResponse(BaseModel):
    """Response from GET /oauth/v2/device/credentials."""

    client_id: str
    client_secret: str


class TokenResponse(BaseModel):
    """Response from POST /oauth/v2/token."""

    access_token: str
    expires_in: int
    token_type: str = "Bearer"
    refresh_token: str = ""


class InstantAvailabilityHost(BaseModel):
    """Availability info for a single hoster."""

    rd: Optional[Dict[str, Any]] = None


class InstantAvailabilityEntry(BaseModel):
    """Availability for a single hash."""

    model_config = {"extra": "allow"}


class HostEntry(BaseModel):
    """A hoster from /torrents/availableHosts."""

    host: str
    max_file_size: int = 0
