import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../player/backend/native_android_backend.dart';
import '../../player/backend/warp_playback_backend.dart';

/// Public-domain test clip, used only so this smoke test has a known-good
/// muxed H.264 URL out of the box. Pass a real backend/YouTube URL via the
/// [testUrl] param for a realistic side-by-side smoothness comparison.
const String _defaultTestUrl = 'https://samplelib.com/mp4/sample-30s.mp4';

/// M1/M2/M3 milestone: native rendering + full playback-contract smoke test,
/// now exercised through the WarpPlaybackBackend abstraction (M3) instead of
/// talking to the platform channels directly — this is how the abstraction
/// itself gets validated on-device before anything production (PlaybackPage/
/// TrailerDialog) is wired onto it in M6/M7. Deliberately minimal and
/// temporary (no scrobble/session wiring). See PLAYER_PROTOTYPE.md and the
/// native player implementation plan.
class NativePlayerSmokeTestPage extends StatefulWidget {
  final String? testUrl;

  const NativePlayerSmokeTestPage({super.key, this.testUrl});

  @override
  State<NativePlayerSmokeTestPage> createState() =>
      _NativePlayerSmokeTestPageState();
}

class _NativePlayerSmokeTestPageState
    extends State<NativePlayerSmokeTestPage> {
  // Direct instantiation, not createPlaybackBackend() — this page's whole
  // purpose is to exercise the native backend specifically on real Android
  // TV hardware; the factory's platform/density branch is trivial,
  // deterministic logic that doesn't need on-device verification.
  late final WarpPlaybackBackend _backend = WarpNativeAndroidBackend();

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  final _rewindFocus = FocusNode(debugLabel: 'DebugRewind');
  final _playPauseFocus = FocusNode(debugLabel: 'DebugPlayPause');
  final _forwardFocus = FocusNode(debugLabel: 'DebugForward');

  WarpPlaybackState _state = WarpPlaybackState.idle;
  bool _initialLoadComplete = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _videoWidth = 0;
  int _videoHeight = 0;
  int _audioTrackCount = 0;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _subscriptions.addAll([
      _backend.stateStream.listen(_onState),
      _backend.positionStream.listen(_onPosition),
      _backend.videoSizeStream.listen(_onVideoSize),
      _backend.tracksStream.listen(_onTracks),
      _backend.completedStream.listen((_) {
        if (mounted) setState(() => _playing = false);
      }),
      _backend.errorStream.listen((error) {
        if (mounted) {
          setState(() => _lastError = '${error.code}: ${error.message}');
        }
      }),
    ]);
    unawaited(_start());
  }

  Future<void> _start() async {
    final url = widget.testUrl ?? _defaultTestUrl;
    try {
      await _backend.setDataSource(WarpMuxedSource(url));
      await _backend.play();
      if (mounted) setState(() => _playing = true);
    } catch (e) {
      if (mounted) setState(() => _lastError = 'setDataSource failed: $e');
    }
  }

  void _onState(WarpPlaybackState state) {
    if (!mounted) return;
    final wasLoading = !_initialLoadComplete;
    setState(() {
      _state = state;
      if (state == WarpPlaybackState.ready) _initialLoadComplete = true;
      if (state == WarpPlaybackState.ended) _playing = false;
    });
    // The play/pause/seek controls only enter the widget tree once loading
    // completes (see the loading-scrim gate in build()). `autofocus`/`entry`
    // on a DpadFocusable only reliably grabs focus on true initial mount —
    // the dpad package's own focus-restoration logic is tuned to route/
    // dialog transitions, not an in-place setState that reveals a
    // previously-absent focusable within an already-mounted page. Request
    // focus explicitly the moment the controls actually appear, matching
    // the pattern already used for this in playback_page.dart/
    // trailer_dialog.dart (e.g. _recoverPlaybackFocus).
    if (wasLoading && _initialLoadComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Dpad.of(context).requestFocus(_playPauseFocus);
      });
    }
  }

  void _onPosition(WarpPositionUpdate update) {
    if (!mounted) return;
    setState(() {
      _position = update.position;
      _duration = update.duration;
    });
  }

  void _onVideoSize(WarpVideoSize size) {
    if (!mounted) return;
    setState(() {
      _videoWidth = size.width;
      _videoHeight = size.height;
    });
  }

  void _onTracks(WarpTrackList tracks) {
    if (!mounted) return;
    setState(() => _audioTrackCount = tracks.audio.length);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    unawaited(_backend.dispose());
    _rewindFocus.dispose();
    _playPauseFocus.dispose();
    _forwardFocus.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final nowPlaying = !_playing;
    setState(() => _playing = nowPlaying);
    unawaited(nowPlaying ? _backend.play() : _backend.pause());
  }

  void _seekBy(int seconds) {
    final target = _position + Duration(seconds: seconds);
    final clamped = target.isNegative
        ? Duration.zero
        : (_duration > Duration.zero && target > _duration ? _duration : target);
    unawaited(_backend.seekTo(clamped));
  }

  void _exit() {
    if (context.canPop()) context.pop();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // The app's root D-pad wrapper deliberately disables Back — every page
    // owns its own Back/Escape handling (see PLAYER_PROTOTYPE.md and the
    // pattern in playback_page.dart / trailer_dialog.dart). This is a
    // temporary M1/M2/M3 debug page, so it just exits on any Back-shaped key.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _exit,
        const SingleActivator(LogicalKeyboardKey.backspace): _exit,
        const SingleActivator(LogicalKeyboardKey.goBack): _exit,
        const SingleActivator(LogicalKeyboardKey.browserBack): _exit,
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // This bare surface is NOT wrapped in Focus/DpadFocusable —
            // mirrors playback_page.dart's pattern where only the overlay
            // controls below are focusable, never the video surface itself.
            _backend.buildSurface(),
            // Until the first `ready` state, the native surface has nothing
            // decoded yet — an empty/transparent SurfaceView region during
            // that gap can show through to whatever's behind it at the
            // hardware compositor level rather than our own black
            // background. An opaque Flutter-side scrim (drawn above the
            // surface in this Stack, which Hybrid Composition guarantees
            // renders on top regardless) covers that gap reliably;
            // debug text/controls stay hidden until real content is about
            // to appear, matching what a production loading state will
            // need too (large movies will buffer far longer than this 30s
            // test clip).
            if (!_initialLoadComplete)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0DB2E2)),
                        SizedBox(height: 16),
                        Text(
                          'Loading video…',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_initialLoadComplete) ...[
              Positioned(
                top: 24,
                left: 24,
                child: Text(
                  'WarpPlayer smoke test (via WarpPlaybackBackend) — '
                  'state: ${_state.name} — '
                  '${_videoWidth}x$_videoHeight — audio tracks: $_audioTrackCount'
                  '${_lastError != null ? '\nerror: $_lastError' : ''}'
                  '\n(Back to exit)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DebugButton(
                          label: '-10s',
                          focusNode: _rewindFocus,
                          onSelect: () => _seekBy(-10),
                        ),
                        const SizedBox(width: 16),
                        _DebugButton(
                          label: _playing ? 'Pause' : 'Play',
                          focusNode: _playPauseFocus,
                          autofocus: true,
                          entry: true,
                          onSelect: _togglePlayPause,
                        ),
                        const SizedBox(width: 16),
                        _DebugButton(
                          label: '+10s',
                          focusNode: _forwardFocus,
                          onSelect: () => _seekBy(10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String label;
  final FocusNode focusNode;
  final VoidCallback onSelect;
  final bool autofocus;
  final bool entry;

  const _DebugButton({
    required this.label,
    required this.focusNode,
    required this.onSelect,
    this.autofocus = false,
    this.entry = false,
  });

  @override
  Widget build(BuildContext context) => DpadFocusable(
    focusNode: focusNode,
    autofocus: autofocus,
    entry: entry,
    onSelect: onSelect,
    tapToSelect: false,
    builder: (context, state, child) => AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: state.focused ? const Color(0xFF0DB2E2) : Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: state.focused ? Colors.white : Colors.white24,
          width: 2,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}
