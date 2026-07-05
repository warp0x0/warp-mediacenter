// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthStatus _$AuthStatusFromJson(Map<String, dynamic> json) => _AuthStatus(
  authenticated: json['authenticated'] as bool,
  pending: json['pending'] as bool,
  expired: json['expired'] as bool,
  denied: json['denied'] as bool,
  error: json['error'] as String?,
  reason: json['reason'] as String?,
  expiresAt: json['expires_at']?.toString(),
  lastRefreshYmd: json['last_refresh_ymd'] as String?,
);

Map<String, dynamic> _$AuthStatusToJson(_AuthStatus instance) =>
    <String, dynamic>{
      'authenticated': instance.authenticated,
      'pending': instance.pending,
      'expired': instance.expired,
      'denied': instance.denied,
      'error': instance.error,
      'reason': instance.reason,
      'expires_at': instance.expiresAt,
      'last_refresh_ymd': instance.lastRefreshYmd,
    };

_TraktAuthStartResponse _$TraktAuthStartResponseFromJson(
  Map<String, dynamic> json,
) => _TraktAuthStartResponse(
  deviceCode: json['device_code'] as String,
  userCode: json['user_code'] as String,
  verificationUrl: json['verification_url'] as String,
  expiresIn: (json['expires_in'] as num).toInt(),
  interval: (json['interval'] as num).toInt(),
);

Map<String, dynamic> _$TraktAuthStartResponseToJson(
  _TraktAuthStartResponse instance,
) => <String, dynamic>{
  'device_code': instance.deviceCode,
  'user_code': instance.userCode,
  'verification_url': instance.verificationUrl,
  'expires_in': instance.expiresIn,
  'interval': instance.interval,
};

_TraktUserProfile _$TraktUserProfileFromJson(Map<String, dynamic> json) =>
    _TraktUserProfile(
      username: json['username'] as String,
      name: json['name'] as String,
      private: json['private'] as bool,
      vip: json['vip'] as bool,
      about: json['about'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$TraktUserProfileToJson(_TraktUserProfile instance) =>
    <String, dynamic>{
      'username': instance.username,
      'name': instance.name,
      'private': instance.private,
      'vip': instance.vip,
      'about': instance.about,
      'avatar_url': instance.avatarUrl,
    };

_ProviderStatus _$ProviderStatusFromJson(Map<String, dynamic> json) =>
    _ProviderStatus(
      status: json['status'] as String,
      authenticated: json['authenticated'] as bool?,
      apiKeyConfigured: json['api_key_configured'] as bool?,
      url: json['url'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$ProviderStatusToJson(_ProviderStatus instance) =>
    <String, dynamic>{
      'status': instance.status,
      'authenticated': instance.authenticated,
      'api_key_configured': instance.apiKeyConfigured,
      'url': instance.url,
      'error': instance.error,
    };

_ProvidersResponse _$ProvidersResponseFromJson(Map<String, dynamic> json) =>
    _ProvidersResponse(
      tmdb: ProviderStatus.fromJson(json['tmdb'] as Map<String, dynamic>),
      trakt: ProviderStatus.fromJson(json['trakt'] as Map<String, dynamic>),
      realdebrid: ProviderStatus.fromJson(
        json['realdebrid'] as Map<String, dynamic>,
      ),
      torrentApi: ProviderStatus.fromJson(
        json['torrent_api'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$ProvidersResponseToJson(_ProvidersResponse instance) =>
    <String, dynamic>{
      'tmdb': instance.tmdb.toJson(),
      'trakt': instance.trakt.toJson(),
      'realdebrid': instance.realdebrid.toJson(),
      'torrent_api': instance.torrentApi.toJson(),
    };

_SettingsResponse _$SettingsResponseFromJson(Map<String, dynamic> json) =>
    _SettingsResponse(
      settings: Map<String, String?>.from(json['settings'] as Map),
    );

Map<String, dynamic> _$SettingsResponseToJson(_SettingsResponse instance) =>
    <String, dynamic>{'settings': instance.settings};

_SettingsUpdateResponse _$SettingsUpdateResponseFromJson(
  Map<String, dynamic> json,
) => _SettingsUpdateResponse(
  message: json['message'] as String,
  key: json['key'] as String,
);

Map<String, dynamic> _$SettingsUpdateResponseToJson(
  _SettingsUpdateResponse instance,
) => <String, dynamic>{'message': instance.message, 'key': instance.key};
