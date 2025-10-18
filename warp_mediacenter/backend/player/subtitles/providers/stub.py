from __future__ import annotations

"""Stub implementations for providers that require interactive auth or scraping."""

from typing import List

from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.player.subtitles.models import (
    SubtitlePayload,
    SubtitleQuery,
    SubtitleResult,
)
from warp_mediacenter.backend.player.subtitles.providers.base import SubtitleProvider

log = get_logger(__name__)


class _DisabledProvider(SubtitleProvider):
    reason: str = ""

    @property
    def is_configured(self) -> bool:  # type: ignore[override]
        return False

    def search(self, query: SubtitleQuery) -> List[SubtitleResult]:  # type: ignore[override]
        log.debug("subtitle_provider_disabled", provider=self.name, reason=self.reason)
        return []

    def download(self, result: SubtitleResult) -> SubtitlePayload:  # type: ignore[override]
        raise RuntimeError(f"Provider {self.name} is disabled: {self.reason}")


class PodnapisiProvider(_DisabledProvider):
    name = "podnapisi"
    reason = "API integration pending credentials"


class BSPlayerProvider(_DisabledProvider):
    name = "bsplayer"
    reason = "API integration pending"


class SubsceneProvider(_DisabledProvider):
    name = "subscene"
    reason = "Requires authenticated scraping with proxy"


class Addic7edProvider(_DisabledProvider):
    name = "addic7ed"
    media_kinds = ("show",)
    reason = "Requires authenticated session"
