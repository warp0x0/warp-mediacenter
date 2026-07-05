// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(providersStatus)
final providersStatusProvider = ProvidersStatusProvider._();

final class ProvidersStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProvidersResponse>,
          ProvidersResponse,
          FutureOr<ProvidersResponse>
        >
    with
        $FutureModifier<ProvidersResponse>,
        $FutureProvider<ProvidersResponse> {
  ProvidersStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'providersStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$providersStatusHash();

  @$internal
  @override
  $FutureProviderElement<ProvidersResponse> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ProvidersResponse> create(Ref ref) {
    return providersStatus(ref);
  }
}

String _$providersStatusHash() => r'f70af0264036e9539ff8c0d9b4688c2d1298bf57';

@ProviderFor(traktAuthStatus)
final traktAuthStatusProvider = TraktAuthStatusProvider._();

final class TraktAuthStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthStatus>,
          AuthStatus,
          FutureOr<AuthStatus>
        >
    with $FutureModifier<AuthStatus>, $FutureProvider<AuthStatus> {
  TraktAuthStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'traktAuthStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$traktAuthStatusHash();

  @$internal
  @override
  $FutureProviderElement<AuthStatus> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AuthStatus> create(Ref ref) {
    return traktAuthStatus(ref);
  }
}

String _$traktAuthStatusHash() => r'47557e008f1c249f3596728fedd201a65f906393';

@ProviderFor(debridAuthStatus)
final debridAuthStatusProvider = DebridAuthStatusProvider._();

final class DebridAuthStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthStatus>,
          AuthStatus,
          FutureOr<AuthStatus>
        >
    with $FutureModifier<AuthStatus>, $FutureProvider<AuthStatus> {
  DebridAuthStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'debridAuthStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$debridAuthStatusHash();

  @$internal
  @override
  $FutureProviderElement<AuthStatus> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AuthStatus> create(Ref ref) {
    return debridAuthStatus(ref);
  }
}

String _$debridAuthStatusHash() => r'bbdde8fa860ada85bcadec78756b6993b2af90d9';

@ProviderFor(traktAccount)
final traktAccountProvider = TraktAccountProvider._();

final class TraktAccountProvider
    extends
        $FunctionalProvider<
          AsyncValue<TraktUserProfile?>,
          TraktUserProfile?,
          FutureOr<TraktUserProfile?>
        >
    with
        $FutureModifier<TraktUserProfile?>,
        $FutureProvider<TraktUserProfile?> {
  TraktAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'traktAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$traktAccountHash();

  @$internal
  @override
  $FutureProviderElement<TraktUserProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TraktUserProfile?> create(Ref ref) {
    return traktAccount(ref);
  }
}

String _$traktAccountHash() => r'5588a048ae149cc0110b47124ad68c0c9668e952';

@ProviderFor(debridAccount)
final debridAccountProvider = DebridAccountProvider._();

final class DebridAccountProvider
    extends
        $FunctionalProvider<
          AsyncValue<DebridAccountInfo?>,
          DebridAccountInfo?,
          FutureOr<DebridAccountInfo?>
        >
    with
        $FutureModifier<DebridAccountInfo?>,
        $FutureProvider<DebridAccountInfo?> {
  DebridAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'debridAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$debridAccountHash();

  @$internal
  @override
  $FutureProviderElement<DebridAccountInfo?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DebridAccountInfo?> create(Ref ref) {
    return debridAccount(ref);
  }
}

String _$debridAccountHash() => r'cbeb8164e3feb0748860251ded61346fb5e492b6';
