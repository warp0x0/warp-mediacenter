// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(titleDetail)
final titleDetailProvider = TitleDetailFamily._();

final class TitleDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<LibraryTitleDetail?>,
          LibraryTitleDetail?,
          FutureOr<LibraryTitleDetail?>
        >
    with
        $FutureModifier<LibraryTitleDetail?>,
        $FutureProvider<LibraryTitleDetail?> {
  TitleDetailProvider._({
    required TitleDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'titleDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$titleDetailHash();

  @override
  String toString() {
    return r'titleDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LibraryTitleDetail?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LibraryTitleDetail?> create(Ref ref) {
    final argument = this.argument as String;
    return titleDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TitleDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$titleDetailHash() => r'7b57047911dfa097c3cf42b4d132c1cab54b8b1c';

final class TitleDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LibraryTitleDetail?>, String> {
  TitleDetailFamily._()
    : super(
        retry: null,
        name: r'titleDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TitleDetailProvider call(String tmdbId) =>
      TitleDetailProvider._(argument: tmdbId, from: this);

  @override
  String toString() => r'titleDetailProvider';
}

@ProviderFor(titleSources)
final titleSourcesProvider = TitleSourcesFamily._();

final class TitleSourcesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SourceRow>>,
          List<SourceRow>,
          FutureOr<List<SourceRow>>
        >
    with $FutureModifier<List<SourceRow>>, $FutureProvider<List<SourceRow>> {
  TitleSourcesProvider._({
    required TitleSourcesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'titleSourcesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$titleSourcesHash();

  @override
  String toString() {
    return r'titleSourcesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SourceRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SourceRow>> create(Ref ref) {
    final argument = this.argument as String;
    return titleSources(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TitleSourcesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$titleSourcesHash() => r'd09efe2327523892872ae35b4fe8bcc8773f121f';

final class TitleSourcesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SourceRow>>, String> {
  TitleSourcesFamily._()
    : super(
        retry: null,
        name: r'titleSourcesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TitleSourcesProvider call(String tmdbId) =>
      TitleSourcesProvider._(argument: tmdbId, from: this);

  @override
  String toString() => r'titleSourcesProvider';
}

@ProviderFor(movieRichDetail)
final movieRichDetailProvider = MovieRichDetailFamily._();

final class MovieRichDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<MovieDetail?>,
          MovieDetail?,
          FutureOr<MovieDetail?>
        >
    with $FutureModifier<MovieDetail?>, $FutureProvider<MovieDetail?> {
  MovieRichDetailProvider._({
    required MovieRichDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'movieRichDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$movieRichDetailHash();

  @override
  String toString() {
    return r'movieRichDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MovieDetail?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MovieDetail?> create(Ref ref) {
    final argument = this.argument as String;
    return movieRichDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MovieRichDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$movieRichDetailHash() => r'add6a8bb6b06703986f741247ac8102e28ed2bdf';

final class MovieRichDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MovieDetail?>, String> {
  MovieRichDetailFamily._()
    : super(
        retry: null,
        name: r'movieRichDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MovieRichDetailProvider call(String tmdbId) =>
      MovieRichDetailProvider._(argument: tmdbId, from: this);

  @override
  String toString() => r'movieRichDetailProvider';
}

@ProviderFor(showRichDetail)
final showRichDetailProvider = ShowRichDetailFamily._();

final class ShowRichDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<ShowDetail?>,
          ShowDetail?,
          FutureOr<ShowDetail?>
        >
    with $FutureModifier<ShowDetail?>, $FutureProvider<ShowDetail?> {
  ShowRichDetailProvider._({
    required ShowRichDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'showRichDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$showRichDetailHash();

  @override
  String toString() {
    return r'showRichDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ShowDetail?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ShowDetail?> create(Ref ref) {
    final argument = this.argument as String;
    return showRichDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShowRichDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$showRichDetailHash() => r'3abb6f55e5e3dbdaaf557f6e7f8b6cf7c1828dbb';

final class ShowRichDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ShowDetail?>, String> {
  ShowRichDetailFamily._()
    : super(
        retry: null,
        name: r'showRichDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShowRichDetailProvider call(String tmdbId) =>
      ShowRichDetailProvider._(argument: tmdbId, from: this);

  @override
  String toString() => r'showRichDetailProvider';
}

@ProviderFor(showSeasonsList)
final showSeasonsListProvider = ShowSeasonsListFamily._();

final class ShowSeasonsListProvider
    extends
        $FunctionalProvider<
          AsyncValue<ShowSeasonsResponse?>,
          ShowSeasonsResponse?,
          FutureOr<ShowSeasonsResponse?>
        >
    with
        $FutureModifier<ShowSeasonsResponse?>,
        $FutureProvider<ShowSeasonsResponse?> {
  ShowSeasonsListProvider._({
    required ShowSeasonsListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'showSeasonsListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$showSeasonsListHash();

  @override
  String toString() {
    return r'showSeasonsListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ShowSeasonsResponse?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ShowSeasonsResponse?> create(Ref ref) {
    final argument = this.argument as String;
    return showSeasonsList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShowSeasonsListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$showSeasonsListHash() => r'cf167e682cf342edfe4862d08b961bdce6e5ea58';

final class ShowSeasonsListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ShowSeasonsResponse?>, String> {
  ShowSeasonsListFamily._()
    : super(
        retry: null,
        name: r'showSeasonsListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShowSeasonsListProvider call(String tmdbId) =>
      ShowSeasonsListProvider._(argument: tmdbId, from: this);

  @override
  String toString() => r'showSeasonsListProvider';
}

@ProviderFor(showProgress)
final showProgressProvider = ShowProgressFamily._();

final class ShowProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<ShowProgressResponse?>,
          ShowProgressResponse?,
          FutureOr<ShowProgressResponse?>
        >
    with
        $FutureModifier<ShowProgressResponse?>,
        $FutureProvider<ShowProgressResponse?> {
  ShowProgressProvider._({
    required ShowProgressFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'showProgressProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$showProgressHash();

  @override
  String toString() {
    return r'showProgressProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ShowProgressResponse?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ShowProgressResponse?> create(Ref ref) {
    final argument = this.argument as String;
    return showProgress(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShowProgressProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$showProgressHash() => r'27ba3dc31dbdb9a71cc49dba56157dc5c5189704';

final class ShowProgressFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ShowProgressResponse?>, String> {
  ShowProgressFamily._()
    : super(
        retry: null,
        name: r'showProgressProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ShowProgressProvider call(String tmdbId) =>
      ShowProgressProvider._(argument: tmdbId, from: this);

  @override
  String toString() => r'showProgressProvider';
}

@ProviderFor(watchProviders)
final watchProvidersProvider = WatchProvidersFamily._();

final class WatchProvidersProvider
    extends
        $FunctionalProvider<
          AsyncValue<WatchProvidersResponse?>,
          WatchProvidersResponse?,
          FutureOr<WatchProvidersResponse?>
        >
    with
        $FutureModifier<WatchProvidersResponse?>,
        $FutureProvider<WatchProvidersResponse?> {
  WatchProvidersProvider._({
    required WatchProvidersFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'watchProvidersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchProvidersHash();

  @override
  String toString() {
    return r'watchProvidersProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WatchProvidersResponse?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WatchProvidersResponse?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return watchProviders(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchProvidersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchProvidersHash() => r'80c55571bab8070185045c16f0487e3c7ab3dee2';

final class WatchProvidersFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<WatchProvidersResponse?>,
          (String, String)
        > {
  WatchProvidersFamily._()
    : super(
        retry: null,
        name: r'watchProvidersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WatchProvidersProvider call(String tmdbId, String mediaType) =>
      WatchProvidersProvider._(argument: (tmdbId, mediaType), from: this);

  @override
  String toString() => r'watchProvidersProvider';
}

@ProviderFor(imdbRating)
final imdbRatingProvider = ImdbRatingFamily._();

final class ImdbRatingProvider
    extends
        $FunctionalProvider<
          AsyncValue<ImdbRatingResponse?>,
          ImdbRatingResponse?,
          FutureOr<ImdbRatingResponse?>
        >
    with
        $FutureModifier<ImdbRatingResponse?>,
        $FutureProvider<ImdbRatingResponse?> {
  ImdbRatingProvider._({
    required ImdbRatingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'imdbRatingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$imdbRatingHash();

  @override
  String toString() {
    return r'imdbRatingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ImdbRatingResponse?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ImdbRatingResponse?> create(Ref ref) {
    final argument = this.argument as String;
    return imdbRating(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ImdbRatingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$imdbRatingHash() => r'0c0a625a9af5ce2b1d6f4aac13a04a0a4aa845b2';

final class ImdbRatingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ImdbRatingResponse?>, String> {
  ImdbRatingFamily._()
    : super(
        retry: null,
        name: r'imdbRatingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ImdbRatingProvider call(String imdbId) =>
      ImdbRatingProvider._(argument: imdbId, from: this);

  @override
  String toString() => r'imdbRatingProvider';
}
