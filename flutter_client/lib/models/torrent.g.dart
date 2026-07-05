// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'torrent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TorrentSearchRequest _$TorrentSearchRequestFromJson(
  Map<String, dynamic> json,
) => _TorrentSearchRequest(
  query: json['query'] as String,
  mediaType: json['media_type'] as String?,
  tmdbId: json['tmdb_id'] as String?,
  season: (json['season'] as num?)?.toInt(),
  episode: (json['episode'] as num?)?.toInt(),
  year: (json['year'] as num?)?.toInt(),
  limit: (json['limit'] as num?)?.toInt(),
);

Map<String, dynamic> _$TorrentSearchRequestToJson(
  _TorrentSearchRequest instance,
) => <String, dynamic>{
  'query': instance.query,
  'media_type': instance.mediaType,
  'tmdb_id': instance.tmdbId,
  'season': instance.season,
  'episode': instance.episode,
  'year': instance.year,
  'limit': instance.limit,
};

_TorrentResult _$TorrentResultFromJson(Map<String, dynamic> json) =>
    _TorrentResult(
      name: json['name'] as String,
      hash: json['hash'] as String,
      magnet: json['magnet'] as String,
      seeders: (json['seeders'] as num).toInt(),
      leechers: (json['leechers'] as num).toInt(),
      size: json['size'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
      sourceSite: json['source_site'] as String,
      quality: json['quality'] as String,
      isCached: json['is_cached'] as bool,
      matchScore: (json['match_score'] as num).toDouble(),
      uploader: json['uploader'] as String,
      date: json['date'] as String,
    );

Map<String, dynamic> _$TorrentResultToJson(_TorrentResult instance) =>
    <String, dynamic>{
      'name': instance.name,
      'hash': instance.hash,
      'magnet': instance.magnet,
      'seeders': instance.seeders,
      'leechers': instance.leechers,
      'size': instance.size,
      'size_bytes': instance.sizeBytes,
      'source_site': instance.sourceSite,
      'quality': instance.quality,
      'is_cached': instance.isCached,
      'match_score': instance.matchScore,
      'uploader': instance.uploader,
      'date': instance.date,
    };

_TorrentSearchResponse _$TorrentSearchResponseFromJson(
  Map<String, dynamic> json,
) => _TorrentSearchResponse(
  filtered: (json['filtered'] as List<dynamic>)
      .map((e) => TorrentResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  unfiltered: (json['unfiltered'] as List<dynamic>)
      .map((e) => TorrentResult.fromJson(e as Map<String, dynamic>))
      .toList(),
  query: json['query'] as String,
  mediaType: json['media_type'] as String,
);

Map<String, dynamic> _$TorrentSearchResponseToJson(
  _TorrentSearchResponse instance,
) => <String, dynamic>{
  'filtered': instance.filtered.map((e) => e.toJson()).toList(),
  'unfiltered': instance.unfiltered.map((e) => e.toJson()).toList(),
  'query': instance.query,
  'media_type': instance.mediaType,
};

_TorrentStatus _$TorrentStatusFromJson(Map<String, dynamic> json) =>
    _TorrentStatus(
      torrentId: json['torrent_id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      progress: (json['progress'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      seeders: (json['seeders'] as num).toInt(),
      linksCount: (json['links_count'] as num).toInt(),
      title: json['title'] as String,
      mediaType: json['media_type'] as String,
      season: (json['season'] as num?)?.toInt(),
      episode: (json['episode'] as num?)?.toInt(),
      elapsedSeconds: (json['elapsed_seconds'] as num).toDouble(),
      message: json['message'] as String,
    );

Map<String, dynamic> _$TorrentStatusToJson(_TorrentStatus instance) =>
    <String, dynamic>{
      'torrent_id': instance.torrentId,
      'name': instance.name,
      'status': instance.status,
      'progress': instance.progress,
      'speed': instance.speed,
      'seeders': instance.seeders,
      'links_count': instance.linksCount,
      'title': instance.title,
      'media_type': instance.mediaType,
      'season': instance.season,
      'episode': instance.episode,
      'elapsed_seconds': instance.elapsedSeconds,
      'message': instance.message,
    };

_TorrentResolveResponse _$TorrentResolveResponseFromJson(
  Map<String, dynamic> json,
) => _TorrentResolveResponse(
  torrentId: json['torrent_id'] as String,
  status: json['status'] as String,
  selectedFile: json['selected_file'] as String?,
  message: json['message'] as String,
);

Map<String, dynamic> _$TorrentResolveResponseToJson(
  _TorrentResolveResponse instance,
) => <String, dynamic>{
  'torrent_id': instance.torrentId,
  'status': instance.status,
  'selected_file': instance.selectedFile,
  'message': instance.message,
};
