import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth.freezed.dart';
part 'auth.g.dart';

@freezed
abstract class AuthStatus with _$AuthStatus {
  const factory AuthStatus({
    required bool authenticated,
    required bool pending,
    required bool expired,
    required bool denied,
    String? error,
    String? reason,
    String? expiresAt,
    String? lastRefreshYmd,
  }) = _AuthStatus;

  factory AuthStatus.fromJson(Map<String, dynamic> json) =>
      _$AuthStatusFromJson(json);
}

@freezed
abstract class TraktAuthStartResponse with _$TraktAuthStartResponse {
  const factory TraktAuthStartResponse({
    required String deviceCode,
    required String userCode,
    required String verificationUrl,
    required int expiresIn,
    required int interval,
  }) = _TraktAuthStartResponse;

  factory TraktAuthStartResponse.fromJson(Map<String, dynamic> json) =>
      _$TraktAuthStartResponseFromJson(json);
}

@freezed
abstract class TraktUserProfile with _$TraktUserProfile {
  const factory TraktUserProfile({
    required String username,
    required String name,
    required bool private,
    required bool vip,
    String? about,
    String? avatarUrl,
  }) = _TraktUserProfile;

  factory TraktUserProfile.fromJson(Map<String, dynamic> json) =>
      _$TraktUserProfileFromJson(json);
}

@freezed
abstract class ProviderStatus with _$ProviderStatus {
  const factory ProviderStatus({
    required String status,
    bool? authenticated,
    bool? apiKeyConfigured,
    String? url,
    String? error,
  }) = _ProviderStatus;

  factory ProviderStatus.fromJson(Map<String, dynamic> json) =>
      _$ProviderStatusFromJson(json);
}

@freezed
abstract class ProvidersResponse with _$ProvidersResponse {
  const factory ProvidersResponse({
    required ProviderStatus tmdb,
    required ProviderStatus trakt,
    required ProviderStatus realdebrid,
    required ProviderStatus torrentApi,
  }) = _ProvidersResponse;

  factory ProvidersResponse.fromJson(Map<String, dynamic> json) =>
      _$ProvidersResponseFromJson(json);
}

@freezed
abstract class SettingsResponse with _$SettingsResponse {
  const factory SettingsResponse({
    required Map<String, String?> settings,
  }) = _SettingsResponse;

  factory SettingsResponse.fromJson(Map<String, dynamic> json) =>
      _$SettingsResponseFromJson(json);
}

@freezed
abstract class SettingsUpdateResponse with _$SettingsUpdateResponse {
  const factory SettingsUpdateResponse({
    required String message,
    required String key,
  }) = _SettingsUpdateResponse;

  factory SettingsUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$SettingsUpdateResponseFromJson(json);
}
