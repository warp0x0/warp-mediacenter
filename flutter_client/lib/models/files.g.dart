// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'files.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FileBrowseEntry _$FileBrowseEntryFromJson(Map<String, dynamic> json) =>
    _FileBrowseEntry(
      name: json['name'] as String,
      path: json['path'] as String,
      isDir: json['is_dir'] as bool,
    );

Map<String, dynamic> _$FileBrowseEntryToJson(_FileBrowseEntry instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'is_dir': instance.isDir,
    };

_FileBrowseResponse _$FileBrowseResponseFromJson(Map<String, dynamic> json) =>
    _FileBrowseResponse(
      path: json['path'] as String,
      parent: json['parent'] as String?,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => FileBrowseEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FileBrowseResponseToJson(_FileBrowseResponse instance) =>
    <String, dynamic>{
      'path': instance.path,
      'parent': instance.parent,
      'entries': instance.entries.map((e) => e.toJson()).toList(),
    };
