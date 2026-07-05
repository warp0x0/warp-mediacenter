import 'package:freezed_annotation/freezed_annotation.dart';

part 'files.freezed.dart';
part 'files.g.dart';

@freezed
abstract class FileBrowseEntry with _$FileBrowseEntry {
  const factory FileBrowseEntry({
    required String name,
    required String path,
    required bool isDir,
  }) = _FileBrowseEntry;

  factory FileBrowseEntry.fromJson(Map<String, dynamic> json) =>
      _$FileBrowseEntryFromJson(json);
}

@freezed
abstract class FileBrowseResponse with _$FileBrowseResponse {
  const factory FileBrowseResponse({
    required String path,
    String? parent,
    required List<FileBrowseEntry> entries,
  }) = _FileBrowseResponse;

  factory FileBrowseResponse.fromJson(Map<String, dynamic> json) =>
      _$FileBrowseResponseFromJson(json);
}
