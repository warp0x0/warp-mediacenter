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
    required ({String provider, String category, String mediaType})
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
        this.argument as ({String provider, String category, String mediaType});
    return catalogData(
      ref,
      provider: argument.provider,
      category: argument.category,
      mediaType: argument.mediaType,
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

String _$catalogDataHash() => r'7fc18f92ad0dfe7830de8e62d143055505c30b6a';

final class CatalogDataFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CatalogResponse>,
          ({String provider, String category, String mediaType})
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
  }) => CatalogDataProvider._(
    argument: (provider: provider, category: category, mediaType: mediaType),
    from: this,
  );

  @override
  String toString() => r'catalogDataProvider';
}

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
