import 'package:freezed_annotation/freezed_annotation.dart';
import 'media.dart';

part 'catalog.freezed.dart';
part 'catalog.g.dart';

@freezed
abstract class CatalogResponse with _$CatalogResponse {
  const factory CatalogResponse({
    required String category,
    required String mediaType,
    int? page,
    String? period,
    int? limit,
    int? offset,
    int? total,
    required List<MediaItem> items,
    required int count,
  }) = _CatalogResponse;

  factory CatalogResponse.fromJson(Map<String, dynamic> json) =>
      _$CatalogResponseFromJson(json);
}

@freezed
abstract class SearchResultItem with _$SearchResultItem {
  const factory SearchResultItem({
    required String source,
    Object? id,
    required String title,
    required String type,
    int? year,
    String? overview,
    String? posterUrl,
    String? posterPath,
    String? backdropPath,
    String? tmdbId,
    @Default([]) List<dynamic> genres,
    double? rating,
    Object? media,
  }) = _SearchResultItem;

  factory SearchResultItem.fromJson(Map<String, dynamic> json) =>
      _$SearchResultItemFromJson(json);
}

@freezed
abstract class SearchSourceCounts with _$SearchSourceCounts {
  const factory SearchSourceCounts({
    required int local,
    required int tmdb,
    required int trakt,
  }) = _SearchSourceCounts;

  factory SearchSourceCounts.fromJson(Map<String, dynamic> json) =>
      _$SearchSourceCountsFromJson(json);
}

@freezed
abstract class SearchResponse with _$SearchResponse {
  const factory SearchResponse({
    required String query,
    required List<SearchResultItem> results,
    required int count,
    required SearchSourceCounts sources,
  }) = _SearchResponse;

  factory SearchResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchResponseFromJson(json);
}

@freezed
abstract class WidgetConfig with _$WidgetConfig {
  const factory WidgetConfig({
    required String provider,
    required String category,
    required String title,
  }) = _WidgetConfig;

  factory WidgetConfig.fromJson(Map<String, dynamic> json) =>
      _$WidgetConfigFromJson(json);
}

@freezed
abstract class WidgetsConfigResponse with _$WidgetsConfigResponse {
  const factory WidgetsConfigResponse({
    required List<WidgetConfig> movies,
    required List<WidgetConfig> shows,
  }) = _WidgetsConfigResponse;

  factory WidgetsConfigResponse.fromJson(Map<String, dynamic> json) =>
      _$WidgetsConfigResponseFromJson(json);
}

@freezed
abstract class SaveWidgetsResponse with _$SaveWidgetsResponse {
  const factory SaveWidgetsResponse({
    required String message,
    required int moviesCount,
    required int showsCount,
  }) = _SaveWidgetsResponse;

  factory SaveWidgetsResponse.fromJson(Map<String, dynamic> json) =>
      _$SaveWidgetsResponseFromJson(json);
}
