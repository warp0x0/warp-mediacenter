import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Video;

import '../../models/media.dart';
import '../../theme/warp_theme.dart';
import '../../theme/warp_tokens.dart';
import '../shared/modal_focus_restore.dart';
import '../shared/tv_modal_chrome_scale.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TrailerDialog — plays YouTube trailers via media_kit (libmpv).
// ─────────────────────────────────────────────────────────────────────────────

class TrailerDialog extends ConsumerStatefulWidget {
  final String trailerUrl;
  final String title;
  final List<Trailer> trailers;

  const TrailerDialog({
    super.key,
    required this.trailerUrl,
    required this.title,
    this.trailers = const [],
  });

  @override
  ConsumerState<TrailerDialog> createState() => _TrailerDialogState();
}

class _TrailerDialogState extends ConsumerState<TrailerDialog>
    with WidgetsBindingObserver, ModalFocusRestore<TrailerDialog> {
  late final Player _player;
  late final VideoController _controller;
  final _surfaceFocus = FocusNode(debugLabel: 'TrailerVideoSurface');
  final _selectorScroll = ScrollController();
  final _selectorRailFocus = FocusNode(debugLabel: 'TrailerSelectorScrollRail');
  final List<FocusNode> _selectorFocusNodes = [];
  StreamSubscription<String>? _playerErrorSub;

  bool _loading = true;
  bool _selectorOpen = false;
  String? _error;
  int _selectedIndex = 0;
  int _loadGeneration = 0;
  late List<Trailer> _orderedTrailers;

  List<Trailer> get _trailers => _orderedTrailers;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _playerErrorSub = _player.stream.error.listen((message) {
      if (!mounted || _loading) return;
      setState(() => _error = message);
    });
    _orderedTrailers = _buildOrderedTrailers();
    _selectedIndex = 0;
    _syncSelectorFocusNodes();
    _loadTrailer(_selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Dpad.of(context).requestFocus(_surfaceFocus);
    });
  }

  @override
  void didUpdateWidget(TrailerDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trailers.length != widget.trailers.length) {
      _orderedTrailers = _buildOrderedTrailers();
      if (_trailers.isEmpty) {
        _selectedIndex = 0;
      } else {
        _selectedIndex = _selectedIndex.clamp(0, _trailers.length - 1).toInt();
      }
      _syncSelectorFocusNodes();
    }
  }

  @override
  void dispose() {
    _surfaceFocus.dispose();
    _selectorScroll.dispose();
    _selectorRailFocus.dispose();
    for (final node in _selectorFocusNodes) {
      node.dispose();
    }
    _playerErrorSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _syncSelectorFocusNodes() {
    while (_selectorFocusNodes.length > _trailers.length) {
      _selectorFocusNodes.removeLast().dispose();
    }
    while (_selectorFocusNodes.length < _trailers.length) {
      final index = _selectorFocusNodes.length;
      _selectorFocusNodes.add(FocusNode(debugLabel: 'TrailerOption-$index'));
    }
  }

  List<Trailer> _buildOrderedTrailers() {
    final source = widget.trailers.isNotEmpty
        ? widget.trailers
        : [Trailer(url: widget.trailerUrl)];
    return source.reversed.toList(growable: false);
  }

  void _close() {
    if (_selectorOpen) {
      setState(() => _selectorOpen = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Dpad.of(context).requestFocus(_surfaceFocus);
      });
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _loadTrailer(int index) async {
    if (index < 0 || index >= _trailers.length) return;
    final generation = ++_loadGeneration;
    setState(() {
      _selectedIndex = index;
      _loading = true;
      _error = null;
    });

    try {
      final streams = await _extractStreams(_trailers[index].url);
      if (!mounted || generation != _loadGeneration) return;

      await _openStreams(streams);
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Dpad.of(context).requestFocus(_surfaceFocus);
      });
    } catch (e) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _error = 'Could not load trailer. ($e)';
      });
    }
  }

  Future<void> _openStreams(_TrailerStreams streams) async {
    if (streams.audioUrl != null) {
      try {
        await _openSeparateStreams(streams.videoUrl, streams.audioUrl!);
        return;
      } catch (_) {
        if (streams.muxedUrl == null) rethrow;
      }
    }
    final fallbackUrl = streams.muxedUrl ?? streams.videoUrl;
    await _player.open(Media(fallbackUrl), play: true);
  }

  Future<void> _openSeparateStreams(String videoUrl, String audioUrl) async {
    await _controller.player.open(Media(videoUrl));
    await _controller.player.setAudioTrack(
      AudioTrack.uri(audioUrl, title: 'YouTube audio'),
    );
  }

  Future<_TrailerStreams> _extractStreams(String youtubeUrl) async {
    final yt = YoutubeExplode();
    try {
      final videoId = VideoId(youtubeUrl);
      final manifest = await yt.videos.streams.getManifest(
        videoId,
        ytClients: [YoutubeApiClient.safari, YoutubeApiClient.androidVr],
      );
      final videoOnly = manifest.videoOnly;
      final audioOnly = manifest.audioOnly;
      final muxed = manifest.muxed;
      debugPrint(
        'Manifest loaded for $videoId: videoOnly=${videoOnly.length}, audioOnly=${audioOnly.length}, muxed=${muxed.length}',
      );
      final muxedUrl = muxed.isNotEmpty
          ? muxed.withHighestBitrate().url.toString()
          : null;
      if (videoOnly.isNotEmpty && audioOnly.isNotEmpty) {
        final bestVideo = videoOnly.withHighestBitrate().url;
        final bestAudio = audioOnly.withHighestBitrate().url;
        return _TrailerStreams(
          bestVideo.toString(),
          audioUrl: bestAudio.toString(),
          muxedUrl: muxedUrl,
        );
      }

      if (muxedUrl != null) {
        return _TrailerStreams(muxedUrl, muxedUrl: muxedUrl);
      }
      if (videoOnly.isNotEmpty) {
        return _TrailerStreams(videoOnly.withHighestBitrate().url.toString());
      }
      throw Exception('No playable stream found');
    } finally {
      yt.close();
    }
  }

  void _togglePlayPause() {
    _player.state.playing
        ? unawaited(_player.pause())
        : unawaited(_player.play());
    setState(() {});
  }

  void _seek(int seconds) {
    final next = _player.state.position + Duration(seconds: seconds);
    unawaited(_player.seek(next.isNegative ? Duration.zero : next));
  }

  void _adjustVolume(double delta) {
    final next = (_player.state.volume + delta).clamp(0.0, 100.0);
    unawaited(_player.setVolume(next));
    setState(() {});
  }

  bool _surfaceDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.left) {
      _seek(-10);
      return true;
    }
    if (direction == TraversalDirection.right) {
      _seek(10);
      return true;
    }
    if (direction == TraversalDirection.up) {
      if (_selectorOpen) {
        Dpad.of(context).requestFocus(_selectorFocusNodes[_selectedIndex]);
        return true;
      }
      _adjustVolume(10);
      return true;
    }
    if (direction == TraversalDirection.down) {
      if (_selectorOpen) {
        Dpad.of(context).requestFocus(_selectorFocusNodes[_selectedIndex]);
        return true;
      }
      _adjustVolume(-10);
      return true;
    }
    return true;
  }

  void _openSelector() {
    if (_trailers.length <= 1) return;
    _syncSelectorFocusNodes();
    setState(() => _selectorOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollSelectedTrailerIntoView();
    });
  }

  void _selectTrailer(int index) {
    setState(() => _selectorOpen = false);
    unawaited(_loadTrailer(index));
  }

  bool _selectorItemDirection(int index, TraversalDirection direction) {
    if (direction == TraversalDirection.right) {
      Dpad.of(context).requestFocus(_selectorRailFocus);
      return true;
    }
    if (direction == TraversalDirection.left) return true;
    return false;
  }

  bool _selectorRailDirection(TraversalDirection direction) {
    if (direction == TraversalDirection.left) {
      _focusNearestSelectorItem();
      return true;
    }
    if (direction == TraversalDirection.up ||
        direction == TraversalDirection.down) {
      _scrollSelector(direction == TraversalDirection.down ? 120 : -120);
      return true;
    }
    return true;
  }

  void _scrollSelector(double delta) {
    if (!_selectorScroll.hasClients) return;
    final position = _selectorScroll.position;
    final target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    _selectorScroll.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollSelectedTrailerIntoView() {
    if (!_selectorScroll.hasClients || _trailers.isEmpty) return;
    const rowExtent = 60.0;
    final position = _selectorScroll.position;
    final itemTop = _selectedIndex * rowExtent;
    final itemBottom = itemTop + rowExtent;
    final viewportTop = position.pixels;
    final viewportBottom = viewportTop + position.viewportDimension;

    double? target;
    if (itemTop < viewportTop) {
      target = itemTop;
    } else if (itemBottom > viewportBottom) {
      target = itemBottom - position.viewportDimension;
    }
    if (target == null) return;

    _selectorScroll.jumpTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  void _focusNearestSelectorItem() {
    if (_selectorFocusNodes.isEmpty) return;
    final offset = _selectorScroll.hasClients ? _selectorScroll.offset : 0.0;
    final index = (offset / 56)
        .round()
        .clamp(0, _selectorFocusNodes.length - 1)
        .toInt();
    Dpad.of(context).requestFocus(_selectorFocusNodes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final w = (size.width * 0.90).clamp(480.0, 1100.0);
    final h = w * 9 / 16 + 56;
    final hasMultipleTrailers = _trailers.length > 1;

    return PopScope(
      canPop: true,
      child: Material(
        color: Colors.black.withAlpha(200),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): _close,
            const SingleActivator(LogicalKeyboardKey.backspace): _close,
            const SingleActivator(LogicalKeyboardKey.goBack): _close,
            const SingleActivator(LogicalKeyboardKey.browserBack): _close,
            const SingleActivator(LogicalKeyboardKey.mediaPlayPause):
                _togglePlayPause,
            const SingleActivator(LogicalKeyboardKey.mediaRewind): () =>
                _seek(-10),
            const SingleActivator(LogicalKeyboardKey.mediaFastForward): () =>
                _seek(10),
          },
          child: DpadRegion(
            memoryKey: 'modal-trailer',
            horizontalEdge: DpadEdgeBehavior.stop,
            verticalEdge: DpadEdgeBehavior.stop,
            child: TvModalChromeScale(
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: w,
                      height: h,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 48,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: t.fontBody,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    hasMultipleTrailers
                                        ? 'Hold Select: Trailers'
                                        : 'Select: Play/Pause',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(120),
                                      fontSize: t.fontSubtitle.clamp(
                                        11.0,
                                        13.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                              child: DpadFocusable(
                                focusNode: _surfaceFocus,
                                autofocus: true,
                                entry: true,
                                onDirection: _surfaceDirection,
                                onSelect: _togglePlayPause,
                                onLongSelect: _openSelector,
                                tapToSelect: false,
                                builder: (context, state, child) =>
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: state.focused
                                              ? WarpColors.accent.withAlpha(190)
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: child,
                                    ),
                                child: _loading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF0DB2E2),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : _error != null
                                    ? _ErrorBody(
                                        message: _error!,
                                        url: _trailers[_selectedIndex].url,
                                        t: t,
                                      )
                                    : GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: _togglePlayPause,
                                        onLongPress: _openSelector,
                                        child: Video(
                                          controller: _controller,
                                          controls: NoVideoControls,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectorOpen) _buildSelectorOverlay(t),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorOverlay(WarpTokens t) {
    return Positioned.fill(
      child: DpadRegion(
        memoryKey: 'modal-trailer-selector',
        horizontalEdge: DpadEdgeBehavior.stop,
        verticalEdge: DpadEdgeBehavior.stop,
        child: Container(
          color: Colors.black.withAlpha(180),
          alignment: Alignment.center,
          child: Container(
            width: 420,
            constraints: const BoxConstraints(maxHeight: 440),
            decoration: BoxDecoration(
              color: const Color(0xFA121218),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.movie_filter_outlined,
                        color: Color(0xFF0DB2E2),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Select Trailer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: t.fontBody,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Back closes list',
                        style: TextStyle(
                          color: Colors.white.withAlpha(90),
                          fontSize: t.fontSubtitle.clamp(10.0, 12.0),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _selectorScroll,
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(18, 0, 44, 18),
                        itemCount: _trailers.length,
                        itemBuilder: (context, index) => _TrailerOptionRow(
                          index: index,
                          selected: index == _selectedIndex,
                          trailer: _trailers[index],
                          focusNode: _selectorFocusNodes[index],
                          onDirection: (direction) =>
                              _selectorItemDirection(index, direction),
                          onSelect: () => _selectTrailer(index),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 10,
                        bottom: 18,
                        child: _TrailerSelectorScrollRail(
                          focusNode: _selectorRailFocus,
                          onDirection: _selectorRailDirection,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrailerStreams {
  final String videoUrl;
  final String? audioUrl;
  final String? muxedUrl;

  const _TrailerStreams(this.videoUrl, {this.audioUrl, this.muxedUrl});
}

class _TrailerOptionRow extends StatelessWidget {
  final int index;
  final bool selected;
  final Trailer trailer;
  final FocusNode focusNode;
  final DpadDirectionCallback onDirection;
  final VoidCallback onSelect;

  const _TrailerOptionRow({
    required this.index,
    required this.selected,
    required this.trailer,
    required this.focusNode,
    required this.onDirection,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DpadFocusable(
        focusNode: focusNode,
        autofocus: selected,
        entry: selected,
        onDirection: onDirection,
        onSelect: onSelect,
        tapToSelect: false,
        builder: (context, state, child) => GestureDetector(
          onTap: onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: state.focused
                  ? const Color(0xFF0DB2E2)
                  : selected
                  ? const Color(0x220DB2E2)
                  : Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: state.focused
                    ? Colors.white
                    : selected
                    ? const Color(0xFF0DB2E2)
                    : Colors.white.withAlpha(20),
                width: state.focused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: selected
                      ? const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 18,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: state.focused
                                ? Colors.white
                                : Colors.white.withAlpha(120),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Trailer ${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: state.focused || selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (trailer.quality?.isNotEmpty == true)
                  Text(
                    trailer.quality!,
                    style: TextStyle(
                      color: state.focused
                          ? Colors.white.withAlpha(220)
                          : const Color(0xFF0DB2E2),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _TrailerSelectorScrollRail extends StatelessWidget {
  final FocusNode focusNode;
  final DpadDirectionCallback onDirection;

  const _TrailerSelectorScrollRail({
    required this.focusNode,
    required this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Center(
        child: DpadFocusable(
          focusNode: focusNode,
          onDirection: onDirection,
          onSelect: () {},
          tapToSelect: false,
          builder: (context, state, child) => AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: state.focused ? 8 : 4,
            height: 112,
            decoration: BoxDecoration(
              color: state.focused
                  ? const Color(0xFF0DB2E2)
                  : Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(999),
              boxShadow: state.focused
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0DB2E2).withAlpha(120),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
          child: const SizedBox.shrink(),
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
          const Icon(
            Icons.play_circle_outline,
            color: Colors.white38,
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.white54, fontSize: t.fontSubtitle),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Trailer URL:',
            style: TextStyle(color: Colors.white38, fontSize: t.fontSubtitle),
          ),
          const SizedBox(height: 4),
          SelectableText(
            url,
            style: TextStyle(
              color: const Color(0xFF0DB2E2),
              fontSize: t.fontSubtitle,
            ),
          ),
        ],
      ),
    );
  }
}
