// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerState {

 int get positionMs; int get durationMs; bool get isPlaying; double get volume;
/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerStateCopyWith<PlayerState> get copyWith => _$PlayerStateCopyWithImpl<PlayerState>(this as PlayerState, _$identity);

  /// Serializes this PlayerState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerState&&(identical(other.positionMs, positionMs) || other.positionMs == positionMs)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.volume, volume) || other.volume == volume));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,positionMs,durationMs,isPlaying,volume);

@override
String toString() {
  return 'PlayerState(positionMs: $positionMs, durationMs: $durationMs, isPlaying: $isPlaying, volume: $volume)';
}


}

/// @nodoc
abstract mixin class $PlayerStateCopyWith<$Res>  {
  factory $PlayerStateCopyWith(PlayerState value, $Res Function(PlayerState) _then) = _$PlayerStateCopyWithImpl;
@useResult
$Res call({
 int positionMs, int durationMs, bool isPlaying, double volume
});




}
/// @nodoc
class _$PlayerStateCopyWithImpl<$Res>
    implements $PlayerStateCopyWith<$Res> {
  _$PlayerStateCopyWithImpl(this._self, this._then);

  final PlayerState _self;
  final $Res Function(PlayerState) _then;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? positionMs = null,Object? durationMs = null,Object? isPlaying = null,Object? volume = null,}) {
  return _then(_self.copyWith(
positionMs: null == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as int,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerState].
extension PlayerStatePatterns on PlayerState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerState value)  $default,){
final _that = this;
switch (_that) {
case _PlayerState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerState value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int positionMs,  int durationMs,  bool isPlaying,  double volume)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that.positionMs,_that.durationMs,_that.isPlaying,_that.volume);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int positionMs,  int durationMs,  bool isPlaying,  double volume)  $default,) {final _that = this;
switch (_that) {
case _PlayerState():
return $default(_that.positionMs,_that.durationMs,_that.isPlaying,_that.volume);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int positionMs,  int durationMs,  bool isPlaying,  double volume)?  $default,) {final _that = this;
switch (_that) {
case _PlayerState() when $default != null:
return $default(_that.positionMs,_that.durationMs,_that.isPlaying,_that.volume);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerState implements PlayerState {
  const _PlayerState({required this.positionMs, required this.durationMs, required this.isPlaying, required this.volume});
  factory _PlayerState.fromJson(Map<String, dynamic> json) => _$PlayerStateFromJson(json);

@override final  int positionMs;
@override final  int durationMs;
@override final  bool isPlaying;
@override final  double volume;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerStateCopyWith<_PlayerState> get copyWith => __$PlayerStateCopyWithImpl<_PlayerState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerState&&(identical(other.positionMs, positionMs) || other.positionMs == positionMs)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.isPlaying, isPlaying) || other.isPlaying == isPlaying)&&(identical(other.volume, volume) || other.volume == volume));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,positionMs,durationMs,isPlaying,volume);

@override
String toString() {
  return 'PlayerState(positionMs: $positionMs, durationMs: $durationMs, isPlaying: $isPlaying, volume: $volume)';
}


}

/// @nodoc
abstract mixin class _$PlayerStateCopyWith<$Res> implements $PlayerStateCopyWith<$Res> {
  factory _$PlayerStateCopyWith(_PlayerState value, $Res Function(_PlayerState) _then) = __$PlayerStateCopyWithImpl;
@override @useResult
$Res call({
 int positionMs, int durationMs, bool isPlaying, double volume
});




}
/// @nodoc
class __$PlayerStateCopyWithImpl<$Res>
    implements _$PlayerStateCopyWith<$Res> {
  __$PlayerStateCopyWithImpl(this._self, this._then);

  final _PlayerState _self;
  final $Res Function(_PlayerState) _then;

/// Create a copy of PlayerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? positionMs = null,Object? durationMs = null,Object? isPlaying = null,Object? volume = null,}) {
  return _then(_PlayerState(
positionMs: null == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as int,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,isPlaying: null == isPlaying ? _self.isPlaying : isPlaying // ignore: cast_nullable_to_non_nullable
as bool,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$PlayerStatus {

 bool get playing; String? get title; String? get mediaKind; String? get source; String? get state; int? get positionMs; int? get durationMs; double? get volume; double? get rate; bool? get isStream; String? get subtitlePath; int? get audioTrackId; int? get subtitleTrackId; String? get startedAt;
/// Create a copy of PlayerStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerStatusCopyWith<PlayerStatus> get copyWith => _$PlayerStatusCopyWithImpl<PlayerStatus>(this as PlayerStatus, _$identity);

  /// Serializes this PlayerStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerStatus&&(identical(other.playing, playing) || other.playing == playing)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind)&&(identical(other.source, source) || other.source == source)&&(identical(other.state, state) || other.state == state)&&(identical(other.positionMs, positionMs) || other.positionMs == positionMs)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.isStream, isStream) || other.isStream == isStream)&&(identical(other.subtitlePath, subtitlePath) || other.subtitlePath == subtitlePath)&&(identical(other.audioTrackId, audioTrackId) || other.audioTrackId == audioTrackId)&&(identical(other.subtitleTrackId, subtitleTrackId) || other.subtitleTrackId == subtitleTrackId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playing,title,mediaKind,source,state,positionMs,durationMs,volume,rate,isStream,subtitlePath,audioTrackId,subtitleTrackId,startedAt);

@override
String toString() {
  return 'PlayerStatus(playing: $playing, title: $title, mediaKind: $mediaKind, source: $source, state: $state, positionMs: $positionMs, durationMs: $durationMs, volume: $volume, rate: $rate, isStream: $isStream, subtitlePath: $subtitlePath, audioTrackId: $audioTrackId, subtitleTrackId: $subtitleTrackId, startedAt: $startedAt)';
}


}

/// @nodoc
abstract mixin class $PlayerStatusCopyWith<$Res>  {
  factory $PlayerStatusCopyWith(PlayerStatus value, $Res Function(PlayerStatus) _then) = _$PlayerStatusCopyWithImpl;
@useResult
$Res call({
 bool playing, String? title, String? mediaKind, String? source, String? state, int? positionMs, int? durationMs, double? volume, double? rate, bool? isStream, String? subtitlePath, int? audioTrackId, int? subtitleTrackId, String? startedAt
});




}
/// @nodoc
class _$PlayerStatusCopyWithImpl<$Res>
    implements $PlayerStatusCopyWith<$Res> {
  _$PlayerStatusCopyWithImpl(this._self, this._then);

  final PlayerStatus _self;
  final $Res Function(PlayerStatus) _then;

/// Create a copy of PlayerStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playing = null,Object? title = freezed,Object? mediaKind = freezed,Object? source = freezed,Object? state = freezed,Object? positionMs = freezed,Object? durationMs = freezed,Object? volume = freezed,Object? rate = freezed,Object? isStream = freezed,Object? subtitlePath = freezed,Object? audioTrackId = freezed,Object? subtitleTrackId = freezed,Object? startedAt = freezed,}) {
  return _then(_self.copyWith(
playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,mediaKind: freezed == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,positionMs: freezed == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as int?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,volume: freezed == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double?,rate: freezed == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double?,isStream: freezed == isStream ? _self.isStream : isStream // ignore: cast_nullable_to_non_nullable
as bool?,subtitlePath: freezed == subtitlePath ? _self.subtitlePath : subtitlePath // ignore: cast_nullable_to_non_nullable
as String?,audioTrackId: freezed == audioTrackId ? _self.audioTrackId : audioTrackId // ignore: cast_nullable_to_non_nullable
as int?,subtitleTrackId: freezed == subtitleTrackId ? _self.subtitleTrackId : subtitleTrackId // ignore: cast_nullable_to_non_nullable
as int?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerStatus].
extension PlayerStatusPatterns on PlayerStatus {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerStatus() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerStatus value)  $default,){
final _that = this;
switch (_that) {
case _PlayerStatus():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerStatus value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerStatus() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool playing,  String? title,  String? mediaKind,  String? source,  String? state,  int? positionMs,  int? durationMs,  double? volume,  double? rate,  bool? isStream,  String? subtitlePath,  int? audioTrackId,  int? subtitleTrackId,  String? startedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerStatus() when $default != null:
return $default(_that.playing,_that.title,_that.mediaKind,_that.source,_that.state,_that.positionMs,_that.durationMs,_that.volume,_that.rate,_that.isStream,_that.subtitlePath,_that.audioTrackId,_that.subtitleTrackId,_that.startedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool playing,  String? title,  String? mediaKind,  String? source,  String? state,  int? positionMs,  int? durationMs,  double? volume,  double? rate,  bool? isStream,  String? subtitlePath,  int? audioTrackId,  int? subtitleTrackId,  String? startedAt)  $default,) {final _that = this;
switch (_that) {
case _PlayerStatus():
return $default(_that.playing,_that.title,_that.mediaKind,_that.source,_that.state,_that.positionMs,_that.durationMs,_that.volume,_that.rate,_that.isStream,_that.subtitlePath,_that.audioTrackId,_that.subtitleTrackId,_that.startedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool playing,  String? title,  String? mediaKind,  String? source,  String? state,  int? positionMs,  int? durationMs,  double? volume,  double? rate,  bool? isStream,  String? subtitlePath,  int? audioTrackId,  int? subtitleTrackId,  String? startedAt)?  $default,) {final _that = this;
switch (_that) {
case _PlayerStatus() when $default != null:
return $default(_that.playing,_that.title,_that.mediaKind,_that.source,_that.state,_that.positionMs,_that.durationMs,_that.volume,_that.rate,_that.isStream,_that.subtitlePath,_that.audioTrackId,_that.subtitleTrackId,_that.startedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerStatus implements PlayerStatus {
  const _PlayerStatus({required this.playing, this.title, this.mediaKind, this.source, this.state, this.positionMs, this.durationMs, this.volume, this.rate, this.isStream, this.subtitlePath, this.audioTrackId, this.subtitleTrackId, this.startedAt});
  factory _PlayerStatus.fromJson(Map<String, dynamic> json) => _$PlayerStatusFromJson(json);

@override final  bool playing;
@override final  String? title;
@override final  String? mediaKind;
@override final  String? source;
@override final  String? state;
@override final  int? positionMs;
@override final  int? durationMs;
@override final  double? volume;
@override final  double? rate;
@override final  bool? isStream;
@override final  String? subtitlePath;
@override final  int? audioTrackId;
@override final  int? subtitleTrackId;
@override final  String? startedAt;

/// Create a copy of PlayerStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerStatusCopyWith<_PlayerStatus> get copyWith => __$PlayerStatusCopyWithImpl<_PlayerStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerStatus&&(identical(other.playing, playing) || other.playing == playing)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind)&&(identical(other.source, source) || other.source == source)&&(identical(other.state, state) || other.state == state)&&(identical(other.positionMs, positionMs) || other.positionMs == positionMs)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.isStream, isStream) || other.isStream == isStream)&&(identical(other.subtitlePath, subtitlePath) || other.subtitlePath == subtitlePath)&&(identical(other.audioTrackId, audioTrackId) || other.audioTrackId == audioTrackId)&&(identical(other.subtitleTrackId, subtitleTrackId) || other.subtitleTrackId == subtitleTrackId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playing,title,mediaKind,source,state,positionMs,durationMs,volume,rate,isStream,subtitlePath,audioTrackId,subtitleTrackId,startedAt);

@override
String toString() {
  return 'PlayerStatus(playing: $playing, title: $title, mediaKind: $mediaKind, source: $source, state: $state, positionMs: $positionMs, durationMs: $durationMs, volume: $volume, rate: $rate, isStream: $isStream, subtitlePath: $subtitlePath, audioTrackId: $audioTrackId, subtitleTrackId: $subtitleTrackId, startedAt: $startedAt)';
}


}

/// @nodoc
abstract mixin class _$PlayerStatusCopyWith<$Res> implements $PlayerStatusCopyWith<$Res> {
  factory _$PlayerStatusCopyWith(_PlayerStatus value, $Res Function(_PlayerStatus) _then) = __$PlayerStatusCopyWithImpl;
@override @useResult
$Res call({
 bool playing, String? title, String? mediaKind, String? source, String? state, int? positionMs, int? durationMs, double? volume, double? rate, bool? isStream, String? subtitlePath, int? audioTrackId, int? subtitleTrackId, String? startedAt
});




}
/// @nodoc
class __$PlayerStatusCopyWithImpl<$Res>
    implements _$PlayerStatusCopyWith<$Res> {
  __$PlayerStatusCopyWithImpl(this._self, this._then);

  final _PlayerStatus _self;
  final $Res Function(_PlayerStatus) _then;

/// Create a copy of PlayerStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playing = null,Object? title = freezed,Object? mediaKind = freezed,Object? source = freezed,Object? state = freezed,Object? positionMs = freezed,Object? durationMs = freezed,Object? volume = freezed,Object? rate = freezed,Object? isStream = freezed,Object? subtitlePath = freezed,Object? audioTrackId = freezed,Object? subtitleTrackId = freezed,Object? startedAt = freezed,}) {
  return _then(_PlayerStatus(
playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,mediaKind: freezed == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,positionMs: freezed == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as int?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,volume: freezed == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double?,rate: freezed == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double?,isStream: freezed == isStream ? _self.isStream : isStream // ignore: cast_nullable_to_non_nullable
as bool?,subtitlePath: freezed == subtitlePath ? _self.subtitlePath : subtitlePath // ignore: cast_nullable_to_non_nullable
as String?,audioTrackId: freezed == audioTrackId ? _self.audioTrackId : audioTrackId // ignore: cast_nullable_to_non_nullable
as int?,subtitleTrackId: freezed == subtitleTrackId ? _self.subtitleTrackId : subtitleTrackId // ignore: cast_nullable_to_non_nullable
as int?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PlayerPlayRequest {

 String get source; String? get sessionId; String? get title; String? get mediaKind; String? get mediaFolder; int? get season; int? get episode; int? get year; String? get language; bool? get startPaused; bool? get isStream; bool? get autoSubtitles; bool? get resumeFromLastPosition; String? get tmdbId; Object? get mediaPayload; Object? get showPayload; String? get sourceType;
/// Create a copy of PlayerPlayRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerPlayRequestCopyWith<PlayerPlayRequest> get copyWith => _$PlayerPlayRequestCopyWithImpl<PlayerPlayRequest>(this as PlayerPlayRequest, _$identity);

  /// Serializes this PlayerPlayRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerPlayRequest&&(identical(other.source, source) || other.source == source)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind)&&(identical(other.mediaFolder, mediaFolder) || other.mediaFolder == mediaFolder)&&(identical(other.season, season) || other.season == season)&&(identical(other.episode, episode) || other.episode == episode)&&(identical(other.year, year) || other.year == year)&&(identical(other.language, language) || other.language == language)&&(identical(other.startPaused, startPaused) || other.startPaused == startPaused)&&(identical(other.isStream, isStream) || other.isStream == isStream)&&(identical(other.autoSubtitles, autoSubtitles) || other.autoSubtitles == autoSubtitles)&&(identical(other.resumeFromLastPosition, resumeFromLastPosition) || other.resumeFromLastPosition == resumeFromLastPosition)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&const DeepCollectionEquality().equals(other.mediaPayload, mediaPayload)&&const DeepCollectionEquality().equals(other.showPayload, showPayload)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,sessionId,title,mediaKind,mediaFolder,season,episode,year,language,startPaused,isStream,autoSubtitles,resumeFromLastPosition,tmdbId,const DeepCollectionEquality().hash(mediaPayload),const DeepCollectionEquality().hash(showPayload),sourceType);

@override
String toString() {
  return 'PlayerPlayRequest(source: $source, sessionId: $sessionId, title: $title, mediaKind: $mediaKind, mediaFolder: $mediaFolder, season: $season, episode: $episode, year: $year, language: $language, startPaused: $startPaused, isStream: $isStream, autoSubtitles: $autoSubtitles, resumeFromLastPosition: $resumeFromLastPosition, tmdbId: $tmdbId, mediaPayload: $mediaPayload, showPayload: $showPayload, sourceType: $sourceType)';
}


}

/// @nodoc
abstract mixin class $PlayerPlayRequestCopyWith<$Res>  {
  factory $PlayerPlayRequestCopyWith(PlayerPlayRequest value, $Res Function(PlayerPlayRequest) _then) = _$PlayerPlayRequestCopyWithImpl;
@useResult
$Res call({
 String source, String? sessionId, String? title, String? mediaKind, String? mediaFolder, int? season, int? episode, int? year, String? language, bool? startPaused, bool? isStream, bool? autoSubtitles, bool? resumeFromLastPosition, String? tmdbId, Object? mediaPayload, Object? showPayload, String? sourceType
});




}
/// @nodoc
class _$PlayerPlayRequestCopyWithImpl<$Res>
    implements $PlayerPlayRequestCopyWith<$Res> {
  _$PlayerPlayRequestCopyWithImpl(this._self, this._then);

  final PlayerPlayRequest _self;
  final $Res Function(PlayerPlayRequest) _then;

/// Create a copy of PlayerPlayRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? sessionId = freezed,Object? title = freezed,Object? mediaKind = freezed,Object? mediaFolder = freezed,Object? season = freezed,Object? episode = freezed,Object? year = freezed,Object? language = freezed,Object? startPaused = freezed,Object? isStream = freezed,Object? autoSubtitles = freezed,Object? resumeFromLastPosition = freezed,Object? tmdbId = freezed,Object? mediaPayload = freezed,Object? showPayload = freezed,Object? sourceType = freezed,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,mediaKind: freezed == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as String?,mediaFolder: freezed == mediaFolder ? _self.mediaFolder : mediaFolder // ignore: cast_nullable_to_non_nullable
as String?,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as int?,episode: freezed == episode ? _self.episode : episode // ignore: cast_nullable_to_non_nullable
as int?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,startPaused: freezed == startPaused ? _self.startPaused : startPaused // ignore: cast_nullable_to_non_nullable
as bool?,isStream: freezed == isStream ? _self.isStream : isStream // ignore: cast_nullable_to_non_nullable
as bool?,autoSubtitles: freezed == autoSubtitles ? _self.autoSubtitles : autoSubtitles // ignore: cast_nullable_to_non_nullable
as bool?,resumeFromLastPosition: freezed == resumeFromLastPosition ? _self.resumeFromLastPosition : resumeFromLastPosition // ignore: cast_nullable_to_non_nullable
as bool?,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,mediaPayload: freezed == mediaPayload ? _self.mediaPayload : mediaPayload ,showPayload: freezed == showPayload ? _self.showPayload : showPayload ,sourceType: freezed == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerPlayRequest].
extension PlayerPlayRequestPatterns on PlayerPlayRequest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerPlayRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerPlayRequest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerPlayRequest value)  $default,){
final _that = this;
switch (_that) {
case _PlayerPlayRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerPlayRequest value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerPlayRequest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String source,  String? sessionId,  String? title,  String? mediaKind,  String? mediaFolder,  int? season,  int? episode,  int? year,  String? language,  bool? startPaused,  bool? isStream,  bool? autoSubtitles,  bool? resumeFromLastPosition,  String? tmdbId,  Object? mediaPayload,  Object? showPayload,  String? sourceType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerPlayRequest() when $default != null:
return $default(_that.source,_that.sessionId,_that.title,_that.mediaKind,_that.mediaFolder,_that.season,_that.episode,_that.year,_that.language,_that.startPaused,_that.isStream,_that.autoSubtitles,_that.resumeFromLastPosition,_that.tmdbId,_that.mediaPayload,_that.showPayload,_that.sourceType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String source,  String? sessionId,  String? title,  String? mediaKind,  String? mediaFolder,  int? season,  int? episode,  int? year,  String? language,  bool? startPaused,  bool? isStream,  bool? autoSubtitles,  bool? resumeFromLastPosition,  String? tmdbId,  Object? mediaPayload,  Object? showPayload,  String? sourceType)  $default,) {final _that = this;
switch (_that) {
case _PlayerPlayRequest():
return $default(_that.source,_that.sessionId,_that.title,_that.mediaKind,_that.mediaFolder,_that.season,_that.episode,_that.year,_that.language,_that.startPaused,_that.isStream,_that.autoSubtitles,_that.resumeFromLastPosition,_that.tmdbId,_that.mediaPayload,_that.showPayload,_that.sourceType);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String source,  String? sessionId,  String? title,  String? mediaKind,  String? mediaFolder,  int? season,  int? episode,  int? year,  String? language,  bool? startPaused,  bool? isStream,  bool? autoSubtitles,  bool? resumeFromLastPosition,  String? tmdbId,  Object? mediaPayload,  Object? showPayload,  String? sourceType)?  $default,) {final _that = this;
switch (_that) {
case _PlayerPlayRequest() when $default != null:
return $default(_that.source,_that.sessionId,_that.title,_that.mediaKind,_that.mediaFolder,_that.season,_that.episode,_that.year,_that.language,_that.startPaused,_that.isStream,_that.autoSubtitles,_that.resumeFromLastPosition,_that.tmdbId,_that.mediaPayload,_that.showPayload,_that.sourceType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerPlayRequest implements PlayerPlayRequest {
  const _PlayerPlayRequest({required this.source, this.sessionId, this.title, this.mediaKind, this.mediaFolder, this.season, this.episode, this.year, this.language, this.startPaused, this.isStream, this.autoSubtitles, this.resumeFromLastPosition, this.tmdbId, this.mediaPayload, this.showPayload, this.sourceType});
  factory _PlayerPlayRequest.fromJson(Map<String, dynamic> json) => _$PlayerPlayRequestFromJson(json);

@override final  String source;
@override final  String? sessionId;
@override final  String? title;
@override final  String? mediaKind;
@override final  String? mediaFolder;
@override final  int? season;
@override final  int? episode;
@override final  int? year;
@override final  String? language;
@override final  bool? startPaused;
@override final  bool? isStream;
@override final  bool? autoSubtitles;
@override final  bool? resumeFromLastPosition;
@override final  String? tmdbId;
@override final  Object? mediaPayload;
@override final  Object? showPayload;
@override final  String? sourceType;

/// Create a copy of PlayerPlayRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerPlayRequestCopyWith<_PlayerPlayRequest> get copyWith => __$PlayerPlayRequestCopyWithImpl<_PlayerPlayRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerPlayRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerPlayRequest&&(identical(other.source, source) || other.source == source)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind)&&(identical(other.mediaFolder, mediaFolder) || other.mediaFolder == mediaFolder)&&(identical(other.season, season) || other.season == season)&&(identical(other.episode, episode) || other.episode == episode)&&(identical(other.year, year) || other.year == year)&&(identical(other.language, language) || other.language == language)&&(identical(other.startPaused, startPaused) || other.startPaused == startPaused)&&(identical(other.isStream, isStream) || other.isStream == isStream)&&(identical(other.autoSubtitles, autoSubtitles) || other.autoSubtitles == autoSubtitles)&&(identical(other.resumeFromLastPosition, resumeFromLastPosition) || other.resumeFromLastPosition == resumeFromLastPosition)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&const DeepCollectionEquality().equals(other.mediaPayload, mediaPayload)&&const DeepCollectionEquality().equals(other.showPayload, showPayload)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,sessionId,title,mediaKind,mediaFolder,season,episode,year,language,startPaused,isStream,autoSubtitles,resumeFromLastPosition,tmdbId,const DeepCollectionEquality().hash(mediaPayload),const DeepCollectionEquality().hash(showPayload),sourceType);

@override
String toString() {
  return 'PlayerPlayRequest(source: $source, sessionId: $sessionId, title: $title, mediaKind: $mediaKind, mediaFolder: $mediaFolder, season: $season, episode: $episode, year: $year, language: $language, startPaused: $startPaused, isStream: $isStream, autoSubtitles: $autoSubtitles, resumeFromLastPosition: $resumeFromLastPosition, tmdbId: $tmdbId, mediaPayload: $mediaPayload, showPayload: $showPayload, sourceType: $sourceType)';
}


}

/// @nodoc
abstract mixin class _$PlayerPlayRequestCopyWith<$Res> implements $PlayerPlayRequestCopyWith<$Res> {
  factory _$PlayerPlayRequestCopyWith(_PlayerPlayRequest value, $Res Function(_PlayerPlayRequest) _then) = __$PlayerPlayRequestCopyWithImpl;
@override @useResult
$Res call({
 String source, String? sessionId, String? title, String? mediaKind, String? mediaFolder, int? season, int? episode, int? year, String? language, bool? startPaused, bool? isStream, bool? autoSubtitles, bool? resumeFromLastPosition, String? tmdbId, Object? mediaPayload, Object? showPayload, String? sourceType
});




}
/// @nodoc
class __$PlayerPlayRequestCopyWithImpl<$Res>
    implements _$PlayerPlayRequestCopyWith<$Res> {
  __$PlayerPlayRequestCopyWithImpl(this._self, this._then);

  final _PlayerPlayRequest _self;
  final $Res Function(_PlayerPlayRequest) _then;

/// Create a copy of PlayerPlayRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? sessionId = freezed,Object? title = freezed,Object? mediaKind = freezed,Object? mediaFolder = freezed,Object? season = freezed,Object? episode = freezed,Object? year = freezed,Object? language = freezed,Object? startPaused = freezed,Object? isStream = freezed,Object? autoSubtitles = freezed,Object? resumeFromLastPosition = freezed,Object? tmdbId = freezed,Object? mediaPayload = freezed,Object? showPayload = freezed,Object? sourceType = freezed,}) {
  return _then(_PlayerPlayRequest(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,mediaKind: freezed == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as String?,mediaFolder: freezed == mediaFolder ? _self.mediaFolder : mediaFolder // ignore: cast_nullable_to_non_nullable
as String?,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as int?,episode: freezed == episode ? _self.episode : episode // ignore: cast_nullable_to_non_nullable
as int?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,startPaused: freezed == startPaused ? _self.startPaused : startPaused // ignore: cast_nullable_to_non_nullable
as bool?,isStream: freezed == isStream ? _self.isStream : isStream // ignore: cast_nullable_to_non_nullable
as bool?,autoSubtitles: freezed == autoSubtitles ? _self.autoSubtitles : autoSubtitles // ignore: cast_nullable_to_non_nullable
as bool?,resumeFromLastPosition: freezed == resumeFromLastPosition ? _self.resumeFromLastPosition : resumeFromLastPosition // ignore: cast_nullable_to_non_nullable
as bool?,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,mediaPayload: freezed == mediaPayload ? _self.mediaPayload : mediaPayload ,showPayload: freezed == showPayload ? _self.showPayload : showPayload ,sourceType: freezed == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PlayerPlayResponse {

 String get status; String get title; String get playerMode;
/// Create a copy of PlayerPlayResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerPlayResponseCopyWith<PlayerPlayResponse> get copyWith => _$PlayerPlayResponseCopyWithImpl<PlayerPlayResponse>(this as PlayerPlayResponse, _$identity);

  /// Serializes this PlayerPlayResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerPlayResponse&&(identical(other.status, status) || other.status == status)&&(identical(other.title, title) || other.title == title)&&(identical(other.playerMode, playerMode) || other.playerMode == playerMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,title,playerMode);

@override
String toString() {
  return 'PlayerPlayResponse(status: $status, title: $title, playerMode: $playerMode)';
}


}

/// @nodoc
abstract mixin class $PlayerPlayResponseCopyWith<$Res>  {
  factory $PlayerPlayResponseCopyWith(PlayerPlayResponse value, $Res Function(PlayerPlayResponse) _then) = _$PlayerPlayResponseCopyWithImpl;
@useResult
$Res call({
 String status, String title, String playerMode
});




}
/// @nodoc
class _$PlayerPlayResponseCopyWithImpl<$Res>
    implements $PlayerPlayResponseCopyWith<$Res> {
  _$PlayerPlayResponseCopyWithImpl(this._self, this._then);

  final PlayerPlayResponse _self;
  final $Res Function(PlayerPlayResponse) _then;

/// Create a copy of PlayerPlayResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? title = null,Object? playerMode = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,playerMode: null == playerMode ? _self.playerMode : playerMode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerPlayResponse].
extension PlayerPlayResponsePatterns on PlayerPlayResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerPlayResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerPlayResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerPlayResponse value)  $default,){
final _that = this;
switch (_that) {
case _PlayerPlayResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerPlayResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerPlayResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String title,  String playerMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerPlayResponse() when $default != null:
return $default(_that.status,_that.title,_that.playerMode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String title,  String playerMode)  $default,) {final _that = this;
switch (_that) {
case _PlayerPlayResponse():
return $default(_that.status,_that.title,_that.playerMode);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String title,  String playerMode)?  $default,) {final _that = this;
switch (_that) {
case _PlayerPlayResponse() when $default != null:
return $default(_that.status,_that.title,_that.playerMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerPlayResponse implements PlayerPlayResponse {
  const _PlayerPlayResponse({required this.status, required this.title, required this.playerMode});
  factory _PlayerPlayResponse.fromJson(Map<String, dynamic> json) => _$PlayerPlayResponseFromJson(json);

@override final  String status;
@override final  String title;
@override final  String playerMode;

/// Create a copy of PlayerPlayResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerPlayResponseCopyWith<_PlayerPlayResponse> get copyWith => __$PlayerPlayResponseCopyWithImpl<_PlayerPlayResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerPlayResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerPlayResponse&&(identical(other.status, status) || other.status == status)&&(identical(other.title, title) || other.title == title)&&(identical(other.playerMode, playerMode) || other.playerMode == playerMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,title,playerMode);

@override
String toString() {
  return 'PlayerPlayResponse(status: $status, title: $title, playerMode: $playerMode)';
}


}

/// @nodoc
abstract mixin class _$PlayerPlayResponseCopyWith<$Res> implements $PlayerPlayResponseCopyWith<$Res> {
  factory _$PlayerPlayResponseCopyWith(_PlayerPlayResponse value, $Res Function(_PlayerPlayResponse) _then) = __$PlayerPlayResponseCopyWithImpl;
@override @useResult
$Res call({
 String status, String title, String playerMode
});




}
/// @nodoc
class __$PlayerPlayResponseCopyWithImpl<$Res>
    implements _$PlayerPlayResponseCopyWith<$Res> {
  __$PlayerPlayResponseCopyWithImpl(this._self, this._then);

  final _PlayerPlayResponse _self;
  final $Res Function(_PlayerPlayResponse) _then;

/// Create a copy of PlayerPlayResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? title = null,Object? playerMode = null,}) {
  return _then(_PlayerPlayResponse(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,playerMode: null == playerMode ? _self.playerMode : playerMode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NativePlayerCommandResponse {

 bool get ok; String get state; String get message;
/// Create a copy of NativePlayerCommandResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativePlayerCommandResponseCopyWith<NativePlayerCommandResponse> get copyWith => _$NativePlayerCommandResponseCopyWithImpl<NativePlayerCommandResponse>(this as NativePlayerCommandResponse, _$identity);

  /// Serializes this NativePlayerCommandResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePlayerCommandResponse&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.state, state) || other.state == state)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ok,state,message);

@override
String toString() {
  return 'NativePlayerCommandResponse(ok: $ok, state: $state, message: $message)';
}


}

/// @nodoc
abstract mixin class $NativePlayerCommandResponseCopyWith<$Res>  {
  factory $NativePlayerCommandResponseCopyWith(NativePlayerCommandResponse value, $Res Function(NativePlayerCommandResponse) _then) = _$NativePlayerCommandResponseCopyWithImpl;
@useResult
$Res call({
 bool ok, String state, String message
});




}
/// @nodoc
class _$NativePlayerCommandResponseCopyWithImpl<$Res>
    implements $NativePlayerCommandResponseCopyWith<$Res> {
  _$NativePlayerCommandResponseCopyWithImpl(this._self, this._then);

  final NativePlayerCommandResponse _self;
  final $Res Function(NativePlayerCommandResponse) _then;

/// Create a copy of NativePlayerCommandResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ok = null,Object? state = null,Object? message = null,}) {
  return _then(_self.copyWith(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NativePlayerCommandResponse].
extension NativePlayerCommandResponsePatterns on NativePlayerCommandResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativePlayerCommandResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativePlayerCommandResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativePlayerCommandResponse value)  $default,){
final _that = this;
switch (_that) {
case _NativePlayerCommandResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativePlayerCommandResponse value)?  $default,){
final _that = this;
switch (_that) {
case _NativePlayerCommandResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool ok,  String state,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativePlayerCommandResponse() when $default != null:
return $default(_that.ok,_that.state,_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool ok,  String state,  String message)  $default,) {final _that = this;
switch (_that) {
case _NativePlayerCommandResponse():
return $default(_that.ok,_that.state,_that.message);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool ok,  String state,  String message)?  $default,) {final _that = this;
switch (_that) {
case _NativePlayerCommandResponse() when $default != null:
return $default(_that.ok,_that.state,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NativePlayerCommandResponse implements NativePlayerCommandResponse {
  const _NativePlayerCommandResponse({required this.ok, required this.state, required this.message});
  factory _NativePlayerCommandResponse.fromJson(Map<String, dynamic> json) => _$NativePlayerCommandResponseFromJson(json);

@override final  bool ok;
@override final  String state;
@override final  String message;

/// Create a copy of NativePlayerCommandResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativePlayerCommandResponseCopyWith<_NativePlayerCommandResponse> get copyWith => __$NativePlayerCommandResponseCopyWithImpl<_NativePlayerCommandResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NativePlayerCommandResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativePlayerCommandResponse&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.state, state) || other.state == state)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ok,state,message);

@override
String toString() {
  return 'NativePlayerCommandResponse(ok: $ok, state: $state, message: $message)';
}


}

/// @nodoc
abstract mixin class _$NativePlayerCommandResponseCopyWith<$Res> implements $NativePlayerCommandResponseCopyWith<$Res> {
  factory _$NativePlayerCommandResponseCopyWith(_NativePlayerCommandResponse value, $Res Function(_NativePlayerCommandResponse) _then) = __$NativePlayerCommandResponseCopyWithImpl;
@override @useResult
$Res call({
 bool ok, String state, String message
});




}
/// @nodoc
class __$NativePlayerCommandResponseCopyWithImpl<$Res>
    implements _$NativePlayerCommandResponseCopyWith<$Res> {
  __$NativePlayerCommandResponseCopyWithImpl(this._self, this._then);

  final _NativePlayerCommandResponse _self;
  final $Res Function(_NativePlayerCommandResponse) _then;

/// Create a copy of NativePlayerCommandResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ok = null,Object? state = null,Object? message = null,}) {
  return _then(_NativePlayerCommandResponse(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NativePlayerStatusResponse {

 bool get available; String get state; bool get playing; String? get source; String? get title; String? get mediaKind; String? get sessionId; int get positionMs; int get durationMs; double get volume; int get updatedAtMs;
/// Create a copy of NativePlayerStatusResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NativePlayerStatusResponseCopyWith<NativePlayerStatusResponse> get copyWith => _$NativePlayerStatusResponseCopyWithImpl<NativePlayerStatusResponse>(this as NativePlayerStatusResponse, _$identity);

  /// Serializes this NativePlayerStatusResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NativePlayerStatusResponse&&(identical(other.available, available) || other.available == available)&&(identical(other.state, state) || other.state == state)&&(identical(other.playing, playing) || other.playing == playing)&&(identical(other.source, source) || other.source == source)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.positionMs, positionMs) || other.positionMs == positionMs)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.updatedAtMs, updatedAtMs) || other.updatedAtMs == updatedAtMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,available,state,playing,source,title,mediaKind,sessionId,positionMs,durationMs,volume,updatedAtMs);

@override
String toString() {
  return 'NativePlayerStatusResponse(available: $available, state: $state, playing: $playing, source: $source, title: $title, mediaKind: $mediaKind, sessionId: $sessionId, positionMs: $positionMs, durationMs: $durationMs, volume: $volume, updatedAtMs: $updatedAtMs)';
}


}

/// @nodoc
abstract mixin class $NativePlayerStatusResponseCopyWith<$Res>  {
  factory $NativePlayerStatusResponseCopyWith(NativePlayerStatusResponse value, $Res Function(NativePlayerStatusResponse) _then) = _$NativePlayerStatusResponseCopyWithImpl;
@useResult
$Res call({
 bool available, String state, bool playing, String? source, String? title, String? mediaKind, String? sessionId, int positionMs, int durationMs, double volume, int updatedAtMs
});




}
/// @nodoc
class _$NativePlayerStatusResponseCopyWithImpl<$Res>
    implements $NativePlayerStatusResponseCopyWith<$Res> {
  _$NativePlayerStatusResponseCopyWithImpl(this._self, this._then);

  final NativePlayerStatusResponse _self;
  final $Res Function(NativePlayerStatusResponse) _then;

/// Create a copy of NativePlayerStatusResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? available = null,Object? state = null,Object? playing = null,Object? source = freezed,Object? title = freezed,Object? mediaKind = freezed,Object? sessionId = freezed,Object? positionMs = null,Object? durationMs = null,Object? volume = null,Object? updatedAtMs = null,}) {
  return _then(_self.copyWith(
available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,mediaKind: freezed == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as String?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,positionMs: null == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as int,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,updatedAtMs: null == updatedAtMs ? _self.updatedAtMs : updatedAtMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NativePlayerStatusResponse].
extension NativePlayerStatusResponsePatterns on NativePlayerStatusResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NativePlayerStatusResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NativePlayerStatusResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NativePlayerStatusResponse value)  $default,){
final _that = this;
switch (_that) {
case _NativePlayerStatusResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NativePlayerStatusResponse value)?  $default,){
final _that = this;
switch (_that) {
case _NativePlayerStatusResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool available,  String state,  bool playing,  String? source,  String? title,  String? mediaKind,  String? sessionId,  int positionMs,  int durationMs,  double volume,  int updatedAtMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NativePlayerStatusResponse() when $default != null:
return $default(_that.available,_that.state,_that.playing,_that.source,_that.title,_that.mediaKind,_that.sessionId,_that.positionMs,_that.durationMs,_that.volume,_that.updatedAtMs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool available,  String state,  bool playing,  String? source,  String? title,  String? mediaKind,  String? sessionId,  int positionMs,  int durationMs,  double volume,  int updatedAtMs)  $default,) {final _that = this;
switch (_that) {
case _NativePlayerStatusResponse():
return $default(_that.available,_that.state,_that.playing,_that.source,_that.title,_that.mediaKind,_that.sessionId,_that.positionMs,_that.durationMs,_that.volume,_that.updatedAtMs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool available,  String state,  bool playing,  String? source,  String? title,  String? mediaKind,  String? sessionId,  int positionMs,  int durationMs,  double volume,  int updatedAtMs)?  $default,) {final _that = this;
switch (_that) {
case _NativePlayerStatusResponse() when $default != null:
return $default(_that.available,_that.state,_that.playing,_that.source,_that.title,_that.mediaKind,_that.sessionId,_that.positionMs,_that.durationMs,_that.volume,_that.updatedAtMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NativePlayerStatusResponse implements NativePlayerStatusResponse {
  const _NativePlayerStatusResponse({required this.available, required this.state, required this.playing, this.source, this.title, this.mediaKind, this.sessionId, required this.positionMs, required this.durationMs, required this.volume, required this.updatedAtMs});
  factory _NativePlayerStatusResponse.fromJson(Map<String, dynamic> json) => _$NativePlayerStatusResponseFromJson(json);

@override final  bool available;
@override final  String state;
@override final  bool playing;
@override final  String? source;
@override final  String? title;
@override final  String? mediaKind;
@override final  String? sessionId;
@override final  int positionMs;
@override final  int durationMs;
@override final  double volume;
@override final  int updatedAtMs;

/// Create a copy of NativePlayerStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NativePlayerStatusResponseCopyWith<_NativePlayerStatusResponse> get copyWith => __$NativePlayerStatusResponseCopyWithImpl<_NativePlayerStatusResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NativePlayerStatusResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NativePlayerStatusResponse&&(identical(other.available, available) || other.available == available)&&(identical(other.state, state) || other.state == state)&&(identical(other.playing, playing) || other.playing == playing)&&(identical(other.source, source) || other.source == source)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.positionMs, positionMs) || other.positionMs == positionMs)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.updatedAtMs, updatedAtMs) || other.updatedAtMs == updatedAtMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,available,state,playing,source,title,mediaKind,sessionId,positionMs,durationMs,volume,updatedAtMs);

@override
String toString() {
  return 'NativePlayerStatusResponse(available: $available, state: $state, playing: $playing, source: $source, title: $title, mediaKind: $mediaKind, sessionId: $sessionId, positionMs: $positionMs, durationMs: $durationMs, volume: $volume, updatedAtMs: $updatedAtMs)';
}


}

/// @nodoc
abstract mixin class _$NativePlayerStatusResponseCopyWith<$Res> implements $NativePlayerStatusResponseCopyWith<$Res> {
  factory _$NativePlayerStatusResponseCopyWith(_NativePlayerStatusResponse value, $Res Function(_NativePlayerStatusResponse) _then) = __$NativePlayerStatusResponseCopyWithImpl;
@override @useResult
$Res call({
 bool available, String state, bool playing, String? source, String? title, String? mediaKind, String? sessionId, int positionMs, int durationMs, double volume, int updatedAtMs
});




}
/// @nodoc
class __$NativePlayerStatusResponseCopyWithImpl<$Res>
    implements _$NativePlayerStatusResponseCopyWith<$Res> {
  __$NativePlayerStatusResponseCopyWithImpl(this._self, this._then);

  final _NativePlayerStatusResponse _self;
  final $Res Function(_NativePlayerStatusResponse) _then;

/// Create a copy of NativePlayerStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? available = null,Object? state = null,Object? playing = null,Object? source = freezed,Object? title = freezed,Object? mediaKind = freezed,Object? sessionId = freezed,Object? positionMs = null,Object? durationMs = null,Object? volume = null,Object? updatedAtMs = null,}) {
  return _then(_NativePlayerStatusResponse(
available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,playing: null == playing ? _self.playing : playing // ignore: cast_nullable_to_non_nullable
as bool,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,mediaKind: freezed == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as String?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,positionMs: null == positionMs ? _self.positionMs : positionMs // ignore: cast_nullable_to_non_nullable
as int,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double,updatedAtMs: null == updatedAtMs ? _self.updatedAtMs : updatedAtMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PendingPlayback {

 String get source; String? get sessionId; String? get title; String? get mediaKind; String? get tmdbId; String? get imdbId; String? get traktId; int? get year; int? get season; int? get episode; double? get resumePercent;
/// Create a copy of PendingPlayback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingPlaybackCopyWith<PendingPlayback> get copyWith => _$PendingPlaybackCopyWithImpl<PendingPlayback>(this as PendingPlayback, _$identity);

  /// Serializes this PendingPlayback to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingPlayback&&(identical(other.source, source) || other.source == source)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.imdbId, imdbId) || other.imdbId == imdbId)&&(identical(other.traktId, traktId) || other.traktId == traktId)&&(identical(other.year, year) || other.year == year)&&(identical(other.season, season) || other.season == season)&&(identical(other.episode, episode) || other.episode == episode)&&(identical(other.resumePercent, resumePercent) || other.resumePercent == resumePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,sessionId,title,mediaKind,tmdbId,imdbId,traktId,year,season,episode,resumePercent);

@override
String toString() {
  return 'PendingPlayback(source: $source, sessionId: $sessionId, title: $title, mediaKind: $mediaKind, tmdbId: $tmdbId, imdbId: $imdbId, traktId: $traktId, year: $year, season: $season, episode: $episode, resumePercent: $resumePercent)';
}


}

/// @nodoc
abstract mixin class $PendingPlaybackCopyWith<$Res>  {
  factory $PendingPlaybackCopyWith(PendingPlayback value, $Res Function(PendingPlayback) _then) = _$PendingPlaybackCopyWithImpl;
@useResult
$Res call({
 String source, String? sessionId, String? title, String? mediaKind, String? tmdbId, String? imdbId, String? traktId, int? year, int? season, int? episode, double? resumePercent
});




}
/// @nodoc
class _$PendingPlaybackCopyWithImpl<$Res>
    implements $PendingPlaybackCopyWith<$Res> {
  _$PendingPlaybackCopyWithImpl(this._self, this._then);

  final PendingPlayback _self;
  final $Res Function(PendingPlayback) _then;

/// Create a copy of PendingPlayback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? sessionId = freezed,Object? title = freezed,Object? mediaKind = freezed,Object? tmdbId = freezed,Object? imdbId = freezed,Object? traktId = freezed,Object? year = freezed,Object? season = freezed,Object? episode = freezed,Object? resumePercent = freezed,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,mediaKind: freezed == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as String?,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,imdbId: freezed == imdbId ? _self.imdbId : imdbId // ignore: cast_nullable_to_non_nullable
as String?,traktId: freezed == traktId ? _self.traktId : traktId // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as int?,episode: freezed == episode ? _self.episode : episode // ignore: cast_nullable_to_non_nullable
as int?,resumePercent: freezed == resumePercent ? _self.resumePercent : resumePercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingPlayback].
extension PendingPlaybackPatterns on PendingPlayback {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingPlayback value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingPlayback() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingPlayback value)  $default,){
final _that = this;
switch (_that) {
case _PendingPlayback():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingPlayback value)?  $default,){
final _that = this;
switch (_that) {
case _PendingPlayback() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String source,  String? sessionId,  String? title,  String? mediaKind,  String? tmdbId,  String? imdbId,  String? traktId,  int? year,  int? season,  int? episode,  double? resumePercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingPlayback() when $default != null:
return $default(_that.source,_that.sessionId,_that.title,_that.mediaKind,_that.tmdbId,_that.imdbId,_that.traktId,_that.year,_that.season,_that.episode,_that.resumePercent);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String source,  String? sessionId,  String? title,  String? mediaKind,  String? tmdbId,  String? imdbId,  String? traktId,  int? year,  int? season,  int? episode,  double? resumePercent)  $default,) {final _that = this;
switch (_that) {
case _PendingPlayback():
return $default(_that.source,_that.sessionId,_that.title,_that.mediaKind,_that.tmdbId,_that.imdbId,_that.traktId,_that.year,_that.season,_that.episode,_that.resumePercent);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String source,  String? sessionId,  String? title,  String? mediaKind,  String? tmdbId,  String? imdbId,  String? traktId,  int? year,  int? season,  int? episode,  double? resumePercent)?  $default,) {final _that = this;
switch (_that) {
case _PendingPlayback() when $default != null:
return $default(_that.source,_that.sessionId,_that.title,_that.mediaKind,_that.tmdbId,_that.imdbId,_that.traktId,_that.year,_that.season,_that.episode,_that.resumePercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingPlayback implements PendingPlayback {
  const _PendingPlayback({required this.source, this.sessionId, this.title, this.mediaKind, this.tmdbId, this.imdbId, this.traktId, this.year, this.season, this.episode, this.resumePercent});
  factory _PendingPlayback.fromJson(Map<String, dynamic> json) => _$PendingPlaybackFromJson(json);

@override final  String source;
@override final  String? sessionId;
@override final  String? title;
@override final  String? mediaKind;
@override final  String? tmdbId;
@override final  String? imdbId;
@override final  String? traktId;
@override final  int? year;
@override final  int? season;
@override final  int? episode;
@override final  double? resumePercent;

/// Create a copy of PendingPlayback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingPlaybackCopyWith<_PendingPlayback> get copyWith => __$PendingPlaybackCopyWithImpl<_PendingPlayback>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingPlaybackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingPlayback&&(identical(other.source, source) || other.source == source)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.imdbId, imdbId) || other.imdbId == imdbId)&&(identical(other.traktId, traktId) || other.traktId == traktId)&&(identical(other.year, year) || other.year == year)&&(identical(other.season, season) || other.season == season)&&(identical(other.episode, episode) || other.episode == episode)&&(identical(other.resumePercent, resumePercent) || other.resumePercent == resumePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,sessionId,title,mediaKind,tmdbId,imdbId,traktId,year,season,episode,resumePercent);

@override
String toString() {
  return 'PendingPlayback(source: $source, sessionId: $sessionId, title: $title, mediaKind: $mediaKind, tmdbId: $tmdbId, imdbId: $imdbId, traktId: $traktId, year: $year, season: $season, episode: $episode, resumePercent: $resumePercent)';
}


}

/// @nodoc
abstract mixin class _$PendingPlaybackCopyWith<$Res> implements $PendingPlaybackCopyWith<$Res> {
  factory _$PendingPlaybackCopyWith(_PendingPlayback value, $Res Function(_PendingPlayback) _then) = __$PendingPlaybackCopyWithImpl;
@override @useResult
$Res call({
 String source, String? sessionId, String? title, String? mediaKind, String? tmdbId, String? imdbId, String? traktId, int? year, int? season, int? episode, double? resumePercent
});




}
/// @nodoc
class __$PendingPlaybackCopyWithImpl<$Res>
    implements _$PendingPlaybackCopyWith<$Res> {
  __$PendingPlaybackCopyWithImpl(this._self, this._then);

  final _PendingPlayback _self;
  final $Res Function(_PendingPlayback) _then;

/// Create a copy of PendingPlayback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? sessionId = freezed,Object? title = freezed,Object? mediaKind = freezed,Object? tmdbId = freezed,Object? imdbId = freezed,Object? traktId = freezed,Object? year = freezed,Object? season = freezed,Object? episode = freezed,Object? resumePercent = freezed,}) {
  return _then(_PendingPlayback(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,mediaKind: freezed == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as String?,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,imdbId: freezed == imdbId ? _self.imdbId : imdbId // ignore: cast_nullable_to_non_nullable
as String?,traktId: freezed == traktId ? _self.traktId : traktId // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as int?,episode: freezed == episode ? _self.episode : episode // ignore: cast_nullable_to_non_nullable
as int?,resumePercent: freezed == resumePercent ? _self.resumePercent : resumePercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$PlayerScrobbleRequest {

 String? get sessionId; String get mediaType; Map<String, dynamic> get media; Map<String, dynamic>? get show; double get progress;
/// Create a copy of PlayerScrobbleRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerScrobbleRequestCopyWith<PlayerScrobbleRequest> get copyWith => _$PlayerScrobbleRequestCopyWithImpl<PlayerScrobbleRequest>(this as PlayerScrobbleRequest, _$identity);

  /// Serializes this PlayerScrobbleRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerScrobbleRequest&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&const DeepCollectionEquality().equals(other.media, media)&&const DeepCollectionEquality().equals(other.show, show)&&(identical(other.progress, progress) || other.progress == progress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,mediaType,const DeepCollectionEquality().hash(media),const DeepCollectionEquality().hash(show),progress);

@override
String toString() {
  return 'PlayerScrobbleRequest(sessionId: $sessionId, mediaType: $mediaType, media: $media, show: $show, progress: $progress)';
}


}

/// @nodoc
abstract mixin class $PlayerScrobbleRequestCopyWith<$Res>  {
  factory $PlayerScrobbleRequestCopyWith(PlayerScrobbleRequest value, $Res Function(PlayerScrobbleRequest) _then) = _$PlayerScrobbleRequestCopyWithImpl;
@useResult
$Res call({
 String? sessionId, String mediaType, Map<String, dynamic> media, Map<String, dynamic>? show, double progress
});




}
/// @nodoc
class _$PlayerScrobbleRequestCopyWithImpl<$Res>
    implements $PlayerScrobbleRequestCopyWith<$Res> {
  _$PlayerScrobbleRequestCopyWithImpl(this._self, this._then);

  final PlayerScrobbleRequest _self;
  final $Res Function(PlayerScrobbleRequest) _then;

/// Create a copy of PlayerScrobbleRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = freezed,Object? mediaType = null,Object? media = null,Object? show = freezed,Object? progress = null,}) {
  return _then(_self.copyWith(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,show: freezed == show ? _self.show : show // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerScrobbleRequest].
extension PlayerScrobbleRequestPatterns on PlayerScrobbleRequest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerScrobbleRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerScrobbleRequest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerScrobbleRequest value)  $default,){
final _that = this;
switch (_that) {
case _PlayerScrobbleRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerScrobbleRequest value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerScrobbleRequest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? sessionId,  String mediaType,  Map<String, dynamic> media,  Map<String, dynamic>? show,  double progress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerScrobbleRequest() when $default != null:
return $default(_that.sessionId,_that.mediaType,_that.media,_that.show,_that.progress);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? sessionId,  String mediaType,  Map<String, dynamic> media,  Map<String, dynamic>? show,  double progress)  $default,) {final _that = this;
switch (_that) {
case _PlayerScrobbleRequest():
return $default(_that.sessionId,_that.mediaType,_that.media,_that.show,_that.progress);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? sessionId,  String mediaType,  Map<String, dynamic> media,  Map<String, dynamic>? show,  double progress)?  $default,) {final _that = this;
switch (_that) {
case _PlayerScrobbleRequest() when $default != null:
return $default(_that.sessionId,_that.mediaType,_that.media,_that.show,_that.progress);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerScrobbleRequest implements PlayerScrobbleRequest {
  const _PlayerScrobbleRequest({this.sessionId, required this.mediaType, required final  Map<String, dynamic> media, final  Map<String, dynamic>? show, required this.progress}): _media = media,_show = show;
  factory _PlayerScrobbleRequest.fromJson(Map<String, dynamic> json) => _$PlayerScrobbleRequestFromJson(json);

@override final  String? sessionId;
@override final  String mediaType;
 final  Map<String, dynamic> _media;
@override Map<String, dynamic> get media {
  if (_media is EqualUnmodifiableMapView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_media);
}

 final  Map<String, dynamic>? _show;
@override Map<String, dynamic>? get show {
  final value = _show;
  if (value == null) return null;
  if (_show is EqualUnmodifiableMapView) return _show;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  double progress;

/// Create a copy of PlayerScrobbleRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerScrobbleRequestCopyWith<_PlayerScrobbleRequest> get copyWith => __$PlayerScrobbleRequestCopyWithImpl<_PlayerScrobbleRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerScrobbleRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerScrobbleRequest&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&const DeepCollectionEquality().equals(other._media, _media)&&const DeepCollectionEquality().equals(other._show, _show)&&(identical(other.progress, progress) || other.progress == progress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,mediaType,const DeepCollectionEquality().hash(_media),const DeepCollectionEquality().hash(_show),progress);

@override
String toString() {
  return 'PlayerScrobbleRequest(sessionId: $sessionId, mediaType: $mediaType, media: $media, show: $show, progress: $progress)';
}


}

/// @nodoc
abstract mixin class _$PlayerScrobbleRequestCopyWith<$Res> implements $PlayerScrobbleRequestCopyWith<$Res> {
  factory _$PlayerScrobbleRequestCopyWith(_PlayerScrobbleRequest value, $Res Function(_PlayerScrobbleRequest) _then) = __$PlayerScrobbleRequestCopyWithImpl;
@override @useResult
$Res call({
 String? sessionId, String mediaType, Map<String, dynamic> media, Map<String, dynamic>? show, double progress
});




}
/// @nodoc
class __$PlayerScrobbleRequestCopyWithImpl<$Res>
    implements _$PlayerScrobbleRequestCopyWith<$Res> {
  __$PlayerScrobbleRequestCopyWithImpl(this._self, this._then);

  final _PlayerScrobbleRequest _self;
  final $Res Function(_PlayerScrobbleRequest) _then;

/// Create a copy of PlayerScrobbleRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = freezed,Object? mediaType = null,Object? media = null,Object? show = freezed,Object? progress = null,}) {
  return _then(_PlayerScrobbleRequest(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,show: freezed == show ? _self._show : show // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$PlayerScrobbleResponse {

 bool get ok; bool get conflict; String? get sessionId; String get action; String get mediaType; double get progress; String? get watchedAt; String? get expiresAt; Map<String, dynamic>? get response;
/// Create a copy of PlayerScrobbleResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerScrobbleResponseCopyWith<PlayerScrobbleResponse> get copyWith => _$PlayerScrobbleResponseCopyWithImpl<PlayerScrobbleResponse>(this as PlayerScrobbleResponse, _$identity);

  /// Serializes this PlayerScrobbleResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerScrobbleResponse&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.conflict, conflict) || other.conflict == conflict)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.action, action) || other.action == action)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.watchedAt, watchedAt) || other.watchedAt == watchedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&const DeepCollectionEquality().equals(other.response, response));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ok,conflict,sessionId,action,mediaType,progress,watchedAt,expiresAt,const DeepCollectionEquality().hash(response));

@override
String toString() {
  return 'PlayerScrobbleResponse(ok: $ok, conflict: $conflict, sessionId: $sessionId, action: $action, mediaType: $mediaType, progress: $progress, watchedAt: $watchedAt, expiresAt: $expiresAt, response: $response)';
}


}

/// @nodoc
abstract mixin class $PlayerScrobbleResponseCopyWith<$Res>  {
  factory $PlayerScrobbleResponseCopyWith(PlayerScrobbleResponse value, $Res Function(PlayerScrobbleResponse) _then) = _$PlayerScrobbleResponseCopyWithImpl;
@useResult
$Res call({
 bool ok, bool conflict, String? sessionId, String action, String mediaType, double progress, String? watchedAt, String? expiresAt, Map<String, dynamic>? response
});




}
/// @nodoc
class _$PlayerScrobbleResponseCopyWithImpl<$Res>
    implements $PlayerScrobbleResponseCopyWith<$Res> {
  _$PlayerScrobbleResponseCopyWithImpl(this._self, this._then);

  final PlayerScrobbleResponse _self;
  final $Res Function(PlayerScrobbleResponse) _then;

/// Create a copy of PlayerScrobbleResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ok = null,Object? conflict = null,Object? sessionId = freezed,Object? action = null,Object? mediaType = null,Object? progress = null,Object? watchedAt = freezed,Object? expiresAt = freezed,Object? response = freezed,}) {
  return _then(_self.copyWith(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,conflict: null == conflict ? _self.conflict : conflict // ignore: cast_nullable_to_non_nullable
as bool,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,watchedAt: freezed == watchedAt ? _self.watchedAt : watchedAt // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,response: freezed == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerScrobbleResponse].
extension PlayerScrobbleResponsePatterns on PlayerScrobbleResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerScrobbleResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerScrobbleResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerScrobbleResponse value)  $default,){
final _that = this;
switch (_that) {
case _PlayerScrobbleResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerScrobbleResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerScrobbleResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool ok,  bool conflict,  String? sessionId,  String action,  String mediaType,  double progress,  String? watchedAt,  String? expiresAt,  Map<String, dynamic>? response)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerScrobbleResponse() when $default != null:
return $default(_that.ok,_that.conflict,_that.sessionId,_that.action,_that.mediaType,_that.progress,_that.watchedAt,_that.expiresAt,_that.response);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool ok,  bool conflict,  String? sessionId,  String action,  String mediaType,  double progress,  String? watchedAt,  String? expiresAt,  Map<String, dynamic>? response)  $default,) {final _that = this;
switch (_that) {
case _PlayerScrobbleResponse():
return $default(_that.ok,_that.conflict,_that.sessionId,_that.action,_that.mediaType,_that.progress,_that.watchedAt,_that.expiresAt,_that.response);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool ok,  bool conflict,  String? sessionId,  String action,  String mediaType,  double progress,  String? watchedAt,  String? expiresAt,  Map<String, dynamic>? response)?  $default,) {final _that = this;
switch (_that) {
case _PlayerScrobbleResponse() when $default != null:
return $default(_that.ok,_that.conflict,_that.sessionId,_that.action,_that.mediaType,_that.progress,_that.watchedAt,_that.expiresAt,_that.response);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerScrobbleResponse implements PlayerScrobbleResponse {
  const _PlayerScrobbleResponse({required this.ok, required this.conflict, this.sessionId, required this.action, required this.mediaType, required this.progress, this.watchedAt, this.expiresAt, final  Map<String, dynamic>? response}): _response = response;
  factory _PlayerScrobbleResponse.fromJson(Map<String, dynamic> json) => _$PlayerScrobbleResponseFromJson(json);

@override final  bool ok;
@override final  bool conflict;
@override final  String? sessionId;
@override final  String action;
@override final  String mediaType;
@override final  double progress;
@override final  String? watchedAt;
@override final  String? expiresAt;
 final  Map<String, dynamic>? _response;
@override Map<String, dynamic>? get response {
  final value = _response;
  if (value == null) return null;
  if (_response is EqualUnmodifiableMapView) return _response;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of PlayerScrobbleResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerScrobbleResponseCopyWith<_PlayerScrobbleResponse> get copyWith => __$PlayerScrobbleResponseCopyWithImpl<_PlayerScrobbleResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerScrobbleResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerScrobbleResponse&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.conflict, conflict) || other.conflict == conflict)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.action, action) || other.action == action)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.watchedAt, watchedAt) || other.watchedAt == watchedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&const DeepCollectionEquality().equals(other._response, _response));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ok,conflict,sessionId,action,mediaType,progress,watchedAt,expiresAt,const DeepCollectionEquality().hash(_response));

@override
String toString() {
  return 'PlayerScrobbleResponse(ok: $ok, conflict: $conflict, sessionId: $sessionId, action: $action, mediaType: $mediaType, progress: $progress, watchedAt: $watchedAt, expiresAt: $expiresAt, response: $response)';
}


}

/// @nodoc
abstract mixin class _$PlayerScrobbleResponseCopyWith<$Res> implements $PlayerScrobbleResponseCopyWith<$Res> {
  factory _$PlayerScrobbleResponseCopyWith(_PlayerScrobbleResponse value, $Res Function(_PlayerScrobbleResponse) _then) = __$PlayerScrobbleResponseCopyWithImpl;
@override @useResult
$Res call({
 bool ok, bool conflict, String? sessionId, String action, String mediaType, double progress, String? watchedAt, String? expiresAt, Map<String, dynamic>? response
});




}
/// @nodoc
class __$PlayerScrobbleResponseCopyWithImpl<$Res>
    implements _$PlayerScrobbleResponseCopyWith<$Res> {
  __$PlayerScrobbleResponseCopyWithImpl(this._self, this._then);

  final _PlayerScrobbleResponse _self;
  final $Res Function(_PlayerScrobbleResponse) _then;

/// Create a copy of PlayerScrobbleResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ok = null,Object? conflict = null,Object? sessionId = freezed,Object? action = null,Object? mediaType = null,Object? progress = null,Object? watchedAt = freezed,Object? expiresAt = freezed,Object? response = freezed,}) {
  return _then(_PlayerScrobbleResponse(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,conflict: null == conflict ? _self.conflict : conflict // ignore: cast_nullable_to_non_nullable
as bool,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,watchedAt: freezed == watchedAt ? _self.watchedAt : watchedAt // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,response: freezed == response ? _self._response : response // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
