import 'package:freezed_annotation/freezed_annotation.dart';

part 'library.freezed.dart';
part 'library.g.dart';

@freezed
abstract class LibrarySection with _$LibrarySection {
  const factory LibrarySection({
    required int id,
    required String name,
    required String kind,
    required List<String> paths,
    required int enabled,
    required String createdAt,
    required String updatedAt,
  }) = _LibrarySection;

  factory LibrarySection.fromJson(Map<String, dynamic> json) =>
      _$LibrarySectionFromJson(json);
}

@freezed
abstract class LibrarySectionsResponse with _$LibrarySectionsResponse {
  const factory LibrarySectionsResponse({
    required List<LibrarySection> sections,
    required int count,
  }) = _LibrarySectionsResponse;

  factory LibrarySectionsResponse.fromJson(Map<String, dynamic> json) =>
      _$LibrarySectionsResponseFromJson(json);
}

@freezed
abstract class SourceRow with _$SourceRow {
  const factory SourceRow({
    required int id,
    required int titleId,
    required String url,
    String? filePath,
    required String sourceType,
    String? quality,
    int? sizeBytes,
    String? scraper,
    String? lastChecked,
    int? fileSize,
    String? fileMtime,
    String? fileHash,
    required String status,
  }) = _SourceRow;

  factory SourceRow.fromJson(Map<String, dynamic> json) =>
      _$SourceRowFromJson(json);
}

@freezed
abstract class LibraryTitleDetail with _$LibraryTitleDetail {
  const factory LibraryTitleDetail({
    required int id,
    String? tmdbId,
    required String type,
    required String title,
    int? year,
    String? overview,
    String? posterUrl,
    String? backdropUrl,
    String? posterPath,
    String? backdropPath,
    required String addedAt,
    required String updatedAt,
    bool? hasLocalSource,
    int? sourceCount,
    List<String>? sourceTypes,
  }) = _LibraryTitleDetail;

  factory LibraryTitleDetail.fromJson(Map<String, dynamic> json) =>
      _$LibraryTitleDetailFromJson(json);
}

@freezed
abstract class TitleSourcesResponse with _$TitleSourcesResponse {
  const factory TitleSourcesResponse({
    required int titleId,
    required String title,
    String? sourceTypeFilter,
    required List<SourceRow> sources,
    required int count,
  }) = _TitleSourcesResponse;

  factory TitleSourcesResponse.fromJson(Map<String, dynamic> json) =>
      _$TitleSourcesResponseFromJson(json);
}

@freezed
abstract class TitleEpisode with _$TitleEpisode {
  const factory TitleEpisode({
    required int id,
    String? tmdbId,
    required int titleId,
    required int season,
    required int episode,
    String? name,
    String? airDate,
    required String addedAt,
    required String updatedAt,
  }) = _TitleEpisode;

  factory TitleEpisode.fromJson(Map<String, dynamic> json) =>
      _$TitleEpisodeFromJson(json);
}

@freezed
abstract class TitleEpisodesResponse with _$TitleEpisodesResponse {
  const factory TitleEpisodesResponse({
    required int titleId,
    required String title,
    int? seasonFilter,
    required List<TitleEpisode> episodes,
    required int count,
  }) = _TitleEpisodesResponse;

  factory TitleEpisodesResponse.fromJson(Map<String, dynamic> json) =>
      _$TitleEpisodesResponseFromJson(json);
}

@freezed
abstract class LibrarySearchItem with _$LibrarySearchItem {
  const factory LibrarySearchItem({
    required int id,
    String? tmdbId,
    required String type,
    required String title,
    int? year,
    String? overview,
    String? posterUrl,
    String? backdropUrl,
    String? posterPath,
    String? backdropPath,
    required String addedAt,
    required String updatedAt,
  }) = _LibrarySearchItem;

  factory LibrarySearchItem.fromJson(Map<String, dynamic> json) =>
      _$LibrarySearchItemFromJson(json);
}

@freezed
abstract class LibrarySearchResponse with _$LibrarySearchResponse {
  const factory LibrarySearchResponse({
    required String query,
    required List<LibrarySearchItem> items,
    required int count,
  }) = _LibrarySearchResponse;

  factory LibrarySearchResponse.fromJson(Map<String, dynamic> json) =>
      _$LibrarySearchResponseFromJson(json);
}

@freezed
abstract class LibraryListResponse with _$LibraryListResponse {
  const factory LibraryListResponse({
    required List<LibrarySearchItem> items,
    required int total,
    required int limit,
    required int offset,
    required bool hasNext,
  }) = _LibraryListResponse;

  factory LibraryListResponse.fromJson(Map<String, dynamic> json) =>
      _$LibraryListResponseFromJson(json);
}

@freezed
abstract class ScanStatus with _$ScanStatus {
  const factory ScanStatus({
    required String scanId,
    required String status,
    required int sectionsTotal,
    required int sectionsCompleted,
    required int filesFound,
    required int titlesAdded,
    required int titlesUpdated,
    required int sourcesAdded,
    String? currentFile,
    required double elapsedSeconds,
    required bool done,
  }) = _ScanStatus;

  factory ScanStatus.fromJson(Map<String, dynamic> json) =>
      _$ScanStatusFromJson(json);
}

@freezed
abstract class ScanResultSummary with _$ScanResultSummary {
  const factory ScanResultSummary({
    required int totalFiles,
    required int newTitles,
    required int updatedTitles,
    required int newEpisodes,
    required double durationSec,
  }) = _ScanResultSummary;

  factory ScanResultSummary.fromJson(Map<String, dynamic> json) =>
      _$ScanResultSummaryFromJson(json);
}

@freezed
abstract class ScanStatusResponse with _$ScanStatusResponse {
  const factory ScanStatusResponse({
    required bool running,
    required double progress,
    required String message,
    required List<String> logs,
    int? filesDone,
    int? filesTotal,
    ScanResultSummary? result,
  }) = _ScanStatusResponse;

  factory ScanStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$ScanStatusResponseFromJson(json);
}
