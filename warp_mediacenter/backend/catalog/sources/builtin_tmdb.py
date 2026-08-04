"""TMDb — the built-in catalog source.

TMDb is not a plugin and never becomes one: it is the metadata backbone the whole
app keys on (every row's ``tmdb_id`` drives navigation, artwork and progress), so
it is always present and cannot be disabled.  What *does* change here is that its
list catalogue moves server-side.

Until now the enumeration of TMDb lists lived only in
``flutter_client/lib/api/catalog_constants.dart`` as compiled-in Dart constants,
while the code that turned a list id into a TMDb path lived in
``tmdb_manager._catalog_path``.  Two halves of one fact, in two languages, kept in
sync by hand.  ``LIST_DEFS`` below is the single declaration; the Settings picker
now reads it over HTTP.

The ids are unchanged (``trending_day``, ``genre_27``, ``decade_1990``) so every
saved widget config keeps resolving.  ``_catalog_path`` still parses the
``genre_``/``decade_`` prefixes — moving that to ``params`` would break stored
configs for no user-visible gain, so ids stay as they are and ``params`` is left
empty for this source.
"""

from __future__ import annotations

from typing import Any, Dict, List, Mapping, Optional, Sequence

from warp_mediacenter.backend.catalog.normalize import catalog_item_to_dict
from warp_mediacenter.backend.catalog.sources.base import KIND_BUILTIN, SourcePage
from warp_mediacenter.backend.common.logging import get_logger
from warp_mediacenter.backend.information_handlers.models import MediaType
from warp_mediacenter.backend.plugins.contracts.catalog import (
    GROUP_DECADE,
    GROUP_DISCOVER,
    GROUP_GENRE,
    GROUP_STANDARD,
    CatalogListDef,
)

log = get_logger(__name__)

SOURCE_ID = "tmdb"

#: TMDb serves 20 items per page and caps ``total_pages`` at 500.
PAGE_SIZE = 20

_MOVIE = ["movie"]
_SHOW = ["show"]
_BOTH = ["movie", "show"]


def _d(
    list_id: str,
    title: str,
    description: str,
    group: str,
    media_types: List[str],
) -> CatalogListDef:
    return CatalogListDef(
        id=list_id,
        title=title,
        description=description,
        group=group,
        media_types=list(media_types),
        supports_pagination=True,
        page_size=PAGE_SIZE,
    )


#: Every list TMDb publishes.  ``media_types`` is what makes this one table
#: instead of the two Dart lists it replaces — ``popular`` served both, and the
#: duplication was where the two copies had already drifted apart.
LIST_DEFS: tuple[CatalogListDef, ...] = (
    # ── Standard ──────────────────────────────────────────────────────────
    _d("trending_day", "Trending Today", "Most-watched in the past 24 hours", GROUP_STANDARD, _BOTH),
    _d("trending_week", "Trending This Week", "Most-watched over the past 7 days", GROUP_STANDARD, _BOTH),
    _d("popular", "Popular", "Consistently popular titles on TMDb", GROUP_STANDARD, _BOTH),
    _d("top_rated", "Top Rated", "Highest user-rated of all time", GROUP_STANDARD, _BOTH),
    _d("now_playing", "Now Playing", "Currently showing in theatres", GROUP_STANDARD, _MOVIE),
    _d("upcoming", "Upcoming", "Movies arriving in theatres soon", GROUP_STANDARD, _MOVIE),
    _d("airing_today", "Airing Today", "Shows with episodes airing today", GROUP_STANDARD, _SHOW),
    _d("on_the_air", "On The Air", "Shows currently airing new episodes", GROUP_STANDARD, _SHOW),
    # ── Discover ──────────────────────────────────────────────────────────
    _d("discover_revenue", "Highest Revenue", "All-time top earners at the box office", GROUP_DISCOVER, _MOVIE),
    _d("discover_most_voted", "Most Voted", "Most user votes — widest audience reach", GROUP_DISCOVER, _BOTH),
    _d("discover_best_rated", "Best Rated", "Highest average score, vote-count filtered", GROUP_DISCOVER, _BOTH),
    _d("discover_latest", "Latest Releases", "Most recently released first", GROUP_DISCOVER, _BOTH),
    # ── By genre — movies ─────────────────────────────────────────────────
    _d("genre_28", "Action", "High-octane action & spectacle", GROUP_GENRE, _MOVIE),
    _d("genre_12", "Adventure", "Journeys, quests & exploration", GROUP_GENRE, _MOVIE),
    _d("genre_80", "Crime", "Heists, detectives & underworld drama", GROUP_GENRE, _BOTH),
    _d("genre_99", "Documentary", "Real-world stories & non-fiction", GROUP_GENRE, _BOTH),
    _d("genre_18", "Drama", "Character-driven emotional stories", GROUP_GENRE, _BOTH),
    _d("genre_14", "Fantasy", "Magic, myths & otherworldly adventures", GROUP_GENRE, _MOVIE),
    _d("genre_36", "History", "Events & figures from the past", GROUP_GENRE, _MOVIE),
    _d("genre_27", "Horror", "Fear, dread & the supernatural", GROUP_GENRE, _MOVIE),
    _d("genre_10402", "Music", "Concerts, biopics & musical stories", GROUP_GENRE, _MOVIE),
    _d("genre_10749", "Romance", "Love stories & relationships", GROUP_GENRE, _MOVIE),
    _d("genre_878", "Science Fiction", "Future worlds, tech & space", GROUP_GENRE, _MOVIE),
    _d("genre_10770", "TV Movie", "Films made for television", GROUP_GENRE, _MOVIE),
    _d("genre_53", "Thriller", "Suspense, tension & nail-biters", GROUP_GENRE, _MOVIE),
    _d("genre_10752", "War", "Conflict, sacrifice & heroism", GROUP_GENRE, _MOVIE),
    # ── By genre — shared / shows ─────────────────────────────────────────
    _d("genre_16", "Animation", "Animated titles for all ages", GROUP_GENRE, _BOTH),
    _d("genre_35", "Comedy", "Light-hearted laughs & humour", GROUP_GENRE, _BOTH),
    _d("genre_10751", "Family", "Fun for the whole family", GROUP_GENRE, _BOTH),
    _d("genre_9648", "Mystery", "Puzzles, secrets & whodunits", GROUP_GENRE, _BOTH),
    _d("genre_37", "Western", "The frontier, outlaws & gunslingers", GROUP_GENRE, _BOTH),
    _d("genre_10759", "Action & Adventure", "Action-packed adventure series", GROUP_GENRE, _SHOW),
    _d("genre_10762", "Kids", "Shows made for younger audiences", GROUP_GENRE, _SHOW),
    _d("genre_10763", "News", "News and current affairs", GROUP_GENRE, _SHOW),
    _d("genre_10764", "Reality", "Reality TV & unscripted entertainment", GROUP_GENRE, _SHOW),
    _d("genre_10765", "Sci-Fi & Fantasy", "Science fiction & fantasy worlds", GROUP_GENRE, _SHOW),
    _d("genre_10766", "Soap", "Ongoing dramatic serial storytelling", GROUP_GENRE, _SHOW),
    _d("genre_10767", "Talk", "Talk shows & interview programmes", GROUP_GENRE, _SHOW),
    _d("genre_10768", "War & Politics", "Political drama & war narratives", GROUP_GENRE, _SHOW),
    # ── By decade ─────────────────────────────────────────────────────────
    _d("decade_2020", "2020s", "Released from 2020 onwards", GROUP_DECADE, _BOTH),
    _d("decade_2010", "2010s", "Released 2010 to 2019", GROUP_DECADE, _BOTH),
    _d("decade_2000", "2000s", "Released 2000 to 2009", GROUP_DECADE, _BOTH),
    _d("decade_1990", "1990s", "Released 1990 to 1999", GROUP_DECADE, _BOTH),
    _d("decade_1980", "1980s", "Released 1980 to 1989", GROUP_DECADE, _BOTH),
    _d("decade_1970", "1970s", "Released 1970 to 1979", GROUP_DECADE, _BOTH),
    _d("decade_1960", "1960s", "Released 1960 to 1969", GROUP_DECADE, _MOVIE),
)


class BuiltinTmdbSource:
    """Adapts ``TMDbManager.catalog_page`` to the source interface."""

    id = SOURCE_ID
    label = "TMDb"
    kind = KIND_BUILTIN
    icon = "movie_outlined"

    def __init__(self, providers: Any) -> None:
        self._providers = providers

    def list_definitions(self) -> Sequence[CatalogListDef]:
        return LIST_DEFS

    def fetch_page(
        self,
        list_id: str,
        *,
        media_type: str,
        params: Mapping[str, Any],
        page: int,
        page_size: int = PAGE_SIZE,
    ) -> SourcePage:
        mt = MediaType.MOVIE if media_type == "movie" else MediaType.SHOW
        language: Optional[str] = None
        if isinstance(params, Mapping):
            raw_language = params.get("language")
            if raw_language:
                language = str(raw_language)

        items, info = self._providers.tmdb.catalog_page(
            mt, list_id, language=language, page=page
        )
        dicts: List[Dict[str, Any]] = [catalog_item_to_dict(item) for item in items]

        total_pages = info.get("total_pages")
        total_results = info.get("total_results")

        # Prefer the page counter: TMDb clamps `total_pages` to 500 but keeps
        # reporting the true `total_results`, so trusting the count alone would
        # keep asking for pages past 500 that come back empty forever.
        if isinstance(total_pages, int):
            has_more = page < total_pages
        else:
            has_more = len(dicts) >= PAGE_SIZE

        return SourcePage(
            items=dicts,
            has_more=has_more,
            total=total_results if isinstance(total_results, int) else None,
        )


__all__ = ["LIST_DEFS", "PAGE_SIZE", "SOURCE_ID", "BuiltinTmdbSource"]
