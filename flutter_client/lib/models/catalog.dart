import 'package:freezed_annotation/freezed_annotation.dart';
import 'media.dart';

part 'catalog.freezed.dart';
part 'catalog.g.dart';

@freezed
abstract class CatalogResponse with _$CatalogResponse {
  const factory CatalogResponse({
    required String category,
    required String mediaType,
    String? source,
    String? listId,
    int? page,
    String? period,
    int? limit,
    int? offset,
    int? total,
    /// Whether more items exist past this window.
    ///
    /// This — not `offset + count < total` — is what Load More must branch on.
    /// `total` is a display hint that several sources cannot report at all
    /// (Simkl's genre browse returns no count) and that TMDb reports in the
    /// millions while capping how deep you can actually page. Nullable so a
    /// response from an older backend still parses.
    bool? hasMore,
    required List<MediaItem> items,
    required int count,
  }) = _CatalogResponse;

  factory CatalogResponse.fromJson(Map<String, dynamic> json) =>
      _$CatalogResponseFromJson(json);
}

/// One list a catalog source publishes — an entry in the Settings picker.
///
/// Mirrors `CatalogListDef` in `backend/plugins/contracts/catalog.py`. `params`
/// is opaque: it is stored verbatim in the widget config and handed back to the
/// source on fetch, so the client never has to understand what a source means
/// by `period` or `sort`.
@freezed
abstract class CatalogListDef with _$CatalogListDef {
  const factory CatalogListDef({
    required String id,
    required String title,
    @Default(['movie', 'show']) List<String> mediaTypes,
    @Default('other') String group,
    String? description,
    @Default(false) bool supportsPagination,
    @Default(20) int pageSize,
    Map<String, dynamic>? params,
    String? sortHint,
  }) = _CatalogListDef;

  factory CatalogListDef.fromJson(Map<String, dynamic> json) =>
      _$CatalogListDefFromJson(json);
}

/// A catalog source and everything it publishes.
///
/// `kind` is `builtin` (TMDb, My Library — always present), `legacy` (the
/// in-tree Trakt integration, hidden when a plugin shadows it) or `plugin`.
@freezed
abstract class CatalogSourceDef with _$CatalogSourceDef {
  const factory CatalogSourceDef({
    required String id,
    required String label,
    @Default('builtin') String kind,
    String? icon,
    @Default([]) List<CatalogListDef> lists,
  }) = _CatalogSourceDef;

  factory CatalogSourceDef.fromJson(Map<String, dynamic> json) =>
      _$CatalogSourceDefFromJson(json);
}

@freezed
abstract class CatalogDefinitions with _$CatalogDefinitions {
  const factory CatalogDefinitions({
    @Default([]) List<CatalogSourceDef> sources,
  }) = _CatalogDefinitions;

  factory CatalogDefinitions.fromJson(Map<String, dynamic> json) =>
      _$CatalogDefinitionsFromJson(json);
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

/// One configured home row.
///
/// `provider` predates the catalog plugin system and is still what the alias
/// routes key on; `source` is the catalog source id. They are the same string
/// for every source, and `source` falls back to `provider` when absent — that
/// is what lets a config saved before this system existed keep working.
@freezed
abstract class WidgetConfig with _$WidgetConfig {
  const factory WidgetConfig({
    required String provider,
    required String category,
    required String title,
    String? source,
    Map<String, dynamic>? params,
  }) = _WidgetConfig;

  factory WidgetConfig.fromJson(Map<String, dynamic> json) =>
      _$WidgetConfigFromJson(json);
}

extension WidgetConfigSource on WidgetConfig {
  /// The catalog source to fetch from.
  String get sourceId => source ?? provider;
}

@freezed
abstract class WidgetsConfigResponse with _$WidgetsConfigResponse {
  const factory WidgetsConfigResponse({
    required List<WidgetConfig> movies,
    required List<WidgetConfig> shows,
    @Default(1) int minWidgets,
    @Default(10) int maxWidgets,
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
