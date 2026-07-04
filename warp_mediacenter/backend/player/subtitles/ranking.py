from __future__ import annotations

"""Release-aware subtitle ranking helpers."""

from pathlib import Path
from typing import Any, Iterable, Optional
from urllib.parse import unquote, urlparse
import re

from warp_mediacenter.backend.player.subtitles.models import SubtitleQuery, SubtitleResult


_RESOLUTIONS = ("2160p", "1080p", "720p", "480p")
_SOURCES = {
    "bluray": ("bluray", "blu-ray", "bdrip", "brrip", "bdremux", "uhdremux", "remux"),
    "web": ("web-dl", "webdl", "webrip", "web"),
    "hdtv": ("hdtv",),
    "dvd": ("dvd", "dvdrip"),
}
_CODECS = {
    "x265": ("x265", "h265", "hevc"),
    "x264": ("x264", "h264", "avc"),
    "av1": ("av1",),
}
_MEDIA_SUFFIXES = (".mkv", ".mp4", ".avi", ".mov", ".wmv", ".srt", ".ass", ".ssa", ".vtt", ".zip", ".gz")
_SITE_TAG_RE = re.compile(r"[\[\(][^\]\)]*(?:eztv|ettv|rarbg|tgx|torrent|x\.to|\.to|\.com)[^\]\)]*[\]\)]", re.I)
_EPISODE_RE = re.compile(r"\bS(?P<season>\d{1,2})[ ._-]*E(?P<episode>\d{1,3})\b", re.I)
_EPISODE_ALT_RE = re.compile(r"\b(?P<season>\d{1,2})x(?P<episode>\d{1,3})\b", re.I)


def _contains_any(value: str, needles: Iterable[str]) -> bool:
    return any(needle in value for needle in needles)


def _basename(value: Optional[str]) -> str:
    if not value:
        return ""
    text = unquote(str(value))
    parsed = urlparse(text)
    if parsed.scheme and parsed.path:
        return parsed.path.rsplit("/", 1)[-1].rsplit("\\", 1)[-1]
    if text.startswith("/") or re.match(r"^[A-Za-z]:[\\/]", text) or "\\" in text:
        return text.rsplit("/", 1)[-1].rsplit("\\", 1)[-1]
    if "/" in text and Path(text).suffix.lower() in _MEDIA_SUFFIXES:
        return text.rsplit("/", 1)[-1]
    return text


def _int_or_none(value: Any) -> int | None:
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _clean_group(value: str | None) -> str | None:
    if not value:
        return None
    group = _SITE_TAG_RE.sub("", value)
    group = re.sub(r"[\[\(].*$", "", group)
    group = re.sub(r"([._\s-]?(eng|english|en|sdh|hi))+$", "", group, flags=re.I)
    group = group.strip(" ._-").lower()
    if not group or len(group) > 24:
        return None
    return group


def _normalized_words(value: str | None) -> str:
    return " ".join(re.findall(r"[a-z0-9]+", (value or "").lower()))


def parse_release(value: Optional[str]) -> dict[str, Any]:
    text = _basename(value) or str(value or "")
    lower = text.lower()
    resolution = next((item for item in _RESOLUTIONS if item in lower), None)
    source = next((name for name, aliases in _SOURCES.items() if _contains_any(lower, aliases)), None)
    codec = next((name for name, aliases in _CODECS.items() if _contains_any(lower, aliases)), None)
    episode_match = _EPISODE_RE.search(text) or _EPISODE_ALT_RE.search(text)
    season = _int_or_none(episode_match.group("season")) if episode_match else None
    episode = _int_or_none(episode_match.group("episode")) if episode_match else None

    cleaned = text
    for suffix in _MEDIA_SUFFIXES:
        if cleaned.lower().endswith(suffix):
            cleaned = cleaned[: -len(suffix)]
            break
    group = None
    if "-" in cleaned:
        group = _clean_group(re.split(r"-", cleaned)[-1])

    return {
        "text": text,
        "lower": lower,
        "normalized": _normalized_words(text),
        "resolution": resolution,
        "source": source,
        "codec": codec,
        "group": group,
        "season": season,
        "episode": episode,
    }


def score_result(query: SubtitleQuery, result: SubtitleResult) -> float:
    """Set ranking metadata and return a normalized 0..1 score."""

    target = parse_release(query.media_path or query.title)
    candidate = parse_release(result.release or result.file_name)
    metadata = result.metadata
    reasons: list[str] = []
    raw = 0.0
    possible = 0.0

    expected_imdb = (query.imdb_id or "").lower().removeprefix("tt")
    candidate_imdb_values = [
        str(metadata.get("imdb_id") or "").lower().removeprefix("tt"),
        str(metadata.get("parent_imdb_id") or "").lower().removeprefix("tt"),
        str(metadata.get("series_imdb_id") or "").lower().removeprefix("tt"),
    ]
    if expected_imdb:
        possible += 35.0
    if metadata.get("exact_id_match") or (expected_imdb and expected_imdb in candidate_imdb_values):
        raw += 35.0
        reasons.append("imdb")

    expected_tmdb = str(query.tmdb_id or "").strip()
    candidate_tmdb = str(metadata.get("tmdb_id") or "").strip()
    if expected_tmdb and candidate_tmdb:
        possible += 10.0
    if expected_tmdb and candidate_tmdb and expected_tmdb == candidate_tmdb:
        raw += 10.0
        reasons.append("tmdb")

    if query.year and query.media_kind != "show":
        possible += 8.0
    if query.year and query.media_kind != "show" and (str(query.year) in candidate["lower"] or str(metadata.get("year") or "") == str(query.year)):
        raw += 8.0
        reasons.append("year")

    title_words = _normalized_words(query.title)
    if title_words:
        possible += 18.0
        if title_words in candidate["normalized"]:
            raw += 18.0
            reasons.append("title")

    for key, weight in (("resolution", 15.0), ("source", 15.0), ("codec", 12.0), ("group", 20.0)):
        if target.get(key):
            possible += weight
        if target.get(key) and candidate.get(key) and target[key] == candidate[key]:
            raw += weight
            reasons.append(str(candidate[key] if key != "group" else "group"))

    if query.media_kind == "show":
        season = _int_or_none(metadata.get("season")) or candidate.get("season")
        episode = _int_or_none(metadata.get("episode")) or candidate.get("episode")
        if query.season:
            possible += 8.0
        if query.season and season and int(season) == int(query.season):
            raw += 8.0
            reasons.append("season")
        if query.episode:
            possible += 12.0
        if query.episode and episode and int(episode) == int(query.episode):
            raw += 12.0
            reasons.append("episode")

    try:
        raw += min(float(result.rating or metadata.get("rating") or 0.0), 10.0) * 0.8
        if result.rating or metadata.get("rating"):
            reasons.append("rating")
    except (TypeError, ValueError):
        pass

    try:
        downloads = float(metadata.get("downloads") or metadata.get("download_count") or 0.0)
        raw += min(downloads, 1000.0) / 100.0
        if downloads:
            reasons.append("downloads")
    except (TypeError, ValueError):
        pass

    metadata["rank"] = {
        "raw_score": round(raw, 2),
        "reasons": reasons,
        "target": {k: target.get(k) for k in ("resolution", "source", "codec", "group")},
        "candidate": {k: candidate.get(k) for k in ("resolution", "source", "codec", "group")},
    }
    return min(1.0, raw / max(possible, 1.0))


def ranked(query: SubtitleQuery, results: list[SubtitleResult]) -> list[SubtitleResult]:
    for item in results:
        item.score = score_result(query, item)
    results.sort(key=lambda item: (-item.score, item.provider, item.file_name))
    return results
