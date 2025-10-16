from __future__ import annotations

"""Dataclasses used across subtitle providers."""

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Iterable, Optional


@dataclass(slots=True)
class SubtitleQuery:
    title: str
    media_kind: str  # "movie" | "show"
    language: str = "eng"
    season: Optional[int] = None
    episode: Optional[int] = None
    year: Optional[int] = None
    release_group: Optional[str] = None
    media_path: Optional[Path] = None
    is_stream: bool = False


@dataclass(slots=True)
class SubtitleResult:
    provider: str
    language: str
    score: float
    release: str
    download_link: str
    file_name: str
    hearing_impaired: bool = False
    rating: Optional[float] = None
    uploaded_at: Optional[datetime] = None
    metadata: dict[str, object] = field(default_factory=dict)

    def as_dict(self) -> dict[str, object]:
        return {
            "provider": self.provider,
            "language": self.language,
            "score": self.score,
            "release": self.release,
            "download_link": self.download_link,
            "file_name": self.file_name,
            "hearing_impaired": self.hearing_impaired,
            "rating": self.rating,
            "uploaded_at": self.uploaded_at.isoformat() if self.uploaded_at else None,
            "metadata": self.metadata,
        }


@dataclass(slots=True)
class SubtitlePayload:
    file_name: str
    content: bytes
    mime_type: Optional[str] = None


PREFERRED_EXTENSIONS: tuple[str, ...] = (".srt", ".ass", ".ssa", ".vtt", ".sub", ".sbv", ".txt")


def normalize_extension(name: str) -> str:
    suffix = Path(name).suffix.lower()
    return suffix


def pick_best_subtitle_file(paths: Iterable[Path]) -> Optional[Path]:
    prioritized = list(PREFERRED_EXTENSIONS)
    by_extension: dict[str, Path] = {}
    for p in paths:
        by_extension[p.suffix.lower()] = p
    for ext in prioritized:
        if ext in by_extension:
            return by_extension[ext]
    return next(iter(by_extension.values()), None)
