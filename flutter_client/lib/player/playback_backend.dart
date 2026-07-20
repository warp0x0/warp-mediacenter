import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart';

import 'native_android_player.dart';

class PlaybackTrackInfo {
  final String id;
  final String title;
  final String? language;
  final String? codec;
  final String? channels;
  final int? channelCount;
  final int? sampleRate;
  final bool selected;
  final bool supported;
  final bool isExternal;
  final Object? raw;

  const PlaybackTrackInfo({
    required this.id,
    required this.title,
    this.language,
    this.codec,
    this.channels,
    this.channelCount,
    this.sampleRate,
    this.selected = false,
    this.supported = true,
    this.isExternal = false,
    this.raw,
  });

  bool get isAuto => id == 'auto';
  bool get isNone => id == 'no';
}

abstract class PlaybackBackend {
  bool get isNativeAndroid;
  bool get playing;
  Duration get position;
  Duration get duration;
  double get volume;
  bool get firstFrameRendered;
  String get currentAspectRatioMode;
  List<PlaybackTrackInfo> get currentAudioTracks;
  PlaybackTrackInfo? get currentSelectedAudioTrack;
  List<PlaybackTrackInfo> get currentSubtitleTracks;
  PlaybackTrackInfo? get currentSelectedSubtitleTrack;

  Stream<bool> get playingStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<double> get volumeStream;
  Stream<bool> get completedStream;
  Stream<bool> get firstFrameStream;
  Stream<List<PlaybackTrackInfo>> get audioTracksStream;
  Stream<PlaybackTrackInfo?> get selectedAudioTrackStream;
  Stream<List<PlaybackTrackInfo>> get subtitleTracksStream;
  Stream<PlaybackTrackInfo?> get selectedSubtitleTrackStream;

  Widget buildView({required Widget controlsOverlay});
  Future<void> open(String source, {Duration startPosition, bool autoplay});
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double value);
  Future<void> stop();
  Future<void> setSubtitleDelay(Duration delay);
  Future<void> setSubtitleTextSizeSp(double sizeSp);
  Future<void> setAudioAmplificationDb(double db);
  Future<void> setAudioPassthrough(bool enabled);
  Future<void> setDolbyMode(bool enabled);
  Future<void> setAspectRatioMode(String mode);
  Future<void> loadSubtitle({
    required String uri,
    String? title,
    String? language,
  });
  Future<void> selectAudioTrack(PlaybackTrackInfo track);
  Future<void> selectSubtitleTrack(PlaybackTrackInfo track);
  Future<void> refreshTracks();
  Future<void> dispose();
}

PlaybackBackend createPlaybackBackend() {
  if (Platform.isAndroid) return NativeAndroidPlaybackBackend();
  return MediaKitPlaybackBackend();
}

class MediaKitPlaybackBackend implements PlaybackBackend {
  final mk.Player player = mk.Player();
  late final VideoController controller = VideoController(player);
  String _aspectRatioMode = 'fit';

  @override
  bool get isNativeAndroid => false;

  @override
  bool get playing => player.state.playing;

  @override
  Duration get position => player.state.position;

  @override
  Duration get duration => player.state.duration;

  @override
  double get volume => player.state.volume;

  @override
  bool get firstFrameRendered => true;

  @override
  String get currentAspectRatioMode => _aspectRatioMode;

  @override
  List<PlaybackTrackInfo> get currentAudioTracks =>
      _mapAudioTracks(player.state.tracks.audio);

  @override
  PlaybackTrackInfo? get currentSelectedAudioTrack =>
      _mapAudioTrack(player.state.track.audio);

  @override
  List<PlaybackTrackInfo> get currentSubtitleTracks =>
      _mapSubtitleTracks(player.state.tracks.subtitle);

  @override
  PlaybackTrackInfo? get currentSelectedSubtitleTrack =>
      _mapSubtitleTrack(player.state.track.subtitle);

  @override
  Stream<bool> get playingStream => player.stream.playing;

  @override
  Stream<Duration> get positionStream => player.stream.position;

  @override
  Stream<Duration> get durationStream => player.stream.duration;

  @override
  Stream<double> get volumeStream => player.stream.volume;

  @override
  Stream<bool> get completedStream => player.stream.completed;

  @override
  Stream<bool> get firstFrameStream => Stream<bool>.value(true);

  @override
  Stream<List<PlaybackTrackInfo>> get audioTracksStream =>
      player.stream.tracks.map((tracks) => _mapAudioTracks(tracks.audio));

  @override
  Stream<PlaybackTrackInfo?> get selectedAudioTrackStream =>
      player.stream.track.map((track) => _mapAudioTrack(track.audio));

  @override
  Stream<List<PlaybackTrackInfo>> get subtitleTracksStream =>
      player.stream.tracks.map((tracks) => _mapSubtitleTracks(tracks.subtitle));

  @override
  Stream<PlaybackTrackInfo?> get selectedSubtitleTrackStream =>
      player.stream.track.map((track) => _mapSubtitleTrack(track.subtitle));

  @override
  Widget buildView({required Widget controlsOverlay}) => Video(
    controller: controller,
    controls: (_) => controlsOverlay,
    fit: BoxFit.contain,
    subtitleViewConfiguration: const SubtitleViewConfiguration(
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

  @override
  Future<void> open(
    String source, {
    Duration startPosition = Duration.zero,
    bool autoplay = true,
  }) async {
    await player.open(mk.Media(source), play: autoplay);
    if (startPosition > Duration.zero) await player.seek(startPosition);
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> setVolume(double value) =>
      player.setVolume(value.clamp(0.0, 100.0).toDouble());

  @override
  Future<void> stop() => player.stop();

  @override
  Future<void> setSubtitleDelay(Duration delay) => _setMpvProperty(
    'sub-delay',
    (delay.inMilliseconds / 1000).toStringAsFixed(2),
  );

  @override
  Future<void> setSubtitleTextSizeSp(double sizeSp) => _setMpvProperty(
    'sub-font-size',
    sizeSp.clamp(20.0, 100.0).round().toString(),
  );

  @override
  Future<void> setAudioAmplificationDb(double db) async {}

  @override
  Future<void> setAudioPassthrough(bool enabled) => _setMpvProperty(
    'audio-spdif',
    enabled ? 'ac3,dts,dts-hd,eac3,truehd' : '',
  );

  @override
  Future<void> setDolbyMode(bool enabled) =>
      _setMpvProperty('audio-channels', enabled ? 'auto' : 'stereo');

  @override
  Future<void> setAspectRatioMode(String mode) async {
    _aspectRatioMode = mode;
    final aspect = _fixedAspectRatio(mode);
    if (aspect != null) {
      await _setMpvProperty('video-aspect-override', aspect.toStringAsFixed(4));
      await _setMpvProperty('video-zoom', '0');
      return;
    }
    await _setMpvProperty('video-aspect-override', 'no');
    await _setMpvProperty('video-zoom', mode == 'zoom' ? '0.2' : '0');
  }

  @override
  Future<void> loadSubtitle({
    required String uri,
    String? title,
    String? language,
  }) async {
    final previousCount = player.state.tracks.subtitle
        .where((track) => track.id != 'auto' && track.id != 'no')
        .length;
    await player.setSubtitleTrack(
      mk.SubtitleTrack.uri(uri, title: title, language: language),
    );
    try {
      final tracks = await player.stream.tracks
          .firstWhere(
            (tracks) =>
                tracks.subtitle
                    .where((track) => track.id != 'auto' && track.id != 'no')
                    .length >
                previousCount,
          )
          .timeout(const Duration(seconds: 5));
      final external = tracks.subtitle
          .where((track) => track.id != 'auto' && track.id != 'no')
          .last;
      await player.setSubtitleTrack(external);
    } catch (_) {}
  }

  @override
  Future<void> selectAudioTrack(PlaybackTrackInfo track) async {
    final raw = track.raw;
    if (raw is mk.AudioTrack) await player.setAudioTrack(raw);
  }

  @override
  Future<void> selectSubtitleTrack(PlaybackTrackInfo track) async {
    final raw = track.raw;
    if (raw is mk.SubtitleTrack) await player.setSubtitleTrack(raw);
  }

  @override
  Future<void> refreshTracks() async {}

  @override
  Future<void> dispose() async {
    await player.stop();
    await player.dispose();
  }

  Future<void> _setMpvProperty(String property, String value) async {
    final platform = player.platform;
    if (platform == null) return;
    try {
      await (platform as dynamic).setProperty(property, value);
    } catch (_) {}
  }

  List<PlaybackTrackInfo> _mapAudioTracks(List<mk.AudioTrack> tracks) =>
      tracks.map(_mapAudioTrack).toList();

  PlaybackTrackInfo _mapAudioTrack(mk.AudioTrack track) => PlaybackTrackInfo(
    id: track.id,
    title: _audioTrackTitle(track),
    language: track.language,
    codec: track.codec,
    channels: track.channels,
    channelCount: track.channelscount,
    sampleRate: track.samplerate,
    raw: track,
  );

  List<PlaybackTrackInfo> _mapSubtitleTracks(List<mk.SubtitleTrack> tracks) =>
      tracks.map(_mapSubtitleTrack).toList();

  PlaybackTrackInfo _mapSubtitleTrack(mk.SubtitleTrack track) =>
      PlaybackTrackInfo(
        id: track.id,
        title: _subtitleTrackTitle(track),
        language: track.language,
        codec: track.codec,
        isExternal: track.uri,
        raw: track,
      );
}

class NativeAndroidPlaybackBackend implements PlaybackBackend {
  final NativeAndroidPlayerController controller =
      NativeAndroidPlayerController();
  final _status = StreamController<NativePlayerEvent>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration>.broadcast();
  final _volume = StreamController<double>.broadcast();
  final _completed = StreamController<bool>.broadcast();
  final _firstFrame = StreamController<bool>.broadcast();
  final _audioTracks = StreamController<List<PlaybackTrackInfo>>.broadcast();
  final _selectedAudioTrack = StreamController<PlaybackTrackInfo?>.broadcast();
  final _subtitleTracks = StreamController<List<PlaybackTrackInfo>>.broadcast();
  final _selectedSubtitleTrack =
      StreamController<PlaybackTrackInfo?>.broadcast();
  late final StreamSubscription<NativePlayerEvent> _events;
  NativePlayerEvent _latest = const NativePlayerEvent(
    type: 'status',
    state: 'idle',
    playing: false,
    positionMs: 0,
    durationMs: 0,
    bufferedPositionMs: 0,
    volume: 1,
  );
  List<PlaybackTrackInfo> _latestAudioTracks = const [];
  List<PlaybackTrackInfo> _latestSubtitleTracks = const [];
  PlaybackTrackInfo? _latestSelectedAudioTrack;
  PlaybackTrackInfo? _latestSelectedSubtitleTrack;
  bool _firstFrameRendered = false;
  String _aspectRatioMode = 'fit';

  NativeAndroidPlaybackBackend() {
    _events = controller.events.listen(_handleEvent, onError: _status.addError);
  }

  @override
  bool get isNativeAndroid => true;

  @override
  bool get playing => _latest.playing;

  @override
  Duration get position => Duration(milliseconds: _latest.positionMs);

  @override
  Duration get duration => Duration(milliseconds: _latest.durationMs);

  @override
  double get volume => (_latest.volume * 100).clamp(0.0, 100.0).toDouble();

  @override
  bool get firstFrameRendered => _firstFrameRendered;

  @override
  String get currentAspectRatioMode => _aspectRatioMode;

  @override
  List<PlaybackTrackInfo> get currentAudioTracks => _latestAudioTracks;

  @override
  PlaybackTrackInfo? get currentSelectedAudioTrack => _latestSelectedAudioTrack;

  @override
  List<PlaybackTrackInfo> get currentSubtitleTracks => _latestSubtitleTracks;

  @override
  PlaybackTrackInfo? get currentSelectedSubtitleTrack =>
      _latestSelectedSubtitleTrack;

  @override
  Stream<bool> get playingStream => _playing.stream;

  @override
  Stream<Duration> get positionStream => _position.stream;

  @override
  Stream<Duration> get durationStream => _duration.stream;

  @override
  Stream<double> get volumeStream => _volume.stream;

  @override
  Stream<bool> get completedStream => _completed.stream;

  @override
  Stream<bool> get firstFrameStream => _firstFrame.stream;

  @override
  Stream<List<PlaybackTrackInfo>> get audioTracksStream => _audioTracks.stream;

  @override
  Stream<PlaybackTrackInfo?> get selectedAudioTrackStream =>
      _selectedAudioTrack.stream;

  @override
  Stream<List<PlaybackTrackInfo>> get subtitleTracksStream =>
      _subtitleTracks.stream;

  @override
  Stream<PlaybackTrackInfo?> get selectedSubtitleTrackStream =>
      _selectedSubtitleTrack.stream;

  @override
  Widget buildView({required Widget controlsOverlay}) => Stack(
    fit: StackFit.expand,
    children: [
      NativeAndroidPlayerSurface(controller: controller),
      controlsOverlay,
    ],
  );

  @override
  Future<void> open(
    String source, {
    Duration startPosition = Duration.zero,
    bool autoplay = true,
  }) async {
    _firstFrameRendered = false;
    _firstFrame.add(false);
    await controller.setDataSource(
      source: source,
      startPosition: startPosition,
      autoplay: autoplay,
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await refreshTracks();
  }

  @override
  Future<void> play() => controller.play();

  @override
  Future<void> pause() => controller.pause();

  @override
  Future<void> seek(Duration position) => controller.seekTo(position);

  @override
  Future<void> setVolume(double value) =>
      controller.setVolume(value.clamp(0.0, 100.0).toDouble() / 100);

  @override
  Future<void> stop() => controller.stop();

  @override
  Future<void> setSubtitleDelay(Duration delay) =>
      controller.setSubtitleDelay(delay);

  @override
  Future<void> setSubtitleTextSizeSp(double sizeSp) =>
      controller.setSubtitleTextSizeSp(sizeSp);

  @override
  Future<void> setAudioAmplificationDb(double db) =>
      controller.setAudioBoostDb(db);

  @override
  Future<void> setAudioPassthrough(bool enabled) =>
      controller.setAudioPassthrough(enabled);

  @override
  Future<void> setDolbyMode(bool enabled) => controller.setDolbyMode(enabled);

  @override
  Future<void> setAspectRatioMode(String mode) async {
    _aspectRatioMode = mode;
    await controller.setAspectRatioMode(mode);
  }

  @override
  Future<void> loadSubtitle({
    required String uri,
    String? title,
    String? language,
  }) async {
    await controller.loadSubtitle(uri: uri, title: title, language: language);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await refreshTracks();
  }

  @override
  Future<void> selectAudioTrack(PlaybackTrackInfo track) =>
      controller.selectAudioTrack(track.id).then((_) => refreshTracks());

  @override
  Future<void> selectSubtitleTrack(PlaybackTrackInfo track) =>
      controller.selectSubtitleTrack(track.id).then((_) => refreshTracks());

  @override
  Future<void> refreshTracks() async {
    final event = await controller.getTracks();
    if (event != null) _handleEvent(event);
  }

  @override
  Future<void> dispose() async {
    await _events.cancel();
    await controller.dispose();
    await _status.close();
    await _playing.close();
    await _position.close();
    await _duration.close();
    await _volume.close();
    await _completed.close();
    await _firstFrame.close();
    await _audioTracks.close();
    await _selectedAudioTrack.close();
    await _subtitleTracks.close();
    await _selectedSubtitleTrack.close();
  }

  void _handleEvent(NativePlayerEvent event) {
    if (event.type == 'tracks') {
      _latestAudioTracks = event.audioTracks.map(_mapNativeTrack).toList();
      _latestSubtitleTracks = event.subtitleTracks
          .map(_mapNativeTrack)
          .toList();
      _latestSelectedAudioTrack = _selectedTrack(
        _latestAudioTracks,
        event.selectedAudioTrackId,
      );
      _latestSelectedSubtitleTrack = _selectedTrack(
        _latestSubtitleTracks,
        event.selectedSubtitleTrackId,
      );
      _audioTracks.add(_latestAudioTracks);
      _subtitleTracks.add(_latestSubtitleTracks);
      _selectedAudioTrack.add(_latestSelectedAudioTrack);
      _selectedSubtitleTrack.add(_latestSelectedSubtitleTrack);
      return;
    }
    if (event.type == 'firstFrame') {
      _firstFrameRendered = true;
      _firstFrame.add(true);
      return;
    }
    if (event.type == 'completed') {
      _completed.add(true);
      return;
    }
    _latest = event;
    _status.add(event);
    _playing.add(event.playing);
    _position.add(Duration(milliseconds: event.positionMs));
    _duration.add(Duration(milliseconds: event.durationMs));
    _volume.add((event.volume * 100).clamp(0.0, 100.0).toDouble());
  }

  PlaybackTrackInfo? _selectedTrack(
    List<PlaybackTrackInfo> tracks,
    String? id,
  ) {
    if (id == null) return null;
    for (final track in tracks) {
      if (track.id == id) return track;
    }
    return null;
  }

  PlaybackTrackInfo _mapNativeTrack(NativePlayerTrack track) =>
      PlaybackTrackInfo(
        id: track.id,
        title: track.title,
        language: track.language,
        codec: track.codec ?? track.mimeType,
        channelCount: track.channelCount,
        sampleRate: track.sampleRate,
        selected: track.selected,
        supported: track.supported,
      );
}

String _audioTrackTitle(mk.AudioTrack track) {
  if (track.id == 'auto') return 'Auto';
  if (track.id == 'no') return 'Disabled';
  final title = track.title?.trim();
  if (title != null && title.isNotEmpty) return title;
  final language = track.language?.trim();
  if (language != null && language.isNotEmpty) return language.toUpperCase();
  return 'Audio ${track.id}';
}

String _subtitleTrackTitle(mk.SubtitleTrack track) {
  if (track.id == 'auto') return 'Auto';
  if (track.id == 'no') return 'Disabled';
  final title = track.title?.trim();
  if (title != null && title.isNotEmpty) return title;
  final language = track.language?.trim();
  if (language != null && language.isNotEmpty) return language.toUpperCase();
  return 'Subtitle ${track.id}';
}

double? _fixedAspectRatio(String mode) => switch (mode) {
  '4:3' => 4 / 3,
  '14:9' => 14 / 9,
  '16:9' => 16 / 9,
  '18:9' => 18 / 9,
  '21:9' => 21 / 9,
  '2.35:1' => 2.35,
  '2.39:1' => 2.39,
  _ => null,
};
