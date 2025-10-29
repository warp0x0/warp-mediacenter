"""Utilities to interpret media filenames into structured metadata."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from guessit import guessit

from warp_mediacenter.backend.information_handlers.models import MediaType


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

    has_episode_context = season is not None or episode is not None or guess_type in {"episode", "show", "season"}

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
