import 'package:freezed_annotation/freezed_annotation.dart';

part 'media.freezed.dart';
part 'media.g.dart';

@freezed
abstract class ImageAsset with _$ImageAsset {
  const factory ImageAsset({
    required String url,
    int? width,
    int? height,
    double? aspectRatio,
    String? language,
  }) = _ImageAsset;

  factory ImageAsset.fromJson(Map<String, dynamic> json) =>
      _$ImageAssetFromJson(json);
}

@freezed
abstract class Genre with _$Genre {
  const factory Genre({
    int? id,
    required String name,
  }) = _Genre;

  factory Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);
}

@freezed
abstract class MediaNested with _$MediaNested {
  const factory MediaNested({
    required String id,
    required String title,
    required String name,
    int? year,
    String? overview,
    String? posterPath,
    String? backdropPath,
    double? rating,
    @Default([]) List<Genre> genres,
  }) = _MediaNested;

  factory MediaNested.fromJson(Map<String, dynamic> json) =>
      _$MediaNestedFromJson(json);
}

@freezed
abstract class MediaItem with _$MediaItem {
  const factory MediaItem({
    required String id,
    required String title,
    required String type,
    required String sourceTag,
    int? year,
    String? overview,
    ImageAsset? poster,
    String? license,
    double? rating,
    @Default([]) List<String> genres,
    String? originCountry,
    String? externalUrl,
    @Default({}) Map<String, dynamic> extra,
    String? posterPath,
    String? backdropPath,
    String? tmdbId,
    String? traktId,
    required MediaNested media,
  }) = _MediaItem;

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);
}

@freezed
abstract class CastMember with _$CastMember {
  const factory CastMember({
    Object? id,
    required String name,
    String? character,
    String? profilePath,
    ImageAsset? profileImage,
    int? order,
  }) = _CastMember;

  factory CastMember.fromJson(Map<String, dynamic> json) =>
      _$CastMemberFromJson(json);
}

@freezed
abstract class Trailer with _$Trailer {
  const factory Trailer({
    required String url,
    String? quality,
    String? mimeType,
    int? sizeBytes,
    String? license,
    @Default([]) List<dynamic> captions,
    bool? isDownload,
    String? sourceTag,
  }) = _Trailer;

  factory Trailer.fromJson(Map<String, dynamic> json) =>
      _$TrailerFromJson(json);
}
