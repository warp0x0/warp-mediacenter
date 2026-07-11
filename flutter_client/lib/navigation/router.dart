import 'dart:ui';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/media.dart';
import 'catalog_browse_route_extra.dart';
import 'detail_route_extra.dart';
import '../pages/detail_view_page.dart';
import '../providers/detail_provider.dart';
import '../pages/library_page.dart';
import '../pages/movies_page.dart';
import '../pages/playback_page.dart';
import '../pages/search_page.dart';
import '../pages/catalog_browse_page.dart';
import '../pages/power_page.dart';
import '../pages/settings_page.dart';
import '../pages/shows_page.dart';
import '../theme/warp_theme.dart';
import '../widgets/layout/backdrop_layer.dart';
import 'last_tab_route.dart';
import 'tab_bar_focus_registry.dart';

part 'router.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WarpRouter — go_router configuration
//
// Mirrors src/App.tsx route structure:
//   /           → MoviesPage
//   /shows      → ShowsPage
//   /search     → SearchPage
//   /library    → LibraryPage
//   /settings   → SettingsPage
//   /power      → PowerPage
//   /detail/:id → DetailViewPage
//   /playback   → PlaybackPage
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
GoRouter warpRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    observers: [routeObserver],
    routes: [
      // Shell wraps all tab-bar screens — tab bar floats above content
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const MoviesPage()),
          GoRoute(path: '/shows', builder: (_, _) => const ShowsPage()),
          GoRoute(path: '/search', builder: (_, _) => const SearchPage()),
          GoRoute(path: '/library', builder: (_, _) => const LibraryPage()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
          GoRoute(path: '/power', builder: (_, _) => const PowerPage()),
          GoRoute(
            path: '/catalog/:provider/:category',
            builder: (ctx, state) {
              final extra = state.extra;
              return CatalogBrowsePage(
                provider: state.pathParameters['provider']!,
                category: state.pathParameters['category']!,
                mediaType: state.uri.queryParameters['type'] ?? 'movie',
                title: state.uri.queryParameters['title'],
                returnFocusNode: extra is CatalogBrowseRouteExtra
                    ? extra.returnFocusNode
                    : null,
              );
            },
          ),
        ],
      ),
      // Full-screen routes (no TabBar/Shell)
      GoRoute(
        path: '/detail/:mediaType/:mediaId',
        builder: (ctx, state) {
          final extra = state.extra;
          return DetailViewPage(
            mediaType: state.pathParameters['mediaType']!,
            mediaId: state.pathParameters['mediaId']!,
            item: extra is DetailRouteExtra
                ? extra.item
                : (extra is MediaItem ? extra : null),
            returnFocusNode: extra is DetailRouteExtra
                ? extra.returnFocusNode
                : null,
          );
        },
      ),
      GoRoute(
        path: '/playback',
        builder: (ctx, state) => PlaybackPage(
          payload: (state.extra as Map<String, dynamic>?) ?? const {},
        ),
      ),
      GoRoute(
        path: '/episodes/:showId',
        builder: (ctx, state) => _PlaceholderScreen(
          label: 'Episodes: ${state.pathParameters['showId']}',
        ),
      ),
      GoRoute(
        path: '/local',
        builder: (_, _) => const _PlaceholderScreen(label: 'Local Browse'),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppShell — tab bar floats as an overlay above all shell-route content.
//
// Mirrors AppShell.tsx + TabBar.tsx exactly:
//   • TabBar is fixed/positioned at top-0, content fills the full screen height
//   • Each WidgetSection fills 100vh and pads its content below the tab bar
//   • No global backdrop widget — each WidgetSection renders its own
// ─────────────────────────────────────────────────────────────────────────────

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _routeIndex(path);
    if (path != '/search') LastTabRoute.value = path;

    // No SafeArea — backdrop must fill the full window edge-to-edge,
    // matching React's h-screen w-screen overflow-hidden wrapper.
    // TV overscan (48dp) is applied inside content widgets, not here.
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Global backdrop — correctly sized via SizedBox.expand → Stack(fit:expand)
          // Pages write backdropProvider on focus change; this widget just renders it.
          const BackdropLayer(),
          // Content (transparent — backdrop shows through)
          child,
          // Floating tab bar — blur + gradient background, pill-style active tab
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _WarpTabBar(selectedIndex: selectedIndex),
          ),
        ],
      ),
    );
  }

  static int _routeIndex(String path) => switch (path) {
    '/search' => 0,
    '/' => 1,
    '/shows' => 2,
    '/library' => 3,
    '/settings' => 4,
    '/power' => 5,
    _ => 1,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// _WarpTabBar — mirrors TabBar.tsx exactly
//
// Background: linear gradient (black/90 → black/60 → transparent) + blur(20)
// Items: centered row, rounded-full pill, active = white/15 bg + white/20 border
// ─────────────────────────────────────────────────────────────────────────────

class _WarpTabBar extends StatelessWidget {
  final int selectedIndex;
  const _WarpTabBar({required this.selectedIndex});

  static const _tabs = [
    (icon: Icons.search, label: 'Search', route: '/search'),
    (icon: Icons.movie_outlined, label: 'Movies', route: '/'),
    (icon: Icons.tv_outlined, label: 'Shows', route: '/shows'),
    (icon: Icons.folder_outlined, label: 'Library', route: '/library'),
    (icon: Icons.settings_outlined, label: 'Settings', route: '/settings'),
    (icon: Icons.power_settings_new, label: 'Power', route: '/power'),
  ];

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;
    // CSS: --tabbar-height: clamp(72px, 12vh, 100px)
    final barH = (screenH * 0.12).clamp(72.0, 100.0);
    // CSS: gap: clamp(16px, 2vw, 40px)
    final gap = (screenW * 0.02).clamp(16.0, 40.0);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: barH,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xE6000000), // rgba(0,0,0,0.9)
                Color(0x99000000), // rgba(0,0,0,0.6)
                Color(0x00000000), // transparent
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
          // FittedBox scales the pill row down uniformly on narrow windows,
          // so individual pill sizes stay proportional (matches CSS clamp behaviour).
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: DpadRegion(
                memoryKey: 'tab-bar',
                horizontalEdge: DpadEdgeBehavior.stop,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _tabs.length; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      _TabPill(tab: _tabs[i], isActive: selectedIndex == i),
                    ],
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

class _TabPill extends ConsumerStatefulWidget {
  final ({IconData icon, String label, String route}) tab;
  final bool isActive;

  const _TabPill({required this.tab, required this.isActive});

  @override
  ConsumerState<_TabPill> createState() => _TabPillState();
}

class _TabPillState extends ConsumerState<_TabPill> {
  final _focusNode = FocusNode(debugLabel: 'TabPill');
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    ref
        .read(tabBarFocusRegistryProvider)
        .register(widget.tab.route, _focusNode);
  }

  @override
  void didUpdateWidget(_TabPill old) {
    super.didUpdateWidget(old);
    if (old.tab.route != widget.tab.route) {
      ref.read(tabBarFocusRegistryProvider).unregister(old.tab.route);
      ref
          .read(tabBarFocusRegistryProvider)
          .register(widget.tab.route, _focusNode);
    }
  }

  @override
  void dispose() {
    ref.read(tabBarFocusRegistryProvider).unregister(widget.tab.route);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;

    // CSS: font-size: clamp(15px, 1vw, 18px)
    final fontSize = (screenW * 0.01).clamp(15.0, 18.0);
    // CSS: padding: clamp(8px,0.63vw,14px) clamp(14px,1.46vw,24px)
    final padV = (screenW * 0.0063).clamp(8.0, 14.0);
    final padH = (screenW * 0.0146).clamp(14.0, 24.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: DpadFocusable(
        focusNode: _focusNode,
        onSelect: () => context.go(widget.tab.route),
        builder: (context, state, child) {
          final active = widget.isActive || state.focused || _hovered;
          // The active-tab pill and a focused pill share the exact same
          // "active" look, so landing focus back on the already-selected
          // tab was otherwise invisible. Layer a cyan ring on top only for
          // that specific overlap — never for focus-alone or active-alone,
          // since those already read fine on their own.
          final showFocusRing = widget.isActive && state.focused;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            decoration: BoxDecoration(
              // active: bg-white/15  inactive: transparent
              color: active ? const Color(0x26FFFFFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              // active: border border-white/20  inactive: no border
              border: Border.all(
                color: showFocusRing
                    ? WarpColors.accent
                    : (active ? const Color(0x33FFFFFF) : Colors.transparent),
                width: showFocusRing ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.tab.icon,
                  size: 16,
                  color: active ? Colors.white : const Color(0x99FFFFFF),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.tab.label,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0x99FFFFFF),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Temporary placeholder — replaced screen-by-screen in Phase 2+
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  final String label;
  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFDEDEDE),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
