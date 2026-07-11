import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api/api_client.dart';
import '../models/collection.dart';
import '../models/media.dart';
import '../navigation/catalog_browse_route_extra.dart';
import '../navigation/detail_route_extra.dart';
import '../navigation/row_first_card_registry.dart';
import '../navigation/tab_bar_focus_registry.dart';
import '../providers/catalog_provider.dart';
import '../providers/library_provider.dart';
import '../theme/warp_theme.dart';
import '../theme/warp_tokens.dart';
import '../widgets/cards/poster_card.dart';
import '../widgets/layout/backdrop_layer.dart';
import '../widgets/media/scan_dialog.dart';
import '../widgets/shared/dpad_controls.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared enums / helpers
// ─────────────────────────────────────────────────────────────────────────────

enum _LibTab { liked, wishlist, discover, local }

enum _MediaTypeF { movie, show }

class _SortOpt {
  final String value, label, sort, order;
  const _SortOpt(this.value, this.label, this.sort, this.order);

  static const all = [
    _SortOpt('added_at-desc', 'Date Added (newest)', 'added_at', 'desc'),
    _SortOpt('added_at-asc', 'Date Added (oldest)', 'added_at', 'asc'),
    _SortOpt('title-asc', 'Name (A–Z)', 'title', 'asc'),
    _SortOpt('title-desc', 'Name (Z–A)', 'title', 'desc'),
    _SortOpt('rating-desc', 'Highest Rated', 'rating', 'desc'),
    _SortOpt('vote_count-desc', 'Most Voted', 'vote_count', 'desc'),
  ];

  static _SortOpt find(String v) =>
      all.firstWhere((o) => o.value == v, orElse: () => all.first);
}

bool _isLastFourCard(int index, int length) {
  if (length <= 0) return false;
  final threshold = length <= 4 ? 0 : length - 4;
  return index >= threshold;
}

void _centerLibraryCard(FocusNode node) {
  final cardContext = node.context;
  if (cardContext == null || !cardContext.mounted) return;
  final renderObject = cardContext.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return;

  final horizontal = Scrollable.maybeOf(cardContext, axis: Axis.horizontal);
  if (horizontal != null) _centerInScrollable(renderObject, horizontal);

  final vertical = Scrollable.maybeOf(cardContext, axis: Axis.vertical);
  if (vertical != null) _centerInScrollable(renderObject, vertical);
}

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

// ─────────────────────────────────────────────────────────────────────────────
// LibraryPage
// ─────────────────────────────────────────────────────────────────────────────

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage>
    with WidgetsBindingObserver {
  _LibTab _tab = _LibTab.liked;
  _MediaTypeF _mt = _MediaTypeF.movie;
  String _sortValue = 'added_at-desc';
  late final List<FocusNode> _subTabFocusNodes;
  final _typeMovieFocus = FocusNode(debugLabel: 'LibraryTypeMovie');
  final _typeShowFocus = FocusNode(debugLabel: 'LibraryTypeShow');
  final _sortFocus = FocusNode(debugLabel: 'LibrarySort');
  final _scanFocus = FocusNode(debugLabel: 'LibraryScan');
  FocusNode? _lastLibraryFocus;
  bool _appActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_rememberLibraryFocus);
    _subTabFocusNodes = List.generate(
      _LibTab.values.length,
      (i) => FocusNode(debugLabel: 'LibrarySubTab-$i'),
    );
    // Clear the global backdrop so it doesn't bleed through the Library page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(backdropProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_rememberLibraryFocus);
    WidgetsBinding.instance.removeObserver(this);
    for (final node in _subTabFocusNodes) {
      node.dispose();
    }
    _typeMovieFocus.dispose();
    _typeShowFocus.dispose();
    _sortFocus.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final node = _lastLibraryFocus;
        if (mounted && node?.context != null) node?.requestFocus();
      });
    }
  }

  void _rememberLibraryFocus() {
    if (!_appActive || !mounted) return;
    final node = FocusManager.instance.primaryFocus;
    final nodeContext = node?.context;
    if (node == null || node is FocusScopeNode || nodeContext == null) return;
    final libraryBox = context.findRenderObject();
    final focusBox = nodeContext.findRenderObject();
    if (libraryBox == null || focusBox == null) return;
    var current = focusBox.parent;
    while (current != null) {
      if (identical(current, libraryBox)) {
        _lastLibraryFocus = node;
        return;
      }
      current = current.parent;
    }
  }

  FocusNode get _selectedTypeFocus =>
      _mt == _MediaTypeF.movie ? _typeMovieFocus : _typeShowFocus;

  bool _focusLibraryTab() {
    final tab = ref.read(tabBarFocusRegistryProvider).forRoute('/library');
    if (tab == null) return false;
    return Dpad.of(context).requestFocus(tab);
  }

  bool _focusSelectedSubtab() {
    return Dpad.of(context).requestFocus(_subTabFocusNodes[_tab.index]);
  }

  bool _focusContentEntry() {
    if (_tab == _LibTab.local) {
      return Dpad.of(context).requestFocus(_typeMovieFocus);
    }
    return Dpad.of(context).requestFocus(_selectedTypeFocus);
  }

  bool _subTabDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.up) {
      _focusLibraryTab();
      return true;
    }
    if (direction == TraversalDirection.down) {
      _focusContentEntry();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final hPad = (size.width * 0.02).clamp(24.0, 48.0);

    return ColoredBox(
      color: const Color(0xFF181818),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Space for floating tab bar
          SizedBox(height: t.tabBarHeight),

          // ── Page header ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              hPad,
              (size.height * 0.02).clamp(16.0, 28.0),
              hPad,
              0,
            ),
            child: Text(
              'All Your Collections In One Place',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: t.pageTitleSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // marginTop: 15px on the subtab nav in Tauri's LibraryPage.tsx
          const SizedBox(height: 15),

          // ── Sub-tab pill nav ─────────────────────────────────────────────
          _SubTabNav(
            selected: _tab,
            onSelect: (v) => setState(() => _tab = v),
            screenSize: size,
            t: t,
            focusNodes: _subTabFocusNodes,
            onDirection: _subTabDirection,
          ),

          // marginBottom: 10px on the subtab nav in Tauri's LibraryPage.tsx
          const SizedBox(height: 10),

          // ── Divider ──────────────────────────────────────────────────────
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: hPad),
            color: Colors.white.withAlpha(20),
          ),

          // ── Tab content ──────────────────────────────────────────────────
          Expanded(
            child: switch (_tab) {
              _LibTab.liked => _CollectionTab(
                key: const ValueKey('liked'),
                collectionType: 'liked',
                mediaType: _mt,
                sortValue: _sortValue,
                onMediaType: (v) => setState(() => _mt = v),
                onSort: (v) => setState(() => _sortValue = v),
                movieFocusNode: _typeMovieFocus,
                showFocusNode: _typeShowFocus,
                sortFocusNode: _sortFocus,
                onFocusSubtabs: _focusSelectedSubtab,
              ),
              _LibTab.wishlist => _CollectionTab(
                key: const ValueKey('wishlist'),
                collectionType: 'wishlist',
                mediaType: _mt,
                sortValue: _sortValue,
                onMediaType: (v) => setState(() => _mt = v),
                onSort: (v) => setState(() => _sortValue = v),
                movieFocusNode: _typeMovieFocus,
                showFocusNode: _typeShowFocus,
                sortFocusNode: _sortFocus,
                onFocusSubtabs: _focusSelectedSubtab,
              ),
              _LibTab.discover => _DiscoverTab(
                mediaType: _mt,
                onMediaType: (v) => setState(() => _mt = v),
                movieFocusNode: _typeMovieFocus,
                showFocusNode: _typeShowFocus,
                onFocusSubtabs: _focusSelectedSubtab,
              ),
              _LibTab.local => _LocalTab(
                mediaType: _mt,
                onMediaType: (v) => setState(() => _mt = v),
                movieFocusNode: _typeMovieFocus,
                showFocusNode: _typeShowFocus,
                scanFocusNode: _scanFocus,
                onFocusSubtabs: _focusSelectedSubtab,
              ),
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-tab pill nav
// ─────────────────────────────────────────────────────────────────────────────

class _SubTabNav extends StatelessWidget {
  final _LibTab selected;
  final void Function(_LibTab) onSelect;
  final Size screenSize;
  final WarpTokens t;
  final List<FocusNode> focusNodes;
  final DpadDirectionCallback onDirection;

  const _SubTabNav({
    required this.selected,
    required this.onSelect,
    required this.screenSize,
    required this.t,
    required this.focusNodes,
    required this.onDirection,
  });

  static const _tabs = [
    (tab: _LibTab.liked, icon: Icons.favorite_border, label: 'Liked'),
    (tab: _LibTab.wishlist, icon: Icons.add, label: 'Wishlist'),
    (tab: _LibTab.discover, icon: Icons.explore_outlined, label: 'Discover'),
    (tab: _LibTab.local, icon: Icons.folder_outlined, label: 'Local'),
  ];

  @override
  Widget build(BuildContext context) {
    final w = screenSize.width;
    final h = screenSize.height;
    final gap = (w * 0.012).clamp(10.0, 24.0);
    final padV = (h * 0.012).clamp(12.0, 20.0);
    final fs = (w * 0.009).clamp(14.0, 17.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: padV),
      child: Center(
        child: DpadRegion(
          memoryKey: 'library-subtabs',
          horizontalEdge: DpadEdgeBehavior.stop,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < _tabs.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                _Pill(
                  icon: _tabs[i].icon,
                  label: _tabs[i].label,
                  isActive: selected == _tabs[i].tab,
                  onTap: () => onSelect(_tabs[i].tab),
                  padV: (h * 0.007).clamp(7.0, 12.0),
                  padH: (w * 0.013).clamp(13.0, 22.0),
                  fontSize: fs,
                  t: t,
                  entry: selected == _tabs[i].tab,
                  focusNode: i < focusNodes.length ? focusNodes[i] : null,
                  onDirection: onDirection,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final double padV, padH, fontSize;
  final WarpTokens t;
  final bool entry;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;

  const _Pill({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.padV,
    required this.padH,
    required this.fontSize,
    required this.t,
    this.entry = false,
    this.focusNode,
    this.onDirection,
  });

  @override
  Widget build(BuildContext context) => WarpDpadButton(
    tokens: t,
    focusNode: focusNode,
    entry: entry,
    onDirection: onDirection,
    onSelect: onTap,
    padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
    backgroundColor: isActive ? const Color(0x26FFFFFF) : Colors.transparent,
    borderColor: isActive ? const Color(0x33FFFFFF) : Colors.transparent,
    focusBackgroundColor: const Color(0x26FFFFFF),
    borderRadius: 999,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: isActive ? Colors.white : Colors.white60),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.white60,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: Movies / Shows toggle
// ─────────────────────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final _MediaTypeF value;
  final void Function(_MediaTypeF) onChange;
  final WarpTokens t;
  final String memoryKey;
  final FocusNode? movieFocusNode;
  final FocusNode? showFocusNode;
  final bool Function(_MediaTypeF option, TraversalDirection direction)?
  onDirection;

  const _TypeToggle({
    required this.value,
    required this.onChange,
    required this.t,
    required this.memoryKey,
    this.movieFocusNode,
    this.showFocusNode,
    this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final fs = (w * 0.0085).clamp(13.0, 15.0);
    final padV = (w * 0.0045).clamp(6.0, 10.0);
    final padH = (w * 0.011).clamp(14.0, 22.0);

    return DpadRegion(
      memoryKey: memoryKey,
      horizontalEdge: DpadEdgeBehavior.stop,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in _MediaTypeF.values)
            WarpDpadButton(
              tokens: t,
              focusNode: option == _MediaTypeF.movie
                  ? movieFocusNode
                  : showFocusNode,
              onDirection: onDirection == null
                  ? null
                  : (d) => onDirection!(option, d),
              onSelect: () => onChange(option),
              padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
              backgroundColor: value == option
                  ? const Color(0x26FFFFFF)
                  : Colors.transparent,
              borderColor: value == option
                  ? const Color(0x33FFFFFF)
                  : Colors.transparent,
              focusBackgroundColor: const Color(0x26FFFFFF),
              borderRadius: 999,
              child: Text(
                option == _MediaTypeF.movie ? 'Movies' : 'Shows',
                style: TextStyle(
                  fontSize: fs,
                  fontWeight: FontWeight.w500,
                  color: value == option ? Colors.white : Colors.white60,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: Sort dropdown button
// ─────────────────────────────────────────────────────────────────────────────

class _SortButton extends StatelessWidget {
  final String sortValue;
  final void Function(String) onSort;
  final WarpTokens t;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;

  const _SortButton({
    required this.sortValue,
    required this.onSort,
    required this.t,
    this.focusNode,
    this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final fs = (w * 0.008).clamp(12.0, 14.0);
    final current = _SortOpt.find(sortValue);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sort:',
          style: TextStyle(fontSize: fs, color: Colors.white38),
        ),
        const SizedBox(width: 8),
        WarpDpadButton(
          tokens: t,
          focusNode: focusNode,
          onDirection: onDirection,
          padding: EdgeInsets.symmetric(
            horizontal: (w * 0.008).clamp(10.0, 14.0),
            vertical: (w * 0.004).clamp(5.0, 8.0),
          ),
          backgroundColor: Colors.white.withAlpha(13),
          borderColor: Colors.white.withAlpha(25),
          onSelect: () async {
            final result = await showDialog<String>(
              context: context,
              builder: (_) => _SortDialog(current: sortValue, t: t),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (focusNode?.context != null) focusNode?.requestFocus();
            });
            if (result != null) onSort(result);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                current.label,
                style: TextStyle(fontSize: fs, color: Colors.white70),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SortDialog extends StatelessWidget {
  final String current;
  final WarpTokens t;
  const _SortDialog({required this.current, required this.t});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).pop(),
          const SingleActivator(LogicalKeyboardKey.goBack): () =>
              Navigator.of(context).pop(),
          const SingleActivator(LogicalKeyboardKey.browserBack): () =>
              Navigator.of(context).pop(),
        },
        child: DpadRegion(
          memoryKey: 'library-sort-dialog',
          verticalEdge: DpadEdgeBehavior.stop,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _SortOpt.all.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: WarpDpadButton(
                      tokens: t,
                      autofocus: _SortOpt.all[i].value == current,
                      entry: _SortOpt.all[i].value == current,
                      onSelect: () =>
                          Navigator.of(context).pop(_SortOpt.all[i].value),
                      backgroundColor: _SortOpt.all[i].value == current
                          ? const Color(0x220DB2E2)
                          : Colors.white.withAlpha(8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: _SortOpt.all[i].value == current
                                ? const Icon(
                                    Icons.check_circle,
                                    size: 15,
                                    color: Color(0xFF0DB2E2),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _SortOpt.all[i].label,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Controls row shared by Liked / Wishlist tabs
// ─────────────────────────────────────────────────────────────────────────────

class _ControlsRow extends StatelessWidget {
  final _MediaTypeF mediaType;
  final String sortValue;
  final void Function(_MediaTypeF) onMediaType;
  final void Function(String) onSort;
  final WarpTokens t;
  final FocusNode movieFocusNode;
  final FocusNode showFocusNode;
  final FocusNode sortFocusNode;
  final String typeToggleMemoryKey;
  final bool Function(_MediaTypeF option, TraversalDirection direction)
  onTypeDirection;
  final DpadDirectionCallback onSortDirection;

  const _ControlsRow({
    required this.mediaType,
    required this.sortValue,
    required this.t,
    required this.onMediaType,
    required this.onSort,
    required this.movieFocusNode,
    required this.showFocusNode,
    required this.sortFocusNode,
    required this.typeToggleMemoryKey,
    required this.onTypeDirection,
    required this.onSortDirection,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = (size.width * 0.02).clamp(24.0, 48.0);
    final vPad = (size.height * 0.012).clamp(12.0, 20.0);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            hPad,
            vPad,
            hPad,
            (size.height * 0.01).clamp(10.0, 16.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TypeToggle(
                value: mediaType,
                onChange: onMediaType,
                t: t,
                memoryKey: typeToggleMemoryKey,
                movieFocusNode: movieFocusNode,
                showFocusNode: showFocusNode,
                onDirection: onTypeDirection,
              ),
              _SortButton(
                sortValue: sortValue,
                onSort: onSort,
                t: t,
                focusNode: sortFocusNode,
                onDirection: onSortDirection,
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          margin: EdgeInsets.symmetric(horizontal: hPad),
          color: Colors.white.withAlpha(20),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CollectionTab — Liked / Wishlist
// Fetches from /api/v1/collections/{type} with mediaType + sort params.
// Mirrors CollectionSubTab.tsx exactly.
// ─────────────────────────────────────────────────────────────────────────────

class _CollectionTab extends ConsumerStatefulWidget {
  final String collectionType;
  final _MediaTypeF mediaType;
  final String sortValue;
  final void Function(_MediaTypeF) onMediaType;
  final void Function(String) onSort;
  final FocusNode movieFocusNode;
  final FocusNode showFocusNode;
  final FocusNode sortFocusNode;
  final bool Function() onFocusSubtabs;

  const _CollectionTab({
    super.key,
    required this.collectionType,
    required this.mediaType,
    required this.sortValue,
    required this.onMediaType,
    required this.onSort,
    required this.movieFocusNode,
    required this.showFocusNode,
    required this.sortFocusNode,
    required this.onFocusSubtabs,
  });

  @override
  ConsumerState<_CollectionTab> createState() => _CollectionTabState();
}

class _CollectionTabState extends ConsumerState<_CollectionTab> {
  List<UserCollection> _items = [];
  int _total = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  static const _pageSize = 20;
  final _loadMoreFocusNode = FocusNode(debugLabel: 'LibraryLoadMore');
  final List<FocusNode> _cardFocusNodes = [];
  int _lastFocusedCard = 0;

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
  }

  @override
  void didUpdateWidget(_CollectionTab old) {
    super.didUpdateWidget(old);
    if (old.mediaType != widget.mediaType ||
        old.sortValue != widget.sortValue) {
      _fetch(reset: true);
    }
  }

  @override
  void dispose() {
    for (final node in _cardFocusNodes) {
      node.dispose();
    }
    _loadMoreFocusNode.dispose();
    super.dispose();
  }

  void _syncCardFocusNodes(int length) {
    while (_cardFocusNodes.length > length) {
      _cardFocusNodes.removeLast().dispose();
    }
    while (_cardFocusNodes.length < length) {
      final index = _cardFocusNodes.length;
      final node = FocusNode(debugLabel: 'LibraryGridCard-$index');
      node.addListener(() {
        if (node.hasFocus) _lastFocusedCard = index;
      });
      _cardFocusNodes.add(node);
    }
    if (_lastFocusedCard >= length) {
      _lastFocusedCard = length <= 0 ? 0 : length - 1;
    }
  }

  bool _focusFirstCard() {
    if (_cardFocusNodes.isEmpty) return true;
    Dpad.of(context).requestFocus(_cardFocusNodes.first);
    return true;
  }

  bool _focusSelectedType() {
    final node = widget.mediaType == _MediaTypeF.movie
        ? widget.movieFocusNode
        : widget.showFocusNode;
    Dpad.of(context).requestFocus(node);
    return true;
  }

  bool _focusLastCard() {
    if (_cardFocusNodes.isEmpty) return _focusSelectedType();
    final index = _lastFocusedCard.clamp(0, _cardFocusNodes.length - 1);
    Dpad.of(context).requestFocus(_cardFocusNodes[index]);
    return true;
  }

  bool _typeDirection(_MediaTypeF option, TraversalDirection direction) {
    if (direction == TraversalDirection.up) return widget.onFocusSubtabs();
    if (direction == TraversalDirection.down) return _focusFirstCard();
    if (direction == TraversalDirection.left && option == _MediaTypeF.movie) {
      return true;
    }
    if (direction == TraversalDirection.right && option == _MediaTypeF.show) {
      Dpad.of(context).requestFocus(widget.sortFocusNode);
      return true;
    }
    return false;
  }

  bool _sortDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.up) return widget.onFocusSubtabs();
    if (direction == TraversalDirection.down) return _focusFirstCard();
    if (direction == TraversalDirection.left) return _focusSelectedType();
    if (direction == TraversalDirection.right) return true;
    return false;
  }

  bool _cardDirection(
    int index,
    int columns,
    bool hasMore,
    TraversalDirection direction,
  ) {
    if (direction == TraversalDirection.up) {
      final target = index - columns;
      if (target >= 0 && target < _cardFocusNodes.length) {
        Dpad.of(context).requestFocus(_cardFocusNodes[target]);
      } else {
        _focusSelectedType();
      }
      return true;
    }
    if (direction == TraversalDirection.down) {
      final target = index + columns;
      if (target < _cardFocusNodes.length) {
        Dpad.of(context).requestFocus(_cardFocusNodes[target]);
      } else if (hasMore) {
        Dpad.of(context).requestFocus(_loadMoreFocusNode);
      }
      return true;
    }
    return false;
  }

  Future<void> _fetch({required bool reset}) async {
    if (!mounted) return;
    if (reset) {
      _syncCardFocusNodes(0);
      setState(() {
        _isLoading = true;
        _items = [];
        _page = 1;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    final opt = _SortOpt.find(widget.sortValue);
    final page = reset ? 1 : _page + 1;

    try {
      final client = ref.read(apiClientProvider);
      final raw = await client.get<Map<String, dynamic>>(
        '/api/v1/collections/${widget.collectionType}',
        params: {
          'type': widget.mediaType.name,
          'sort': opt.sort,
          'order': opt.order,
          'page': page,
          'limit': _pageSize,
        },
      );
      final resp = CollectionResponse.fromJson(raw);
      if (!mounted) return;
      final nextItems = reset ? resp.items : [..._items, ...resp.items];
      _syncCardFocusNodes(nextItems.length);
      setState(() {
        _items = nextItems;
        _total = resp.count;
        _page = page;
      });
    } catch (_) {
      // Leave _items as-is; spinner will stop below.
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(collectionMutationVersionProvider, (previous, next) {
      if (previous != null && previous != next) _fetch(reset: true);
    });

    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final hPad = (size.width * 0.02).clamp(24.0, 48.0);

    return Column(
      children: [
        _ControlsRow(
          mediaType: widget.mediaType,
          sortValue: widget.sortValue,
          t: t,
          onMediaType: widget.onMediaType,
          onSort: widget.onSort,
          movieFocusNode: widget.movieFocusNode,
          showFocusNode: widget.showFocusNode,
          sortFocusNode: widget.sortFocusNode,
          typeToggleMemoryKey:
              'library-${widget.collectionType}-${widget.mediaType.name}-type-toggle',
          onTypeDirection: _typeDirection,
          onSortDirection: _sortDirection,
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF0DB2E2),
                    strokeWidth: 2,
                  ),
                )
              : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.collectionType == 'liked'
                            ? Icons.favorite_border
                            : Icons.add,
                        size: 52,
                        color: Colors.white.withAlpha(38),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.collectionType == 'liked'
                            ? 'Your liked titles will appear here.'
                            : 'Your wishlist will appear here.',
                        style: TextStyle(
                          fontSize: t.fontBody,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildGrid(t, size, hPad),
        ),
      ],
    );
  }

  Widget _buildGrid(WarpTokens t, Size size, double hPad) {
    final hasMore = _items.length < _total;
    final cols = (size.width / (t.posterWidth + t.cardGap)).floor().clamp(
      2,
      10,
    );

    return DpadRegion(
      memoryKey:
          'library-${widget.collectionType}-${widget.mediaType.name}-grid',
      horizontalEdge: DpadEdgeBehavior.stop,
      verticalEdge: DpadEdgeBehavior.stop,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(
              hPad,
            ).copyWith(top: (size.height * 0.015).clamp(16.0, 24.0)),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: (size.height * 0.018).clamp(16.0, 28.0),
                crossAxisSpacing: t.cardGap,
                childAspectRatio: t.posterWidth / t.posterCardTotalHeight,
              ),
              delegate: SliverChildBuilderDelegate((_, i) {
                final item = collectionToMedia(_items[i]);
                return PosterCard(
                  item: item,
                  isSelected: false,
                  tokens: t,
                  focusNode: i < _cardFocusNodes.length
                      ? _cardFocusNodes[i]
                      : null,
                  entry: i == 0,
                  onDirection: (d) => _cardDirection(i, cols, hasMore, d),
                  onTap: () => context.push(
                    '/detail/${item.type}/${item.tmdbId ?? item.id}',
                    extra: DetailRouteExtra(
                      item: item,
                      returnFocusNode: i < _cardFocusNodes.length
                          ? _cardFocusNodes[i]
                          : null,
                    ),
                  ),
                  onDoubleTap: () => context.push(
                    '/detail/${item.type}/${item.tmdbId ?? item.id}',
                    extra: DetailRouteExtra(
                      item: item,
                      returnFocusNode: i < _cardFocusNodes.length
                          ? _cardFocusNodes[i]
                          : null,
                    ),
                  ),
                );
              }, childCount: _items.length),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
              child: Center(
                child: hasMore
                    ? WarpDpadButton(
                        tokens: t,
                        focusNode: _loadMoreFocusNode,
                        onDirection: (d) {
                          if (d == TraversalDirection.up) {
                            return _focusLastCard();
                          }
                          if (d == TraversalDirection.down) return true;
                          return false;
                        },
                        width: 150,
                        height: 40,
                        padding: EdgeInsets.zero,
                        enabled: !_isLoadingMore,
                        onSelect: () => _fetch(reset: false),
                        child: _isLoadingMore
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0DB2E2),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Load More',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                      )
                    : Text(
                        '$_total title${_total != 1 ? 's' : ''} total',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HoverableRibbon — wraps a horizontal ListView with hover-reveal chevrons.
// Matches Tauri's library ribbon style: 700px scroll per click, opacity-0 → 1.
// ─────────────────────────────────────────────────────────────────────────────

class _HoverableRibbon extends StatefulWidget {
  final double height;
  final double scrollAmount;
  final Widget Function(ScrollController) builder;

  const _HoverableRibbon({
    required this.height,
    required this.scrollAmount,
    required this.builder,
  });

  @override
  State<_HoverableRibbon> createState() => _HoverableRibbonState();
}

class _HoverableRibbonState extends State<_HoverableRibbon> {
  final _scrollCtrl = ScrollController();
  bool _hovered = false;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      (_scrollCtrl.offset - widget.scrollAmount).clamp(
        0.0,
        _scrollCtrl.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollRight() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      (_scrollCtrl.offset + widget.scrollAmount).clamp(
        0.0,
        _scrollCtrl.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            Positioned.fill(child: widget.builder(_scrollCtrl)),

            Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: AbsorbPointer(
                  absorbing: !_hovered,
                  child: AnimatedOpacity(
                    opacity: _hovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: _LibChevronBtn(
                      icon: Icons.chevron_left,
                      onTap: _scrollLeft,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              right: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: AbsorbPointer(
                  absorbing: !_hovered,
                  child: AnimatedOpacity(
                    opacity: _hovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: _LibChevronBtn(
                      icon: Icons.chevron_right,
                      onTap: _scrollRight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibChevronBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _LibChevronBtn({required this.icon, required this.onTap});
  @override
  State<_LibChevronBtn> createState() => _LibChevronBtnState();
}

class _LibChevronBtnState extends State<_LibChevronBtn> {
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(_hovered ? 204 : 128),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(widget.icon, color: Colors.white, size: 50),
        ),
      ),
    );
  }
}

// "See More →" button for Discover ribbon headers
class _DiscoverSeeMoreBtn extends StatefulWidget {
  final VoidCallback onTap;
  final WarpTokens t;
  final FocusNode focusNode;
  final DpadDirectionCallback onDirection;
  const _DiscoverSeeMoreBtn({
    required this.onTap,
    required this.t,
    required this.focusNode,
    required this.onDirection,
  });
  @override
  State<_DiscoverSeeMoreBtn> createState() => _DiscoverSeeMoreBtnState();
}

class _DiscoverSeeMoreBtnState extends State<_DiscoverSeeMoreBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: DpadFocusable(
        focusNode: widget.focusNode,
        onSelect: widget.onTap,
        onDirection: widget.onDirection,
        tapToSelect: false,
        builder: (context, state, child) {
          final focused = state.focused;
          final active = _hovered || focused;
          return GestureDetector(
            onTap: () {
              widget.focusNode.requestFocus();
              widget.onTap();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: WarpColors.accent.withAlpha(140),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: widget.t.fontSubtitle,
                  fontWeight: FontWeight.w700,
                  color: focused
                      ? WarpColors.danger
                      : (active ? Colors.white : Colors.white70),
                  letterSpacing: 1.5,
                ),
                child: const Text('See More →'),
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
// _DiscoverTab — catalog ribbons from TMDb, filtered by mediaType
// Mirrors DiscoverSubTab.tsx (uses TMDb providers since Trakt may not be auth'd)
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoverTab extends ConsumerStatefulWidget {
  final _MediaTypeF mediaType;
  final void Function(_MediaTypeF) onMediaType;
  final FocusNode movieFocusNode;
  final FocusNode showFocusNode;
  final bool Function() onFocusSubtabs;

  const _DiscoverTab({
    required this.mediaType,
    required this.onMediaType,
    required this.movieFocusNode,
    required this.showFocusNode,
    required this.onFocusSubtabs,
  });

  static const _sections = [
    (provider: 'trakt', category: 'trending', label: 'Trending Now'),
    (provider: 'trakt', category: 'popular', label: 'Popular'),
    (provider: 'trakt', category: 'anticipated', label: 'Most Anticipated'),
    (provider: 'trakt', category: 'watched', label: 'Most Watched'),
    (provider: 'trakt', category: 'played', label: 'Most Played'),
    (provider: 'trakt', category: 'collected', label: 'Most Collected'),
    (provider: 'trakt', category: 'favorited', label: 'Most Favorited'),
  ];

  @override
  ConsumerState<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<_DiscoverTab> {
  final _rowRegistry = RowFirstCardRegistry();

  bool _focusSelectedType() {
    final node = widget.mediaType == _MediaTypeF.movie
        ? widget.movieFocusNode
        : widget.showFocusNode;
    Dpad.of(context).requestFocus(node);
    return true;
  }

  bool _focusRegisteredFrom(int rowIndex, int delta) {
    for (
      var i = rowIndex + delta;
      i >= 0 && i < _DiscoverTab._sections.length;
      i += delta
    ) {
      final node = _rowRegistry.entryFor(i);
      if (node != null) {
        Dpad.of(context).requestFocus(node);
        return true;
      }
    }
    return false;
  }

  bool _typeDirection(_MediaTypeF option, TraversalDirection direction) {
    if (direction == TraversalDirection.up) return widget.onFocusSubtabs();
    if (direction == TraversalDirection.down) {
      _focusRegisteredFrom(-1, 1);
      return true;
    }
    if (direction == TraversalDirection.left && option == _MediaTypeF.movie) {
      return true;
    }
    if (direction == TraversalDirection.right && option == _MediaTypeF.show) {
      return true;
    }
    return false;
  }

  bool _ribbonDirection(int rowIndex, TraversalDirection direction) {
    if (direction == TraversalDirection.up) {
      if (!_focusRegisteredFrom(rowIndex, -1)) _focusSelectedType();
      return true;
    }
    if (direction == TraversalDirection.down) {
      _focusRegisteredFrom(rowIndex, 1);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final hPad = (size.width * 0.02).clamp(20.0, 40.0);
    final mt = widget.mediaType.name; // 'movie' or 'show'

    return Column(
      children: [
        // Movies / Shows toggle (centered)
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: (size.height * 0.012).clamp(12.0, 20.0),
          ),
          child: Center(
            child: _TypeToggle(
              value: widget.mediaType,
              onChange: widget.onMediaType,
              t: t,
              memoryKey:
                  'library-discover-${widget.mediaType.name}-type-toggle',
              movieFocusNode: widget.movieFocusNode,
              showFocusNode: widget.showFocusNode,
              onDirection: _typeDirection,
            ),
          ),
        ),
        Container(
          height: 1,
          margin: EdgeInsets.symmetric(horizontal: hPad),
          color: Colors.white.withAlpha(20),
        ),

        // Ribbon sections
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: (size.height * 0.015).clamp(16.0, 24.0),
                bottom: 24,
              ),
              child: Column(
                children: [
                  for (var row = 0; row < _DiscoverTab._sections.length; row++)
                    _DiscoverRibbon(
                      key: ValueKey(
                        '${_DiscoverTab._sections[row].category}-$mt',
                      ),
                      label: _DiscoverTab._sections[row].label,
                      provider: _DiscoverTab._sections[row].provider,
                      category: _DiscoverTab._sections[row].category,
                      mediaType: mt,
                      t: t,
                      hPad: hPad,
                      rowIndex: row,
                      rowRegistry: _rowRegistry,
                      onDirection: _ribbonDirection,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscoverRibbon extends ConsumerStatefulWidget {
  final String label, provider, category, mediaType;
  final WarpTokens t;
  final double hPad;
  final int rowIndex;
  final RowFirstCardRegistry rowRegistry;
  final bool Function(int rowIndex, TraversalDirection direction) onDirection;

  const _DiscoverRibbon({
    super.key,
    required this.label,
    required this.provider,
    required this.category,
    required this.mediaType,
    required this.t,
    required this.hPad,
    required this.rowIndex,
    required this.rowRegistry,
    required this.onDirection,
  });

  @override
  ConsumerState<_DiscoverRibbon> createState() => _DiscoverRibbonState();
}

class _DiscoverRibbonState extends ConsumerState<_DiscoverRibbon> {
  final List<FocusNode> _focusNodes = [];
  final _seeMoreFocusNode = FocusNode(debugLabel: 'LibraryDiscoverSeeMore');
  int _lastFocusedIndex = 0;

  @override
  void dispose() {
    widget.rowRegistry.unregister(widget.rowIndex);
    _seeMoreFocusNode.dispose();
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool _seeMoreDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.up) {
      return widget.onDirection(widget.rowIndex, direction);
    }
    if (direction == TraversalDirection.down) {
      final node = widget.rowRegistry.entryFor(widget.rowIndex);
      if (node != null) {
        Dpad.of(context).requestFocus(node);
      } else if (_focusNodes.isNotEmpty) {
        Dpad.of(context).requestFocus(
          _focusNodes[_lastFocusedIndex.clamp(0, _focusNodes.length - 1)],
        );
      }
      return true;
    }
    if (direction == TraversalDirection.left ||
        direction == TraversalDirection.right) {
      return true;
    }
    return false;
  }

  void _syncFocusNodes(int length) {
    while (_focusNodes.length > length) {
      _focusNodes.removeLast().dispose();
    }
    while (_focusNodes.length < length) {
      final index = _focusNodes.length;
      final node = FocusNode(
        debugLabel: 'LibraryDiscover-${widget.category}-$index',
      );
      node.addListener(() {
        if (node.hasFocus) {
          _lastFocusedIndex = index;
          widget.rowRegistry.register(widget.rowIndex, node);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && node.hasFocus) _centerLibraryCard(node);
          });
        }
      });
      _focusNodes.add(node);
    }
    if (_focusNodes.isNotEmpty) {
      widget.rowRegistry.register(widget.rowIndex, _focusNodes.first);
    } else {
      widget.rowRegistry.unregister(widget.rowIndex);
    }
  }

  bool _cardDirection(int index, TraversalDirection direction) {
    if (direction == TraversalDirection.up &&
        _isLastFourCard(index, _focusNodes.length)) {
      Dpad.of(context).requestFocus(_seeMoreFocusNode);
      return true;
    }
    return widget.onDirection(widget.rowIndex, direction);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final async = ref.watch(
      catalogDataProvider(
        provider: widget.provider,
        category: widget.category,
        mediaType: widget.mediaType,
      ),
    );

    return async.when(
      loading: () => SizedBox(height: widget.t.posterCardTotalHeight + 60),
      error: (_, _) => const SizedBox.shrink(),
      data: (catalog) {
        _syncFocusNodes(catalog.items.length);
        if (catalog.items.isEmpty) {
          widget.rowRegistry.unregister(widget.rowIndex);
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.hPad),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: (size.width * 0.0095).clamp(14.0, 17.0),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.02,
                    ),
                  ),
                  _DiscoverSeeMoreBtn(
                    t: widget.t,
                    focusNode: _seeMoreFocusNode,
                    onDirection: _seeMoreDirection,
                    onTap: () => context.push(
                      '/catalog/${widget.provider}/${widget.category}?type=${widget.mediaType}&title=${Uri.encodeComponent(widget.label)}',
                      extra: CatalogBrowseRouteExtra(
                        returnFocusNode: _seeMoreFocusNode,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _HoverableRibbon(
              height: widget.t.posterCardTotalHeight + 16,
              scrollAmount: 700,
              builder: (ctrl) => ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: DpadRegion(
                  memoryKey:
                      'library-discover-${widget.mediaType}-${widget.category}',
                  horizontalEdge: DpadEdgeBehavior.stop,
                  verticalEdge: DpadEdgeBehavior.stop,
                  child: ListView.separated(
                    controller: ctrl,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.hPad,
                      vertical: 8,
                    ),
                    itemCount: catalog.items.length,
                    separatorBuilder: (context, i) =>
                        SizedBox(width: widget.t.cardGap),
                    itemBuilder: (_, i) {
                      final item = catalog.items[i];
                      return PosterCard(
                        item: item,
                        isSelected: false,
                        tokens: widget.t,
                        focusNode: i < _focusNodes.length
                            ? _focusNodes[i]
                            : null,
                        entry: i == 0,
                        autoScroll: false,
                        onDirection: (d) => _cardDirection(i, d),
                        onTap: () => context.push(
                          '/detail/${item.type}/${item.tmdbId ?? item.id}',
                          extra: DetailRouteExtra(
                            item: item,
                            returnFocusNode: i < _focusNodes.length
                                ? _focusNodes[i]
                                : null,
                          ),
                        ),
                        onDoubleTap: () => context.push(
                          '/detail/${item.type}/${item.tmdbId ?? item.id}',
                          extra: DetailRouteExtra(
                            item: item,
                            returnFocusNode: i < _focusNodes.length
                                ? _focusNodes[i]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: (size.height * 0.02).clamp(20.0, 32.0)),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LocalTab — sidebar + media toggle + ribbons
// Mirrors LocalSubTab.tsx: two ribbons (Recently Added, Names A–Z),
// per-ribbon skeleton loading, empty-state only when both ribbons have no data.
// ─────────────────────────────────────────────────────────────────────────────

class _LocalTab extends ConsumerStatefulWidget {
  final _MediaTypeF mediaType;
  final void Function(_MediaTypeF) onMediaType;
  final FocusNode movieFocusNode;
  final FocusNode showFocusNode;
  final FocusNode scanFocusNode;
  final bool Function() onFocusSubtabs;

  const _LocalTab({
    required this.mediaType,
    required this.onMediaType,
    required this.movieFocusNode,
    required this.showFocusNode,
    required this.scanFocusNode,
    required this.onFocusSubtabs,
  });

  @override
  ConsumerState<_LocalTab> createState() => _LocalTabState();
}

class _LocalTabState extends ConsumerState<_LocalTab> {
  final _rowRegistry = RowFirstCardRegistry();
  FocusNode? _scanReturnNode;

  bool _focusSelectedType() {
    final node = widget.mediaType == _MediaTypeF.movie
        ? widget.movieFocusNode
        : widget.showFocusNode;
    Dpad.of(context).requestFocus(node);
    return true;
  }

  bool _focusRegisteredFrom(int rowIndex, int delta) {
    for (var i = rowIndex + delta; i >= 0 && i < 2; i += delta) {
      final node = _rowRegistry.entryFor(i);
      if (node != null) {
        Dpad.of(context).requestFocus(node);
        return true;
      }
    }
    return false;
  }

  bool _scanDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.up) return widget.onFocusSubtabs();
    if (direction == TraversalDirection.right) {
      final node = _scanReturnNode;
      if (node?.context != null) {
        Dpad.of(context).requestFocus(node!);
      } else {
        Dpad.of(context).requestFocus(widget.movieFocusNode);
      }
      return true;
    }
    if (direction == TraversalDirection.down) {
      Dpad.of(context).requestFocus(widget.movieFocusNode);
      return true;
    }
    if (direction == TraversalDirection.left) return true;
    return false;
  }

  bool _typeDirection(_MediaTypeF option, TraversalDirection direction) {
    if (direction == TraversalDirection.up) return widget.onFocusSubtabs();
    if (direction == TraversalDirection.down) {
      _focusRegisteredFrom(-1, 1);
      return true;
    }
    if (direction == TraversalDirection.left && option == _MediaTypeF.movie) {
      _scanReturnNode = null;
      Dpad.of(context).requestFocus(widget.scanFocusNode);
      return true;
    }
    if (direction == TraversalDirection.right && option == _MediaTypeF.show) {
      return true;
    }
    return false;
  }

  bool _ribbonDirection(int rowIndex, TraversalDirection direction) {
    if (direction == TraversalDirection.up) {
      if (!_focusRegisteredFrom(rowIndex, -1)) _focusSelectedType();
      return true;
    }
    if (direction == TraversalDirection.down) {
      _focusRegisteredFrom(rowIndex, 1);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final hPad = (size.width * 0.02).clamp(20.0, 36.0);

    final recentAsync = widget.mediaType == _MediaTypeF.movie
        ? ref.watch(libraryMoviesProvider)
        : ref.watch(libraryShowsProvider);
    final azAsync = widget.mediaType == _MediaTypeF.movie
        ? ref.watch(libraryMoviesAzProvider)
        : ref.watch(libraryShowsAzProvider);

    final recentItems =
        recentAsync.asData?.value.items.map(libraryItemToMedia).toList() ?? [];
    final azItems =
        azAsync.asData?.value.items.map(libraryItemToMedia).toList() ?? [];
    final hasContent = recentItems.isNotEmpty || azItems.isNotEmpty;
    final isLoading = recentAsync.isLoading || azAsync.isLoading;

    return Row(
      children: [
        // ── Sidebar ────────────────────────────────────────────────────────
        Container(
          width: (size.width * 0.16).clamp(200.0, 280.0),
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: Color(0x0DFFFFFF))),
          ),
          padding: EdgeInsets.all((size.width * 0.02).clamp(24.0, 40.0)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 40,
                color: Colors.white.withAlpha(38),
              ),
              const SizedBox(height: 16),
              Text(
                'Add your Collections\nfrom Local Drive',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: (size.width * 0.009).clamp(14.0, 16.0),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan folders to import movies and shows into your local library.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(90),
                  fontSize: (size.width * 0.0072).clamp(11.0, 13.0),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              WarpDpadButton(
                tokens: t,
                focusNode: widget.scanFocusNode,
                onDirection: _scanDirection,
                width: double.infinity,
                backgroundColor: const Color(0xCC333232),
                focusBackgroundColor: const Color(0xFF0DB2E2),
                borderColor: const Color(0xFF0DB2E2),
                focusBorderColor: const Color(0xFF0DB2E2),
                onSelect: () => showDialog<void>(
                  context: context,
                  builder: (_) => const ScanDialog(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.document_scanner_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Start Scanning',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (size.width * 0.0085).clamp(13.0, 15.0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Main content ───────────────────────────────────────────────────
        Expanded(
          child: Column(
            children: [
              // Movies | Shows toggle
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hPad,
                  vertical: (size.height * 0.012).clamp(12.0, 20.0),
                ),
                child: Row(
                  children: [
                    _TypeToggle(
                      value: widget.mediaType,
                      onChange: widget.onMediaType,
                      t: t,
                      memoryKey:
                          'library-local-${widget.mediaType.name}-type-toggle',
                      movieFocusNode: widget.movieFocusNode,
                      showFocusNode: widget.showFocusNode,
                      onDirection: _typeDirection,
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                margin: EdgeInsets.symmetric(horizontal: hPad),
                color: Colors.white.withAlpha(20),
              ),

              // Ribbons
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: (size.height * 0.015).clamp(16.0, 24.0),
                      bottom: (size.height * 0.02).clamp(20.0, 32.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LocalRibbon(
                          label: 'Recently Added',
                          items: recentItems,
                          isLoading: recentAsync.isLoading,
                          t: t,
                          hPad: hPad,
                          rowIndex: 0,
                          memoryKey:
                              'library-local-${widget.mediaType.name}-recent',
                          rowRegistry: _rowRegistry,
                          scanFocusNode: widget.scanFocusNode,
                          onScanReturn: (node) => _scanReturnNode = node,
                          onDirection: _ribbonDirection,
                          onSeeMore: (returnFocusNode) => context.push(
                            '/catalog/local/recent?type=${widget.mediaType.name}&title=${Uri.encodeComponent('Recently Added')}',
                            extra: CatalogBrowseRouteExtra(
                              returnFocusNode: returnFocusNode,
                            ),
                          ),
                        ),
                        _LocalRibbon(
                          label: 'Names A–Z',
                          items: azItems,
                          isLoading: azAsync.isLoading,
                          t: t,
                          hPad: hPad,
                          rowIndex: 1,
                          memoryKey:
                              'library-local-${widget.mediaType.name}-az',
                          rowRegistry: _rowRegistry,
                          scanFocusNode: widget.scanFocusNode,
                          onScanReturn: (node) => _scanReturnNode = node,
                          onDirection: _ribbonDirection,
                          onSeeMore: (returnFocusNode) => context.push(
                            '/catalog/local/az?type=${widget.mediaType.name}&title=${Uri.encodeComponent('Names A-Z')}',
                            extra: CatalogBrowseRouteExtra(
                              returnFocusNode: returnFocusNode,
                            ),
                          ),
                        ),
                        // Empty state — shown only when both ribbons have finished loading with no content
                        if (!isLoading && !hasContent)
                          Padding(
                            padding: EdgeInsets.only(
                              top: (size.height * 0.12).clamp(48.0, 100.0),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder_open_outlined,
                                    size: 48,
                                    color: Colors.white.withAlpha(38),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No local media yet.',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: t.bodySize,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Click "Start Scanning" to import movies and shows.',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: t.subtitleSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocalRibbon extends StatefulWidget {
  final String label;
  final List<MediaItem> items;
  final bool isLoading;
  final WarpTokens t;
  final double hPad;
  final int rowIndex;
  final String memoryKey;
  final RowFirstCardRegistry rowRegistry;
  final FocusNode scanFocusNode;
  final void Function(FocusNode node) onScanReturn;
  final bool Function(int rowIndex, TraversalDirection direction) onDirection;
  final void Function(FocusNode returnFocusNode) onSeeMore;

  const _LocalRibbon({
    required this.label,
    required this.items,
    required this.isLoading,
    required this.t,
    required this.hPad,
    required this.rowIndex,
    required this.memoryKey,
    required this.rowRegistry,
    required this.scanFocusNode,
    required this.onScanReturn,
    required this.onDirection,
    required this.onSeeMore,
  });

  @override
  State<_LocalRibbon> createState() => _LocalRibbonState();
}

class _LocalRibbonState extends State<_LocalRibbon> {
  final List<FocusNode> _focusNodes = [];
  final _seeMoreFocusNode = FocusNode(debugLabel: 'LibraryLocalSeeMore');
  int _lastFocusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _syncFocusNodes(widget.items.length);
  }

  @override
  void didUpdateWidget(_LocalRibbon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length ||
        oldWidget.rowIndex != widget.rowIndex) {
      if (oldWidget.rowIndex != widget.rowIndex) {
        widget.rowRegistry.unregister(oldWidget.rowIndex);
      }
      _syncFocusNodes(widget.items.length);
    }
  }

  @override
  void dispose() {
    widget.rowRegistry.unregister(widget.rowIndex);
    _seeMoreFocusNode.dispose();
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncFocusNodes(int length) {
    while (_focusNodes.length > length) {
      _focusNodes.removeLast().dispose();
    }
    while (_focusNodes.length < length) {
      final index = _focusNodes.length;
      final node = FocusNode(debugLabel: 'LibraryLocal-${widget.label}-$index');
      node.addListener(() {
        if (node.hasFocus) {
          _lastFocusedIndex = index;
          widget.rowRegistry.register(widget.rowIndex, node);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && node.hasFocus) _centerLibraryCard(node);
          });
        }
      });
      _focusNodes.add(node);
    }
    if (_focusNodes.isNotEmpty) {
      widget.rowRegistry.register(widget.rowIndex, _focusNodes.first);
    } else {
      widget.rowRegistry.unregister(widget.rowIndex);
    }
  }

  bool _seeMoreDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.up) {
      return widget.onDirection(widget.rowIndex, direction);
    }
    if (direction == TraversalDirection.down) {
      final node = widget.rowRegistry.entryFor(widget.rowIndex);
      if (node != null) {
        Dpad.of(context).requestFocus(node);
      } else if (_focusNodes.isNotEmpty) {
        Dpad.of(context).requestFocus(
          _focusNodes[_lastFocusedIndex.clamp(0, _focusNodes.length - 1)],
        );
      }
      return true;
    }
    if (direction == TraversalDirection.left ||
        direction == TraversalDirection.right) {
      return true;
    }
    return false;
  }

  bool _cardDirection(int index, TraversalDirection direction) {
    if (direction == TraversalDirection.left && index == 0) {
      widget.onScanReturn(_focusNodes[index]);
      Dpad.of(context).requestFocus(widget.scanFocusNode);
      return true;
    }
    if (direction == TraversalDirection.up &&
        _isLastFourCard(index, _focusNodes.length)) {
      Dpad.of(context).requestFocus(_seeMoreFocusNode);
      return true;
    }
    return widget.onDirection(widget.rowIndex, direction);
  }

  @override
  Widget build(BuildContext context) {
    // Mirror Tauri: hide the ribbon when done loading and empty
    if (!widget.isLoading && widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final w = MediaQuery.sizeOf(context).width;
    final titleFs = (w * 0.0095).clamp(14.0, 17.0);

    return Padding(
      padding: EdgeInsets.only(bottom: (w * 0.02).clamp(20.0, 32.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: widget.hPad,
              right: widget.hPad,
              bottom: (w * 0.005).clamp(6.0, 10.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: titleFs,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: titleFs * 0.02,
                  ),
                ),
                if (!widget.isLoading && widget.items.isNotEmpty)
                  _DiscoverSeeMoreBtn(
                    t: widget.t,
                    focusNode: _seeMoreFocusNode,
                    onDirection: _seeMoreDirection,
                    onTap: () => widget.onSeeMore(_seeMoreFocusNode),
                  ),
              ],
            ),
          ),
          if (widget.isLoading)
            SizedBox(
              height: widget.t.posterCardTotalHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: widget.hPad),
                itemCount: 6,
                separatorBuilder: (context, i) =>
                    SizedBox(width: widget.t.cardGap),
                itemBuilder: (context, i) => _LocalSkeletonCard(t: widget.t),
              ),
            )
          else
            _HoverableRibbon(
              height: widget.t.posterCardTotalHeight + 16,
              scrollAmount: 700,
              builder: (ctrl) => ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: DpadRegion(
                  memoryKey: widget.memoryKey,
                  horizontalEdge: DpadEdgeBehavior.stop,
                  verticalEdge: DpadEdgeBehavior.stop,
                  child: ListView.separated(
                    controller: ctrl,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.hPad,
                      vertical: 8,
                    ),
                    itemCount: widget.items.length,
                    separatorBuilder: (context, i) =>
                        SizedBox(width: widget.t.cardGap),
                    itemBuilder: (_, i) {
                      final item = widget.items[i];
                      return PosterCard(
                        item: item,
                        isSelected: false,
                        tokens: widget.t,
                        focusNode: i < _focusNodes.length
                            ? _focusNodes[i]
                            : null,
                        entry: i == 0,
                        autoScroll: false,
                        onDirection: (d) => _cardDirection(i, d),
                        onTap: () => context.push(
                          '/detail/${item.type}/${item.tmdbId ?? item.id}',
                          extra: DetailRouteExtra(
                            item: item,
                            returnFocusNode: i < _focusNodes.length
                                ? _focusNodes[i]
                                : null,
                          ),
                        ),
                        onDoubleTap: () => context.push(
                          '/detail/${item.type}/${item.tmdbId ?? item.id}',
                          extra: DetailRouteExtra(
                            item: item,
                            returnFocusNode: i < _focusNodes.length
                                ? _focusNodes[i]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocalSkeletonCard extends StatelessWidget {
  final WarpTokens t;
  const _LocalSkeletonCard({required this.t});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: t.posterWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: t.posterWidth,
            height: t.posterHeight,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(13),
              borderRadius: BorderRadius.circular(t.cardRadius),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: t.posterWidth * 0.7,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: t.posterWidth * 0.4,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
