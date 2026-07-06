import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api_client.dart';
import '../models/catalog.dart';
import '../models/media.dart';
import '../theme/warp_tokens.dart';
import '../widgets/cards/poster_card.dart';
import '../widgets/layout/backdrop_layer.dart';
import '../widgets/shared/dpad_controls.dart';

const _kPageSize = 20;

class CatalogBrowsePage extends ConsumerStatefulWidget {
  const CatalogBrowsePage({
    super.key,
    required this.provider,
    required this.category,
    this.mediaType = 'movie',
    this.title,
  });

  final String provider;
  final String category;
  final String mediaType;
  final String? title;

  @override
  ConsumerState<CatalogBrowsePage> createState() => _CatalogBrowsePageState();
}

class _CatalogBrowsePageState extends ConsumerState<CatalogBrowsePage> {
  List<MediaItem> _items = [];
  int _offset = 0;
  bool _hasMore = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(backdropProvider.notifier).clear();
    });
    _fetchPage(0);
  }

  String get _displayTitle =>
      widget.title ?? widget.category.replaceAll('_', ' ');

  Future<CatalogResponse?> _fetchCatalog(int offset) async {
    final client = ref.read(apiClientProvider);
    final raw = await client.get<Map<String, dynamic>>(
      '/api/v1/catalog/${widget.provider}/${widget.category}',
      params: {
        'media_type': widget.mediaType,
        'limit': _kPageSize,
        'offset': offset,
      },
    );
    return CatalogResponse.fromJson(raw);
  }

  bool _computeHasMore(CatalogResponse data, int currentOffset) {
    if (data.total != null) {
      return currentOffset + data.count < data.total!;
    }
    return data.count >= _kPageSize;
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
      final data = await _fetchCatalog(offset);
      if (!mounted || data == null) return;
      setState(() {
        _items = offset == 0 ? data.items : [..._items, ...data.items];
        _offset = offset;
        _hasMore = _computeHasMore(data, offset);
      });
    } catch (_) {
      if (mounted && offset == 0) {
        setState(() => _error = 'Failed to load catalog. Is the backend running?');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextOffset = _offset + _kPageSize;
      final data = await _fetchCatalog(nextOffset);
      if (!mounted || data == null) return;
      setState(() {
        _items = [..._items, ...data.items];
        _offset = nextOffset;
        _hasMore = _computeHasMore(data, nextOffset);
      });
    } catch (_) {
      // silently ignore load-more failures
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final hPad = (size.width * 0.02).clamp(24.0, 48.0);
    final rowGap = (size.height * 0.015).clamp(16.0, 28.0);

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      body: SingleChildScrollView(
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
                      style: TextStyle(color: Colors.white54, fontSize: t.fontBody),
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
                      for (final item in _items)
                        PosterCard(
                          key: ValueKey(item.id),
                          item: item,
                          isSelected: false,
                          tokens: t,
                          onTap: () => context.push(
                            '/detail/${item.type}/${item.tmdbId ?? item.id}',
                            extra: item,
                          ),
                          onDoubleTap: () => context.push(
                            '/detail/${item.type}/${item.tmdbId ?? item.id}',
                            extra: item,
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
                      style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 24),
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
  });

  final String title;
  final int itemCount;
  final bool hasMore;
  final bool isLoading;
  final String? error;
  final double hPad;
  final WarpTokens t;

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
            child: _BackBtn(t: t),
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
                  style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
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
  const _BackBtn({required this.t});
  final WarpTokens t;

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
      onSelect: () => context.pop(),
      backgroundColor: Colors.white.withAlpha(15),
      focusBackgroundColor: Colors.white.withAlpha(26),
      borderColor: Colors.white.withAlpha(26),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.arrow_back, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'Back',
            style: TextStyle(
              color: Colors.white,
              fontSize: (MediaQuery.sizeOf(context).width * 0.009).clamp(13.0, 16.0),
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
    required this.onTap,
    required this.t,
    required this.child,
  });

  final double width;
  final double height;
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
      onSelect: widget.onTap,
      backgroundColor: Colors.white.withAlpha(15),
      focusBackgroundColor: Colors.white.withAlpha(26),
      borderColor: Colors.white.withAlpha(26),
      child: widget.child,
    );
  }
}
