import 'package:freezed_annotation/freezed_annotation.dart';

part 'debrid.freezed.dart';
part 'debrid.g.dart';

@freezed
abstract class DebridAccountInfo with _$DebridAccountInfo {
  const factory DebridAccountInfo({
    required int id,
    required String username,
    required String email,
    required int points,
    required String locale,
    required String avatar,
    required String type,
    required int premium,
    required String expiration,
  }) = _DebridAccountInfo;

  factory DebridAccountInfo.fromJson(Map<String, dynamic> json) =>
      _$DebridAccountInfoFromJson(json);
}

@freezed
abstract class DebridTorrentFile with _$DebridTorrentFile {
  const factory DebridTorrentFile({
    required int id,
    required String path,
    required int bytes,
    required int selected,
  }) = _DebridTorrentFile;

  factory DebridTorrentFile.fromJson(Map<String, dynamic> json) =>
      _$DebridTorrentFileFromJson(json);
}

@freezed
abstract class DebridTorrentInfo with _$DebridTorrentInfo {
  const factory DebridTorrentInfo({
    required String id,
    required String filename,
    required String originalFilename,
    required String hash,
    required int bytes,
    required int originalBytes,
    required String host,
    required int split,
    required double progress,
    required String status,
    required String added,
    required List<DebridTorrentFile> files,
    required List<String> links,
    String? ended,
    double? speed,
    int? seeders,
  }) = _DebridTorrentInfo;

  factory DebridTorrentInfo.fromJson(Map<String, dynamic> json) =>
      _$DebridTorrentInfoFromJson(json);
}

@freezed
abstract class DebridStreamResponse with _$DebridStreamResponse {
  const factory DebridStreamResponse({
    required String torrentId,
    required int fileId,
    required String fileName,
    required String streamUrl,
  }) = _DebridStreamResponse;

  factory DebridStreamResponse.fromJson(Map<String, dynamic> json) =>
      _$DebridStreamResponseFromJson(json);
}
