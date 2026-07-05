import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../api/api_client.dart';
import '../models/detail.dart';
import '../models/library.dart';

part 'detail_provider.g.dart';

/// Singleton route observer. Registered in GoRouter; DetailPage subscribes to
/// it so didPopNext() fires exactly when PlaybackPage is popped off the stack.
final routeObserver = RouteObserver<ModalRoute<dynamic>>();

/// Incrementing this counter signals playback teardown to all listening pages.
/// PlaybackPage increments it on exit; home and detail pages listen and re-fetch.
class PlaybackEndedNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void increment() => state++;
}

final playbackEndedProvider =
    NotifierProvider<PlaybackEndedNotifier, int>(PlaybackEndedNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Library title detail — returns null if not in library (404)
// Endpoint: GET /api/v1/library/title/{tmdbId}
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<LibraryTitleDetail?> titleDetail(Ref ref, String tmdbId) async {
  final client = ref.watch(apiClientProvider);
  try {
    final raw = await client.get<Map<String, dynamic>>('/api/v1/library/title/$tmdbId');
    return LibraryTitleDetail.fromJson(raw);
  } on ApiError catch (e) {
    if (e.isNotFound) return null;
    rethrow;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Library sources for a title
// Endpoint: GET /api/v1/library/title/{tmdbId}/sources
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<List<SourceRow>> titleSources(Ref ref, String tmdbId) async {
  final client = ref.watch(apiClientProvider);
  try {
    final raw = await client.get<Map<String, dynamic>>('/api/v1/library/title/$tmdbId/sources');
    return TitleSourcesResponse.fromJson(raw).sources;
  } on ApiError catch (e) {
    if (e.isNotFound) return [];
    rethrow;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rich movie detail (TMDB metadata: cast, trailers, tagline, runtime)
// Endpoint: GET /api/v1/catalog/detail/movie/{tmdbId}
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<MovieDetail?> movieRichDetail(Ref ref, String tmdbId) async {
  final client = ref.watch(apiClientProvider);
  try {
    final raw = await client.get<Map<String, dynamic>>('/api/v1/catalog/detail/movie/$tmdbId');
    return MovieDetail.fromJson(raw);
  } on ApiError catch (e) {
    if (e.isNotFound) return null;
    rethrow;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rich show detail (TMDB metadata: cast, trailers, seasons count)
// Endpoint: GET /api/v1/catalog/detail/show/{tmdbId}
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<ShowDetail?> showRichDetail(Ref ref, String tmdbId) async {
  final client = ref.watch(apiClientProvider);
  try {
    final raw = await client.get<Map<String, dynamic>>('/api/v1/catalog/detail/show/$tmdbId');
    return ShowDetail.fromJson(raw);
  } on ApiError catch (e) {
    if (e.isNotFound) return null;
    rethrow;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Show seasons with episode lists
// Endpoint: GET /api/v1/catalog/show/{tmdbId}/seasons
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<ShowSeasonsResponse?> showSeasonsList(Ref ref, String tmdbId) async {
  final client = ref.watch(apiClientProvider);
  try {
    final raw = await client.get<Map<String, dynamic>>('/api/v1/catalog/show/$tmdbId/seasons');
    return ShowSeasonsResponse.fromJson(raw);
  } on ApiError catch (e) {
    if (e.isNotFound) return null;
    rethrow;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Show watched-progress via Trakt
// Endpoint: GET /api/v1/catalog/trakt/show_progress/{tmdbId}
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<ShowProgressResponse?> showProgress(Ref ref, String tmdbId) async {
  final client = ref.watch(apiClientProvider);
  try {
    final raw = await client.get<Map<String, dynamic>>(
      '/api/v1/catalog/trakt/show_progress/$tmdbId',
    );
    return ShowProgressResponse.fromJson(raw);
  } catch (_) {
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Watch providers (streaming / rent / buy)
// Endpoint: GET /api/v1/catalog/detail/{movie|show}/{tmdbId}/providers
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<WatchProvidersResponse?> watchProviders(
  Ref ref,
  String tmdbId,
  String mediaType,
) async {
  final client = ref.watch(apiClientProvider);
  final path = mediaType == 'show'
      ? '/api/v1/catalog/detail/show/$tmdbId/providers'
      : '/api/v1/catalog/detail/movie/$tmdbId/providers';
  try {
    final raw = await client.get<Map<String, dynamic>>(path);
    return WatchProvidersResponse.fromJson(raw);
  } catch (_) {
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMDB rating lookup
// Endpoint: GET /api/v1/catalog/imdb-rating/{imdbId}
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<ImdbRatingResponse?> imdbRating(Ref ref, String imdbId) async {
  final client = ref.watch(apiClientProvider);
  try {
    final raw = await client.get<Map<String, dynamic>>('/api/v1/catalog/imdb-rating/$imdbId');
    return ImdbRatingResponse.fromJson(raw);
  } catch (_) {
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Movie playback progress — scrobble/pause progress from Trakt for a single movie.
// Not code-generated so no build_runner run needed.
// Endpoint: GET /api/v1/catalog/trakt/movie_progress/{tmdbId}
// ─────────────────────────────────────────────────────────────────────────────

typedef MovieProgressData = ({double progress, bool resumeAvailable});

final movieProgressProvider = FutureProvider.autoDispose
    .family<MovieProgressData, String>((ref, tmdbId) async {
  final client = ref.watch(apiClientProvider);
  try {
    final raw = await client.get<Map<String, dynamic>>(
      '/api/v1/catalog/trakt/movie_progress/$tmdbId',
    );
    return (
      progress: (raw['progress'] as num?)?.toDouble() ?? 0.0,
      resumeAvailable: raw['resume_available'] as bool? ?? false,
    );
  } catch (_) {
    return (progress: 0.0, resumeAvailable: false);
  }
});
