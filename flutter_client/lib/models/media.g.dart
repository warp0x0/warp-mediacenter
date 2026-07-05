// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ImageAsset _$ImageAssetFromJson(Map<String, dynamic> json) => _ImageAsset(
  url: json['url'] as String,
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
  aspectRatio: (json['aspect_ratio'] as num?)?.toDouble(),
  language: json['language'] as String?,
);

Map<String, dynamic> _$ImageAssetToJson(_ImageAsset instance) =>
    <String, dynamic>{
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
      'aspect_ratio': instance.aspectRatio,
      'language': instance.language,
    };

_Genre _$GenreFromJson(Map<String, dynamic> json) =>
    _Genre(id: (json['id'] as num?)?.toInt(), name: json['name'] as String);

Map<String, dynamic> _$GenreToJson(_Genre instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

_MediaNested _$MediaNestedFromJson(Map<String, dynamic> json) => _MediaNested(
  id: json['id'] as String,
  title: json['title'] as String,
  name: json['name'] as String,
  year: (json['year'] as num?)?.toInt(),
  overview: json['overview'] as String?,
  posterPath: json['poster_path'] as String?,
  backdropPath: json['backdrop_path'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  genres:
      (json['genres'] as List<dynamic>?)
          ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$MediaNestedToJson(_MediaNested instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'name': instance.name,
      'year': instance.year,
      'overview': instance.overview,
      'poster_path': instance.posterPath,
      'backdrop_path': instance.backdropPath,
      'rating': instance.rating,
      'genres': instance.genres.map((e) => e.toJson()).toList(),
    };

_MediaItem _$MediaItemFromJson(Map<String, dynamic> json) => _MediaItem(
  id: json['id'] as String,
  title: json['title'] as String,
  type: json['type'] as String,
  sourceTag: json['source_tag'] as String,
  year: (json['year'] as num?)?.toInt(),
  overview: json['overview'] as String?,
  poster: json['poster'] == null
      ? null
      : ImageAsset.fromJson(json['poster'] as Map<String, dynamic>),
  license: json['license'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  genres:
      (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  originCountry: json['origin_country'] as String?,
  externalUrl: json['external_url'] as String?,
  extra: json['extra'] as Map<String, dynamic>? ?? const {},
  posterPath: json['poster_path'] as String?,
  backdropPath: json['backdrop_path'] as String?,
  tmdbId: json['tmdb_id'] as String?,
  traktId: json['trakt_id'] as String?,
  media: MediaNested.fromJson(json['media'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MediaItemToJson(_MediaItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': instance.type,
      'source_tag': instance.sourceTag,
      'year': instance.year,
      'overview': instance.overview,
      'poster': instance.poster?.toJson(),
      'license': instance.license,
      'rating': instance.rating,
      'genres': instance.genres,
      'origin_country': instance.originCountry,
      'external_url': instance.externalUrl,
      'extra': instance.extra,
      'poster_path': instance.posterPath,
      'backdrop_path': instance.backdropPath,
      'tmdb_id': instance.tmdbId,
      'trakt_id': instance.traktId,
      'media': instance.media.toJson(),
    };

_CastMember _$CastMemberFromJson(Map<String, dynamic> json) => _CastMember(
  id: json['id'],
  name: json['name'] as String,
  character: json['character'] as String?,
  profilePath: json['profile_path'] as String?,
  profileImage: json['profile_image'] == null
      ? null
      : ImageAsset.fromJson(json['profile_image'] as Map<String, dynamic>),
  order: (json['order'] as num?)?.toInt(),
);

Map<String, dynamic> _$CastMemberToJson(_CastMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'character': instance.character,
      'profile_path': instance.profilePath,
      'profile_image': instance.profileImage?.toJson(),
      'order': instance.order,
    };

_Trailer _$TrailerFromJson(Map<String, dynamic> json) => _Trailer(
  url: json['url'] as String,
  quality: json['quality'] as String?,
  mimeType: json['mime_type'] as String?,
  sizeBytes: (json['size_bytes'] as num?)?.toInt(),
  license: json['license'] as String?,
  captions: json['captions'] as List<dynamic>? ?? const [],
  isDownload: json['is_download'] as bool?,
  sourceTag: json['source_tag'] as String?,
);

Map<String, dynamic> _$TrailerToJson(_Trailer instance) => <String, dynamic>{
  'url': instance.url,
  'quality': instance.quality,
  'mime_type': instance.mimeType,
  'size_bytes': instance.sizeBytes,
  'license': instance.license,
  'captions': instance.captions,
  'is_download': instance.isDownload,
  'source_tag': instance.sourceTag,
};
