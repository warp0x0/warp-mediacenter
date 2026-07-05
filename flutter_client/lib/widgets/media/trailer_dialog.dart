import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Video;
import '../../theme/warp_theme.dart';
import '../../theme/warp_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TrailerDialog — plays a YouTube trailer URL via media_kit (libmpv)
// Falls back to in-app info if extraction fails.
// ─────────────────────────────────────────────────────────────────────────────

class TrailerDialog extends ConsumerStatefulWidget {
  final String trailerUrl;
  final String title;

  const TrailerDialog({
    super.key,
    required this.trailerUrl,
    required this.title,
  });

  @override
  ConsumerState<TrailerDialog> createState() => _TrailerDialogState();
}

class _TrailerDialogState extends ConsumerState<TrailerDialog> {
  late final Player _player;
  late final VideoController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _resolveAndPlay();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _resolveAndPlay() async {
    try {
      final url = await _extractDirectUrl(widget.trailerUrl);
      await _player.open(Media(url));
      if (mounted) { setState(() => _loading = false); }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load trailer. ($e)';
        });
      }
    }
  }

  Future<String> _extractDirectUrl(String youtubeUrl) async {
    // youtube_explode_dart: extract a direct streamable URL
    final yt = YoutubeExplode();
    try {
      final videoId = VideoId(youtubeUrl);
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      // Prefer muxed (video+audio), highest quality
      final muxed = manifest.muxed;
      if (muxed.isNotEmpty) {
        final best = muxed.withHighestBitrate();
        return best.url.toString();
      }
      // Fall back to best video-only stream
      final video = manifest.videoOnly;
      if (video.isNotEmpty) {
        return video.withHighestBitrate().url.toString();
      }
      throw Exception('No playable stream found');
    } finally {
      yt.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final w = (size.width * 0.90).clamp(480.0, 1100.0);
    final h = w * 9 / 16 + 56; // 16:9 + header

    return Material(
      color: Colors.black.withAlpha(200),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),
        },
        child: DpadRegion(
          memoryKey: 'modal-trailer',
          horizontalEdge: DpadEdgeBehavior.stop,
          verticalEdge: DpadEdgeBehavior.stop,
          child: Center(
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(20)),
          ),
          child: Column(
            children: [
              // Header
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(color: Colors.white, fontSize: t.fontBody, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DpadFocusable(
                      autofocus: true,
                      entry: true,
                      onSelect: () => Navigator.of(context).pop(),
                      builder: (context, state, child) => Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: state.focused
                              ? [BoxShadow(color: WarpColors.accent.withAlpha(140), blurRadius: 18, spreadRadius: 2)]
                              : null,
                        ),
                        // Selection is handled by the outer DpadFocusable's
                        // tapToSelect — plain Icon so it isn't a second tap target.
                        padding: const EdgeInsets.all(12),
                        child: const Icon(Icons.close, color: Colors.white70),
                      ),
                      child: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // Video area
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0DB2E2), strokeWidth: 2))
                      : _error != null
                          ? _ErrorBody(message: _error!, url: widget.trailerUrl, t: t)
                          : Video(controller: _controller),
                ),
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final String url;
  final WarpTokens t;

  const _ErrorBody({required this.message, required this.url, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_outline, color: Colors.white38, size: 52),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.white54, fontSize: t.fontSubtitle), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            'Trailer URL:',
            style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
          ),
          const SizedBox(height: 4),
          SelectableText(
            url,
            style: TextStyle(color: const Color(0xFF0DB2E2), fontSize: t.fontSubtitle),
          ),
        ],
      ),
    );
  }
}
