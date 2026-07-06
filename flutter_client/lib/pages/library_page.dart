import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api/api_client.dart';
import '../models/collection.dart';
import '../models/media.dart';
import '../providers/catalog_provider.dart';
import '../providers/library_provider.dart';
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
    _SortOpt('added_at-desc',  'Date Added (newest)', 'added_at',   'desc'),
    _SortOpt('added_at-asc',   'Date Added (oldest)', 'added_at',   'asc'),
    _SortOpt('title-asc',      'Name (A–Z)',           'title',      'asc'),
    _SortOpt('title-desc',     'Name (Z–A)',            'title',      'desc'),
    _SortOpt('rating-desc',    'Highest Rated',         'rating',     'desc'),
    _SortOpt('vote_count-desc','Most Voted',            'vote_count', 'desc'),
  ];

  static _SortOpt find(String v) =>
      all.firstWhere((o) => o.value == v, orElse: () => all.first);
}

// ─────────────────────────────────────────────────────────────────────────────
// LibraryPage
// ─────────────────────────────────────────────────────────────────────────────

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  _LibTab _tab       = _LibTab.liked;
  _MediaTypeF _mt    = _MediaTypeF.movie;
  String _sortValue  = 'added_at-desc';

  @override
  void initState() {
    super.initState();
    // Clear the global backdrop so it doesn't bleed through the Library page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(backdropProvider.notifier).clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t    = WarpTokens.watch(context, ref);
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
              hPad, 0,
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
                ),
              _LibTab.wishlist => _CollectionTab(
                  key: const ValueKey('wishlist'),
                  collectionType: 'wishlist',
                  mediaType: _mt,
                  sortValue: _sortValue,
                  onMediaType: (v) => setState(() => _mt = v),
                  onSort: (v) => setState(() => _sortValue = v),
                ),
              _LibTab.discover => _DiscoverTab(
                  mediaType: _mt,
                  onMediaType: (v) => setState(() => _mt = v),
                ),
              _LibTab.local => _LocalTab(
                  mediaType: _mt,
                  onMediaType: (v) => setState(() => _mt = v),
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

  const _SubTabNav({
    required this.selected,
    required this.onSelect,
    required this.screenSize,
    required this.t,
  });

  static const _tabs = [
    (tab: _LibTab.liked,    icon: Icons.favorite_border,  label: 'Liked'),
    (tab: _LibTab.wishlist, icon: Icons.add,               label: 'Wishlist'),
    (tab: _LibTab.discover, icon: Icons.explore_outlined,  label: 'Discover'),
    (tab: _LibTab.local,    icon: Icons.folder_outlined,   label: 'Local'),
  ];

  @override
  Widget build(BuildContext context) {
    final w    = screenSize.width;
    final h    = screenSize.height;
    final gap  = (w * 0.012).clamp(10.0, 24.0);
    final padV = (h * 0.012).clamp(12.0, 20.0);
    final fs   = (w * 0.009).clamp(14.0, 17.0);

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
                  entry: i == 0,
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

  const _Pill({
    required this.icon, required this.label, required this.isActive,
    required this.onTap, required this.padV, required this.padH,
    required this.fontSize, required this.t, this.entry = false,
  });

  @override
  Widget build(BuildContext context) => WarpDpadButton(
    tokens: t,
    entry: entry,
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

  const _TypeToggle({required this.value, required this.onChange, required this.t});

  @override
  Widget build(BuildContext context) {
    final w   = MediaQuery.sizeOf(context).width;
    final fs  = (w * 0.0085).clamp(13.0, 15.0);
    final padV = (w * 0.0045).clamp(6.0, 10.0);
    final padH = (w * 0.011).clamp(14.0, 22.0);

    return DpadRegion(
      memoryKey: 'library-type-toggle',
      horizontalEdge: DpadEdgeBehavior.stop,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in _MediaTypeF.values)
            WarpDpadButton(
              tokens: t,
              onSelect: () => onChange(option),
              padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
              backgroundColor: value == option ? const Color(0x26FFFFFF) : Colors.transparent,
              borderColor: value == option ? const Color(0x33FFFFFF) : Colors.transparent,
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

  const _SortButton({required this.sortValue, required this.onSort, required this.t});

  @override
  Widget build(BuildContext context) {
    final w       = MediaQuery.sizeOf(context).width;
    final fs      = (w * 0.008).clamp(12.0, 14.0);
    final current = _SortOpt.find(sortValue);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Sort:', style: TextStyle(fontSize: fs, color: Colors.white38)),
        const SizedBox(width: 8),
        WarpDpadButton(
          tokens: t,
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
            if (result != null) onSort(result);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(current.label, style: TextStyle(fontSize: fs, color: Colors.white70)),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white38),
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
                    autofocus: i == 0,
                    entry: i == 0,
                    onSelect: () => Navigator.of(context).pop(_SortOpt.all[i].value),
                    backgroundColor: _SortOpt.all[i].value == current
                        ? const Color(0x220DB2E2)
                        : Colors.white.withAlpha(8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: _SortOpt.all[i].value == current
                              ? const Icon(Icons.check_circle, size: 15, color: Color(0xFF0DB2E2))
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_SortOpt.all[i].label, style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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

  const _ControlsRow({
    required this.mediaType, required this.sortValue, required this.t,
    required this.onMediaType, required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = (size.width * 0.02).clamp(24.0, 48.0);
    final vPad = (size.height * 0.012).clamp(12.0, 20.0);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, (size.height * 0.01).clamp(10.0, 16.0)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TypeToggle(value: mediaType, onChange: onMediaType, t: t),
              _SortButton(sortValue: sortValue, onSort: onSort, t: t),
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

  const _CollectionTab({
    super.key,
    required this.collectionType,
    required this.mediaType,
    required this.sortValue,
    required this.onMediaType,
    required this.onSort,
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

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
  }

  @override
  void didUpdateWidget(_CollectionTab old) {
    super.didUpdateWidget(old);
    if (old.mediaType != widget.mediaType || old.sortValue != widget.sortValue) {
      _fetch(reset: true);
    }
  }

  Future<void> _fetch({required bool reset}) async {
    if (!mounted) return;
    if (reset) {
      setState(() { _isLoading = true; _items = []; _page = 1; });
    } else {
      setState(() => _isLoadingMore = true);
    }

    final opt  = _SortOpt.find(widget.sortValue);
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
      setState(() {
        _items = reset ? resp.items : [..._items, ...resp.items];
        _total = resp.count;
        _page  = page;
      });
    } catch (_) {
      // Leave _items as-is; spinner will stop below.
    } finally {
      if (mounted) setState(() { _isLoading = false; _isLoadingMore = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t    = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final hPad = (size.width * 0.02).clamp(24.0, 48.0);

    return Column(
      children: [
        _ControlsRow(
          mediaType: widget.mediaType, sortValue: widget.sortValue,
          t: t,
          onMediaType: widget.onMediaType, onSort: widget.onSort,
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0DB2E2), strokeWidth: 2))
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.collectionType == 'liked' ? Icons.favorite_border : Icons.add,
                            size: 52, color: Colors.white.withAlpha(38),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.collectionType == 'liked'
                                ? 'Your liked titles will appear here.'
                                : 'Your wishlist will appear here.',
                            style: TextStyle(fontSize: t.fontBody, color: Colors.white54),
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
    final cols = (size.width / (t.posterWidth + t.cardGap)).floor().clamp(2, 10);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(hPad).copyWith(top: (size.height * 0.015).clamp(16.0, 24.0)),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: (size.height * 0.018).clamp(16.0, 28.0),
              crossAxisSpacing: t.cardGap,
              childAspectRatio: t.posterWidth / t.posterCardTotalHeight,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final item = collectionToMedia(_items[i]);
                return PosterCard(
                  item: item, isSelected: false, tokens: t,
                  onTap: () => context.push('/detail/${item.type}/${item.tmdbId ?? item.id}', extra: item),
                  onDoubleTap: () => context.push('/detail/${item.type}/${item.tmdbId ?? item.id}', extra: item),
                );
              },
              childCount: _items.length,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
            child: Center(
              child: hasMore
                  ? WarpDpadButton(
                      tokens: t,
                      width: 150,
                      height: 40,
                      padding: EdgeInsets.zero,
                      enabled: !_isLoadingMore,
                      onSelect: () => _fetch(reset: false),
                      child: _isLoadingMore
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF0DB2E2), strokeWidth: 2))
                          : const Text('Load More', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    )
                  : Text(
                      '$_total title${_total != 1 ? 's' : ''} total',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
            ),
          ),
        ),
      ],
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
      (_scrollCtrl.offset - widget.scrollAmount).clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollRight() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      (_scrollCtrl.offset + widget.scrollAmount).clamp(0.0, _scrollCtrl.position.maxScrollExtent),
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
              left: 4, top: 0, bottom: 0,
              child: Center(
                child: AbsorbPointer(
                  absorbing: !_hovered,
                  child: AnimatedOpacity(
                    opacity: _hovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: _LibChevronBtn(icon: Icons.chevron_left, onTap: _scrollLeft),
                  ),
                ),
              ),
            ),

            Positioned(
              right: 4, top: 0, bottom: 0,
              child: Center(
                child: AbsorbPointer(
                  absorbing: !_hovered,
                  child: AnimatedOpacity(
                    opacity: _hovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: _LibChevronBtn(icon: Icons.chevron_right, onTap: _scrollRight),
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
              BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 2)),
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
  const _DiscoverSeeMoreBtn({required this.onTap, required this.t});
  @override
  State<_DiscoverSeeMoreBtn> createState() => _DiscoverSeeMoreBtnState();
}

class _DiscoverSeeMoreBtnState extends State<_DiscoverSeeMoreBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return WarpDpadButton(
      tokens: widget.t,
      onSelect: widget.onTap,
      backgroundColor: Colors.transparent,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _hovered ? const Color(0xFF0DB2E2) : const Color(0xFF0DB2E2).withAlpha(180),
              ),
              child: const Text('See More'),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _hovered ? 1.0 : 0.7,
              child: const Icon(Icons.chevron_right, size: 13, color: Color(0xFF0DB2E2)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DiscoverTab — catalog ribbons from TMDb, filtered by mediaType
// Mirrors DiscoverSubTab.tsx (uses TMDb providers since Trakt may not be auth'd)
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoverTab extends ConsumerWidget {
  final _MediaTypeF mediaType;
  final void Function(_MediaTypeF) onMediaType;

  const _DiscoverTab({required this.mediaType, required this.onMediaType});

  static const _sections = [
    (provider: 'trakt', category: 'trending',    label: 'Trending Now'),
    (provider: 'trakt', category: 'popular',     label: 'Popular'),
    (provider: 'trakt', category: 'anticipated', label: 'Most Anticipated'),
    (provider: 'trakt', category: 'watched',     label: 'Most Watched'),
    (provider: 'trakt', category: 'played',      label: 'Most Played'),
    (provider: 'trakt', category: 'collected',   label: 'Most Collected'),
    (provider: 'trakt', category: 'favorited',   label: 'Most Favorited'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t    = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final hPad = (size.width * 0.02).clamp(20.0, 40.0);
    final mt   = mediaType.name; // 'movie' or 'show'

    return Column(
      children: [
        // Movies / Shows toggle (centered)
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: (size.height * 0.012).clamp(12.0, 20.0),
          ),
          child: Center(child: _TypeToggle(value: mediaType, onChange: onMediaType, t: t)),
        ),
        Container(height: 1, margin: EdgeInsets.symmetric(horizontal: hPad), color: Colors.white.withAlpha(20)),

        // Ribbon sections
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: (size.height * 0.015).clamp(16.0, 24.0), bottom: 24),
              child: Column(
                children: [
                  for (final s in _sections)
                    _DiscoverRibbon(
                      key: ValueKey('${s.category}-$mt'),
                      label: s.label,
                      provider: s.provider,
                      category: s.category,
                      mediaType: mt,
                      t: t,
                      hPad: hPad,
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

class _DiscoverRibbon extends ConsumerWidget {
  final String label, provider, category, mediaType;
  final WarpTokens t;
  final double hPad;

  const _DiscoverRibbon({
    super.key,
    required this.label, required this.provider,
    required this.category, required this.mediaType,
    required this.t, required this.hPad,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final async = ref.watch(catalogDataProvider(
      provider: provider, category: category, mediaType: mediaType,
    ));

    return async.when(
      loading: () => SizedBox(height: t.posterCardTotalHeight + 60),
      error: (_, _) => const SizedBox.shrink(),
      data: (catalog) {
        if (catalog.items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: (size.width * 0.0095).clamp(14.0, 17.0),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.02,
                    ),
                  ),
                  _DiscoverSeeMoreBtn(
                    t: t,
                    onTap: () => context.push(
                      '/catalog/$provider/$category?type=$mediaType&title=${Uri.encodeComponent(label)}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _HoverableRibbon(
              height: t.posterCardTotalHeight + 16,
              scrollAmount: 700,
              builder: (ctrl) => ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: ListView.separated(
                  controller: ctrl,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
                  itemCount: catalog.items.length,
                  separatorBuilder: (context, i) => SizedBox(width: t.cardGap),
                  itemBuilder: (_, i) {
                    final item = catalog.items[i];
                    return PosterCard(
                      item: item, isSelected: false, tokens: t,
                      onTap: () => context.push('/detail/${item.type}/${item.tmdbId ?? item.id}', extra: item),
                      onDoubleTap: () => context.push('/detail/${item.type}/${item.tmdbId ?? item.id}', extra: item),
                    );
                  },
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

class _LocalTab extends ConsumerWidget {
  final _MediaTypeF mediaType;
  final void Function(_MediaTypeF) onMediaType;

  const _LocalTab({required this.mediaType, required this.onMediaType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t    = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final hPad = (size.width * 0.02).clamp(20.0, 36.0);

    final recentAsync = mediaType == _MediaTypeF.movie
        ? ref.watch(libraryMoviesProvider)
        : ref.watch(libraryShowsProvider);
    final azAsync = mediaType == _MediaTypeF.movie
        ? ref.watch(libraryMoviesAzProvider)
        : ref.watch(libraryShowsAzProvider);

    final recentItems = recentAsync.asData?.value.items.map(libraryItemToMedia).toList() ?? [];
    final azItems     = azAsync.asData?.value.items.map(libraryItemToMedia).toList() ?? [];
    final hasContent  = recentItems.isNotEmpty || azItems.isNotEmpty;
    final isLoading   = recentAsync.isLoading || azAsync.isLoading;

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
              Icon(Icons.folder_open_outlined, size: 40, color: Colors.white.withAlpha(38)),
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
                width: double.infinity,
                backgroundColor: const Color(0xFF0DB2E2),
                focusBackgroundColor: const Color(0xFF0DB2E2),
                borderColor: const Color(0xFF0DB2E2),
                focusBorderColor: Colors.white,
                onSelect: () => showDialog<void>(
                  context: context,
                  builder: (_) => const ScanDialog(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.document_scanner_outlined, color: Colors.black, size: 15),
                    const SizedBox(width: 8),
                    Text(
                      'Start Scanning',
                      style: TextStyle(
                        color: Colors.black,
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
                  _TypeToggle(value: mediaType, onChange: onMediaType, t: t),
                  ],
                ),
              ),
              Container(height: 1, margin: EdgeInsets.symmetric(horizontal: hPad), color: Colors.white.withAlpha(20)),

              // Ribbons
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
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
                        ),
                        _LocalRibbon(
                          label: 'Names A–Z',
                          items: azItems,
                          isLoading: azAsync.isLoading,
                          t: t,
                          hPad: hPad,
                        ),
                        // Empty state — shown only when both ribbons have finished loading with no content
                        if (!isLoading && !hasContent)
                          Padding(
                            padding: EdgeInsets.only(top: (size.height * 0.12).clamp(48.0, 100.0)),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.folder_open_outlined, size: 48, color: Colors.white.withAlpha(38)),
                                  const SizedBox(height: 16),
                                  Text('No local media yet.', style: TextStyle(color: Colors.white54, fontSize: t.bodySize)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Click "Start Scanning" to import movies and shows.',
                                    style: TextStyle(color: Colors.white38, fontSize: t.subtitleSize),
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

class _LocalRibbon extends StatelessWidget {
  final String label;
  final List<MediaItem> items;
  final bool isLoading;
  final WarpTokens t;
  final double hPad;

  const _LocalRibbon({
    required this.label,
    required this.items,
    required this.isLoading,
    required this.t,
    required this.hPad,
  });

  @override
  Widget build(BuildContext context) {
    // Mirror Tauri: hide the ribbon when done loading and empty
    if (!isLoading && items.isEmpty) return const SizedBox.shrink();

    final w = MediaQuery.sizeOf(context).width;
    final titleFs = (w * 0.0095).clamp(14.0, 17.0);

    return Padding(
      padding: EdgeInsets.only(bottom: (w * 0.02).clamp(20.0, 32.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: hPad, right: hPad, bottom: (w * 0.005).clamp(6.0, 10.0)),
            child: Text(
              label,
              style: TextStyle(
                fontSize: titleFs,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: titleFs * 0.02,
              ),
            ),
          ),
          if (isLoading)
            SizedBox(
              height: t.posterCardTotalHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: hPad),
                itemCount: 6,
                separatorBuilder: (context, i) => SizedBox(width: t.cardGap),
                itemBuilder: (context, i) => _LocalSkeletonCard(t: t),
              ),
            )
          else
            _HoverableRibbon(
              height: t.posterCardTotalHeight + 16,
              scrollAmount: 700,
              builder: (ctrl) => ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: ListView.separated(
                  controller: ctrl,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (context, i) => SizedBox(width: t.cardGap),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return PosterCard(
                      item: item, isSelected: false, tokens: t,
                      onTap: () => context.push('/detail/${item.type}/${item.tmdbId ?? item.id}', extra: item),
                      onDoubleTap: () => context.push('/detail/${item.type}/${item.tmdbId ?? item.id}', extra: item),
                    );
                  },
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
