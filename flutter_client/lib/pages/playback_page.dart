import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';
import '../api/api_client.dart';
import '../providers/detail_provider.dart';
import '../theme/warp_tokens.dart';
import '../widgets/media/subtitle_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PlaybackPage — full-screen media_kit video player
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
    with WindowListener {
  late final Player _player;
  late final VideoController _controller;

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
  double _seekValue = 0;
  double _subtitleDelaySeconds = 0;
  double _audioAmplification = 100;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);

    final src = widget.payload['source'] as String? ?? '';
    final resumeFromFrac = (widget.payload['resumeFromFrac'] as num?)
        ?.toDouble();

    if (src.isNotEmpty) {
      _player.open(Media(src));
    }

    // Seek to resume position once duration is known
    if (resumeFromFrac != null && resumeFromFrac > 0) {
      _player.stream.duration.firstWhere((d) => d.inSeconds > 0).then((dur) {
        final seekTo = Duration(
          milliseconds: (resumeFromFrac * dur.inMilliseconds).round(),
        );
        _player.seek(seekTo);
      }).ignore();
    }

    _resetHideTimer();

    // Track OS-level fullscreen changes (green button, Ctrl+Cmd+F, etc.)
    windowManager.addListener(this);

    // Scrobble start after first progress tick
    _player.stream.position.listen(_onPosition);
    _player.stream.completed.listen(_onCompleted);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekBarFocus.dispose();
    _menuFocus.dispose();
    _subtitlesFocus.dispose();
    _audioTracksFocus.dispose();
    _playPauseRowFocus.dispose();
    _fullscreenFocus.dispose();
    _stopFocus.dispose();
    _centerPlayFocus.dispose();
    _volumeBarFocus.dispose();
    windowManager.removeListener(this);
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  void onWindowEnterFullScreen() {
    if (mounted) setState(() => _isFullscreen = true);
  }

  @override
  void onWindowLeaveFullScreen() {
    if (mounted) setState(() => _isFullscreen = false);
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (!_showControls) setState(() => _showControls = true);
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _player.state.playing) {
        setState(() => _showControls = false);
      }
    });
  }

  Duration? _scrobbleStartedAt;

  void _onPosition(Duration pos) {
    final dur = _player.state.duration;
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

    // Restore windowed mode if we're in fullscreen
    if (_isFullscreen) {
      try {
        await windowManager.setFullScreen(false);
      } catch (_) {}
    }

    final dur = _player.state.duration;
    final pos = completed ? dur : _player.state.position;
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
        if (!didPop) _exitPlayback();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        // Back/Escape must work regardless of which control currently has
        // D-pad focus (progress bar, an icon, the volume bar, ...) — a
        // CallbackShortcuts here sits as an ancestor of every DpadFocusable
        // on this screen, so it's checked before the event would otherwise
        // reach the app-root Dpad.wrap()'s generic back handling. This
        // preserves the existing "Back = Stop playback" behavior exactly
        // (backspace/goBack/browserBack/mediaStop all included, not just
        // dpad's own narrower default back key set).
        body: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): _handleEscape,
            const SingleActivator(LogicalKeyboardKey.backspace): _exitPlayback,
            const SingleActivator(LogicalKeyboardKey.goBack): _exitPlayback,
            const SingleActivator(LogicalKeyboardKey.browserBack): _exitPlayback,
            const SingleActivator(LogicalKeyboardKey.mediaStop): _exitPlayback,
          },
          child: MouseRegion(
            onEnter: (_) => _resetHideTimer(),
            onHover: (_) => _resetHideTimer(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _resetHideTimer,
              onDoubleTap: _toggleFullscreen,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Video surface ─────────────────────────────────────────────
                  Video(
                    controller: _controller,
                    controls: NoVideoControls,
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
                          Shadow(
                            color: Color(0xDD000000),
                            blurRadius: 6,
                            offset: Offset(1, 1),
                          ),
                          Shadow(
                            color: Color(0xAA000000),
                            blurRadius: 3,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 48.0),
                    ),
                  ),

                  // ── Controls overlay ──────────────────────────────────────────
                  IgnorePointer(
                    ignoring: !_showControls,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: _buildControlsOverlay(t, title),
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

  // Escape means "exit fullscreen" first, "stop playback" otherwise — kept
  // as its own binding since it's distinct from the plain back/stop keys.
  void _handleEscape() {
    _resetHideTimer();
    if (_isFullscreen) {
      _toggleFullscreen();
    } else {
      _exitPlayback();
    }
  }

  // ── D-pad navigation: shared onDirection callbacks ─────────────────────
  //
  // Progress bar (autofocus) <-> LHS icons (Menu/Subtitles/AudioTracks)
  // <-> center Play/Pause <-> volume bar <-> RHS icons (Play-Pause-in-row/
  // Fullscreen/Stop). Left/Right within the icon row is plain default beam
  // traversal; only the cross-row Up/Down jumps and the volume bar's
  // adjust-mode need explicit overrides.

  bool _seekBarDirection(TraversalDirection d) {
    _resetHideTimer();
    if (d == TraversalDirection.left) { _seek(-10); return true; }
    if (d == TraversalDirection.right) { _seek(10); return true; }
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
      if (d == TraversalDirection.up) { _adjustVolume(0.1); return true; }
      if (d == TraversalDirection.down) { _adjustVolume(-0.1); return true; }
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

  void _toggleVolumeAdjustMode() => setState(() => _adjustingVolume = !_adjustingVolume);

  void _togglePlay() {
    _player.state.playing ? _player.pause() : _player.play();
    setState(() {});
  }

  void _seek(int seconds) {
    final pos = _player.state.position + Duration(seconds: seconds);
    _player.seek(pos.isNegative ? Duration.zero : pos);
  }

  void _adjustVolume(double delta) {
    final v = (_player.state.volume + delta * 100).clamp(0.0, 100.0);
    _setVolume(v);
    setState(() {});
  }

  void _setVolume(double value) {
    final v = value.clamp(0.0, 200.0);
    _audioAmplification = v;
    unawaited(_player.setVolume(v));
  }

  void _exitPlayback() {
    unawaited(_finishPlayback());
  }

  void _toggleFullscreen() {
    _resetHideTimer();
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;
    unawaited(_setFullscreen(!_isFullscreen));
  }

  Future<void> _setFullscreen(bool enabled) async {
    try {
      if (enabled) {
        await windowManager.setFullScreen(true);
      } else {
        await windowManager.setFullScreen(false);
      }
    } catch (_) {
      // window_manager may not be initialized on all platforms.
    }
  }

  Future<void> _setMpvProperty(String property, String value) async {
    final platform = _player.platform;
    if (platform == null) return;
    try {
      await (platform as dynamic).setProperty(property, value);
    } catch (_) {
      // Advanced mpv options are unavailable on some platforms/backends.
    }
  }

  void _setSubtitleDelay(double seconds) {
    final value = seconds.clamp(-5.0, 5.0);
    if (mounted) setState(() => _subtitleDelaySeconds = value);
    unawaited(_setMpvProperty('sub-delay', value.toStringAsFixed(2)));
  }

  void _setAudioAmplification(double value) {
    final v = value.clamp(0.0, 200.0);
    if (mounted) setState(() => _audioAmplification = v);
    unawaited(_player.setVolume(v));
  }

  void _setAudioPassthrough(bool enabled) {
    if (mounted) setState(() => _audioPassthrough = enabled);
    unawaited(
      _setMpvProperty(
        'audio-spdif',
        enabled ? 'ac3,dts,dts-hd,eac3,truehd' : '',
      ),
    );
  }

  void _setDolbyMode(bool enabled) {
    if (mounted) setState(() => _dolbyMode = enabled);
    unawaited(_setMpvProperty('audio-channels', enabled ? 'auto' : 'stereo'));
  }

  void _openSubtitles() {
    _resetHideTimer();
    final mediaType = widget.payload['mediaType'] as String? ?? 'movie';
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SubtitleDialog(
        player: _player,
        tmdbId: widget.payload['tmdbId'] as String? ?? '',
        mediaKind: mediaType == 'show' ? 'show' : 'movie',
        title: widget.payload['title'] as String?,
        season: widget.payload['season'] as int?,
        episode: widget.payload['episode'] as int?,
        sourceUrl: widget.payload['source'] as String?,
      ),
    );
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
              const SizedBox(height: 20),
              Row(
                children: [
                  _DialogTextButton(
                    label: 'Reset',
                    onTap: () {
                      delay = 0;
                      setDialogState(() {});
                      _setSubtitleDelay(0);
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
                value: '${amplification.round()}%',
              ),
              const SizedBox(height: 12),
              _AccentSlider(
                value: amplification,
                min: 0,
                max: 200,
                divisions: 40,
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
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _AudioTracksDialog(
        tracksStream: _player.stream.tracks,
        trackStream: _player.stream.track,
        initialTracks: _player.state.tracks,
        initialTrack: _player.state.track,
        onSelect: (track) => unawaited(_player.setAudioTrack(track)),
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
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 12),
                        ],
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
            stream: _player.stream.playing,
            builder: (_, snap) => _CenterPlayButton(
              playing: snap.data ?? _player.state.playing,
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
              stream: _player.stream.volume,
              builder: (_, snap) => _VerticalVolumeBar(
                value: ((snap.data ?? _player.state.volume) / 100).clamp(
                  0.0,
                  1.0,
                ),
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
                stream: _player.stream.position,
                builder: (context, posSnap) {
                  return StreamBuilder<Duration>(
                    stream: _player.stream.duration,
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
                                stream: _player.stream.playing,
                                builder: (_, snap) => _OverlayIconButton(
                                  icon: (snap.data ?? _player.state.playing)
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
                                _player.seek(
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
const _uoscGlass = Color(0xB30B1118);

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
    builder: (context, state, child) => AnimatedContainer(
      duration: const Duration(milliseconds: 150),
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
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xD90A0E14), Color(0xA8061820)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _uoscAccent.withAlpha(70)),
          boxShadow: const [
            BoxShadow(
              color: Color(0xAA000000),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
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
      ),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _uoscGlass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(26)),
                // Icon-category focus indicator: prominent cyan halo.
                boxShadow: [
                  if (state.focused)
                    BoxShadow(color: _uoscAccent.withAlpha(160), blurRadius: 22, spreadRadius: 3)
                  else
                    const BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8)),
                ],
              ),
              child: _GradientIcon(icon: icon, size: 24),
            ),
          ),
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
    child: Icon(
      icon,
      size: size,
      shadows: const [Shadow(color: Colors.black, blurRadius: 16)],
    ),
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
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_uoscAccent.withAlpha(48), Colors.black.withAlpha(120)],
              ),
              border: Border.all(color: Colors.white.withAlpha(38)),
              boxShadow: [
                BoxShadow(
                  color: _uoscAccent.withAlpha(state.focused ? 200 : 44),
                  blurRadius: state.focused ? 44 : 34,
                  spreadRadius: state.focused ? 8 : 4,
                ),
                const BoxShadow(color: Colors.black87, blurRadius: 28),
              ],
            ),
            child: Center(
              child: _GradientIcon(
                icon: playing ? Icons.pause : Icons.play_arrow,
                size: 62,
              ),
            ),
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
            onVerticalDragUpdate: (details) => update(details.localPosition.dy),
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xC90A0F16), Color(0x8A082331)],
                    ),
                    border: Border(
                      left: BorderSide(
                        color: (state.focused || adjusting) ? _uoscAccentLight : _uoscAccent.withAlpha(70),
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
                              // "Volume level pill" activatable highlight —
                              // Select enters adjust mode, Up/Down changes
                              // the value directly while this glow is shown.
                              boxShadow: adjusting
                                  ? [BoxShadow(color: _uoscAccentLight.withAlpha(180), blurRadius: 16, spreadRadius: 2)]
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
                                    boxShadow: [
                                      BoxShadow(
                                        color: _uoscAccentLight.withAlpha(110),
                                        blurRadius: 14,
                                      ),
                                    ],
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
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),
      },
      child: DpadRegion(
        memoryKey: 'player-menu',
        horizontalEdge: DpadEdgeBehavior.stop,
        verticalEdge: DpadEdgeBehavior.stop,
        child: SafeArea(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 0, 124),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _uoscGlass,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _uoscAccent.withAlpha(72)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 28,
                      offset: Offset(0, 16),
                    ),
                  ],
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
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),
      },
      child: DpadRegion(
        memoryKey: 'player-settings-dialog',
        horizontalEdge: DpadEdgeBehavior.stop,
        verticalEdge: DpadEdgeBehavior.stop,
        child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xF20A0E14), Color(0xE50A1A24)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _uoscAccent.withAlpha(76)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 36,
                  offset: Offset(0, 18),
                ),
              ],
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
                        border: Border.all(color: _uoscAccent.withAlpha(60)),
                      ),
                      child: Center(child: _GradientIcon(icon: icon, size: 23)),
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
                          boxShadow: state.focused
                              ? [BoxShadow(color: _uoscAccent.withAlpha(160), blurRadius: 18, spreadRadius: 2)]
                              : null,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white70),
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
          border: Border.all(color: state.focused ? _uoscAccentLight : _uoscAccent.withAlpha(58)),
          boxShadow: state.focused
              ? [BoxShadow(color: _uoscAccent.withAlpha(140), blurRadius: 16, spreadRadius: 2)]
              : null,
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
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: filled ? Colors.black : Colors.white,
      backgroundColor: filled ? _uoscAccentLight : Colors.white.withAlpha(16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(12),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withAlpha(22)),
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
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: _uoscAccentLight,
          inactiveThumbColor: Colors.white70,
          inactiveTrackColor: Colors.white24,
        ),
      ],
    ),
  );
}

class _AudioTracksDialog extends StatelessWidget {
  final Stream<Tracks> tracksStream;
  final Stream<Track> trackStream;
  final Tracks initialTracks;
  final Track initialTrack;
  final ValueChanged<AudioTrack> onSelect;

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
    child: StreamBuilder<Tracks>(
      stream: tracksStream,
      initialData: initialTracks,
      builder: (context, tracksSnap) => StreamBuilder<Track>(
        stream: trackStream,
        initialData: initialTrack,
        builder: (context, trackSnap) {
          final tracks = tracksSnap.data?.audio ?? const <AudioTrack>[];
          final selected = trackSnap.data?.audio ?? initialTrack.audio;
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
                  selected: track == selected,
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
  final AudioTrack track;
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
              : (selected ? _uoscAccentLight.withAlpha(120) : Colors.white.withAlpha(20)),
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

String _audioTrackTitle(AudioTrack track) {
  if (track.id == 'auto') return 'Auto';
  if (track.id == 'no') return 'Disabled';
  final title = track.title?.trim();
  if (title != null && title.isNotEmpty) return title;
  final language = track.language?.trim();
  if (language != null && language.isNotEmpty) return language.toUpperCase();
  return 'Audio ${track.id}';
}

String _audioTrackSubtitle(AudioTrack track) {
  if (track.id == 'auto') return 'Let the player choose the best track.';
  if (track.id == 'no') return 'Disable audio output.';
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
  } else if (track.channelscount != null) {
    parts.add('${track.channelscount} channels');
  }
  final samplerate = track.samplerate;
  if (samplerate != null && samplerate > 0) {
    parts.add('${(samplerate / 1000).toStringAsFixed(1)} kHz');
  }
  return parts.isEmpty ? 'Track id ${track.id}' : parts.join(' · ');
}
