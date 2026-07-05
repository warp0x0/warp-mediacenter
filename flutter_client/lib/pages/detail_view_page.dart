import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api/api_client.dart';
import '../api/catalog_constants.dart';
import '../models/detail.dart';
import '../models/library.dart';
import '../models/media.dart';
import '../providers/detail_provider.dart';
import '../providers/library_provider.dart';
import '../theme/warp_theme.dart';
import '../theme/warp_tokens.dart';
import '../widgets/layout/backdrop_layer.dart';
import '../widgets/media/torrent_dialog.dart';
import '../widgets/media/trailer_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper types
// ─────────────────────────────────────────────────────────────────────────────

class _ShowResumeInfo {
  final int season;
  final int episode;
  final bool isScrobbled;
  final double progress;
  const _ShowResumeInfo({
    required this.season,
    required this.episode,
    required this.isScrobbled,
    required this.progress,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DetailViewPage
// ─────────────────────────────────────────────────────────────────────────────

class DetailViewPage extends ConsumerStatefulWidget {
  final String mediaType; // 'movie' | 'show'
  final String mediaId; // TMDB ID
  final MediaItem? item; // optional fast-path from navigation

  const DetailViewPage({
    super.key,
    required this.mediaType,
    required this.mediaId,
    this.item,
  });

  @override
  ConsumerState<DetailViewPage> createState() => _DetailViewPageState();
}

class _DetailViewPageState extends ConsumerState<DetailViewPage>
    with RouteAware {
  final _scrollCtrl = ScrollController();
  int _selectedSeasonIdx = 0;
  int? _torrentSeason;
  int? _torrentEpisode;
  bool _resumeModalOpen = false;
  double? _resumePercent;
  String? _markingEpisodeKey;
  bool _pushedPlayback = false;

  bool get _isShow => widget.mediaType == 'show';

  // ── D-pad navigation: linear vertical section chain ────────────────────
  // Hero action bar <-> Where-to-Watch-or-Season-pills <-> Episode cards
  // (show only) <-> Local Sources. Entry FocusNodes are owned here (parent)
  // since sections come and go based on async data; each section wires its
  // own boundary item(s) to the shared callbacks below via widget.rowRegistry.
  final _backFocusNode = FocusNode(debugLabel: 'Back');
  final _playTrailerFocusNode = FocusNode(debugLabel: 'PlayTrailer');
  final _playResumeFocusNode = FocusNode(debugLabel: 'PlayResume');
  final _wishlistFocusNode = FocusNode(debugLabel: 'Wishlist');
  final _shareFocusNode = FocusNode(debugLabel: 'Share');
  final _likeFocusNode = FocusNode(debugLabel: 'Like');
  final _episodesEntryFocusNode = FocusNode(debugLabel: 'EpisodesEntry'); // 1st season pill
  final _whereToWatchEntryFocusNode = FocusNode(debugLabel: 'WhereToWatchEntry'); // 1st provider logo
  final _localSourcesEntryFocusNode = FocusNode(debugLabel: 'LocalSourcesEntry'); // 1st source row

  bool _hasTrailer = false;
  bool _hasEpisodes = false;
  bool _hasWhereToWatch = false;
  bool _hasLocalSources = false;
  bool _initialFocusRequested = false;

  FocusNode get _heroEntryNode => _hasTrailer ? _playTrailerFocusNode : _playResumeFocusNode;

  bool _heroDirection(TraversalDirection d) {
    if (d != TraversalDirection.down) return false;
    if (_hasEpisodes) { Dpad.of(context).requestFocus(_episodesEntryFocusNode); return true; }
    if (_hasWhereToWatch) { Dpad.of(context).requestFocus(_whereToWatchEntryFocusNode); return true; }
    if (_hasLocalSources) { Dpad.of(context).requestFocus(_localSourcesEntryFocusNode); return true; }
    return false;
  }

  bool _episodesEntryUp(TraversalDirection d) {
    if (d != TraversalDirection.up) return false;
    Dpad.of(context).requestFocus(_heroEntryNode);
    return true;
  }

  // Down from the last episode card -> whatever section comes next.
  bool _episodesLastDown(TraversalDirection d) {
    if (d != TraversalDirection.down) return false;
    if (_hasWhereToWatch) { Dpad.of(context).requestFocus(_whereToWatchEntryFocusNode); return true; }
    if (_hasLocalSources) { Dpad.of(context).requestFocus(_localSourcesEntryFocusNode); return true; }
    return false;
  }

  bool _whereToWatchDirection(TraversalDirection d) {
    if (d == TraversalDirection.up) {
      Dpad.of(context).requestFocus(_hasEpisodes ? _episodesEntryFocusNode : _heroEntryNode);
      return true;
    }
    if (d == TraversalDirection.down) {
      if (_hasLocalSources) { Dpad.of(context).requestFocus(_localSourcesEntryFocusNode); return true; }
      return false;
    }
    return false;
  }

  // Only the 1st Local Sources row needs an Up override — it's a vertical
  // list, so intra-section Up/Down between rows is plain default beam nav.
  bool _localSourcesFirstUp(TraversalDirection d) {
    if (d != TraversalDirection.up) return false;
    if (_hasWhereToWatch) { Dpad.of(context).requestFocus(_whereToWatchEntryFocusNode); return true; }
    if (_hasEpisodes) { Dpad.of(context).requestFocus(_episodesEntryFocusNode); return true; }
    Dpad.of(context).requestFocus(_heroEntryNode);
    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedBackdrop();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _scrollCtrl.dispose();
    _backFocusNode.dispose();
    _playTrailerFocusNode.dispose();
    _playResumeFocusNode.dispose();
    _wishlistFocusNode.dispose();
    _shareFocusNode.dispose();
    _likeFocusNode.dispose();
    _episodesEntryFocusNode.dispose();
    _whereToWatchEntryFocusNode.dispose();
    _localSourcesEntryFocusNode.dispose();
    super.dispose();
  }

  /// Called by RouteObserver exactly when PlaybackPage (or any page above us)
  /// is popped and this DetailPage becomes the top route again.
  @override
  void didPopNext() {
    if (!_pushedPlayback) return;
    _pushedPlayback = false;
    _refreshAfterPlayback();
  }

  void _seedBackdrop() {
    if (!mounted) return;
    final item = widget.item;
    if (item?.backdropPath != null) {
      ref.read(backdropProvider.notifier).set(backdropUrl(item!.backdropPath));
    }
  }

  void _refreshAfterPlayback() {
    if (!mounted) return;
    if (_isShow) {
      ref.invalidate(showProgressProvider(widget.mediaId));
    } else {
      ref.invalidate(movieProgressProvider(widget.mediaId));
    }
  }

  Future<void> _pushPlayback(Map<String, dynamic> payload) async {
    _pushedPlayback = true;
    try {
      final refreshed = await context.push<bool>('/playback', extra: payload);
      if (!mounted) return;
      if (refreshed == true) _refreshAfterPlayback();
    } finally {
      if (mounted) _pushedPlayback = false;
    }
  }

  Future<void> _toggleLike(bool currentlyLiked, MediaItem? item) async {
    final client = ref.read(apiClientProvider);
    final tmdbId = widget.mediaId;
    try {
      if (currentlyLiked) {
        await client.delete('/api/v1/collections/liked/$tmdbId');
      } else {
        await client.post<void>(
          '/api/v1/collections/liked',
          body: {
            'tmdb_id': tmdbId,
            'type': widget.mediaType,
            'title': item?.title ?? tmdbId,
            'year': item?.year,
            'overview': item?.overview,
            'poster_path': item?.posterPath,
            'backdrop_path': item?.backdropPath,
            'rating': item?.rating,
          },
        );
      }
    } finally {
      ref.invalidate(isLikedProvider(tmdbId));
    }
  }

  Future<void> _toggleWishlist(
    bool currentlyWishlisted,
    MediaItem? item,
  ) async {
    final client = ref.read(apiClientProvider);
    final tmdbId = widget.mediaId;
    try {
      if (currentlyWishlisted) {
        await client.delete('/api/v1/collections/wishlist/$tmdbId');
      } else {
        await client.post<void>(
          '/api/v1/collections/wishlist',
          body: {
            'tmdb_id': tmdbId,
            'type': widget.mediaType,
            'title': item?.title ?? tmdbId,
            'year': item?.year,
            'overview': item?.overview,
            'poster_path': item?.posterPath,
            'backdrop_path': item?.backdropPath,
            'rating': item?.rating,
          },
        );
      }
    } finally {
      ref.invalidate(isWishlistedProvider(tmdbId));
    }
  }

  String get _apiBaseUrl => ref.read(apiClientProvider).dio.options.baseUrl;

  String _localStreamUrl(SourceRow source) {
    final fname = source.filePath?.split('/').last ?? 'video';
    return '$_apiBaseUrl/api/v1/library/sources/${source.id}/stream/${Uri.encodeComponent(fname)}';
  }

  void _logLocalFallback(SourceRow source, Object? error, [StackTrace? stack]) {
    developer.log(
      'Local playback unavailable; opening torrent dialog instead. '
      'source_id=${source.id}, file_path=${source.filePath ?? "(unknown)"}',
      name: 'warp.flutter.detail',
      level: 900, // warning
      error: error,
      stackTrace: stack,
    );
  }

  Future<bool> _isLocalSourcePlayable(SourceRow source) async {
    final url = _localStreamUrl(source);
    try {
      final resp = await ref
          .read(apiClientProvider)
          .dio
          .getUri<ResponseBody>(
            Uri.parse(url),
            options: Options(
              headers: const {'Range': 'bytes=0-0'},
              responseType: ResponseType.stream,
              validateStatus: (_) => true,
            ),
          );
      await resp.data?.stream.drain<void>();
      final status = resp.statusCode ?? 0;
      if (status == 200 || status == 206) return true;
      _logLocalFallback(source, 'HTTP $status');
      return false;
    } catch (error, stack) {
      _logLocalFallback(source, error, stack);
      return false;
    }
  }

  void _playLocalSource(
    SourceRow source, {
    int? season,
    int? episode,
    double? resumeFromFrac,
  }) {
    unawaited(
      _playLocalSourceChecked(
        source,
        season: season,
        episode: episode,
        resumeFromFrac: resumeFromFrac,
      ),
    );
  }

  Future<void> _playLocalSourceChecked(
    SourceRow source, {
    int? season,
    int? episode,
    double? resumeFromFrac,
  }) async {
    final playable = await _isLocalSourcePlayable(source);
    if (!mounted) return;
    if (!playable) {
      _openTorrentDialog(
        resumePercent: resumeFromFrac != null ? resumeFromFrac * 100 : null,
      );
      return;
    }

    _playUrl(
      _localStreamUrl(source),
      season: season,
      episode: episode,
      resumeFromFrac: resumeFromFrac,
    );
  }

  // Matches SxxExx, SxEx, NxNN filename patterns for local episode lookup
  SourceRow? _findLocalEpisodeSource(
    int season,
    int episode,
    List<SourceRow> sources,
  ) {
    final re = RegExp(
      '(?:[Ss]0*$season[Ee]0*$episode|\\b$season[xX]0*$episode)(?!\\d)',
      caseSensitive: false,
    );
    return sources
        .where(
          (s) =>
              s.sourceType == 'local' &&
              s.status != 'missing' &&
              s.filePath != null &&
              re.hasMatch(s.filePath!.split('/').last),
        )
        .firstOrNull;
  }

  _ShowResumeInfo? _computeShowResumeInfo(ShowProgressResponse? progress) {
    if (progress == null) return null;
    // Priority 1: episode with partial scrobble (paused mid-watch)
    for (final season in progress.seasons) {
      if (season.number == 0) continue;
      for (final ep in season.episodes) {
        if (ep.scrobbleProgress != null && ep.scrobbleProgress! > 0) {
          return _ShowResumeInfo(
            season: season.number,
            episode: ep.number,
            isScrobbled: true,
            progress: ep.scrobbleProgress!,
          );
        }
      }
    }
    // Priority 2: first uncompleted episode
    for (final season in progress.seasons) {
      if (season.number == 0) continue;
      for (final ep in season.episodes) {
        if (!ep.completed) {
          return _ShowResumeInfo(
            season: season.number,
            episode: ep.number,
            isScrobbled: false,
            progress: 0,
          );
        }
      }
    }
    return null;
  }

  double? _computeShowOverallProgress(ShowProgressResponse? progress) {
    if (progress == null || progress.aired == null || progress.aired == 0) {
      return null;
    }
    return double.parse(
      ((progress.completed ?? 0) / progress.aired! * 100).toStringAsFixed(1),
    );
  }

  Future<void> _markEpisodeWatched(
    int seasonNum,
    int episodeNum,
    int? playbackId,
    String title,
    int? year,
    String? overview,
    MediaItem? item,
  ) async {
    final key = '$seasonNum:$episodeNum';
    if (mounted) setState(() => _markingEpisodeKey = key);
    try {
      final client = ref.read(apiClientProvider);
      final body = <String, dynamic>{
        'tmdb_id': widget.mediaId,
        'media_type': 'episode',
        'season': seasonNum,
        'episode': episodeNum,
        'title': title,
        'poster_path': item?.posterPath,
        'backdrop_path': item?.backdropPath,
      };
      if (playbackId != null) body['playback_id'] = playbackId;
      if (year != null) body['year'] = year;
      if (overview != null) body['overview'] = overview;

      await client.post<void>('/api/v1/library/mark-watched', body: body);
      // Invalidate progress so episode state refreshes
      ref.invalidate(showProgressProvider(widget.mediaId));
    } finally {
      if (mounted) {
        setState(() {
          if (_markingEpisodeKey == key) _markingEpisodeKey = null;
        });
      }
    }
  }

  void _handlePlay({
    required bool isShow,
    required _ShowResumeInfo? showResumeInfo,
    required bool isMovieResumeAvailable,
    required double? movieResumeProgress,
    required SourceRow? localSource,
    required List<SourceRow> sources,
  }) {
    if (isShow && showResumeInfo != null) {
      final info = showResumeInfo;
      setState(() {
        _torrentSeason = info.season;
        _torrentEpisode = info.episode;
      });
      if (info.isScrobbled) {
        setState(() {
          _resumePercent = info.progress;
          _resumeModalOpen = true;
        });
        return;
      }
      // No scrobble — play immediately via local source if available
      final epSrc = _findLocalEpisodeSource(info.season, info.episode, sources);
      if (epSrc != null) {
        _playLocalSource(epSrc, season: info.season, episode: info.episode);
        return;
      }
      _openTorrentDialog();
      return;
    }
    if (!isShow && isMovieResumeAvailable && movieResumeProgress != null) {
      setState(() {
        _resumePercent = movieResumeProgress;
        _resumeModalOpen = true;
      });
      return;
    }
    if (!isShow && localSource != null) {
      _playLocalSource(localSource, season: null, episode: null);
      return;
    }
    _openTorrentDialog();
  }

  void _handlePlayEpisode({
    required EpisodeDetail ep,
    required int seasonNum,
    required double? epScrobblePct,
    required List<SourceRow> sources,
  }) {
    final epNum = ep.episodeNumber;
    setState(() {
      _torrentSeason = seasonNum;
      _torrentEpisode = epNum;
    });
    if (epScrobblePct != null && epScrobblePct > 0) {
      setState(() {
        _resumePercent = epScrobblePct;
        _resumeModalOpen = true;
      });
      return;
    }
    final epSrc = epNum != null
        ? _findLocalEpisodeSource(seasonNum, epNum, sources)
        : null;
    if (epSrc != null && epNum != null) {
      _playLocalSource(epSrc, season: seasonNum, episode: epNum);
      return;
    }
    _openTorrentDialog();
  }

  void _openTorrentDialog({String? title, double? resumePercent}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TorrentDialog(
        title: title ?? widget.item?.title ?? widget.mediaId,
        mediaKind: _isShow ? 'tv' : 'movie',
        tmdbId: widget.mediaId,
        year: widget.item?.year,
        season: _torrentSeason,
        episode: _torrentEpisode,
        resumePercent: resumePercent,
        onPlaybackReady: (payload) => unawaited(_pushPlayback(payload)),
        onClose: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
    );
  }

  void _playUrl(
    String url, {
    int? season,
    int? episode,
    double? resumeFromFrac,
  }) {
    unawaited(
      _pushPlayback({
        'source': url,
        'title': widget.item?.title ?? widget.mediaId,
        'mediaType': widget.mediaType,
        'tmdbId': widget.mediaId,
        'season': season,
        'episode': episode,
        'resumeFromFrac': resumeFromFrac,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    WarpTokens.watch(
      context,
      ref,
    ); // keep tokens provider alive for child widgets
    final size = MediaQuery.sizeOf(context);
    final tmdbId = widget.mediaId;
    final hPad = (size.width * 0.025).clamp(20.0, 48.0);

    ref.listen<int>(playbackEndedProvider, (_, _) {
      _refreshAfterPlayback();
    });

    final libraryAsync = ref.watch(titleDetailProvider(tmdbId));
    final sourcesAsync = ref.watch(titleSourcesProvider(tmdbId));
    final movieAsync = _isShow
        ? null
        : ref.watch(movieRichDetailProvider(tmdbId));
    final showAsync = _isShow
        ? ref.watch(showRichDetailProvider(tmdbId))
        : null;
    final seasonsAsync = _isShow
        ? ref.watch(showSeasonsListProvider(tmdbId))
        : null;
    final progressAsync = _isShow
        ? ref.watch(showProgressProvider(tmdbId))
        : null;
    final providersAsync = ref.watch(
      watchProvidersProvider(tmdbId, widget.mediaType),
    );

    final movieDetail = movieAsync?.asData?.value;
    final showDetail = showAsync?.asData?.value;
    final sources = sourcesAsync.asData?.value ?? [];
    final showProgress = progressAsync?.value;
    final watchProviders = providersAsync.asData?.value;

    final imdbId = movieDetail?.imdbId ?? showDetail?.imdbId;
    final imdbRatingAsync = imdbId != null
        ? ref.watch(imdbRatingProvider(imdbId))
        : null;
    final imdbRating = imdbRatingAsync?.asData?.value?.rating;
    final tmdbRating = movieDetail?.voteAverage ?? showDetail?.voteAverage;

    // Collection status — same providers as PosterCard so state is shared/cached
    final liked = ref.watch(isLikedProvider(tmdbId)).asData?.value ?? false;
    final wishlisted =
        ref.watch(isWishlistedProvider(tmdbId)).asData?.value ?? false;

    final item = widget.item;
    final title = item?.title ?? movieDetail?.title ?? showDetail?.title ?? '…';
    final overview =
        item?.overview ?? movieDetail?.overview ?? showDetail?.overview ?? '';
    final year = item?.year;
    final genres = (item?.genres.isNotEmpty ?? false)
        ? item!.genres
        : (movieDetail?.genres ?? showDetail?.genres ?? <String>[]);
    final tagline = _isShow
        ? null
        : (movieDetail?.tagline?.isNotEmpty == true
              ? movieDetail!.tagline
              : null);
    final runtime = _isShow ? null : movieDetail?.runtimeMinutes;
    final trailerUrl =
        movieDetail?.trailers.firstOrNull?.url ??
        showDetail?.trailers.firstOrNull?.url;

    final posterImg = item?.posterPath != null
        ? posterUrl(item!.posterPath, size: 'w500')
        : (movieDetail?.poster?.url ?? showDetail?.poster?.url ?? '');
    final backdropImg = item?.backdropPath != null
        ? backdropUrl(item!.backdropPath)
        : (movieDetail?.backdrop?.url ?? showDetail?.backdrop?.url ?? '');

    final cast =
        (movieDetail?.credits.cast ??
                showDetail?.credits.cast ??
                <CastMember>[])
            .take(12)
            .toList();
    final crew =
        movieDetail?.credits.crew ?? showDetail?.credits.crew ?? <dynamic>[];

    final localSource = sources
        .where((s) => s.sourceType == 'local' && s.status != 'missing')
        .firstOrNull;

    final heroH = math.max(size.height * 0.70, 500.0);
    // Poster dimensions matching Tauri exactly
    final posterW = (size.width * 0.18).clamp(200.0, 280.0);
    final posterH = (size.width * 0.27).clamp(300.0, 420.0);
    final spacerH = (size.width * 0.23).clamp(180.0, 240.0);

    // Resume / progress state
    final showResumeInfo = _computeShowResumeInfo(showProgress);
    final showOverallProgress = _computeShowOverallProgress(showProgress);
    // Movie progress comes from a watched provider so it refreshes after playback
    final movieProgressAsync = !_isShow
        ? ref.watch(movieProgressProvider(tmdbId))
        : null;
    final movieProgressData = movieProgressAsync?.value;
    final rawPct = movieProgressData?.progress ?? 0.0;
    final movieResumeProgress = rawPct > 0 ? rawPct : null;
    final isMovieResumeAvailable = movieProgressData?.resumeAvailable ?? false;

    // Director / writers
    String? director;
    final List<String> writers = [];
    for (final c in crew) {
      if (c is Map) {
        final job = c['job']?.toString() ?? '';
        final dept = c['department']?.toString() ?? '';
        final name = c['name']?.toString() ?? '';
        if (job == 'Director' && director == null) director = name;
        if (dept == 'Writing' && writers.length < 2 && name.isNotEmpty) {
          writers.add(name);
        }
      }
    }

    final isDetailLoading = _isShow
        ? (showAsync?.isLoading ?? false)
        : (movieAsync?.isLoading ?? false);

    // Keep the D-pad section-chain flags in sync with what's actually
    // rendered below, and request the initial focus (Play Trailer, or
    // Play/Resume if no trailer) the first time the hero row's real state
    // is known (this page loads its detail data asynchronously).
    _hasTrailer = trailerUrl != null;
    _hasEpisodes = _isShow && (seasonsAsync?.asData?.value?.seasons.isNotEmpty ?? false);
    _hasWhereToWatch = watchProviders != null &&
        (watchProviders.streaming.isNotEmpty ||
            watchProviders.rent.isNotEmpty ||
            watchProviders.buy.isNotEmpty);
    _hasLocalSources = sources.isNotEmpty;
    if (!_initialFocusRequested && !isDetailLoading) {
      _initialFocusRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _heroEntryNode.requestFocus();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // ── Main scroll ──────────────────────────────────────────────────
          CustomScrollView(
            controller: _scrollCtrl,
            slivers: [
              // ── Hero ───────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  width: size.width,
                  height: heroH,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Backdrop image
                      if (backdropImg.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: backdropImg,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          placeholder: (_, _) =>
                              const ColoredBox(color: Color(0xFF181818)),
                          errorWidget: (_, _, _) =>
                              const ColoredBox(color: Color(0xFF181818)),
                        )
                      else
                        const ColoredBox(color: Color(0xFF181818)),

                      // Tauri gradient: transparent 0%, transparent 30%, rgba(0,0,0,0.3) 50%,
                      //                  rgba(0,0,0,0.7) 70%, rgba(0,0,0,0.95) 90%, #0a0a0a 100%
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Color(0x4C000000),
                              Color(0xB3000000),
                              Color(0xF2000000),
                              Color(0xFF0A0A0A),
                            ],
                            stops: [0.0, 0.30, 0.50, 0.70, 0.90, 1.0],
                          ),
                        ),
                      ),

                      // Hero action bar — Back, Play Trailer, Play/Resume, and
                      // the Like/Wishlist/Share icons all share one DpadRegion
                      // so left/right beam nav flows between them even though
                      // Back is positioned separately (top-left) from the rest
                      // (top-right); all share the same _heroDirection
                      // callback (down -> next section).
                      DpadRegion(
                        memoryKey: 'detail-hero-actions',
                        child: Stack(
                          children: [
                            // Back button — top-left
                            // Tauri: position top clamp(20,2.5vw,48) left clamp(20,2.5vw,48)
                            //   100×40, bg-black/90 border-white → hover bg-black/80 border-white/30
                            Positioned(
                              top: hPad,
                              left: hPad,
                              child: _BackButton(
                                onBack: () => context.pop(),
                                focusNode: _backFocusNode,
                                onDirection: _heroDirection,
                              ),
                            ),

                            // Action buttons — top-right
                            Positioned(
                              top: hPad,
                              right: hPad,
                              child: Row(
                                children: [
                                  // Trailer button (only when trailer exists)
                                  if (trailerUrl != null) ...[
                                    _PlayTrailerButton(
                                      loading: false,
                                      focusNode: _playTrailerFocusNode,
                                      onDirection: _heroDirection,
                                      onTap: () {
                                        showDialog<void>(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (_) => TrailerDialog(
                                            trailerUrl: trailerUrl,
                                            title: title,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                  ],

                                  // Play / Resume button
                                  _PlayResumeButton(
                                    isShow: _isShow,
                                    showResumeInfo: showResumeInfo,
                                    isMovieResumeAvailable: isMovieResumeAvailable,
                                    focusNode: _playResumeFocusNode,
                                    onDirection: _heroDirection,
                                    onTap: () => _handlePlay(
                                      isShow: _isShow,
                                      showResumeInfo: showResumeInfo,
                                      isMovieResumeAvailable: isMovieResumeAvailable,
                                      movieResumeProgress: movieResumeProgress,
                                      localSource: localSource,
                                      sources: sources,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Wishlist circle button
                                  _CircleActionButton(
                                    active: wishlisted,
                                    activeColor: const Color(0x40109B60),
                                    activeBorderColor: const Color(0x9910B97D),
                                    activeIconColor: const Color(0xFF34D399),
                                    icon: wishlisted ? Icons.check_circle : Icons.add,
                                    focusNode: _wishlistFocusNode,
                                    onDirection: _heroDirection,
                                    onTap: () => _toggleWishlist(wishlisted, item),
                                  ),
                                  const SizedBox(width: 8),

                                  // Share circle button
                                  _CircleActionButton(
                                    active: false,
                                    activeColor: Colors.transparent,
                                    activeBorderColor: Colors.transparent,
                                    activeIconColor: Colors.white,
                                    icon: Icons.share,
                                    focusNode: _shareFocusNode,
                                    onDirection: _heroDirection,
                                    onTap: () {},
                                  ),
                                  const SizedBox(width: 8),

                                  // Like circle button
                                  _CircleActionButton(
                                    active: liked,
                                    activeColor: const Color(0x40EF4444),
                                    activeBorderColor: const Color(0x99EF4444),
                                    activeIconColor: const Color(0xFFF87171),
                                    icon: liked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    focusNode: _likeFocusNode,
                                    onDirection: _heroDirection,
                                    onTap: () => _toggleLike(liked, item),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Poster + metadata — positioned at bottom, translateY(50%)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Transform.translate(
                          offset: Offset(0, posterH * 0.50),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Poster
                                Container(
                                  width: posterW,
                                  height: posterH,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(13),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(25),
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x99000000),
                                        blurRadius: 32,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: posterImg.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: posterImg,
                                          fit: BoxFit.cover,
                                          placeholder: (_, _) =>
                                              const SizedBox.shrink(),
                                          errorWidget: (_, _, _) => Center(
                                            child: Text(
                                              'No Poster',
                                              style: TextStyle(
                                                color: Colors.white.withAlpha(
                                                  76,
                                                ),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            'No Poster',
                                            style: TextStyle(
                                              color: Colors.white.withAlpha(76),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                ),

                                const SizedBox(width: 32),

                                // Metadata block
                                Expanded(
                                  child: Padding(
                                    // clamp(40px, 6vh, 80px) top padding
                                    padding: EdgeInsets.only(
                                      top: (size.height * 0.06).clamp(
                                        40.0,
                                        80.0,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Title clamp(32px, 3.5vw, 56px) — 50px wider than overview
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 800,
                                          ),
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: (size.width * 0.035)
                                                  .clamp(32.0, 56.0),
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              height: 1.1,
                                              shadows: const [
                                                Shadow(
                                                  color: Color(0xE6000000),
                                                  blurRadius: 16,
                                                  offset: Offset(2, 4),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Tagline
                                        if (tagline != null) ...[
                                          const SizedBox(height: 16),
                                          Text(
                                            tagline,
                                            style: TextStyle(
                                              fontSize: (size.width * 0.012)
                                                  .clamp(16.0, 18.0),
                                              color: Colors.white.withAlpha(
                                                204,
                                              ),
                                              fontStyle: FontStyle.italic,
                                              shadows: const [
                                                Shadow(
                                                  color: Color(0xE6000000),
                                                  blurRadius: 8,
                                                  offset: Offset(1, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 16),

                                        // Rating badges + year + runtime
                                        Row(
                                          children: [
                                            if (tmdbRating != null)
                                              _TmdbBadge(rating: tmdbRating),
                                            if (tmdbRating != null &&
                                                imdbRating != null)
                                              const SizedBox(width: 12),
                                            if (imdbRating != null)
                                              _ImdbBadge(rating: imdbRating),
                                            if ((imdbRating != null ||
                                                    tmdbRating != null) &&
                                                year != null)
                                              const SizedBox(width: 20),
                                            if (year != null)
                                              Text(
                                                '$year',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            if (runtime != null) ...[
                                              const SizedBox(width: 20),
                                              Text(
                                                '$runtime min',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),

                                        // Genres
                                        if (genres.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.label_outline,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  genres.take(5).join('  ·  '),
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withAlpha(180),
                                                    fontSize: 15,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],

                                        // Overview — Tauri: max-w-3xl (≈768px), clamp font
                                        if (overview.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 700,
                                            ),
                                            child: Text(
                                              overview,
                                              style: TextStyle(
                                                fontSize: (size.width * 0.011)
                                                    .clamp(15.0, 18.0),
                                                color: Colors.white.withAlpha(
                                                  217,
                                                ),
                                                height: 1.7,
                                                shadows: const [
                                                  Shadow(
                                                    color: Color(0xCC000000),
                                                    blurRadius: 8,
                                                    offset: Offset(1, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Spacer for overlapping poster ───────────────────────────────
              SliverToBoxAdapter(child: SizedBox(height: spacerH)),

              // ── Progress bar (shows: overall %, movies: scrobble %) ─────────
              SliverToBoxAdapter(
                child: Builder(
                  builder: (_) {
                    final pct = _isShow
                        ? showOverallProgress
                        : movieResumeProgress;
                    if (pct == null || pct <= 0) return const SizedBox.shrink();
                    final label = _isShow
                        ? '$pct% completed'
                        : '${pct.round()}% watched';
                    return Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: Container(
                                height: 6,
                                color: Colors.white.withAlpha(25),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: (pct / 100).clamp(0.0, 1.0),
                                  child: Container(
                                    color: const Color(0xFFFBBF24),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            label,
                            style: TextStyle(
                              color: Colors.white.withAlpha(128),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Director / Writers / Year ───────────────────────────────────
              if (!isDetailLoading && (director != null || writers.isNotEmpty))
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(hPad, 40, hPad, 32),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A0A0A),
                      border: Border(top: BorderSide(color: Color(0x0DFFFFFF))),
                    ),
                    child: Wrap(
                      spacing: 40,
                      runSpacing: 16,
                      children: [
                        if (director != null)
                          _CrewItem(label: 'Director', value: director),
                        if (writers.isNotEmpty)
                          _CrewItem(
                            label: writers.length > 1 ? 'Writers' : 'Writer',
                            value: writers.join(', '),
                          ),
                        if (year != null)
                          _CrewItem(label: 'Year', value: '$year'),
                      ],
                    ),
                  ),
                ),

              // ── Episodes section (shows) ─────────────────────────────────────
              if (_isShow && seasonsAsync != null)
                SliverToBoxAdapter(
                  child: seasonsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (seasons) =>
                        seasons == null || seasons.seasons.isEmpty
                        ? const SizedBox.shrink()
                        : _EpisodesSection(
                            seasons: seasons,
                            selectedIdx: _selectedSeasonIdx,
                            showProgress: showProgress,
                            showResumeInfo: showResumeInfo,
                            sources: sources,
                            markingEpisodeKey: _markingEpisodeKey,
                            entryFocusNode: _episodesEntryFocusNode,
                            onEntryUp: _episodesEntryUp,
                            onLastEpisodeDown: _episodesLastDown,
                            onSeasonChange: (i) =>
                                setState(() => _selectedSeasonIdx = i),
                            onPlayEpisode: (ep, seasonNum, epScrobblePct) =>
                                _handlePlayEpisode(
                                  ep: ep,
                                  seasonNum: seasonNum,
                                  epScrobblePct: epScrobblePct,
                                  sources: sources,
                                ),
                            onMarkWatched: (sNum, epNum, pbId) =>
                                _markEpisodeWatched(
                                  sNum,
                                  epNum,
                                  pbId,
                                  title,
                                  year,
                                  overview,
                                  item,
                                ),
                            findLocalSource: (s, e) =>
                                _findLocalEpisodeSource(s, e, sources),
                            hPad: hPad,
                          ),
                  ),
                ),

              // ── Cast section (with chevrons — user requirement) ──────────────
              if (!isDetailLoading && cast.isNotEmpty)
                SliverToBoxAdapter(
                  child: _CastSection(cast: cast, hPad: hPad),
                ),

              // ── Where to Watch ───────────────────────────────────────────────
              if (watchProviders != null &&
                  (watchProviders.streaming.isNotEmpty ||
                      watchProviders.rent.isNotEmpty ||
                      watchProviders.buy.isNotEmpty))
                SliverToBoxAdapter(
                  child: _WatchProvidersSection(
                    providers: watchProviders,
                    hPad: hPad,
                    entryFocusNode: _whereToWatchEntryFocusNode,
                    onDirection: _whereToWatchDirection,
                  ),
                ),

              // ── Local Sources ────────────────────────────────────────────────
              if (sources.isNotEmpty)
                SliverToBoxAdapter(
                  child: _LocalSourcesSection(
                    sources: sources,
                    hPad: hPad,
                    entryFocusNode: _localSourcesEntryFocusNode,
                    onEntryUp: _localSourcesFirstUp,
                    onPlay: (src) =>
                        _playLocalSource(src, season: null, episode: null),
                  ),
                ),

              // ── "Add to library" hint ────────────────────────────────────────
              if (libraryAsync.asData?.value == null && !libraryAsync.isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 32),
                    child: Text(
                      'Add this title to your library to see local file sources.',
                      style: TextStyle(
                        color: Colors.white.withAlpha(102),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),

          // ── Resume modal overlay ─────────────────────────────────────────
          if (_resumeModalOpen)
            _ResumeModal(
              resumePercent: _resumePercent,
              onContinue: () {
                final pct = _resumePercent;
                setState(() => _resumeModalOpen = false);
                if (_isShow &&
                    _torrentSeason != null &&
                    _torrentEpisode != null) {
                  final epSrc = _findLocalEpisodeSource(
                    _torrentSeason!,
                    _torrentEpisode!,
                    sources,
                  );
                  if (epSrc != null) {
                    _playLocalSource(
                      epSrc,
                      season: _torrentSeason,
                      episode: _torrentEpisode,
                      resumeFromFrac: pct != null ? pct / 100 : null,
                    );
                    return;
                  }
                } else if (!_isShow && localSource != null) {
                  _playLocalSource(
                    localSource,
                    season: null,
                    episode: null,
                    resumeFromFrac: pct != null ? pct / 100 : null,
                  );
                  return;
                }
                _openTorrentDialog(resumePercent: pct?.toDouble());
              },
              onStartOver: () {
                setState(() {
                  _resumePercent = null;
                  _resumeModalOpen = false;
                });
                if (_isShow &&
                    _torrentSeason != null &&
                    _torrentEpisode != null) {
                  final epSrc = _findLocalEpisodeSource(
                    _torrentSeason!,
                    _torrentEpisode!,
                    sources,
                  );
                  if (epSrc != null) {
                    _playLocalSource(
                      epSrc,
                      season: _torrentSeason,
                      episode: _torrentEpisode,
                    );
                    return;
                  }
                } else if (!_isShow && localSource != null) {
                  _playLocalSource(localSource, season: null, episode: null);
                  return;
                }
                _openTorrentDialog();
              },
              onCancel: () => setState(() => _resumeModalOpen = false),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Back Button
// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatefulWidget {
  final VoidCallback onBack;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;
  const _BackButton({required this.onBack, this.focusNode, this.onDirection});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Tauri: 100×40, bg-black/90 border-white, hover bg-black/80 border-white/30
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: DpadFocusable(
        focusNode: widget.focusNode,
        onDirection: widget.onDirection,
        onSelect: widget.onBack,
        tapToSelect: false,
        builder: (context, state, child) => GestureDetector(
          onTap: () {
            widget.focusNode?.requestFocus();
            widget.onBack();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            height: 40,
            decoration: BoxDecoration(
              color: _hovered ? const Color(0xCC000000) : const Color(0xE6000000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hovered ? Colors.white.withAlpha(76) : Colors.white,
              ),
              // Icon-category focus indicator: prominent cyan halo.
              boxShadow: state.focused
                  ? [BoxShadow(color: WarpColors.accent.withAlpha(140), blurRadius: 18, spreadRadius: 2)]
                  : null,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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

// ─────────────────────────────────────────────────────────────────────────────
// Play Trailer Button
// ─────────────────────────────────────────────────────────────────────────────

class _PlayTrailerButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;
  const _PlayTrailerButton({
    required this.loading,
    required this.onTap,
    this.focusNode,
    this.onDirection,
  });

  @override
  State<_PlayTrailerButton> createState() => _PlayTrailerButtonState();
}

class _PlayTrailerButtonState extends State<_PlayTrailerButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: DpadFocusable(
        focusNode: widget.focusNode,
        onDirection: widget.onDirection,
        onSelect: widget.loading ? () {} : widget.onTap,
        enabled: !widget.loading,
        tapToSelect: false,
        builder: (context, state, child) {
          // Global rule: CTA buttons never show a ring — dark/cyan-border
          // by default, revealing their own accent (cyan) only when focused.
          final active = state.focused || _hovered;
          return GestureDetector(
            onTap: widget.loading
                ? null
                : () {
                    widget.focusNode?.requestFocus();
                    widget.onTap();
                  },
            child: Transform.translate(
              offset: _hovered ? const Offset(0, -2) : Offset.zero,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 150,
                height: 40,
                decoration: BoxDecoration(
                  color: active ? WarpColors.accent : const Color(0xCC333232),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: WarpColors.accent, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 18,
                          ),
                    const SizedBox(width: 8),
                    const Text(
                      'Play Trailer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Play / Resume Button
// ─────────────────────────────────────────────────────────────────────────────

class _PlayResumeButton extends StatefulWidget {
  final bool isShow;
  final _ShowResumeInfo? showResumeInfo;
  final bool isMovieResumeAvailable;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;

  const _PlayResumeButton({
    required this.isShow,
    required this.showResumeInfo,
    required this.isMovieResumeAvailable,
    required this.onTap,
    this.focusNode,
    this.onDirection,
  });

  @override
  State<_PlayResumeButton> createState() => _PlayResumeButtonState();
}

class _PlayResumeButtonState extends State<_PlayResumeButton> {
  bool _hovered = false;

  String get _label {
    if (widget.isShow) {
      final info = widget.showResumeInfo;
      if (info == null) return 'Play';
      final s = info.season.toString().padLeft(2, '0');
      final e = (info.episode).toString().padLeft(2, '0');
      return info.isScrobbled ? 'Resume S${s}E$e' : 'Next S${s}E$e';
    }
    return widget.isMovieResumeAvailable ? 'Resume' : 'Play';
  }

  bool get _isResume {
    if (widget.isShow) return widget.showResumeInfo?.isScrobbled == true;
    return widget.isMovieResumeAvailable;
  }

  // Tauri: amber rgb(217,119,6) for resume, red rgb(229,9,20) for play.
  // Global rule: CTA buttons only reveal their native color on focus —
  // unfocused they show the shared dark/cyan-border look.
  Color get _color =>
      _isResume ? const Color(0xFFD97706) : const Color(0xFFE50914);
  Color get _shadow =>
      _isResume ? const Color(0x66D97706) : const Color(0x66E50914);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: DpadFocusable(
        focusNode: widget.focusNode,
        onDirection: widget.onDirection,
        onSelect: widget.onTap,
        tapToSelect: false,
        builder: (context, state, child) {
          final active = state.focused || _hovered;
          return GestureDetector(
            onTap: () {
              widget.focusNode?.requestFocus();
              widget.onTap();
            },
            child: Transform.translate(
              offset: _hovered ? const Offset(0, -2) : Offset.zero,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minWidth: 150),
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: active ? _color : const Color(0xCC333232),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: active ? _color : WarpColors.accent, width: 1),
                  boxShadow: active
                      ? [BoxShadow(color: _shadow, blurRadius: 16, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 18,
                      fill: 1,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circle Action Button (Wishlist / Share / Like)
// ─────────────────────────────────────────────────────────────────────────────

class _CircleActionButton extends StatefulWidget {
  final bool active;
  final Color activeColor;
  final Color activeBorderColor;
  final Color activeIconColor;
  final IconData icon;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;

  const _CircleActionButton({
    required this.active,
    required this.activeColor,
    required this.activeBorderColor,
    required this.activeIconColor,
    required this.icon,
    required this.onTap,
    this.focusNode,
    this.onDirection,
  });

  @override
  State<_CircleActionButton> createState() => _CircleActionButtonState();
}

class _CircleActionButtonState extends State<_CircleActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Tauri: w-12 h-12 (48×48) rounded-full backdrop-blur-3xl hover:scale-110
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: DpadFocusable(
        focusNode: widget.focusNode,
        onDirection: widget.onDirection,
        onSelect: widget.onTap,
        tapToSelect: false,
        builder: (context, state, child) => GestureDetector(
          onTap: () {
            widget.focusNode?.requestFocus();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: _hovered ? 1.10 : 1.0,
            duration: const Duration(milliseconds: 200),
            // Icon-category focus indicator: prominent cyan halo, drawn
            // outside the ClipOval so it isn't clipped away.
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: state.focused
                    ? [BoxShadow(color: WarpColors.accent.withAlpha(140), blurRadius: 18, spreadRadius: 2)]
                    : null,
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      // Inactive: deep black with stronger opacity; active: brand color over dark base
                      color: widget.active
                          ? Color.alphaBlend(
                              widget.activeColor,
                              const Color(0xCC000000),
                            )
                          : const Color(0xCC000000),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.active
                            ? widget.activeBorderColor
                            : Colors.white.withAlpha(80),
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.active ? widget.activeIconColor : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rating Badge
// ─────────────────────────────────────────────────────────────────────────────

class _TmdbBadge extends StatelessWidget {
  final double rating;
  const _TmdbBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF032541),
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Text(
            'TMDb',
            style: TextStyle(
              color: Color(0xFF01B4E4),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ImdbBadge extends StatelessWidget {
  final double rating;
  const _ImdbBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF5C518),
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Text(
            'IMDb',
            style: TextStyle(
              color: Colors.black,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Crew Item
// ─────────────────────────────────────────────────────────────────────────────

class _CrewItem extends StatelessWidget {
  final String label;
  final String value;

  const _CrewItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w500,
            color: Color(0x80FFFFFF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xE6FFFFFF),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Episodes Section
// ─────────────────────────────────────────────────────────────────────────────

class _EpisodesSection extends StatefulWidget {
  final ShowSeasonsResponse seasons;
  final int selectedIdx;
  final ShowProgressResponse? showProgress;
  final _ShowResumeInfo? showResumeInfo;
  final List<SourceRow> sources;
  final String? markingEpisodeKey;
  final void Function(int) onSeasonChange;
  final void Function(EpisodeDetail ep, int seasonNum, double? epScrobblePct)
  onPlayEpisode;
  final Future<void> Function(int seasonNum, int epNum, int? playbackId)
  onMarkWatched;
  final SourceRow? Function(int season, int episode) findLocalSource;
  final double hPad;
  // D-pad chain: entryFocusNode is the 1st season pill (down-target from the
  // hero action bar). onEntryUp fires for every pill's Up (-> hero).
  // onLastEpisodeDown fires for the last episode card's Down (-> whatever
  // section comes next: Where to Watch or Local Sources).
  final FocusNode entryFocusNode;
  final DpadDirectionCallback onEntryUp;
  final DpadDirectionCallback onLastEpisodeDown;

  const _EpisodesSection({
    required this.seasons,
    required this.selectedIdx,
    required this.showProgress,
    required this.showResumeInfo,
    required this.sources,
    required this.markingEpisodeKey,
    required this.onSeasonChange,
    required this.onPlayEpisode,
    required this.onMarkWatched,
    required this.findLocalSource,
    required this.hPad,
    required this.entryFocusNode,
    required this.onEntryUp,
    required this.onLastEpisodeDown,
  });

  @override
  State<_EpisodesSection> createState() => _EpisodesSectionState();
}

class _EpisodesSectionState extends State<_EpisodesSection> {
  final _seasonScroll = ScrollController();
  List<FocusNode> _pillFocusNodes = [];
  List<FocusNode> _episodeFocusNodes = [];

  @override
  void dispose() {
    _seasonScroll.dispose();
    for (final fn in _pillFocusNodes) { fn.dispose(); }
    for (final fn in _episodeFocusNodes) { fn.dispose(); }
    super.dispose();
  }

  // Rebuilds the per-pill FocusNode list, reusing widget.entryFocusNode for
  // pill 0 (external, so the hero row's Down target stays stable).
  void _syncPillFocusNodes(int count) {
    if (_pillFocusNodes.length == count) return;
    for (var i = 1; i < _pillFocusNodes.length; i++) { _pillFocusNodes[i].dispose(); }
    _pillFocusNodes = List.generate(count, (i) => i == 0 ? widget.entryFocusNode : FocusNode());
  }

  void _syncEpisodeFocusNodes(int count) {
    if (_episodeFocusNodes.length == count) return;
    for (final fn in _episodeFocusNodes) { fn.dispose(); }
    _episodeFocusNodes = List.generate(count, (_) => FocusNode());
  }

  // Every pill shares this: Up -> hero action bar; Down -> 1st episode card
  // (local — the episode list is part of this same section).
  bool _pillDirection(TraversalDirection d) {
    if (d == TraversalDirection.up) return widget.onEntryUp(d);
    if (d == TraversalDirection.down) {
      if (_episodeFocusNodes.isNotEmpty) {
        Dpad.of(context).requestFocus(_episodeFocusNodes[0]);
        return true;
      }
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final seasons = widget.seasons.seasons;
    final selected = seasons.isNotEmpty ? seasons[widget.selectedIdx] : null;
    final epCount = selected?.episodeCount;
    final episodes = selected?.episodes ?? const [];

    _syncPillFocusNodes(seasons.length);
    _syncEpisodeFocusNodes(episodes.length);

    return Container(
      padding: EdgeInsets.fromLTRB(widget.hPad, 48, widget.hPad, 64),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Episodes',
                style: TextStyle(
                  fontSize: (size.width * 0.0175).clamp(22.0, 28.0),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (epCount != null) ...[
                const SizedBox(width: 16),
                Text(
                  '$epCount episodes',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0x66FFFFFF),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),

          // Season selector with chevrons
          Row(
            children: [
              _SeasonChevron(
                icon: Icons.chevron_left,
                onTap: () => _seasonScroll.animateTo(
                  _seasonScroll.offset - 300,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: ListView.separated(
                      controller: _seasonScroll,
                      scrollDirection: Axis.horizontal,
                      itemCount: seasons.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _SeasonPill(
                        seasonNumber: seasons[i].seasonNumber,
                        episodeCount: seasons[i].episodeCount,
                        active: i == widget.selectedIdx,
                        onTap: () => widget.onSeasonChange(i),
                        focusNode: i < _pillFocusNodes.length ? _pillFocusNodes[i] : null,
                        onDirection: _pillDirection,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SeasonChevron(
                icon: Icons.chevron_right,
                onTap: () => _seasonScroll.animateTo(
                  _seasonScroll.offset + 300,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Episode cards
          if (selected?.episodes?.isNotEmpty == true)
            Column(
              children: selected!.episodes!.asMap().entries.map((entry) {
                final epIdx = entry.key;
                final ep = entry.value;
                final seasonNum = selected.seasonNumber;
                final epCode =
                    'S${seasonNum.toString().padLeft(2, '0')}E${(ep.episodeNumber ?? 1).toString().padLeft(2, '0')}';

                // Progress state from Trakt
                final progressSeason = widget.showProgress?.seasons
                    .where((s) => s.number == seasonNum)
                    .firstOrNull;
                final progressEp = progressSeason?.episodes
                    .where((e) => e.number == ep.episodeNumber)
                    .firstOrNull;
                final isWatched = progressEp?.completed == true;
                final isResumeEp =
                    widget.showResumeInfo?.season == seasonNum &&
                    widget.showResumeInfo?.episode == ep.episodeNumber;
                final epScrobblePct =
                    (progressEp?.scrobbleProgress != null &&
                        progressEp!.scrobbleProgress! > 0)
                    ? progressEp.scrobbleProgress
                    : null;
                final epLocalSrc = ep.episodeNumber != null
                    ? widget.findLocalSource(seasonNum, ep.episodeNumber!)
                    : null;
                final watchedDone = isWatched && !isResumeEp;
                final isMarking =
                    widget.markingEpisodeKey ==
                    '$seasonNum:${ep.episodeNumber ?? epIdx + 1}';

                // Only the 1st/last episode card need a D-pad boundary
                // override — intra-list Up/Down between cards is plain
                // default beam nav.
                final bool isFirstEp = epIdx == 0;
                final bool isLastEp = epIdx == episodes.length - 1;
                final DpadDirectionCallback? epDirection = (isFirstEp || isLastEp)
                    ? (d) {
                        if (isFirstEp && d == TraversalDirection.up) {
                          Dpad.of(context).requestFocus(_pillFocusNodes[0]);
                          return true;
                        }
                        if (isLastEp && d == TraversalDirection.down) {
                          return widget.onLastEpisodeDown(d);
                        }
                        return false;
                      }
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _EpisodeCard(
                    episode: ep,
                    seasonNum: seasonNum,
                    epCode: epCode,
                    isWatched: isWatched,
                    isResumeEp: isResumeEp,
                    watchedDone: watchedDone,
                    epScrobblePct: epScrobblePct,
                    epLocalSrc: epLocalSrc,
                    isMarking: isMarking,
                    focusNode: epIdx < _episodeFocusNodes.length ? _episodeFocusNodes[epIdx] : null,
                    onDirection: epDirection,
                    onPlay: () =>
                        widget.onPlayEpisode(ep, seasonNum, epScrobblePct),
                    onMarkWatched: () => widget.onMarkWatched(
                      seasonNum,
                      ep.episodeNumber ?? epIdx + 1,
                      progressEp?.playbackId,
                    ),
                    size: size,
                  ),
                );
              }).toList(),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: Column(
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: Color(0x33FFFFFF),
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No episode details available for this season.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0x4DFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SeasonChevron extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SeasonChevron({required this.icon, required this.onTap});

  @override
  State<_SeasonChevron> createState() => _SeasonChevronState();
}

class _SeasonChevronState extends State<_SeasonChevron> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withAlpha(25) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: Colors.white.withAlpha(140),
            size: 25,
          ),
        ),
      ),
    );
  }
}

class _SeasonPill extends StatefulWidget {
  final int seasonNumber;
  final int? episodeCount;
  final bool active;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;

  const _SeasonPill({
    required this.seasonNumber,
    required this.episodeCount,
    required this.active,
    required this.onTap,
    this.focusNode,
    this.onDirection,
  });

  @override
  State<_SeasonPill> createState() => _SeasonPillState();
}

class _SeasonPillState extends State<_SeasonPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    // Tauri: active pill uses var(--accent) = #0DB2E2, text #000
    //        inactive: rgba(255,255,255,0.06) bg, border rgba(255,255,255,0.10)
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: DpadFocusable(
        focusNode: widget.focusNode,
        onDirection: widget.onDirection,
        onSelect: widget.onTap,
        tapToSelect: false,
        builder: (context, state, child) => GestureDetector(
        onTap: () {
          widget.focusNode?.requestFocus();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF0DB2E2)
                : (_hovered
                      ? Colors.white.withAlpha(20)
                      : Colors.white.withAlpha(15)),
            borderRadius: BorderRadius.circular(99),
            border: state.focused
                ? Border.all(color: WarpColors.accent, width: 2)
                : (active
                    ? null
                    : Border.all(color: Colors.white.withAlpha(_hovered ? 38 : 25))),
            boxShadow: active
                ? const [BoxShadow(color: Color(0x5901B4E4), blurRadius: 14)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'S${widget.seasonNumber.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: active
                      ? Colors.black
                      : Colors.white.withAlpha(_hovered ? 180 : 140),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (widget.episodeCount != null) ...[
                const SizedBox(width: 4),
                Text(
                  '· ${widget.episodeCount}ep',
                  style: TextStyle(
                    color: active
                        ? Colors.black.withAlpha(160)
                        : Colors.white.withAlpha(_hovered ? 130 : 100),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Episode Card
// ─────────────────────────────────────────────────────────────────────────────

class _EpisodeCard extends StatefulWidget {
  final EpisodeDetail episode;
  final int seasonNum;
  final String epCode;
  final bool isWatched;
  final bool isResumeEp;
  final bool watchedDone;
  final double? epScrobblePct;
  final SourceRow? epLocalSrc;
  final bool isMarking;
  final VoidCallback onPlay;
  final Future<void> Function() onMarkWatched;
  final Size size;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;

  const _EpisodeCard({
    required this.episode,
    required this.seasonNum,
    required this.epCode,
    required this.isWatched,
    required this.isResumeEp,
    required this.watchedDone,
    required this.epScrobblePct,
    required this.epLocalSrc,
    required this.isMarking,
    required this.onPlay,
    required this.onMarkWatched,
    required this.size,
    this.focusNode,
    this.onDirection,
  });

  @override
  State<_EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<_EpisodeCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ep = widget.episode;
    final size = widget.size;
    final watchedDone = widget.watchedDone;
    final isResumeEp = widget.isResumeEp;
    final epScrobblePct = widget.epScrobblePct;
    final epLocalSrc = widget.epLocalSrc;
    final isMarking = widget.isMarking;

    final stillImg = ep.stillFrame?.url != null
        ? posterUrl(ep.stillFrame!.url, size: 'w300')
        : null;

    // Tauri: episode card colors
    final bgColor = isResumeEp
        ? const Color(0x14D97706)
        : watchedDone
        ? const Color(0x05FFFFFF)
        : const Color(0x08FFFFFF);
    final borderColor = isResumeEp
        ? const Color(0x66D97706)
        : watchedDone
        ? const Color(0x0AFFFFFF)
        : const Color(0x12FFFFFF);

    // Still frame width: clamp(160px, 14vw, 220px)
    final stillW = (size.width * 0.14).clamp(160.0, 220.0);

    return DpadFocusable(
      focusNode: widget.focusNode,
      onDirection: widget.onDirection,
      onFocusChange: (v) => setState(() => _focused = v),
      onSelect: widget.onPlay,
      tapToSelect: false,
      builder: (context, state, child) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () {
            widget.focusNode?.requestFocus();
            widget.onPlay();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 110),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused ? const Color(0xFF0DB2E2) : borderColor,
                width: _focused ? 1.5 : 1.0,
              ),
              boxShadow: _hovered
                  ? const [
                      BoxShadow(
                        color: Color(0x80000000),
                        blurRadius: 24,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            // Tauri: opacity 0.65 for watched-done episodes that aren't resume
            child: Opacity(
              opacity: watchedDone ? 0.65 : 1.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Still frame
                          SizedBox(
                            width: stillW,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (stillImg != null) ...[
                                  CachedNetworkImage(
                                    imageUrl: stillImg,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => const ColoredBox(
                                      color: Color(0x0AFFFFFF),
                                    ),
                                    errorWidget: (_, _, _) => const ColoredBox(
                                      color: Color(0x0AFFFFFF),
                                    ),
                                  ),
                                  // Tauri: gradient to right from transparent to black/20
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.transparent,
                                          Color(0x33000000),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else
                                  const Center(
                                    child: Icon(
                                      Icons.play_arrow,
                                      color: Color(0x33FFFFFF),
                                      size: 22,
                                    ),
                                  ),

                                // SxxExx badge
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xB7000000),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      widget.epCode,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xE6FFFFFF),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),

                                // Watched tick overlay
                                if (widget.isWatched)
                                  const Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF34D399),
                                      size: 18,
                                    ),
                                  ),

                                // Local file indicator — cyan HardDrive
                                if (epLocalSrc != null)
                                  const Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Icon(
                                      Icons.storage,
                                      color: Color(0xFF22D3EE),
                                      size: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Metadata + play button
                          Expanded(
                            child: Container(
                              color: Colors.white.withAlpha(25),
                              padding: const EdgeInsets.fromLTRB(24, 16, 0, 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ep.title.isEmpty
                                              ? 'Episode ${ep.episodeNumber}'
                                              : ep.title,
                                          style: TextStyle(
                                            fontSize: (size.width * 0.01).clamp(
                                              14.0,
                                              17.0,
                                            ),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            if (ep.airDate != null)
                                              Text(
                                                ep.airDate!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0x66FFFFFF),
                                                ),
                                              ),
                                            if (ep.airDate != null &&
                                                ep.runtimeMinutes != null)
                                              const Text(
                                                ' · ',
                                                style: TextStyle(
                                                  color: Color(0x66FFFFFF),
                                                ),
                                              ),
                                            if (ep.runtimeMinutes != null)
                                              Text(
                                                '${ep.runtimeMinutes} min',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0x66FFFFFF),
                                                ),
                                              ),
                                            if (ep.voteAverage != null) ...[
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.star,
                                                size: 10,
                                                color: Color(0xE6EAB308),
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                ep.voteAverage!.toStringAsFixed(
                                                  1,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xE6EAB308),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (ep.overview != null &&
                                            ep.overview!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            ep.overview!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: (size.width * 0.0075)
                                                  .clamp(12.0, 14.0),
                                              color: Colors.white.withAlpha(
                                                115,
                                              ),
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Episode play button
                                  _EpisodePlayButton(
                                    watchedDone: watchedDone,
                                    epScrobblePct: epScrobblePct,
                                    hasLocalSource: epLocalSrc != null,
                                    isMarking: isMarking,
                                    onPlay: widget.onPlay,
                                    onMarkWatched: widget.onMarkWatched,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrobble progress bar — full card width, top edge (3px)
                    if (epScrobblePct != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          color: Colors.white.withAlpha(25),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (epScrobblePct / 100).clamp(0.0, 1.0),
                            child: Container(color: const Color(0xFFFBBF24)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Episode Play Button
// ─────────────────────────────────────────────────────────────────────────────

class _EpisodePlayButton extends StatefulWidget {
  final bool watchedDone;
  final double? epScrobblePct;
  final bool hasLocalSource;
  final bool isMarking;
  final VoidCallback onPlay;
  final Future<void> Function() onMarkWatched;

  const _EpisodePlayButton({
    required this.watchedDone,
    required this.epScrobblePct,
    required this.hasLocalSource,
    required this.isMarking,
    required this.onPlay,
    required this.onMarkWatched,
  });

  @override
  State<_EpisodePlayButton> createState() => _EpisodePlayButtonState();
}

class _EpisodePlayButtonState extends State<_EpisodePlayButton> {
  bool _hovered = false;

  // Tauri colors for episode play button
  Color get _bgColor => widget.watchedDone
      ? const Color(0x29109B60)
      : widget.epScrobblePct != null
      ? const Color(0xE6D97706)
      : const Color(0xD9E50914);

  Color get _textColor =>
      widget.watchedDone ? const Color(0xFF6EE7B7) : Colors.white;

  BoxBorder get _border => widget.watchedDone
      ? Border.all(color: const Color(0x59109B60))
      : Border.all(color: Colors.transparent);

  BoxShadow get _shadow => BoxShadow(
    color: widget.watchedDone
        ? const Color(0x29109B60)
        : widget.epScrobblePct != null
        ? const Color(0x66D97706)
        : const Color(0x4DE50914),
    blurRadius: 12,
    offset: const Offset(0, 2),
  );

  String get _label {
    if (widget.isMarking) return 'Updating...';
    if (widget.watchedDone) return 'Watched';
    if (widget.epScrobblePct != null) return 'Resume';
    return 'Play';
  }

  Widget get _icon {
    if (widget.isMarking) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
      );
    }
    if (widget.watchedDone) {
      return Icon(Icons.check_circle_outline, size: 14, color: _textColor);
    }
    if (widget.hasLocalSource) {
      return Icon(Icons.storage, size: 14, color: _textColor);
    }
    return Icon(Icons.play_arrow, size: 14, color: _textColor, fill: 1);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isMarking ? null : widget.onPlay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 20),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(8),
            border: _border,
            boxShadow: [_shadow],
          ),
          child: Opacity(
            opacity: widget.isMarking ? 0.8 : (_hovered ? 1.0 : 1.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _icon,
                const SizedBox(width: 8),
                Text(
                  _label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
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

// ─────────────────────────────────────────────────────────────────────────────
// Cast Section  (with chevrons — user requirement)
// ─────────────────────────────────────────────────────────────────────────────

class _CastSection extends StatefulWidget {
  final List<CastMember> cast;
  final double hPad;

  const _CastSection({required this.cast, required this.hPad});

  @override
  State<_CastSection> createState() => _CastSectionState();
}

class _CastSectionState extends State<_CastSection> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      padding: EdgeInsets.fromLTRB(widget.hPad, 48, 0, 56),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: widget.hPad),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cast',
                  style: TextStyle(
                    fontSize: (size.width * 0.0175).clamp(22.0, 28.0),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                // "View All" button — Tauri has this
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    'View All',
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Chevron + ribbon
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CastChevron(
                icon: Icons.chevron_left,
                onTap: () => _scroll.animateTo(
                  _scroll.offset - 320,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SizedBox(
                  height: 272,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: ListView.separated(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(right: widget.hPad - 4),
                      itemCount: widget.cast.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 16),
                      itemBuilder: (_, i) => _CastCard(member: widget.cast[i]),
                    ),
                  ),
                ),
              ),
              _CastChevron(
                icon: Icons.chevron_right,
                onTap: () => _scroll.animateTo(
                  _scroll.offset + 320,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                ),
              ),
              SizedBox(width: widget.hPad - 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _CastChevron extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CastChevron({required this.icon, required this.onTap});

  @override
  State<_CastChevron> createState() => _CastChevronState();
}

class _CastChevronState extends State<_CastChevron> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withAlpha(25) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: Colors.white.withAlpha(180),
            size: 50,
          ),
        ),
      ),
    );
  }
}

class _CastCard extends StatefulWidget {
  final CastMember member;
  const _CastCard({required this.member});

  @override
  State<_CastCard> createState() => _CastCardState();
}

class _CastCardState extends State<_CastCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final photo = (m.profileImage?.url ?? m.profilePath) != null
        ? posterUrl(m.profileImage?.url ?? m.profilePath!, size: 'w300')
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedSlide(
        offset: _hovered ? const Offset(0, -0.08) : Offset.zero,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 160,
          // Tauri: hover:shadow-[0_12px_24px_rgba(0,0,0,0.5)] hover:bg-white/[0.05]
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withAlpha(13)
                : Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? Colors.white.withAlpha(38)
                  : Colors.white.withAlpha(20),
            ),
            boxShadow: _hovered
                ? const [
                    BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 200,
                width: 160,
                child: photo != null
                    ? CachedNetworkImage(
                        imageUrl: photo,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const ColoredBox(color: Color(0x0DFFFFFF)),
                        errorWidget: (_, _, _) => const _NoPhoto(),
                      )
                    : const _NoPhoto(),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xE6FFFFFF),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (m.character != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          m.character!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0x80FFFFFF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoPhoto extends StatelessWidget {
  const _NoPhoto();

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0x0DFFFFFF),
    child: const Center(
      child: Icon(Icons.person_outline, color: Color(0x4DFFFFFF), size: 40),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Where to Watch Section
// ─────────────────────────────────────────────────────────────────────────────

class _WatchProvidersSection extends StatelessWidget {
  final WatchProvidersResponse providers;
  final double hPad;
  // D-pad chain: entryFocusNode goes on the very first logo rendered
  // (streaming's first if present, else rent/buy's first). onDirection is
  // shared across every logo in this section (up -> previous section;
  // down -> next section).
  final FocusNode entryFocusNode;
  final DpadDirectionCallback onDirection;

  const _WatchProvidersSection({
    required this.providers,
    required this.hPad,
    required this.entryFocusNode,
    required this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final combined = [...providers.rent, ...providers.buy];
    final firstIsStreaming = providers.streaming.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(hPad, 48, hPad, 56),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where to Watch',
            style: TextStyle(
              fontSize: (size.width * 0.0175).clamp(22.0, 28.0),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),

          if (providers.streaming.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Streaming Now',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xB3FFFFFF),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (var i = 0; i < providers.streaming.length; i++)
                  _ProviderLogo(
                    provider: providers.streaming[i],
                    focusNode: i == 0 ? entryFocusNode : null,
                    onDirection: onDirection,
                  ),
              ],
            ),
          ],

          if (combined.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Text(
              'Rent / Buy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xB3FFFFFF),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (var i = 0; i < combined.length; i++)
                  _ProviderLogo(
                    provider: combined[i],
                    focusNode: (!firstIsStreaming && i == 0) ? entryFocusNode : null,
                    onDirection: onDirection,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProviderLogo extends StatefulWidget {
  final WatchProvider provider;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;
  const _ProviderLogo({required this.provider, this.focusNode, this.onDirection});

  @override
  State<_ProviderLogo> createState() => _ProviderLogoState();
}

class _ProviderLogoState extends State<_ProviderLogo> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final imgUrl = p.logoPath != null
        ? 'https://image.tmdb.org/t/p/w92${p.logoPath}'
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      // These logos are purely informational (no action wired up in the
      // backend model yet) — focusable/halo-on-focus for D-pad reachability,
      // onSelect is a no-op.
      child: DpadFocusable(
        focusNode: widget.focusNode,
        onDirection: widget.onDirection,
        onSelect: () {},
        tapToSelect: false,
        builder: (context, state, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: state.focused
                ? [BoxShadow(color: WarpColors.accent.withAlpha(140), blurRadius: 18, spreadRadius: 2)]
                : null,
          ),
          child: AnimatedScale(
            scale: _hovered ? 1.10 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: imgUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: imgUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.white.withAlpha(13),
                      ),
                      errorWidget: (_, _, _) =>
                          _ProviderFallback(name: p.providerName),
                    ),
                  )
                : _ProviderFallback(name: p.providerName),
          ),
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _ProviderFallback extends StatelessWidget {
  final String name;
  const _ProviderFallback({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(13),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(
      child: Text(
        name.substring(0, math.min(3, name.length)).toUpperCase(),
        style: const TextStyle(
          color: Color(0x80FFFFFF),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Local Sources Section
// ─────────────────────────────────────────────────────────────────────────────

class _LocalSourcesSection extends StatelessWidget {
  final List<SourceRow> sources;
  final double hPad;
  final void Function(SourceRow) onPlay;
  // D-pad chain: entryFocusNode is the 1st source row (down-target from the
  // previous section). onEntryUp fires only for the 1st row's Up — this is
  // a vertical list, so intra-section Up/Down between rows is plain default
  // beam nav, and there's nothing below Local Sources.
  final FocusNode entryFocusNode;
  final DpadDirectionCallback onEntryUp;

  const _LocalSourcesSection({
    required this.sources,
    required this.hPad,
    required this.onPlay,
    required this.entryFocusNode,
    required this.onEntryUp,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      padding: EdgeInsets.fromLTRB(hPad, 40, hPad, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Local Sources',
            style: TextStyle(
              fontSize: (size.width * 0.0175).clamp(22.0, 28.0),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < sources.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SourceRow(
                source: sources[i],
                onPlay: () => onPlay(sources[i]),
                focusNode: i == 0 ? entryFocusNode : null,
                onDirection: i == 0 ? onEntryUp : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatefulWidget {
  final SourceRow source;
  final VoidCallback onPlay;
  final FocusNode? focusNode;
  final DpadDirectionCallback? onDirection;
  const _SourceRow({
    required this.source,
    required this.onPlay,
    this.focusNode,
    this.onDirection,
  });

  @override
  State<_SourceRow> createState() => _SourceRowState();
}

class _SourceRowState extends State<_SourceRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final src = widget.source;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DpadFocusable(
        focusNode: widget.focusNode,
        onDirection: widget.onDirection,
        onSelect: widget.onPlay,
        tapToSelect: false,
        builder: (context, state, child) => GestureDetector(
        onTap: () {
          widget.focusNode?.requestFocus();
          widget.onPlay();
        },
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(_hovered ? 13 : 8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: state.focused
                ? WarpColors.accent
                : Colors.white.withAlpha(_hovered ? 35 : 20),
            width: state.focused ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(13),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                (src.quality ?? src.sourceType).toUpperCase(),
                style: const TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                src.filePath ?? src.url,
                style: const TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.onPlay,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withAlpha(51)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Play',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Resume Modal Overlay  (matches Tauri exactly)
// ─────────────────────────────────────────────────────────────────────────────

class _ResumeModal extends StatelessWidget {
  final double? resumePercent;
  final VoidCallback onContinue;
  final VoidCallback onStartOver;
  final VoidCallback onCancel;

  const _ResumeModal({
    required this.resumePercent,
    required this.onContinue,
    required this.onStartOver,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Tauri: fixed inset-0 z-60 flex items-center justify-center
    //   bg: rgba(0,0,0,0.75) backdrop-blur-[8px]
    return GestureDetector(
      onTap: onCancel,
      child: Container(
        color: const Color(0xBF000000),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent dismiss on modal tap
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFA0C0C10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(25)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resume Playback',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resumePercent != null
                        ? 'You were ${resumePercent!.round()}% through. Continue from where you left off or start over?'
                        : 'Continue from where you left off or start over?',
                    style: const TextStyle(
                      color: Color(0x80FFFFFF),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Continue Watching button
                  _ResumeModalButton(
                    label: 'Continue Watching',
                    color: const Color(0xFFD97706),
                    textColor: Colors.white,
                    shadow: const Color(0x59D97706),
                    onTap: onContinue,
                  ),
                  const SizedBox(height: 12),

                  // Start Over button
                  _ResumeModalButton(
                    label: 'Start Over',
                    color: Colors.white.withAlpha(10),
                    textColor: Colors.white.withAlpha(165),
                    shadow: Colors.transparent,
                    borderColor: Colors.white.withAlpha(25),
                    onTap: onStartOver,
                  ),
                  const SizedBox(height: 12),

                  // Cancel (text only)
                  Center(
                    child: GestureDetector(
                      onTap: onCancel,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white.withAlpha(89),
                            fontSize: 14,
                          ),
                        ),
                      ),
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

class _ResumeModalButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color textColor;
  final Color shadow;
  final Color? borderColor;
  final VoidCallback onTap;

  const _ResumeModalButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.shadow,
    this.borderColor,
    required this.onTap,
  });

  @override
  State<_ResumeModalButton> createState() => _ResumeModalButtonState();
}

class _ResumeModalButtonState extends State<_ResumeModalButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withAlpha(220) : widget.color,
            borderRadius: BorderRadius.circular(12),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!)
                : null,
            boxShadow: [
              BoxShadow(
                color: widget.shadow,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
