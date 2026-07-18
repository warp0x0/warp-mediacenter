import 'dart:async';

import 'package:better_player_enhanced/better_player.dart';
import 'package:flutter/widgets.dart';

import '../better_trailer_player.dart';
import 'warp_playback_backend.dart';

/// Thin adapter wrapping the existing better_player_enhanced trailer path
/// (BetterTrailerPlayerController/BetterTrailerPlayerSurface, unchanged)
/// behind WarpPlaybackBackend, so TrailerDialog can use one uniform backend
/// type across platforms once wired in M7. Scope: desktop and non-TV-Android
/// trailers only — Android TV trailers use WarpNativeAndroidBackend instead
/// (see backend_factory.dart). Not yet used by any caller as of M3; exists
/// so the factory and interface are complete.
///
/// No native track/subtitle API exists in better_player_enhanced's trailer
/// usage today (trailers don't need it), so those methods are no-ops here.
class WarpBetterPlayerBackend implements WarpPlaybackBackend {
  WarpBetterPlayerBackend() {
    _controller = BetterTrailerPlayerController(
      onError: (message) => _errorController.add(
        WarpPlayerError(code: 'better_player_error', message: message),
      ),
    );
    _positionTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _pollPosition(),
    );
  }

  late final BetterTrailerPlayerController _controller;
  late final Timer _positionTimer;
  bool _everReady = false;
  bool? _lastIsPlaying;

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

  @override
  bool get supportsAudioPassthrough => false;
  @override
  bool get supportsDemuxedSource => false;
  @override
  bool get supportsAudioAmplificationBeyond100 => false;

  @override
  Future<void> setAudioPassthrough(bool enabled) async {}
  @override
  Future<void> setDolbyMode(bool enabled) async {}

  BetterPlayerController get _player => _controller.controller;

  void _pollPosition() {
    final value = _player.videoPlayerController?.value;
    if (value == null) return;
    final duration = value.duration ?? Duration.zero;
    _positionController.add(
      WarpPositionUpdate(
        position: value.position,
        bufferedPosition: value.buffered.isEmpty
            ? Duration.zero
            : value.buffered.last.end,
        duration: duration,
      ),
    );
    final state = value.isBuffering
        ? WarpPlaybackState.buffering
        : WarpPlaybackState.ready;
    if (state == WarpPlaybackState.ready) _everReady = true;
    _stateController.add(state);
    if (value.isPlaying != _lastIsPlaying) {
      _lastIsPlaying = value.isPlaying;
      _playingController.add(value.isPlaying);
    }
    if (_everReady &&
        duration > Duration.zero &&
        value.position >= duration) {
      _completedController.add(null);
    }
  }

  @override
  Future<void> setDataSource(
    WarpDataSource source, {
    Duration? startPosition,
  }) async {
    switch (source) {
      case WarpMuxedSource(:final url):
        await _controller.load(url);
      case WarpDemuxedSource():
        throw UnimplementedError(
          'Demuxed sources are not supported by the better_player_enhanced backend',
        );
    }
    if (startPosition != null && startPosition > Duration.zero) {
      await _player.seekTo(startPosition);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seekTo(Duration position) => _player.seekTo(position);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume.clamp(0.0, 1.0));

  @override
  Future<void> setPlaybackSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<WarpTrackList> getTracks() async => const WarpTrackList();

  @override
  Future<void> selectAudioTrack(String trackId) async {}

  @override
  Future<String> addExternalSubtitle(
    String uri, {
    String? title,
    String? language,
  }) async => '';

  @override
  Future<void> selectSubtitleTrack(String? trackId) async {}

  @override
  Future<void> setSubtitleDelay(Duration delay) async {}

  @override
  Widget buildSurface() => BetterTrailerPlayerSurface(controller: _controller);

  @override
  Future<void> dispose() async {
    _positionTimer.cancel();
    _controller.dispose();
    await _stateController.close();
    await _playingController.close();
    await _positionController.close();
    await _videoSizeController.close();
    await _errorController.close();
    await _completedController.close();
    await _tracksController.close();
  }
}
