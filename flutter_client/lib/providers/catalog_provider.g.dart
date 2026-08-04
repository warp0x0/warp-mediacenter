// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(catalogData)
final catalogDataProvider = CatalogDataFamily._();

final class CatalogDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<CatalogResponse>,
          CatalogResponse,
          FutureOr<CatalogResponse>
        >
    with $FutureModifier<CatalogResponse>, $FutureProvider<CatalogResponse> {
  CatalogDataProvider._({
    required CatalogDataFamily super.from,
    required ({
      String provider,
      String category,
      String mediaType,
      String? source,
      Map<String, dynamic>? params,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'catalogDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$catalogDataHash();

  @override
  String toString() {
    return r'catalogDataProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<CatalogResponse> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CatalogResponse> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String provider,
              String category,
              String mediaType,
              String? source,
              Map<String, dynamic>? params,
            });
    return catalogData(
      ref,
      provider: argument.provider,
      category: argument.category,
      mediaType: argument.mediaType,
      source: argument.source,
      params: argument.params,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CatalogDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$catalogDataHash() => r'755e7afe75859d77215fe6bca87d9d56c13524df';

final class CatalogDataFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CatalogResponse>,
          ({
            String provider,
            String category,
            String mediaType,
            String? source,
            Map<String, dynamic>? params,
          })
        > {
  CatalogDataFamily._()
    : super(
        retry: null,
        name: r'catalogDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CatalogDataProvider call({
    required String provider,
    required String category,
    required String mediaType,
    String? source,
    Map<String, dynamic>? params,
  }) => CatalogDataProvider._(
    argument: (
      provider: provider,
      category: category,
      mediaType: mediaType,
      source: source,
      params: params,
    ),
    from: this,
  );

  @override
  String toString() => r'catalogDataProvider';
}

/// Every catalog source and the lists it publishes.
///
/// This is what makes the Settings picker plugin-aware: installing a catalog
/// plugin changes this response, and the picker rebuilds from it with no
/// client-side change. Invalidated whenever the plugin set moves — see
/// `pluginActionsProvider`.

@ProviderFor(catalogDefinitions)
final catalogDefinitionsProvider = CatalogDefinitionsProvider._();

/// Every catalog source and the lists it publishes.
///
/// This is what makes the Settings picker plugin-aware: installing a catalog
/// plugin changes this response, and the picker rebuilds from it with no
/// client-side change. Invalidated whenever the plugin set moves — see
/// `pluginActionsProvider`.

final class CatalogDefinitionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<CatalogDefinitions>,
          CatalogDefinitions,
          FutureOr<CatalogDefinitions>
        >
    with
        $FutureModifier<CatalogDefinitions>,
        $FutureProvider<CatalogDefinitions> {
  /// Every catalog source and the lists it publishes.
  ///
  /// This is what makes the Settings picker plugin-aware: installing a catalog
  /// plugin changes this response, and the picker rebuilds from it with no
  /// client-side change. Invalidated whenever the plugin set moves — see
  /// `pluginActionsProvider`.
  CatalogDefinitionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogDefinitionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogDefinitionsHash();

  @$internal
  @override
  $FutureProviderElement<CatalogDefinitions> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CatalogDefinitions> create(Ref ref) {
    return catalogDefinitions(ref);
  }
}

String _$catalogDefinitionsHash() =>
    r'd4f98505a5280b43e73d2dc619e36907ed18bd8d';

@ProviderFor(widgetsConfig)
final widgetsConfigProvider = WidgetsConfigProvider._();

final class WidgetsConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<WidgetsConfigResponse>,
          WidgetsConfigResponse,
          FutureOr<WidgetsConfigResponse>
        >
    with
        $FutureModifier<WidgetsConfigResponse>,
        $FutureProvider<WidgetsConfigResponse> {
  WidgetsConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetsConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetsConfigHash();

  @$internal
  @override
  $FutureProviderElement<WidgetsConfigResponse> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WidgetsConfigResponse> create(Ref ref) {
    return widgetsConfig(ref);
  }
}

String _$widgetsConfigHash() => r'38b1fe4f069c69b7a325436250292b48d44ff814';
