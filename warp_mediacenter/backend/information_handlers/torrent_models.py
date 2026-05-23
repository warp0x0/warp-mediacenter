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
    """Aggregated torrent search response split by cache status."""

    cached: List[TorrentResult] = field(default_factory=list)
    uncached: List[TorrentResult] = field(default_factory=list)
    query: str = ""
    media_type: str = ""
    total_results: int = 0

    @property
    def all_results(self) -> List[TorrentResult]:
        return self.cached + self.uncached

    def to_dict(self) -> dict:
        def _serialize(t: TorrentResult) -> dict:
            return {
                "name": t.name,
                "magnet": t.magnet,
                "hash": t.hash,
                "seeders": t.seeders,
                "leechers": t.leechers,
                "size": t.size,
                "size_bytes": t.size_bytes,
                "source_site": t.source_site,
                "quality": t.quality,
                "is_cached": t.is_cached,
                "uploader": t.uploader,
                "date": t.date,
                "match_score": round(t.match_score, 3),
            }

        return {
            "cached": [_serialize(t) for t in self.cached],
            "uncached": [_serialize(t) for t in self.uncached],
            "query": self.query,
            "media_type": self.media_type,
            "total_results": self.total_results,
        }
