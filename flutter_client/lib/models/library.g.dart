// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LibrarySection _$LibrarySectionFromJson(Map<String, dynamic> json) =>
    _LibrarySection(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      kind: json['kind'] as String,
      paths: (json['paths'] as List<dynamic>).map((e) => e as String).toList(),
      enabled: (json['enabled'] as num).toInt(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$LibrarySectionToJson(_LibrarySection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'kind': instance.kind,
      'paths': instance.paths,
      'enabled': instance.enabled,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

_LibrarySectionsResponse _$LibrarySectionsResponseFromJson(
  Map<String, dynamic> json,
) => _LibrarySectionsResponse(
  sections: (json['sections'] as List<dynamic>)
      .map((e) => LibrarySection.fromJson(e as Map<String, dynamic>))
      .toList(),
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$LibrarySectionsResponseToJson(
  _LibrarySectionsResponse instance,
) => <String, dynamic>{
  'sections': instance.sections.map((e) => e.toJson()).toList(),
  'count': instance.count,
};

_SourceRow _$SourceRowFromJson(Map<String, dynamic> json) => _SourceRow(
  id: (json['id'] as num).toInt(),
  titleId: (json['title_id'] as num).toInt(),
  url: json['url'] as String,
  filePath: json['file_path'] as String?,
  sourceType: json['source_type'] as String,
  quality: json['quality'] as String?,
  sizeBytes: (json['size_bytes'] as num?)?.toInt(),
  scraper: json['scraper'] as String?,
  lastChecked: json['last_checked'] as String?,
  fileSize: (json['file_size'] as num?)?.toInt(),
  fileMtime: json['file_mtime'] as String?,
  fileHash: json['file_hash'] as String?,
  status: json['status'] as String,
);

Map<String, dynamic> _$SourceRowToJson(_SourceRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title_id': instance.titleId,
      'url': instance.url,
      'file_path': instance.filePath,
      'source_type': instance.sourceType,
      'quality': instance.quality,
      'size_bytes': instance.sizeBytes,
      'scraper': instance.scraper,
      'last_checked': instance.lastChecked,
      'file_size': instance.fileSize,
      'file_mtime': instance.fileMtime,
      'file_hash': instance.fileHash,
      'status': instance.status,
    };

_LibraryTitleDetail _$LibraryTitleDetailFromJson(Map<String, dynamic> json) =>
    _LibraryTitleDetail(
      id: (json['id'] as num).toInt(),
      tmdbId: json['tmdb_id'] as String?,
      type: json['type'] as String,
      title: json['title'] as String,
      year: (json['year'] as num?)?.toInt(),
      overview: json['overview'] as String?,
      posterUrl: json['poster_url'] as String?,
      backdropUrl: json['backdrop_url'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      addedAt: json['added_at'] as String,
      updatedAt: json['updated_at'] as String,
      hasLocalSource: json['has_local_source'] as bool?,
      sourceCount: (json['source_count'] as num?)?.toInt(),
      sourceTypes: (json['source_types'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$LibraryTitleDetailToJson(_LibraryTitleDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tmdb_id': instance.tmdbId,
      'type': instance.type,
      'title': instance.title,
      'year': instance.year,
      'overview': instance.overview,
      'poster_url': instance.posterUrl,
      'backdrop_url': instance.backdropUrl,
      'poster_path': instance.posterPath,
      'backdrop_path': instance.backdropPath,
      'added_at': instance.addedAt,
      'updated_at': instance.updatedAt,
      'has_local_source': instance.hasLocalSource,
      'source_count': instance.sourceCount,
      'source_types': instance.sourceTypes,
    };

_TitleSourcesResponse _$TitleSourcesResponseFromJson(
  Map<String, dynamic> json,
) => _TitleSourcesResponse(
  titleId: (json['title_id'] as num).toInt(),
  title: json['title'] as String,
  sourceTypeFilter: json['source_type_filter'] as String?,
  sources: (json['sources'] as List<dynamic>)
      .map((e) => SourceRow.fromJson(e as Map<String, dynamic>))
      .toList(),
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$TitleSourcesResponseToJson(
  _TitleSourcesResponse instance,
) => <String, dynamic>{
  'title_id': instance.titleId,
  'title': instance.title,
  'source_type_filter': instance.sourceTypeFilter,
  'sources': instance.sources.map((e) => e.toJson()).toList(),
  'count': instance.count,
};

_TitleEpisode _$TitleEpisodeFromJson(Map<String, dynamic> json) =>
    _TitleEpisode(
      id: (json['id'] as num).toInt(),
      tmdbId: json['tmdb_id'] as String?,
      titleId: (json['title_id'] as num).toInt(),
      season: (json['season'] as num).toInt(),
      episode: (json['episode'] as num).toInt(),
      name: json['name'] as String?,
      airDate: json['air_date'] as String?,
      addedAt: json['added_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$TitleEpisodeToJson(_TitleEpisode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tmdb_id': instance.tmdbId,
      'title_id': instance.titleId,
      'season': instance.season,
      'episode': instance.episode,
      'name': instance.name,
      'air_date': instance.airDate,
      'added_at': instance.addedAt,
      'updated_at': instance.updatedAt,
    };

_TitleEpisodesResponse _$TitleEpisodesResponseFromJson(
  Map<String, dynamic> json,
) => _TitleEpisodesResponse(
  titleId: (json['title_id'] as num).toInt(),
  title: json['title'] as String,
  seasonFilter: (json['season_filter'] as num?)?.toInt(),
  episodes: (json['episodes'] as List<dynamic>)
      .map((e) => TitleEpisode.fromJson(e as Map<String, dynamic>))
      .toList(),
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$TitleEpisodesResponseToJson(
  _TitleEpisodesResponse instance,
) => <String, dynamic>{
  'title_id': instance.titleId,
  'title': instance.title,
  'season_filter': instance.seasonFilter,
  'episodes': instance.episodes.map((e) => e.toJson()).toList(),
  'count': instance.count,
};

_LibrarySearchItem _$LibrarySearchItemFromJson(Map<String, dynamic> json) =>
    _LibrarySearchItem(
      id: (json['id'] as num).toInt(),
      tmdbId: json['tmdb_id'] as String?,
      type: json['type'] as String,
      title: json['title'] as String,
      year: (json['year'] as num?)?.toInt(),
      overview: json['overview'] as String?,
      posterUrl: json['poster_url'] as String?,
      backdropUrl: json['backdrop_url'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      addedAt: json['added_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$LibrarySearchItemToJson(_LibrarySearchItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tmdb_id': instance.tmdbId,
      'type': instance.type,
      'title': instance.title,
      'year': instance.year,
      'overview': instance.overview,
      'poster_url': instance.posterUrl,
      'backdrop_url': instance.backdropUrl,
      'poster_path': instance.posterPath,
      'backdrop_path': instance.backdropPath,
      'added_at': instance.addedAt,
      'updated_at': instance.updatedAt,
    };

_LibrarySearchResponse _$LibrarySearchResponseFromJson(
  Map<String, dynamic> json,
) => _LibrarySearchResponse(
  query: json['query'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => LibrarySearchItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$LibrarySearchResponseToJson(
  _LibrarySearchResponse instance,
) => <String, dynamic>{
  'query': instance.query,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'count': instance.count,
};

_LibraryListResponse _$LibraryListResponseFromJson(Map<String, dynamic> json) =>
    _LibraryListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => LibrarySearchItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
      hasNext: json['has_next'] as bool,
    );

Map<String, dynamic> _$LibraryListResponseToJson(
  _LibraryListResponse instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'limit': instance.limit,
  'offset': instance.offset,
  'has_next': instance.hasNext,
};

_ScanStatus _$ScanStatusFromJson(Map<String, dynamic> json) => _ScanStatus(
  scanId: json['scan_id'] as String,
  status: json['status'] as String,
  sectionsTotal: (json['sections_total'] as num).toInt(),
  sectionsCompleted: (json['sections_completed'] as num).toInt(),
  filesFound: (json['files_found'] as num).toInt(),
  titlesAdded: (json['titles_added'] as num).toInt(),
  titlesUpdated: (json['titles_updated'] as num).toInt(),
  sourcesAdded: (json['sources_added'] as num).toInt(),
  currentFile: json['current_file'] as String?,
  elapsedSeconds: (json['elapsed_seconds'] as num).toDouble(),
  done: json['done'] as bool,
);

Map<String, dynamic> _$ScanStatusToJson(_ScanStatus instance) =>
    <String, dynamic>{
      'scan_id': instance.scanId,
      'status': instance.status,
      'sections_total': instance.sectionsTotal,
      'sections_completed': instance.sectionsCompleted,
      'files_found': instance.filesFound,
      'titles_added': instance.titlesAdded,
      'titles_updated': instance.titlesUpdated,
      'sources_added': instance.sourcesAdded,
      'current_file': instance.currentFile,
      'elapsed_seconds': instance.elapsedSeconds,
      'done': instance.done,
    };

_ScanResultSummary _$ScanResultSummaryFromJson(Map<String, dynamic> json) =>
    _ScanResultSummary(
      totalFiles: (json['total_files'] as num).toInt(),
      newTitles: (json['new_titles'] as num).toInt(),
      updatedTitles: (json['updated_titles'] as num).toInt(),
      newEpisodes: (json['new_episodes'] as num).toInt(),
      durationSec: (json['duration_sec'] as num).toDouble(),
    );

Map<String, dynamic> _$ScanResultSummaryToJson(_ScanResultSummary instance) =>
    <String, dynamic>{
      'total_files': instance.totalFiles,
      'new_titles': instance.newTitles,
      'updated_titles': instance.updatedTitles,
      'new_episodes': instance.newEpisodes,
      'duration_sec': instance.durationSec,
    };

_ScanStatusResponse _$ScanStatusResponseFromJson(Map<String, dynamic> json) =>
    _ScanStatusResponse(
      running: json['running'] as bool,
      progress: (json['progress'] as num).toDouble(),
      message: json['message'] as String,
      logs: (json['logs'] as List<dynamic>).map((e) => e as String).toList(),
      filesDone: (json['files_done'] as num?)?.toInt(),
      filesTotal: (json['files_total'] as num?)?.toInt(),
      result: json['result'] == null
          ? null
          : ScanResultSummary.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ScanStatusResponseToJson(_ScanStatusResponse instance) =>
    <String, dynamic>{
      'running': instance.running,
      'progress': instance.progress,
      'message': instance.message,
      'logs': instance.logs,
      'files_done': instance.filesDone,
      'files_total': instance.filesTotal,
      'result': instance.result?.toJson(),
    };
