import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

const _methods = MethodChannel('warp/external_player/methods');
const _events = EventChannel('warp/external_player/events');

enum ExternalMpvResultCode { ok, canceled }

class ExternalMpvResult {
  final ExternalMpvResultCode code;
  final int? positionMs;
  final int? durationMs;

  const ExternalMpvResult({
    required this.code,
    this.positionMs,
    this.durationMs,
  });

  factory ExternalMpvResult.fromMap(Map<dynamic, dynamic> map) {
    final rawCode = map['resultCode']?.toString();
    return ExternalMpvResult(
      code: rawCode == 'ok'
          ? ExternalMpvResultCode.ok
          : ExternalMpvResultCode.canceled,
      positionMs: (map['positionMs'] as num?)?.toInt(),
      durationMs: (map['durationMs'] as num?)?.toInt(),
    );
  }
}

class ExternalMpvPlayer {
  static Stream<ExternalMpvResult> get results {
    if (!Platform.isAndroid) return const Stream.empty();
    return _events
        .receiveBroadcastStream()
        .where((raw) => raw is Map)
        .map((raw) => ExternalMpvResult.fromMap(raw as Map<dynamic, dynamic>));
  }

  static Future<bool> isInstalled() async {
    if (!Platform.isAndroid) return false;
    return await _methods.invokeMethod<bool>('isMpvInstalled') ?? false;
  }

  static Future<bool> openInstallPage() async {
    if (!Platform.isAndroid) return false;
    return await _methods.invokeMethod<bool>('openMpvInstallPage') ?? false;
  }

  static Future<bool> launch({
    required String url,
    String? title,
    int? positionMs,
  }) async {
    if (!Platform.isAndroid) return false;
    return await _methods.invokeMethod<bool>('launchMpv', {
          'url': url,
          if (title != null && title.isNotEmpty) 'title': title,
          if (positionMs != null && positionMs > 0) 'positionMs': positionMs,
        }) ??
        false;
  }
}

bool shouldUseExternalMpv(String? value) {
  final normalized = value?.toLowerCase() ?? '';
  if (normalized.isEmpty) return false;
  final safeCodec = RegExp(r'\b(h\.?264|x264|avc)\b');
  if (safeCodec.hasMatch(normalized)) return false;
  final riskyCodec = RegExp(
    r'\b(hevc|h\.?265|x265|10[- ]?bit|hdr|dolby[ ._-]?vision|dv|av1)\b',
  );
  return riskyCodec.hasMatch(normalized);
}
