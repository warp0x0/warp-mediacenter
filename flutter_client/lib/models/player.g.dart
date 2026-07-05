// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayerState _$PlayerStateFromJson(Map<String, dynamic> json) => _PlayerState(
  positionMs: (json['position_ms'] as num).toInt(),
  durationMs: (json['duration_ms'] as num).toInt(),
  isPlaying: json['is_playing'] as bool,
  volume: (json['volume'] as num).toDouble(),
);

Map<String, dynamic> _$PlayerStateToJson(_PlayerState instance) =>
    <String, dynamic>{
      'position_ms': instance.positionMs,
      'duration_ms': instance.durationMs,
      'is_playing': instance.isPlaying,
      'volume': instance.volume,
    };

_PlayerStatus _$PlayerStatusFromJson(Map<String, dynamic> json) =>
    _PlayerStatus(
      playing: json['playing'] as bool,
      title: json['title'] as String?,
      mediaKind: json['media_kind'] as String?,
      source: json['source'] as String?,
      state: json['state'] as String?,
      positionMs: (json['position_ms'] as num?)?.toInt(),
      durationMs: (json['duration_ms'] as num?)?.toInt(),
      volume: (json['volume'] as num?)?.toDouble(),
      rate: (json['rate'] as num?)?.toDouble(),
      isStream: json['is_stream'] as bool?,
      subtitlePath: json['subtitle_path'] as String?,
      audioTrackId: (json['audio_track_id'] as num?)?.toInt(),
      subtitleTrackId: (json['subtitle_track_id'] as num?)?.toInt(),
      startedAt: json['started_at'] as String?,
    );

Map<String, dynamic> _$PlayerStatusToJson(_PlayerStatus instance) =>
    <String, dynamic>{
      'playing': instance.playing,
      'title': instance.title,
      'media_kind': instance.mediaKind,
      'source': instance.source,
      'state': instance.state,
      'position_ms': instance.positionMs,
      'duration_ms': instance.durationMs,
      'volume': instance.volume,
      'rate': instance.rate,
      'is_stream': instance.isStream,
      'subtitle_path': instance.subtitlePath,
      'audio_track_id': instance.audioTrackId,
      'subtitle_track_id': instance.subtitleTrackId,
      'started_at': instance.startedAt,
    };

_PlayerPlayRequest _$PlayerPlayRequestFromJson(Map<String, dynamic> json) =>
    _PlayerPlayRequest(
      source: json['source'] as String,
      sessionId: json['session_id'] as String?,
      title: json['title'] as String?,
      mediaKind: json['media_kind'] as String?,
      mediaFolder: json['media_folder'] as String?,
      season: (json['season'] as num?)?.toInt(),
      episode: (json['episode'] as num?)?.toInt(),
      year: (json['year'] as num?)?.toInt(),
      language: json['language'] as String?,
      startPaused: json['start_paused'] as bool?,
      isStream: json['is_stream'] as bool?,
      autoSubtitles: json['auto_subtitles'] as bool?,
      resumeFromLastPosition: json['resume_from_last_position'] as bool?,
      tmdbId: json['tmdb_id'] as String?,
      mediaPayload: json['media_payload'],
      showPayload: json['show_payload'],
      sourceType: json['source_type'] as String?,
    );

Map<String, dynamic> _$PlayerPlayRequestToJson(_PlayerPlayRequest instance) =>
    <String, dynamic>{
      'source': instance.source,
      'session_id': instance.sessionId,
      'title': instance.title,
      'media_kind': instance.mediaKind,
      'media_folder': instance.mediaFolder,
      'season': instance.season,
      'episode': instance.episode,
      'year': instance.year,
      'language': instance.language,
      'start_paused': instance.startPaused,
      'is_stream': instance.isStream,
      'auto_subtitles': instance.autoSubtitles,
      'resume_from_last_position': instance.resumeFromLastPosition,
      'tmdb_id': instance.tmdbId,
      'media_payload': instance.mediaPayload,
      'show_payload': instance.showPayload,
      'source_type': instance.sourceType,
    };

_PlayerPlayResponse _$PlayerPlayResponseFromJson(Map<String, dynamic> json) =>
    _PlayerPlayResponse(
      status: json['status'] as String,
      title: json['title'] as String,
      playerMode: json['player_mode'] as String,
    );

Map<String, dynamic> _$PlayerPlayResponseToJson(_PlayerPlayResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'title': instance.title,
      'player_mode': instance.playerMode,
    };

_NativePlayerCommandResponse _$NativePlayerCommandResponseFromJson(
  Map<String, dynamic> json,
) => _NativePlayerCommandResponse(
  ok: json['ok'] as bool,
  state: json['state'] as String,
  message: json['message'] as String,
);

Map<String, dynamic> _$NativePlayerCommandResponseToJson(
  _NativePlayerCommandResponse instance,
) => <String, dynamic>{
  'ok': instance.ok,
  'state': instance.state,
  'message': instance.message,
};

_NativePlayerStatusResponse _$NativePlayerStatusResponseFromJson(
  Map<String, dynamic> json,
) => _NativePlayerStatusResponse(
  available: json['available'] as bool,
  state: json['state'] as String,
  playing: json['playing'] as bool,
  source: json['source'] as String?,
  title: json['title'] as String?,
  mediaKind: json['media_kind'] as String?,
  sessionId: json['session_id'] as String?,
  positionMs: (json['position_ms'] as num).toInt(),
  durationMs: (json['duration_ms'] as num).toInt(),
  volume: (json['volume'] as num).toDouble(),
  updatedAtMs: (json['updated_at_ms'] as num).toInt(),
);

Map<String, dynamic> _$NativePlayerStatusResponseToJson(
  _NativePlayerStatusResponse instance,
) => <String, dynamic>{
  'available': instance.available,
  'state': instance.state,
  'playing': instance.playing,
  'source': instance.source,
  'title': instance.title,
  'media_kind': instance.mediaKind,
  'session_id': instance.sessionId,
  'position_ms': instance.positionMs,
  'duration_ms': instance.durationMs,
  'volume': instance.volume,
  'updated_at_ms': instance.updatedAtMs,
};

_PendingPlayback _$PendingPlaybackFromJson(Map<String, dynamic> json) =>
    _PendingPlayback(
      source: json['source'] as String,
      sessionId: json['session_id'] as String?,
      title: json['title'] as String?,
      mediaKind: json['media_kind'] as String?,
      tmdbId: json['tmdb_id'] as String?,
      imdbId: json['imdb_id'] as String?,
      traktId: json['trakt_id'] as String?,
      year: (json['year'] as num?)?.toInt(),
      season: (json['season'] as num?)?.toInt(),
      episode: (json['episode'] as num?)?.toInt(),
      resumePercent: (json['resume_percent'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PendingPlaybackToJson(_PendingPlayback instance) =>
    <String, dynamic>{
      'source': instance.source,
      'session_id': instance.sessionId,
      'title': instance.title,
      'media_kind': instance.mediaKind,
      'tmdb_id': instance.tmdbId,
      'imdb_id': instance.imdbId,
      'trakt_id': instance.traktId,
      'year': instance.year,
      'season': instance.season,
      'episode': instance.episode,
      'resume_percent': instance.resumePercent,
    };

_PlayerScrobbleRequest _$PlayerScrobbleRequestFromJson(
  Map<String, dynamic> json,
) => _PlayerScrobbleRequest(
  sessionId: json['session_id'] as String?,
  mediaType: json['media_type'] as String,
  media: json['media'] as Map<String, dynamic>,
  show: json['show'] as Map<String, dynamic>?,
  progress: (json['progress'] as num).toDouble(),
);

Map<String, dynamic> _$PlayerScrobbleRequestToJson(
  _PlayerScrobbleRequest instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'media_type': instance.mediaType,
  'media': instance.media,
  'show': instance.show,
  'progress': instance.progress,
};

_PlayerScrobbleResponse _$PlayerScrobbleResponseFromJson(
  Map<String, dynamic> json,
) => _PlayerScrobbleResponse(
  ok: json['ok'] as bool,
  conflict: json['conflict'] as bool,
  sessionId: json['session_id'] as String?,
  action: json['action'] as String,
  mediaType: json['media_type'] as String,
  progress: (json['progress'] as num).toDouble(),
  watchedAt: json['watched_at'] as String?,
  expiresAt: json['expires_at'] as String?,
  response: json['response'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PlayerScrobbleResponseToJson(
  _PlayerScrobbleResponse instance,
) => <String, dynamic>{
  'ok': instance.ok,
  'conflict': instance.conflict,
  'session_id': instance.sessionId,
  'action': instance.action,
  'media_type': instance.mediaType,
  'progress': instance.progress,
  'watched_at': instance.watchedAt,
  'expires_at': instance.expiresAt,
  'response': instance.response,
};
