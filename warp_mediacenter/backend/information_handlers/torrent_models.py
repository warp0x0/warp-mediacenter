"""Data models for torrent search results."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import List


@dataclass(slots=True)
class TorrentResult:
    """A single torrent search result."""

    name: str
    magnet: str
    hash: str
    seeders: int
    leechers: int
    size: str
    size_bytes: int
    source_site: str
    quality: str
    is_cached: bool = False
    uploader: str = ""
    date: str = ""
    match_score: float = 0.0


@dataclass(slots=True)
class TorrentSearchResponse:
    """Aggregated torrent search response.

    filtered   — results that passed the RD-exclusion filter (safe to send to RD).
    unfiltered — results before the RD-exclusion step (broader, but some may fail RD).
    Both lists are already sorted: quality bracket first (4K→1080p→720p→Unknown),
    then file size descending within each bracket.
    """

    filtered:   List[TorrentResult] = field(default_factory=list)
    unfiltered: List[TorrentResult] = field(default_factory=list)
    query:      str = ""
    media_type: str = ""

    def to_dict(self) -> dict:
        def _serialize(t: TorrentResult) -> dict:
            return {
                "name":        t.name,
                "magnet":      t.magnet,
                "hash":        t.hash,
                "seeders":     t.seeders,
                "leechers":    t.leechers,
                "size":        t.size,
                "size_bytes":  t.size_bytes,
                "source_site": t.source_site,
                "quality":     t.quality,
                "is_cached":   t.is_cached,
                "uploader":    t.uploader,
                "date":        t.date,
                "match_score": round(t.match_score, 3),
            }

        return {
            "filtered":   [_serialize(t) for t in self.filtered],
            "unfiltered": [_serialize(t) for t in self.unfiltered],
            "query":      self.query,
            "media_type": self.media_type,
        }
