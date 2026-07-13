import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'api/api_client.dart';
import 'navigation/router.dart';
import 'theme/warp_theme.dart';
import 'theme/warp_tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for desktop fullscreen support
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(const WindowOptions(), () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize media_kit (libmpv) before any Player is created
  MediaKit.ensureInitialized();

  // Load persisted settings before first frame
  final savedBaseUrl = await loadSavedBaseUrl();
  final density = await _detectUiDensity();

  // Lock to landscape — media center is landscape-first on all platforms
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Full-screen immersive on Android TV
  if (Platform.isAndroid) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  runApp(
    ProviderScope(
      overrides: [
        apiBaseUrlProvider.overrideWith(() => ApiBaseUrlNotifier(savedBaseUrl)),
        uiDensityProvider.overrideWith(() => UiDensityNotifier(density)),
      ],
      child: const WarpApp(),
    ),
  );
}

// Auto-detect Android TV via the leanback system feature flag
Future<UiDensity> _detectUiDensity() async {
  if (!Platform.isAndroid) return UiDensity.desktop;
  try {
    final android = await DeviceInfoPlugin().androidInfo;
    if (android.systemFeatures.contains('android.software.leanback')) {
      return UiDensity.tv;
    }
  } catch (_) {}
  return UiDensity.desktop;
}

// ─────────────────────────────────────────────────────────────────────────────
// WarpApp — root widget
// ─────────────────────────────────────────────────────────────────────────────

class WarpApp extends ConsumerWidget {
  const WarpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(warpRouterProvider);
    final density = ref.watch(uiDensityProvider);

    // Build theme with a default screen size — widgets use WarpTokens.of(ctx)
    // internally for accurate fluid sizing at their own layout context.
    final tokens = WarpTokens(density, const Size(1280, 720));

    return MaterialApp.router(
      title: 'Warp MediaCenter',
      debugShowCheckedModeBanner: false,
      theme: WarpTheme.build(tokens),
      routerConfig: router,
      builder: (context, child) {
        final dpadWrapped = Dpad.wrap(
          // Page/dialog-level handlers own Back/Escape. The root dpad has no
          // onBack callback, so mapping these keys here can preempt focused
          // text fields and route-specific shortcuts.
          keySet: const DpadKeySet(back: []),
        )(context, child);
        if (density != UiDensity.tv) return dpadWrapped;
        return _TvViewportScale(child: dpadWrapped);
      },
    );
  }
}

class _TvViewportScale extends StatelessWidget {
  static const _scale = 0.4;
  static const _chromeScale = 1.5;

  final Widget child;

  const _TvViewportScale({required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    if (size.width <= 0 || size.height <= 0) return child;

    final virtualSize = Size(size.width / _scale, size.height / _scale);
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: virtualSize.width,
        maxWidth: virtualSize.width,
        minHeight: virtualSize.height,
        maxHeight: virtualSize.height,
        child: Transform.scale(
          scale: _scale,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: virtualSize.width,
            height: virtualSize.height,
            child: MediaQuery(
              data: media.copyWith(
                size: virtualSize,
                textScaler: TextScaler.linear(_chromeScale),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
