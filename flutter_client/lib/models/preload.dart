import 'package:freezed_annotation/freezed_annotation.dart';

part 'preload.freezed.dart';
part 'preload.g.dart';

@freezed
abstract class PreloadStatus with _$PreloadStatus {
  const factory PreloadStatus({
    required String url,
    required bool active,
    required int bytesDownloaded,
    required int totalSize,
    required double percent,
    required bool downloadComplete,
  }) = _PreloadStatus;

  factory PreloadStatus.fromJson(Map<String, dynamic> json) =>
      _$PreloadStatusFromJson(json);
}

@freezed
abstract class PreloadSessionCreateRequest with _$PreloadSessionCreateRequest {
  const factory PreloadSessionCreateRequest({
    String? streamUrl,
    String? magnet,
    String? title,
    String? mediaKind,
    Map<String, dynamic>? metadata,
    double? startPercent,
  }) = _PreloadSessionCreateRequest;

  factory PreloadSessionCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$PreloadSessionCreateRequestFromJson(json);
}

@freezed
abstract class PreloadSessionCreateResponse with _$PreloadSessionCreateResponse {
  const factory PreloadSessionCreateResponse({
    required String sessionId,
    required String playbackUrl,
    String? localUrl,
    required String statusUrl,
    required String cleanupUrl,
    required String createdAt,
  }) = _PreloadSessionCreateResponse;

  factory PreloadSessionCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$PreloadSessionCreateResponseFromJson(json);
}

@freezed
abstract class PreloadSessionStatus with _$PreloadSessionStatus {
  const factory PreloadSessionStatus({
    required String sessionId,
    required String url,
    required bool active,
    required int bytesDownloaded,
    required int totalSize,
    int? remainingSize,
    required double percent,
    required bool downloadComplete,
    String? error,
    required String state,
    String? title,
    String? mediaKind,
    required String playbackUrl,
    bool? localTorrent,
    required int bufferAheadBytes,
    required int activeStreams,
    required String createdAt,
    required String updatedAt,
  }) = _PreloadSessionStatus;

  factory PreloadSessionStatus.fromJson(Map<String, dynamic> json) =>
      _$PreloadSessionStatusFromJson(json);
}
