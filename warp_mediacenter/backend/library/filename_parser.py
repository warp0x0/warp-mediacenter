"""Utilities to interpret media filenames into structured metadata."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from guessit import guessit

from warp_mediacenter.backend.information_handlers.models import MediaType

# Matches an explicit episode indicator in a filename.  Only when one of these
# patterns appears do we trust guessit's season/episode values.  This prevents
# codec/resolution tokens like "1080" from being mis-parsed as S10E80, or
# numeric title fragments like "1.2.3" from implying an episode.
_EXPLICIT_EPISODE_RE = re.compile(
    r'[Ss]\d{1,2}[Ee]\d{1,3}'   # S01E01 / S1E1
    r'|\b\d{1,2}[xX]\d{1,3}\b'  # 1x01 / 01x01
    r'|\bseason\s*\d+\b',        # Season 2 / season2
    re.IGNORECASE,
)


@dataclass(frozen=True)
class ParsedName:
    """Structured information extracted from a filename."""

    media_type: MediaType
    title: str
    year: Optional[int] = None
    season: Optional[int] = None
    episode: Optional[int] = None


def parse_media_name(path: Path) -> Optional[ParsedName]:
    """Infer the media title/episode metadata from a filesystem entry."""

    details = guessit(path.name)
    title = _coerce_str(details.get("title"))

    # Bracket-title rescue: guessit treats "[Rec]" as release_group, leaving
    # title=None.  When the filename starts with [Something], use it as title.
    if not title:
        m = re.match(r'^\[(.+?)\]', path.name)
        if m:
            title = m.group(1).strip() or None

    if not title:
        return None

    year = _coerce_int(details.get("year"))

    season_value = details.get("season")
    episode_value = details.get("episode")

    season = _coerce_int(season_value)
    episode = _coerce_int(episode_value)

    guess_type = _coerce_str(details.get("type")) or ""
    guess_type = guess_type.lower()

    if season is None and isinstance(season_value, (list, tuple)):
        season = _coerce_int(season_value[0])
    if episode is None and isinstance(episode_value, (list, tuple)):
        episode = _coerce_int(episode_value[0])

    # Require an explicit SxxExx / NxN / "Season N" pattern before classifying
    # as a show.  Tokens like "1080.264" produce season=10, episode=80 in guessit
    # but have no explicit marker — those files fall back to movie lookup.
    explicit_show = bool(_EXPLICIT_EPISODE_RE.search(path.name))
    has_episode_context = explicit_show and (season is not None or episode is not None)

    if has_episode_context:
        media_type = MediaType.SHOW
    else:
        media_type = MediaType.MOVIE
        season = None
        episode = None

    return ParsedName(
        media_type=media_type,
        title=title,
        year=year,
        season=season,
        episode=episode,
    )


def _coerce_int(value: object) -> Optional[int]:
    if value is None:
        return None
    if isinstance(value, bool):
        return None
    if isinstance(value, (list, tuple)):
        for entry in value:
            candidate = _coerce_int(entry)
            if candidate is not None:
                return candidate
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _coerce_str(value: object) -> Optional[str]:
    if value is None:
        return None
    if isinstance(value, str):
        stripped = value.strip()
        return stripped or None
    return str(value).strip() or None


__all__ = ["ParsedName", "parse_media_name"]
