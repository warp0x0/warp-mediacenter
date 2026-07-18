import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/warp_tokens.dart';
import 'better_player_backend.dart';
import 'media_kit_backend.dart';
import 'native_android_backend.dart';
import 'warp_playback_backend.dart';

/// Selects the playback backend for the current platform/device.
///
/// Native Media3/ExoPlayer is Android TV-only (reuses the existing leanback
/// feature detection at lib/main.dart's [uiDensityProvider] — no new
/// detection mechanism). Desktop and Android mobile keep using media_kit for
/// full playback. Trailers on non-TV platforms keep using the existing
/// better_player_enhanced path (wrapped in [WarpBetterPlayerBackend])
/// unchanged, per the locked scope decision in the native player
/// implementation plan — desktop/mobile trailer behavior is not being
/// changed by this work.
WarpPlaybackBackend createPlaybackBackend(
  WidgetRef ref, {
  required bool isTrailer,
}) {
  final isAndroidTv = Platform.isAndroid && ref.read(uiDensityProvider) == UiDensity.tv;
  if (isAndroidTv) return WarpNativeAndroidBackend();
  if (isTrailer) return WarpBetterPlayerBackend();
  return WarpMediaKitBackend();
}
