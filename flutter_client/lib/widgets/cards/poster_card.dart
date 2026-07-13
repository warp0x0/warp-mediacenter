import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/catalog_constants.dart';
import '../../models/media.dart';
import '../../providers/detail_provider.dart';
import '../../providers/library_provider.dart';
import '../../theme/warp_tokens.dart';
import '../shared/media_context_menu.dart';
import '../shared/warp_context_menu.dart';

class PosterCard extends ConsumerStatefulWidget {
  final MediaItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final FocusNode? focusNode;
  final WarpTokens tokens;
  // Optional size overrides — used by ribbons that display smaller cards.
  // When null, falls back to tokens.posterWidth / tokens.posterHeight.
  final double? cardWidth;
  final double? cardHeight;
  final DpadDirectionCallback? onDirection;
  final bool entry;
  // dpad's own focus-gain auto-scroll only nudges enough to satisfy a
  // fixed padding — callers that need deterministic centering (e.g.
  // scrolling the whole row to the middle of the viewport) should disable
  // this and do their own scrolling instead.
  final bool autoScroll;
  final bool enableDefaultContextMenu;
  final List<WarpContextMenuItem> Function()? contextMenuBuilder;

  const PosterCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    required this.tokens,
    this.focusNode,
    this.cardWidth,
    this.cardHeight,
    this.onDirection,
    this.entry = false,
    this.autoScroll = true,
    this.enableDefaultContextMenu = true,
    this.contextMenuBuilder,
  });

  @override
  ConsumerState<PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends ConsumerState<PosterCard> {
  bool _focused = false;
  bool _hovered = false;
  bool _contextMenuOpen = false;

  List<WarpContextMenuItem> _contextMenuItems() {
    final builder = widget.contextMenuBuilder;
    if (builder != null) return builder();
    if (!widget.enableDefaultContextMenu) return const [];
    final tmdbId = widget.item.tmdbId;
    final liked = tmdbId != null && tmdbId.isNotEmpty
        ? ref.read(isLikedProvider(tmdbId)).asData?.value ?? false
        : false;
    final wishlisted = tmdbId != null && tmdbId.isNotEmpty
        ? ref.read(isWishlistedProvider(tmdbId)).asData?.value ?? false
        : false;
    return buildMediaContextMenuItems(
      ref,
      widget.item,
      liked: liked,
      wishlisted: wishlisted,
    );
  }

  Future<void> _openContextMenu() async {
    final items = _contextMenuItems();
    if (items.isEmpty) return;
    setState(() => _contextMenuOpen = true);
    try {
      await showWarpContextMenu(
        context,
        items: items,
        restoreFocusNode: widget.focusNode,
        centerInViewport: true,
      );
    } finally {
      if (mounted) setState(() => _contextMenuOpen = false);
    }
  }

  // Mirrors useTmdbEnrichment.ts fallback order:
  //   1. item.poster_path / item.media.poster_path → direct TMDb URL
  //   2. item.poster.url                            → asset already resolved
  //   3. fetch full TMDb detail by tmdb_id and use detail.poster.url
  //      (collection items are sometimes stored without a poster_path)
  String _resolveDirectUrl() {
    final direct = posterUrl(widget.item.posterPath);
    if (direct.isNotEmpty) return direct;

    final asset = widget.item.poster?.url;
    if (asset != null && asset.isNotEmpty) {
      return asset.startsWith('/') ? posterUrl(asset) : asset;
    }

    final nested = posterUrl(widget.item.media.posterPath);
    if (nested.isNotEmpty) return nested;

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final imgW = widget.cardWidth ?? t.posterWidth;
    final imgH = widget.cardHeight ?? t.posterHeight;
    final showRing = _focused || _contextMenuOpen;
    final title = widget.item.title.isNotEmpty
        ? widget.item.title
        : (widget.item.media.title.isNotEmpty
              ? widget.item.media.title
              : widget.item.media.name);
    final year = widget.item.year ?? widget.item.media.year;

    String url = _resolveDirectUrl();
    double? enrichedRating;

    final tmdbId = widget.item.tmdbId;
    if (url.isEmpty && tmdbId != null && tmdbId.isNotEmpty) {
      if (widget.item.type == 'show') {
        final detail = ref.watch(showRichDetailProvider(tmdbId)).asData?.value;
        if (detail?.poster?.url.isNotEmpty ?? false) url = detail!.poster!.url;
        enrichedRating = detail?.voteAverage;
      } else {
        final detail = ref.watch(movieRichDetailProvider(tmdbId)).asData?.value;
        if (detail?.poster?.url.isNotEmpty ?? false) url = detail!.poster!.url;
        enrichedRating = detail?.voteAverage;
      }
    }

    final rating =
        widget.item.rating ?? widget.item.media.rating ?? enrichedRating;

    // Self-managed collection status — mirrors useIsLiked/useIsWishlisted.ts,
    // shown on every card that has a tmdbId, just like Tauri's CollectionButtons.
    final liked = tmdbId != null && tmdbId.isNotEmpty
        ? ref.watch(isLikedProvider(tmdbId)).asData?.value ?? false
        : false;
    final wishlisted = tmdbId != null && tmdbId.isNotEmpty
        ? ref.watch(isWishlistedProvider(tmdbId)).asData?.value ?? false
        : false;

    // Clamp font sizes to match Tauri PosterCard
    final media = MediaQuery.of(context);
    final w = media.size.width;
    double scaled(num value) => media.textScaler.scale(value.toDouble());
    final titleFs = (w * 0.0073).clamp(12.0, 15.0);
    final yearFs = (w * 0.0063).clamp(10.0, 13.0);
    final ratingFs = (w * 0.0068).clamp(11.0, 14.0);
    final btnSize = scaled((w * 0.015).clamp(20.0, 26.0));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DpadFocusable(
        effects: const [],
        focusNode: widget.focusNode,
        entry: widget.entry,
        autoScroll: widget.autoScroll,
        onFocusChange: (v) => setState(() => _focused = v),
        onDirection: widget.onDirection,
        onSelect: widget.onTap,
        onLongSelect: _openContextMenu,
        tapToSelect: false,
        child: GestureDetector(
          onTap: () {
            widget.focusNode?.requestFocus();
            widget.onTap();
          },
          onDoubleTap: widget.onDoubleTap,
          onLongPress: _openContextMenu,
          onSecondaryTap: _openContextMenu,
          child: AnimatedScale(
            scale: _hovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 150),
            alignment:
                Alignment.center, // CSS default: transform-origin center center
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Poster image ───────────────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: imgW,
                  height: imgH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(t.cardRadius),
                    border: showRing
                        ? Border.all(
                            color: const Color(0xFF0DB2E2),
                            width: t.cardFocusRingWidth,
                          )
                        : null,
                    boxShadow: showRing
                        ? [
                            const BoxShadow(
                              color: Color(0x470DB2E2),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : [
                            const BoxShadow(
                              color: Colors.black38,
                              blurRadius: 8,
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      (t.cardRadius - (showRing ? t.cardFocusRingWidth : 0))
                          .clamp(0, t.cardRadius),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Poster
                        if (url.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                _Skeleton(radius: t.cardRadius),
                            errorWidget: (_, _, _) => _NoPoster(t: t),
                          )
                        else
                          _NoPoster(t: t),

                        // Subtle inner vignette — a dark rim between the poster
                        // art and the outer cyan focus ring, so the ring stays
                        // legible even against near-white/near-cyan poster edges.
                        const Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.fromBorderSide(
                                  BorderSide(
                                    color: Color(0x59000000),
                                    width: 3.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Rating badge — top right (mirrors Tauri: width:50px, height:25px)
                        if (rating != null && rating > 0)
                          Positioned(
                            top: scaled((w * 0.0031).clamp(4.0, 8.0)),
                            right: scaled((w * 0.0031).clamp(4.0, 8.0)),
                            child: Container(
                              width: scaled(50),
                              height: scaled(25),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(179),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: scaled(ratingFs + 1),
                                    color: const Color(0xFFFBBF24),
                                  ),
                                  SizedBox(width: scaled(2)),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: ratingFs,
                                      fontWeight: FontWeight.w600,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Collection buttons — top left (mirrors CollectionButtons.tsx)
                        // Inactive buttons hidden until card is hovered (opacity-0 → opacity-100).
                        // Active (liked/wishlisted) buttons always visible.
                        if (tmdbId != null && tmdbId.isNotEmpty)
                          Positioned(
                            top: scaled((w * 0.0031).clamp(4.0, 8.0)),
                            left: scaled((w * 0.0031).clamp(4.0, 8.0)),
                            child: Column(
                              children: [
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 150),
                                  opacity: liked || _hovered ? 1.0 : 0.0,
                                  child: _CollectionBtn(
                                    size: btnSize,
                                    active: liked,
                                    hovered: false,
                                    icon: Icons.favorite,
                                    activeColor: const Color(0xFFF87171),
                                    activeBg: const Color(0x40EF4444),
                                    activeBorder: const Color(0x99EF4444),
                                    onTap: () => toggleLiked(ref, widget.item),
                                  ),
                                ),
                                SizedBox(
                                  height: scaled((w * 0.0026).clamp(3.0, 5.0)),
                                ),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 150),
                                  opacity: wishlisted || _hovered ? 1.0 : 0.0,
                                  child: _CollectionBtn(
                                    size: btnSize,
                                    active: wishlisted,
                                    hovered: false,
                                    icon: wishlisted
                                        ? Icons.check_circle
                                        : Icons.add,
                                    activeColor: const Color(0xFF34D399),
                                    activeBg: const Color(0x4010B981),
                                    activeBorder: const Color(0x9910B981),
                                    onTap: () =>
                                        toggleWishlisted(ref, widget.item),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Progress bar
                        if (widget.item.extra['progress'] is num &&
                            (widget.item.extra['progress'] as num) > 0)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 2,
                            child: _ProgressBar(
                              percent: (widget.item.extra['progress'] as num)
                                  .toDouble(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Title + year (below card, matches Tauri PosterCard) ────────
                const SizedBox(height: 5),
                SizedBox(
                  width: imgW,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: (w * 0.0016).clamp(2.0, 4.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titleFs,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        if (year != null)
                          Text(
                            '$year',
                            style: TextStyle(
                              fontSize: yearFs,
                              color: const Color(0xFF8A8A8A),
                              height: 1.3,
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

// Mirrors CollectionButtons.tsx: bg-black/60 → hover:bg-black/80 when inactive
class _CollectionBtn extends StatefulWidget {
  final double size;
  final bool active;
  final bool hovered; // unused externally — internal state manages it
  final IconData icon;
  final Color activeColor;
  final Color activeBg;
  final Color activeBorder;
  final VoidCallback onTap;

  const _CollectionBtn({
    required this.size,
    required this.active,
    required this.hovered,
    required this.icon,
    required this.activeColor,
    required this.activeBg,
    required this.activeBorder,
    required this.onTap,
  });

  @override
  State<_CollectionBtn> createState() => _CollectionBtnState();
}

class _CollectionBtnState extends State<_CollectionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bgAlpha = widget.active
        ? null
        : (_hovered ? 204 : 153); // black/80 vs black/60
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.active
                ? widget.activeBg
                : Colors.black.withAlpha(bgAlpha!),
            border: Border.all(
              color: widget.active
                  ? widget.activeBorder
                  : Colors.white.withAlpha(51),
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            size: widget.size * 0.55,
            color: widget.active ? widget.activeColor : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double radius;
  const _Skeleton({required this.radius});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: Colors.white.withAlpha(13),
    ),
  );
}

class _NoPoster extends StatelessWidget {
  final WarpTokens t;
  const _NoPoster({required this.t});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white.withAlpha(13),
    child: Center(
      child: Text(
        'No Poster',
        style: TextStyle(
          color: const Color(0xFF8A8A8A),
          fontSize: t.fontSubtitle,
        ),
      ),
    ),
  );
}

class _ProgressBar extends StatelessWidget {
  final double percent;
  const _ProgressBar({required this.percent});
  @override
  Widget build(BuildContext context) => Container(
    height: 5,
    color: Colors.white.withAlpha(38),
    child: Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: (percent / 100).clamp(0.0, 1.0),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFBBF24),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(3),
              bottomRight: Radius.circular(3),
            ),
          ),
        ),
      ),
    ),
  );
}
