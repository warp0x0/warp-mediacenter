import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

const _methods = MethodChannel('warp/external_player/methods');
const _events = EventChannel('warp/external_player/events');

enum ExternalPlayerResultCode { ok, canceled }

class ExternalPlayerResult {
  final ExternalPlayerResultCode code;
  final int? positionMs;
  final int? durationMs;

  const ExternalPlayerResult({
    required this.code,
    this.positionMs,
    this.durationMs,
  });

  factory ExternalPlayerResult.fromMap(Map<dynamic, dynamic> map) {
    final rawCode = map['resultCode']?.toString();
    return ExternalPlayerResult(
      code: rawCode == 'ok'
          ? ExternalPlayerResultCode.ok
          : ExternalPlayerResultCode.canceled,
      positionMs: (map['positionMs'] as num?)?.toInt(),
      durationMs: (map['durationMs'] as num?)?.toInt(),
    );
  }
}

class ExternalVideoPlayer {
  static const label = 'MX Player';

  static Stream<ExternalPlayerResult> get results {
    if (!Platform.isAndroid) return const Stream.empty();
    return _events
        .receiveBroadcastStream()
        .where((raw) => raw is Map)
        .map(
          (raw) => ExternalPlayerResult.fromMap(raw as Map<dynamic, dynamic>),
        );
  }

  static Future<bool> isInstalled() async {
    if (!Platform.isAndroid) return false;
    return await _methods.invokeMethod<bool>('isMxPlayerInstalled') ?? false;
  }

  static Future<bool> openInstallPage() async {
    if (!Platform.isAndroid) return false;
    return await _methods.invokeMethod<bool>('openMxPlayerInstallPage') ??
        false;
  }

  static Future<bool> launch({
    required String url,
    String? title,
    int? positionMs,
  }) async {
    if (!Platform.isAndroid) return false;
    return await _methods.invokeMethod<bool>('launchMxPlayer', {
          'url': url,
          if (title != null && title.isNotEmpty) 'title': title,
          if (positionMs != null && positionMs > 0) 'positionMs': positionMs,
        }) ??
        false;
  }
}

bool shouldUseExternalMxPlayer(String? value) {
  final normalized = value?.toLowerCase() ?? '';
  if (normalized.isEmpty) return false;
  final safeCodec = RegExp(r'\b(h\.?264|x264|avc)\b');
  if (safeCodec.hasMatch(normalized)) return false;
  final riskyCodec = RegExp(
    r'\b(hevc|h\.?265|x265|10[- ]?bit|hdr|dolby[ ._-]?vision|dv|av1)\b',
  );
  return riskyCodec.hasMatch(normalized);
}
