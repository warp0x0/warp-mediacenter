"""The one place a catalog row's wire shape is decided.

Every catalog row the client renders — TMDb, legacy Trakt, a plugin, Continue
Watching — passes through here.  Before this module the conversion existed three
times (``routes/discovery.py`` twice, ``routes/trakt.py`` once) and had already
drifted: one copy flattened ``poster_path`` and built the nested ``media`` block,
one built ``media`` from raw TMDb fields, and one did neither.

The shape itself is not pretty and is deliberately preserved rather than cleaned
up.  It carries the same values three ways:

* top-level ``poster_path`` / ``backdrop_path`` — what the poster cards read,
* ``extra.ids`` plus flattened ``tmdb_id`` / ``trakt_id`` — what navigation reads,
* a nested ``media`` block duplicating title/year/artwork — what the hero header
  and ribbon cards read (``widget_section.dart``, ``poster_card.dart``).

Changing it means changing Flutter widgets in lockstep, so new sources adopt it
as-is.  Adding a *source* must never require a client change; that is the whole
point of routing everything through one function.
"""

from __future__ import annotations

from typing import Any, Dict, List, Mapping, Optional

__all__ = [
    "catalog_item_to_dict",
    "media_block",
    "tmdb_result_to_dict",
]


def _year_from_date(value: Any) -> Optional[int]:
    text = str(value or "")
    if len(text) < 4:
        return None
    try:
        return int(text[:4])
    except (TypeError, ValueError):
        return None


def media_block(item: Mapping[str, Any]) -> Dict[str, Any]:
    """The nested ``media`` block the Flutter cards read.

    ``title`` is duplicated into ``name`` because the client reads whichever the
    TMDb endpoint for that media type would have used (``title`` for movies,
    ``name`` for shows) and normalising it here means the cards never have to
    know which source produced the row.
    """

    genres = item.get("genres") or []
    return {
        "id": item.get("id"),
        "title": item.get("title"),
        "name": item.get("title"),
        "year": item.get("year"),
        "overview": item.get("overview"),
        "poster_path": item.get("poster_path"),
        "backdrop_path": item.get("backdrop_path"),
        "rating": item.get("rating"),
        "genres": [
            g if isinstance(g, Mapping) else {"name": g} for g in genres
        ],
    }


def catalog_item_to_dict(item: Any) -> Dict[str, Any]:
    """Convert a ``CatalogItem`` (or a plain dict) into the client wire shape.

    Accepts a Pydantic ``CatalogItem``, a mapping, or anything dict-like, because
    the three call sites this replaces each fed it something different.
    """

    if hasattr(item, "model_dump"):
        d: Dict[str, Any] = item.model_dump(mode="json")
    elif isinstance(item, Mapping):
        d = dict(item)
    else:
        d = dict(item) if hasattr(item, "__iter__") else {}

    extra = d.get("extra")
    raw = extra.get("raw_payload") if isinstance(extra, Mapping) else None
    if not isinstance(raw, Mapping):
        raw = {}

    # Artwork, in preference order: whatever the source already flattened onto
    # raw_payload, then the structured ImageAsset, then a bare string poster.
    if raw.get("poster_path"):
        d["poster_path"] = raw.get("poster_path")
    if raw.get("backdrop_path"):
        d["backdrop_path"] = raw.get("backdrop_path")

    poster = d.get("poster")
    if isinstance(poster, Mapping):
        if not d.get("poster_path"):
            d["poster_path"] = (
                poster.get("medium") or poster.get("large") or poster.get("original")
            )
        if not d.get("backdrop_path"):
            d["backdrop_path"] = poster.get("original")
    elif isinstance(poster, str) and not d.get("poster_path"):
        d["poster_path"] = poster

    # Ids.  TMDb is the app's canonical key — navigation, artwork and progress
    # all resolve on it — so it is flattened even when the source is not TMDb.
    ids = extra.get("ids") if isinstance(extra, Mapping) else None
    if isinstance(ids, Mapping):
        d["tmdb_id"] = ids.get("tmdb")
        d["trakt_id"] = ids.get("trakt")
    if not d.get("tmdb_id") and raw.get("id"):
        d["tmdb_id"] = str(raw.get("id"))
    if not d.get("trakt_id"):
        d["trakt_id"] = raw.get("trakt_slug") or raw.get("slug")

    d["media"] = media_block(d)
    return d


def tmdb_result_to_dict(
    result: Mapping[str, Any], media_type: str
) -> Dict[str, Any]:
    """Convert a raw TMDb API result into the same wire shape.

    Used where the response never became a ``CatalogItem`` — collection parts and
    the recommendations/similar fan-out behind "Based on what you watched".
    """

    tmdb_id = str(result.get("id") or "")
    title = result.get("title") or result.get("name") or ""
    year = _year_from_date(
        result.get("release_date") or result.get("first_air_date")
    )
    genres: List[Any] = []

    item: Dict[str, Any] = {
        "id": tmdb_id,
        "title": title,
        "type": media_type,
        "year": year,
        "overview": result.get("overview"),
        "poster_path": result.get("poster_path"),
        "backdrop_path": result.get("backdrop_path"),
        "rating": result.get("vote_average"),
        "genres": genres,
        "tmdb_id": tmdb_id,
        "trakt_id": None,
        "source_tag": "tmdb",
        "extra": {"raw_payload": dict(result), "ids": {"tmdb": tmdb_id}},
    }
    item["media"] = media_block(item)
    return item
