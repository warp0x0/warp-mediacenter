import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';
part 'player.g.dart';

@freezed
abstract class PlayerState with _$PlayerState {
  const factory PlayerState({
    required int positionMs,
    required int durationMs,
    required bool isPlaying,
    required double volume,
  }) = _PlayerState;

  factory PlayerState.fromJson(Map<String, dynamic> json) =>
      _$PlayerStateFromJson(json);
}

@freezed
abstract class PlayerStatus with _$PlayerStatus {
  const factory PlayerStatus({
    required bool playing,
    String? title,
    String? mediaKind,
    String? source,
    String? state,
    int? positionMs,
    int? durationMs,
    double? volume,
    double? rate,
    bool? isStream,
    String? subtitlePath,
    int? audioTrackId,
    int? subtitleTrackId,
    String? startedAt,
  }) = _PlayerStatus;

  factory PlayerStatus.fromJson(Map<String, dynamic> json) =>
      _$PlayerStatusFromJson(json);
}

@freezed
abstract class PlayerPlayRequest with _$PlayerPlayRequest {
  const factory PlayerPlayRequest({
    required String source,
    String? sessionId,
    String? title,
    String? mediaKind,
    String? mediaFolder,
    int? season,
    int? episode,
    int? year,
    String? language,
    bool? startPaused,
    bool? isStream,
    bool? autoSubtitles,
    bool? resumeFromLastPosition,
    String? tmdbId,
    Object? mediaPayload,
    Object? showPayload,
    String? sourceType,
  }) = _PlayerPlayRequest;

  factory PlayerPlayRequest.fromJson(Map<String, dynamic> json) =>
      _$PlayerPlayRequestFromJson(json);
}

@freezed
abstract class PlayerPlayResponse with _$PlayerPlayResponse {
  const factory PlayerPlayResponse({
    required String status,
    required String title,
    required String playerMode,
  }) = _PlayerPlayResponse;

  factory PlayerPlayResponse.fromJson(Map<String, dynamic> json) =>
      _$PlayerPlayResponseFromJson(json);
}

@freezed
abstract class NativePlayerCommandResponse with _$NativePlayerCommandResponse {
  const factory NativePlayerCommandResponse({
    required bool ok,
    required String state,
    required String message,
  }) = _NativePlayerCommandResponse;

  factory NativePlayerCommandResponse.fromJson(Map<String, dynamic> json) =>
      _$NativePlayerCommandResponseFromJson(json);
}

@freezed
abstract class NativePlayerStatusResponse with _$NativePlayerStatusResponse {
  const factory NativePlayerStatusResponse({
    required bool available,
    required String state,
    required bool playing,
    String? source,
    String? title,
    String? mediaKind,
    String? sessionId,
    required int positionMs,
    required int durationMs,
    required double volume,
    required int updatedAtMs,
  }) = _NativePlayerStatusResponse;

  factory NativePlayerStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$NativePlayerStatusResponseFromJson(json);
}

@freezed
abstract class PendingPlayback with _$PendingPlayback {
  const factory PendingPlayback({
    required String source,
    String? sessionId,
    String? title,
    String? mediaKind,
    String? tmdbId,
    String? imdbId,
    String? traktId,
    int? year,
    int? season,
    int? episode,
    double? resumePercent,
  }) = _PendingPlayback;

  factory PendingPlayback.fromJson(Map<String, dynamic> json) =>
      _$PendingPlaybackFromJson(json);
}

@freezed
abstract class PlayerScrobbleRequest with _$PlayerScrobbleRequest {
  const factory PlayerScrobbleRequest({
    String? sessionId,
    required String mediaType,
    required Map<String, dynamic> media,
    Map<String, dynamic>? show,
    required double progress,
  }) = _PlayerScrobbleRequest;

  factory PlayerScrobbleRequest.fromJson(Map<String, dynamic> json) =>
      _$PlayerScrobbleRequestFromJson(json);
}

@freezed
abstract class PlayerScrobbleResponse with _$PlayerScrobbleResponse {
  const factory PlayerScrobbleResponse({
    required bool ok,
    required bool conflict,
    String? sessionId,
    required String action,
    required String mediaType,
    required double progress,
    String? watchedAt,
    String? expiresAt,
    Map<String, dynamic>? response,
  }) = _PlayerScrobbleResponse;

  factory PlayerScrobbleResponse.fromJson(Map<String, dynamic> json) =>
      _$PlayerScrobbleResponseFromJson(json);
}
