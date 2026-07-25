import 'dart:async';
import 'dart:io';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/warp_theme.dart';
import '../theme/warp_tokens.dart';
import '../widgets/shared/dpad_controls.dart';
import '../widgets/shared/warp_accent_button.dart';
import 'native_android_player.dart';

class NativePlayerSmokeTestPage extends ConsumerStatefulWidget {
  const NativePlayerSmokeTestPage({super.key});

  @override
  ConsumerState<NativePlayerSmokeTestPage> createState() =>
      _NativePlayerSmokeTestPageState();
}

class _NativePlayerSmokeTestPageState
    extends ConsumerState<NativePlayerSmokeTestPage> {
  static const _defaultUrl =
      'https://samplelib.com/mp4/sample-30s.mp4';

  late final NativeAndroidPlayerController _player;
  late final TextEditingController _urlCtrl;
  final _urlFieldFocus = FocusNode(debugLabel: 'NativeSmokeUrlField');
  final _urlWrapperFocus = FocusNode(debugLabel: 'NativeSmokeUrlWrapper');
  StreamSubscription<NativePlayerEvent>? _eventsSub;

  NativePlayerEvent? _lastEvent;
  String? _error;
  bool _controlsVisible = true;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _player = NativeAndroidPlayerController();
    _urlCtrl = TextEditingController(text: _defaultUrl);
    _eventsSub = _player.events.listen(
      (event) {
        if (!mounted) return;
        setState(() {
          _lastEvent = event;
          if (event.type == 'error') {
            _error = '${event.code ?? 'ERROR'}: ${event.message ?? 'Unknown'}';
          }
        });
      },
      onError: (error) {
        if (mounted) setState(() => _error = error.toString());
      },
    );
    unawaited(_loadWhenReady());
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _urlCtrl.dispose();
    _urlFieldFocus.dispose();
    _urlWrapperFocus.dispose();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _loadWhenReady() async {
    await _player.ready;
    if (!mounted) return;
    await _loadUrl();
  }

  Future<void> _loadUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() => _error = null);
    try {
      await _player.setDataSource(source: url, autoplay: true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  void _togglePlayPause() {
    final playing = _lastEvent?.playing ?? false;
    unawaited(playing ? _player.pause() : _player.play());
  }

  void _seek(int seconds) {
    unawaited(_player.seekBy(Duration(seconds: seconds)));
  }

  void _changeVolume(double delta) {
    _volume = (_volume + delta).clamp(0.0, 1.0);
    unawaited(_player.setVolume(_volume));
    if (mounted) setState(() {});
  }

  void _handleBack() {
    if (_controlsVisible) {
      setState(() => _controlsVisible = false);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final event = _lastEvent;
    final position = event?.positionMs ?? 0;
    final duration = event?.durationMs ?? 0;
    final progress = duration > 0 ? position / duration : 0.0;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handleBack,
        const SingleActivator(LogicalKeyboardKey.backspace): _handleBack,
        const SingleActivator(LogicalKeyboardKey.goBack): _handleBack,
        const SingleActivator(LogicalKeyboardKey.browserBack): _handleBack,
        const SingleActivator(LogicalKeyboardKey.mediaPlayPause):
            _togglePlayPause,
        const SingleActivator(LogicalKeyboardKey.mediaRewind): () => _seek(-10),
        const SingleActivator(LogicalKeyboardKey.mediaFastForward): () =>
            _seek(10),
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            NativeAndroidPlayerSurface(controller: _player),
            if (!Platform.isAndroid)
              const Center(
                child: Text(
                  'Native player smoke test is Android-only.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _controlsVisible = true),
              ),
            ),
            AnimatedOpacity(
              opacity: _controlsVisible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: _buildOverlay(t, event, progress),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(
    WarpTokens t,
    NativePlayerEvent? event,
    double progress,
  ) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE6000000), Colors.transparent, Color(0xE6000000)],
          stops: [0, 0.48, 1],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.science_outlined, color: WarpColors.accent),
                  const SizedBox(width: 10),
                  Text(
                    'Native Player Smoke Test',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: t.fontSection,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Back hides controls, then exits',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: t.fontSubtitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: WarpDpadTextField(
                      controller: _urlCtrl,
                      fieldFocusNode: _urlFieldFocus,
                      wrapperFocusNode: _urlWrapperFocus,
                      tokens: t,
                      moveCursorToEndOnEnter: true,
                      onSubmitted: (_) => _loadUrl(),
                      decoration: const InputDecoration(
                        hintText: 'Enter HTTP, file://, or backend stream URL',
                        filled: true,
                        fillColor: Color(0xCC111827),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  WarpAccentButton(
                    label: 'Load URL',
                    icon: Icons.play_circle_outline,
                    accentColor: WarpColors.accent,
                    fontSize: t.fontSubtitle,
                    paddingHorizontal: 18,
                    paddingVertical: 12,
                    onSelect: _loadUrl,
                  ),
                  const SizedBox(width: 12),
                  WarpAccentButton(
                    label: 'Exit',
                    icon: Icons.close,
                    accentColor: WarpColors.danger,
                    fontSize: t.fontSubtitle,
                    paddingHorizontal: 18,
                    paddingVertical: 12,
                    onSelect: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
              ],
              const Spacer(),
              _SmokeStatusBar(
                event: event,
                progress: progress,
                volume: _volume,
                onPlayPause: _togglePlayPause,
                onSeekBack: () => _seek(-10),
                onSeekForward: () => _seek(10),
                onVolumeDown: () => _changeVolume(-0.1),
                onVolumeUp: () => _changeVolume(0.1),
                t: t,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmokeStatusBar extends StatelessWidget {
  final NativePlayerEvent? event;
  final double progress;
  final double volume;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekBack;
  final VoidCallback onSeekForward;
  final VoidCallback onVolumeDown;
  final VoidCallback onVolumeUp;
  final WarpTokens t;

  const _SmokeStatusBar({
    required this.event,
    required this.progress,
    required this.volume,
    required this.onPlayPause,
    required this.onSeekBack,
    required this.onSeekForward,
    required this.onVolumeDown,
    required this.onVolumeUp,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final playing = event?.playing ?? false;
    final state = event?.state.isNotEmpty == true ? event!.state : 'waiting';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xD90B1118),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                formatNativePlayerTime(event?.positionMs ?? 0),
                style: const TextStyle(color: Colors.white70),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    color: WarpColors.accent,
                    backgroundColor: Colors.white.withAlpha(24),
                  ),
                ),
              ),
              Text(
                formatNativePlayerTime(event?.durationMs ?? 0),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DpadRegion(
            memoryKey: 'native-smoke-controls',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                WarpAccentButton(
                  label: '-10s',
                  icon: Icons.replay_10,
                  accentColor: WarpColors.accent,
                  fontSize: t.fontSubtitle,
                  paddingHorizontal: 14,
                  paddingVertical: 10,
                  onSelect: onSeekBack,
                ),
                WarpAccentButton(
                  label: playing ? 'Pause' : 'Play',
                  icon: playing ? Icons.pause : Icons.play_arrow,
                  accentColor: WarpColors.accent,
                  fontSize: t.fontSubtitle,
                  paddingHorizontal: 14,
                  paddingVertical: 10,
                  autofocus: true,
                  onSelect: onPlayPause,
                ),
                WarpAccentButton(
                  label: '+10s',
                  icon: Icons.forward_10,
                  accentColor: WarpColors.accent,
                  fontSize: t.fontSubtitle,
                  paddingHorizontal: 14,
                  paddingVertical: 10,
                  onSelect: onSeekForward,
                ),
                WarpAccentButton(
                  label: 'Vol -',
                  icon: Icons.volume_down,
                  accentColor: WarpColors.accent,
                  fontSize: t.fontSubtitle,
                  paddingHorizontal: 14,
                  paddingVertical: 10,
                  onSelect: onVolumeDown,
                ),
                WarpAccentButton(
                  label: 'Vol +',
                  icon: Icons.volume_up,
                  accentColor: WarpColors.accent,
                  fontSize: t.fontSubtitle,
                  paddingHorizontal: 14,
                  paddingVertical: 10,
                  onSelect: onVolumeUp,
                ),
                Text(
                  'State: $state  •  Volume: ${(volume * 100).round()}%'
                  '${event?.width != null ? '  •  ${event!.width}x${event!.height}' : ''}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: t.fontSubtitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
