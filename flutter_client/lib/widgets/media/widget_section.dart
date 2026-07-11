import 'dart:async';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/catalog_constants.dart';
import '../../models/media.dart';
import '../../navigation/catalog_browse_route_extra.dart';
import '../../navigation/row_first_card_registry.dart';
import '../../navigation/tab_bar_focus_registry.dart';
import '../../navigation/detail_route_extra.dart';
import '../../providers/detail_provider.dart';
import '../../theme/warp_theme.dart';
import '../../theme/warp_tokens.dart';
import '../cards/widget_ribbon_card.dart';
import '../layout/backdrop_layer.dart';
import '../shared/warp_accent_button.dart';
import 'trailer_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WidgetSection — full-viewport-height snap section with backdrop hero + ribbon
//
// Mirrors WidgetSection.tsx exactly:
//   • Full screen height, snap-start (PageScrollPhysics in MoviesPage)
//   • Backdrop fills entire section; tab bar floats above via AppShell Stack
//   • Hero: title, synopsis (auto-scroll if > 3 lines), ratings, year/runtime,
//            Play Trailer + More Info/Resume buttons
//   • Bottom ribbon: PosterCards + section header + "See More"
// ─────────────────────────────────────────────────────────────────────────────

class WidgetSection extends ConsumerStatefulWidget {
  final String title;
  final List<MediaItem> items;
  final bool isLoading;
  final String mediaType;
  final String? provider;
  final String? category;
  final int rowIndex;
  final bool initialFocus;
  // This page's own tab-bar route (e.g. '/' for Movies, '/shows' for Shows) —
  // used so row 0's hero group can focus this page's own tab pill on Up.
  final String ownRoute;
  // Page-owned registry (MoviesPage/ShowsPage/SearchPage each pass their own
  // instance) mapping rowIndex -> that row's first poster card FocusNode.
  final RowFirstCardRegistry rowRegistry;
  final int rowCount;
  final Future<void> Function(int rowIndex)? onRowFocusRequested;
  final void Function(int rowIndex)? onFirstCardRegistered;

  const WidgetSection({
    super.key,
    required this.title,
    required this.items,
    required this.rowIndex,
    required this.ownRoute,
    required this.rowRegistry,
    required this.rowCount,
    this.isLoading = false,
    this.mediaType = 'movie',
    this.provider,
    this.category,
    this.initialFocus = false,
    this.onRowFocusRequested,
    this.onFirstCardRegistered,
  });

  @override
  ConsumerState<WidgetSection> createState() => _WidgetSectionState();
}

class _WidgetSectionState extends ConsumerState<WidgetSection> {
  int _selectedIdx = 0;
  late final ScrollController _ribbonScroll;
  late final ScrollController _synopsisScroll;
  late List<FocusNode> _focusNodes;
  Timer? _synopsisTimer;

  // Hero action-group focus nodes. Play Trailer is the hero group's entry
  // point when a trailer is available (_hasTrailer, kept in sync from
  // build()); otherwise More Info/Resume is. See More is registered
  // separately and only mounted when provider+category are set.
  late final FocusNode _playTrailerFocusNode = FocusNode(
    debugLabel: 'PlayTrailer-row${widget.rowIndex}',
  );
  late final FocusNode _moreInfoFocusNode = FocusNode(
    debugLabel: 'MoreInfo-row${widget.rowIndex}',
  );
  late final FocusNode _seeMoreFocusNode = FocusNode(
    debugLabel: 'SeeMore-row${widget.rowIndex}',
  );
  bool _hasTrailer = false;

  FocusNode get _heroEntryFocusNode =>
      _hasTrailer ? _playTrailerFocusNode : _moreInfoFocusNode;

  String get _regionPrefix =>
      '${widget.ownRoute.replaceAll('/', '_')}-${widget.mediaType}-${widget.rowIndex}';

  @override
  void initState() {
    super.initState();
    _ribbonScroll = ScrollController();
    _synopsisScroll = ScrollController();
    _rebuildFocusNodes();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _registerFirstCard();
      if (widget.initialFocus && _focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
      if (widget.initialFocus && widget.items.isNotEmpty) {
        final url = backdropUrl(widget.items[0].backdropPath);
        if (url.isNotEmpty) ref.read(backdropProvider.notifier).set(url);
      }
      _resetSynopsis();
    });
  }

  // ── D-pad navigation: shared onDirection callbacks ─────────────────────
  //
  // Up from any ribbon card -> this row's own hero entry button (local),
  //   except the ribbon's last card, whose Up instead goes to See More
  //   (when this row has one) — kept alongside the existing Right-arrow
  //   path from More Info/Resume, not replacing it.
  // Down from any ribbon card -> next row's 1st poster card (registry).
  // Down from the hero group -> this row's own ribbon 1st card (local).
  // Up from the hero group -> row 0: this page's own tab pill; else:
  //   previous row's ribbon 1st card (registry) — symmetric with ribbon's Down.
  // Left/Right are never intercepted here — default dpad beam traversal
  // handles them (both within the ribbon and within the hero group).

  bool get _hasSeeMore => widget.provider != null && widget.category != null;

  bool _ribbonDirection(int cardIdx, TraversalDirection d) {
    if (d == TraversalDirection.up) {
      if (_hasSeeMore && cardIdx == widget.items.length - 1) {
        Dpad.of(context).requestFocus(_seeMoreFocusNode);
      } else {
        Dpad.of(context).requestFocus(_heroEntryFocusNode);
      }
      return true;
    }
    if (d == TraversalDirection.down) {
      final target = widget.rowIndex + 1;
      if (target >= widget.rowCount) return true;
      if (widget.onRowFocusRequested != null) {
        unawaited(widget.onRowFocusRequested!(target));
        return true;
      }
      final next = widget.rowRegistry.entryFor(target);
      if (next != null) {
        Dpad.of(context).requestFocus(next);
      }
      return true;
    }
    return false;
  }

  bool _heroDirection(TraversalDirection d) {
    if (d == TraversalDirection.down) {
      if (_focusNodes.isNotEmpty) {
        // Return to whichever card was last focused in this row's ribbon
        // (already tracked by _selectItem via the per-card focus listener),
        // not always the 1st card — otherwise Down after Up-from-a-scrolled
        // -away card silently re-targeted an off-screen node.
        final idx = _selectedIdx.clamp(0, _focusNodes.length - 1);
        Dpad.of(context).requestFocus(_focusNodes[idx]);
        return true;
      }
      return false;
    }
    if (d == TraversalDirection.up) {
      if (widget.rowIndex == 0) {
        final tab = ref
            .read(tabBarFocusRegistryProvider)
            .forRoute(widget.ownRoute);
        if (tab != null) {
          Dpad.of(context).requestFocus(tab);
          return true;
        }
        return false;
      }
      final target = widget.rowIndex - 1;
      // Route through the same page-scroll-then-focus path Down uses —
      // the previous row's page may have scrolled off and been disposed
      // (PageView.builder tears down far-off pages), so a bare registry
      // lookup can silently miss; onRowFocusRequested re-scrolls the
      // PageView there first and retries focus once it re-registers.
      if (widget.onRowFocusRequested != null) {
        unawaited(widget.onRowFocusRequested!(target));
        return true;
      }
      final prev = widget.rowRegistry.entryFor(target);
      if (prev != null) {
        Dpad.of(context).requestFocus(prev);
        return true;
      }
      return false;
    }
    return false;
  }

  void _selectItem(int idx) {
    if (idx < 0 || idx >= widget.items.length) return;
    setState(() => _selectedIdx = idx);
    _centerCard(idx);
    final url = backdropUrl(widget.items[idx].backdropPath);
    if (url.isNotEmpty) ref.read(backdropProvider.notifier).set(url);
    _resetSynopsis();
  }

  void _rebuildFocusNodes() {
    _focusNodes = List.generate(widget.items.length, (_) => FocusNode());
    for (var i = 0; i < _focusNodes.length; i++) {
      final idx = i;
      _focusNodes[idx].addListener(() {
        if (_focusNodes[idx].hasFocus) _selectItem(idx);
      });
    }
  }

  void _registerFirstCard() {
    if (!mounted || _focusNodes.isEmpty) {
      widget.rowRegistry.unregister(widget.rowIndex);
      return;
    }
    widget.rowRegistry.register(widget.rowIndex, _focusNodes[0]);
    widget.onFirstCardRegistered?.call(widget.rowIndex);
  }

  // Reset synopsis scroll and start the 3-second auto-scroll timer.
  // Mirrors WidgetSection.tsx's useEffect on selected?.overview.
  void _resetSynopsis() {
    _synopsisTimer?.cancel();
    if (_synopsisScroll.hasClients) _synopsisScroll.jumpTo(0);
    _synopsisTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_synopsisScroll.hasClients) return;
      final max = _synopsisScroll.position.maxScrollExtent;
      if (max <= 0) return; // text fits in 3 lines — nothing to scroll
      // ~30px/sec to match Tauri's 0.5px/rAF at 60fps
      _synopsisScroll.animateTo(
        max,
        duration: Duration(milliseconds: (max / 30 * 1000).round()),
        curve: Curves.linear,
      );
    });
  }

  void _openTrailer(String url, String titleStr) {
    showDialog(
      context: context,
      builder: (_) => TrailerDialog(trailerUrl: url, title: titleStr),
    );
  }

  @override
  void didUpdateWidget(WidgetSection old) {
    super.didUpdateWidget(old);
    if (old.items.length != widget.items.length) {
      for (final fn in _focusNodes) {
        fn.dispose();
      }
      _selectedIdx = 0;
      _rebuildFocusNodes();
      _registerFirstCard();
    }
  }

  @override
  void dispose() {
    widget.rowRegistry.unregister(widget.rowIndex);
    _synopsisTimer?.cancel();
    _ribbonScroll.dispose();
    _synopsisScroll.dispose();
    _playTrailerFocusNode.dispose();
    _moreInfoFocusNode.dispose();
    _seeMoreFocusNode.dispose();
    for (final fn in _focusNodes) {
      fn.dispose();
    }
    super.dispose();
  }

  void _centerCard(int idx) {
    if (!_ribbonScroll.hasClients) return;
    final t = WarpTokens(UiDensity.desktop, MediaQuery.sizeOf(context));
    final cardW = t.ribbonPosterWidth + t.cardGap;
    final viewW = _ribbonScroll.position.viewportDimension;
    final target = (cardW * idx) - (viewW / 2 - t.ribbonPosterWidth / 2);
    _ribbonScroll.animateTo(
      target.clamp(0.0, _ribbonScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);

    if (widget.isLoading) return _buildSkeleton(size, t);
    if (widget.items.isEmpty) return _buildEmpty(size, t);

    final selected = widget.items[_selectedIdx];
    final tmdbId = selected.tmdbId ?? selected.id.toString();

    // Fetch rich detail for ratings, runtime, and trailer URL.
    // Conditional watch is safe here — mediaType is constant per WidgetSection instance.
    final movieDetail = (tmdbId.isNotEmpty && widget.mediaType == 'movie')
        ? ref.watch(movieRichDetailProvider(tmdbId)).asData?.value
        : null;
    final showDetail = (tmdbId.isNotEmpty && widget.mediaType == 'show')
        ? ref.watch(showRichDetailProvider(tmdbId)).asData?.value
        : null;

    final imdbId = movieDetail?.imdbId ?? showDetail?.imdbId ?? '';
    final imdbRating = imdbId.isNotEmpty
        ? ref.watch(imdbRatingProvider(imdbId)).asData?.value?.rating
        : null;

    final tmdbRating = movieDetail?.voteAverage ?? showDetail?.voteAverage;
    final runtime = movieDetail?.runtimeMinutes;
    final trailers = movieDetail?.trailers ?? showDetail?.trailers ?? [];
    final firstTrailer = trailers.isNotEmpty ? trailers.first : null;
    _hasTrailer = firstTrailer != null;

    final hasResume = selected.extra['resume_available'] == true;

    // height drives snap-scroll; width is unconstrained so ListView sets it.
    // Backdrop + gradients are rendered by BackdropLayer in AppShell — this
    // widget is transparent so the global backdrop shows through.
    return SizedBox(
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Content (hero + ribbon) — bottom-anchored ─────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: EdgeInsets.only(
                left: (size.width * 0.045).clamp(45.0, 90.0),
                right: (size.width * 0.045).clamp(45.0, 90.0),
                bottom: (size.height * 0.025).clamp(20.0, 36.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hero action group: Play Trailer / More Info / See More all
                  // share one DpadRegion so left/right beam nav flows between
                  // them, and all three share the same _heroDirection
                  // onDirection callback (down -> own ribbon; up -> row 0's
                  // tab pill, or the previous row's 1st card).
                  DpadRegion(
                    memoryKey: '$_regionPrefix-hero',
                    verticalEdge: DpadEdgeBehavior.stop,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Hero info block
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: (size.width * 0.504).clamp(384.0, 816.0),
                          ),
                          child: _HeroInfo(
                            item: selected,
                            t: t,
                            screenSize: size,
                            tmdbRating: tmdbRating,
                            imdbRating: imdbRating,
                            runtime: runtime,
                            hasResume: hasResume,
                            synopsisScroll: _synopsisScroll,
                            playTrailerFocusNode: _playTrailerFocusNode,
                            moreInfoFocusNode: _moreInfoFocusNode,
                            onDirection: _heroDirection,
                            onPlayTrailer: firstTrailer != null
                                ? () => _openTrailer(
                                    firstTrailer.url,
                                    selected.title,
                                  )
                                : null,
                            onMoreInfo: () => context.push(
                              '/detail/${selected.type}/${selected.tmdbId ?? selected.id}',
                              extra: DetailRouteExtra(
                                item: selected,
                                returnFocusNode:
                                    _selectedIdx < _focusNodes.length
                                    ? _focusNodes[_selectedIdx]
                                    : _moreInfoFocusNode,
                              ),
                            ),
                          ),
                        ),

                        // Section header row
                        _SectionHeader(
                          title: widget.title,
                          provider: widget.provider,
                          category: widget.category,
                          mediaType: widget.mediaType,
                          t: t,
                          seeMoreFocusNode: _seeMoreFocusNode,
                          onDirection: _heroDirection,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),

                  // Poster ribbon — own region, stopped horizontal edges (no
                  // wrap/escape at first/last card), shared _ribbonDirection
                  // callback on every card for the up/down row-chain.
                  DpadRegion(
                    memoryKey: '$_regionPrefix-ribbon',
                    horizontalEdge: DpadEdgeBehavior.stop,
                    verticalEdge: DpadEdgeBehavior.stop,
                    child: _PosterRibbon(
                      items: widget.items,
                      selectedIdx: _selectedIdx,
                      focusNodes: _focusNodes,
                      scrollController: _ribbonScroll,
                      tokens: t,
                      onSelect: _selectItem,
                      onDirection: _ribbonDirection,
                      onNavigate: (item, index) => context.push(
                        '/detail/${item.type}/${item.tmdbId ?? item.id}',
                        extra: DetailRouteExtra(
                          item: item,
                          returnFocusNode: index < _focusNodes.length
                              ? _focusNodes[index]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(Size size, WarpTokens t) => SizedBox(
    height: size.height,
    child: const ColoredBox(
      color: Color(0xFF181818),
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0DB2E2),
          strokeWidth: 2,
        ),
      ),
    ),
  );

  Widget _buildEmpty(Size size, WarpTokens t) => SizedBox(
    height: size.height,
    child: ColoredBox(
      color: const Color(0xFF181818),
      child: Center(
        child: Text(
          'No items available',
          style: TextStyle(
            color: const Color(0xFF8A8A8A),
            fontSize: t.fontBody,
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero info: title, synopsis (auto-scroll), ratings, year/runtime, buttons
// Mirrors the hero content block from WidgetSection.tsx exactly.
// ─────────────────────────────────────────────────────────────────────────────

class _HeroInfo extends StatelessWidget {
  final MediaItem item;
  final WarpTokens t;
  final Size screenSize;
  final double? tmdbRating;
  final double? imdbRating;
  final int? runtime;
  final bool hasResume;
  final ScrollController synopsisScroll;
  final VoidCallback? onPlayTrailer;
  final VoidCallback onMoreInfo;
  final FocusNode playTrailerFocusNode;
  final FocusNode moreInfoFocusNode;
  final DpadDirectionCallback onDirection;

  const _HeroInfo({
    required this.item,
    required this.t,
    required this.screenSize,
    required this.synopsisScroll,
    required this.onMoreInfo,
    required this.playTrailerFocusNode,
    required this.moreInfoFocusNode,
    required this.onDirection,
    this.tmdbRating,
    this.imdbRating,
    this.runtime,
    this.hasResume = false,
    this.onPlayTrailer,
  });

  @override
  Widget build(BuildContext context) {
    final w = screenSize.width;
    final h = screenSize.height;

    // CSS: clamp(32px, 3.5vw, 56px)
    final titleSize = (w * 0.035).clamp(32.0, 56.0);
    // CSS: clamp(16px, 1.2vw, 22px)
    final bodySize = (w * 0.012).clamp(16.0, 22.0);
    // CSS: clamp(14px, 0.9vw, 18px)
    final metaSize = (w * 0.009).clamp(14.0, 18.0);
    // CSS: clamp(17px, 1.2vw, 22px)
    final btnSize = (w * 0.012).clamp(17.0, 22.0);
    // CSS: clamp(22px, 2.8vh, 30px) — margin-bottom between sections
    final sectionGap = (h * 0.028).clamp(22.0, 30.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Title ────────────────────────────────────────────────────────────
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -0.5,
            shadows: const [
              Shadow(
                color: Color(0xCC000000),
                blurRadius: 12,
                offset: Offset(2, 4),
              ),
            ],
          ),
        ),
        SizedBox(height: sectionGap),

        // ── Synopsis (3-line cap, auto-scrolls if longer) ────────────────────
        if (item.overview != null && item.overview!.isNotEmpty) ...[
          SizedBox(
            // 3 lines × lineHeight 1.6 × fontSize
            height: bodySize * 1.6 * 3,
            child: SingleChildScrollView(
              controller: synopsisScroll,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                item.overview!,
                style: TextStyle(
                  fontSize: bodySize,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withAlpha(230), // white/90
                  height: 1.6,
                  shadows: const [
                    Shadow(
                      color: Color(0xE6000000),
                      blurRadius: 8,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: sectionGap),
        ],

        // ── Ratings + year + runtime ─────────────────────────────────────────
        Wrap(
          spacing: (w * 0.012).clamp(12.0, 20.0),
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (tmdbRating != null) _TmdbBadge(rating: tmdbRating!),
            if (imdbRating != null) _ImdbBadge(rating: imdbRating!),
            if (item.year != null)
              Text(
                '${item.year}',
                style: TextStyle(
                  fontSize: metaSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(217),
                ),
              ),
            if (runtime != null && runtime! > 0)
              Text(
                '$runtime min',
                style: TextStyle(
                  fontSize: metaSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withAlpha(153),
                ),
              ),
          ],
        ),
        SizedBox(height: sectionGap),

        // ── Action buttons ────────────────────────────────────────────────────
        // Global rule: CTA buttons never show a focus ring — unfocused they
        // all render the same dark-bg/cyan-border look; focused, each
        // reveals its own native accent (Play Trailer -> cyan, Resume -> amber).
        Row(
          children: [
            if (onPlayTrailer != null)
              WarpAccentButton(
                label: 'Play Trailer',
                icon: Icons.play_arrow_rounded,
                accentColor: WarpColors.accent,
                fontSize: btnSize,
                paddingHorizontal: (w * 0.02).clamp(20.0, 42.0),
                paddingVertical: (w * 0.008).clamp(10.0, 18.0),
                focusNode: playTrailerFocusNode,
                onDirection: onDirection,
                onSelect: onPlayTrailer!,
              ),
            if (onPlayTrailer != null)
              SizedBox(width: (w * 0.01).clamp(12.0, 20.0)),

            // More Info / Resume — dark bg, cyan border unfocused; focused
            // reveals amber (Resume) or cyan (More Info).
            WarpAccentButton(
              label: hasResume ? 'Resume' : 'More Info',
              accentColor: hasResume ? WarpColors.warning : WarpColors.accent,
              fontSize: btnSize,
              paddingHorizontal: (w * 0.02).clamp(20.0, 42.0),
              paddingVertical: (w * 0.008).clamp(10.0, 18.0),
              focusNode: moreInfoFocusNode,
              onDirection: onDirection,
              onSelect: onMoreInfo,
            ),
          ],
        ),
        SizedBox(height: 35), // matches Tauri's marginBottom: '35px'
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rating badges — SVG-style logos matching RatingBadges.tsx exactly
// ─────────────────────────────────────────────────────────────────────────────

class _TmdbBadge extends StatelessWidget {
  final double rating;
  const _TmdbBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // TMDb pill: dark blue (#032541) with gradient text — simplified as colored container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF032541),
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Text(
            'TMDb',
            style: TextStyle(
              color: Color(0xFF01B4E4),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ImdbBadge extends StatelessWidget {
  final double rating;
  const _ImdbBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF5C518),
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Text(
            'IMDb',
            style: TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header: label + "See More →"
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? provider;
  final String? category;
  final String mediaType;
  final WarpTokens t;
  final FocusNode seeMoreFocusNode;
  final DpadDirectionCallback onDirection;

  const _SectionHeader({
    required this.title,
    required this.provider,
    required this.category,
    required this.mediaType,
    required this.t,
    required this.seeMoreFocusNode,
    required this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: t.fontSubtitle,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        _SeeMoreBtn(
          t: t,
          focusNode: seeMoreFocusNode,
          onDirection: onDirection,
          onTap: (provider != null && category != null)
              ? () => context.push(
                  '/catalog/$provider/$category?type=$mediaType&title=${Uri.encodeComponent(title)}',
                  extra: CatalogBrowseRouteExtra(
                    returnFocusNode: seeMoreFocusNode,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

// Text-link style — no filled CTA look, so it uses the same "highlight on
// focus" treatment it already used for hover (closest matching visual
// language for a plain text link, per the global rules).
class _SeeMoreBtn extends StatefulWidget {
  final WarpTokens t;
  final VoidCallback? onTap;
  final FocusNode focusNode;
  final DpadDirectionCallback onDirection;
  const _SeeMoreBtn({
    required this.t,
    required this.focusNode,
    required this.onDirection,
    this.onTap,
  });
  @override
  State<_SeeMoreBtn> createState() => _SeeMoreBtnState();
}

class _SeeMoreBtnState extends State<_SeeMoreBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: DpadFocusable(
        focusNode: widget.focusNode,
        enabled: widget.onTap != null,
        onSelect: widget.onTap ?? () {},
        onDirection: widget.onDirection,
        tapToSelect: false,
        builder: (context, state, child) {
          final focused = state.focused;
          final active = _hovered || focused;
          return GestureDetector(
            onTap: widget.onTap == null
                ? null
                : () {
                    widget.focusNode.requestFocus();
                    widget.onTap!();
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
// Poster ribbon: horizontal WidgetRibbonCard row with hover-reveal chevrons
// Matches Tauri's WidgetRibbonItem (poster only, no title/year text below).
// Chevrons scroll 400px, appear on mouse hover (opacity-0 → opacity-100).
// ─────────────────────────────────────────────────────────────────────────────

class _PosterRibbon extends StatefulWidget {
  final List<MediaItem> items;
  final int selectedIdx;
  final List<FocusNode> focusNodes;
  final ScrollController scrollController;
  final WarpTokens tokens;
  final void Function(int idx) onSelect;
  final void Function(MediaItem item, int index) onNavigate;
  final bool Function(int cardIdx, TraversalDirection d) onDirection;

  const _PosterRibbon({
    required this.items,
    required this.selectedIdx,
    required this.focusNodes,
    required this.scrollController,
    required this.tokens,
    required this.onSelect,
    required this.onNavigate,
    required this.onDirection,
  });

  @override
  State<_PosterRibbon> createState() => _PosterRibbonState();
}

class _PosterRibbonState extends State<_PosterRibbon> {
  bool _hovered = false;

  void _scrollLeft() {
    final c = widget.scrollController;
    if (!c.hasClients) return;
    c.animateTo(
      (c.offset - 400).clamp(0.0, c.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollRight() {
    final c = widget.scrollController;
    if (!c.hasClients) return;
    c.animateTo(
      (c.offset + 400).clamp(0.0, c.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    // Ribbon height = image only + 16px vertical padding (8 top + 8 bottom).
    // No text block below — matches Tauri's WidgetRibbonItem.
    final ribbonH = t.ribbonPosterHeight + 16;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        // Extra vertical headroom so hover:scale-105 doesn't clip top/bottom
        height: ribbonH + 16,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: ListView.separated(
                  controller: widget.scrollController,
                  scrollDirection: Axis.horizontal,
                  // Extra vertical padding matches the headroom above
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 4,
                  ),
                  itemCount: widget.items.length,
                  separatorBuilder: (context, i) =>
                      SizedBox(width: widget.tokens.cardGap),
                  itemBuilder: (_, i) => WidgetRibbonCard(
                    item: widget.items[i],
                    isSelected: widget.selectedIdx == i,
                    tokens: widget.tokens,
                    focusNode: i < widget.focusNodes.length
                        ? widget.focusNodes[i]
                        : null,
                    entry: i == 0,
                    onDirection: (d) => widget.onDirection(i, d),
                    onTap: () => widget.onSelect(i),
                    onDoubleTap: () => widget.onNavigate(widget.items[i], i),
                  ),
                ),
              ),
            ),

            // Left chevron — 400px scroll, visible on hover
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
                    child: _ChevronBtn(
                      icon: Icons.chevron_left,
                      onTap: _scrollLeft,
                    ),
                  ),
                ),
              ),
            ),

            // Right chevron — 400px scroll, visible on hover
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
                    child: _ChevronBtn(
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

class _ChevronBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ChevronBtn({required this.icon, required this.onTap});
  @override
  State<_ChevronBtn> createState() => _ChevronBtnState();
}

class _ChevronBtnState extends State<_ChevronBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(_hovered ? 210 : 128),
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
