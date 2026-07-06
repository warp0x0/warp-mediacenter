import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/catalog_constants.dart';
import '../../models/media.dart';
import '../../providers/library_provider.dart';
import '../../theme/warp_tokens.dart';

/// Ribbon card matching Tauri's WidgetRibbonItem — poster image only, no title/year text.
/// Used in horizontal ribbon rows within WidgetSection.
/// For library grids and other contexts with title text, use PosterCard instead.
class WidgetRibbonCard extends ConsumerStatefulWidget {
  final MediaItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final FocusNode? focusNode;
  final WarpTokens tokens;
  final DpadDirectionCallback? onDirection;
  final bool entry;

  const WidgetRibbonCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    required this.tokens,
    this.focusNode,
    this.onDirection,
    this.entry = false,
  });

  @override
  ConsumerState<WidgetRibbonCard> createState() => _WidgetRibbonCardState();
}

class _WidgetRibbonCardState extends ConsumerState<WidgetRibbonCard> {
  bool _focused = false;
  bool _hovered = false;

  String _resolveUrl() {
    final direct = posterUrl(widget.item.posterPath);
    if (direct.isNotEmpty) return direct;
    final asset = widget.item.poster?.url;
    if (asset != null && asset.isNotEmpty) {
      return asset.startsWith('/') ? posterUrl(asset) : asset;
    }
    return posterUrl(widget.item.media.posterPath);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final imgW = t.ribbonPosterWidth;
    final imgH = t.ribbonPosterHeight;
    final showRing = _focused;

    final tmdbId = widget.item.tmdbId;
    final liked = tmdbId != null && tmdbId.isNotEmpty
        ? ref.watch(isLikedProvider(tmdbId)).asData?.value ?? false
        : false;
    final wishlisted = tmdbId != null && tmdbId.isNotEmpty
        ? ref.watch(isWishlistedProvider(tmdbId)).asData?.value ?? false
        : false;

    final w = MediaQuery.sizeOf(context).width;
    final btnSize = (w * 0.012).clamp(14.0, 20.0);
    final url = _resolveUrl();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DpadFocusable(
        effects: const [],
        focusNode: widget.focusNode,
        entry: widget.entry,
        // The ribbon's own horizontal position is already managed manually
        // (WidgetSection._centerCard), and the vertical row-to-row position
        // is fully owned by _focusRowByDpad's explicit PageView.animateToPage
        // — dpad's built-in ensureVisible walks *every* scrollable ancestor
        // (including that vertical PageView) and was fighting both of them:
        // the ribbon sits closer than dpad's default 48px scrollPadding to
        // the bottom of the page, so it nudged the PageView on every card
        // focus (visible as the whole hero+ribbon jumping), and it could
        // also overshoot back toward the previous row right after a
        // deliberate row jump landed.
        autoScroll: false,
        onFocusChange: (v) => setState(() => _focused = v),
        onDirection: widget.onDirection,
        // D-pad Select navigates to the detail page — arrow-key focus
        // already drives the hero preview (WidgetSection's focus listener
        // calls onTap/_selectItem on every focus change), so Select's own
        // job is to commit, matching mouse's double-tap-to-navigate.
        onSelect: widget.onDoubleTap,
        tapToSelect: false,
        child: GestureDetector(
          onTap: () {
            widget.focusNode?.requestFocus();
            widget.onTap();
          },
          onDoubleTap: widget.onDoubleTap,
          child: AnimatedScale(
            scale: showRing || _hovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: imgW,
            height: imgH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(t.cardRadius),
              border: showRing
                  ? Border.all(color: const Color(0xFF0DB2E2), width: t.cardFocusRingWidth)
                  : null,
              boxShadow: showRing
                  ? [const BoxShadow(color: Color(0x470DB2E2), blurRadius: 20, spreadRadius: 1)]
                  : (_hovered
                      ? [const BoxShadow(color: Colors.black54, blurRadius: 16)]
                      : [const BoxShadow(color: Colors.black38, blurRadius: 8)]),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                (t.cardRadius - (showRing ? t.cardFocusRingWidth : 0)).clamp(0.0, t.cardRadius),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _RibbonSkeleton(radius: t.cardRadius),
                      errorWidget: (_, _, _) => const _RibbonNoPoster(),
                    )
                  else
                    const _RibbonNoPoster(),

                  // Subtle inner vignette — a dark rim between the poster
                  // art and the outer cyan focus ring, so the ring stays
                  // legible even against near-white/near-cyan poster edges.
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.fromBorderSide(
                            BorderSide(color: Color(0x59000000), width: 3.5),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (tmdbId != null && tmdbId.isNotEmpty)
                    Positioned(
                      top: 4, left: 4,
                      child: Column(
                        children: [
                          _RibbonCollectionBtn(
                            size: btnSize,
                            active: liked,
                            icon: Icons.favorite,
                            activeColor: const Color(0xFFF87171),
                            activeBg: const Color(0x40EF4444),
                            activeBorder: const Color(0x99EF4444),
                            onTap: () => toggleLiked(ref, widget.item),
                          ),
                          const SizedBox(height: 3),
                          _RibbonCollectionBtn(
                            size: btnSize,
                            active: wishlisted,
                            icon: wishlisted ? Icons.check_circle : Icons.add,
                            activeColor: const Color(0xFF34D399),
                            activeBg: const Color(0x4010B981),
                            activeBorder: const Color(0x9910B981),
                            onTap: () => toggleWishlisted(ref, widget.item),
                          ),
                        ],
                      ),
                    ),

                  if (widget.item.extra['progress'] is num &&
                      (widget.item.extra['progress'] as num) > 0)
                    Positioned(
                      left: 0, right: 0, bottom: 2,
                      child: _RibbonProgressBar(
                        percent: (widget.item.extra['progress'] as num).toDouble(),
                      ),
                    ),
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

class _RibbonCollectionBtn extends StatelessWidget {
  final double size;
  final bool active;
  final IconData icon;
  final Color activeColor;
  final Color activeBg;
  final Color activeBorder;
  final VoidCallback onTap;

  const _RibbonCollectionBtn({
    required this.size,
    required this.active,
    required this.icon,
    required this.activeColor,
    required this.activeBg,
    required this.activeBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? activeBg : Colors.black.withAlpha(153),
          border: Border.all(
            color: active ? activeBorder : Colors.white.withAlpha(51),
            width: 1,
          ),
        ),
        child: Icon(icon, size: size * 0.55, color: active ? activeColor : Colors.white),
      ),
    );
  }
}

class _RibbonSkeleton extends StatelessWidget {
  final double radius;
  const _RibbonSkeleton({required this.radius});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: Colors.white.withAlpha(13),
    ),
  );
}

class _RibbonNoPoster extends StatelessWidget {
  const _RibbonNoPoster();

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white.withAlpha(13),
    child: const Center(
      child: Text(
        'No Poster',
        style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 10),
      ),
    ),
  );
}

class _RibbonProgressBar extends StatelessWidget {
  final double percent;
  const _RibbonProgressBar({required this.percent});

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
