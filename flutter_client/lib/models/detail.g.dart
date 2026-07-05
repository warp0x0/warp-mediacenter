// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MediaCredits _$MediaCreditsFromJson(Map<String, dynamic> json) =>
    _MediaCredits(
      cast:
          (json['cast'] as List<dynamic>?)
              ?.map((e) => CastMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      crew: json['crew'] as List<dynamic>? ?? const [],
    );

Map<String, dynamic> _$MediaCreditsToJson(_MediaCredits instance) =>
    <String, dynamic>{
      'cast': instance.cast.map((e) => e.toJson()).toList(),
      'crew': instance.crew,
    };

_EpisodeDetail _$EpisodeDetailFromJson(Map<String, dynamic> json) =>
    _EpisodeDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      seasonNumber: (json['season_number'] as num?)?.toInt(),
      episodeNumber: (json['episode_number'] as num?)?.toInt(),
      overview: json['overview'] as String?,
      airDate: json['air_date'] as String?,
      runtimeMinutes: (json['runtime_minutes'] as num?)?.toInt(),
      poster: json['poster'] == null
          ? null
          : ImageAsset.fromJson(json['poster'] as Map<String, dynamic>),
      stillFrame: json['still_frame'] == null
          ? null
          : ImageAsset.fromJson(json['still_frame'] as Map<String, dynamic>),
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$EpisodeDetailToJson(_EpisodeDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'season_number': instance.seasonNumber,
      'episode_number': instance.episodeNumber,
      'overview': instance.overview,
      'air_date': instance.airDate,
      'runtime_minutes': instance.runtimeMinutes,
      'poster': instance.poster?.toJson(),
      'still_frame': instance.stillFrame?.toJson(),
      'vote_average': instance.voteAverage,
    };

_SeasonDetail _$SeasonDetailFromJson(Map<String, dynamic> json) =>
    _SeasonDetail(
      seasonNumber: (json['season_number'] as num).toInt(),
      episodeCount: (json['episode_count'] as num?)?.toInt(),
      title: json['title'] as String?,
      overview: json['overview'] as String?,
      poster: json['poster'] == null
          ? null
          : ImageAsset.fromJson(json['poster'] as Map<String, dynamic>),
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => EpisodeDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SeasonDetailToJson(_SeasonDetail instance) =>
    <String, dynamic>{
      'season_number': instance.seasonNumber,
      'episode_count': instance.episodeCount,
      'title': instance.title,
      'overview': instance.overview,
      'poster': instance.poster?.toJson(),
      'episodes': instance.episodes?.map((e) => e.toJson()).toList(),
    };

_MovieDetail _$MovieDetailFromJson(Map<String, dynamic> json) => _MovieDetail(
  id: json['id'] as String,
  title: json['title'] as String,
  overview: json['overview'] as String?,
  poster: json['poster'] == null
      ? null
      : ImageAsset.fromJson(json['poster'] as Map<String, dynamic>),
  backdrop: json['backdrop'] == null
      ? null
      : ImageAsset.fromJson(json['backdrop'] as Map<String, dynamic>),
  genres:
      (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  releaseDate: json['release_date'] as String?,
  runtimeMinutes: (json['runtime_minutes'] as num?)?.toInt(),
  tagline: json['tagline'] as String?,
  voteAverage: (json['vote_average'] as num?)?.toDouble(),
  voteCount: (json['vote_count'] as num?)?.toInt(),
  credits: MediaCredits.fromJson(json['credits'] as Map<String, dynamic>),
  trailers:
      (json['trailers'] as List<dynamic>?)
          ?.map((e) => Trailer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  imdbId: json['imdb_id'] as String?,
);

Map<String, dynamic> _$MovieDetailToJson(_MovieDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'overview': instance.overview,
      'poster': instance.poster?.toJson(),
      'backdrop': instance.backdrop?.toJson(),
      'genres': instance.genres,
      'release_date': instance.releaseDate,
      'runtime_minutes': instance.runtimeMinutes,
      'tagline': instance.tagline,
      'vote_average': instance.voteAverage,
      'vote_count': instance.voteCount,
      'credits': instance.credits.toJson(),
      'trailers': instance.trailers.map((e) => e.toJson()).toList(),
      'imdb_id': instance.imdbId,
    };

_ShowDetail _$ShowDetailFromJson(Map<String, dynamic> json) => _ShowDetail(
  id: json['id'] as String,
  title: json['title'] as String,
  overview: json['overview'] as String?,
  poster: json['poster'] == null
      ? null
      : ImageAsset.fromJson(json['poster'] as Map<String, dynamic>),
  backdrop: json['backdrop'] == null
      ? null
      : ImageAsset.fromJson(json['backdrop'] as Map<String, dynamic>),
  genres:
      (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  firstAirDate: json['first_air_date'] as String?,
  lastAirDate: json['last_air_date'] as String?,
  numberOfSeasons: (json['number_of_seasons'] as num?)?.toInt(),
  numberOfEpisodes: (json['number_of_episodes'] as num?)?.toInt(),
  voteAverage: (json['vote_average'] as num?)?.toDouble(),
  voteCount: (json['vote_count'] as num?)?.toInt(),
  credits: MediaCredits.fromJson(json['credits'] as Map<String, dynamic>),
  trailers:
      (json['trailers'] as List<dynamic>?)
          ?.map((e) => Trailer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  seasons:
      (json['seasons'] as List<dynamic>?)
          ?.map((e) => SeasonDetail.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  imdbId: json['imdb_id'] as String?,
);

Map<String, dynamic> _$ShowDetailToJson(_ShowDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'overview': instance.overview,
      'poster': instance.poster?.toJson(),
      'backdrop': instance.backdrop?.toJson(),
      'genres': instance.genres,
      'first_air_date': instance.firstAirDate,
      'last_air_date': instance.lastAirDate,
      'number_of_seasons': instance.numberOfSeasons,
      'number_of_episodes': instance.numberOfEpisodes,
      'vote_average': instance.voteAverage,
      'vote_count': instance.voteCount,
      'credits': instance.credits.toJson(),
      'trailers': instance.trailers.map((e) => e.toJson()).toList(),
      'seasons': instance.seasons.map((e) => e.toJson()).toList(),
      'imdb_id': instance.imdbId,
    };

_ImdbRatingResponse _$ImdbRatingResponseFromJson(Map<String, dynamic> json) =>
    _ImdbRatingResponse(
      imdbId: json['imdb_id'] as String,
      rating: (json['rating'] as num?)?.toDouble(),
      voteCount: (json['vote_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ImdbRatingResponseToJson(_ImdbRatingResponse instance) =>
    <String, dynamic>{
      'imdb_id': instance.imdbId,
      'rating': instance.rating,
      'vote_count': instance.voteCount,
    };

_ShowSeasonsResponse _$ShowSeasonsResponseFromJson(Map<String, dynamic> json) =>
    _ShowSeasonsResponse(
      showId: json['show_id'] as String,
      title: json['title'] as String,
      seasonsCount: (json['seasons_count'] as num).toInt(),
      seasons: (json['seasons'] as List<dynamic>)
          .map((e) => SeasonDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ShowSeasonsResponseToJson(
  _ShowSeasonsResponse instance,
) => <String, dynamic>{
  'show_id': instance.showId,
  'title': instance.title,
  'seasons_count': instance.seasonsCount,
  'seasons': instance.seasons.map((e) => e.toJson()).toList(),
};

_ShowProgressEpisode _$ShowProgressEpisodeFromJson(Map<String, dynamic> json) =>
    _ShowProgressEpisode(
      number: (json['number'] as num).toInt(),
      completed: json['completed'] as bool? ?? false,
      scrobbleProgress: (json['scrobble_progress'] as num?)?.toDouble(),
      playbackId: (json['playback_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ShowProgressEpisodeToJson(
  _ShowProgressEpisode instance,
) => <String, dynamic>{
  'number': instance.number,
  'completed': instance.completed,
  'scrobble_progress': instance.scrobbleProgress,
  'playback_id': instance.playbackId,
};

_ShowProgressSeason _$ShowProgressSeasonFromJson(Map<String, dynamic> json) =>
    _ShowProgressSeason(
      number: (json['number'] as num).toInt(),
      episodes:
          (json['episodes'] as List<dynamic>?)
              ?.map(
                (e) => ShowProgressEpisode.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ShowProgressSeasonToJson(_ShowProgressSeason instance) =>
    <String, dynamic>{
      'number': instance.number,
      'episodes': instance.episodes.map((e) => e.toJson()).toList(),
    };

_ShowProgressResponse _$ShowProgressResponseFromJson(
  Map<String, dynamic> json,
) => _ShowProgressResponse(
  aired: (json['aired'] as num?)?.toInt(),
  completed: (json['completed'] as num?)?.toInt(),
  seasons:
      (json['seasons'] as List<dynamic>?)
          ?.map((e) => ShowProgressSeason.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ShowProgressResponseToJson(
  _ShowProgressResponse instance,
) => <String, dynamic>{
  'aired': instance.aired,
  'completed': instance.completed,
  'seasons': instance.seasons.map((e) => e.toJson()).toList(),
};

_WatchProvider _$WatchProviderFromJson(Map<String, dynamic> json) =>
    _WatchProvider(
      providerId: (json['provider_id'] as num?)?.toInt(),
      providerName: json['provider_name'] as String,
      logoPath: json['logo_path'] as String?,
    );

Map<String, dynamic> _$WatchProviderToJson(_WatchProvider instance) =>
    <String, dynamic>{
      'provider_id': instance.providerId,
      'provider_name': instance.providerName,
      'logo_path': instance.logoPath,
    };

_WatchProvidersResponse _$WatchProvidersResponseFromJson(
  Map<String, dynamic> json,
) => _WatchProvidersResponse(
  movieId: json['movie_id'] as String,
  streaming:
      (json['streaming'] as List<dynamic>?)
          ?.map((e) => WatchProvider.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  rent:
      (json['rent'] as List<dynamic>?)
          ?.map((e) => WatchProvider.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  buy:
      (json['buy'] as List<dynamic>?)
          ?.map((e) => WatchProvider.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$WatchProvidersResponseToJson(
  _WatchProvidersResponse instance,
) => <String, dynamic>{
  'movie_id': instance.movieId,
  'streaming': instance.streaming.map((e) => e.toJson()).toList(),
  'rent': instance.rent.map((e) => e.toJson()).toList(),
  'buy': instance.buy.map((e) => e.toJson()).toList(),
};
