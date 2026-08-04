import '../models/catalog.dart';

const kImageBase = 'https://image.tmdb.org/t/p';

// ─────────────────────────────────────────────────────────────────────────────
// Catalog groups
//
// The lists themselves are no longer declared here. They come from
// `GET /api/v1/catalog/definitions`, which every source — built-in TMDb, the
// legacy Trakt integration, and each installed catalog plugin — contributes to.
// That is what lets installing a plugin add rows to the picker with no client
// change; a compiled-in menu could never do that.
//
// What stays is the presentation of the `group` field those definitions carry.
// ─────────────────────────────────────────────────────────────────────────────

/// Group headers, in render order. Keys match the wire strings in
/// `backend/plugins/contracts/catalog.py`.
const kCatalogGroupOrder = <String>[
  'standard',
  'discover',
  'genre',
  'decade',
  'network',
  'other',
];

const kCatalogGroupLabels = <String, String>{
  'standard': 'STANDARD LISTS',
  'discover': 'DISCOVER',
  'genre': 'BY GENRE',
  'decade': 'BY DECADE',
  'network': 'BY NETWORK',
  'other': 'OTHER',
};

/// Label for a group, tolerating one this build has never heard of.
///
/// A newer plugin inventing a group must degrade to a readable header rather
/// than dropping its lists out of the picker entirely.
String catalogGroupLabel(String group) =>
    kCatalogGroupLabels[group] ?? group.toUpperCase();

/// Sort key for a group, putting unknown groups last but keeping them.
int catalogGroupRank(String group) {
  final index = kCatalogGroupOrder.indexOf(group);
  return index < 0 ? kCatalogGroupOrder.length : index;
}

// ── The pinned first row ──────────────────────────────────────────────────────

/// Continue Watching is always row 1 on both home pages, and is not
/// configurable.
///
/// It is the one row whose position carries meaning: resuming what you were
/// last watching is the primary reason to open the app, so it should never be
/// somewhere the user has to hunt for. It also isn't really a *catalog* — it
/// comes from whichever tracker is active, so "which list is this" has no
/// answer to offer in the picker.
const kPinnedWidget = WidgetConfig(
  source: 'warp',
  provider: 'warp',
  category: 'continue_watching',
  title: 'Continue Watching',
);

/// Whether a stored row is the Continue Watching row.
///
/// Matches on category alone: configs written before Continue Watching moved to
/// its own source still name `trakt` as the provider, and they mean this row.
bool isPinnedWidget(WidgetConfig w) =>
    w.category == kPinnedWidget.category;

/// Force [rows] into the shape the home pages expect: pinned row first, exactly
/// once, everything else after it.
///
/// Applied to whatever the server returns, so a config saved before the row was
/// pinned — or hand-edited since — still opens correctly rather than showing
/// Continue Watching in slot 4, or twice.
List<WidgetConfig> withPinnedFirst(List<WidgetConfig> rows) {
  final rest = [
    for (final row in rows)
      if (!isPinnedWidget(row)) row,
  ];
  return [
    kPinnedWidget,
    ...rest.take(kMaxWidgets - 1),
  ];
}

// ── Default widget presets ────────────────────────────────────────────────────
//
// Kept in sync by hand with `_DEFAULT_MOVIE_WIDGETS` / `_DEFAULT_SHOW_WIDGETS`
// in `backend/api/routes/settings.py`. These are only used before the server's
// config arrives, so a drift shows up as a flicker rather than a wrong save.

const kDefaultMovieWidgets = [
  kPinnedWidget,
  WidgetConfig(source: 'tmdb', provider: 'tmdb', category: 'trending_day',  title: 'Trending Today'),
  WidgetConfig(source: 'tmdb', provider: 'tmdb', category: 'popular',       title: 'Popular'),
  WidgetConfig(source: 'tmdb', provider: 'tmdb', category: 'top_rated',     title: 'Top Rated'),
  WidgetConfig(source: 'tmdb', provider: 'tmdb', category: 'now_playing',   title: 'Now Playing'),
  WidgetConfig(source: 'tmdb', provider: 'tmdb', category: 'upcoming',      title: 'Upcoming'),
];

const kDefaultShowWidgets = [
  kPinnedWidget,
  WidgetConfig(source: 'tmdb', provider: 'tmdb', category: 'trending_day',  title: 'Trending Today'),
  WidgetConfig(source: 'tmdb', provider: 'tmdb', category: 'popular',       title: 'Popular'),
  WidgetConfig(source: 'tmdb', provider: 'tmdb', category: 'top_rated',     title: 'Top Rated'),
  WidgetConfig(source: 'tmdb', provider: 'tmdb', category: 'airing_today',  title: 'Airing Today'),
  WidgetConfig(source: 'tmdb', provider: 'tmdb', category: 'on_the_air',    title: 'On The Air'),
];

/// Home rows allowed. Mirrors `MIN_WIDGETS`/`MAX_WIDGETS` in
/// `backend/api/routes/settings.py`, which enforces them.
const kMinWidgets = 1;
const kMaxWidgets = 10;

/// Rows at the top of the list the user cannot configure — just Continue
/// Watching today. Everything indexed at or beyond this is theirs to change, so
/// the default of 6 rows means 5 configurable, and the cap of 10 means 9.
const kPinnedRowCount = 1;

// ── Image helpers ─────────────────────────────────────────────────────────────

/// True when a source handed us a ready-made artwork URL rather than a TMDb path.
///
/// Non-TMDb catalog sources supply absolute URLs — Simkl serves posters from
/// simkl.in, TheTVDB from artworks.thetvdb.com. Prefixing those with the TMDb
/// image base produces a URL that is nonsense and silently renders nothing.
bool _isAbsolute(String path) =>
    path.startsWith('http://') || path.startsWith('https://');

String posterUrl(String? path, {String size = 'w300'}) {
  if (path == null || path.isEmpty) return '';
  if (_isAbsolute(path)) return path;
  return '$kImageBase/$size$path';
}

String backdropUrl(String? path, {String size = 'w1280'}) {
  if (path == null || path.isEmpty) return '';
  if (_isAbsolute(path)) {
    return path.replaceFirst(RegExp(r'/original/'), '/w1280/');
  }
  return '$kImageBase/$size$path';
}
