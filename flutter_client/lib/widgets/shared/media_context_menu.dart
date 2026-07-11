import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/media.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/library_provider.dart';
import 'warp_context_menu.dart';

List<WarpContextMenuItem> buildMediaContextMenuItems(
  WidgetRef ref,
  MediaItem item, {
  required bool liked,
  required bool wishlisted,
}) {
  final tmdbId = item.tmdbId;
  if (tmdbId == null || tmdbId.isEmpty) return const [];

  return [
    WarpContextMenuItem(
      label: 'Mark as Watched',
      icon: Icons.check_circle_outline,
      onSelected: () => markMediaWatched(ref, item),
    ),
    WarpContextMenuItem(
      label: liked ? 'Unlike' : 'Like',
      icon: liked ? Icons.favorite : Icons.favorite_border,
      onSelected: () => toggleLiked(ref, item),
    ),
    WarpContextMenuItem(
      label: wishlisted ? 'Remove from Wishlist' : 'Add to Wishlist',
      icon: wishlisted ? Icons.bookmark_remove : Icons.bookmark_add_outlined,
      onSelected: () => toggleWishlisted(ref, item),
    ),
  ];
}

Future<void> markMediaWatched(WidgetRef ref, MediaItem item) async {
  final tmdbId = item.tmdbId;
  if (tmdbId == null || tmdbId.isEmpty) return;

  final client = ref.read(apiClientProvider);
  await client.post<void>(
    '/api/v1/library/mark-watched',
    body: {
      'tmdb_id': tmdbId,
      'media_type': item.type == 'show' ? 'show' : 'movie',
      'title': item.title.isNotEmpty ? item.title : item.media.title,
      'year': item.year ?? item.media.year,
      'overview': item.overview ?? item.media.overview,
      'poster_path': item.posterPath ?? item.media.posterPath,
      'backdrop_path': item.backdropPath ?? item.media.backdropPath,
    },
  );

  _refreshMediaSurfaces(ref, tmdbId);
}

void _refreshMediaSurfaces(WidgetRef ref, String tmdbId) {
  ref.invalidate(catalogDataProvider);
  ref.invalidate(libraryMoviesProvider);
  ref.invalidate(libraryShowsProvider);
  ref.invalidate(libraryMoviesAzProvider);
  ref.invalidate(libraryShowsAzProvider);
  ref.invalidate(isLikedProvider(tmdbId));
  ref.invalidate(isWishlistedProvider(tmdbId));
}
