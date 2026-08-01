import 'package:freezed_annotation/freezed_annotation.dart';

part 'plugin.freezed.dart';
part 'plugin.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Plugin models — mirror /api/v1/plugins/*
//
// Settings pages are described by the backend rather than hard-coded here: a
// plugin declares its own fields and supplies their current values, and this
// client renders whatever it is handed.  That is what lets a plugin installed
// after the app shipped still get a working settings page.
// ─────────────────────────────────────────────────────────────────────────────

@freezed
abstract class PluginAuthState with _$PluginAuthState {
  const factory PluginAuthState({
    @Default(false) bool required,
    @Default(false) bool connected,
    @Default(false) bool configured,
    String? status,
    String? username,
    String? detail,
    // Plan/tier label a plugin's auth status can report (e.g. Simkl's
    // free/pro/vip) — separate from `detail` so the UI can badge it
    // distinctly rather than parse it back out of a formatted string.
    String? plan,
    @Default(false) bool reauthRequired,
    String? reauthReason,
    double? expiresAt,
    PluginAuthFlow? flow,
  }) = _PluginAuthState;

  factory PluginAuthState.fromJson(Map<String, dynamic> json) =>
      _$PluginAuthStateFromJson(json);
}

/// State of an in-flight device-code authorisation.
@freezed
abstract class PluginAuthFlow with _$PluginAuthFlow {
  const factory PluginAuthFlow({
    @Default('none') String status,
    String? error,
    String? userCode,
    String? verificationUrl,
    double? expiresAt,
    @Default(5) int interval,
  }) = _PluginAuthFlow;

  factory PluginAuthFlow.fromJson(Map<String, dynamic> json) =>
      _$PluginAuthFlowFromJson(json);
}

@freezed
abstract class PluginSummary with _$PluginSummary {
  const factory PluginSummary({
    required String pluginId,
    required String category,
    required String name,
    required String version,
    @Default(false) bool enabled,
    @Default(false) bool exclusive,
    @Default(false) bool hasSettings,
    String? description,
    String? icon,
    String? author,
    String? homepage,
    String? authKind,
    @Default([]) List<String> capabilities,
    PluginAuthState? auth,
  }) = _PluginSummary;

  factory PluginSummary.fromJson(Map<String, dynamic> json) =>
      _$PluginSummaryFromJson(json);
}

@freezed
abstract class PluginCategory with _$PluginCategory {
  const factory PluginCategory({
    required String id,
    required String label,
    @Default('') String description,
    @Default(false) bool exclusive,
    @Default([]) List<PluginSummary> installed,
    String? activePluginId,
  }) = _PluginCategory;

  factory PluginCategory.fromJson(Map<String, dynamic> json) =>
      _$PluginCategoryFromJson(json);
}

@freezed
abstract class PluginCategoriesResponse with _$PluginCategoriesResponse {
  const factory PluginCategoriesResponse({
    @Default([]) List<PluginCategory> categories,
  }) = _PluginCategoriesResponse;

  factory PluginCategoriesResponse.fromJson(Map<String, dynamic> json) =>
      _$PluginCategoriesResponseFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings schema
// ─────────────────────────────────────────────────────────────────────────────

/// Field kinds a plugin settings page can contain.
///
/// [unknown] is the fallback for a type this client version does not recognise:
/// a newer plugin renders its unsupported fields as an inert note rather than
/// crashing the page or silently dropping them.
enum PluginFieldType {
  text,
  password,
  toggle,
  select,
  number,
  actionButton,
  authPanel,
  info,
  unknown;

  static PluginFieldType parse(String? raw) => switch (raw) {
    'text' => PluginFieldType.text,
    'password' => PluginFieldType.password,
    'toggle' => PluginFieldType.toggle,
    'select' => PluginFieldType.select,
    'number' => PluginFieldType.number,
    'action_button' => PluginFieldType.actionButton,
    'auth_panel' => PluginFieldType.authPanel,
    'info' => PluginFieldType.info,
    _ => PluginFieldType.unknown,
  };

  bool get isEditable => switch (this) {
    PluginFieldType.text ||
    PluginFieldType.password ||
    PluginFieldType.toggle ||
    PluginFieldType.select ||
    PluginFieldType.number => true,
    _ => false,
  };
}

class PluginSelectOption {
  final String value;
  final String label;

  const PluginSelectOption({required this.value, required this.label});

  factory PluginSelectOption.fromJson(Map<String, dynamic> json) {
    final value = '${json['value'] ?? ''}';
    return PluginSelectOption(
      value: value,
      label: '${json['label'] ?? value}',
    );
  }
}

/// One field on a plugin's settings page.
///
/// Hand-parsed rather than generated: the payload is deliberately loose so a
/// plugin can add keys this client has never heard of, and [raw] keeps them
/// around for field types that need extras.
class PluginField {
  final PluginFieldType type;
  final String id;
  final String label;
  final String? help;
  final bool required;
  final Object? value;
  final List<PluginSelectOption> options;
  final num? min;
  final num? max;
  final String? text;
  final String? style;
  final bool confirm;
  final String? authKind;
  final PluginAuthState? authState;
  final Map<String, dynamic> raw;

  const PluginField({
    required this.type,
    required this.id,
    required this.label,
    this.help,
    this.required = false,
    this.value,
    this.options = const [],
    this.min,
    this.max,
    this.text,
    this.style,
    this.confirm = false,
    this.authKind,
    this.authState,
    this.raw = const {},
  });

  factory PluginField.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final state = json['state'];
    return PluginField(
      type: PluginFieldType.parse(json['type'] as String?),
      id: '${json['id'] ?? ''}',
      label: '${json['label'] ?? json['id'] ?? ''}',
      help: json['help'] as String?,
      required: json['required'] == true,
      value: json['value'],
      options: rawOptions is List
          ? rawOptions
                .whereType<Map>()
                .map((o) => PluginSelectOption.fromJson(o.cast<String, dynamic>()))
                .toList()
          : const [],
      min: json['min'] as num?,
      max: json['max'] as num?,
      text: json['text'] as String?,
      style: json['style'] as String?,
      confirm: json['confirm'] == true,
      authKind: json['auth_kind'] as String?,
      authState: state is Map
          ? PluginAuthState.fromJson(state.cast<String, dynamic>())
          : null,
      raw: json.cast<String, dynamic>(),
    );
  }

  String get stringValue => value == null ? '' : '$value';
  bool get boolValue => value == true;
  double? get numberValue =>
      value is num ? (value as num).toDouble() : double.tryParse('$value');
}

class PluginSection {
  final String id;
  final String title;
  final String? description;
  final List<PluginField> fields;

  const PluginSection({
    required this.id,
    required this.title,
    this.description,
    this.fields = const [],
  });

  factory PluginSection.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    return PluginSection(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      description: json['description'] as String?,
      fields: rawFields is List
          ? rawFields
                .whereType<Map>()
                .map((f) => PluginField.fromJson(f.cast<String, dynamic>()))
                .toList()
          : const [],
    );
  }
}

class PluginSettingsSchema {
  final String pluginId;
  final String title;
  final String? icon;
  final String? description;
  final String category;
  final String version;
  final bool active;
  final PluginAuthState? auth;
  final List<PluginSection> sections;

  const PluginSettingsSchema({
    required this.pluginId,
    required this.title,
    this.icon,
    this.description,
    this.category = '',
    this.version = '',
    this.active = false,
    this.auth,
    this.sections = const [],
  });

  factory PluginSettingsSchema.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    final auth = json['auth'];
    return PluginSettingsSchema(
      pluginId: '${json['plugin_id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      category: '${json['category'] ?? ''}',
      version: '${json['version'] ?? ''}',
      active: json['active'] == true,
      auth: auth is Map
          ? PluginAuthState.fromJson(auth.cast<String, dynamic>())
          : null,
      sections: rawSections is List
          ? rawSections
                .whereType<Map>()
                .map((s) => PluginSection.fromJson(s.cast<String, dynamic>()))
                .toList()
          : const [],
    );
  }

  /// Editable fields in render order — the order focus traversal follows.
  Iterable<PluginField> get editableFields sync* {
    for (final section in sections) {
      for (final field in section.fields) {
        if (field.type.isEditable) yield field;
      }
    }
  }
}
