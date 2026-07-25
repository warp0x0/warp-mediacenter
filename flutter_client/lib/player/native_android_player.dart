import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

const _viewType = 'warp/native_media3_player';

class NativePlayerEvent {
  final String type;
  final String state;
  final String? reason;
  final bool playing;
  final int positionMs;
  final int durationMs;
  final int bufferedPositionMs;
  final double volume;
  final String? code;
  final String? message;
  final int? width;
  final int? height;
  final List<NativePlayerTrack> audioTracks;
  final List<NativePlayerTrack> subtitleTracks;
  final String? selectedAudioTrackId;
  final String? selectedSubtitleTrackId;

  const NativePlayerEvent({
    required this.type,
    required this.state,
    required this.playing,
    required this.positionMs,
    required this.durationMs,
    required this.bufferedPositionMs,
    required this.volume,
    this.reason,
    this.code,
    this.message,
    this.width,
    this.height,
    this.audioTracks = const [],
    this.subtitleTracks = const [],
    this.selectedAudioTrackId,
    this.selectedSubtitleTrackId,
  });

  factory NativePlayerEvent.fromMap(Map<dynamic, dynamic> map) {
    return NativePlayerEvent(
      type: map['type']?.toString() ?? 'status',
      state: map['state']?.toString() ?? '',
      reason: map['reason']?.toString(),
      playing: map['playing'] == true,
      positionMs: (map['positionMs'] as num?)?.toInt() ?? 0,
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      bufferedPositionMs: (map['bufferedPositionMs'] as num?)?.toInt() ?? 0,
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
      code: map['code']?.toString(),
      message: map['message']?.toString(),
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      audioTracks: NativePlayerTrack.listFrom(map['audioTracks']),
      subtitleTracks: NativePlayerTrack.listFrom(map['subtitleTracks']),
      selectedAudioTrackId: map['selectedAudioTrackId']?.toString(),
      selectedSubtitleTrackId: map['selectedSubtitleTrackId']?.toString(),
    );
  }
}

class NativePlayerTrack {
  final String id;
  final String title;
  final String? language;
  final String? codec;
  final String? mimeType;
  final int? channelCount;
  final int? sampleRate;
  final bool selected;
  final bool supported;

  const NativePlayerTrack({
    required this.id,
    required this.title,
    this.language,
    this.codec,
    this.mimeType,
    this.channelCount,
    this.sampleRate,
    this.selected = false,
    this.supported = true,
  });

  factory NativePlayerTrack.fromMap(Map<dynamic, dynamic> map) {
    return NativePlayerTrack(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Track',
      language: map['language']?.toString(),
      codec: map['codec']?.toString(),
      mimeType: map['mimeType']?.toString(),
      channelCount: (map['channelCount'] as num?)?.toInt(),
      sampleRate: (map['sampleRate'] as num?)?.toInt(),
      selected: map['selected'] == true,
      supported: map['supported'] != false,
    );
  }

  static List<NativePlayerTrack> listFrom(Object? value) {
    final list = value is List ? value : const [];
    return [
      for (final item in list)
        if (item is Map) NativePlayerTrack.fromMap(item),
    ];
  }
}

class NativeAndroidPlayerController {
  final _events = StreamController<NativePlayerEvent>.broadcast();
  final _ready = Completer<void>();
  StreamSubscription<dynamic>? _eventSub;
  MethodChannel? _methods;
  bool _disposed = false;

  Stream<NativePlayerEvent> get events => _events.stream;
  Future<void> get ready => _ready.future;

  bool get isAttached => _methods != null && !_disposed;

  Future<void> attach(int viewId) async {
    if (_disposed || _methods != null) return;
    _methods = MethodChannel('warp/native_media3_player/$viewId/methods');
    final eventChannel = EventChannel(
      'warp/native_media3_player/$viewId/events',
    );
    _eventSub = eventChannel.receiveBroadcastStream().listen((raw) {
      if (raw is Map) {
        _events.add(NativePlayerEvent.fromMap(raw));
      }
    }, onError: _events.addError);
    if (!_ready.isCompleted) _ready.complete();
  }

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    await ready;
    if (_disposed) return null;
    return _methods?.invokeMethod<T>(method, args);
  }

  Future<void> setDataSource({
    String? source,
    String? videoUrl,
    String? audioUrl,
    Map<String, String>? headers,
    Duration startPosition = Duration.zero,
    bool autoplay = true,
    bool youtubeTrailerMode = false,
  }) async {
    await _invoke<void>('setDataSource', {
      if (source != null && source.isNotEmpty) 'source': source,
      if (videoUrl != null && videoUrl.isNotEmpty) 'videoUrl': videoUrl,
      if (audioUrl != null && audioUrl.isNotEmpty) 'audioUrl': audioUrl,
      if (headers != null && headers.isNotEmpty) 'headers': headers,
      'startPositionMs': startPosition.inMilliseconds,
      'autoplay': autoplay,
      'youtubeTrailerMode': youtubeTrailerMode,
    });
  }

  Future<void> play() => _invoke<void>('play');

  Future<void> pause() => _invoke<void>('pause');

  Future<void> seekTo(Duration position) =>
      _invoke<void>('seekTo', {'positionMs': position.inMilliseconds});

  Future<void> seekBy(Duration delta) =>
      _invoke<void>('seekBy', {'deltaMs': delta.inMilliseconds});

  Future<void> setVolume(double value) =>
      _invoke<void>('setVolume', {'volume': value.clamp(0.0, 1.0)});

  Future<void> setAudioBoostDb(double value) =>
      _invoke<void>('setAudioBoost', {'boostDb': value.clamp(0.0, 30.0)});

  Future<void> setAspectRatioMode(String mode) =>
      _invoke<void>('setAspectRatioMode', {'mode': mode});

  Future<void> setSubtitleDelay(Duration delay) =>
      _invoke<void>('setSubtitleDelay', {'delayMs': delay.inMilliseconds});

  Future<void> setSubtitleTextSizeSp(double sizeSp) => _invoke<void>(
    'setSubtitleTextSize',
    {'sizeSp': sizeSp.clamp(20.0, 100.0)},
  );

  Future<void> loadSubtitle({
    required String uri,
    String? title,
    String? language,
  }) => _invoke<void>('loadSubtitle', {
    'uri': uri,
    if (title != null && title.isNotEmpty) 'title': title,
    if (language != null && language.isNotEmpty) 'language': language,
  });

  Future<void> selectAudioTrack(String id) =>
      _invoke<void>('selectAudioTrack', {'id': id});

  Future<void> selectSubtitleTrack(String id) =>
      _invoke<void>('selectSubtitleTrack', {'id': id});

  Future<NativePlayerEvent?> getTracks() async {
    final raw = await _invoke<Map<dynamic, dynamic>>('getTracks');
    return raw == null ? null : NativePlayerEvent.fromMap(raw);
  }

  Future<void> setAudioPassthrough(bool enabled) =>
      _invoke<void>('setAudioPassthrough', {'enabled': enabled});

  Future<void> setDolbyMode(bool enabled) =>
      _invoke<void>('setDolbyMode', {'enabled': enabled});

  Future<void> stop() => _invoke<void>('stop');

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _eventSub?.cancel();
    try {
      await _methods?.invokeMethod<void>('dispose');
    } catch (_) {}
    await _events.close();
  }
}

class NativeAndroidPlayerSurface extends StatelessWidget {
  final NativeAndroidPlayerController controller;
  final Map<String, Object?> creationParams;
  final bool fill;
  final String renderSurface;

  const NativeAndroidPlayerSurface({
    super.key,
    required this.controller,
    this.fill = false,
    this.renderSurface = 'surface',
    this.creationParams = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            'Native Media3 player is Android-only.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return PlatformViewLink(
      viewType: _viewType,
      surfaceFactory: (context, platformViewController) {
        return AndroidViewSurface(
          controller: platformViewController as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        final paramsMap = <String, Object?>{
          ...creationParams,
          if (fill) 'resizeMode': 'fill',
          'renderSurface': renderSurface,
        };
        return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: _viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: paramsMap,
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () => params.onFocusChanged(true),
          )
          ..addOnPlatformViewCreatedListener((id) {
            params.onPlatformViewCreated(id);
            unawaited(controller.attach(id));
          })
          ..create();
      },
    );
  }
}

String formatNativePlayerTime(int ms) {
  final d = Duration(milliseconds: ms);
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}
