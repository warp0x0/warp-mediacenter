import 'package:flutter/widgets.dart';

/// Playback lifecycle state, backend-agnostic.
enum WarpPlaybackState { idle, buffering, ready, ended, error }

/// Periodic position/duration tick.
class WarpPositionUpdate {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  const WarpPositionUpdate({
    required this.position,
    required this.bufferedPosition,
    required this.duration,
  });
}

/// Decoded video frame dimensions, for aspect-ratio-correct surface sizing.
class WarpVideoSize {
  final int width;
  final int height;
  final int rotationDegrees;

  const WarpVideoSize({
    required this.width,
    required this.height,
    this.rotationDegrees = 0,
  });
}

class WarpPlayerError {
  final String code;
  final String message;
  final bool isRecoverable;

  const WarpPlayerError({
    required this.code,
    required this.message,
    this.isRecoverable = false,
  });
}

class WarpAudioTrack {
  final String id;
  final String? language;
  final String? label;
  final String? codec;
  final int? channels;
  final int? bitrate;
  final bool selected;

  const WarpAudioTrack({
    required this.id,
    this.language,
    this.label,
    this.codec,
    this.channels,
    this.bitrate,
    this.selected = false,
  });
}

class WarpTextTrack {
  final String id;
  final String? language;
  final String? label;
  final bool isExternal;
  final bool selected;

  const WarpTextTrack({
    required this.id,
    this.language,
    this.label,
    this.isExternal = false,
    this.selected = false,
  });
}

class WarpTrackList {
  final List<WarpAudioTrack> audio;
  final List<WarpTextTrack> text;

  const WarpTrackList({this.audio = const [], this.text = const []});
}

/// A playable source: either a single muxed URL, or a separate video-only +
/// audio-only pair (YouTube/demuxed — paired via native MergingMediaSource
/// on the native backend once M4 lands; see [WarpDemuxedSource]).
sealed class WarpDataSource {
  const WarpDataSource();
}

class WarpMuxedSource extends WarpDataSource {
  final String url;
  final Map<String, String>? headers;

  const WarpMuxedSource(this.url, {this.headers});
}

class WarpDemuxedSource extends WarpDataSource {
  final String videoUrl;
  final String audioUrl;
  final Map<String, String>? headers;

  const WarpDemuxedSource(this.videoUrl, this.audioUrl, {this.headers});
}

/// Backend-agnostic playback interface. Two production implementations:
/// [WarpNativeAndroidBackend] (Android TV only — Media3/ExoPlayer via a
/// native SurfaceView, bypassing Flutter's compositor) and
/// [WarpMediaKitBackend] (desktop/non-TV-Android — media_kit/libmpv,
/// extracted from the logic that lives in playback_page.dart today).
/// [WarpBetterPlayerBackend] adapts the existing better_player_enhanced
/// trailer path for desktop/non-TV-Android trailers (M7).
///
/// Selected at runtime via [createPlaybackBackend] — see backend_factory.dart.
abstract class WarpPlaybackBackend {
  Stream<WarpPlaybackState> get stateStream;

  /// Whether the backend is actually advancing playback right now — distinct
  /// from [stateStream], which reports readiness (buffering/ready/etc.) but
  /// not play/pause intent. Drives the play/pause icon and the
  /// pause-while-a-dialog-is-open/resume-after pattern used when opening
  /// SubtitleDialog or the audio-tracks dialog.
  Stream<bool> get playingStream;
  Stream<WarpPositionUpdate> get positionStream;
  Stream<WarpVideoSize> get videoSizeStream;
  Stream<WarpPlayerError> get errorStream;
  Stream<void> get completedStream;
  Stream<WarpTrackList> get tracksStream;

  /// Whether [setDataSource] accepts a [WarpDemuxedSource] (video-only +
  /// audio-only pair via native MergingMediaSource). True only on
  /// [WarpNativeAndroidBackend] — callers (youtube_stream_selector.dart via
  /// TrailerDialog) must check this before selecting a demuxed pair, since
  /// [WarpBetterPlayerBackend] and [WarpMediaKitBackend] throw
  /// [UnimplementedError] for demuxed sources rather than silently
  /// degrading.
  bool get supportsDemuxedSource;

  /// Whether this backend can drive AC3/DTS/etc. bitstream passthrough.
  /// False on the native backend — MediaCodec negotiates passthrough
  /// automatically with no app-level toggle; true on media_kit (mpv
  /// `audio-spdif` property). Drives whether PlaybackPage shows the
  /// passthrough toggle at all (hidden, not disabled, when unsupported).
  bool get supportsAudioPassthrough;

  /// Whether [setVolume] accepts values above 1.0 (up to 2.0) for gain
  /// amplification. False on the native backend — ExoPlayer's volume is
  /// hard-capped at 1.0 with no software gain stage; true on media_kit.
  bool get supportsAudioAmplificationBeyond100;

  Future<void> setDataSource(WarpDataSource source, {Duration? startPosition});
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);

  /// 0.0 (silent) to 1.0 (100%, normal), extending to 2.0 (200%) only where
  /// [supportsAudioAmplificationBeyond100] is true — backends clamp to
  /// their own supported range internally.
  Future<void> setVolume(double volume);
  Future<void> setPlaybackSpeed(double speed);

  Future<WarpTrackList> getTracks();
  Future<void> selectAudioTrack(String trackId);

  /// Bitstream passthrough (AC3/DTS/etc.). No-op where
  /// [supportsAudioPassthrough] is false — callers must hide, not just
  /// disable, the toggle in that case (a no-op control that looks live is
  /// worse than no control).
  Future<void> setAudioPassthrough(bool enabled);

  /// Prefer surround channel layout when available. No-op where
  /// [supportsAudioPassthrough] is false (reuses the same capability flag —
  /// both are mpv-specific `audio-*` property pokes with no MediaCodec
  /// equivalent).
  Future<void> setDolbyMode(bool enabled);

  /// Resolves once the added subtitle track is actually selectable — not
  /// merely "added" — so callers never need their own poll-for-registration
  /// workaround (subtitle_dialog.dart currently has to do this by hand for
  /// mpv's async external-track registration; this supersedes that once
  /// SubtitleDialog is wired onto this abstraction in M6/M7).
  Future<String> addExternalSubtitle(String uri, {String? title, String? language});
  Future<void> selectSubtitleTrack(String? trackId);
  Future<void> setSubtitleDelay(Duration delay);

  /// The raw, unfocusable video surface only — no controls. Callers layer
  /// their own D-pad-navigable overlay controls on top in a Stack, mirroring
  /// today's playback_page.dart pattern (bare video widget as the Stack's
  /// first child; every interactive control is a separate DpadFocusable
  /// layered above it — never the surface itself).
  Widget buildSurface();

  Future<void> dispose();
}
