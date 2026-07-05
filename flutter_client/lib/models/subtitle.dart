import 'package:freezed_annotation/freezed_annotation.dart';

part 'subtitle.freezed.dart';
part 'subtitle.g.dart';

@freezed
abstract class SubtitleSearchResult with _$SubtitleSearchResult {
  const factory SubtitleSearchResult({
    required String provider,
    required String language,
    required double score,
    required String release,
    required String downloadLink,
    required String fileName,
    required bool hearingImpaired,
    double? rating,
    String? uploadedAt,
    @Default({}) Map<String, dynamic> metadata,
  }) = _SubtitleSearchResult;

  factory SubtitleSearchResult.fromJson(Map<String, dynamic> json) =>
      _$SubtitleSearchResultFromJson(json);
}

@freezed
abstract class SubtitleSearchResponse with _$SubtitleSearchResponse {
  const factory SubtitleSearchResponse({
    required String query,
    required String mediaKind,
    required String language,
    required List<SubtitleSearchResult> results,
    required int count,
  }) = _SubtitleSearchResponse;

  factory SubtitleSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$SubtitleSearchResponseFromJson(json);
}

@freezed
abstract class SubtitleDownloadResponse with _$SubtitleDownloadResponse {
  const factory SubtitleDownloadResponse({
    required String id,
    required String fileName,
    required String path,
    required String url,
  }) = _SubtitleDownloadResponse;

  factory SubtitleDownloadResponse.fromJson(Map<String, dynamic> json) =>
      _$SubtitleDownloadResponseFromJson(json);
}

@freezed
abstract class SubtitleLoadResponse with _$SubtitleLoadResponse {
  const factory SubtitleLoadResponse({
    required String status,
    required String path,
    String? url,
  }) = _SubtitleLoadResponse;

  factory SubtitleLoadResponse.fromJson(Map<String, dynamic> json) =>
      _$SubtitleLoadResponseFromJson(json);
}

@freezed
abstract class SubtitleTrack with _$SubtitleTrack {
  const factory SubtitleTrack({
    required String id,
    required String language,
    required String name,
    String? url,
  }) = _SubtitleTrack;

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) =>
      _$SubtitleTrackFromJson(json);
}
