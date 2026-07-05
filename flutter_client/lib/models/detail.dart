import 'package:freezed_annotation/freezed_annotation.dart';
import 'media.dart';

part 'detail.freezed.dart';
part 'detail.g.dart';

@freezed
abstract class MediaCredits with _$MediaCredits {
  const factory MediaCredits({
    @Default([]) List<CastMember> cast,
    @Default([]) List<dynamic> crew,
  }) = _MediaCredits;

  factory MediaCredits.fromJson(Map<String, dynamic> json) =>
      _$MediaCreditsFromJson(json);
}

@freezed
abstract class EpisodeDetail with _$EpisodeDetail {
  const factory EpisodeDetail({
    required String id,
    required String title,
    int? seasonNumber,
    int? episodeNumber,
    String? overview,
    String? airDate,
    int? runtimeMinutes,
    ImageAsset? poster,
    ImageAsset? stillFrame,
    double? voteAverage,
  }) = _EpisodeDetail;

  factory EpisodeDetail.fromJson(Map<String, dynamic> json) =>
      _$EpisodeDetailFromJson(json);
}

@freezed
abstract class SeasonDetail with _$SeasonDetail {
  const factory SeasonDetail({
    required int seasonNumber,
    int? episodeCount,
    String? title,
    String? overview,
    ImageAsset? poster,
    List<EpisodeDetail>? episodes,
  }) = _SeasonDetail;

  factory SeasonDetail.fromJson(Map<String, dynamic> json) =>
      _$SeasonDetailFromJson(json);
}

@freezed
abstract class MovieDetail with _$MovieDetail {
  const factory MovieDetail({
    required String id,
    required String title,
    String? overview,
    ImageAsset? poster,
    ImageAsset? backdrop,
    @Default([]) List<String> genres,
    String? releaseDate,
    int? runtimeMinutes,
    String? tagline,
    double? voteAverage,
    int? voteCount,
    required MediaCredits credits,
    @Default([]) List<Trailer> trailers,
    String? imdbId,
  }) = _MovieDetail;

  factory MovieDetail.fromJson(Map<String, dynamic> json) =>
      _$MovieDetailFromJson(json);
}

@freezed
abstract class ShowDetail with _$ShowDetail {
  const factory ShowDetail({
    required String id,
    required String title,
    String? overview,
    ImageAsset? poster,
    ImageAsset? backdrop,
    @Default([]) List<String> genres,
    String? firstAirDate,
    String? lastAirDate,
    int? numberOfSeasons,
    int? numberOfEpisodes,
    double? voteAverage,
    int? voteCount,
    required MediaCredits credits,
    @Default([]) List<Trailer> trailers,
    @Default([]) List<SeasonDetail> seasons,
    String? imdbId,
  }) = _ShowDetail;

  factory ShowDetail.fromJson(Map<String, dynamic> json) =>
      _$ShowDetailFromJson(json);
}

@freezed
abstract class ImdbRatingResponse with _$ImdbRatingResponse {
  const factory ImdbRatingResponse({
    required String imdbId,
    double? rating,
    int? voteCount,
  }) = _ImdbRatingResponse;

  factory ImdbRatingResponse.fromJson(Map<String, dynamic> json) =>
      _$ImdbRatingResponseFromJson(json);
}

@freezed
abstract class ShowSeasonsResponse with _$ShowSeasonsResponse {
  const factory ShowSeasonsResponse({
    required String showId,
    required String title,
    required int seasonsCount,
    required List<SeasonDetail> seasons,
  }) = _ShowSeasonsResponse;

  factory ShowSeasonsResponse.fromJson(Map<String, dynamic> json) =>
      _$ShowSeasonsResponseFromJson(json);
}

// ── Show watched-progress (Trakt) ────────────────────────────────────────────

@freezed
abstract class ShowProgressEpisode with _$ShowProgressEpisode {
  const factory ShowProgressEpisode({
    required int number,
    @Default(false) bool completed,
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
    @Default([]) List<ShowProgressEpisode> episodes,
  }) = _ShowProgressSeason;

  factory ShowProgressSeason.fromJson(Map<String, dynamic> json) =>
      _$ShowProgressSeasonFromJson(json);
}

@freezed
abstract class ShowProgressResponse with _$ShowProgressResponse {
  const factory ShowProgressResponse({
    int? aired,
    int? completed,
    @Default([]) List<ShowProgressSeason> seasons,
  }) = _ShowProgressResponse;

  factory ShowProgressResponse.fromJson(Map<String, dynamic> json) =>
      _$ShowProgressResponseFromJson(json);
}

// ── Watch Providers ────────────────────────────────────────────────────────────

@freezed
abstract class WatchProvider with _$WatchProvider {
  const factory WatchProvider({
    int? providerId,
    required String providerName,
    String? logoPath,
  }) = _WatchProvider;

  factory WatchProvider.fromJson(Map<String, dynamic> json) =>
      _$WatchProviderFromJson(json);
}

@freezed
abstract class WatchProvidersResponse with _$WatchProvidersResponse {
  const factory WatchProvidersResponse({
    required String movieId,
    @Default([]) List<WatchProvider> streaming,
    @Default([]) List<WatchProvider> rent,
    @Default([]) List<WatchProvider> buy,
  }) = _WatchProvidersResponse;

  factory WatchProvidersResponse.fromJson(Map<String, dynamic> json) =>
      _$WatchProvidersResponseFromJson(json);
}
