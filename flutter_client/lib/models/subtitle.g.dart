// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subtitle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubtitleSearchResult _$SubtitleSearchResultFromJson(
  Map<String, dynamic> json,
) => _SubtitleSearchResult(
  provider: json['provider'] as String,
  language: json['language'] as String,
  score: (json['score'] as num).toDouble(),
  release: json['release'] as String,
  downloadLink: json['download_link'] as String,
  fileName: json['file_name'] as String,
  hearingImpaired: json['hearing_impaired'] as bool,
  rating: (json['rating'] as num?)?.toDouble(),
  uploadedAt: json['uploaded_at'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$SubtitleSearchResultToJson(
  _SubtitleSearchResult instance,
) => <String, dynamic>{
  'provider': instance.provider,
  'language': instance.language,
  'score': instance.score,
  'release': instance.release,
  'download_link': instance.downloadLink,
  'file_name': instance.fileName,
  'hearing_impaired': instance.hearingImpaired,
  'rating': instance.rating,
  'uploaded_at': instance.uploadedAt,
  'metadata': instance.metadata,
};

_SubtitleSearchResponse _$SubtitleSearchResponseFromJson(
  Map<String, dynamic> json,
) => _SubtitleSearchResponse(
  query: json['query'] as String,
  mediaKind: json['media_kind'] as String,
  language: json['language'] as String,
  results: (json['results'] as List<dynamic>)
      .map((e) => SubtitleSearchResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$SubtitleSearchResponseToJson(
  _SubtitleSearchResponse instance,
) => <String, dynamic>{
  'query': instance.query,
  'media_kind': instance.mediaKind,
  'language': instance.language,
  'results': instance.results.map((e) => e.toJson()).toList(),
  'count': instance.count,
};

_SubtitleDownloadResponse _$SubtitleDownloadResponseFromJson(
  Map<String, dynamic> json,
) => _SubtitleDownloadResponse(
  id: json['id'] as String,
  fileName: json['file_name'] as String,
  path: json['path'] as String,
  url: json['url'] as String,
);

Map<String, dynamic> _$SubtitleDownloadResponseToJson(
  _SubtitleDownloadResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'file_name': instance.fileName,
  'path': instance.path,
  'url': instance.url,
};

_SubtitleLoadResponse _$SubtitleLoadResponseFromJson(
  Map<String, dynamic> json,
) => _SubtitleLoadResponse(
  status: json['status'] as String,
  path: json['path'] as String,
  url: json['url'] as String?,
);

Map<String, dynamic> _$SubtitleLoadResponseToJson(
  _SubtitleLoadResponse instance,
) => <String, dynamic>{
  'status': instance.status,
  'path': instance.path,
  'url': instance.url,
};

_SubtitleTrack _$SubtitleTrackFromJson(Map<String, dynamic> json) =>
    _SubtitleTrack(
      id: json['id'] as String,
      language: json['language'] as String,
      name: json['name'] as String,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$SubtitleTrackToJson(_SubtitleTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'language': instance.language,
      'name': instance.name,
      'url': instance.url,
    };
