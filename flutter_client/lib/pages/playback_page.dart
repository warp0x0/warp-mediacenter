import 'dart:async';
import 'dart:io';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import '../api/api_client.dart';
import '../player/playback_backend.dart';
import '../providers/detail_provider.dart';
import '../theme/warp_tokens.dart';
import '../widgets/media/subtitle_dialog.dart';
import '../widgets/shared/tv_modal_chrome_scale.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PlaybackPage — full-screen video player
//
// Receives via go_router extra (Map<String, dynamic>):
//   source     String   — stream or local file URL
//   title      String?  — display title
//   mediaType  String?  — 'movie' | 'show'
//   tmdbId     String?  — for scrobble
//   season     int?     — for episode scrobble
//   episode    int?     — for episode scrobble
// ─────────────────────────────────────────────────────────────────────────────

class PlaybackPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> payload;

  const PlaybackPage({super.key, required this.payload});

  @override
  ConsumerState<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends ConsumerState<PlaybackPage>
    with WindowListener, WidgetsBindingObserver {
  late final PlaybackBackend _playback;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _completedSub;
  StreamSubscription<bool>? _firstFrameSub;

  // ── D-pad navigation focus nodes ────────────────────────────────────────
  // Initial focus lands on the progress bar. LHS icons (Menu/Subtitles/
  // AudioTracks) share Up -> center Play/Pause; RHS icons (Play-Pause-in-row/
  // Fullscreen/Stop) share Up -> volume bar. See _seekBarDirection /
  // _lhsIconDirection / _rhsIconDirection / _centerPlayDirection /
  // _volumeBarDirection below for the full graph.
  final _seekBarFocus = FocusNode(debugLabel: 'SeekBar');
  final _menuFocus = FocusNode(debugLabel: 'MenuIcon');
  final _subtitlesFocus = FocusNode(debugLabel: 'SubtitlesIcon');
  final _audioTracksFocus = FocusNode(debugLabel: 'AudioTracksIcon');
  final _playPauseRowFocus = FocusNode(debugLabel: 'PlayPauseRowIcon');
  final _aspectRatioFocus = FocusNode(debugLabel: 'AspectRatioIcon');
  final _fullscreenFocus = FocusNode(debugLabel: 'FullscreenIcon');
  final _stopFocus = FocusNode(debugLabel: 'StopIcon');
  final _centerPlayFocus = FocusNode(debugLabel: 'CenterPlayButton');
  final _volumeBarFocus = FocusNode(debugLabel: 'VolumeBar');
  bool _adjustingVolume = false;

  bool _showControls = true;
  bool _exiting = false;
  bool _allowPop = false;
  bool _seeking = false;
  bool _audioPassthrough = false;
  bool _dolbyMode = false;
  bool _isFullscreen = false;
  bool _firstFrameRendered = false;
  String _aspectRatioMode = 'fit';
  double _seekValue = 0;
  double _subtitleDelaySeconds = 0;
  int _subtitleSizeIndex = 1;
  double _audioAmplification = 0;
  Timer? _hideTimer;

  bool get _overlayHasFocus => [
    _seekBarFocus,
    _menuFocus,
    _subtitlesFocus,
    _audioTracksFocus,
    _playPauseRowFocus,
    _aspectRatioFocus,
    _fullscreenFocus,
    _stopFocus,
    _centerPlayFocus,
    _volumeBarFocus,
  ].any((node) => node.hasFocus);

  bool get _isCurrentRoute => ModalRoute.of(context)?.isCurrent ?? true;

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_isDesktop) windowManager.addListener(this);
    _playback = createPlaybackBackend();

    final src = widget.payload['source'] as String? ?? '';
    final resumeFromFrac = (widget.payload['resumeFromFrac'] as num?)
        ?.toDouble();

    if (src.isNotEmpty) {
      unawaited(_playback.open(src));
    }

    // Seek to resume position once duration is known
    if (resumeFromFrac != null && resumeFromFrac > 0) {
      _playback.durationStream.firstWhere((d) => d.inSeconds > 0).then((dur) {
        final seekTo = Duration(
          milliseconds: (resumeFromFrac * dur.inMilliseconds).round(),
        );
        _playback.seek(seekTo);
      }).ignore();
    }

    for (final node in [
      _seekBarFocus,
      _menuFocus,
      _subtitlesFocus,
      _audioTracksFocus,
      _playPauseRowFocus,
      _aspectRatioFocus,
      _fullscreenFocus,
      _stopFocus,
      _centerPlayFocus,
      _volumeBarFocus,
    ]) {
      node.addListener(_handleOverlayFocusChanged);
    }

    _resetHideTimer();

    // Scrobble start after first progress tick
    _positionSub = _playback.positionStream.listen(_onPosition);
    _completedSub = _playback.completedStream.listen(_onCompleted);
    _firstFrameSub = _playback.firstFrameStream.listen((rendered) {
      if (mounted) setState(() => _firstFrameRendered = rendered);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    if (_isDesktop) windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    for (final node in [
      _seekBarFocus,
      _menuFocus,
      _subtitlesFocus,
      _audioTracksFocus,
      _playPauseRowFocus,
      _aspectRatioFocus,
      _fullscreenFocus,
      _stopFocus,
      _centerPlayFocus,
      _volumeBarFocus,
    ]) {
      node.removeListener(_handleOverlayFocusChanged);
    }
    _seekBarFocus.dispose();
    _menuFocus.dispose();
    _subtitlesFocus.dispose();
    _audioTracksFocus.dispose();
    _playPauseRowFocus.dispose();
    _aspectRatioFocus.dispose();
    _fullscreenFocus.dispose();
    _stopFocus.dispose();
    _centerPlayFocus.dispose();
    _volumeBarFocus.dispose();
    _positionSub?.cancel();
    _completedSub?.cancel();
    _firstFrameSub?.cancel();
    unawaited(_playback.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_recoverPlaybackFocus());
    }
  }

  @override
  void onWindowEnterFullScreen() {
    if (mounted) setState(() => _isFullscreen = true);
    unawaited(_recoverFocusAfterFullscreenTransition());
  }

  @override
  void onWindowLeaveFullScreen() {
    if (mounted) setState(() => _isFullscreen = false);
    unawaited(_recoverFocusAfterFullscreenTransition());
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (!_showControls) setState(() => _showControls = true);
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || !_isCurrentRoute) return;
      _hideControlsOverlay();
    });
  }

  void _handleOverlayFocusChanged() {
    if (!_showControls || !_overlayHasFocus || _exiting) return;
    _resetHideTimer();
  }

  Duration? _scrobbleStartedAt;

  void _onPosition(Duration pos) {
    final dur = _playback.duration;
    if (dur.inSeconds == 0) return;

    // Fire scrobble start once playback is 5 seconds in
    if (_scrobbleStartedAt == null && pos.inSeconds >= 5) {
      _scrobbleStartedAt = pos;
      _sendScrobble('start', pos, dur);
    }
  }

  void _onCompleted(bool done) {
    if (done) {
      unawaited(_finishPlayback(completed: true));
    }
  }

  Future<void> _cleanupSession() async {
    final sessionId = widget.payload['sessionId'] as String?;
    if (sessionId == null || sessionId.isEmpty) return;
    try {
      await ref
          .read(apiClientProvider)
          .delete('/api/v1/player/preload/session/$sessionId');
    } catch (_) {
      // Session cleanup is best-effort; playback exit must still complete.
    }
  }

  /// Signal teardown to all listening pages.
  ///
  /// Incrementing [playbackEndedProvider] is safe after widget disposal because
  /// [ref.read] only reads the notifier — it does not depend on widget lifecycle.
  /// Home page and detail page both listen to this counter and re-fetch their
  /// data when it changes.  The backend clears its Trakt cache synchronously
  /// inside the scrobble-stop handler, so by the time listeners react the
  /// backend will already return fresh data.
  void _triggerRefresh() {
    ref.read(playbackEndedProvider.notifier).increment();
  }

  Future<void> _finishPlayback({bool completed = false}) async {
    if (_exiting) return;
    _exiting = true;
    _hideTimer?.cancel();

    if (_isDesktop && _isFullscreen) {
      try {
        await windowManager.setFullScreen(false);
      } catch (_) {}
    }

    final dur = _playback.duration;
    final pos = completed ? dur : _playback.position;
    await _sendScrobble('stop', pos, dur);

    if (!mounted) return;
    await _cleanupSession();

    if (!mounted) return;
    _triggerRefresh();

    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.canPop()) {
        context.pop(true);
      }
    });
  }

  Future<void> _sendScrobble(String action, Duration pos, Duration dur) async {
    final tmdbId = widget.payload['tmdbId'] as String?;
    if (tmdbId == null) return;

    final progress = dur.inSeconds > 0
        ? (pos.inSeconds / dur.inSeconds * 100).clamp(0.0, 100.0)
        : 0.0;

    final mediaType = widget.payload['mediaType'] as String? ?? 'movie';
    final season = widget.payload['season'] as int?;
    final episode = widget.payload['episode'] as int?;
    final title = widget.payload['title'] as String? ?? '';

    try {
      final client = ref.read(apiClientProvider);
      await client.post<dynamic>(
        '/api/v1/player/scrobble/$action',
        body: {
          'session_id': null,
          'media_type': mediaType == 'show' ? 'episode' : 'movie',
          'progress': progress,
          'media': {
            'title': title,
            'ids': {'tmdb': int.tryParse(tmdbId)},
          },
          if (season != null || episode != null)
            'episode': {'season': season, 'number': episode},
        },
      );
    } catch (_) {
      // Scrobble is best-effort — don't crash playback on failure
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final title = widget.payload['title'] as String? ?? '';

    return PopScope<bool>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handlePlaybackBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        // Back/Escape must work regardless of which control currently has
        // D-pad focus (progress bar, an icon, the volume bar, ...) — a
        // CallbackShortcuts here sits as an ancestor of every DpadFocusable
        // on this screen, so it's checked before the event would otherwise
        // reach the app-root Dpad.wrap()'s generic back handling. This
        // Back clears visible controls first; only Back on the clean video
        // surface stops playback.
        body: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape):
                _handlePlaybackBack,
            const SingleActivator(LogicalKeyboardKey.backspace):
                _handlePlaybackBack,
            const SingleActivator(LogicalKeyboardKey.goBack):
                _handlePlaybackBack,
            const SingleActivator(LogicalKeyboardKey.browserBack):
                _handlePlaybackBack,
            const SingleActivator(LogicalKeyboardKey.mediaStop): _exitPlayback,
            const SingleActivator(LogicalKeyboardKey.mediaPlayPause):
                _togglePlay,
            const SingleActivator(LogicalKeyboardKey.mediaPlay): _play,
            const SingleActivator(LogicalKeyboardKey.mediaPause): _pause,
            const SingleActivator(LogicalKeyboardKey.mediaRewind): () =>
                _seek(-10),
            const SingleActivator(LogicalKeyboardKey.mediaFastForward): () =>
                _seek(10),
          },
          child: MouseRegion(
            onEnter: (_) => _resetHideTimer(),
            onHover: (_) => _resetHideTimer(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _resetHideTimer,
              onDoubleTap: _resetHideTimer,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Video surface ─────────────────────────────────────────────
                  _playback.buildView(
                    controlsOverlay: _ControlsShortcuts(
                      onBack: _handlePlaybackBack,
                      onStop: _exitPlayback,
                      onPlayPause: _togglePlay,
                      onPlay: _play,
                      onPause: _pause,
                      onRewind: () => _seek(-10),
                      onFastForward: () => _seek(10),
                      child: _buildPlaybackOverlay(t, title),
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

  Widget _buildPlaybackOverlay(WarpTokens t, String title) => Stack(
    fit: StackFit.expand,
    children: [
      if (_playback.isNativeAndroid && !_firstFrameRendered)
        const IgnorePointer(child: _LoadingScrim()),
      IgnorePointer(
        ignoring: !_showControls,
        child: Opacity(
          opacity: _showControls ? 1.0 : 0.0,
          child: _buildControlsOverlay(t, title),
        ),
      ),
    ],
  );

  void _handlePlaybackBack() {
    if (_showControls) {
      _hideControlsOverlay();
      return;
    }
    _exitPlayback();
  }

  void _hideControlsOverlay() {
    _hideTimer?.cancel();
    if (!mounted) return;
    Dpad.of(context).requestFocus(_seekBarFocus);
    setState(() {
      _showControls = false;
      _adjustingVolume = false;
    });
  }

  // ── D-pad navigation: shared onDirection callbacks ─────────────────────
  //
  // Progress bar (autofocus) <-> LHS icons (Menu/Subtitles/AudioTracks)
  // <-> center Play/Pause <-> volume bar <-> RHS icons. Desktop includes a
  // fullscreen icon; Android TV is already immersive, so it omits that dead
  // control. Left/Right within the icon row is plain default beam traversal;
  // only the cross-row Up/Down jumps and volume adjust-mode need overrides.

  bool _seekBarDirection(TraversalDirection d) {
    _resetHideTimer();
    if (d == TraversalDirection.left) {
      _seek(-10);
      return true;
    }
    if (d == TraversalDirection.right) {
      _seek(10);
      return true;
    }
    if (d == TraversalDirection.up) {
      Dpad.of(context).requestFocus(_menuFocus);
      return true;
    }
    return false;
  }

  bool _lhsIconDirection(TraversalDirection d) {
    _resetHideTimer();
    if (d == TraversalDirection.up) {
      Dpad.of(context).requestFocus(_centerPlayFocus);
      return true;
    }
    return false;
  }

  bool _rhsIconDirection(TraversalDirection d) {
    _resetHideTimer();
    if (d == TraversalDirection.up) {
      Dpad.of(context).requestFocus(_volumeBarFocus);
      return true;
    }
    return false;
  }

  bool _centerPlayDirection(TraversalDirection d) {
    _resetHideTimer();
    if (d == TraversalDirection.down) {
      Dpad.of(context).requestFocus(_menuFocus);
      return true;
    }
    if (d == TraversalDirection.right) {
      Dpad.of(context).requestFocus(_volumeBarFocus);
      return true;
    }
    return false;
  }

  // Outer volume bar is a two-level "activatable" focusable: Select enters
  // adjust mode where Up/Down directly change volume; Select again commits
  // and exits back to normal navigation (Left -> center Play, Down -> Stop).
  bool _volumeBarDirection(TraversalDirection d) {
    _resetHideTimer();
    if (_adjustingVolume) {
      if (d == TraversalDirection.up) {
        _adjustVolume(0.1);
        return true;
      }
      if (d == TraversalDirection.down) {
        _adjustVolume(-0.1);
        return true;
      }
      return true; // swallow left/right too — the pill has focus while adjusting
    }
    if (d == TraversalDirection.left) {
      Dpad.of(context).requestFocus(_centerPlayFocus);
      return true;
    }
    if (d == TraversalDirection.down) {
      Dpad.of(context).requestFocus(_stopFocus);
      return true;
    }
    return false;
  }

  void _toggleVolumeAdjustMode() =>
      setState(() => _adjustingVolume = !_adjustingVolume);

  void _togglePlay() {
    _resetHideTimer();
    _playback.playing ? _playback.pause() : _playback.play();
    setState(() {});
  }

  void _play() {
    _resetHideTimer();
    _playback.play();
    setState(() {});
  }

  void _pause() {
    _resetHideTimer();
    _playback.pause();
    setState(() {});
  }

  void _seek(int seconds) {
    _resetHideTimer();
    final pos = _playback.position + Duration(seconds: seconds);
    _playback.seek(pos.isNegative ? Duration.zero : pos);
  }

  void _adjustVolume(double delta) {
    final v = (_playback.volume + delta * 100).clamp(0.0, 100.0);
    _setVolume(v);
    setState(() {});
  }

  void _setVolume(double value) {
    final v = value.clamp(0.0, 100.0);
    unawaited(_playback.setVolume(v));
  }

  void _exitPlayback() {
    unawaited(_finishPlayback());
  }

  void _toggleFullscreen() {
    _resetHideTimer();
    if (!_isDesktop) return;
    unawaited(_setWindowFullscreen(!_isFullscreen));
  }

  void _openAspectRatioMenu() {
    _resetHideTimer();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _AspectRatioDialog(
        selectedMode: _aspectRatioMode,
        onSelect: (mode) {
          setState(() => _aspectRatioMode = mode);
          unawaited(_playback.setAspectRatioMode(mode));
        },
      ),
    );
  }

  Future<void> _setWindowFullscreen(bool enabled) async {
    try {
      await windowManager.setFullScreen(enabled);
      final actual = await _waitForWindowFullscreen(enabled);
      if (!mounted) return;
      setState(() => _isFullscreen = actual);
      await _recoverFocusAfterFullscreenTransition();
    } catch (_) {}
  }

  Future<bool> _waitForWindowFullscreen(bool expected) async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final value = await windowManager.isFullScreen();
      if (value == expected) return value;
    }
    return windowManager.isFullScreen();
  }

  Future<void> _recoverFocusAfterFullscreenTransition() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await _recoverPlaybackFocus();
  }

  Future<void> _recoverPlaybackFocus() async {
    if (!mounted || _exiting || !_isCurrentRoute) return;
    if (_isDesktop) {
      try {
        await windowManager.focus();
      } catch (_) {}
    }
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _exiting || !_isCurrentRoute) return;
      Dpad.of(context).requestFocus(_seekBarFocus);
      _resetHideTimer();
    });
  }

  void _setSubtitleDelay(double seconds) {
    final value = seconds.clamp(-5.0, 5.0);
    if (mounted) setState(() => _subtitleDelaySeconds = value);
    unawaited(
      _playback.setSubtitleDelay(
        Duration(milliseconds: (value * 1000).round()),
      ),
    );
  }

  void _setSubtitleSizeIndex(int index) {
    final value = index.clamp(0, _subtitleSizeOptions.length - 1).toInt();
    if (mounted) setState(() => _subtitleSizeIndex = value);
    unawaited(_playback.setSubtitleTextSizeSp(_subtitleSizeOptions[value].sp));
  }

  void _setAudioAmplification(double value) {
    final v = value.clamp(0.0, 30.0);
    if (mounted) setState(() => _audioAmplification = v);
    unawaited(_playback.setAudioAmplificationDb(v));
  }

  void _setAudioPassthrough(bool enabled) {
    if (mounted) setState(() => _audioPassthrough = enabled);
    unawaited(_playback.setAudioPassthrough(enabled));
  }

  void _setDolbyMode(bool enabled) {
    if (mounted) setState(() => _dolbyMode = enabled);
    unawaited(_playback.setDolbyMode(enabled));
  }

  void _openSubtitles() {
    _resetHideTimer();
    unawaited(_playback.refreshTracks());
    final mediaType = widget.payload['mediaType'] as String? ?? 'movie';
    final wasPlaying = _playback.playing;
    if (wasPlaying) _playback.pause();
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SubtitleDialog(
        player: _playback,
        tmdbId: widget.payload['tmdbId'] as String? ?? '',
        mediaKind: mediaType == 'show' ? 'show' : 'movie',
        title: widget.payload['title'] as String?,
        season: widget.payload['season'] as int?,
        episode: widget.payload['episode'] as int?,
        sourceUrl: widget.payload['source'] as String?,
      ),
    ).whenComplete(() {
      if (mounted && !_exiting && wasPlaying) _playback.play();
    });
  }

  void _openPlayerMenu() {
    _resetHideTimer();
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => _PlayerMenuDialog(
        onSubtitleSettings: () {
          Navigator.of(dialogContext).pop();
          Future<void>.microtask(_openSubtitleSettings);
        },
        onAudioSettings: () {
          Navigator.of(dialogContext).pop();
          Future<void>.microtask(_openAudioSettings);
        },
      ),
    );
  }

  void _openSubtitleSettings() {
    _resetHideTimer();
    var delay = _subtitleDelaySeconds;
    var sizeIndex = _subtitleSizeIndex;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => _SettingsDialogFrame(
          icon: Icons.subtitles,
          title: 'Subtitle Settings',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingsValueHeader(
                label: 'Subtitle timing',
                value: '${delay >= 0 ? '+' : ''}${delay.toStringAsFixed(2)}s',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _RoundIconAction(
                    icon: Icons.remove,
                    onTap: () {
                      delay = (delay - 0.25).clamp(-5.0, 5.0);
                      setDialogState(() {});
                      _setSubtitleDelay(delay);
                    },
                  ),
                  Expanded(
                    child: _AccentSlider(
                      value: delay,
                      min: -5,
                      max: 5,
                      divisions: 40,
                      onChanged: (value) {
                        delay = value;
                        setDialogState(() {});
                        _setSubtitleDelay(value);
                      },
                    ),
                  ),
                  _RoundIconAction(
                    icon: Icons.add,
                    onTap: () {
                      delay = (delay + 0.25).clamp(-5.0, 5.0);
                      setDialogState(() {});
                      _setSubtitleDelay(delay);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Negative values hasten subtitles. Positive values delay them.',
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              _SettingsValueHeader(
                label: 'Subtitle size',
                value: _subtitleSizeOptions[sizeIndex].label,
              ),
              const SizedBox(height: 10),
              _AccentSlider(
                value: sizeIndex.toDouble(),
                min: 0,
                max: (_subtitleSizeOptions.length - 1).toDouble(),
                divisions: _subtitleSizeOptions.length - 1,
                onChanged: (value) {
                  sizeIndex = value
                      .round()
                      .clamp(0, _subtitleSizeOptions.length - 1)
                      .toInt();
                  setDialogState(() {});
                  _setSubtitleSizeIndex(sizeIndex);
                },
              ),
              const SizedBox(height: 6),
              const _SubtitleSizeScale(),
              const SizedBox(height: 20),
              Row(
                children: [
                  _DialogTextButton(
                    label: 'Reset',
                    onTap: () {
                      delay = 0;
                      sizeIndex = 1;
                      setDialogState(() {});
                      _setSubtitleDelay(0);
                      _setSubtitleSizeIndex(sizeIndex);
                    },
                  ),
                  const Spacer(),
                  _DialogTextButton(
                    label: 'Done',
                    filled: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAudioSettings() {
    _resetHideTimer();
    var amplification = _audioAmplification;
    var passthrough = _audioPassthrough;
    var dolby = _dolbyMode;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => _SettingsDialogFrame(
          icon: Icons.volume_up,
          title: 'Audio Settings',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingsValueHeader(
                label: 'Audio amplification',
                value: '+${amplification.round()} dB',
              ),
              const SizedBox(height: 12),
              _AccentSlider(
                value: amplification,
                min: 0,
                max: 30,
                divisions: 30,
                onChanged: (value) {
                  amplification = value;
                  setDialogState(() {});
                  _setAudioAmplification(value);
                },
              ),
              const SizedBox(height: 20),
              _SettingsSwitchRow(
                title: 'Audio passthrough',
                subtitle: 'Prefer AC3/DTS bitstream output when supported.',
                value: passthrough,
                onChanged: (value) {
                  passthrough = value;
                  setDialogState(() {});
                  _setAudioPassthrough(value);
                },
              ),
              const SizedBox(height: 10),
              _SettingsSwitchRow(
                title: 'Dolby mode',
                subtitle: 'Prefer surround channel layout when available.',
                value: dolby,
                onChanged: (value) {
                  dolby = value;
                  setDialogState(() {});
                  _setDolbyMode(value);
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Unsupported options are ignored by the active backend.',
                    style: TextStyle(
                      color: Colors.white.withAlpha(135),
                      height: 1.35,
                    ),
                  ),
                  const Spacer(),
                  _DialogTextButton(
                    label: 'Done',
                    filled: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAudioTracks() {
    _resetHideTimer();
    unawaited(_playback.refreshTracks());
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _AudioTracksDialog(
        tracksStream: _playback.audioTracksStream,
        trackStream: _playback.selectedAudioTrackStream,
        initialTracks: _playback.currentAudioTracks,
        initialTrack: _playback.currentSelectedAudioTrack,
        onSelect: (track) => unawaited(_playback.selectAudioTrack(track)),
      ),
    );
  }

  Widget _buildControlsOverlay(WarpTokens t, String title) {
    final edge = t.tvEdgePadding + 18;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC000000),
                Color(0x26000000),
                Colors.transparent,
                Color(0x73000000),
                Color(0xE6000000),
              ],
              stops: [0, 0.16, 0.45, 0.76, 1],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(edge, 14, edge, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withAlpha(235),
                        fontSize: t.fontSection,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Center(
          child: StreamBuilder<bool>(
            stream: _playback.playingStream,
            builder: (_, snap) => _CenterPlayButton(
              playing: snap.data ?? _playback.playing,
              onTap: _togglePlay,
              focusNode: _centerPlayFocus,
              onDirection: _centerPlayDirection,
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: StreamBuilder<double>(
              stream: _playback.volumeStream,
              builder: (_, snap) => _VerticalVolumeBar(
                value: ((snap.data ?? _playback.volume) / 100).clamp(0.0, 1.0),
                onChanged: (value) => _setVolume(value * 100),
                focusNode: _volumeBarFocus,
                onDirection: _volumeBarDirection,
                adjusting: _adjustingVolume,
                onToggleAdjust: _toggleVolumeAdjustMode,
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(edge, 0, edge, t.tvEdgePadding + 18),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: StreamBuilder<Duration>(
                stream: _playback.positionStream,
                builder: (context, posSnap) {
                  return StreamBuilder<Duration>(
                    stream: _playback.durationStream,
                    builder: (context, durSnap) {
                      final pos = posSnap.data ?? Duration.zero;
                      final dur = durSnap.data ?? Duration.zero;
                      final frac = dur.inMilliseconds > 0
                          ? pos.inMilliseconds / dur.inMilliseconds
                          : 0.0;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              _OverlayIconButton(
                                icon: Icons.menu,
                                tooltip: 'Menu',
                                onTap: _openPlayerMenu,
                                focusNode: _menuFocus,
                                onDirection: _lhsIconDirection,
                              ),
                              const SizedBox(width: 10),
                              _OverlayIconButton(
                                icon: Icons.subtitles,
                                tooltip: 'Subtitles',
                                onTap: _openSubtitles,
                                focusNode: _subtitlesFocus,
                                onDirection: _lhsIconDirection,
                              ),
                              const SizedBox(width: 10),
                              _OverlayIconButton(
                                icon: Icons.audiotrack,
                                tooltip: 'Audio Tracks',
                                onTap: _openAudioTracks,
                                focusNode: _audioTracksFocus,
                                onDirection: _lhsIconDirection,
                              ),
                              const Spacer(),
                              StreamBuilder<bool>(
                                stream: _playback.playingStream,
                                builder: (_, snap) => _OverlayIconButton(
                                  icon: (snap.data ?? _playback.playing)
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  tooltip: 'Play/Pause',
                                  onTap: _togglePlay,
                                  focusNode: _playPauseRowFocus,
                                  onDirection: _rhsIconDirection,
                                ),
                              ),
                              const SizedBox(width: 10),
                              _OverlayIconButton(
                                icon: Icons.aspect_ratio,
                                tooltip: 'Aspect Ratio',
                                onTap: _openAspectRatioMenu,
                                focusNode: _aspectRatioFocus,
                                onDirection: _rhsIconDirection,
                              ),
                              if (_isDesktop) ...[
                                const SizedBox(width: 10),
                                _OverlayIconButton(
                                  icon: _isFullscreen
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  tooltip: _isFullscreen
                                      ? 'Exit Fullscreen'
                                      : 'Fullscreen',
                                  onTap: _toggleFullscreen,
                                  focusNode: _fullscreenFocus,
                                  onDirection: _rhsIconDirection,
                                ),
                              ],
                              const SizedBox(width: 10),
                              _OverlayIconButton(
                                icon: Icons.stop,
                                tooltip: 'Stop',
                                onTap: _exitPlayback,
                                focusNode: _stopFocus,
                                onDirection: _rhsIconDirection,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ProgressDock(
                            positionLabel: _formatDuration(pos),
                            durationLabel: _formatDuration(dur),
                            child: _SeekBar(
                              value: _seeking ? _seekValue : frac,
                              focusNode: _seekBarFocus,
                              onDirection: _seekBarDirection,
                              onSelect: _togglePlay,
                              onChanged: (v) => setState(() {
                                _seeking = true;
                                _seekValue = v;
                              }),
                              onChangeEnd: (v) {
                                setState(() => _seeking = false);
                                _playback.seek(
                                  Duration(
                                    milliseconds: (v * dur.inMilliseconds)
                                        .round(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

const _uoscAccent = Color(0xFF0DB2E2);
const _uoscAccentLight = Color(0xFF78F4FF);
const _uoscGlass = Color(0xFF0B1118);
const _subtitleSizeOptions = [
  _SubtitleSizeOption('XSmall', 30),
  _SubtitleSizeOption('Small', 40),
  _SubtitleSizeOption('Medium', 55),
  _SubtitleSizeOption('Large', 70),
  _SubtitleSizeOption('XLarge', 85),
];

class _SubtitleSizeOption {
  final String label;
  final double sp;

  const _SubtitleSizeOption(this.label, this.sp);
}

class _ControlsShortcuts extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onStop;
  final VoidCallback onPlayPause;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onRewind;
  final VoidCallback onFastForward;
  final Widget child;

  const _ControlsShortcuts({
    required this.onBack,
    required this.onStop,
    required this.onPlayPause,
    required this.onPlay,
    required this.onPause,
    required this.onRewind,
    required this.onFastForward,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): onBack,
      const SingleActivator(LogicalKeyboardKey.backspace): onBack,
      const SingleActivator(LogicalKeyboardKey.goBack): onBack,
      const SingleActivator(LogicalKeyboardKey.browserBack): onBack,
      const SingleActivator(LogicalKeyboardKey.mediaStop): onStop,
      const SingleActivator(LogicalKeyboardKey.mediaPlayPause): onPlayPause,
      const SingleActivator(LogicalKeyboardKey.mediaPlay): onPlay,
      const SingleActivator(LogicalKeyboardKey.mediaPause): onPause,
      const SingleActivator(LogicalKeyboardKey.mediaRewind): onRewind,
      const SingleActivator(LogicalKeyboardKey.mediaFastForward): onFastForward,
    },
    child: child,
  );
}

class _LoadingScrim extends StatelessWidget {
  const _LoadingScrim();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Colors.black,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              color: _uoscAccentLight,
              strokeWidth: 2,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SeekBar extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;
  final VoidCallback? onSelect;

  const _SeekBar({
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    this.focusNode,
    this.onDirection,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) => DpadFocusable(
    focusNode: focusNode,
    autofocus: true,
    entry: true,
    onDirection: onDirection,
    onSelect: onSelect ?? () {},
    tapToSelect: false,
    builder: (context, state, child) => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: state.focused ? _uoscAccent : Colors.transparent,
          width: 2,
        ),
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          activeTrackColor: _uoscAccentLight,
          inactiveTrackColor: Colors.white.withAlpha(38),
          thumbColor: Colors.white,
          overlayColor: _uoscAccent.withAlpha(54),
        ),
        child: Slider(
          value: value.clamp(0.0, 1.0),
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

class _ProgressDock extends StatelessWidget {
  final String positionLabel;
  final String durationLabel;
  final Widget child;

  const _ProgressDock({
    required this.positionLabel,
    required this.durationLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    decoration: BoxDecoration(
      color: const Color(0xE60A0E14),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _uoscAccent.withAlpha(70)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _TimeLabel(positionLabel),
              const Spacer(),
              _TimeLabel(durationLabel),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TimeLabel extends StatelessWidget {
  final String value;

  const _TimeLabel(this.value);

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: TextStyle(
      color: Colors.white.withAlpha(180),
      fontSize: 12,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: 0.3,
    ),
  );
}

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;

  const _OverlayIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.focusNode,
    this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    final child = DpadFocusable(
      focusNode: focusNode,
      onDirection: onDirection,
      onSelect: onTap,
      tapToSelect: false,
      builder: (context, state, child) => GestureDetector(
        onTap: () {
          focusNode?.requestFocus();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: state.focused ? _uoscAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: state.focused ? _uoscAccentLight : Colors.transparent,
              width: 2,
            ),
          ),
          child: _GradientIcon(icon: icon, size: 24),
        ),
      ),
      child: const SizedBox.shrink(),
    );

    if (tooltip == null) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}

class _GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const _GradientIcon({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (bounds) => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Color(0xFFF3FFFF), _uoscAccentLight],
      stops: [0, 0.72, 1],
    ).createShader(bounds),
    child: Icon(icon, size: size),
  );
}

class _CenterPlayButton extends StatelessWidget {
  final bool playing;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;

  const _CenterPlayButton({
    required this.playing,
    required this.onTap,
    this.focusNode,
    this.onDirection,
  });

  @override
  Widget build(BuildContext context) => DpadFocusable(
    focusNode: focusNode,
    onDirection: onDirection,
    onSelect: onTap,
    tapToSelect: false,
    builder: (context, state, child) => GestureDetector(
      onTap: () {
        focusNode?.requestFocus();
        onTap();
      },
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: state.focused ? _uoscAccent.withAlpha(120) : Colors.black87,
          border: Border.all(color: Colors.white.withAlpha(70)),
        ),
        child: Center(
          child: _GradientIcon(
            icon: playing ? Icons.pause : Icons.play_arrow,
            size: 62,
          ),
        ),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

class _VerticalVolumeBar extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;
  final bool adjusting;
  final VoidCallback? onToggleAdjust;

  const _VerticalVolumeBar({
    required this.value,
    required this.onChanged,
    this.focusNode,
    this.onDirection,
    this.adjusting = false,
    this.onToggleAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 54,
      height: 260,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const topPad = 42.0;
          const bottomPad = 54.0;
          final trackHeight = constraints.maxHeight - topPad - bottomPad;

          void update(double y) {
            final normalized = 1 - ((y - topPad) / trackHeight).clamp(0.0, 1.0);
            onChanged(normalized.toDouble());
          }

          return DpadFocusable(
            focusNode: focusNode,
            onDirection: onDirection,
            onSelect: onToggleAdjust ?? () {},
            tapToSelect: false,
            builder: (context, state, child) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => update(details.localPosition.dy),
              onVerticalDragUpdate: (details) =>
                  update(details.localPosition.dy),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(24),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xE60A0F16),
                    border: Border(
                      left: BorderSide(
                        color: (state.focused || adjusting)
                            ? _uoscAccentLight
                            : _uoscAccent.withAlpha(70),
                        width: (state.focused || adjusting) ? 2 : 1,
                      ),
                      top: BorderSide(color: Colors.white.withAlpha(18)),
                      bottom: BorderSide(color: Colors.white.withAlpha(18)),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _GradientIcon(
                        icon: v == 0
                            ? Icons.volume_off
                            : v < 0.5
                            ? Icons.volume_down
                            : Icons.volume_up,
                        size: 22,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 5,
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(35),
                              borderRadius: BorderRadius.circular(999),
                              border: adjusting
                                  ? Border.all(color: _uoscAccentLight)
                                  : null,
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: v,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [_uoscAccent, _uoscAccentLight],
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Text(
                          '${(v * 100).round()}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            child: const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class _PlayerMenuDialog extends StatelessWidget {
  final VoidCallback onSubtitleSettings;
  final VoidCallback onAudioSettings;

  const _PlayerMenuDialog({
    required this.onSubtitleSettings,
    required this.onAudioSettings,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
        const SingleActivator(LogicalKeyboardKey.backspace): () =>
            Navigator.of(context).pop(),
        const SingleActivator(LogicalKeyboardKey.goBack): () =>
            Navigator.of(context).pop(),
        const SingleActivator(LogicalKeyboardKey.browserBack): () =>
            Navigator.of(context).pop(),
      },
      child: DpadRegion(
        memoryKey: 'player-menu',
        horizontalEdge: DpadEdgeBehavior.stop,
        verticalEdge: DpadEdgeBehavior.stop,
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(85, 0, 0, 124),
              child: TvModalChromeScale(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _uoscGlass,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _uoscAccent.withAlpha(72)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MenuTile(
                          icon: Icons.subtitles,
                          title: 'Subtitle Settings',
                          subtitle: 'Delay or hasten subtitle timing',
                          onTap: onSubtitleSettings,
                          autofocus: true,
                        ),
                        _MenuTile(
                          icon: Icons.volume_up,
                          title: 'Audio Settings',
                          subtitle: 'Amplification, passthrough, Dolby',
                          onTap: onAudioSettings,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool autofocus;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) => DpadFocusable(
    autofocus: autofocus,
    entry: autofocus,
    onSelect: onTap,
    builder: (context, state, child) => InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: state.focused ? _uoscAccentLight : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _uoscAccent.withAlpha(28),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _uoscAccent.withAlpha(54)),
                ),
                child: Center(child: _GradientIcon(icon: icon, size: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withAlpha(145),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withAlpha(130),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

class _SettingsDialogFrame extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SettingsDialogFrame({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    child: TvModalChromeScale(
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).pop(),
          const SingleActivator(LogicalKeyboardKey.backspace): () =>
              Navigator.of(context).pop(),
          const SingleActivator(LogicalKeyboardKey.goBack): () =>
              Navigator.of(context).pop(),
          const SingleActivator(LogicalKeyboardKey.browserBack): () =>
              Navigator.of(context).pop(),
        },
        child: DpadRegion(
          memoryKey: 'player-settings-dialog',
          horizontalEdge: DpadEdgeBehavior.stop,
          verticalEdge: DpadEdgeBehavior.stop,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A0E14), Color(0xFF0A1A24)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: _uoscAccent.withAlpha(76)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _uoscAccent.withAlpha(30),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: _uoscAccent.withAlpha(60),
                            ),
                          ),
                          child: Center(
                            child: _GradientIcon(icon: icon, size: 23),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        DpadFocusable(
                          autofocus: true,
                          entry: true,
                          onSelect: () => Navigator.of(context).pop(),
                          builder: (context, state, child) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: state.focused
                                  ? Colors.white.withAlpha(24)
                                  : Colors.transparent,
                              border: Border.all(
                                color: state.focused
                                    ? Colors.white.withAlpha(220)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close,
                                  color: state.focused
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          child: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SettingsValueHeader extends StatelessWidget {
  final String label;
  final String value;

  const _SettingsValueHeader({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withAlpha(175),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      const Spacer(),
      Text(
        value,
        style: const TextStyle(
          color: _uoscAccentLight,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );
}

class _SubtitleSizeScale extends StatelessWidget {
  const _SubtitleSizeScale();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        for (var i = 0; i < _subtitleSizeOptions.length; i++) ...[
          Expanded(
            child: Text(
              _subtitleSizeOptions[i].label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(145),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (i < _subtitleSizeOptions.length - 1) const SizedBox(width: 4),
        ],
      ],
    ),
  );
}

class _AccentSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const _AccentSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    final step = (max - min) / (divisions ?? 20);
    return DpadFocusable(
      onSelect: () {},
      // Left/Right adjust the value directly instead of navigating away —
      // mirrors the adjacent _RoundIconAction +/- buttons.
      onDirection: (d) {
        if (d == TraversalDirection.left) {
          onChanged((value - step).clamp(min, max));
          return true;
        }
        if (d == TraversalDirection.right) {
          onChanged((value + step).clamp(min, max));
          return true;
        }
        return false;
      },
      builder: (context, state, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: state.focused ? _uoscAccentLight : Colors.transparent,
            width: 2,
          ),
        ),
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: _uoscAccentLight,
            inactiveTrackColor: Colors.white.withAlpha(36),
            thumbColor: Colors.white,
            overlayColor: _uoscAccent.withAlpha(50),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}

class _RoundIconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => DpadFocusable(
    onSelect: onTap,
    builder: (context, state, child) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          shape: BoxShape.circle,
          border: Border.all(
            color: state.focused ? _uoscAccentLight : _uoscAccent.withAlpha(58),
            width: state.focused ? 2 : 1,
          ),
        ),
        child: Center(child: _GradientIcon(icon: icon, size: 20)),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

class _DialogTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _DialogTextButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) => DpadFocusable(
    onSelect: onTap,
    builder: (context, state, child) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: filled ? _uoscAccentLight : Colors.white.withAlpha(16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: state.focused ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.black : Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

class _SettingsSwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DpadFocusable(
    onSelect: () => onChanged(!value),
    tapToSelect: false,
    builder: (context, state, child) => GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: state.focused
                ? _uoscAccentLight
                : Colors.white.withAlpha(22),
            width: state.focused ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(142),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            IgnorePointer(
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: _uoscAccentLight,
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white24,
              ),
            ),
          ],
        ),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

class _AspectRatioDialog extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onSelect;

  const _AspectRatioDialog({
    required this.selectedMode,
    required this.onSelect,
  });

  static const _options = [
    _AspectRatioOption(
      mode: 'fit',
      title: 'Fit',
      subtitle: 'Preserve source aspect ratio inside the screen.',
    ),
    _AspectRatioOption(
      mode: 'fill',
      title: 'Fill',
      subtitle: 'Fill the full player area without preserving letterbox.',
    ),
    _AspectRatioOption(
      mode: 'zoom',
      title: 'Zoom',
      subtitle: 'Crop evenly to remove surrounding black bars.',
    ),
    _AspectRatioOption(
      mode: '16:9',
      title: '16:9',
      subtitle: 'HDTV and widescreen broadcast standard.',
    ),
    _AspectRatioOption(
      mode: '4:3',
      title: '4:3',
      subtitle: 'Classic TV and legacy broadcast standard.',
    ),
    _AspectRatioOption(
      mode: '14:9',
      title: '14:9',
      subtitle: 'Broadcast compromise between 4:3 and 16:9.',
    ),
    _AspectRatioOption(
      mode: '18:9',
      title: '18:9',
      subtitle: '2:1 Univisium / modern streaming frame.',
    ),
    _AspectRatioOption(
      mode: '21:9',
      title: '21:9',
      subtitle: 'Ultrawide/cinema-style display frame.',
    ),
    _AspectRatioOption(
      mode: '2.35:1',
      title: '2.35:1',
      subtitle: 'CinemaScope theatrical ratio.',
    ),
    _AspectRatioOption(
      mode: '2.39:1',
      title: '2.39:1',
      subtitle: 'Modern anamorphic theatrical ratio.',
    ),
  ];

  @override
  Widget build(BuildContext context) => _SettingsDialogFrame(
    icon: Icons.aspect_ratio,
    title: 'Aspect Ratio',
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 430),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _options.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final option = _options[index];
          return _AspectRatioTile(
            option: option,
            selected: option.mode == selectedMode,
            onTap: () {
              onSelect(option.mode);
              Navigator.of(context).pop();
            },
          );
        },
      ),
    ),
  );
}

class _AspectRatioOption {
  final String mode;
  final String title;
  final String subtitle;

  const _AspectRatioOption({
    required this.mode,
    required this.title,
    required this.subtitle,
  });
}

class _AspectRatioTile extends StatelessWidget {
  final _AspectRatioOption option;
  final bool selected;
  final VoidCallback onTap;

  const _AspectRatioTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => DpadFocusable(
    onSelect: onTap,
    builder: (context, state, child) => InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? _uoscAccent.withAlpha(34)
              : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: state.focused
                ? _uoscAccentLight
                : (selected
                      ? _uoscAccentLight.withAlpha(120)
                      : Colors.white.withAlpha(20)),
            width: state.focused ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? _uoscAccent.withAlpha(46)
                    : Colors.white.withAlpha(14),
              ),
              child: Center(
                child: selected
                    ? const Icon(Icons.check, color: _uoscAccentLight, size: 20)
                    : _GradientIcon(icon: Icons.aspect_ratio, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(145),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

class _AudioTracksDialog extends StatelessWidget {
  final Stream<List<PlaybackTrackInfo>> tracksStream;
  final Stream<PlaybackTrackInfo?> trackStream;
  final List<PlaybackTrackInfo> initialTracks;
  final PlaybackTrackInfo? initialTrack;
  final ValueChanged<PlaybackTrackInfo> onSelect;

  const _AudioTracksDialog({
    required this.tracksStream,
    required this.trackStream,
    required this.initialTracks,
    required this.initialTrack,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => _SettingsDialogFrame(
    icon: Icons.audiotrack,
    title: 'Audio Tracks',
    child: StreamBuilder<List<PlaybackTrackInfo>>(
      stream: tracksStream,
      initialData: initialTracks,
      builder: (context, tracksSnap) => StreamBuilder<PlaybackTrackInfo?>(
        stream: trackStream,
        initialData: initialTrack,
        builder: (context, trackSnap) {
          final tracks = tracksSnap.data ?? const <PlaybackTrackInfo>[];
          final selected = trackSnap.data;
          if (tracks.isEmpty) {
            return Text(
              'No audio tracks are available for this media.',
              style: TextStyle(color: Colors.white.withAlpha(170)),
            );
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: tracks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final track = tracks[index];
                return _TrackTile(
                  track: track,
                  selected: track.id == selected?.id || track.selected,
                  onTap: () => onSelect(track),
                );
              },
            ),
          );
        },
      ),
    ),
  );
}

class _TrackTile extends StatelessWidget {
  final PlaybackTrackInfo track;
  final bool selected;
  final VoidCallback onTap;

  const _TrackTile({
    required this.track,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => DpadFocusable(
    onSelect: onTap,
    builder: (context, state, child) => InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? _uoscAccent.withAlpha(34)
              : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: state.focused
                ? _uoscAccentLight
                : (selected
                      ? _uoscAccentLight.withAlpha(120)
                      : Colors.white.withAlpha(20)),
            width: state.focused ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? _uoscAccent.withAlpha(46)
                    : Colors.white.withAlpha(14),
              ),
              child: Center(
                child: selected
                    ? const Icon(Icons.check, color: _uoscAccentLight, size: 20)
                    : _GradientIcon(icon: Icons.audiotrack, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _audioTrackTitle(track),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _audioTrackSubtitle(track),
                    style: TextStyle(
                      color: Colors.white.withAlpha(145),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    child: const SizedBox.shrink(),
  );
}

String _audioTrackTitle(PlaybackTrackInfo track) {
  if (track.isAuto) return 'Auto';
  if (track.isNone) return 'Disabled';
  final title = track.title.trim();
  if (title.isNotEmpty) return title;
  final language = track.language?.trim();
  if (language != null && language.isNotEmpty) return language.toUpperCase();
  return 'Audio ${track.id}';
}

String _audioTrackSubtitle(PlaybackTrackInfo track) {
  if (track.isAuto) return 'Let the player choose the best track.';
  if (track.isNone) return 'Disable audio output.';
  final parts = <String>[];
  final language = track.language?.trim();
  if (language != null && language.isNotEmpty) {
    parts.add(language.toUpperCase());
  }
  final codec = track.codec?.trim();
  if (codec != null && codec.isNotEmpty) parts.add(codec.toUpperCase());
  final channels = track.channels?.trim();
  if (channels != null && channels.isNotEmpty) {
    parts.add(channels);
  } else if (track.channelCount != null) {
    parts.add('${track.channelCount} channels');
  }
  final samplerate = track.sampleRate;
  if (samplerate != null && samplerate > 0) {
    parts.add('${(samplerate / 1000).toStringAsFixed(1)} kHz');
  }
  return parts.isEmpty ? 'Track id ${track.id}' : parts.join(' · ');
}
