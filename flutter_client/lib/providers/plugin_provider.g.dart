// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every category and what is installed in it.  Drives the Plugins panel and
/// the dynamic sidebar in one request.

@ProviderFor(pluginCategories)
final pluginCategoriesProvider = PluginCategoriesProvider._();

/// Every category and what is installed in it.  Drives the Plugins panel and
/// the dynamic sidebar in one request.

final class PluginCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PluginCategory>>,
          List<PluginCategory>,
          FutureOr<List<PluginCategory>>
        >
    with
        $FutureModifier<List<PluginCategory>>,
        $FutureProvider<List<PluginCategory>> {
  /// Every category and what is installed in it.  Drives the Plugins panel and
  /// the dynamic sidebar in one request.
  PluginCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pluginCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pluginCategoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<PluginCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PluginCategory>> create(Ref ref) {
    return pluginCategories(ref);
  }
}

String _$pluginCategoriesHash() => r'c33e41bd11a9b1c85f708139c7f81bd30711ac17';

/// Installed plugins that contribute a settings page, flattened across
/// categories in the order the backend lists them.

@ProviderFor(configurablePlugins)
final configurablePluginsProvider = ConfigurablePluginsProvider._();

/// Installed plugins that contribute a settings page, flattened across
/// categories in the order the backend lists them.

final class ConfigurablePluginsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PluginSummary>>,
          List<PluginSummary>,
          FutureOr<List<PluginSummary>>
        >
    with
        $FutureModifier<List<PluginSummary>>,
        $FutureProvider<List<PluginSummary>> {
  /// Installed plugins that contribute a settings page, flattened across
  /// categories in the order the backend lists them.
  ConfigurablePluginsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configurablePluginsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configurablePluginsHash();

  @$internal
  @override
  $FutureProviderElement<List<PluginSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PluginSummary>> create(Ref ref) {
    return configurablePlugins(ref);
  }
}

String _$configurablePluginsHash() =>
    r'95c86b39fab3f130e2ef569db75ade7dadb40499';

@ProviderFor(pluginSettingsSchema)
final pluginSettingsSchemaProvider = PluginSettingsSchemaFamily._();

final class PluginSettingsSchemaProvider
    extends
        $FunctionalProvider<
          AsyncValue<PluginSettingsSchema>,
          PluginSettingsSchema,
          FutureOr<PluginSettingsSchema>
        >
    with
        $FutureModifier<PluginSettingsSchema>,
        $FutureProvider<PluginSettingsSchema> {
  PluginSettingsSchemaProvider._({
    required PluginSettingsSchemaFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pluginSettingsSchemaProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pluginSettingsSchemaHash();

  @override
  String toString() {
    return r'pluginSettingsSchemaProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PluginSettingsSchema> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PluginSettingsSchema> create(Ref ref) {
    final argument = this.argument as String;
    return pluginSettingsSchema(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PluginSettingsSchemaProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pluginSettingsSchemaHash() =>
    r'daeba839fed0331377766b000a1c9d37bb12ebf1';

final class PluginSettingsSchemaFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PluginSettingsSchema>, String> {
  PluginSettingsSchemaFamily._()
    : super(
        retry: null,
        name: r'pluginSettingsSchemaProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PluginSettingsSchemaProvider call(String pluginId) =>
      PluginSettingsSchemaProvider._(argument: pluginId, from: this);

  @override
  String toString() => r'pluginSettingsSchemaProvider';
}

@ProviderFor(pluginAuthStatus)
final pluginAuthStatusProvider = PluginAuthStatusFamily._();

final class PluginAuthStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<PluginAuthState>,
          PluginAuthState,
          FutureOr<PluginAuthState>
        >
    with $FutureModifier<PluginAuthState>, $FutureProvider<PluginAuthState> {
  PluginAuthStatusProvider._({
    required PluginAuthStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pluginAuthStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pluginAuthStatusHash();

  @override
  String toString() {
    return r'pluginAuthStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PluginAuthState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PluginAuthState> create(Ref ref) {
    final argument = this.argument as String;
    return pluginAuthStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PluginAuthStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pluginAuthStatusHash() => r'57b363778ac191f6fef941a4122358498e9941cf';

final class PluginAuthStatusFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PluginAuthState>, String> {
  PluginAuthStatusFamily._()
    : super(
        retry: null,
        name: r'pluginAuthStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PluginAuthStatusProvider call(String pluginId) =>
      PluginAuthStatusProvider._(argument: pluginId, from: this);

  @override
  String toString() => r'pluginAuthStatusProvider';
}

@ProviderFor(pluginActions)
final pluginActionsProvider = PluginActionsProvider._();

final class PluginActionsProvider
    extends $FunctionalProvider<PluginActions, PluginActions, PluginActions>
    with $Provider<PluginActions> {
  PluginActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pluginActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pluginActionsHash();

  @$internal
  @override
  $ProviderElement<PluginActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PluginActions create(Ref ref) {
    return pluginActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PluginActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PluginActions>(value),
    );
  }
}

String _$pluginActionsHash() => r'9c8ec254fde68b637af37230f816cd5be8b2045a';
