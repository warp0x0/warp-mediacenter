// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debrid.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DebridAccountInfo _$DebridAccountInfoFromJson(Map<String, dynamic> json) =>
    _DebridAccountInfo(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      email: json['email'] as String,
      points: (json['points'] as num).toInt(),
      locale: json['locale'] as String,
      avatar: json['avatar'] as String,
      type: json['type'] as String,
      premium: (json['premium'] as num).toInt(),
      expiration: json['expiration'] as String,
    );

Map<String, dynamic> _$DebridAccountInfoToJson(_DebridAccountInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'points': instance.points,
      'locale': instance.locale,
      'avatar': instance.avatar,
      'type': instance.type,
      'premium': instance.premium,
      'expiration': instance.expiration,
    };

_DebridTorrentFile _$DebridTorrentFileFromJson(Map<String, dynamic> json) =>
    _DebridTorrentFile(
      id: (json['id'] as num).toInt(),
      path: json['path'] as String,
      bytes: (json['bytes'] as num).toInt(),
      selected: (json['selected'] as num).toInt(),
    );

Map<String, dynamic> _$DebridTorrentFileToJson(_DebridTorrentFile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'path': instance.path,
      'bytes': instance.bytes,
      'selected': instance.selected,
    };

_DebridTorrentInfo _$DebridTorrentInfoFromJson(Map<String, dynamic> json) =>
    _DebridTorrentInfo(
      id: json['id'] as String,
      filename: json['filename'] as String,
      originalFilename: json['original_filename'] as String,
      hash: json['hash'] as String,
      bytes: (json['bytes'] as num).toInt(),
      originalBytes: (json['original_bytes'] as num).toInt(),
      host: json['host'] as String,
      split: (json['split'] as num).toInt(),
      progress: (json['progress'] as num).toDouble(),
      status: json['status'] as String,
      added: json['added'] as String,
      files: (json['files'] as List<dynamic>)
          .map((e) => DebridTorrentFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      links: (json['links'] as List<dynamic>).map((e) => e as String).toList(),
      ended: json['ended'] as String?,
      speed: (json['speed'] as num?)?.toDouble(),
      seeders: (json['seeders'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DebridTorrentInfoToJson(_DebridTorrentInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'filename': instance.filename,
      'original_filename': instance.originalFilename,
      'hash': instance.hash,
      'bytes': instance.bytes,
      'original_bytes': instance.originalBytes,
      'host': instance.host,
      'split': instance.split,
      'progress': instance.progress,
      'status': instance.status,
      'added': instance.added,
      'files': instance.files.map((e) => e.toJson()).toList(),
      'links': instance.links,
      'ended': instance.ended,
      'speed': instance.speed,
      'seeders': instance.seeders,
    };

_DebridStreamResponse _$DebridStreamResponseFromJson(
  Map<String, dynamic> json,
) => _DebridStreamResponse(
  torrentId: json['torrent_id'] as String,
  fileId: (json['file_id'] as num).toInt(),
  fileName: json['file_name'] as String,
  streamUrl: json['stream_url'] as String,
);

Map<String, dynamic> _$DebridStreamResponseToJson(
  _DebridStreamResponse instance,
) => <String, dynamic>{
  'torrent_id': instance.torrentId,
  'file_id': instance.fileId,
  'file_name': instance.fileName,
  'stream_url': instance.streamUrl,
};
