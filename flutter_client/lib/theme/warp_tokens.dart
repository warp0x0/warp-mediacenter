import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UiDensity — desktop vs TV scaling mode
// ─────────────────────────────────────────────────────────────────────────────

enum UiDensity { desktop, tv }

// Riverpod 3: NotifierProvider replaces StateProvider
// Auto-detected on Android TV; overridable via Settings
final uiDensityProvider = NotifierProvider<UiDensityNotifier, UiDensity>(
  UiDensityNotifier.new,
);

class UiDensityNotifier extends Notifier<UiDensity> {
  final UiDensity _initial;
  UiDensityNotifier([this._initial = UiDensity.desktop]);

  @override
  UiDensity build() => _initial;

  void update(UiDensity density) => state = density;
}

// ─────────────────────────────────────────────────────────────────────────────
// WarpTokens — THE SINGLE SOURCE OF TRUTH for all visual dimensions
//
// Mirrors the CSS variable system in index.css exactly, including the
// html[data-ui-density="tv"] override layer.
//
// Usage in ConsumerWidget / ConsumerStatefulWidget:
//   final t = WarpTokens.watch(context, ref);
//   SizedBox(width: t.posterWidth, height: t.posterHeight)
//
// Usage in non-Consumer widgets (pass density from parent):
//   WarpTokens(density, MediaQuery.sizeOf(context))
//
// NEVER hardcode sizes in individual widgets.
// ─────────────────────────────────────────────────────────────────────────────

class WarpTokens {
  final UiDensity density;
  final Size _screen;

  // Primary constructor — used in main.dart for initial theme build
  const WarpTokens(this.density, this._screen);

  // Convenience factory for ConsumerWidgets — reads density from Riverpod
  // and screen size from MediaQuery in one call.
  factory WarpTokens.watch(BuildContext context, WidgetRef ref) {
    final density = ref.watch(uiDensityProvider);
    final screen = MediaQuery.sizeOf(context);
    return WarpTokens(density, screen);
  }

  bool get isTV => density == UiDensity.tv;

  // ── Tab bar / layout ────────────────────────────────────────────────────────
  // CSS: --tabbar-height: clamp(72px, 12vh, 100px)
  //  TV: clamp(96px, 13vh, 132px)
  double get tabBarHeight =>
      isTV ? _clampH(96, 0.13, 132) : _clampH(72, 0.12, 100);

  // CSS: --sidebar-width: clamp(200px, 12.5vw, 280px)
  //  TV: clamp(260px, 18vw, 360px)
  double get sidebarWidth =>
      isTV ? _clampW(260, 0.18, 360) : _clampW(200, 0.125, 280);

  // CSS: --title-bar-height: clamp(32px, 3.7vh, 44px)
  //  TV: clamp(40px, 4.6vh, 56px)
  double get titleBarHeight =>
      isTV ? _clampH(40, 0.046, 56) : _clampH(32, 0.037, 44);

  // ── Poster cards ────────────────────────────────────────────────────────────
  // CSS var --poster-width: clamp(160px, 10.4vw, 220px) — used by PosterCard
  // in the library grid and anywhere PosterCard is shown at its default size.
  // TV: clamp(220px, 14vw, 300px)
  double get posterWidth =>
      isTV ? _clampW(220, 0.14, 300) : _clampW(160, 0.104, 220);

  // Ribbon override (WidgetSection/WidgetRibbonItem inline style):
  // clamp(110px, 9vw, 170px) — smaller cards in the horizontal scroll ribbons.
  // TV: clamp(190px, 12vw, 260px)
  double get ribbonPosterWidth =>
      isTV ? _clampW(190, 0.12, 260) : _clampW(110, 0.09, 170);

  // Height = width × 1.5, matching Tauri's aspectRatio:'2/3' on the img tag.
  double get posterHeight => posterWidth * 1.5;
  double get ribbonPosterHeight => ribbonPosterWidth * 1.5;

  // Extra vertical space below the poster image for title + year text.
  // gap(5) + title(≤18) + year(≤17) + small margin(4) = 44
  double get posterCardTextHeight => 44.0;

  // Full card height including the text block below the image.
  double get posterCardTotalHeight => posterHeight + posterCardTextHeight;
  double get ribbonPosterCardTotalHeight => ribbonPosterHeight + posterCardTextHeight;

  // ── Grid / spacing ──────────────────────────────────────────────────────────
  // CSS: --card-gap: clamp(8px, 0.625vw, 16px)
  //  TV: clamp(14px, 1vw, 24px)
  double get cardGap =>
      isTV ? _clampW(14, 0.01, 24) : _clampW(8, 0.00625, 16);

  // CSS: --card-radius: clamp(10px, 0.73vw, 16px)
  //  TV: clamp(14px, 0.9vw, 22px)
  double get cardRadius =>
      isTV ? _clampW(14, 0.009, 22) : _clampW(10, 0.0073, 16);

  // Fixed radii (from --radius-* in @theme)
  double get radiusBtn   => 10;
  double get radiusInput => 10;
  double get radiusPill  => 8;

  // ── Detail view ─────────────────────────────────────────────────────────────
  // CSS: --detail-hero-height: 70vh
  double get detailHeroHeight => _screen.height * 0.70;

  // ── Backdrop blur ───────────────────────────────────────────────────────────
  double get backdropBlurSigma => isTV ? 18.0 : 12.0;

  // ── Font sizes ──────────────────────────────────────────────────────────────
  // CSS: --text-page: 26px  /  TV: clamp(34px, 2.8vw, 52px)
  double get fontPage =>
      isTV ? _clampW(34, 0.028, 52) : 26;

  // CSS: --text-section: 22px  /  TV: clamp(24px, 1.8vw, 34px)
  double get fontSection =>
      isTV ? _clampW(24, 0.018, 34) : 22;

  // CSS: --text-heading: 18px (same both modes)
  double get fontHeading => 18;

  // CSS: --text-body: 16px  /  TV: clamp(18px, 1.25vw, 24px)
  double get fontBody =>
      isTV ? _clampW(18, 0.0125, 24) : 16;

  // CSS: --text-subtitle: 14px  /  TV: clamp(15px, 1vw, 19px)
  double get fontSubtitle =>
      isTV ? _clampW(15, 0.010, 19) : 14;

  // ── Page/section title sizes (clamp variants) ────────────────────────────────
  // CSS: --page-title-size: clamp(24px, 2vw, 36px)  /  TV: clamp(34px, 2.8vw, 52px)
  double get pageTitleSize =>
      isTV ? _clampW(34, 0.028, 52) : _clampW(24, 0.02, 36);

  // CSS: --section-title-size: clamp(18px, 1.5vw, 24px)  /  TV: clamp(24px, 1.8vw, 34px)
  double get sectionTitleSize =>
      isTV ? _clampW(24, 0.018, 34) : _clampW(18, 0.015, 24);

  // CSS: --body-size: clamp(14px, 1vw, 17px)  /  TV: clamp(18px, 1.25vw, 24px)
  double get bodySize =>
      isTV ? _clampW(18, 0.0125, 24) : _clampW(14, 0.01, 17);

  // CSS: --subtitle-size: clamp(12px, 0.83vw, 15px)  /  TV: clamp(15px, 1vw, 19px)
  double get subtitleSize =>
      isTV ? _clampW(15, 0.010, 19) : _clampW(12, 0.0083, 15);

  // ── Focus ring ──────────────────────────────────────────────────────────────
  // CSS: outline: 2px solid var(--accent)  /  TV: 4px
  double get focusRingWidth  => isTV ? 4.0 : 2.0;
  double get focusRingOffset => isTV ? 4.0 : 2.0;

  // Wider ring specifically for poster/ribbon cards — poster art can be any
  // color, including near-identical to the accent ring, so cards need extra
  // width to stay visible where buttons/text fields (flat, known colors)
  // don't.
  double get cardFocusRingWidth => isTV ? 6.0 : 3.5;

  // ── Touch target minimum (Android TV guideline: 60dp) ────────────────────────
  double get minTouchTarget => isTV ? 60.0 : 44.0;

  // ── Overscan / edge safety padding (Android TV recommendation: 48dp) ─────────
  double get tvEdgePadding => isTV ? 48.0 : 0.0;

  // ── Helpers (private) ────────────────────────────────────────────────────────
  double _clampW(double min, double frac, double max) =>
      (_screen.width * frac).clamp(min, max);

  double _clampH(double min, double frac, double max) =>
      (_screen.height * frac).clamp(min, max);
}
