from __future__ import annotations

"""Provider base classes and helpers."""

from abc import ABC, abstractmethod
from typing import List

from ..models import SubtitlePayload, SubtitleQuery, SubtitleResult
from ...exceptions import SubtitleProviderUnavailable
from ...common.logging import get_logger

log = get_logger(__name__)


class SubtitleProvider(ABC):
    name: str = "provider"
    media_kinds: tuple[str, ...] = ("movie", "show")
    retries: int = 1
    backoff_sec: float = 1.0

    def is_available_for(self, media_kind: str) -> bool:
        if media_kind not in self.media_kinds:
            return False
        return self.is_configured

    @property
    def is_configured(self) -> bool:
        return True

    @abstractmethod
    def search(self, query: SubtitleQuery) -> List[SubtitleResult]:
        raise NotImplementedError

    @abstractmethod
    def download(self, result: SubtitleResult) -> SubtitlePayload:
        raise NotImplementedError


def ensure_api_key(name: str, value: str | None) -> str:
    if not value:
        raise SubtitleProviderUnavailable(f"{name} API credentials missing")
    return value
