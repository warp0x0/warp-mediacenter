from __future__ import annotations

"""Exceptions for the player subsystem."""


class PlayerError(Exception):
    """Top-level error raised by the player subsystem."""


class SubtitleError(PlayerError):
    """Raised when subtitle discovery or download fails."""


class SubtitleProviderUnavailable(SubtitleError):
    """Raised when a specific provider cannot service the request."""


class SubtitleDownloadError(SubtitleError):
    """Raised when a provider returns an invalid archive or payload."""
