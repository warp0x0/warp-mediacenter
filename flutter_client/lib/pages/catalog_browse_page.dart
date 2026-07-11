import 'dart:math' as math;

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_client.dart';
import '../models/catalog.dart';
import '../models/library.dart';
import '../models/media.dart';
import '../navigation/detail_route_extra.dart';
import '../providers/library_provider.dart';
import '../theme/warp_tokens.dart';
import '../widgets/cards/poster_card.dart';
import '../widgets/layout/backdrop_layer.dart';
import '../widgets/shared/dpad_controls.dart';

const _kPageSize = 20;

class _BrowsePageData {
  const _BrowsePageData({
    required this.items,
    required this.count,
    required this.hasMore,
  });

  final List<MediaItem> items;
  final int count;
  final bool hasMore;
}

class CatalogBrowsePage extends ConsumerStatefulWidget {
  const CatalogBrowsePage({
    super.key,
    required this.provider,
    required this.category,
    this.mediaType = 'movie',
    this.title,
    this.returnFocusNode,
  });

  final String provider;
  final String category;
  final String mediaType;
  final String? title;
  final FocusNode? returnFocusNode;

  @override
  ConsumerState<CatalogBrowsePage> createState() => _CatalogBrowsePageState();
}

class _CatalogBrowsePageState extends ConsumerState<CatalogBrowsePage>
    with WidgetsBindingObserver {
  List<MediaItem> _items = [];
  int _offset = 0;
  bool _hasMore = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  final List<FocusNode> _cardFocusNodes = [];
  final _scrollController = ScrollController();
  final _backFocusNode = FocusNode(debugLabel: 'CatalogBrowseBack');
  final _loadMoreFocusNode = FocusNode(debugLabel: 'CatalogBrowseLoadMore');
  final _scrollRailFocusNode = FocusNode(debugLabel: 'CatalogBrowseScrollRail');
  FocusNode? _lastCatalogBrowseFocus;
  bool _appActive = true;
  bool _initialFocusRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_rememberCatalogBrowseFocus);
    _backFocusNode.addListener(_handleBackFocusChanged);
    _loadMoreFocusNode.addListener(_handleLoadMoreFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(backdropProvider.notifier).clear();
    });
    _fetchPage(0);
  }

  String get _displayTitle =>
      widget.title ?? widget.category.replaceAll('_', ' ');

  bool get _isLocalBrowse => widget.provider == 'local';

  Future<_BrowsePageData?> _fetchPageData(int offset) async {
    final client = ref.read(apiClientProvider);
    if (_isLocalBrowse) {
      final raw = await client.get<Map<String, dynamic>>(
        widget.mediaType == 'show'
            ? '/api/v1/library/shows'
            : '/api/v1/library/movies',
        params: {
          'limit': _kPageSize,
          'offset': offset,
          'sort': widget.category == 'az' ? 'title' : 'added_at',
          'order': widget.category == 'az' ? 'asc' : 'desc',
          'local_only': 'true',
        },
      );
      final data = LibraryListResponse.fromJson(raw);
      return _BrowsePageData(
        items: data.items.map(libraryItemToMedia).toList(),
        count: data.items.length,
        hasMore: data.hasNext,
      );
    }

    final raw = await client.get<Map<String, dynamic>>(
      '/api/v1/catalog/${widget.provider}/${widget.category}',
      params: {
        'media_type': widget.mediaType,
        'limit': _kPageSize,
        'offset': offset,
      },
    );
    final data = CatalogResponse.fromJson(raw);
    final hasMore = () {
      if (data.total != null) {
        return offset + data.count < data.total!;
      }
      return data.count >= _kPageSize;
    }();
    return _BrowsePageData(
      items: data.items,
      count: data.count,
      hasMore: hasMore,
    );
  }

  Future<void> _fetchPage(int offset) async {
    if (offset == 0) {
      setState(() {
        _isLoading = true;
        _items = [];
        _offset = 0;
        _hasMore = false;
        _error = null;
      });
    }
    try {
      final data = await _fetchPageData(offset);
      if (!mounted || data == null) return;
      setState(() {
        _items = offset == 0 ? data.items : [..._items, ...data.items];
        _offset = offset;
        _hasMore = data.hasMore;
      });
    } catch (_) {
      if (mounted && offset == 0) {
        setState(
          () => _error = 'Failed to load catalog. Is the backend running?',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    final firstNewIndex = _items.length;
    setState(() => _isLoadingMore = true);
    try {
      final nextOffset = _offset + _kPageSize;
      final data = await _fetchPageData(nextOffset);
      if (!mounted || data == null) return;
      setState(() {
        _items = [..._items, ...data.items];
        _offset = nextOffset;
        _hasMore = data.hasMore;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && firstNewIndex < _cardFocusNodes.length) {
          _focusCard(firstNewIndex);
        }
      });
    } catch (_) {
      // silently ignore load-more failures
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  void dispose() {
    _backFocusNode.removeListener(_handleBackFocusChanged);
    _loadMoreFocusNode.removeListener(_handleLoadMoreFocusChanged);
    FocusManager.instance.removeListener(_rememberCatalogBrowseFocus);
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _backFocusNode.dispose();
    _loadMoreFocusNode.dispose();
    _scrollRailFocusNode.dispose();
    for (final node in _cardFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final node = _lastCatalogBrowseFocus;
        if (mounted && node?.context != null) node?.requestFocus();
      });
    }
  }

  void _rememberCatalogBrowseFocus() {
    if (!_appActive || !mounted) return;
    final node = FocusManager.instance.primaryFocus;
    final nodeContext = node?.context;
    if (node == null || node is FocusScopeNode || nodeContext == null) return;
    final pageBox = context.findRenderObject();
    final focusBox = nodeContext.findRenderObject();
    if (pageBox == null || focusBox == null) return;
    var current = focusBox.parent;
    while (current != null) {
      if (identical(current, pageBox)) {
        _lastCatalogBrowseFocus = node;
        return;
      }
      current = current.parent;
    }
  }

  void _syncCardFocusNodes(int length) {
    while (_cardFocusNodes.length > length) {
      final node = _cardFocusNodes.removeLast();
      node.dispose();
    }
    while (_cardFocusNodes.length < length) {
      final index = _cardFocusNodes.length;
      final node = FocusNode(debugLabel: 'CatalogBrowseCard-$index');
      node.addListener(() => _handleCardFocusChanged(node));
      _cardFocusNodes.add(node);
    }
  }

  void _handleBackFocusChanged() {
    if (!_backFocusNode.hasFocus || !_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleLoadMoreFocusChanged() {
    if (_loadMoreFocusNode.hasFocus) _centerNode(_loadMoreFocusNode);
  }

  void _handleCardFocusChanged(FocusNode node) {
    if (node.hasFocus) _centerNode(node);
  }

  void _centerNode(FocusNode node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !node.hasFocus || !_scrollController.hasClients) return;
      final nodeContext = node.context;
      if (nodeContext == null) return;
      final box = nodeContext.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final center = box.localToGlobal(box.size.center(Offset.zero));
      final viewportHeight = MediaQuery.sizeOf(context).height;
      final target =
          (_scrollController.offset + center.dy - viewportHeight * 0.5).clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _restoreReturnFocus() {
    final node = widget.returnFocusNode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (node?.context != null) node?.requestFocus();
    });
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      _restoreReturnFocus();
    }
  }

  void _focus(FocusNode node) => Dpad.of(context).requestFocus(node);

  int _gridColumns(WarpTokens t, double availableWidth) {
    return math.max(
      1,
      ((availableWidth + t.cardGap) / (t.posterWidth + t.cardGap)).floor(),
    );
  }

  void _focusCard(int index) {
    if (index < 0 || index >= _cardFocusNodes.length) return;
    _focus(_cardFocusNodes[index]);
  }

  bool _cardDirection(int index, int columns, TraversalDirection direction) {
    final rowStart = (index ~/ columns) * columns;
    final rowEnd = math.min(rowStart + columns - 1, _cardFocusNodes.length - 1);

    if (direction == TraversalDirection.left) {
      if (index == rowStart) return true;
      _focusCard(index - 1);
      return true;
    }

    if (direction == TraversalDirection.right) {
      if (index == rowEnd) {
        _focus(_scrollRailFocusNode);
        return true;
      }
      _focusCard(index + 1);
      return true;
    }

    if (direction == TraversalDirection.up) {
      final previous = index - columns;
      if (previous >= 0) {
        _focusCard(previous);
      } else {
        _focus(_backFocusNode);
      }
      return true;
    }

    if (direction == TraversalDirection.down) {
      final next = index + columns;
      if (next < _cardFocusNodes.length) {
        _focusCard(next);
      } else if (_hasMore) {
        _focus(_loadMoreFocusNode);
      }
      return true;
    }

    return false;
  }

  bool _backDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.down && _cardFocusNodes.isNotEmpty) {
      _focusCard(0);
      return true;
    }
    return direction == TraversalDirection.left ||
        direction == TraversalDirection.up ||
        direction == TraversalDirection.right;
  }

  bool _loadMoreDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.up && _cardFocusNodes.isNotEmpty) {
      _focusCard(_cardFocusNodes.length - 1);
      return true;
    }
    if (direction == TraversalDirection.right) {
      _focus(_scrollRailFocusNode);
      return true;
    }
    return direction == TraversalDirection.left ||
        direction == TraversalDirection.down;
  }

  void _scrollBrowse(double direction) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final next =
        (position.pixels + position.viewportDimension * 0.85 * direction).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
    position.animateTo(
      next,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  List<FocusNode> _browseFocusNodes() => [
    _backFocusNode,
    ..._cardFocusNodes,
    if (_hasMore) _loadMoreFocusNode,
  ];

  bool _focusNearestFromRail() {
    final nodes = _browseFocusNodes()
        .where((node) => node.context != null && node != _scrollRailFocusNode)
        .toList();
    if (nodes.isEmpty) return true;
    final railContext = _scrollRailFocusNode.context;
    final railBox = railContext?.findRenderObject();
    final railCenter = railBox is RenderBox && railBox.hasSize
        ? railBox.localToGlobal(railBox.size.center(Offset.zero)).dy
        : MediaQuery.sizeOf(context).height / 2;
    FocusNode? best;
    var bestDistance = double.infinity;
    var bestX = double.negativeInfinity;
    for (final node in nodes) {
      final nodeContext = node.context;
      if (nodeContext == null) continue;
      final box = nodeContext.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final center = box.localToGlobal(box.size.center(Offset.zero));
      final distance = (center.dy - railCenter).abs();
      if (distance < bestDistance - 0.5 ||
          ((distance - bestDistance).abs() <= 0.5 && center.dx > bestX)) {
        best = node;
        bestDistance = distance;
        bestX = center.dx;
      }
    }
    if (best != null) _focus(best);
    return true;
  }

  bool _scrollRailDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.up) {
      _scrollBrowse(-1);
      return true;
    }
    if (direction == TraversalDirection.down) {
      _scrollBrowse(1);
      return true;
    }
    if (direction == TraversalDirection.left) return _focusNearestFromRail();
    if (direction == TraversalDirection.right) return true;
    return false;
  }

  void _requestInitialFocusIfReady() {
    if (_initialFocusRequested || _isLoading || _cardFocusNodes.isEmpty) return;
    _initialFocusRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _cardFocusNodes.first.context != null) {
        _focus(_cardFocusNodes.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final hPad = (size.width * 0.02).clamp(24.0, 48.0);
    final rowGap = (size.height * 0.015).clamp(16.0, 28.0);
    _syncCardFocusNodes(_items.length);
    final columns = _gridColumns(t, size.width - (hPad * 2));
    _requestInitialFocusIfReady();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _goBack,
        const SingleActivator(LogicalKeyboardKey.goBack): _goBack,
        const SingleActivator(LogicalKeyboardKey.browserBack): _goBack,
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF181818),
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: t.tabBarHeight),

                  _Header(
                    title: _displayTitle,
                    itemCount: _items.length,
                    hasMore: _hasMore,
                    isLoading: _isLoading,
                    error: _error,
                    hPad: hPad,
                    t: t,
                    focusNode: _backFocusNode,
                    onBack: _goBack,
                    onDirection: _backDirection,
                  ),

                  if (_isLoading)
                    SizedBox(
                      height: size.height * 0.5,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0DB2E2),
                          strokeWidth: 2,
                        ),
                      ),
                    ),

                  if (!_isLoading && _error != null)
                    Padding(
                      padding: EdgeInsets.only(
                        left: hPad,
                        top: (size.height * 0.1).clamp(40.0, 80.0),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: const Color(0xFFEF4444),
                          fontSize: t.fontBody,
                        ),
                      ),
                    ),

                  if (!_isLoading && _error == null) ...[
                    if (_items.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: (size.height * 0.1).clamp(40.0, 80.0),
                        ),
                        child: Center(
                          child: Text(
                            'No titles available.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: t.fontBody,
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: Wrap(
                          spacing: t.cardGap,
                          runSpacing: rowGap,
                          children: [
                            for (var i = 0; i < _items.length; i++)
                              PosterCard(
                                key: ValueKey(_items[i].id),
                                item: _items[i],
                                isSelected: false,
                                tokens: t,
                                focusNode: i < _cardFocusNodes.length
                                    ? _cardFocusNodes[i]
                                    : null,
                                entry: i == 0,
                                onDirection: (direction) =>
                                    _cardDirection(i, columns, direction),
                                autoScroll: false,
                                onTap: () => context.push(
                                  '/detail/${_items[i].type}/${_items[i].tmdbId ?? _items[i].id}',
                                  extra: DetailRouteExtra(
                                    item: _items[i],
                                    returnFocusNode: i < _cardFocusNodes.length
                                        ? _cardFocusNodes[i]
                                        : null,
                                  ),
                                ),
                                onDoubleTap: () => context.push(
                                  '/detail/${_items[i].type}/${_items[i].tmdbId ?? _items[i].id}',
                                  extra: DetailRouteExtra(
                                    item: _items[i],
                                    returnFocusNode: i < _cardFocusNodes.length
                                        ? _cardFocusNodes[i]
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                    if (_hasMore)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: (size.height * 0.03).clamp(24.0, 48.0),
                        ),
                        child: Center(
                          child: _SecondaryBtn(
                            width: 150,
                            height: 40,
                            focusNode: _loadMoreFocusNode,
                            onDirection: _loadMoreDirection,
                            onTap: _loadMore,
                            t: t,
                            child: _isLoadingMore
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Load More',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: t.fontBody,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                    if (!_hasMore && _items.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: (size.height * 0.025).clamp(20.0, 36.0),
                        ),
                        child: Center(
                          child: Text(
                            '${_items.length} title${_items.length != 1 ? 's' : ''} total',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: t.fontSubtitle,
                            ),
                          ),
                        ),
                      ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: _CatalogBrowseScrollRail(
                focusNode: _scrollRailFocusNode,
                onDirection: _scrollRailDirection,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header: Back button (absolute left) + centered title + subtitle
// Mirrors Tauri's position:relative wrapper with position:absolute Back button.
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.itemCount,
    required this.hasMore,
    required this.isLoading,
    required this.error,
    required this.hPad,
    required this.t,
    required this.focusNode,
    required this.onBack,
    required this.onDirection,
  });

  final String title;
  final int itemCount;
  final bool hasMore;
  final bool isLoading;
  final String? error;
  final double hPad;
  final WarpTokens t;
  final FocusNode focusNode;
  final VoidCallback onBack;
  final DpadDirectionCallback onDirection;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final vPad = (size.height * 0.015).clamp(16.0, 28.0);
    final vPadBottom = (size.height * 0.012).clamp(12.0, 20.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPadBottom),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _BackBtn(
              t: t,
              focusNode: focusNode,
              onBack: onBack,
              onDirection: onDirection,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: t.pageTitleSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              if (!isLoading && error == null && itemCount > 0)
                Text(
                  '$itemCount title${itemCount != 1 ? 's' : ''}${hasMore ? '+' : ''}',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: t.fontSubtitle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Back button — btn-secondary style with hover: bg lightens + border turns cyan
// ─────────────────────────────────────────────────────────────────────────────

class _BackBtn extends StatefulWidget {
  const _BackBtn({
    required this.t,
    required this.focusNode,
    required this.onBack,
    required this.onDirection,
  });
  final WarpTokens t;
  final FocusNode focusNode;
  final VoidCallback onBack;
  final DpadDirectionCallback onDirection;

  @override
  State<_BackBtn> createState() => _BackBtnState();
}

class _BackBtnState extends State<_BackBtn> {
  @override
  Widget build(BuildContext context) {
    return WarpDpadButton(
      width: 100,
      height: 40,
      padding: EdgeInsets.zero,
      tokens: widget.t,
      focusNode: widget.focusNode,
      onDirection: widget.onDirection,
      onSelect: widget.onBack,
      backgroundColor: const Color(0xCC333232),
      focusBackgroundColor: const Color(0xFF8B5CF6),
      borderColor: const Color(0xFF8B5CF6),
      focusBorderColor: const Color(0xFF8B5CF6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.arrow_back, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'Back',
            style: TextStyle(
              color: Colors.white,
              fontSize: (MediaQuery.sizeOf(context).width * 0.009).clamp(
                13.0,
                16.0,
              ),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Load More button — btn-secondary style
// ─────────────────────────────────────────────────────────────────────────────

class _SecondaryBtn extends StatefulWidget {
  const _SecondaryBtn({
    required this.width,
    required this.height,
    required this.focusNode,
    required this.onDirection,
    required this.onTap,
    required this.t,
    required this.child,
  });

  final double width;
  final double height;
  final FocusNode focusNode;
  final DpadDirectionCallback onDirection;
  final VoidCallback onTap;
  final WarpTokens t;
  final Widget child;

  @override
  State<_SecondaryBtn> createState() => _SecondaryBtnState();
}

class _SecondaryBtnState extends State<_SecondaryBtn> {
  @override
  Widget build(BuildContext context) {
    return WarpDpadButton(
      width: widget.width,
      height: widget.height,
      padding: EdgeInsets.zero,
      tokens: widget.t,
      focusNode: widget.focusNode,
      onDirection: widget.onDirection,
      onSelect: widget.onTap,
      backgroundColor: const Color(0xCC333232),
      focusBackgroundColor: const Color(0xFF0DB2E2),
      borderColor: const Color(0xFF0DB2E2),
      focusBorderColor: const Color(0xFF0DB2E2),
      child: widget.child,
    );
  }
}

class _CatalogBrowseScrollRail extends StatelessWidget {
  final FocusNode focusNode;
  final DpadDirectionCallback onDirection;

  const _CatalogBrowseScrollRail({
    required this.focusNode,
    required this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Center(
        child: DpadFocusable(
          focusNode: focusNode,
          onDirection: onDirection,
          onSelect: () {},
          tapToSelect: false,
          builder: (context, state, child) => AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: state.focused ? 8 : 4,
            height: 132,
            decoration: BoxDecoration(
              color: state.focused
                  ? const Color(0xFF0DB2E2)
                  : Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(999),
              boxShadow: state.focused
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0DB2E2).withAlpha(120),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
