import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;

import 'warp_playback_backend.dart';

/// Desktop and non-TV-Android backend: media_kit/libmpv. Extracted from the
/// player logic that used to live inline in playback_page.dart (M6).
class WarpMediaKitBackend implements WarpPlaybackBackend {
  WarpMediaKitBackend() {
    _player = mk.Player();
    _controller = mkv.VideoController(_player);

    _bufferingSubscription = _player.stream.buffering.listen((buffering) {
      _stateController.add(
        buffering ? WarpPlaybackState.buffering : WarpPlaybackState.ready,
      );
    });
    _positionSubscription = _player.stream.position.listen((position) {
      _positionController.add(
        WarpPositionUpdate(
          position: position,
          bufferedPosition: _player.state.buffer,
          duration: _player.state.duration,
        ),
      );
    });
    _completedSubscription = _player.stream.completed.listen((done) {
      if (done) _completedController.add(null);
    });
    _errorSubscription = _player.stream.error.listen((error) {
      _errorController.add(
        WarpPlayerError(code: 'mpv_error', message: error),
      );
    });
    _widthSubscription = _player.stream.width.listen((_) => _emitVideoSize());
    _heightSubscription = _player.stream.height.listen((_) => _emitVideoSize());
    _tracksSubscription = _player.stream.tracks.listen((tracks) {
      _tracksController.add(_parseTracks(tracks));
    });
  }

  late final mk.Player _player;
  late final mkv.VideoController _controller;

  late final StreamSubscription<bool> _bufferingSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<bool> _completedSubscription;
  late final StreamSubscription<String> _errorSubscription;
  late final StreamSubscription<int?> _widthSubscription;
  late final StreamSubscription<int?> _heightSubscription;
  late final StreamSubscription<mk.Tracks> _tracksSubscription;

  final _stateController = StreamController<WarpPlaybackState>.broadcast();
  final _positionController = StreamController<WarpPositionUpdate>.broadcast();
  final _videoSizeController = StreamController<WarpVideoSize>.broadcast();
  final _errorController = StreamController<WarpPlayerError>.broadcast();
  final _completedController = StreamController<void>.broadcast();
  final _tracksController = StreamController<WarpTrackList>.broadcast();

  @override
  Stream<WarpPlaybackState> get stateStream => _stateController.stream;
  @override
  Stream<bool> get playingStream => _player.stream.playing;
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
  bool get supportsAudioPassthrough => true;
  @override
  bool get supportsDemuxedSource => false;
  @override
  bool get supportsAudioAmplificationBeyond100 => true;

  void _emitVideoSize() {
    final w = _player.state.width;
    final h = _player.state.height;
    if (w != null && h != null) {
      _videoSizeController.add(WarpVideoSize(width: w, height: h));
    }
  }

  @override
  Future<void> setDataSource(
    WarpDataSource source, {
    Duration? startPosition,
  }) async {
    switch (source) {
      case WarpMuxedSource(:final url):
        // play: false — the native backend's setDataSource never auto-plays
        // either (ExoPlayer's setMediaSource/prepare doesn't start
        // playback), so callers must explicitly call play() afterward on
        // both backends. Relying on media_kit's own auto-play default here
        // would make behavior backend-dependent.
        await _player.open(mk.Media(url), play: false);
      case WarpDemuxedSource():
        // Movies/episodes (this backend's actual production use, per the
        // native player plan) are always single muxed URLs — demuxed
        // pairing is only ever needed on the YouTube/trailer path, which
        // lands in M4.
        throw UnimplementedError(
          'Demuxed video+audio sources on the media_kit backend land in M4',
        );
    }
    if (startPosition != null && startPosition > Duration.zero) {
      unawaited(
        _player.stream.duration.firstWhere((d) => d.inSeconds > 0).then((_) {
          _player.seek(startPosition);
        }),
      );
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seekTo(Duration position) => _player.seek(position);

  // media_kit's volume convention is 0-200 (percent); the interface's is
  // 0.0-2.0 (fraction) — convert here so the public contract stays uniform
  // across backends.
  @override
  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0.0, 2.0) * 100);

  @override
  Future<void> setPlaybackSpeed(double speed) => _player.setRate(speed);

  @override
  Future<WarpTrackList> getTracks() async => _parseTracks(_player.state.tracks);

  @override
  Future<void> selectAudioTrack(String trackId) async {
    final matches = _player.state.tracks.audio.where((t) => t.id == trackId);
    await _player.setAudioTrack(
      matches.isEmpty ? mk.AudioTrack.no() : matches.first,
    );
  }

  @override
  Future<String> addExternalSubtitle(
    String uri, {
    String? title,
    String? language,
  }) async {
    await _player.setSubtitleTrack(
      mk.SubtitleTrack.uri(uri, title: title, language: language),
    );
    // mpv registers external subtitle tracks asynchronously — wait for the
    // new track to actually appear (matches the existing ad-hoc workaround
    // in subtitle_dialog.dart, which this supersedes once SubtitleDialog is
    // wired onto this abstraction in M6/M7) before resolving, so callers
    // never see a track that isn't actually selectable yet.
    final tracks = await _player.stream.tracks.firstWhere(
      (t) => t.subtitle.any(
        (s) => s.uri && s.id != 'auto' && s.id != 'no',
      ),
    );
    final external = tracks.subtitle.where(
      (s) => s.uri && s.id != 'auto' && s.id != 'no',
    );
    return external.isEmpty ? '' : external.last.id;
  }

  @override
  Future<void> selectSubtitleTrack(String? trackId) async {
    if (trackId == null) {
      await _player.setSubtitleTrack(mk.SubtitleTrack.no());
      return;
    }
    final matches = _player.state.tracks.subtitle.where(
      (t) => t.id == trackId,
    );
    await _player.setSubtitleTrack(
      matches.isEmpty ? mk.SubtitleTrack.no() : matches.first,
    );
  }

  @override
  Future<void> setSubtitleDelay(Duration delay) => _setMpvProperty(
    'sub-delay',
    (delay.inMilliseconds / 1000).toStringAsFixed(2),
  );

  @override
  Future<void> setAudioPassthrough(bool enabled) => _setMpvProperty(
    'audio-spdif',
    enabled ? 'ac3,dts,dts-hd,eac3,truehd' : '',
  );

  @override
  Future<void> setDolbyMode(bool enabled) =>
      _setMpvProperty('audio-channels', enabled ? 'auto' : 'stereo');

  Future<void> _setMpvProperty(String property, String value) async {
    final platform = _player.platform;
    if (platform == null) return;
    try {
      await (platform as dynamic).setProperty(property, value);
    } catch (_) {
      // Advanced mpv options are unavailable on some platforms/backends.
    }
  }

  @override
  Widget buildSurface() => mkv.Video(
    controller: _controller,
    controls: null,
    fit: BoxFit.contain,
    // Matches the native backend's default subtitle style exactly (see
    // WarpExoPlayerController.applyDefaultSubtitleStyle) — baked into the
    // backend itself, same as the native side, rather than requiring every
    // caller to pass it through the interface.
    subtitleViewConfiguration: const mkv.SubtitleViewConfiguration(
      style: TextStyle(
        height: 1.4,
        fontSize: 40.0,
        letterSpacing: 0.0,
        wordSpacing: 0.0,
        color: Color(0xffffffff),
        fontWeight: FontWeight.w600,
        backgroundColor: Colors.transparent,
        shadows: [
          Shadow(color: Color(0xDD000000), blurRadius: 6, offset: Offset(1, 1)),
          Shadow(color: Color(0xAA000000), blurRadius: 3, offset: Offset(0, 0)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 48.0),
    ),
  );

  WarpTrackList _parseTracks(mk.Tracks tracks) {
    final currentAudioId = _player.state.track.audio.id;
    final currentSubtitleId = _player.state.track.subtitle.id;
    final audio = tracks.audio
        .where((t) => t.id != 'auto' && t.id != 'no')
        .map(
          (t) => WarpAudioTrack(
            id: t.id,
            language: t.language,
            label: t.title,
            codec: t.codec,
            channels: t.channelscount,
            bitrate: t.bitrate,
            selected: t.id == currentAudioId,
          ),
        )
        .toList();
    final text = tracks.subtitle
        .where((t) => t.id != 'auto' && t.id != 'no')
        .map(
          (t) => WarpTextTrack(
            id: t.id,
            language: t.language,
            label: t.title,
            isExternal: t.uri,
            selected: t.id == currentSubtitleId,
          ),
        )
        .toList();
    return WarpTrackList(audio: audio, text: text);
  }

  @override
  Future<void> dispose() async {
    await _bufferingSubscription.cancel();
    await _positionSubscription.cancel();
    await _completedSubscription.cancel();
    await _errorSubscription.cancel();
    await _widthSubscription.cancel();
    await _heightSubscription.cancel();
    await _tracksSubscription.cancel();
    await _stateController.close();
    await _positionController.close();
    await _videoSizeController.close();
    await _errorController.close();
    await _completedController.close();
    await _tracksController.close();
    await _player.stop();
    await _player.dispose();
  }
}
