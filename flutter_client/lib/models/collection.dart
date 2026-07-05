import 'package:freezed_annotation/freezed_annotation.dart';

part 'collection.freezed.dart';
part 'collection.g.dart';

@freezed
abstract class UserCollection with _$UserCollection {
  const factory UserCollection({
    required int id,
    required String collectionType,
    required String tmdbId,
    required String type,
    required String title,
    int? year,
    String? overview,
    String? posterPath,
    String? backdropPath,
    double? rating,
    int? voteCount,
    @Default([]) List<String> genres,
    required String addedAt,
  }) = _UserCollection;

  factory UserCollection.fromJson(Map<String, dynamic> json) =>
      _$UserCollectionFromJson(json);
}

@freezed
abstract class CollectionResponse with _$CollectionResponse {
  const factory CollectionResponse({
    required String collectionType,
    required List<UserCollection> items,
    required int count,
    required int page,
    required int limit,
  }) = _CollectionResponse;

  factory CollectionResponse.fromJson(Map<String, dynamic> json) =>
      _$CollectionResponseFromJson(json);
}

@freezed
abstract class CollectionStatusResponse with _$CollectionStatusResponse {
  const factory CollectionStatusResponse({
    required String tmdbId,
    required bool inCollection,
  }) = _CollectionStatusResponse;

  factory CollectionStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$CollectionStatusResponseFromJson(json);
}

@freezed
abstract class CollectionItemPayload with _$CollectionItemPayload {
  const factory CollectionItemPayload({
    required String tmdbId,
    required String type,
    required String title,
    int? year,
    String? overview,
    String? posterPath,
    String? backdropPath,
    double? rating,
    int? voteCount,
    @Default([]) List<String> genres,
  }) = _CollectionItemPayload;

  factory CollectionItemPayload.fromJson(Map<String, dynamic> json) =>
      _$CollectionItemPayloadFromJson(json);
}

@freezed
abstract class ShowProgressEpisode with _$ShowProgressEpisode {
  const factory ShowProgressEpisode({
    required int number,
    required bool completed,
    String? lastWatchedAt,
    double? scrobbleProgress,
    int? playbackId,
  }) = _ShowProgressEpisode;

  factory ShowProgressEpisode.fromJson(Map<String, dynamic> json) =>
      _$ShowProgressEpisodeFromJson(json);
}

@freezed
abstract class ShowProgressSeason with _$ShowProgressSeason {
  const factory ShowProgressSeason({
    required int number,
    int? aired,
    int? completed,
    required List<ShowProgressEpisode> episodes,
  }) = _ShowProgressSeason;

  factory ShowProgressSeason.fromJson(Map<String, dynamic> json) =>
      _$ShowProgressSeasonFromJson(json);
}

@freezed
abstract class ShowProgressResponse with _$ShowProgressResponse {
  const factory ShowProgressResponse({
    required String traktId,
    required String tmdbId,
    int? aired,
    int? completed,
    required List<ShowProgressSeason> seasons,
  }) = _ShowProgressResponse;

  factory ShowProgressResponse.fromJson(Map<String, dynamic> json) =>
      _$ShowProgressResponseFromJson(json);
}
