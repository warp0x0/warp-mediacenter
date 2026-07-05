// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PreloadStatus _$PreloadStatusFromJson(Map<String, dynamic> json) =>
    _PreloadStatus(
      url: json['url'] as String,
      active: json['active'] as bool,
      bytesDownloaded: (json['bytes_downloaded'] as num).toInt(),
      totalSize: (json['total_size'] as num).toInt(),
      percent: (json['percent'] as num).toDouble(),
      downloadComplete: json['download_complete'] as bool,
    );

Map<String, dynamic> _$PreloadStatusToJson(_PreloadStatus instance) =>
    <String, dynamic>{
      'url': instance.url,
      'active': instance.active,
      'bytes_downloaded': instance.bytesDownloaded,
      'total_size': instance.totalSize,
      'percent': instance.percent,
      'download_complete': instance.downloadComplete,
    };

_PreloadSessionCreateRequest _$PreloadSessionCreateRequestFromJson(
  Map<String, dynamic> json,
) => _PreloadSessionCreateRequest(
  streamUrl: json['stream_url'] as String?,
  magnet: json['magnet'] as String?,
  title: json['title'] as String?,
  mediaKind: json['media_kind'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
  startPercent: (json['start_percent'] as num?)?.toDouble(),
);

Map<String, dynamic> _$PreloadSessionCreateRequestToJson(
  _PreloadSessionCreateRequest instance,
) => <String, dynamic>{
  'stream_url': instance.streamUrl,
  'magnet': instance.magnet,
  'title': instance.title,
  'media_kind': instance.mediaKind,
  'metadata': instance.metadata,
  'start_percent': instance.startPercent,
};

_PreloadSessionCreateResponse _$PreloadSessionCreateResponseFromJson(
  Map<String, dynamic> json,
) => _PreloadSessionCreateResponse(
  sessionId: json['session_id'] as String,
  playbackUrl: json['playback_url'] as String,
  localUrl: json['local_url'] as String?,
  statusUrl: json['status_url'] as String,
  cleanupUrl: json['cleanup_url'] as String,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$PreloadSessionCreateResponseToJson(
  _PreloadSessionCreateResponse instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'playback_url': instance.playbackUrl,
  'local_url': instance.localUrl,
  'status_url': instance.statusUrl,
  'cleanup_url': instance.cleanupUrl,
  'created_at': instance.createdAt,
};

_PreloadSessionStatus _$PreloadSessionStatusFromJson(
  Map<String, dynamic> json,
) => _PreloadSessionStatus(
  sessionId: json['session_id'] as String,
  url: json['url'] as String,
  active: json['active'] as bool,
  bytesDownloaded: (json['bytes_downloaded'] as num).toInt(),
  totalSize: (json['total_size'] as num).toInt(),
  remainingSize: (json['remaining_size'] as num?)?.toInt(),
  percent: (json['percent'] as num).toDouble(),
  downloadComplete: json['download_complete'] as bool,
  error: json['error'] as String?,
  state: json['state'] as String,
  title: json['title'] as String?,
  mediaKind: json['media_kind'] as String?,
  playbackUrl: json['playback_url'] as String,
  localTorrent: json['local_torrent'] as bool?,
  bufferAheadBytes: (json['buffer_ahead_bytes'] as num).toInt(),
  activeStreams: (json['active_streams'] as num).toInt(),
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$PreloadSessionStatusToJson(
  _PreloadSessionStatus instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'url': instance.url,
  'active': instance.active,
  'bytes_downloaded': instance.bytesDownloaded,
  'total_size': instance.totalSize,
  'remaining_size': instance.remainingSize,
  'percent': instance.percent,
  'download_complete': instance.downloadComplete,
  'error': instance.error,
  'state': instance.state,
  'title': instance.title,
  'media_kind': instance.mediaKind,
  'playback_url': instance.playbackUrl,
  'local_torrent': instance.localTorrent,
  'buffer_ahead_bytes': instance.bufferAheadBytes,
  'active_streams': instance.activeStreams,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
