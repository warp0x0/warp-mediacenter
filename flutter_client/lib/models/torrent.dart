import 'package:freezed_annotation/freezed_annotation.dart';

part 'torrent.freezed.dart';
part 'torrent.g.dart';

@freezed
abstract class TorrentSearchRequest with _$TorrentSearchRequest {
  const factory TorrentSearchRequest({
    required String query,
    String? mediaType,
    String? tmdbId,
    int? season,
    int? episode,
    int? year,
    int? limit,
  }) = _TorrentSearchRequest;

  factory TorrentSearchRequest.fromJson(Map<String, dynamic> json) =>
      _$TorrentSearchRequestFromJson(json);
}

@freezed
abstract class TorrentResult with _$TorrentResult {
  const factory TorrentResult({
    required String name,
    required String hash,
    required String magnet,
    required int seeders,
    required int leechers,
    required String size,
    required int sizeBytes,
    required String sourceSite,
    required String quality,
    required bool isCached,
    required double matchScore,
    required String uploader,
    required String date,
  }) = _TorrentResult;

  factory TorrentResult.fromJson(Map<String, dynamic> json) =>
      _$TorrentResultFromJson(json);
}

@freezed
abstract class TorrentSearchResponse with _$TorrentSearchResponse {
  const factory TorrentSearchResponse({
    required List<TorrentResult> filtered,
    required List<TorrentResult> unfiltered,
    required String query,
    required String mediaType,
  }) = _TorrentSearchResponse;

  factory TorrentSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$TorrentSearchResponseFromJson(json);
}

@freezed
abstract class TorrentStatus with _$TorrentStatus {
  const factory TorrentStatus({
    required String torrentId,
    required String name,
    required String status,
    required double progress,
    required double speed,
    required int seeders,
    required int linksCount,
    required String title,
    required String mediaType,
    int? season,
    int? episode,
    required double elapsedSeconds,
    required String message,
  }) = _TorrentStatus;

  factory TorrentStatus.fromJson(Map<String, dynamic> json) =>
      _$TorrentStatusFromJson(json);
}

@freezed
abstract class TorrentResolveResponse with _$TorrentResolveResponse {
  const factory TorrentResolveResponse({
    required String torrentId,
    required String status,
    String? selectedFile,
    required String message,
  }) = _TorrentResolveResponse;

  factory TorrentResolveResponse.fromJson(Map<String, dynamic> json) =>
      _$TorrentResolveResponseFromJson(json);
}
