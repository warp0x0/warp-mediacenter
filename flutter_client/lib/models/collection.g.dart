// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserCollection _$UserCollectionFromJson(Map<String, dynamic> json) =>
    _UserCollection(
      id: (json['id'] as num).toInt(),
      collectionType: json['collection_type'] as String,
      tmdbId: json['tmdb_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      year: (json['year'] as num?)?.toInt(),
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      voteCount: (json['vote_count'] as num?)?.toInt(),
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      addedAt: json['added_at'] as String,
    );

Map<String, dynamic> _$UserCollectionToJson(_UserCollection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'collection_type': instance.collectionType,
      'tmdb_id': instance.tmdbId,
      'type': instance.type,
      'title': instance.title,
      'year': instance.year,
      'overview': instance.overview,
      'poster_path': instance.posterPath,
      'backdrop_path': instance.backdropPath,
      'rating': instance.rating,
      'vote_count': instance.voteCount,
      'genres': instance.genres,
      'added_at': instance.addedAt,
    };

_CollectionResponse _$CollectionResponseFromJson(Map<String, dynamic> json) =>
    _CollectionResponse(
      collectionType: json['collection_type'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => UserCollection.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );

Map<String, dynamic> _$CollectionResponseToJson(_CollectionResponse instance) =>
    <String, dynamic>{
      'collection_type': instance.collectionType,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'count': instance.count,
      'page': instance.page,
      'limit': instance.limit,
    };

_CollectionStatusResponse _$CollectionStatusResponseFromJson(
  Map<String, dynamic> json,
) => _CollectionStatusResponse(
  tmdbId: json['tmdb_id'] as String,
  inCollection: json['in_collection'] as bool,
);

Map<String, dynamic> _$CollectionStatusResponseToJson(
  _CollectionStatusResponse instance,
) => <String, dynamic>{
  'tmdb_id': instance.tmdbId,
  'in_collection': instance.inCollection,
};

_CollectionItemPayload _$CollectionItemPayloadFromJson(
  Map<String, dynamic> json,
) => _CollectionItemPayload(
  tmdbId: json['tmdb_id'] as String,
  type: json['type'] as String,
  title: json['title'] as String,
  year: (json['year'] as num?)?.toInt(),
  overview: json['overview'] as String?,
  posterPath: json['poster_path'] as String?,
  backdropPath: json['backdrop_path'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  voteCount: (json['vote_count'] as num?)?.toInt(),
  genres:
      (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$CollectionItemPayloadToJson(
  _CollectionItemPayload instance,
) => <String, dynamic>{
  'tmdb_id': instance.tmdbId,
  'type': instance.type,
  'title': instance.title,
  'year': instance.year,
  'overview': instance.overview,
  'poster_path': instance.posterPath,
  'backdrop_path': instance.backdropPath,
  'rating': instance.rating,
  'vote_count': instance.voteCount,
  'genres': instance.genres,
};

_ShowProgressEpisode _$ShowProgressEpisodeFromJson(Map<String, dynamic> json) =>
    _ShowProgressEpisode(
      number: (json['number'] as num).toInt(),
      completed: json['completed'] as bool,
      lastWatchedAt: json['last_watched_at'] as String?,
      scrobbleProgress: (json['scrobble_progress'] as num?)?.toDouble(),
      playbackId: (json['playback_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ShowProgressEpisodeToJson(
  _ShowProgressEpisode instance,
) => <String, dynamic>{
  'number': instance.number,
  'completed': instance.completed,
  'last_watched_at': instance.lastWatchedAt,
  'scrobble_progress': instance.scrobbleProgress,
  'playback_id': instance.playbackId,
};

_ShowProgressSeason _$ShowProgressSeasonFromJson(Map<String, dynamic> json) =>
    _ShowProgressSeason(
      number: (json['number'] as num).toInt(),
      aired: (json['aired'] as num?)?.toInt(),
      completed: (json['completed'] as num?)?.toInt(),
      episodes: (json['episodes'] as List<dynamic>)
          .map((e) => ShowProgressEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ShowProgressSeasonToJson(_ShowProgressSeason instance) =>
    <String, dynamic>{
      'number': instance.number,
      'aired': instance.aired,
      'completed': instance.completed,
      'episodes': instance.episodes.map((e) => e.toJson()).toList(),
    };

_ShowProgressResponse _$ShowProgressResponseFromJson(
  Map<String, dynamic> json,
) => _ShowProgressResponse(
  traktId: json['trakt_id'] as String,
  tmdbId: json['tmdb_id'] as String,
  aired: (json['aired'] as num?)?.toInt(),
  completed: (json['completed'] as num?)?.toInt(),
  seasons: (json['seasons'] as List<dynamic>)
      .map((e) => ShowProgressSeason.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ShowProgressResponseToJson(
  _ShowProgressResponse instance,
) => <String, dynamic>{
  'trakt_id': instance.traktId,
  'tmdb_id': instance.tmdbId,
  'aired': instance.aired,
  'completed': instance.completed,
  'seasons': instance.seasons.map((e) => e.toJson()).toList(),
};
