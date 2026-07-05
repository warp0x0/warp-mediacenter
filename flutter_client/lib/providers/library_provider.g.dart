// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(libraryMovies)
final libraryMoviesProvider = LibraryMoviesProvider._();

final class LibraryMoviesProvider
    extends
        $FunctionalProvider<
          AsyncValue<LibraryListResponse>,
          LibraryListResponse,
          FutureOr<LibraryListResponse>
        >
    with
        $FutureModifier<LibraryListResponse>,
        $FutureProvider<LibraryListResponse> {
  LibraryMoviesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryMoviesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryMoviesHash();

  @$internal
  @override
  $FutureProviderElement<LibraryListResponse> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LibraryListResponse> create(Ref ref) {
    return libraryMovies(ref);
  }
}

String _$libraryMoviesHash() => r'658d3f21d696ecf2d30b780ef3d5ea94941d267b';

@ProviderFor(libraryShows)
final libraryShowsProvider = LibraryShowsProvider._();

final class LibraryShowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<LibraryListResponse>,
          LibraryListResponse,
          FutureOr<LibraryListResponse>
        >
    with
        $FutureModifier<LibraryListResponse>,
        $FutureProvider<LibraryListResponse> {
  LibraryShowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryShowsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryShowsHash();

  @$internal
  @override
  $FutureProviderElement<LibraryListResponse> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LibraryListResponse> create(Ref ref) {
    return libraryShows(ref);
  }
}

String _$libraryShowsHash() => r'dc18721f066355b292146b53c588cc03dbabd967';

@ProviderFor(libraryMoviesAz)
final libraryMoviesAzProvider = LibraryMoviesAzProvider._();

final class LibraryMoviesAzProvider
    extends
        $FunctionalProvider<
          AsyncValue<LibraryListResponse>,
          LibraryListResponse,
          FutureOr<LibraryListResponse>
        >
    with
        $FutureModifier<LibraryListResponse>,
        $FutureProvider<LibraryListResponse> {
  LibraryMoviesAzProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryMoviesAzProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryMoviesAzHash();

  @$internal
  @override
  $FutureProviderElement<LibraryListResponse> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LibraryListResponse> create(Ref ref) {
    return libraryMoviesAz(ref);
  }
}

String _$libraryMoviesAzHash() => r'cc3f6157709bf4df4e6a828955d1fbeae7037c97';

@ProviderFor(libraryShowsAz)
final libraryShowsAzProvider = LibraryShowsAzProvider._();

final class LibraryShowsAzProvider
    extends
        $FunctionalProvider<
          AsyncValue<LibraryListResponse>,
          LibraryListResponse,
          FutureOr<LibraryListResponse>
        >
    with
        $FutureModifier<LibraryListResponse>,
        $FutureProvider<LibraryListResponse> {
  LibraryShowsAzProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryShowsAzProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryShowsAzHash();

  @$internal
  @override
  $FutureProviderElement<LibraryListResponse> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LibraryListResponse> create(Ref ref) {
    return libraryShowsAz(ref);
  }
}

String _$libraryShowsAzHash() => r'4f801e457794a2e0d96a0f3578b141505675f234';

@ProviderFor(librarySearch)
final librarySearchProvider = LibrarySearchFamily._();

final class LibrarySearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<LibrarySearchResponse>,
          LibrarySearchResponse,
          FutureOr<LibrarySearchResponse>
        >
    with
        $FutureModifier<LibrarySearchResponse>,
        $FutureProvider<LibrarySearchResponse> {
  LibrarySearchProvider._({
    required LibrarySearchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'librarySearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$librarySearchHash();

  @override
  String toString() {
    return r'librarySearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LibrarySearchResponse> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LibrarySearchResponse> create(Ref ref) {
    final argument = this.argument as String;
    return librarySearch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LibrarySearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$librarySearchHash() => r'3e7d823ab4574a7c9bff4b9ed4e59951bc28868b';

final class LibrarySearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LibrarySearchResponse>, String> {
  LibrarySearchFamily._()
    : super(
        retry: null,
        name: r'librarySearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LibrarySearchProvider call(String query) =>
      LibrarySearchProvider._(argument: query, from: this);

  @override
  String toString() => r'librarySearchProvider';
}

@ProviderFor(collection)
final collectionProvider = CollectionFamily._();

final class CollectionProvider
    extends
        $FunctionalProvider<
          AsyncValue<CollectionResponse>,
          CollectionResponse,
          FutureOr<CollectionResponse>
        >
    with
        $FutureModifier<CollectionResponse>,
        $FutureProvider<CollectionResponse> {
  CollectionProvider._({
    required CollectionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'collectionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$collectionHash();

  @override
  String toString() {
    return r'collectionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CollectionResponse> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CollectionResponse> create(Ref ref) {
    final argument = this.argument as String;
    return collection(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CollectionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$collectionHash() => r'f05582643973f37a63005c93b4b4b92413036d39';

final class CollectionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CollectionResponse>, String> {
  CollectionFamily._()
    : super(
        retry: null,
        name: r'collectionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CollectionProvider call(String collectionType) =>
      CollectionProvider._(argument: collectionType, from: this);

  @override
  String toString() => r'collectionProvider';
}

@ProviderFor(isLiked)
final isLikedProvider = IsLikedFamily._();

final class IsLikedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  IsLikedProvider._({
    required IsLikedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isLikedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isLikedHash();

  @override
  String toString() {
    return r'isLikedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return isLiked(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsLikedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isLikedHash() => r'55019438852a5b311bfc06e2d30ed48f9efe90ed';

final class IsLikedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  IsLikedFamily._()
    : super(
        retry: null,
        name: r'isLikedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsLikedProvider call(String tmdbId) =>
      IsLikedProvider._(argument: tmdbId, from: this);

  @override
  String toString() => r'isLikedProvider';
}

@ProviderFor(isWishlisted)
final isWishlistedProvider = IsWishlistedFamily._();

final class IsWishlistedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  IsWishlistedProvider._({
    required IsWishlistedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isWishlistedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isWishlistedHash();

  @override
  String toString() {
    return r'isWishlistedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return isWishlisted(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsWishlistedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isWishlistedHash() => r'884b56324cc90b703c91bc7b22558b8de587741b';

final class IsWishlistedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  IsWishlistedFamily._()
    : super(
        retry: null,
        name: r'isWishlistedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsWishlistedProvider call(String tmdbId) =>
      IsWishlistedProvider._(argument: tmdbId, from: this);

  @override
  String toString() => r'isWishlistedProvider';
}

@ProviderFor(scanStatus)
final scanStatusProvider = ScanStatusProvider._();

final class ScanStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<ScanStatusResponse>,
          ScanStatusResponse,
          FutureOr<ScanStatusResponse>
        >
    with
        $FutureModifier<ScanStatusResponse>,
        $FutureProvider<ScanStatusResponse> {
  ScanStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanStatusHash();

  @$internal
  @override
  $FutureProviderElement<ScanStatusResponse> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ScanStatusResponse> create(Ref ref) {
    return scanStatus(ref);
  }
}

String _$scanStatusHash() => r'7bd3385a001fead267deb0dc8a815b05b16b8fc6';
