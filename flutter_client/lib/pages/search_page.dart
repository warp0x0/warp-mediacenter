import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_client.dart';
import '../models/media.dart';
import '../navigation/detail_route_extra.dart';
import '../navigation/last_tab_route.dart';
import '../navigation/row_first_card_registry.dart';
import '../navigation/tab_bar_focus_registry.dart';
import '../theme/warp_theme.dart';
import '../theme/warp_tokens.dart';
import '../widgets/cards/poster_card.dart';
import '../widgets/layout/backdrop_layer.dart';
import '../widgets/shared/dpad_controls.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SearchPage — mirrors Tauri's SearchPage.tsx exactly
//
// Background: solid #181818 (bg-bg-primary), backdrop cleared on enter.
// Idle: recent searches from GET /api/v1/settings/search-history
// Search: parallel TMDb + Trakt, split into 3 ribbon rows
// ─────────────────────────────────────────────────────────────────────────────

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  // Outer D-pad-navigable wrapper around the search TextField — Select
  // transfers real focus onto _focus, entering dpad's native text-edit mode.
  final _searchBarNode = FocusNode(debugLabel: 'SearchBarWrapper');
  final _searchBtnFocusNode = FocusNode(debugLabel: 'SearchBtn');
  // Page-local registry for result-ribbon Down-chaining (rowIndex 0/1/2 for
  // however many of Movies(TMDb)/Shows(TMDb)/Trakt are actually non-empty).
  final _rowRegistry = RowFirstCardRegistry();
  List<FocusNode> _historyRowFocusNodes = [];
  // "X" delete-button nodes, parallel to _historyRowFocusNodes — owned here
  // (rather than internally by each _HistoryItem) so a deletion can move
  // focus to the next row's "X" button by index.
  List<FocusNode> _historyXFocusNodes = [];
  // The floating tab bar overlays the top of this scrollable body, so
  // dpad's own generic ensureVisible (48px padding) isn't always tall
  // enough to clear it. Explicitly scroll to 0 whenever D-pad navigation
  // deliberately returns focus to the search bar, rather than relying on
  // that heuristic.
  final _pageScroll = ScrollController();

  List<String> _history = [];
  bool _historyLoading = true;

  List<MediaItem> _tmdbMovies = [];
  List<MediaItem> _tmdbShows = [];
  List<MediaItem> _traktItems = [];
  bool _searching = false;
  String? _error;
  String _activeQuery = '';

  bool get _hasResults =>
      _tmdbMovies.isNotEmpty || _tmdbShows.isNotEmpty || _traktItems.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(backdropProvider.notifier).clear();
    });
    // Rebuild when text changes so Search button enabled state stays in sync
    _ctrl.addListener(() => setState(() {}));
    // Rebuild on edit-mode transitions so the wrapper's `enabled`/onDirection
    // gating (below) stays in sync with whether the raw TextField currently
    // holds real focus.
    _focus.addListener(_onEditFocusChange);
    _loadHistory();
  }

  void _onEditFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.removeListener(_onEditFocusChange);
    _focus.dispose();
    _searchBarNode.dispose();
    _searchBtnFocusNode.dispose();
    _pageScroll.dispose();
    for (final fn in _historyRowFocusNodes) {
      fn.dispose();
    }
    for (final fn in _historyXFocusNodes) {
      fn.dispose();
    }
    super.dispose();
  }

  // Focuses the search bar and reliably scrolls the page back to the top —
  // used by every D-pad path that returns focus to the search bar, since
  // dpad's own generic ensureVisible padding isn't tall enough to clear the
  // floating tab bar overlaying this scrollable body.
  void _focusSearchBar() {
    Dpad.of(context).requestFocus(_searchBarNode);
    if (_pageScroll.hasClients) {
      _pageScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _syncHistoryFocusNodes() {
    for (final fn in _historyRowFocusNodes) {
      fn.dispose();
    }
    for (final fn in _historyXFocusNodes) {
      fn.dispose();
    }
    _historyRowFocusNodes = List.generate(_history.length, (_) => FocusNode());
    _historyXFocusNodes = List.generate(_history.length, (_) => FocusNode());
  }

  // ── D-pad navigation ────────────────────────────────────────────────────
  //
  // Up from the search bar (always) -> this page's own tab pill. This is
  // the ONLY path that reaches the tab — Recent Search rows' Up goes back
  // to the search bar itself (_historyRowUp), not straight to the tab.
  // Down from the search bar (or Search button) -> 1st result card if a
  // search has run, else the 1st Recent Search row, else no-op.
  // Up/Down always fully consume the press (return true unconditionally,
  // even with no target) so they never fall through to dpad's default
  // geometric beam traversal, which is unreliable across this page (that's
  // what was sending Right-from-search-bar to the 1st history row's X
  // button instead of the Search button).

  bool _searchBarDirection(TraversalDirection d) {
    if (d == TraversalDirection.up) {
      final tab = ref.read(tabBarFocusRegistryProvider).forRoute('/search');
      if (tab != null) {
        Dpad.of(context).requestFocus(tab);
      }
      return true;
    }
    if (d == TraversalDirection.down) {
      if (_hasResults) {
        final first = _rowRegistry.entryFor(0);
        if (first != null) {
          Dpad.of(context).requestFocus(first);
        }
        return true;
      }
      if (_historyRowFocusNodes.isNotEmpty) {
        Dpad.of(context).requestFocus(_historyRowFocusNodes[0]);
      }
      return true;
    }
    return false;
  }

  // The search bar wrapper and Search button share _searchBarDirection's
  // up/down behavior, but each needs its own explicit left/right target —
  // default beam traversal was picking the 1st Recent Search row's "X"
  // button instead of the Search button, so this is spelled out rather
  // than left to geometry.
  //
  // The wrapper's Focus node stays in the key-bubbling chain even once the
  // bare TextField below it (excludeChildFocus: false) takes real focus —
  // dpad dispatches onDirection from there on *every* Right/Left press
  // regardless of caret position, since real caret movement happens via a
  // separate channel (the text input connection) that doesn't consume the
  // key from dpad's point of view. onDirection always sees the pre-move
  // caret offset (verified empirically), so checking the boundary here
  // reliably distinguishes "still moving through the text" (return false,
  // let it through) from "already at the edge, nowhere left to move"
  // (return true, escape) — without this, either every press would jump
  // away (if unconditional) or none would (if always deferred).
  bool _searchBarWrapperDirection(TraversalDirection d) {
    if (d == TraversalDirection.right) {
      if (!_focus.hasFocus) {
        // Wrapper mode (not editing): always jump straight to the button.
        Dpad.of(context).requestFocus(_searchBtnFocusNode);
        return true;
      }
      if (_ctrl.selection.end >= _ctrl.text.length) {
        Dpad.of(context).requestFocus(_searchBtnFocusNode);
        return true;
      }
      return false;
    }
    if (d == TraversalDirection.left) {
      // Nothing to the left of the search bar in either mode — strictly a
      // no-op. Consuming it unconditionally (rather than only at the edit
      // -mode boundary) matters in wrapper mode too: leaving it unhandled
      // let it leak into dpad's own uncontrolled beam-traversal fallback,
      // which was landing on whichever result card last had focus instead
      // of doing nothing.
      if (!_focus.hasFocus) return true;
      return _ctrl.selection.start <= 0;
    }
    return _searchBarDirection(d);
  }

  bool _searchBtnDirection(TraversalDirection d) {
    if (d == TraversalDirection.left) {
      Dpad.of(context).requestFocus(_searchBarNode);
      return true;
    }
    // Nothing to the right of the Search button — strictly a no-op.
    // Leaving this unhandled let it leak into dpad's own uncontrolled
    // beam-traversal fallback, which was landing on whichever result
    // card last had focus instead of doing nothing.
    if (d == TraversalDirection.right) return true;
    return _searchBarDirection(d);
  }

  // Up from the 1st Recent Search row (either its text entry or its "X"
  // button) -> the search bar specifically, never straight to the tab
  // pill — only the search bar/Search button's own Up reaches the tab.
  bool _historyRowUp(TraversalDirection d) {
    if (d == TraversalDirection.up) {
      _focusSearchBar();
      return true;
    }
    return false;
  }

  // Up from any card in a result ribbon -> the search bar (row 0) or the
  // previous ribbon's 1st card. Down -> next ribbon's 1st card.
  bool _resultRibbonDirection(int rowIndex, TraversalDirection d) {
    if (d == TraversalDirection.up) {
      if (rowIndex == 0) {
        _focusSearchBar();
        return true;
      }
      final prev = _rowRegistry.entryFor(rowIndex - 1);
      if (prev != null) {
        Dpad.of(context).requestFocus(prev);
      }
      return true;
    }
    if (d == TraversalDirection.down) {
      final next = _rowRegistry.entryFor(rowIndex + 1);
      if (next != null) {
        Dpad.of(context).requestFocus(next);
      }
      return true;
    }
    return false;
  }

  Future<void> _loadHistory() async {
    try {
      final client = ref.read(apiClientProvider);
      final raw = await client.get<Map<String, dynamic>>(
        '/api/v1/settings/search-history',
      );
      if (mounted) {
        final history = List<String>.from((raw['history'] as List?) ?? []);
        setState(() {
          _history = history;
          _historyLoading = false;
          _syncHistoryFocusNodes();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Future<void> _addHistory(String query) async {
    try {
      final client = ref.read(apiClientProvider);
      final raw = await client.post<Map<String, dynamic>>(
        '/api/v1/settings/search-history',
        body: {'query': query},
      );
      if (mounted) {
        final history = List<String>.from((raw['history'] as List?) ?? []);
        setState(() {
          _history = history;
          _syncHistoryFocusNodes();
        });
      }
    } catch (_) {}
  }

  Future<void> _deleteHistory(int index) async {
    if (index < 0 || index >= _history.length) return;
    final query = _history[index];
    try {
      final client = ref.read(apiClientProvider);
      await client.delete(
        '/api/v1/settings/search-history',
        params: {'query': query},
      );
      if (!mounted) return;
      setState(() {
        _history = _history.where((q) => q != query).toList();
        _syncHistoryFocusNodes();
      });
      // Land focus on whichever row's "X" button now occupies this index
      // (the row that was immediately after the deleted one), or the new
      // last row if the deleted one was last, or the search bar if the
      // list is now empty.
      if (_historyXFocusNodes.isNotEmpty) {
        final target = index.clamp(0, _historyXFocusNodes.length - 1);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Dpad.of(context).requestFocus(_historyXFocusNodes[target]);
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusSearchBar();
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "$query" from history'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete entry'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF3A1010),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _doSearch(String query, {bool addToHistory = true}) async {
    final q = query.trim();
    if (q.isEmpty) return;

    setState(() {
      _activeQuery = q;
      _searching = true;
      _error = null;
      _tmdbMovies = [];
      _tmdbShows = [];
      _traktItems = [];
    });

    final client = ref.read(apiClientProvider);

    final results = await Future.wait([
      client
          .get<Map<String, dynamic>>(
            '/api/v1/search/tmdb',
            params: {'q': q, 'type': 'all'},
          )
          .then((r) => r)
          .catchError((_) => <String, dynamic>{}),
      client
          .get<Map<String, dynamic>>(
            '/api/v1/search/trakt',
            params: {'q': q, 'type': 'all', 'limit': '50'},
          )
          .then((r) => r)
          .catchError((_) => <String, dynamic>{}),
    ]);

    if (!mounted) return;

    final tmdbRaw = results[0];
    final traktRaw = results[1];

    final tmdbItems = _parseTmdb(tmdbRaw);
    final traktItems = _parseTrakt(traktRaw);

    if (tmdbItems.isEmpty &&
        traktItems.isEmpty &&
        tmdbRaw.isEmpty &&
        traktRaw.isEmpty) {
      setState(() {
        _error = 'Search failed. Is the backend running?';
        _searching = false;
      });
      return;
    }

    setState(() {
      _tmdbMovies = tmdbItems.where((i) => i.type == 'movie').toList();
      _tmdbShows = tmdbItems.where((i) => i.type == 'show').toList();
      _traktItems = traktItems;
      _searching = false;
    });

    if (addToHistory) _addHistory(q);
  }

  List<MediaItem> _parseTmdb(Map<String, dynamic> raw) {
    final list = raw['results'] as List? ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final rawType = m['type'] as String? ?? 'movie';
      final type = rawType == 'tv' || rawType == 'show' ? 'show' : 'movie';
      final id = m['id']?.toString() ?? m['title']?.toString() ?? '';
      final tmdbId = (m['tmdb_id'] ?? m['id'])?.toString() ?? '';
      return MediaItem(
        id: id,
        title: (m['title'] as String?) ?? '',
        type: type,
        sourceTag: 'tmdb',
        year: m['year'] as int?,
        overview: m['overview'] as String?,
        rating: (m['rating'] as num?)?.toDouble(),
        genres: List<String>.from(m['genres'] ?? []),
        posterPath: m['poster_path'] as String?,
        backdropPath: m['backdrop_path'] as String?,
        tmdbId: tmdbId,
        media: MediaNested(
          id: id,
          title: (m['title'] as String?) ?? '',
          name: (m['title'] as String?) ?? '',
          year: m['year'] as int?,
          overview: m['overview'] as String?,
          posterPath: m['poster_path'] as String?,
          backdropPath: m['backdrop_path'] as String?,
          rating: (m['rating'] as num?)?.toDouble(),
        ),
      );
    }).toList();
  }

  List<MediaItem> _parseTrakt(Map<String, dynamic> raw) {
    final list = raw['results'] as List? ?? [];
    return list.map((e) {
      final entry = e as Map<String, dynamic>;
      final entryType = entry['type'] as String? ?? 'movie';
      final mediaMap = (entry['media'] ?? entry) as Map<String, dynamic>;
      final extraMap = (mediaMap['extra'] ?? {}) as Map<String, dynamic>;
      final idsMap = (extraMap['ids'] ?? {}) as Map<String, dynamic>;
      final posterPath = extraMap['poster_path'] as String?;
      final backdropPath = extraMap['backdrop_path'] as String?;
      final tmdbId = idsMap['tmdb']?.toString();
      final traktId = idsMap['trakt']?.toString();
      final poster = mediaMap['poster'];
      ImageAsset? posterAsset;
      if (poster is Map<String, dynamic> && poster['url'] is String) {
        posterAsset = ImageAsset(url: poster['url'] as String);
      }
      final id = mediaMap['id']?.toString() ?? '';
      return MediaItem(
        id: id,
        title: (mediaMap['title'] as String?) ?? '',
        type: entryType == 'show' ? 'show' : 'movie',
        sourceTag: 'trakt',
        year: mediaMap['year'] as int?,
        overview: mediaMap['overview'] as String?,
        rating: (mediaMap['rating'] as num?)?.toDouble(),
        genres: List<String>.from(mediaMap['genres'] ?? []),
        poster: posterAsset,
        posterPath: posterPath,
        backdropPath: backdropPath,
        tmdbId: tmdbId,
        traktId: traktId,
        media: MediaNested(
          id: id,
          title: (mediaMap['title'] as String?) ?? '',
          name: (mediaMap['title'] as String?) ?? '',
          year: mediaMap['year'] as int?,
          overview: mediaMap['overview'] as String?,
          posterPath: posterPath,
          backdropPath: backdropPath,
          rating: (mediaMap['rating'] as num?)?.toDouble(),
        ),
      );
    }).toList();
  }

  void _navigateToDetail(MediaItem item, {FocusNode? returnFocusNode}) {
    final id = item.tmdbId?.isNotEmpty == true ? item.tmdbId! : item.id;
    if (id.isEmpty) return;
    context.push(
      '/detail/${item.type}/$id',
      extra: DetailRouteExtra(item: item, returnFocusNode: returnFocusNode),
    );
  }

  // Search is one of the shell's tab routes, switched via go() (which
  // replaces the location rather than pushing), so there's no navigator
  // back-stack to pop here. LastTabRoute remembers whichever tab was
  // active before the user switched to Search, so Back/Backspace can
  // return there directly.
  void _exitToPreviousTab() => context.go(LastTabRoute.value);

  // Escape/goBack/browserBack are a 2-level hierarchy on this page: while
  // the search TextField is genuinely being edited, the first press only
  // backs out of edit mode (to the wrapper) — it does NOT leave the page.
  // Only once out of edit mode does the same key leave to the previous tab.
  //
  // Backspace is deliberately NOT part of this while editing — it needs to
  // reach the TextField as a real character-delete. Outside edit mode
  // (where there's no text to delete), it still means "back" like the
  // others; see the bindings map below, which drops the Backspace entry
  // entirely while _focus.hasFocus so it's never intercepted here.
  void _handleBackKey() {
    if (_focus.hasFocus) {
      Dpad.of(context).requestFocus(_searchBarNode);
    } else {
      _exitToPreviousTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    // 80% width centered — matches Tauri's `width: '80%'` on the search bar container
    final barWidth = size.width * 0.80;
    final hasResults =
        _tmdbMovies.isNotEmpty ||
        _tmdbShows.isNotEmpty ||
        _traktItems.isNotEmpty;
    final showNoResults =
        _activeQuery.isNotEmpty && !_searching && _error == null && !hasResults;

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      // MaterialApp's WidgetsApp installs a default Escape -> DismissIntent
      // shortcut, and EditableText's own DismissIntent handler explicitly
      // passes through to the *next* ancestor Actions handling that intent
      // whenever no selection toolbar is showing — independent of whichever
      // Shortcuts widget actually captured the raw key. Overriding
      // DismissIntent here catches that path directly, on top of the raw
      // CallbackShortcuts binding below, so Escape can't slip past both.
      body: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _handleBackKey();
              return null;
            },
          ),
        },
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): _handleBackKey,
            const SingleActivator(LogicalKeyboardKey.goBack): _handleBackKey,
            const SingleActivator(LogicalKeyboardKey.browserBack):
                _handleBackKey,
            // Only bound while NOT editing — while editing, Backspace must
            // fall through entirely so it reaches the TextField as a real
            // character delete instead of being caught here.
            if (!_focus.hasFocus)
              const SingleActivator(LogicalKeyboardKey.backspace):
                  _exitToPreviousTab,
          },
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              controller: _pageScroll,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: t.tabBarHeight),

                    // ── Search bar ───────────────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: (size.height * 0.035).clamp(28.0, 52.0),
                      ),
                      child: SizedBox(
                        width: barWidth,
                        child: Row(
                          children: [
                            Expanded(
                              // Outer wrapper is the D-pad-navigable stop; Select
                              // transfers real focus onto the bare TextField, after
                              // which dpad's native text-edit arrow handling takes
                              // over (caret movement / navigate-away at boundaries).
                              child: WarpDpadTextField(
                                controller: _ctrl,
                                fieldFocusNode: _focus,
                                wrapperFocusNode: _searchBarNode,
                                tokens: t,
                                autofocus: true,
                                autoScroll: false,
                                disableWrapperWhileEditing: true,
                                moveCursorToEndOnEnter: true,
                                enableSelectAllContextMenu: true,
                                onDirection: _searchBarWrapperDirection,
                                onSubmitted: _doSearch,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: t.fontBody,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search movies & shows…',
                                  hintStyle: const TextStyle(
                                    color: Color(0x66FFFFFF),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withAlpha(10),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: (size.height * 0.025).clamp(
                                      12.0,
                                      20.0,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      t.radiusBtn,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.white.withAlpha(25),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      t.radiusBtn,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.white.withAlpha(25),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      t.radiusBtn,
                                    ),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0DB2E2),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _SearchBtn(
                              isLoading: _searching,
                              hasQuery: _ctrl.text.trim().isNotEmpty,
                              onTap: () => _doSearch(_ctrl.text),
                              t: t,
                              height: (size.height * 0.05).clamp(44.0, 56.0),
                              focusNode: _searchBtnFocusNode,
                              onDirection: _searchBtnDirection,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Loading ──────────────────────────────────────────────────────
                    if (_searching)
                      Padding(
                        padding: EdgeInsets.only(
                          top: (size.height * 0.1).clamp(40.0, 80.0),
                        ),
                        child: const CircularProgressIndicator(
                          color: Color(0xFF0DB2E2),
                          strokeWidth: 2,
                        ),
                      ),

                    // ── Error ────────────────────────────────────────────────────────
                    if (!_searching && _error != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: (size.height * 0.1).clamp(40.0, 80.0),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: const Color(0xFFEF4444),
                            fontSize: t.fontBody,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // ── No results ───────────────────────────────────────────────────
                    if (showNoResults)
                      Padding(
                        padding: EdgeInsets.only(
                          top: (size.height * 0.1).clamp(40.0, 80.0),
                        ),
                        child: Text(
                          'No results found for "$_activeQuery"',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: t.fontBody,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // ── Results: TMDb Movies, TMDb Shows, Trakt ──────────────────────
                    if (!_searching && _error == null && hasResults)
                      Padding(
                        padding: EdgeInsets.only(
                          top: (size.height * 0.005).clamp(4.0, 8.0),
                          bottom: 24,
                        ),
                        child: Builder(
                          builder: (context) {
                            // Assign rowIndex 0/1/2 in display order, skipping empty
                            // ribbons, so cross-ribbon Down-chaining stays contiguous.
                            var row = 0;
                            return Column(
                              children: [
                                if (_tmdbMovies.isNotEmpty)
                                  _ResultRibbon(
                                    label: 'Movies (TMDb)',
                                    items: _tmdbMovies,
                                    onTap: _navigateToDetail,
                                    t: t,
                                    rowIndex: row++,
                                    rowRegistry: _rowRegistry,
                                    onDirection: _resultRibbonDirection,
                                  ),
                                if (_tmdbShows.isNotEmpty)
                                  _ResultRibbon(
                                    label: 'Shows (TMDb)',
                                    items: _tmdbShows,
                                    onTap: _navigateToDetail,
                                    t: t,
                                    rowIndex: row++,
                                    rowRegistry: _rowRegistry,
                                    onDirection: _resultRibbonDirection,
                                  ),
                                if (_traktItems.isNotEmpty)
                                  _ResultRibbon(
                                    label: 'Trakt',
                                    items: _traktItems,
                                    onTap: _navigateToDetail,
                                    t: t,
                                    rowIndex: row++,
                                    rowRegistry: _rowRegistry,
                                    onDirection: _resultRibbonDirection,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),

                    // ── Idle: history or prompt ──────────────────────────────────────
                    if (_activeQuery.isEmpty && !_searching)
                      Padding(
                        padding: EdgeInsets.only(
                          top: (size.height * 0.03).clamp(24.0, 44.0),
                          bottom: 24,
                        ),
                        child: _historyLoading
                            ? const SizedBox.shrink()
                            : _history.isNotEmpty
                            ? SizedBox(
                                width: barWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'RECENT SEARCHES',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: (size.width * 0.007).clamp(
                                          11.0,
                                          13.0,
                                        ),
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: (size.height * 0.01).clamp(
                                        8.0,
                                        14.0,
                                      ),
                                    ),
                                    for (
                                      var i = 0;
                                      i < _history.length &&
                                          i < _historyRowFocusNodes.length &&
                                          i < _historyXFocusNodes.length;
                                      i++
                                    )
                                      _HistoryItem(
                                        query: _history[i],
                                        t: t,
                                        rowFocusNode: _historyRowFocusNodes[i],
                                        xFocusNode: _historyXFocusNodes[i],
                                        isFirst: i == 0,
                                        onRowUp: _historyRowUp,
                                        onTap: () {
                                          _ctrl.text = _history[i];
                                          _doSearch(_history[i]);
                                        },
                                        onDelete: () => _deleteHistory(i),
                                      ),
                                  ],
                                ),
                              )
                            : Text(
                                'Search across TMDb & Trakt',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: t.fontBody,
                                ),
                                textAlign: TextAlign.center,
                              ),
                      ),

                    // Extra bottom padding
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search button — btn-primary (cyan background)
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBtn extends StatefulWidget {
  const _SearchBtn({
    required this.isLoading,
    required this.hasQuery,
    required this.onTap,
    required this.t,
    required this.height,
    required this.focusNode,
    required this.onDirection,
  });

  final bool isLoading;
  // Purely visual now (dims the button when there's no query yet) — it no
  // longer gates focusability or taps. A disabled DpadFocusable can never
  // be focused at all, which made Right-from-the-search-bar a silent
  // no-op whenever the query was empty; _doSearch already no-ops on an
  // empty query on its own, so gating reachability here added no safety,
  // only a D-pad dead end.
  final bool hasQuery;
  final VoidCallback onTap;
  final WarpTokens t;
  final double height;
  final FocusNode focusNode;
  final DpadDirectionCallback onDirection;

  @override
  State<_SearchBtn> createState() => _SearchBtnState();
}

class _SearchBtnState extends State<_SearchBtn> {
  bool _hovered = false;

  static const _darkBg = Color(0xCC333232);
  static const _cyanBorder = WarpColors.accent;

  @override
  Widget build(BuildContext context) {
    // The only state that legitimately makes this button non-interactive
    // is an in-flight search — an empty query is still fully focusable
    // and tappable, just visually muted until there's something to search.
    final focusable = !widget.isLoading;
    return MouseRegion(
      cursor: focusable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DpadFocusable(
        focusNode: widget.focusNode,
        enabled: focusable,
        onDirection: widget.onDirection,
        onSelect: widget.onTap,
        tapToSelect: false,
        builder: (context, state, child) {
          final focused = state.focused;
          // Global rule: CTA buttons never show a ring — dark/cyan-border by
          // default, filled cyan only when focused.
          final showAccent = focused || _hovered;
          return GestureDetector(
            onTap: focusable
                ? () {
                    widget.focusNode.requestFocus();
                    widget.onTap();
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: widget.height,
              padding: EdgeInsets.symmetric(
                horizontal: (MediaQuery.sizeOf(context).width * 0.015).clamp(
                  16.0,
                  28.0,
                ),
              ),
              decoration: BoxDecoration(
                color: showAccent ? WarpColors.accent : _darkBg,
                borderRadius: BorderRadius.circular(widget.t.radiusBtn),
                border: Border.all(
                  color: showAccent
                      ? WarpColors.accent
                      : _cyanBorder.withAlpha(widget.hasQuery ? 255 : 130),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isLoading) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (MediaQuery.sizeOf(context).width * 0.009)
                          .clamp(14.0, 17.0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History item — clock icon + text, hover bg-white/5
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// _HistoryItem — two focusable targets, left/right beam nav between them
// (both are in-beam siblings in the same Row, so default dpad traversal
// handles Left/Right natively — no manual key handling needed):
//   1. Row entry (clock + text) — external rowFocusNode (SearchPage needs to
//      address the 1st row from the search bar's Down and, if isFirst, wires
//      Up back to the search bar via onRowUp).
//   2. X delete button — internal FocusNode, Select calls onDelete.
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryItem extends StatefulWidget {
  const _HistoryItem({
    required this.query,
    required this.t,
    required this.onTap,
    required this.onDelete,
    required this.rowFocusNode,
    required this.xFocusNode,
    required this.isFirst,
    required this.onRowUp,
  });
  final String query;
  final WarpTokens t;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final FocusNode rowFocusNode;
  // Owned by SearchPage (not internally) so a deletion can move focus to
  // the next row's "X" button by index.
  final FocusNode xFocusNode;
  final bool isFirst;
  final DpadDirectionCallback onRowUp;

  @override
  State<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<_HistoryItem> {
  bool _rowHovered = false;
  bool _xHovered = false;

  // Row bg lights up when either element is active
  bool get _rowActive =>
      _rowHovered ||
      widget.rowFocusNode.hasFocus ||
      _xHovered ||
      widget.xFocusNode.hasFocus;
  // X button visible when either element is active
  bool get _xVisible => _rowActive;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padV = (size.height * 0.008).clamp(8.0, 13.0);
    final padH = (size.width * 0.006).clamp(8.0, 12.0);

    return IntrinsicHeight(
      child: Row(
        children: [
          // ── Row entry (clock + text) ──────────────────────────────────────
          Expanded(
            child: DpadFocusable(
              focusNode: widget.rowFocusNode,
              onFocusChange: (_) => setState(() {}),
              onDirection: widget.isFirst ? widget.onRowUp : null,
              onSelect: widget.onTap,
              tapToSelect: false,
              builder: (context, state, child) => MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _rowHovered = true),
                onExit: (_) => setState(() => _rowHovered = false),
                child: GestureDetector(
                  onTap: () {
                    widget.rowFocusNode.requestFocus();
                    widget.onTap();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: EdgeInsets.symmetric(
                      horizontal: padH,
                      vertical: padV,
                    ),
                    decoration: BoxDecoration(
                      color: _rowActive
                          ? Colors.white.withAlpha(13)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: state.focused
                              ? Colors.white70
                              : Colors.white38,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.query,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.t.fontBody,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child: const SizedBox.shrink(),
            ),
          ),

          // ── X delete button — separate focus target ───────────────────────
          DpadFocusable(
            focusNode: widget.xFocusNode,
            onFocusChange: (_) => setState(() {}),
            onDirection: widget.isFirst ? widget.onRowUp : null,
            onSelect: widget.onDelete,
            tapToSelect: false,
            builder: (context, state, child) => AnimatedOpacity(
              opacity: _xVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _xHovered = true),
                onExit: (_) => setState(() => _xHovered = false),
                child: GestureDetector(
                  onTap: () {
                    widget.xFocusNode.requestFocus();
                    widget.onDelete();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 36,
                    decoration: BoxDecoration(
                      color: _xHovered || state.focused
                          ? Colors.white.withAlpha(20)
                          : _rowActive
                          ? Colors.white.withAlpha(8)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                      // Cyan focus ring when keyboard-focused
                      border: state.focused
                          ? Border.all(color: const Color(0xFF0DB2E2), width: 1)
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: _xHovered || state.focused
                            ? Colors.white
                            : Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result ribbon row — section header + horizontal scroll of PosterCards
// Mirrors Tauri's ResultRow component (ref={ribbonRef}, chevron buttons)
// ─────────────────────────────────────────────────────────────────────────────

class _ResultRibbon extends StatefulWidget {
  const _ResultRibbon({
    required this.label,
    required this.items,
    required this.onTap,
    required this.t,
    required this.rowIndex,
    required this.rowRegistry,
    required this.onDirection,
  });

  final String label;
  final List<MediaItem> items;
  final void Function(MediaItem item, {FocusNode? returnFocusNode}) onTap;
  final WarpTokens t;
  final int rowIndex;
  final RowFirstCardRegistry rowRegistry;
  final bool Function(int rowIndex, TraversalDirection d) onDirection;

  @override
  State<_ResultRibbon> createState() => _ResultRibbonState();
}

class _ResultRibbonState extends State<_ResultRibbon> {
  final _scrollCtrl = ScrollController();
  bool _hovered = false;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _rebuildFocusNodes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _focusNodes.isEmpty) return;
      widget.rowRegistry.register(widget.rowIndex, _focusNodes[0]);
      // A fresh mount of the 1st ribbon only ever happens right after a
      // search just produced results (ribbons are conditionally rendered,
      // torn down between searches) — auto-jump focus there.
      if (widget.rowIndex == 0) Dpad.of(context).requestFocus(_focusNodes[0]);
    });
  }

  // Every card's focus listener re-registers itself as this row's entry
  // point, so Up/Down from an adjacent row (or the search bar, for row 0)
  // returns to whichever card last had focus — matching WidgetSection's
  // pattern. Always registering card 0 instead broke once it scrolled out
  // of the horizontal viewport: ListView lazily unmounts off-screen cards,
  // so requesting focus on an unattached node silently no-ops.
  void _rebuildFocusNodes() {
    _focusNodes = List.generate(widget.items.length, (_) => FocusNode());
    for (var i = 0; i < _focusNodes.length; i++) {
      final idx = i;
      _focusNodes[idx].addListener(() {
        if (_focusNodes[idx].hasFocus) {
          widget.rowRegistry.register(widget.rowIndex, _focusNodes[idx]);
          _centerFocusedCard(_focusNodes[idx]);
        }
      });
    }
  }

  // dpad's own focus-gain auto-scroll (disabled on these cards, see
  // PosterCard.autoScroll above) only nudges the page enough to satisfy a
  // fixed padding — if a row was already mostly visible it did nothing at
  // all, leaving the newly-focused card off-center. This always scrolls
  // the page so the card sits at the vertical center of the viewport,
  // clamped to the scroll extents when centering isn't possible (near the
  // very top/bottom of the page).
  void _centerFocusedCard(FocusNode node) {
    final cardContext = node.context;
    if (cardContext == null) return;
    final renderBox = cardContext.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return;

    // Horizontal: this row's own ribbon — the nearest Scrollable ancestor.
    // Disabling PosterCard's autoScroll also removed dpad's own horizontal
    // scroll-into-view for it, so this needs to be handled explicitly too,
    // not just the vertical page centering below.
    final ribbon = Scrollable.maybeOf(cardContext, axis: Axis.horizontal);
    if (ribbon != null) _centerInScrollable(renderBox, ribbon);

    // Vertical: the page itself. Its own Scrollable isn't the nearest one
    // (the ribbon above is), so this asks specifically for the nearest
    // *vertical* ancestor — the same "rows nested inside vertically
    // scrolling pages" case DpadScroll.ensureVisible handles internally.
    final page = Scrollable.maybeOf(cardContext, axis: Axis.vertical);
    if (page != null) _centerInScrollable(renderBox, page);
  }

  // Scrolls `scrollable` so `target` sits at the center of its viewport
  // along whichever axis it scrolls, clamped to the scroll extents when
  // perfect centering isn't possible (near either end of the content).
  void _centerInScrollable(RenderBox target, ScrollableState scrollable) {
    final viewport = scrollable.context.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return;
    final position = scrollable.position;
    if (!position.hasPixels || !position.hasContentDimensions) return;

    final bounds = MatrixUtils.transformRect(
      target.getTransformTo(viewport),
      Offset.zero & target.size,
    );
    final horizontal =
        axisDirectionToAxis(scrollable.axisDirection) == Axis.horizontal;
    final targetCenter = horizontal
        ? (bounds.left + bounds.right) / 2
        : (bounds.top + bounds.bottom) / 2;
    final viewportExtent = horizontal
        ? viewport.size.width
        : viewport.size.height;
    final delta = targetCenter - viewportExtent / 2;
    final offset = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((offset - position.pixels).abs() < 0.5) return;
    position.animateTo(
      offset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(_ResultRibbon old) {
    super.didUpdateWidget(old);
    if (old.items.length != widget.items.length ||
        old.rowIndex != widget.rowIndex) {
      if (old.rowIndex != widget.rowIndex) {
        widget.rowRegistry.unregister(old.rowIndex);
      }
      for (final fn in _focusNodes) {
        fn.dispose();
      }
      _rebuildFocusNodes();
      if (_focusNodes.isNotEmpty) {
        widget.rowRegistry.register(widget.rowIndex, _focusNodes[0]);
      } else {
        widget.rowRegistry.unregister(widget.rowIndex);
      }
    }
  }

  @override
  void dispose() {
    widget.rowRegistry.unregister(widget.rowIndex);
    for (final fn in _focusNodes) {
      fn.dispose();
    }
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scroll(double delta) {
    _scrollCtrl.animateTo(
      (_scrollCtrl.offset + delta).clamp(
        0.0,
        _scrollCtrl.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final size = MediaQuery.sizeOf(context);
    // 10% horizontal padding on each side — matches Tauri's paddingLeft/Right: '10%'
    final hPad = size.width * 0.10;
    final rowGap = (size.height * 0.03).clamp(24.0, 44.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: EdgeInsets.only(bottom: rowGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: EdgeInsets.only(
                left: hPad,
                right: hPad,
                bottom: (size.height * 0.008).clamp(8.0, 16.0),
              ),
              child: Row(
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: t.sectionTitleSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.items.length} result${widget.items.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: t.fontSubtitle,
                    ),
                  ),
                ],
              ),
            ),

            // Ribbon + chevrons
            // Height: posterHeight + 5 (gap) + ~36 (title+year text) + 16 (padding) + 8 (scale headroom)
            SizedBox(
              height: t.posterHeight + 65,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Cards — full width of Stack. DpadRegion stops horizontal
                  // edges so Left/Right at the 1st/last card never leaks
                  // into default beam traversal and jumps into an adjacent
                  // ribbon row — Up/Down between rows is handled explicitly
                  // by widget.onDirection instead.
                  Positioned.fill(
                    child: DpadRegion(
                      memoryKey: 'search-ribbon-${widget.rowIndex}',
                      horizontalEdge: DpadEdgeBehavior.stop,
                      verticalEdge: DpadEdgeBehavior.stop,
                      child: ListView.separated(
                        controller: _scrollCtrl,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.only(
                          left: hPad,
                          right: hPad,
                          top: 4,
                          bottom: 8,
                        ),
                        separatorBuilder: (_, _) => SizedBox(width: t.cardGap),
                        itemCount: widget.items.length,
                        itemBuilder: (ctx, i) {
                          final item = widget.items[i];
                          return PosterCard(
                            key: ValueKey(item.id),
                            item: item,
                            isSelected: false,
                            tokens: t,
                            focusNode: i < _focusNodes.length
                                ? _focusNodes[i]
                                : null,
                            entry: i == 0,
                            // dpad's default only nudges the page enough to
                            // satisfy a fixed padding — _centerFocusedCard
                            // below always centers the row instead.
                            autoScroll: false,
                            onDirection: (d) =>
                                widget.onDirection(widget.rowIndex, d),
                            onTap: () => widget.onTap(
                              item,
                              returnFocusNode: i < _focusNodes.length
                                  ? _focusNodes[i]
                                  : null,
                            ),
                            onDoubleTap: () => widget.onTap(
                              item,
                              returnFocusNode: i < _focusNodes.length
                                  ? _focusNodes[i]
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Left chevron — Positioned is direct Stack child (fixes ParentDataWidget)
                  Positioned(
                    left: (size.width * 0.003).clamp(4.0, 8.0),
                    top: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Center(
                        child: _ChevronBtn(
                          onTap: () => _scroll(-400),
                          left: true,
                        ),
                      ),
                    ),
                  ),

                  // Right chevron — Positioned is direct Stack child
                  Positioned(
                    right: (size.width * 0.003).clamp(4.0, 8.0),
                    top: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Center(
                        child: _ChevronBtn(
                          onTap: () => _scroll(400),
                          left: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChevronBtn extends StatefulWidget {
  const _ChevronBtn({required this.onTap, required this.left});
  final VoidCallback onTap;
  final bool left;

  @override
  State<_ChevronBtn> createState() => _ChevronBtnState();
}

class _ChevronBtnState extends State<_ChevronBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(_hovered ? 179 : 128),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.left ? Icons.chevron_left : Icons.chevron_right,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
  }
}
