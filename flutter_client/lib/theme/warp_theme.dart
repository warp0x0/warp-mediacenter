import 'dart:io';
import 'package:flutter/material.dart';
import 'warp_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WarpColors — all colors from index.css :root variables
// ─────────────────────────────────────────────────────────────────────────────

class WarpColors {
  WarpColors._();

  // Backgrounds
  static const bgPrimary = Color(0xFF181818);          // --bg-primary
  static const bgPanel   = Color(0x8C000000);          // rgba(0,0,0,0.55)
  static const bgCard    = Color(0x08FFFFFF);          // rgba(255,255,255,0.03)
  static const bgSidebar = Color(0x99000000);          // rgba(0,0,0,0.60)
  static const bgHover   = Color(0x0FFFFFFF);          // rgba(255,255,255,0.06)

  // Foreground
  static const fgPrimary = Color(0xFFDEDEDE);          // --fg-primary
  static const fgMuted   = Color(0xFF8A8A8A);          // --fg-muted
  static const fgWhite   = Color(0xFFFFFFFF);          // --fg-white

  // Accent
  static const accent      = Color(0xFF0DB2E2);        // --accent
  static const accentHover = Color(0xFF1FC8F0);        // --accent-hover
  static const accentMuted = Color(0x400DB2E2);        // rgba(13,178,226,0.25)

  // Status
  static const success = Color(0xFF00E676);            // --success
  static const danger  = Color(0xFFE94560);            // --danger
  static const warning = Color(0xFFFF9800);            // --warning

  // Focus glow — accent at 28% opacity (TV) / 25% (desktop)
  static const focusGlowTV      = Color(0x470DB2E2);
  static const focusGlowDesktop = Color(0x400DB2E2);
}

// ─────────────────────────────────────────────────────────────────────────────
// WarpTheme — builds ThemeData from WarpTokens
//
// Font strategy:
//   macOS / iOS : '.AppleSystemUIFont'  → SF Pro Text (system native)
//   Android / Linux / Windows : 'WarpUI'  → bundled Inter (5 weights)
// ─────────────────────────────────────────────────────────────────────────────

class WarpTheme {
  WarpTheme._();

  static String get _fontFamily {
    if (Platform.isMacOS || Platform.isIOS) return '.AppleSystemUIFont';
    return 'WarpUI'; // Inter bundled in assets/fonts/
  }

  static ThemeData build(WarpTokens t) {
    final colorScheme = ColorScheme.dark(
      surface:          WarpColors.bgPrimary,
      surfaceContainer: WarpColors.bgPanel,
      primary:          WarpColors.accent,
      onPrimary:        WarpColors.fgWhite,
      secondary:        WarpColors.accentMuted,
      onSecondary:      WarpColors.accent,
      error:            WarpColors.danger,
      onSurface:        WarpColors.fgPrimary,
      outline:          const Color(0x1AFFFFFF),  // white/10
    );

    final textTheme = TextTheme(
      // page title: --text-page (26px desktop / clamp TV), weight 800, -0.5 tracking
      displayLarge: TextStyle(
        fontSize: t.fontPage,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: WarpColors.fgWhite,
      ),
      // section title: --text-section
      titleLarge: TextStyle(
        fontSize: t.fontSection,
        fontWeight: FontWeight.w700,
        color: WarpColors.fgWhite,
      ),
      // heading: --text-heading
      titleMedium: TextStyle(
        fontSize: t.fontHeading,
        fontWeight: FontWeight.w700,
        color: WarpColors.fgPrimary,
      ),
      // body: --text-body
      bodyLarge: TextStyle(
        fontSize: t.fontBody,
        fontWeight: FontWeight.w400,
        color: WarpColors.fgPrimary,
      ),
      // subtitle: --text-subtitle
      bodySmall: TextStyle(
        fontSize: t.fontSubtitle,
        fontWeight: FontWeight.w400,
        color: WarpColors.fgMuted,
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: WarpColors.bgPrimary,
      fontFamily: _fontFamily,
      textTheme: textTheme,
      useMaterial3: true,

      // Focus indicator — accent ring matching :focus-visible CSS rule
      focusColor: WarpColors.accentMuted,

      // Slider (seek bar, volume)
      sliderTheme: SliderThemeData(
        activeTrackColor: WarpColors.accent,
        thumbColor: WarpColors.accent,
        inactiveTrackColor: const Color(0x33FFFFFF),  // white/20
        overlayColor: WarpColors.accentMuted,
        trackHeight: 3,
      ),

      // Icon
      iconTheme: const IconThemeData(color: WarpColors.fgPrimary),

      // Divider
      dividerColor: const Color(0x1AFFFFFF),  // white/10

      // Input decoration (for search, settings forms)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x0DFFFFFF),  // rgba(255,255,255,0.05)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusInput),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusInput),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusInput),
          borderSide: const BorderSide(color: WarpColors.accent, width: 2),
        ),
        hintStyle: TextStyle(color: WarpColors.fgMuted, fontSize: t.fontBody),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),

      // Page transitions — fade (TV) or slide (desktop)
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS:   const ZoomPageTransitionsBuilder(),
          TargetPlatform.linux:   const FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: const FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WarpFocusDecoration — consistent focus ring for all focusable widgets
//
// Use this as the `decoration` inside FocusableActionDetector or wrap a
// widget with WarpFocusRing to get the TV-appropriate accent ring.
// ─────────────────────────────────────────────────────────────────────────────

class WarpFocusRing extends StatelessWidget {
  final bool hasFocus;
  final WarpTokens tokens;
  final Widget child;
  final double? borderRadius;

  const WarpFocusRing({
    super.key,
    required this.hasFocus,
    required this.tokens,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? tokens.cardRadius;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: hasFocus
            ? Border.all(
                color: WarpColors.accent,
                width: tokens.focusRingWidth,
              )
            : null,
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: tokens.isTV
                      ? WarpColors.focusGlowTV
                      : WarpColors.focusGlowDesktop,
                  blurRadius: tokens.isTV ? 28 : 16,
                  spreadRadius: tokens.isTV ? 4 : 2,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
