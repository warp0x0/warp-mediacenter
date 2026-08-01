// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PluginAuthState _$PluginAuthStateFromJson(Map<String, dynamic> json) =>
    _PluginAuthState(
      required: json['required'] as bool? ?? false,
      connected: json['connected'] as bool? ?? false,
      configured: json['configured'] as bool? ?? false,
      status: json['status'] as String?,
      username: json['username'] as String?,
      detail: json['detail'] as String?,
      plan: json['plan'] as String?,
      reauthRequired: json['reauth_required'] as bool? ?? false,
      reauthReason: json['reauth_reason'] as String?,
      expiresAt: (json['expires_at'] as num?)?.toDouble(),
      flow: json['flow'] == null
          ? null
          : PluginAuthFlow.fromJson(json['flow'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PluginAuthStateToJson(_PluginAuthState instance) =>
    <String, dynamic>{
      'required': instance.required,
      'connected': instance.connected,
      'configured': instance.configured,
      'status': instance.status,
      'username': instance.username,
      'detail': instance.detail,
      'plan': instance.plan,
      'reauth_required': instance.reauthRequired,
      'reauth_reason': instance.reauthReason,
      'expires_at': instance.expiresAt,
      'flow': instance.flow?.toJson(),
    };

_PluginAuthFlow _$PluginAuthFlowFromJson(Map<String, dynamic> json) =>
    _PluginAuthFlow(
      status: json['status'] as String? ?? 'none',
      error: json['error'] as String?,
      userCode: json['user_code'] as String?,
      verificationUrl: json['verification_url'] as String?,
      expiresAt: (json['expires_at'] as num?)?.toDouble(),
      interval: (json['interval'] as num?)?.toInt() ?? 5,
    );

Map<String, dynamic> _$PluginAuthFlowToJson(_PluginAuthFlow instance) =>
    <String, dynamic>{
      'status': instance.status,
      'error': instance.error,
      'user_code': instance.userCode,
      'verification_url': instance.verificationUrl,
      'expires_at': instance.expiresAt,
      'interval': instance.interval,
    };

_PluginSummary _$PluginSummaryFromJson(Map<String, dynamic> json) =>
    _PluginSummary(
      pluginId: json['plugin_id'] as String,
      category: json['category'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      enabled: json['enabled'] as bool? ?? false,
      exclusive: json['exclusive'] as bool? ?? false,
      hasSettings: json['has_settings'] as bool? ?? false,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      author: json['author'] as String?,
      homepage: json['homepage'] as String?,
      authKind: json['auth_kind'] as String?,
      capabilities:
          (json['capabilities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      auth: json['auth'] == null
          ? null
          : PluginAuthState.fromJson(json['auth'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PluginSummaryToJson(_PluginSummary instance) =>
    <String, dynamic>{
      'plugin_id': instance.pluginId,
      'category': instance.category,
      'name': instance.name,
      'version': instance.version,
      'enabled': instance.enabled,
      'exclusive': instance.exclusive,
      'has_settings': instance.hasSettings,
      'description': instance.description,
      'icon': instance.icon,
      'author': instance.author,
      'homepage': instance.homepage,
      'auth_kind': instance.authKind,
      'capabilities': instance.capabilities,
      'auth': instance.auth?.toJson(),
    };

_PluginCategory _$PluginCategoryFromJson(Map<String, dynamic> json) =>
    _PluginCategory(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
      exclusive: json['exclusive'] as bool? ?? false,
      installed:
          (json['installed'] as List<dynamic>?)
              ?.map((e) => PluginSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      activePluginId: json['active_plugin_id'] as String?,
    );

Map<String, dynamic> _$PluginCategoryToJson(_PluginCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'description': instance.description,
      'exclusive': instance.exclusive,
      'installed': instance.installed.map((e) => e.toJson()).toList(),
      'active_plugin_id': instance.activePluginId,
    };

_PluginCategoriesResponse _$PluginCategoriesResponseFromJson(
  Map<String, dynamic> json,
) => _PluginCategoriesResponse(
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => PluginCategory.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$PluginCategoriesResponseToJson(
  _PluginCategoriesResponse instance,
) => <String, dynamic>{
  'categories': instance.categories.map((e) => e.toJson()).toList(),
};
