import 'dart:async';

import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'warp_playback_backend.dart';

const String _methodChannelPrefix =
    'com.warp.warp_mediacenter_client/warp_player_methods/';
const String _eventChannelPrefix =
    'com.warp.warp_mediacenter_client/warp_player_events/';
const String _viewType = 'com.warp.warp_mediacenter_client/warp_player_view';

/// Android TV-only backend: native Media3/ExoPlayer rendering to a
/// SurfaceView via true Hybrid Composition, bypassing Flutter's compositor
/// entirely for video. See PLAYER_PROTOTYPE.md and the native player
/// implementation plan for the full design (and why a plain `AndroidView`
/// does not work here — it defaults to Texture Layer Hybrid Composition,
/// which does not correctly composite a raw SurfaceView).
///
/// Wiring validated against the native Kotlin side via the M1/M2/M3 debug
/// page (lib/pages/debug/native_player_smoke_test_page.dart, now itself
/// rewired onto this class). Demuxed sources (MergingMediaSource, M4) are
/// implemented natively. Subtitle methods (M5) are wired through to the
/// native MethodChannel contract already, but the native side doesn't
/// implement them yet — calls fail until that milestone lands.
class WarpNativeAndroidBackend implements WarpPlaybackBackend {
  WarpNativeAndroidBackend() : instanceId = const Uuid().v4() {
    _methodChannel = MethodChannel(_methodChannelPrefix + instanceId);
    _eventChannel = EventChannel(_eventChannelPrefix + instanceId);
  }

  final String instanceId;
  late final MethodChannel _methodChannel;
  late final EventChannel _eventChannel;
  StreamSubscription<dynamic>? _eventSubscription;

  bool _surfaceReady = false;
  final Completer<void> _surfaceReadyCompleter = Completer<void>();
  WarpDataSource? _pendingDataSource;
  Duration? _pendingStartPosition;

  // Every outgoing method call must wait for the platform view (and its
  // native MethodChannel handler) to actually exist — invoking a method
  // before then throws MissingPluginException, since nothing is registered
  // on the channel yet. Callers can build the widget tree and immediately
  // start issuing commands (see trailer_dialog.dart's _openStreams) well
  // before the platform view creation round trip completes.
  Future<void> _ensureSurfaceReady() =>
      _surfaceReady ? Future.value() : _surfaceReadyCompleter.future;

  final _stateController = StreamController<WarpPlaybackState>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _positionController = StreamController<WarpPositionUpdate>.broadcast();
  final _videoSizeController = StreamController<WarpVideoSize>.broadcast();
  final _errorController = StreamController<WarpPlayerError>.broadcast();
  final _completedController = StreamController<void>.broadcast();
  final _tracksController = StreamController<WarpTrackList>.broadcast();

  @override
  Stream<WarpPlaybackState> get stateStream => _stateController.stream;
  @override
  Stream<bool> get playingStream => _playingController.stream;
  @override
  Stream<WarpPositionUpdate> get positionStream => _positionController.stream;
  @override
  Stream<WarpVideoSize> get videoSizeStream => _videoSizeController.stream;
  @override
  Stream<WarpPlayerError> get errorStream => _errorController.stream;
  @override
  Stream<void> get completedStream => _completedController.stream;
  @override
  Stream<WarpTrackList> get tracksStream => _tracksController.stream;

  // No MediaCodec-level equivalent to mpv's audio-spdif/audio-channels
  // toggles, and ExoPlayer's volume is hard-capped at 1.0 with no software
  // gain stage — see WarpPlaybackBackend's doc comments for the UI
  // implication (these controls should be hidden, not disabled, here).
  @override
  bool get supportsAudioPassthrough => false;
  @override
  bool get supportsDemuxedSource => true;
  @override
  bool get supportsAudioAmplificationBeyond100 => false;

  @override
  Future<void> setAudioPassthrough(bool enabled) async {}
  @override
  Future<void> setDolbyMode(bool enabled) async {}

  @override
  Future<void> setDataSource(
    WarpDataSource source, {
    Duration? startPosition,
  }) async {
    _pendingDataSource = source;
    _pendingStartPosition = startPosition;
    // The native view (and its channel handlers) may not exist yet if
    // setDataSource is called before buildSurface()'s platform view has
    // finished creating — flush once _onPlatformViewCreated fires. If the
    // surface already exists, apply immediately.
    if (_surfaceReady) await _applyPendingDataSource();
  }

  Future<void> _applyPendingDataSource() async {
    final source = _pendingDataSource;
    if (source == null) return;
    final args = <String, dynamic>{
      if (_pendingStartPosition != null)
        'startPositionMs': _pendingStartPosition!.inMilliseconds,
    };
    switch (source) {
      case WarpMuxedSource(:final url, :final headers):
        args['muxedUrl'] = url;
        if (headers != null) args['headers'] = headers;
      case WarpDemuxedSource(:final videoUrl, :final audioUrl, :final headers):
        args['videoUrl'] = videoUrl;
        args['audioUrl'] = audioUrl;
        if (headers != null) args['headers'] = headers;
    }
    await _methodChannel.invokeMethod<void>('setDataSource', args);
  }

  @override
  Future<void> play() async {
    await _ensureSurfaceReady();
    await _methodChannel.invokeMethod<void>('play');
  }

  @override
  Future<void> pause() async {
    await _ensureSurfaceReady();
    await _methodChannel.invokeMethod<void>('pause');
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _ensureSurfaceReady();
    await _methodChannel.invokeMethod<void>('seekTo', {
      'positionMs': position.inMilliseconds,
    });
  }

  @override
  Future<void> setVolume(double volume) async {
    await _ensureSurfaceReady();
    await _methodChannel.invokeMethod<void>('setVolume', {
      'volume': volume.clamp(0.0, 1.0),
    });
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    await _ensureSurfaceReady();
    await _methodChannel.invokeMethod<void>('setPlaybackSpeed', {
      'speed': speed,
    });
  }

  @override
  Future<WarpTrackList> getTracks() async {
    await _ensureSurfaceReady();
    final result = await _methodChannel.invokeMapMethod<String, dynamic>(
      'getTracks',
    );
    return _parseTrackList(result);
  }

  @override
  Future<void> selectAudioTrack(String trackId) async {
    await _ensureSurfaceReady();
    await _methodChannel.invokeMethod<void>('selectAudioTrack', {
      'trackId': trackId,
    });
  }

  @override
  Future<String> addExternalSubtitle(
    String uri, {
    String? title,
    String? language,
  }) async {
    await _ensureSurfaceReady();
    final result = await _methodChannel.invokeMapMethod<String, dynamic>(
      'addExternalSubtitle',
      {'uri': uri, 'title': title, 'language': language},
    );
    return result?['trackId'] as String? ?? '';
  }

  @override
  Future<void> selectSubtitleTrack(String? trackId) async {
    await _ensureSurfaceReady();
    await _methodChannel.invokeMethod<void>('selectSubtitleTrack', {
      'trackId': trackId,
    });
  }

  @override
  Future<void> setSubtitleDelay(Duration delay) async {
    await _ensureSurfaceReady();
    await _methodChannel.invokeMethod<void>('setSubtitleDelayMs', {
      'delayMs': delay.inMilliseconds,
    });
  }

  @override
  Widget buildSurface() {
    // Deliberately NOT a plain AndroidView — see the class doc comment.
    // This surface is never wrapped in Focus/DpadFocusable by this class;
    // callers must not wrap it either (mirrors playback_page.dart's bare
    // video-widget pattern) so it can never steal D-pad focus.
    return PlatformViewLink(
      viewType: _viewType,
      surfaceFactory: (context, controller) => AndroidViewSurface(
        controller: controller as AndroidViewController,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      ),
      onCreatePlatformView: (params) {
        return PlatformViewsService.initSurfaceAndroidView(
          id: params.id,
          viewType: _viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: {'instanceId': instanceId},
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () => params.onFocusChanged(true),
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..addOnPlatformViewCreatedListener(_onPlatformViewCreated)
          ..create();
      },
    );
  }

  void _onPlatformViewCreated(int id) {
    // Must subscribe only after the platform view (and its native
    // EventChannel handler) actually exists — subscribing earlier sends a
    // "listen" handshake nothing is registered to receive yet, and it's
    // silently dropped with no error on either side (cost real debugging
    // time during M1/M2 — see feedback_flutter_surfaceview_platformview
    // memory).
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(_onEvent);
    _surfaceReady = true;
    if (!_surfaceReadyCompleter.isCompleted) _surfaceReadyCompleter.complete();
    unawaited(_applyPendingDataSource());
  }

  void _onEvent(dynamic event) {
    if (event is! Map) return;
    final map = Map<String, dynamic>.from(event);
    switch (map['event']) {
      case 'stateChanged':
        _stateController.add(_parseState(map['state'] as String?));
      case 'playingChanged':
        _playingController.add(map['playing'] as bool? ?? false);
      case 'positionUpdate':
        _positionController.add(
          WarpPositionUpdate(
            position: Duration(
              milliseconds: (map['positionMs'] as num).toInt(),
            ),
            bufferedPosition: Duration(
              milliseconds: (map['bufferedPositionMs'] as num).toInt(),
            ),
            duration: Duration(
              milliseconds: (map['durationMs'] as num).toInt(),
            ),
          ),
        );
      case 'videoSizeChanged':
        _videoSizeController.add(
          WarpVideoSize(
            width: (map['width'] as num).toInt(),
            height: (map['height'] as num).toInt(),
            rotationDegrees: (map['rotationDegrees'] as num?)?.toInt() ?? 0,
          ),
        );
      case 'tracksChanged':
        _tracksController.add(_parseTrackList(map));
      case 'completed':
        _completedController.add(null);
      case 'error':
        _errorController.add(
          WarpPlayerError(
            code: map['code'] as String? ?? 'unknown',
            message: map['message'] as String? ?? '',
            isRecoverable: map['isRecoverable'] as bool? ?? false,
          ),
        );
    }
  }

  WarpPlaybackState _parseState(String? raw) => switch (raw) {
    'idle' => WarpPlaybackState.idle,
    'buffering' => WarpPlaybackState.buffering,
    'ready' => WarpPlaybackState.ready,
    'ended' => WarpPlaybackState.ended,
    'error' => WarpPlaybackState.error,
    _ => WarpPlaybackState.idle,
  };

  WarpTrackList _parseTrackList(Map<String, dynamic>? raw) {
    if (raw == null) return const WarpTrackList();
    final audio = ((raw['audio'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(
          (m) => WarpAudioTrack(
            id: m['id'] as String,
            language: m['language'] as String?,
            label: m['label'] as String?,
            codec: m['codec'] as String?,
            channels: (m['channels'] as num?)?.toInt(),
            bitrate: (m['bitrate'] as num?)?.toInt(),
            selected: m['selected'] as bool? ?? false,
          ),
        )
        .toList();
    final text = ((raw['text'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(
          (m) => WarpTextTrack(
            id: m['id'] as String,
            language: m['language'] as String?,
            label: m['label'] as String?,
            isExternal: m['isExternal'] as bool? ?? false,
            selected: m['selected'] as bool? ?? false,
          ),
        )
        .toList();
    return WarpTrackList(audio: audio, text: text);
  }

  @override
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    try {
      await _methodChannel.invokeMethod<void>('dispose');
    } catch (_) {
      // Best-effort — native side may already be gone (e.g. platform view
      // torn down first).
    }
    await _stateController.close();
    await _playingController.close();
    await _positionController.close();
    await _videoSizeController.close();
    await _errorController.close();
    await _completedController.close();
    await _tracksController.close();
  }
}
