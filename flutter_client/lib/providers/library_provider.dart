import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../api/api_client.dart';
import '../models/collection.dart';
import '../models/library.dart';
import '../models/media.dart';
import 'catalog_provider.dart';

part 'library_provider.g.dart';

final collectionMutationVersionProvider =
    NotifierProvider<CollectionMutationVersionNotifier, int>(
      CollectionMutationVersionNotifier.new,
    );

class CollectionMutationVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

// ─────────────────────────────────────────────────────────────────────────────
// Library list providers
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<LibraryListResponse> libraryMovies(Ref ref) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>(
    '/api/v1/library/movies',
    params: {
      'limit': 30,
      'sort': 'added_at',
      'order': 'desc',
      'local_only': 'true',
    },
  );
  return LibraryListResponse.fromJson(raw);
}

@riverpod
Future<LibraryListResponse> libraryShows(Ref ref) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>(
    '/api/v1/library/shows',
    params: {
      'limit': 30,
      'sort': 'added_at',
      'order': 'desc',
      'local_only': 'true',
    },
  );
  return LibraryListResponse.fromJson(raw);
}

@riverpod
Future<LibraryListResponse> libraryMoviesAz(Ref ref) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>(
    '/api/v1/library/movies',
    params: {
      'limit': 30,
      'sort': 'title',
      'order': 'asc',
      'local_only': 'true',
    },
  );
  return LibraryListResponse.fromJson(raw);
}

@riverpod
Future<LibraryListResponse> libraryShowsAz(Ref ref) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>(
    '/api/v1/library/shows',
    params: {
      'limit': 30,
      'sort': 'title',
      'order': 'asc',
      'local_only': 'true',
    },
  );
  return LibraryListResponse.fromJson(raw);
}

@riverpod
Future<LibrarySearchResponse> librarySearch(Ref ref, String query) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>(
    '/api/v1/library/search',
    params: {'query': query, 'limit': 40},
  );
  return LibrarySearchResponse.fromJson(raw);
}

// ─────────────────────────────────────────────────────────────────────────────
// Collection providers — liked, wishlist
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<CollectionResponse> collection(Ref ref, String collectionType) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>(
    '/api/v1/collections/$collectionType',
    params: {'limit': 100},
  );
  return CollectionResponse.fromJson(raw);
}

// Per-item status — mirrors useIsLiked/useIsWishlisted.ts, used by PosterCard
// to self-manage its like/wishlist button state for any item with a tmdbId.
@riverpod
Future<bool> isLiked(Ref ref, String tmdbId) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>(
    '/api/v1/collections/liked/$tmdbId/status',
  );
  return CollectionStatusResponse.fromJson(raw).inCollection;
}

@riverpod
Future<bool> isWishlisted(Ref ref, String tmdbId) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>(
    '/api/v1/collections/wishlist/$tmdbId/status',
  );
  return CollectionStatusResponse.fromJson(raw).inCollection;
}

Future<void> toggleLiked(WidgetRef ref, MediaItem item) async {
  final tmdbId = item.tmdbId;
  if (tmdbId == null || tmdbId.isEmpty) return;
  final client = ref.read(apiClientProvider);
  final currentlyLiked =
      ref.read(isLikedProvider(tmdbId)).asData?.value ?? false;
  try {
    if (currentlyLiked) {
      await client.delete('/api/v1/collections/liked/$tmdbId');
    } else {
      await client.post<void>(
        '/api/v1/collections/liked',
        body: _collectionPayload(item, tmdbId),
      );
    }
  } finally {
    _refreshCollectionSurfaces(ref, tmdbId);
  }
}

Future<void> toggleWishlisted(WidgetRef ref, MediaItem item) async {
  final tmdbId = item.tmdbId;
  if (tmdbId == null || tmdbId.isEmpty) return;
  final client = ref.read(apiClientProvider);
  final currentlyWishlisted =
      ref.read(isWishlistedProvider(tmdbId)).asData?.value ?? false;
  try {
    if (currentlyWishlisted) {
      await client.delete('/api/v1/collections/wishlist/$tmdbId');
    } else {
      await client.post<void>(
        '/api/v1/collections/wishlist',
        body: _collectionPayload(item, tmdbId),
      );
    }
  } finally {
    _refreshCollectionSurfaces(ref, tmdbId);
  }
}

void _refreshCollectionSurfaces(WidgetRef ref, String tmdbId) {
  ref.read(collectionMutationVersionProvider.notifier).bump();
  ref.invalidate(isLikedProvider(tmdbId));
  ref.invalidate(isWishlistedProvider(tmdbId));
  ref.invalidate(collectionProvider('liked'));
  ref.invalidate(collectionProvider('wishlist'));
  ref.invalidate(catalogDataProvider);
}

Map<String, dynamic> _collectionPayload(MediaItem item, String tmdbId) => {
  'tmdb_id': tmdbId,
  'type': item.type,
  'title': item.title.isNotEmpty ? item.title : item.media.title,
  'year': item.year ?? item.media.year,
  'poster_path': item.posterPath ?? item.media.posterPath,
  'backdrop_path': item.backdropPath ?? item.media.backdropPath,
  'rating': item.rating ?? item.media.rating,
  'overview': item.overview ?? item.media.overview,
};

// ─────────────────────────────────────────────────────────────────────────────
// Scan status
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<ScanStatusResponse> scanStatus(Ref ref) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>(
    '/api/v1/settings/library/scan/status',
  );
  return ScanStatusResponse.fromJson(raw);
}

// ─────────────────────────────────────────────────────────────────────────────
// Adapter helpers — convert library/collection types to MediaItem
// ─────────────────────────────────────────────────────────────────────────────

MediaItem libraryItemToMedia(LibrarySearchItem item) => MediaItem(
  id: item.id.toString(),
  title: item.title,
  type: _normaliseType(item.type),
  sourceTag: 'local',
  year: item.year,
  overview: item.overview,
  // Mirror Tauri's toMediaItem: use poster_url (TMDb relative path) as poster.url.
  // poster_path is a local server disk path — not usable as a network image URL.
  poster: (item.posterUrl != null && item.posterUrl!.isNotEmpty)
      ? ImageAsset(url: item.posterUrl!)
      : null,
  posterPath: null,
  backdropPath: null,
  tmdbId: item.tmdbId,
  genres: const [],
  extra: const {},
  media: MediaNested(
    id: item.tmdbId ?? item.id.toString(),
    title: item.title,
    name: item.title,
    year: item.year,
    overview: item.overview,
    posterPath: null,
    backdropPath: null,
    genres: const [],
  ),
);

MediaItem collectionToMedia(UserCollection c) => MediaItem(
  id: c.id.toString(),
  title: c.title,
  type: _normaliseType(c.type),
  sourceTag: 'collection',
  year: c.year,
  overview: c.overview,
  posterPath: c.posterPath,
  backdropPath: c.backdropPath,
  tmdbId: c.tmdbId,
  rating: c.rating,
  genres: c.genres,
  extra: const {},
  media: MediaNested(
    id: c.tmdbId,
    title: c.title,
    name: c.title,
    year: c.year,
    overview: c.overview,
    posterPath: c.posterPath,
    backdropPath: c.backdropPath,
    genres: const [],
  ),
);

String _normaliseType(String t) =>
    (t == 'tv' || t == 'show') ? 'show' : 'movie';
