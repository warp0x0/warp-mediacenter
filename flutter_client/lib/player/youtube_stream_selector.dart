import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Video;

import 'backend/warp_playback_backend.dart';

/// Picks the best playable stream(s) from a YouTube [StreamManifest].
///
/// Prefers a demuxed video-only + audio-only pair when the video-only
/// stream's bitrate beats the best available muxed stream — YouTube's
/// demuxed streams go up to far higher resolution/bitrate than muxed
/// progressive streams (which YouTube caps around 360p-720p) — but only when
/// [allowDemuxed] is true. Callers (TrailerDialog) must pass
/// `backend.supportsDemuxedSource` here: [WarpBetterPlayerBackend] (desktop/
/// non-TV-Android trailers) and [WarpMediaKitBackend] throw
/// [UnimplementedError] for a [WarpDemuxedSource], so selecting one for a
/// backend that can't play it would break trailer playback outright rather
/// than gracefully falling back. Falls back to the best muxed stream
/// whenever demuxed isn't selected/available, and throws only when neither
/// is available — the same failure mode trailer_dialog.dart's
/// `_extractStreams` had before this selector existed, just with a real
/// demuxed attempt made first (when allowed) instead of giving up
/// immediately.
WarpDataSource selectBestStream(
  StreamManifest manifest, {
  required bool allowDemuxed,
}) {
  final videoOnly = manifest.videoOnly;
  final audioOnly = manifest.audioOnly;
  final muxed = manifest.muxed;

  final bestVideoOnly = videoOnly.isEmpty ? null : videoOnly.withHighestBitrate();
  final bestAudioOnly = audioOnly.isEmpty ? null : audioOnly.withHighestBitrate();
  final bestMuxed = muxed.isEmpty ? null : muxed.withHighestBitrate();

  if (allowDemuxed && bestVideoOnly != null && bestAudioOnly != null) {
    final demuxedBeatsMuxed =
        bestMuxed == null ||
        bestVideoOnly.bitrate.bitsPerSecond > bestMuxed.bitrate.bitsPerSecond;
    if (demuxedBeatsMuxed) {
      return WarpDemuxedSource(
        _withRateBypass(bestVideoOnly.url.toString()),
        _withRateBypass(bestAudioOnly.url.toString()),
      );
    }
  }
  if (bestMuxed != null) {
    return WarpMuxedSource(_withRateBypass(bestMuxed.url.toString()));
  }
  throw Exception('No playable stream found in manifest');
}

/// googlevideo.com URLs fetched via non-browser YouTube clients (e.g. the
/// `androidVr` client this app falls back to) omit `ratebypass=yes`, which
/// causes YouTube's CDN to server-side throttle delivery in bursts with
/// enforced dead gaps between them rather than a steady stream — observed
/// on-device as playback reliably freezing ~10-15s in on every trailer
/// (first burst exhausted, then a ~20s dead stall waiting for the next one).
/// `ratebypass` is not part of the URL's signed `sparams`/`lsparams` set, so
/// appending it doesn't invalidate the signature — this is the standard
/// fix used throughout the yt-dlp/youtube-dl ecosystem for the same issue.
String _withRateBypass(String url) {
  final uri = Uri.parse(url);
  if (uri.queryParameters['ratebypass'] == 'yes') return url;
  return uri.replace(
    queryParameters: {...uri.queryParameters, 'ratebypass': 'yes'},
  ).toString();
}
