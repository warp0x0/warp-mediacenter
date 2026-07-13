import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/warp_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// backdropProvider — global state for the full-screen backdrop image URL
// Mirrors src/contexts/BackdropContext.tsx
// ─────────────────────────────────────────────────────────────────────────────

final backdropProvider = NotifierProvider<BackdropNotifier, String?>(
  BackdropNotifier.new,
);

class BackdropNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? url) {
    if (state != url) state = url;
  }

  void clear() => state = null;
}

// ─────────────────────────────────────────────────────────────────────────────
// BackdropLayer
//
// Renders the full-screen backdrop image behind all content.
// Mounted inside AppShell as the bottom layer of a Stack.
//
// Fix for the "blur cuts off midway" bug:
//   A ShaderMask makes the blur itself fade from opaque (top) to transparent
//   (bottom) using a LinearGradient mask. This eliminates the hard edge.
//   Gradient overlays sit on top as pure color layers (no blur).
// ─────────────────────────────────────────────────────────────────────────────

class BackdropLayer extends ConsumerWidget {
  const BackdropLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = ref.watch(backdropProvider);
    final t = WarpTokens.watch(context, ref);

    final child = imageUrl == null
        ? const SizedBox.expand(key: ValueKey('__empty__'))
        : _BackdropImage(key: ValueKey(imageUrl), url: imageUrl, tokens: t);

    if (t.isTV) return child;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: child,
    );
  }
}

class _BackdropImage extends StatelessWidget {
  final String url;
  final WarpTokens tokens;

  const _BackdropImage({super.key, required this.url, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final cacheWidth = _targetCacheWidth(
      context,
      MediaQuery.sizeOf(context).width,
    );
    final cacheHeight = (cacheWidth * 9 / 16).round();

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Raw backdrop image ───────────────────────────────────
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            memCacheWidth: cacheWidth,
            memCacheHeight: cacheHeight,
            fadeInDuration: tokens.isTV
                ? Duration.zero
                : const Duration(milliseconds: 500),
            fadeOutDuration: tokens.isTV
                ? Duration.zero
                : const Duration(milliseconds: 1000),
            placeholder: (_, _) => const SizedBox.shrink(),
            errorWidget: (_, _, _) => const SizedBox.shrink(),
          ),

          if (tokens.isTV) ...[
            // TV: avoid full-screen blur/compositing. Keep text readable on
            // the left while leaving the artwork bright on the right.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF2181818),
                    Color(0xCC181818),
                    Color(0x00181818),
                  ],
                  stops: [0.0, 0.50, 0.78],
                ),
              ),
            ),
          ] else ...[
            // ── Layer 2: Blur with smooth fade-out via ShaderMask ────────────
            //
            // The ShaderMask applies a vertical gradient as an alpha mask to the
            // blur output. The blur is fully opaque at the top (0–45%) and fades
            // to transparent by the bottom. This removes the hard cutoff edge.
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white, // fully opaque (blur shows)
                  Colors.white, // hold opacity through mid-section
                  Colors.transparent, // fade out completely
                ],
                stops: [0.0, 0.42, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: tokens.backdropBlurSigma,
                  sigmaY: tokens.backdropBlurSigma,
                ),
                child: Container(color: Colors.transparent),
              ),
            ),

            // ── Layer 3: Dark gradient — top transparent → bottom opaque ────
            // Mirrors CSS: linear-gradient(transparent → rgba(24,24,24,0.8) → #181818)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00181818), // transparent
                    Color(0xCC181818), // ~80% at 55%
                    Color(0xFF181818), // fully opaque at bottom
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // ── Layer 4: Left-to-right vignette ──────────────────────────────
            // Mirrors CSS: linear-gradient(to right, rgba(24,24,24,0.7) → transparent)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xB3181818), // ~70% opaque on left
                    Color(0x00181818), // transparent at 50%
                  ],
                  stops: [0.0, 0.5],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

int _targetCacheWidth(
  BuildContext context,
  double displayWidth, {
  int max = 1280,
}) {
  final media = MediaQuery.of(context);
  final view = View.maybeOf(context);
  final logicalViewportWidth = view == null
      ? media.size.width
      : view.physicalSize.width / view.devicePixelRatio;
  final paintScale = media.size.width <= 0
      ? 1.0
      : (logicalViewportWidth / media.size.width).clamp(0.1, 1.0);
  final pixels = (displayWidth * media.devicePixelRatio * paintScale).ceil();
  return pixels.clamp(1, max).toInt();
}
