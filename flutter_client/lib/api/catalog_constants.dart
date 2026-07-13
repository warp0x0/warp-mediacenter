import '../models/catalog.dart';

const kImageBase = 'https://image.tmdb.org/t/p';

// ─────────────────────────────────────────────────────────────────────────────
// Catalog source definitions — mirrors frontend/src/lib/constants.ts
// ─────────────────────────────────────────────────────────────────────────────

enum CatalogGroup { standard, discover, genre, decade }

class CatalogDef {
  final String id;
  final String label;
  final String description;
  final CatalogGroup group;
  const CatalogDef({
    required this.id,
    required this.label,
    required this.description,
    required this.group,
  });
}

const kCatalogGroupLabels = {
  CatalogGroup.standard: 'STANDARD LISTS',
  CatalogGroup.discover: 'DISCOVER',
  CatalogGroup.genre:    'BY GENRE',
  CatalogGroup.decade:   'BY DECADE',
};

// ── TMDb Movie Catalogs (36) ──────────────────────────────────────────────────

const kTmdbMovieCatalogs = [
  // Standard (6)
  CatalogDef(id: 'trending_day',  label: 'Trending Today',      description: 'Most-watched movies in the past 24 hours',   group: CatalogGroup.standard),
  CatalogDef(id: 'trending_week', label: 'Trending This Week',  description: 'Most-watched movies over the past 7 days',    group: CatalogGroup.standard),
  CatalogDef(id: 'now_playing',   label: 'Now Playing',         description: 'Currently showing in theatres',               group: CatalogGroup.standard),
  CatalogDef(id: 'popular',       label: 'Popular',             description: 'Consistently popular titles on TMDb',         group: CatalogGroup.standard),
  CatalogDef(id: 'top_rated',     label: 'Top Rated',           description: 'Highest user-rated movies of all time',       group: CatalogGroup.standard),
  CatalogDef(id: 'upcoming',      label: 'Upcoming',            description: 'Movies arriving in theatres soon',            group: CatalogGroup.standard),
  // Discover (4)
  CatalogDef(id: 'discover_revenue',    label: 'Highest Revenue',  description: 'All-time top earners at the box office',      group: CatalogGroup.discover),
  CatalogDef(id: 'discover_most_voted', label: 'Most Voted',       description: 'Most user votes — widest audience reach',     group: CatalogGroup.discover),
  CatalogDef(id: 'discover_best_rated', label: 'Best Rated',       description: 'Highest average score (300+ votes)',          group: CatalogGroup.discover),
  CatalogDef(id: 'discover_latest',     label: 'Latest Releases',  description: 'Most recently released movies first',         group: CatalogGroup.discover),
  // By Genre (19)
  CatalogDef(id: 'genre_28',    label: 'Action',          description: 'High-octane action & spectacle',           group: CatalogGroup.genre),
  CatalogDef(id: 'genre_12',    label: 'Adventure',       description: 'Journeys, quests & exploration',           group: CatalogGroup.genre),
  CatalogDef(id: 'genre_16',    label: 'Animation',       description: 'Animated films for all ages',              group: CatalogGroup.genre),
  CatalogDef(id: 'genre_35',    label: 'Comedy',          description: 'Light-hearted laughs & humour',            group: CatalogGroup.genre),
  CatalogDef(id: 'genre_80',    label: 'Crime',           description: 'Heists, detectives & underworld drama',    group: CatalogGroup.genre),
  CatalogDef(id: 'genre_99',    label: 'Documentary',     description: 'Real-world stories & non-fiction',         group: CatalogGroup.genre),
  CatalogDef(id: 'genre_18',    label: 'Drama',           description: 'Character-driven emotional stories',       group: CatalogGroup.genre),
  CatalogDef(id: 'genre_10751', label: 'Family',          description: 'Fun for the whole family',                 group: CatalogGroup.genre),
  CatalogDef(id: 'genre_14',    label: 'Fantasy',         description: 'Magic, myths & otherworldly adventures',  group: CatalogGroup.genre),
  CatalogDef(id: 'genre_36',    label: 'History',         description: 'Events & figures from the past',          group: CatalogGroup.genre),
  CatalogDef(id: 'genre_27',    label: 'Horror',          description: 'Fear, dread & the supernatural',          group: CatalogGroup.genre),
  CatalogDef(id: 'genre_10402', label: 'Music',           description: 'Concerts, biopics & musical stories',     group: CatalogGroup.genre),
  CatalogDef(id: 'genre_9648',  label: 'Mystery',         description: 'Puzzles, secrets & whodunits',            group: CatalogGroup.genre),
  CatalogDef(id: 'genre_10749', label: 'Romance',         description: 'Love stories & relationships',            group: CatalogGroup.genre),
  CatalogDef(id: 'genre_878',   label: 'Science Fiction', description: 'Future worlds, tech & space',             group: CatalogGroup.genre),
  CatalogDef(id: 'genre_10770', label: 'TV Movie',        description: 'Films made for television',               group: CatalogGroup.genre),
  CatalogDef(id: 'genre_53',    label: 'Thriller',        description: 'Suspense, tension & nail-biters',         group: CatalogGroup.genre),
  CatalogDef(id: 'genre_10752', label: 'War',             description: 'Conflict, sacrifice & heroism',           group: CatalogGroup.genre),
  CatalogDef(id: 'genre_37',    label: 'Western',         description: 'The frontier, outlaws & gunslingers',     group: CatalogGroup.genre),
  // By Decade (7)
  CatalogDef(id: 'decade_2020', label: '2020s', description: 'Films from 2020 to today',   group: CatalogGroup.decade),
  CatalogDef(id: 'decade_2010', label: '2010s', description: 'Films from 2010 to 2019',    group: CatalogGroup.decade),
  CatalogDef(id: 'decade_2000', label: '2000s', description: 'Films from 2000 to 2009',    group: CatalogGroup.decade),
  CatalogDef(id: 'decade_1990', label: '1990s', description: 'Films from 1990 to 1999',    group: CatalogGroup.decade),
  CatalogDef(id: 'decade_1980', label: '1980s', description: 'Films from 1980 to 1989',    group: CatalogGroup.decade),
  CatalogDef(id: 'decade_1970', label: '1970s', description: 'Films from 1970 to 1979',    group: CatalogGroup.decade),
  CatalogDef(id: 'decade_1960', label: '1960s', description: 'Films from 1960 to 1969',    group: CatalogGroup.decade),
];

// ── TMDb Show Catalogs (31) ───────────────────────────────────────────────────

const kTmdbShowCatalogs = [
  // Standard (6)
  CatalogDef(id: 'trending_day',  label: 'Trending Today',     description: 'Most-watched shows in the past 24 hours',   group: CatalogGroup.standard),
  CatalogDef(id: 'trending_week', label: 'Trending This Week', description: 'Most-watched shows over the past 7 days',    group: CatalogGroup.standard),
  CatalogDef(id: 'airing_today',  label: 'Airing Today',       description: 'Shows with episodes airing today',           group: CatalogGroup.standard),
  CatalogDef(id: 'on_the_air',    label: 'On The Air',         description: 'Shows currently airing new episodes',        group: CatalogGroup.standard),
  CatalogDef(id: 'popular',       label: 'Popular',            description: 'Consistently popular shows on TMDb',         group: CatalogGroup.standard),
  CatalogDef(id: 'top_rated',     label: 'Top Rated',          description: 'Highest user-rated shows of all time',       group: CatalogGroup.standard),
  // Discover (3)
  CatalogDef(id: 'discover_most_voted', label: 'Most Voted',    description: 'Most user votes — widest audience reach',  group: CatalogGroup.discover),
  CatalogDef(id: 'discover_best_rated', label: 'Best Rated',    description: 'Highest average score (300+ votes)',        group: CatalogGroup.discover),
  CatalogDef(id: 'discover_latest',     label: 'Latest Shows',  description: 'Most recently released shows first',       group: CatalogGroup.discover),
  // By Genre (16)
  CatalogDef(id: 'genre_10759', label: 'Action & Adventure', description: 'Action-packed adventure series',             group: CatalogGroup.genre),
  CatalogDef(id: 'genre_16',    label: 'Animation',          description: 'Animated series for all ages',               group: CatalogGroup.genre),
  CatalogDef(id: 'genre_35',    label: 'Comedy',             description: 'Light-hearted laughs & humour',              group: CatalogGroup.genre),
  CatalogDef(id: 'genre_80',    label: 'Crime',              description: 'Heists, detectives & underworld drama',      group: CatalogGroup.genre),
  CatalogDef(id: 'genre_99',    label: 'Documentary',        description: 'Real-world stories & non-fiction',           group: CatalogGroup.genre),
  CatalogDef(id: 'genre_18',    label: 'Drama',              description: 'Character-driven emotional stories',         group: CatalogGroup.genre),
  CatalogDef(id: 'genre_10751', label: 'Family',             description: 'Fun for the whole family',                   group: CatalogGroup.genre),
  CatalogDef(id: 'genre_10762', label: 'Kids',               description: 'Shows made for younger audiences',           group: CatalogGroup.genre),
  CatalogDef(id: 'genre_9648',  label: 'Mystery',            description: 'Puzzles, secrets & whodunits',              group: CatalogGroup.genre),
  CatalogDef(id: 'genre_10763', label: 'News',               description: 'News and current affairs',                  group: CatalogGroup.genre),
  CatalogDef(id: 'genre_10764', label: 'Reality',            description: 'Reality TV & unscripted entertainment',     group: CatalogGroup.genre),
  CatalogDef(id: 'genre_10765', label: 'Sci-Fi & Fantasy',   description: 'Science fiction & fantasy worlds',          group: CatalogGroup.genre),
  CatalogDef(id: 'genre_10766', label: 'Soap',               description: 'Ongoing dramatic serial storytelling',      group: CatalogGroup.genre),
  CatalogDef(id: 'genre_10767', label: 'Talk',               description: 'Talk shows & interview programmes',         group: CatalogGroup.genre),
  CatalogDef(id: 'genre_10768', label: 'War & Politics',     description: 'Political drama & war narratives',          group: CatalogGroup.genre),
  CatalogDef(id: 'genre_37',    label: 'Western',            description: 'The frontier, outlaws & gunslingers',       group: CatalogGroup.genre),
  // By Decade (6)
  CatalogDef(id: 'decade_2020', label: '2020s', description: 'Shows from 2020 to today',  group: CatalogGroup.decade),
  CatalogDef(id: 'decade_2010', label: '2010s', description: 'Shows from 2010 to 2019',   group: CatalogGroup.decade),
  CatalogDef(id: 'decade_2000', label: '2000s', description: 'Shows from 2000 to 2009',   group: CatalogGroup.decade),
  CatalogDef(id: 'decade_1990', label: '1990s', description: 'Shows from 1990 to 1999',   group: CatalogGroup.decade),
  CatalogDef(id: 'decade_1980', label: '1980s', description: 'Shows from 1980 to 1989',   group: CatalogGroup.decade),
  CatalogDef(id: 'decade_1970', label: '1970s', description: 'Shows from 1970 to 1979',   group: CatalogGroup.decade),
];

// ── Trakt Catalogs (6 each) ───────────────────────────────────────────────────

const kTraktMovieCatalogs = [
  CatalogDef(id: 'continue_watching',  label: 'Continue Watching',  description: 'Pick up where you left off',                group: CatalogGroup.standard),
  CatalogDef(id: 'based_on_watched',   label: 'Based on Watched',   description: 'Personalised based on your history',        group: CatalogGroup.standard),
  CatalogDef(id: 'trending',           label: 'Trending',           description: 'What Trakt users are watching right now',   group: CatalogGroup.standard),
  CatalogDef(id: 'popular',            label: 'Popular',            description: 'Most popular on Trakt',                     group: CatalogGroup.standard),
  CatalogDef(id: 'watched',            label: 'Most Watched',       description: 'Most plays by Trakt users',                 group: CatalogGroup.standard),
  CatalogDef(id: 'anticipated',        label: 'Anticipated',        description: 'Most anticipated upcoming titles',          group: CatalogGroup.standard),
];

const kTraktShowCatalogs = [
  CatalogDef(id: 'continue_watching',  label: 'Continue Watching',  description: 'Pick up where you left off',                group: CatalogGroup.standard),
  CatalogDef(id: 'based_on_watched',   label: 'Based on Watched',   description: 'Personalised based on your history',        group: CatalogGroup.standard),
  CatalogDef(id: 'trending',           label: 'Trending',           description: 'What Trakt users are watching right now',   group: CatalogGroup.standard),
  CatalogDef(id: 'popular',            label: 'Popular',            description: 'Most popular on Trakt',                     group: CatalogGroup.standard),
  CatalogDef(id: 'watched',            label: 'Most Watched',       description: 'Most plays by Trakt users',                 group: CatalogGroup.standard),
  CatalogDef(id: 'anticipated',        label: 'Anticipated',        description: 'Most anticipated upcoming titles',          group: CatalogGroup.standard),
];

// ── Default widget presets ────────────────────────────────────────────────────

const kDefaultMovieWidgets = [
  WidgetConfig(provider: 'tmdb', category: 'trending_day',  title: 'Trending Today'),
  WidgetConfig(provider: 'tmdb', category: 'popular',       title: 'Popular'),
  WidgetConfig(provider: 'tmdb', category: 'top_rated',     title: 'Top Rated'),
  WidgetConfig(provider: 'tmdb', category: 'now_playing',   title: 'Now Playing'),
  WidgetConfig(provider: 'tmdb', category: 'upcoming',      title: 'Upcoming'),
  WidgetConfig(provider: 'tmdb', category: 'trending_week', title: 'Trending This Week'),
];

const kDefaultShowWidgets = [
  WidgetConfig(provider: 'tmdb', category: 'trending_day',  title: 'Trending Today'),
  WidgetConfig(provider: 'tmdb', category: 'popular',       title: 'Popular'),
  WidgetConfig(provider: 'tmdb', category: 'top_rated',     title: 'Top Rated'),
  WidgetConfig(provider: 'tmdb', category: 'airing_today',  title: 'Airing Today'),
  WidgetConfig(provider: 'tmdb', category: 'on_the_air',    title: 'On The Air'),
  WidgetConfig(provider: 'tmdb', category: 'trending_week', title: 'Trending This Week'),
];

// ── Image helpers ─────────────────────────────────────────────────────────────

String posterUrl(String? path, {String size = 'w300'}) {
  if (path == null || path.isEmpty) return '';
  return '$kImageBase/$size$path';
}

String backdropUrl(String? path, {String size = 'w1280'}) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path.replaceFirst(RegExp(r'/original/'), '/w1280/');
  }
  return '$kImageBase/$size$path';
}
