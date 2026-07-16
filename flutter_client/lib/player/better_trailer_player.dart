import 'dart:async';

import 'package:better_player_enhanced/better_player.dart';
import 'package:flutter/material.dart';

/// Minimal BetterPlayer/ExoPlayer wrapper for trailer A/B testing.
///
/// The package's Android backend currently renders through Flutter textures;
/// it does not expose a public SurfaceView switch in 1.0.4.
class BetterTrailerPlayerController {
  late final BetterPlayerController _controller;
  double _volume = 1.0;

  BetterTrailerPlayerController({void Function(String message)? onError}) {
    _controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        autoDispose: false,
        allowedScreenSleep: false,
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        handleLifecycle: true,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false,
          showControlsOnInitialize: false,
          enablePlayPause: false,
          enableProgressBar: false,
          enableProgressText: false,
          enableSkips: false,
          enableMute: false,
          enableFullscreen: false,
          enableOverflowMenu: false,
          enablePlaybackSpeed: false,
          enableQualities: false,
          enableSubtitles: false,
          enableAudioTracks: false,
          enablePip: false,
          backgroundColor: Colors.black,
        ),
        eventListener: (event) {
          if (event.betterPlayerEventType != BetterPlayerEventType.exception) {
            return;
          }
          final message = event.parameters?['exception']?.toString();
          if (message != null && message.isNotEmpty) onError?.call(message);
        },
      ),
    );
  }

  BetterPlayerController get controller => _controller;

  Future<void> load(String url) async {
    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      videoFormat: BetterPlayerVideoFormat.other,
      videoExtension: 'mp4',
      useAsmsAudioTracks: false,
      useAsmsSubtitles: false,
      useAsmsTracks: false,
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        minBufferMs: 15000,
        maxBufferMs: 50000,
        bufferForPlaybackMs: 1500,
        bufferForPlaybackAfterRebufferMs: 2500,
      ),
    );
    await _controller.setupDataSource(dataSource);
    await _controller.setVolume(_volume);
    await _controller.play();
  }

  Future<void> togglePlayPause() async {
    final playing = _controller.isPlaying() ?? false;
    if (playing) {
      await _controller.pause();
    } else {
      await _controller.play();
    }
  }

  Future<void> seekBy(Duration delta) async {
    final value = _controller.videoPlayerController?.value;
    final current = value?.position ?? Duration.zero;
    final duration = value?.duration;
    var next = current + delta;
    if (next.isNegative) next = Duration.zero;
    if (duration != null && next > duration) next = duration;
    await _controller.seekTo(next);
  }

  Future<void> adjustVolume(double delta) async {
    _volume = (_volume + delta).clamp(0.0, 1.0);
    await _controller.setVolume(_volume);
  }

  void dispose() {
    _controller.dispose(forceDispose: true);
  }
}

class BetterTrailerPlayerSurface extends StatelessWidget {
  final BetterTrailerPlayerController controller;

  const BetterTrailerPlayerSurface({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: BetterPlayer(controller: controller.controller),
    );
  }
}
