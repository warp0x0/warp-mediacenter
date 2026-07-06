import 'dart:async';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/api_client.dart';
import '../../models/torrent.dart';
import '../../models/preload.dart';
import '../../models/debrid.dart';
import '../../theme/warp_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TorrentDialog — search → resolve → poll → stream → preload → navigate
//
// API flow (matches Tauri exactly):
//   1. POST /api/v1/torrent/search  → filtered + unfiltered lists
//   2. POST /api/v1/torrent/resolve (media_type, no magnet) → torrent_id
//   3. Poll GET /api/v1/torrent/status/{id} until 'downloaded'|'finished'
//   4. GET /api/v1/debrid/torrent/{id} → file list, pick best video file
//   5. GET /api/v1/debrid/stream/{id}/{file.id} → stream_url
//   6. POST /api/v1/player/preload/session → playback_url → push /playback
// ─────────────────────────────────────────────────────────────────────────────

enum _BannerKind { info, progress, success, error }

class _BannerState {
  final _BannerKind kind;
  final String text;
  final String? subtext;
  const _BannerState(this.kind, this.text, {this.subtext});
}

enum _LocalConfirmReason { preBlocked, runtimeBlocked }

class TorrentDialog extends ConsumerStatefulWidget {
  final String title;
  final String mediaKind; // 'movie' | 'tv'
  final String? tmdbId;
  final int? year;
  final int? season;
  final int? episode;
  final double? resumePercent;
  final void Function(Map<String, dynamic> payload)? onPlaybackReady;
  final VoidCallback onClose;

  const TorrentDialog({
    super.key,
    required this.title,
    required this.mediaKind,
    required this.onClose,
    this.tmdbId,
    this.year,
    this.season,
    this.episode,
    this.resumePercent,
    this.onPlaybackReady,
  });

  @override
  ConsumerState<TorrentDialog> createState() => _TorrentDialogState();
}

class _TorrentDialogState extends ConsumerState<TorrentDialog> {
  final _searchCtrl = TextEditingController();
  final _searchFieldFocus = FocusNode(debugLabel: 'TorrentSearchField');
  final _searchWrapperFocus = FocusNode(debugLabel: 'TorrentSearchWrapper');
  final _searchBtnFocus = FocusNode(debugLabel: 'TorrentSearchBtn');
  final _localConfirmCancelFocus = FocusNode(debugLabel: 'LocalConfirmCancel');
  List<FocusNode> _resultFocusNodes = [];

  List<TorrentResult> _results = [];
  Set<String> _rdSafeHashes = {};
  bool _searching = false;
  bool _resolving = false;
  bool _hasSearched = false;
  _BannerState? _banner;
  bool _cancelled = false;
  String?
  _preloadSessionId; // set while preload polling is active (used by cancel)

  // Local confirm overlay (RD-blocked path)
  TorrentResult? _localConfirmResult;
  _LocalConfirmReason? _localConfirmReason;

  static const _videoExts = {
    '.mkv',
    '.mp4',
    '.avi',
    '.m2ts',
    '.ts',
    '.mov',
    '.wmv',
    '.m4v',
    '.iso',
    '.vob',
    '.mpg',
    '.mpeg',
  };
  static const _archiveExts = {
    '.rar',
    '.zip',
    '.7z',
    '.gz',
    '.tar',
    '.001',
    '.r01',
    '.r00',
  };

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.title;
    WidgetsBinding.instance.addPostFrameCallback((_) => _doSearch());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFieldFocus.dispose();
    _searchWrapperFocus.dispose();
    _searchBtnFocus.dispose();
    _localConfirmCancelFocus.dispose();
    for (final fn in _resultFocusNodes) {
      fn.dispose();
    }
    super.dispose();
  }

  void _syncResultFocusNodes() {
    for (final fn in _resultFocusNodes) {
      fn.dispose();
    }
    _resultFocusNodes = List.generate(_results.length, (_) => FocusNode());
  }

  ApiClient get _client => ref.read(apiClientProvider);

  bool get _isBusy => _searching || _resolving;

  // ── Search ──────────────────────────────────────────────────────────────────

  Future<void> _doSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _hasSearched = true;
      _results = [];
      _rdSafeHashes = {};
      _banner = null;
    });

    try {
      final raw = await _client.post<Map<String, dynamic>>(
        '/api/v1/torrent/search',
        body: {
          'query': q,
          'media_type': widget.mediaKind,
          if (widget.tmdbId != null) 'tmdb_id': widget.tmdbId,
          if (widget.season != null) 'season': widget.season,
          if (widget.episode != null) 'episode': widget.episode,
          if (widget.year != null) 'year': widget.year,
          'limit': 24,
        },
      );
      final resp = TorrentSearchResponse.fromJson(raw);
      final filtered = resp.filtered;
      final unfiltered = resp.unfiltered;
      final safeHashes = filtered.map((r) => r.hash).toSet();
      final blockedCount = unfiltered.length - filtered.length;

      setState(() {
        _results = unfiltered;
        _rdSafeHashes = safeHashes;
        if (unfiltered.isEmpty) {
          _banner = const _BannerState(
            _BannerKind.info,
            'No results found — try a different query.',
          );
        } else {
          final parts = [
            '${unfiltered.length} source${unfiltered.length != 1 ? 's' : ''} found',
          ];
          final sub = blockedCount > 0 ? '$blockedCount RD-blocked' : null;
          _banner = _BannerState(_BannerKind.info, parts[0], subtext: sub);
        }
      });
      _syncResultFocusNodes();
      if (_resultFocusNodes.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _resultFocusNodes[0].requestFocus();
        });
      }
    } catch (e) {
      setState(
        () => _banner = _BannerState(
          _BannerKind.error,
          'Search failed',
          subtext: _msg(e),
        ),
      );
    } finally {
      setState(() => _searching = false);
    }
  }

  // ── Resolve (RD path) ────────────────────────────────────────────────────────

  Future<void> _pickTorrent(TorrentResult result) async {
    _cancelled = false;
    setState(() {
      _resolving = true;
      _banner = _BannerState(
        _BannerKind.progress,
        'Resolving torrent…',
        subtext: result.name,
      );
    });

    try {
      final resolveRaw = await _client.post<Map<String, dynamic>>(
        '/api/v1/torrent/resolve',
        body: {
          'torrent_hash': result.hash, // backend key is torrent_hash, not hash
          'title': widget.title,
          'media_type': widget.mediaKind, // NOTE: media_type, not media_kind
          if (widget.tmdbId != null) 'tmdb_id': widget.tmdbId,
          if (widget.season != null) 'season': widget.season,
          if (widget.episode != null) 'episode': widget.episode,
          if (widget.year != null) 'year': widget.year,
        },
      );
      if (_cancelled) return;

      final resolve = TorrentResolveResponse.fromJson(resolveRaw);
      final streamUrl = await _waitForStream(resolve.torrentId);
      if (_cancelled || streamUrl == null) return;

      await _startPreload(streamUrl);
    } catch (e) {
      if (_cancelled) return;
      final msg = _msg(e);
      final isBlocked =
          msg.toLowerCase().contains('infringing') ||
          msg.toLowerCase().contains('dmca') ||
          (e is ApiError && e.statusCode == 422);
      if (isBlocked) {
        setState(() {
          _localConfirmResult = result;
          _localConfirmReason = _LocalConfirmReason.runtimeBlocked;
          _banner = null;
        });
      } else {
        setState(
          () => _banner = _BannerState(
            _BannerKind.error,
            'Resolution failed',
            subtext: msg,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  // ── Wait for RD download ─────────────────────────────────────────────────────

  Future<String?> _waitForStream(String torrentId) async {
    for (var i = 0; i < 20; i++) {
      if (_cancelled) return null;

      final statusRaw = await _client.get<Map<String, dynamic>>(
        '/api/v1/torrent/status/$torrentId',
      );
      if (_cancelled) return null;

      // Parse manually — backend omits speed/seeders/etc. in some states,
      // so TorrentStatus.fromJson would crash on the non-null num casts.
      final rdStatus = statusRaw['status'] as String? ?? 'unknown';
      final progress = (statusRaw['progress'] as num?)?.toDouble() ?? 0.0;
      final speed = (statusRaw['speed'] as num?)?.toDouble() ?? 0.0;
      final seeders = (statusRaw['seeders'] as num?)?.toInt() ?? 0;
      final message = statusRaw['message'] as String? ?? '';

      final parts = <String>['Status: $rdStatus'];
      if (progress > 0) parts.add('${progress.toStringAsFixed(0)}%');
      if (speed > 0) {
        parts.add('${(speed / 1024 / 1024).toStringAsFixed(1)} MB/s');
      }
      if (seeders > 0) parts.add('$seeders seeders');

      if (!mounted) return null;
      setState(
        () => _banner = _BannerState(
          _BannerKind.progress,
          'Caching on Real-Debrid…',
          subtext: parts.join('  ·  '),
        ),
      );

      if (rdStatus == 'downloaded' || rdStatus == 'finished') {
        // Get file list and pick the best video file
        final infoRaw = await _client.get<Map<String, dynamic>>(
          '/api/v1/debrid/torrent/$torrentId',
        );
        if (_cancelled) return null;

        final info = DebridTorrentInfo.fromJson(infoRaw);
        final selectedFiles = info.files.where((f) => f.selected == 1).toList();

        String fileExt(DebridTorrentFile f) {
          final dot = f.path.lastIndexOf('.');
          return dot >= 0 ? f.path.substring(dot).toLowerCase() : '';
        }

        final videoFiles =
            selectedFiles.where((f) => _videoExts.contains(fileExt(f))).toList()
              ..sort((a, b) => b.bytes.compareTo(a.bytes));

        final file = videoFiles.isNotEmpty
            ? videoFiles.first
            : (selectedFiles.isNotEmpty
                  ? selectedFiles.first
                  : info.files.firstOrNull);
        if (file == null) return null;

        final streamRaw = await _client.get<Map<String, dynamic>>(
          '/api/v1/debrid/stream/$torrentId/${file.id}',
        );
        if (_cancelled) return null;

        final streamResp = DebridStreamResponse.fromJson(streamRaw);
        final ext =
            streamResp.streamUrl
                .split('?')[0]
                .split('.')
                .lastOrNull
                ?.toLowerCase() ??
            '';
        if (_archiveExts.contains('.$ext')) {
          throw Exception(
            'This release is packaged as a RAR/ZIP archive and cannot be streamed. Try a different source.',
          );
        }
        return streamResp.streamUrl;
      }

      if (['error', 'dead', 'unknown'].contains(rdStatus)) {
        throw Exception(
          message.isNotEmpty ? message : 'Torrent status: $rdStatus',
        );
      }

      await Future.delayed(const Duration(seconds: 3));
    }
    throw Exception(
      'Timed out waiting for Real-Debrid — torrent may be slow or unavailable.',
    );
  }

  // ── Local libtorrent path ────────────────────────────────────────────────────

  Future<void> _pickLocalTorrent(TorrentResult result) async {
    setState(() {
      _localConfirmResult = null;
      _localConfirmReason = null;
      _resolving = true;
      _banner = const _BannerState(
        _BannerKind.progress,
        'Downloading the entire Torrent file…',
        subtext: 'Fetching torrent metadata…',
      );
    });
    _cancelled = false;

    try {
      final raw = await _client.post<Map<String, dynamic>>(
        '/api/v1/player/preload/session',
        body: {
          'magnet': result.magnet,
          'title': widget.title,
          'media_kind': widget.mediaKind,
          'start_percent': widget.resumePercent ?? 0,
        },
      );
      if (_cancelled || !mounted) return;

      final session = PreloadSessionCreateResponse.fromJson(raw);
      await _pollPreload(session, fallbackUrl: session.playbackUrl);
    } catch (e) {
      if (mounted) {
        setState(
          () => _banner = _BannerState(
            _BannerKind.error,
            'Local download failed',
            subtext: _msg(e),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  // ── Start preload session → poll → navigate ───────────────────────────────────

  Future<void> _startPreload(String streamUrl) async {
    if (!mounted) return;
    setState(
      () => _banner = const _BannerState(
        _BannerKind.progress,
        'Preparing stream…',
      ),
    );

    PreloadSessionCreateResponse? session;
    try {
      final raw = await _client.post<Map<String, dynamic>>(
        '/api/v1/player/preload/session',
        body: {
          'stream_url': streamUrl,
          'title': widget.title,
          'media_kind': widget.mediaKind,
          'start_percent': widget.resumePercent ?? 0,
        },
      );
      if (_cancelled || !mounted) return;

      session = PreloadSessionCreateResponse.fromJson(raw);
      await _pollPreload(session, fallbackUrl: streamUrl);
    } catch (_) {
      // Preload session creation failed — navigate directly to stream URL
      if (_cancelled || !mounted) return;
      _navigateToPlayback(source: streamUrl, sessionId: session?.sessionId);
    }
  }

  // ── Shared preload polling ─────────────────────────────────────────────────────
  // Polls GET /api/v1/player/preload/session/{id}/status every 1s.
  // CDN/RD:    fires when percent >= 20 OR download_complete
  // libtorrent: fires only when download_complete (needs full file on disk)

  Future<void> _pollPreload(
    PreloadSessionCreateResponse session, {
    required String fallbackUrl,
  }) async {
    setState(() => _preloadSessionId = session.sessionId);

    var pollCount = 0;
    var detectedLocalTorrent = false;

    while (true) {
      if (_cancelled || !mounted) return;

      try {
        final raw = await _client.get<Map<String, dynamic>>(
          '/api/v1/player/preload/session/${session.sessionId}/status',
        );
        if (_cancelled || !mounted) return;

        final state = raw['state'] as String? ?? 'buffering';
        final pct = (raw['percent'] as num?)?.toDouble() ?? 0.0;
        final bytesDownloaded = (raw['bytes_downloaded'] as num?)?.toInt() ?? 0;
        final totalSize = (raw['total_size'] as num?)?.toInt() ?? 0;
        final remainingSize = (raw['remaining_size'] as num?)?.toInt() ?? 0;
        final downloadComplete = raw['download_complete'] as bool? ?? false;
        final isLocalTorrent = raw['local_torrent'] as bool? ?? false;
        final filePath = raw['file_path'] as String?;
        final downloadRateKb =
            (raw['download_rate_kb'] as num?)?.toDouble() ?? 0.0;
        final numPeers = (raw['num_peers'] as num?)?.toInt() ?? 0;
        final errorMsg = raw['error'] as String?;

        if (isLocalTorrent) detectedLocalTorrent = true;

        if (state == 'error') {
          setState(() {
            _preloadSessionId = null;
            _banner = _BannerState(
              _BannerKind.error,
              'Buffering failed',
              subtext: errorMsg ?? 'Unknown preload error',
            );
          });
          return;
        }

        // For libtorrent: show 1 decimal (e.g. 87.2%), capped at 99.9 until
        // download_complete fires — prevents 99.8 rounding to "100%" prematurely.
        final displayPct = isLocalTorrent
            ? (downloadComplete
                  ? '100.0'
                  : pct.clamp(0.0, 99.9).toStringAsFixed(1))
            : pct.round().toString();

        final String subtext;
        if (isLocalTorrent) {
          final mbDl = (bytesDownloaded / 1024 / 1024).toStringAsFixed(1);
          final mbTot = totalSize > 0
              ? (totalSize / 1024 / 1024).toStringAsFixed(1)
              : '?';
          final speed = downloadRateKb >= 1024
              ? '${(downloadRateKb / 1024).toStringAsFixed(1)} MBps'
              : '${downloadRateKb.toStringAsFixed(1)} KBps';
          subtext =
              'Progress: $displayPct%  |  Downloaded: $mbDl / $mbTot MB  |  Down Speed: $speed'
              '${numPeers > 0 ? "  |  Peers: $numPeers" : ""}';
        } else {
          final mbDl = (bytesDownloaded / 1024 / 1024).toStringAsFixed(0);
          final denom = remainingSize > 0 ? remainingSize : totalSize;
          final mbTot = denom > 0
              ? ' / ${(denom / 1024 / 1024).toStringAsFixed(0)} MB'
              : '';
          subtext = '$displayPct%  ·  $mbDl$mbTot MB';
        }

        setState(
          () => _banner = _BannerState(
            _BannerKind.progress,
            isLocalTorrent
                ? 'Downloading the entire Torrent file…'
                : 'Downloading initial bytes (20%) for smooth playback…',
            subtext: subtext,
          ),
        );

        final streamReady = isLocalTorrent
            ? downloadComplete
            : (pct >= 20 || downloadComplete);

        if (streamReady) {
          if (!mounted) return;
          setState(() => _preloadSessionId = null);

          // For libtorrent: the file is fully on disk — stream it directly via
          // the local file endpoint (same path used for library file playback).
          // This gives libmpv proper Content-Type from extension + full Range
          // support without going through the preload session proxy.
          String source;
          if (isLocalTorrent && filePath != null && filePath.isNotEmpty) {
            final base = _client.dio.options.baseUrl.replaceAll(
              RegExp(r'/$'),
              '',
            );
            // Strip leading '/' so the URL is stream/tmp/... not stream//tmp/...
            final relPath = filePath.startsWith('/')
                ? filePath.substring(1)
                : filePath;
            source = '$base/api/v1/stream/${Uri.encodeFull(relPath)}';
          } else {
            source = session.localUrl ?? session.playbackUrl;
          }

          _navigateToPlayback(source: source, sessionId: session.sessionId);
          return;
        }
      } catch (_) {
        // Transient poll error — keep retrying
      }

      pollCount++;
      // Libtorrent downloads the full file — no fixed timeout; the user cancels
      // via the Cancel button if they want to abort. Only the CDN/RD path gets a
      // 2-minute cap and then falls through to direct playback.
      if (!detectedLocalTorrent && pollCount >= 120) break;

      await Future.delayed(const Duration(seconds: 1));
    }

    // Timeout (RD/CDN path only) — fall through to direct playback
    if (!mounted) return;
    setState(() => _preloadSessionId = null);
    _navigateToPlayback(source: fallbackUrl, sessionId: session.sessionId);
  }

  // ── Navigate to playback ──────────────────────────────────────────────────────

  void _navigateToPlayback({required String source, String? sessionId}) {
    // resumePercent is 0–100 from Trakt; PlaybackPage expects resumeFromFrac as 0.0–1.0
    final resumeFromFrac = widget.resumePercent != null
        ? widget.resumePercent! / 100.0
        : null;
    final payload = {
      'source': source,
      'title': widget.title,
      'mediaType': widget.mediaKind == 'tv' ? 'show' : 'movie',
      'tmdbId': widget.tmdbId,
      'season': widget.season,
      'episode': widget.episode,
      'sessionId': sessionId,
      'resumeFromFrac': resumeFromFrac,
    };

    widget.onClose();
    final onPlaybackReady = widget.onPlaybackReady;
    if (onPlaybackReady != null) {
      onPlaybackReady(payload);
    } else {
      context.push('/playback', extra: payload);
    }
  }

  // ── Cancel ───────────────────────────────────────────────────────────────────

  void _handleCancel() {
    _cancelled = true;
    final sid = _preloadSessionId;
    if (sid != null) {
      _client.delete('/api/v1/player/preload/session/$sid').ignore();
      _preloadSessionId = null;
    }
    setState(() {
      _resolving = false;
      _banner = null;
    });
  }

  String _msg(Object e) {
    if (e is ApiError) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = WarpTokens.watch(context, ref);
    final size = MediaQuery.sizeOf(context);
    final episodeTag = widget.mediaKind == 'tv' && widget.season != null
        ? '  ·  S${widget.season.toString().padLeft(2, '0')}E${(widget.episode ?? 1).toString().padLeft(2, '0')}'
        : '';

    return Material(
      color: Colors.black.withAlpha(190),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
        },
        child: DpadRegion(
          memoryKey: 'modal-torrent',
          horizontalEdge: DpadEdgeBehavior.stop,
          verticalEdge: DpadEdgeBehavior.stop,
          child: Stack(
            children: [
              // Main dialog
              Center(
                child: Container(
                  width: (size.width * 0.62).clamp(520.0, 900.0),
                  constraints: BoxConstraints(maxHeight: size.height * 0.82),
                  decoration: BoxDecoration(
                    color: const Color(0xF7000000).withAlpha(247),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(23)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Accent top stripe
                        Container(
                          height: 3,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0DB2E2), Color(0x1F0DB2E2)],
                            ),
                          ),
                        ),

                        // Header
                        _buildHeader(t, episodeTag),

                        // Search bar
                        _buildSearchBar(t),

                        // Banner
                        if (_banner != null) _buildBanner(_banner!, t),

                        // Scrollable body
                        Flexible(child: _buildBody(t)),
                      ],
                    ),
                  ),
                ),
              ),

              // Local confirm overlay — an in-page overlay (not a routed dialog),
              // so it needs its own explicit DpadRegion trap; Dpad.wrap()'s
              // route-level isolation doesn't cover it automatically.
              if (_localConfirmResult != null)
                DpadRegion(
                  memoryKey: 'torrent-local-confirm',
                  horizontalEdge: DpadEdgeBehavior.stop,
                  verticalEdge: DpadEdgeBehavior.stop,
                  child: _buildLocalConfirmOverlay(t),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WarpTokens t, String episodeTag) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0DB2E2).withAlpha(50),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.cast, color: Color(0xFF0DB2E2), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Search Sources',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: t.fontSection.clamp(14.0, 18.0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${widget.title}$episodeTag',
                  style: TextStyle(
                    color: Colors.white.withAlpha(90),
                    fontSize: (t.fontSubtitle).clamp(11.0, 13.0),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          DpadFocusable(
            onSelect: widget.onClose,
            builder: (context, state, child) => Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: state.focused
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0DB2E2).withAlpha(140),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Icon(
                  Icons.close,
                  color: Colors.white.withAlpha(90),
                  size: 16,
                ),
              ),
            ),
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(WarpTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          Expanded(
            // Outer wrapper is the D-pad-navigable stop; Select transfers
            // real focus onto the bare TextField (native dpad text-edit
            // arrow handling takes over from there).
            child: DpadFocusable(
              focusNode: _searchWrapperFocus,
              autofocus: true,
              entry: true,
              excludeChildFocus: false,
              onSelect: () => _searchFieldFocus.requestFocus(),
              builder: (context, state, child) => AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: state.focused
                        ? const Color(0xFF0DB2E2)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: child,
              ),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFieldFocus,
                style: TextStyle(color: Colors.white, fontSize: t.fontBody),
                onSubmitted: (_) => _isBusy ? null : _doSearch(),
                decoration: InputDecoration(
                  hintText: 'Search sources…',
                  hintStyle: TextStyle(
                    color: Colors.white38,
                    fontSize: t.fontBody,
                  ),
                  filled: true,
                  fillColor: Colors.white.withAlpha(13),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withAlpha(30)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withAlpha(30)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: Color(0xFF0DB2E2)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          DpadFocusable(
            focusNode: _searchBtnFocus,
            enabled: !_isBusy,
            onSelect: _doSearch,
            builder: (context, state, child) => GestureDetector(
              onTap: _isBusy ? null : _doSearch,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isBusy ? 0.6 : 1.0,
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0DB2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: state.focused ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _searching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: t.fontBody,
                          ),
                        ),
                ),
              ),
            ),
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(_BannerState b, WarpTokens t) {
    final (bg, border, textColor) = switch (b.kind) {
      _BannerKind.info => (
        const Color(0x0AFFFFFF),
        const Color(0x14FFFFFF),
        const Color(0x99FFFFFF),
      ),
      _BannerKind.progress => (
        const Color(0x1201B4E4),
        const Color(0x3301B4E4),
        const Color(0xE601B4E4),
      ),
      _BannerKind.success => (
        const Color(0x1422C55E),
        const Color(0x4022C55E),
        const Color(0xFF4ADE80),
      ),
      _BannerKind.error => (
        const Color(0x14EF4444),
        const Color(0x40EF4444),
        const Color(0xFFF87171),
      ),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: switch (b.kind) {
                  _BannerKind.progress => SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 1.5,
                    ),
                  ),
                  _BannerKind.success => Icon(
                    Icons.check_circle_outline,
                    size: 13,
                    color: textColor,
                  ),
                  _BannerKind.error => Icon(
                    Icons.error_outline,
                    size: 13,
                    color: textColor,
                  ),
                  _BannerKind.info => Icon(
                    Icons.info_outline,
                    size: 13,
                    color: textColor.withAlpha(153),
                  ),
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      b.text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (b.subtext != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        b.subtext!,
                        style: TextStyle(
                          color: textColor.withAlpha(178),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (b.kind == _BannerKind.progress)
                DpadFocusable(
                  onSelect: _handleCancel,
                  builder: (context, state, child) => GestureDetector(
                    onTap: _handleCancel,
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: state.focused
                              ? Colors.white
                              : textColor.withAlpha(128),
                          width: state.focused ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close,
                            size: 10,
                            color: textColor.withAlpha(153),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Cancel',
                            style: TextStyle(
                              color: textColor.withAlpha(153),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  child: const SizedBox.shrink(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(WarpTokens t) {
    // Resolving state: only show banner (no results list)
    if (_resolving) return const SizedBox(height: 120);

    if (_searching) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0DB2E2),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return SizedBox(
        height: 160,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.cast,
                size: 24,
                color: Colors.white.withAlpha(50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter a query and press Search',
              style: TextStyle(
                color: Colors.white.withAlpha(76),
                fontSize: t.fontBody,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasSearched && _results.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'No sources found. Try a different query.',
            style: TextStyle(
              color: Colors.white.withAlpha(76),
              fontSize: t.fontBody,
            ),
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        itemCount: _results.length,
        itemBuilder: (_, i) {
          final result = _results[i];
          final isBlocked = !_rdSafeHashes.contains(result.hash);
          return _ResultRow(
            result: result,
            isRdBlocked: isBlocked,
            isBusy: _isBusy,
            focusNode: i < _resultFocusNodes.length
                ? _resultFocusNodes[i]
                : null,
            onTap: () {
              if (_isBusy) return;
              if (isBlocked) {
                setState(() {
                  _localConfirmResult = result;
                  _localConfirmReason = _LocalConfirmReason.preBlocked;
                });
              } else {
                _pickTorrent(result);
              }
            },
            t: t,
          );
        },
      ),
    );
  }

  Widget _buildLocalConfirmOverlay(WarpTokens t) {
    final result = _localConfirmResult!;
    final reason = _localConfirmReason!;

    return Positioned.fill(
      child: Container(
        color: const Color(0xE10A0A0E),
        alignment: Alignment.center,
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFA121218),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0x1FF59E0B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reason == _LocalConfirmReason.runtimeBlocked
                              ? 'Rejected by Real-Debrid'
                              : 'Blocked by Real-Debrid',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reason == _LocalConfirmReason.runtimeBlocked
                              ? 'Real-Debrid rejected this torrent due to copyright or legal restrictions. Download locally via libtorrent instead?'
                              : 'This source is filtered by Real-Debrid and will fail if sent through it. Download locally via libtorrent instead?',
                          style: TextStyle(
                            color: Colors.white.withAlpha(127),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.name,
                          style: TextStyle(
                            color: Colors.white.withAlpha(64),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DpadFocusable(
                    focusNode: _localConfirmCancelFocus,
                    autofocus: true,
                    entry: true,
                    onSelect: () => setState(() {
                      _localConfirmResult = null;
                      _localConfirmReason = null;
                    }),
                    builder: (context, state, child) => GestureDetector(
                      onTap: () => setState(() {
                        _localConfirmResult = null;
                        _localConfirmReason = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: state.focused
                                ? const Color(0xFF0DB2E2)
                                : Colors.white.withAlpha(20),
                            width: state.focused ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white.withAlpha(127),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    child: const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 10),
                  DpadFocusable(
                    onSelect: () => _pickLocalTorrent(result),
                    builder: (context, state, child) => GestureDetector(
                      onTap: () => _pickLocalTorrent(result),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0DB2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: state.focused
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'Download Locally',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    child: const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ResultRow extends StatefulWidget {
  final TorrentResult result;
  final bool isRdBlocked;
  final bool isBusy;
  final VoidCallback onTap;
  final WarpTokens t;
  final FocusNode? focusNode;

  const _ResultRow({
    required this.result,
    required this.isRdBlocked,
    required this.isBusy,
    required this.onTap,
    required this.t,
    this.focusNode,
  });

  @override
  State<_ResultRow> createState() => _ResultRowState();
}

class _ResultRowState extends State<_ResultRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final t = widget.t;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DpadFocusable(
        focusNode: widget.focusNode,
        enabled: !widget.isBusy,
        onSelect: widget.onTap,
        tapToSelect: false,
        builder: (context, state, child) => GestureDetector(
          onTap: () {
            widget.focusNode?.requestFocus();
            if (!widget.isBusy) widget.onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.white.withAlpha(13)
                  : Colors.white.withAlpha(6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: state.focused
                    ? const Color(0xFF0DB2E2)
                    : (_hovered
                          ? Colors.white.withAlpha(30)
                          : Colors.white.withAlpha(15)),
                width: state.focused ? 2 : 1,
              ),
            ),
            child: Opacity(
              opacity: widget.isBusy ? 0.4 : 1.0,
              child: Row(
                children: [
                  // Left: name + metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          r.name,
                          style: TextStyle(
                            color: Colors.white.withAlpha(217),
                            fontSize: t.fontSubtitle.clamp(12.0, 15.0),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${r.seeders} seeders',
                              style: TextStyle(
                                color: Colors.white.withAlpha(90),
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '  ·  ',
                              style: TextStyle(
                                color: Colors.white.withAlpha(51),
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              r.size,
                              style: TextStyle(
                                color: Colors.white.withAlpha(90),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Right: badges
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isRdBlocked) ...[
                        _Pill(
                          label: 'RD Blocked',
                          bg: const Color(0x1FF59E0B),
                          fg: const Color(0xFFFBBF24),
                          border: const Color(0x40F59E0B),
                          icon: Icons.warning_amber_rounded,
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (r.quality.isNotEmpty && r.quality != 'unknown')
                        _Pill(
                          label: r.quality,
                          bg: const Color(0xFF0DB2E2).withAlpha(38),
                          fg: const Color(0xFF0DB2E2),
                          border: Colors.transparent,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final Color border;
  final IconData? icon;

  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
        ],
        Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
