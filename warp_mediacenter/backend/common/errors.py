from __future__ import annotations



class WarpError(Exception):
    """Base for all Warp MediaCenter exceptions."""


class ConfigError(WarpError):
    """Configuration related issues."""


class TaskError(WarpError):
    """Task scheduling/execution issues."""


class NetworkError(WarpError):
    """Network/HTTP layer issues."""


class ProviderError(WarpError):
    """Info-provider (TMDb/Trakt/RD) issues."""
