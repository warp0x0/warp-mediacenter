// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'torrent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TorrentSearchRequest {

 String get query; String? get mediaType; String? get tmdbId; int? get season; int? get episode; int? get year; int? get limit;
/// Create a copy of TorrentSearchRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TorrentSearchRequestCopyWith<TorrentSearchRequest> get copyWith => _$TorrentSearchRequestCopyWithImpl<TorrentSearchRequest>(this as TorrentSearchRequest, _$identity);

  /// Serializes this TorrentSearchRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TorrentSearchRequest&&(identical(other.query, query) || other.query == query)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.season, season) || other.season == season)&&(identical(other.episode, episode) || other.episode == episode)&&(identical(other.year, year) || other.year == year)&&(identical(other.limit, limit) || other.limit == limit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,mediaType,tmdbId,season,episode,year,limit);

@override
String toString() {
  return 'TorrentSearchRequest(query: $query, mediaType: $mediaType, tmdbId: $tmdbId, season: $season, episode: $episode, year: $year, limit: $limit)';
}


}

/// @nodoc
abstract mixin class $TorrentSearchRequestCopyWith<$Res>  {
  factory $TorrentSearchRequestCopyWith(TorrentSearchRequest value, $Res Function(TorrentSearchRequest) _then) = _$TorrentSearchRequestCopyWithImpl;
@useResult
$Res call({
 String query, String? mediaType, String? tmdbId, int? season, int? episode, int? year, int? limit
});




}
/// @nodoc
class _$TorrentSearchRequestCopyWithImpl<$Res>
    implements $TorrentSearchRequestCopyWith<$Res> {
  _$TorrentSearchRequestCopyWithImpl(this._self, this._then);

  final TorrentSearchRequest _self;
  final $Res Function(TorrentSearchRequest) _then;

/// Create a copy of TorrentSearchRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? mediaType = freezed,Object? tmdbId = freezed,Object? season = freezed,Object? episode = freezed,Object? year = freezed,Object? limit = freezed,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as int?,episode: freezed == episode ? _self.episode : episode // ignore: cast_nullable_to_non_nullable
as int?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [TorrentSearchRequest].
extension TorrentSearchRequestPatterns on TorrentSearchRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TorrentSearchRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TorrentSearchRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TorrentSearchRequest value)  $default,){
final _that = this;
switch (_that) {
case _TorrentSearchRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TorrentSearchRequest value)?  $default,){
final _that = this;
switch (_that) {
case _TorrentSearchRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  String? mediaType,  String? tmdbId,  int? season,  int? episode,  int? year,  int? limit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TorrentSearchRequest() when $default != null:
return $default(_that.query,_that.mediaType,_that.tmdbId,_that.season,_that.episode,_that.year,_that.limit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  String? mediaType,  String? tmdbId,  int? season,  int? episode,  int? year,  int? limit)  $default,) {final _that = this;
switch (_that) {
case _TorrentSearchRequest():
return $default(_that.query,_that.mediaType,_that.tmdbId,_that.season,_that.episode,_that.year,_that.limit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  String? mediaType,  String? tmdbId,  int? season,  int? episode,  int? year,  int? limit)?  $default,) {final _that = this;
switch (_that) {
case _TorrentSearchRequest() when $default != null:
return $default(_that.query,_that.mediaType,_that.tmdbId,_that.season,_that.episode,_that.year,_that.limit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TorrentSearchRequest implements TorrentSearchRequest {
  const _TorrentSearchRequest({required this.query, this.mediaType, this.tmdbId, this.season, this.episode, this.year, this.limit});
  factory _TorrentSearchRequest.fromJson(Map<String, dynamic> json) => _$TorrentSearchRequestFromJson(json);

@override final  String query;
@override final  String? mediaType;
@override final  String? tmdbId;
@override final  int? season;
@override final  int? episode;
@override final  int? year;
@override final  int? limit;

/// Create a copy of TorrentSearchRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TorrentSearchRequestCopyWith<_TorrentSearchRequest> get copyWith => __$TorrentSearchRequestCopyWithImpl<_TorrentSearchRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TorrentSearchRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TorrentSearchRequest&&(identical(other.query, query) || other.query == query)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.season, season) || other.season == season)&&(identical(other.episode, episode) || other.episode == episode)&&(identical(other.year, year) || other.year == year)&&(identical(other.limit, limit) || other.limit == limit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,mediaType,tmdbId,season,episode,year,limit);

@override
String toString() {
  return 'TorrentSearchRequest(query: $query, mediaType: $mediaType, tmdbId: $tmdbId, season: $season, episode: $episode, year: $year, limit: $limit)';
}


}

/// @nodoc
abstract mixin class _$TorrentSearchRequestCopyWith<$Res> implements $TorrentSearchRequestCopyWith<$Res> {
  factory _$TorrentSearchRequestCopyWith(_TorrentSearchRequest value, $Res Function(_TorrentSearchRequest) _then) = __$TorrentSearchRequestCopyWithImpl;
@override @useResult
$Res call({
 String query, String? mediaType, String? tmdbId, int? season, int? episode, int? year, int? limit
});




}
/// @nodoc
class __$TorrentSearchRequestCopyWithImpl<$Res>
    implements _$TorrentSearchRequestCopyWith<$Res> {
  __$TorrentSearchRequestCopyWithImpl(this._self, this._then);

  final _TorrentSearchRequest _self;
  final $Res Function(_TorrentSearchRequest) _then;

/// Create a copy of TorrentSearchRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? mediaType = freezed,Object? tmdbId = freezed,Object? season = freezed,Object? episode = freezed,Object? year = freezed,Object? limit = freezed,}) {
  return _then(_TorrentSearchRequest(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as int?,episode: freezed == episode ? _self.episode : episode // ignore: cast_nullable_to_non_nullable
as int?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$TorrentResult {

 String get name; String get hash; String get magnet; int get seeders; int get leechers; String get size; int get sizeBytes; String get sourceSite; String get quality; bool get isCached; double get matchScore; String get uploader; String get date;
/// Create a copy of TorrentResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TorrentResultCopyWith<TorrentResult> get copyWith => _$TorrentResultCopyWithImpl<TorrentResult>(this as TorrentResult, _$identity);

  /// Serializes this TorrentResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TorrentResult&&(identical(other.name, name) || other.name == name)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.magnet, magnet) || other.magnet == magnet)&&(identical(other.seeders, seeders) || other.seeders == seeders)&&(identical(other.leechers, leechers) || other.leechers == leechers)&&(identical(other.size, size) || other.size == size)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.sourceSite, sourceSite) || other.sourceSite == sourceSite)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.isCached, isCached) || other.isCached == isCached)&&(identical(other.matchScore, matchScore) || other.matchScore == matchScore)&&(identical(other.uploader, uploader) || other.uploader == uploader)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,hash,magnet,seeders,leechers,size,sizeBytes,sourceSite,quality,isCached,matchScore,uploader,date);

@override
String toString() {
  return 'TorrentResult(name: $name, hash: $hash, magnet: $magnet, seeders: $seeders, leechers: $leechers, size: $size, sizeBytes: $sizeBytes, sourceSite: $sourceSite, quality: $quality, isCached: $isCached, matchScore: $matchScore, uploader: $uploader, date: $date)';
}


}

/// @nodoc
abstract mixin class $TorrentResultCopyWith<$Res>  {
  factory $TorrentResultCopyWith(TorrentResult value, $Res Function(TorrentResult) _then) = _$TorrentResultCopyWithImpl;
@useResult
$Res call({
 String name, String hash, String magnet, int seeders, int leechers, String size, int sizeBytes, String sourceSite, String quality, bool isCached, double matchScore, String uploader, String date
});




}
/// @nodoc
class _$TorrentResultCopyWithImpl<$Res>
    implements $TorrentResultCopyWith<$Res> {
  _$TorrentResultCopyWithImpl(this._self, this._then);

  final TorrentResult _self;
  final $Res Function(TorrentResult) _then;

/// Create a copy of TorrentResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? hash = null,Object? magnet = null,Object? seeders = null,Object? leechers = null,Object? size = null,Object? sizeBytes = null,Object? sourceSite = null,Object? quality = null,Object? isCached = null,Object? matchScore = null,Object? uploader = null,Object? date = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,magnet: null == magnet ? _self.magnet : magnet // ignore: cast_nullable_to_non_nullable
as String,seeders: null == seeders ? _self.seeders : seeders // ignore: cast_nullable_to_non_nullable
as int,leechers: null == leechers ? _self.leechers : leechers // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sourceSite: null == sourceSite ? _self.sourceSite : sourceSite // ignore: cast_nullable_to_non_nullable
as String,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as String,isCached: null == isCached ? _self.isCached : isCached // ignore: cast_nullable_to_non_nullable
as bool,matchScore: null == matchScore ? _self.matchScore : matchScore // ignore: cast_nullable_to_non_nullable
as double,uploader: null == uploader ? _self.uploader : uploader // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TorrentResult].
extension TorrentResultPatterns on TorrentResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TorrentResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TorrentResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TorrentResult value)  $default,){
final _that = this;
switch (_that) {
case _TorrentResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TorrentResult value)?  $default,){
final _that = this;
switch (_that) {
case _TorrentResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String hash,  String magnet,  int seeders,  int leechers,  String size,  int sizeBytes,  String sourceSite,  String quality,  bool isCached,  double matchScore,  String uploader,  String date)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TorrentResult() when $default != null:
return $default(_that.name,_that.hash,_that.magnet,_that.seeders,_that.leechers,_that.size,_that.sizeBytes,_that.sourceSite,_that.quality,_that.isCached,_that.matchScore,_that.uploader,_that.date);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String hash,  String magnet,  int seeders,  int leechers,  String size,  int sizeBytes,  String sourceSite,  String quality,  bool isCached,  double matchScore,  String uploader,  String date)  $default,) {final _that = this;
switch (_that) {
case _TorrentResult():
return $default(_that.name,_that.hash,_that.magnet,_that.seeders,_that.leechers,_that.size,_that.sizeBytes,_that.sourceSite,_that.quality,_that.isCached,_that.matchScore,_that.uploader,_that.date);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String hash,  String magnet,  int seeders,  int leechers,  String size,  int sizeBytes,  String sourceSite,  String quality,  bool isCached,  double matchScore,  String uploader,  String date)?  $default,) {final _that = this;
switch (_that) {
case _TorrentResult() when $default != null:
return $default(_that.name,_that.hash,_that.magnet,_that.seeders,_that.leechers,_that.size,_that.sizeBytes,_that.sourceSite,_that.quality,_that.isCached,_that.matchScore,_that.uploader,_that.date);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TorrentResult implements TorrentResult {
  const _TorrentResult({required this.name, required this.hash, required this.magnet, required this.seeders, required this.leechers, required this.size, required this.sizeBytes, required this.sourceSite, required this.quality, required this.isCached, required this.matchScore, required this.uploader, required this.date});
  factory _TorrentResult.fromJson(Map<String, dynamic> json) => _$TorrentResultFromJson(json);

@override final  String name;
@override final  String hash;
@override final  String magnet;
@override final  int seeders;
@override final  int leechers;
@override final  String size;
@override final  int sizeBytes;
@override final  String sourceSite;
@override final  String quality;
@override final  bool isCached;
@override final  double matchScore;
@override final  String uploader;
@override final  String date;

/// Create a copy of TorrentResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TorrentResultCopyWith<_TorrentResult> get copyWith => __$TorrentResultCopyWithImpl<_TorrentResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TorrentResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TorrentResult&&(identical(other.name, name) || other.name == name)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.magnet, magnet) || other.magnet == magnet)&&(identical(other.seeders, seeders) || other.seeders == seeders)&&(identical(other.leechers, leechers) || other.leechers == leechers)&&(identical(other.size, size) || other.size == size)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.sourceSite, sourceSite) || other.sourceSite == sourceSite)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.isCached, isCached) || other.isCached == isCached)&&(identical(other.matchScore, matchScore) || other.matchScore == matchScore)&&(identical(other.uploader, uploader) || other.uploader == uploader)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,hash,magnet,seeders,leechers,size,sizeBytes,sourceSite,quality,isCached,matchScore,uploader,date);

@override
String toString() {
  return 'TorrentResult(name: $name, hash: $hash, magnet: $magnet, seeders: $seeders, leechers: $leechers, size: $size, sizeBytes: $sizeBytes, sourceSite: $sourceSite, quality: $quality, isCached: $isCached, matchScore: $matchScore, uploader: $uploader, date: $date)';
}


}

/// @nodoc
abstract mixin class _$TorrentResultCopyWith<$Res> implements $TorrentResultCopyWith<$Res> {
  factory _$TorrentResultCopyWith(_TorrentResult value, $Res Function(_TorrentResult) _then) = __$TorrentResultCopyWithImpl;
@override @useResult
$Res call({
 String name, String hash, String magnet, int seeders, int leechers, String size, int sizeBytes, String sourceSite, String quality, bool isCached, double matchScore, String uploader, String date
});




}
/// @nodoc
class __$TorrentResultCopyWithImpl<$Res>
    implements _$TorrentResultCopyWith<$Res> {
  __$TorrentResultCopyWithImpl(this._self, this._then);

  final _TorrentResult _self;
  final $Res Function(_TorrentResult) _then;

/// Create a copy of TorrentResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? hash = null,Object? magnet = null,Object? seeders = null,Object? leechers = null,Object? size = null,Object? sizeBytes = null,Object? sourceSite = null,Object? quality = null,Object? isCached = null,Object? matchScore = null,Object? uploader = null,Object? date = null,}) {
  return _then(_TorrentResult(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,magnet: null == magnet ? _self.magnet : magnet // ignore: cast_nullable_to_non_nullable
as String,seeders: null == seeders ? _self.seeders : seeders // ignore: cast_nullable_to_non_nullable
as int,leechers: null == leechers ? _self.leechers : leechers // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sourceSite: null == sourceSite ? _self.sourceSite : sourceSite // ignore: cast_nullable_to_non_nullable
as String,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as String,isCached: null == isCached ? _self.isCached : isCached // ignore: cast_nullable_to_non_nullable
as bool,matchScore: null == matchScore ? _self.matchScore : matchScore // ignore: cast_nullable_to_non_nullable
as double,uploader: null == uploader ? _self.uploader : uploader // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TorrentSearchResponse {

 List<TorrentResult> get filtered; List<TorrentResult> get unfiltered; String get query; String get mediaType;
/// Create a copy of TorrentSearchResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TorrentSearchResponseCopyWith<TorrentSearchResponse> get copyWith => _$TorrentSearchResponseCopyWithImpl<TorrentSearchResponse>(this as TorrentSearchResponse, _$identity);

  /// Serializes this TorrentSearchResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TorrentSearchResponse&&const DeepCollectionEquality().equals(other.filtered, filtered)&&const DeepCollectionEquality().equals(other.unfiltered, unfiltered)&&(identical(other.query, query) || other.query == query)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(filtered),const DeepCollectionEquality().hash(unfiltered),query,mediaType);

@override
String toString() {
  return 'TorrentSearchResponse(filtered: $filtered, unfiltered: $unfiltered, query: $query, mediaType: $mediaType)';
}


}

/// @nodoc
abstract mixin class $TorrentSearchResponseCopyWith<$Res>  {
  factory $TorrentSearchResponseCopyWith(TorrentSearchResponse value, $Res Function(TorrentSearchResponse) _then) = _$TorrentSearchResponseCopyWithImpl;
@useResult
$Res call({
 List<TorrentResult> filtered, List<TorrentResult> unfiltered, String query, String mediaType
});




}
/// @nodoc
class _$TorrentSearchResponseCopyWithImpl<$Res>
    implements $TorrentSearchResponseCopyWith<$Res> {
  _$TorrentSearchResponseCopyWithImpl(this._self, this._then);

  final TorrentSearchResponse _self;
  final $Res Function(TorrentSearchResponse) _then;

/// Create a copy of TorrentSearchResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? filtered = null,Object? unfiltered = null,Object? query = null,Object? mediaType = null,}) {
  return _then(_self.copyWith(
filtered: null == filtered ? _self.filtered : filtered // ignore: cast_nullable_to_non_nullable
as List<TorrentResult>,unfiltered: null == unfiltered ? _self.unfiltered : unfiltered // ignore: cast_nullable_to_non_nullable
as List<TorrentResult>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TorrentSearchResponse].
extension TorrentSearchResponsePatterns on TorrentSearchResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TorrentSearchResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TorrentSearchResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TorrentSearchResponse value)  $default,){
final _that = this;
switch (_that) {
case _TorrentSearchResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TorrentSearchResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TorrentSearchResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TorrentResult> filtered,  List<TorrentResult> unfiltered,  String query,  String mediaType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TorrentSearchResponse() when $default != null:
return $default(_that.filtered,_that.unfiltered,_that.query,_that.mediaType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TorrentResult> filtered,  List<TorrentResult> unfiltered,  String query,  String mediaType)  $default,) {final _that = this;
switch (_that) {
case _TorrentSearchResponse():
return $default(_that.filtered,_that.unfiltered,_that.query,_that.mediaType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TorrentResult> filtered,  List<TorrentResult> unfiltered,  String query,  String mediaType)?  $default,) {final _that = this;
switch (_that) {
case _TorrentSearchResponse() when $default != null:
return $default(_that.filtered,_that.unfiltered,_that.query,_that.mediaType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TorrentSearchResponse implements TorrentSearchResponse {
  const _TorrentSearchResponse({required final  List<TorrentResult> filtered, required final  List<TorrentResult> unfiltered, required this.query, required this.mediaType}): _filtered = filtered,_unfiltered = unfiltered;
  factory _TorrentSearchResponse.fromJson(Map<String, dynamic> json) => _$TorrentSearchResponseFromJson(json);

 final  List<TorrentResult> _filtered;
@override List<TorrentResult> get filtered {
  if (_filtered is EqualUnmodifiableListView) return _filtered;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_filtered);
}

 final  List<TorrentResult> _unfiltered;
@override List<TorrentResult> get unfiltered {
  if (_unfiltered is EqualUnmodifiableListView) return _unfiltered;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unfiltered);
}

@override final  String query;
@override final  String mediaType;

/// Create a copy of TorrentSearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TorrentSearchResponseCopyWith<_TorrentSearchResponse> get copyWith => __$TorrentSearchResponseCopyWithImpl<_TorrentSearchResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TorrentSearchResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TorrentSearchResponse&&const DeepCollectionEquality().equals(other._filtered, _filtered)&&const DeepCollectionEquality().equals(other._unfiltered, _unfiltered)&&(identical(other.query, query) || other.query == query)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_filtered),const DeepCollectionEquality().hash(_unfiltered),query,mediaType);

@override
String toString() {
  return 'TorrentSearchResponse(filtered: $filtered, unfiltered: $unfiltered, query: $query, mediaType: $mediaType)';
}


}

/// @nodoc
abstract mixin class _$TorrentSearchResponseCopyWith<$Res> implements $TorrentSearchResponseCopyWith<$Res> {
  factory _$TorrentSearchResponseCopyWith(_TorrentSearchResponse value, $Res Function(_TorrentSearchResponse) _then) = __$TorrentSearchResponseCopyWithImpl;
@override @useResult
$Res call({
 List<TorrentResult> filtered, List<TorrentResult> unfiltered, String query, String mediaType
});




}
/// @nodoc
class __$TorrentSearchResponseCopyWithImpl<$Res>
    implements _$TorrentSearchResponseCopyWith<$Res> {
  __$TorrentSearchResponseCopyWithImpl(this._self, this._then);

  final _TorrentSearchResponse _self;
  final $Res Function(_TorrentSearchResponse) _then;

/// Create a copy of TorrentSearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? filtered = null,Object? unfiltered = null,Object? query = null,Object? mediaType = null,}) {
  return _then(_TorrentSearchResponse(
filtered: null == filtered ? _self._filtered : filtered // ignore: cast_nullable_to_non_nullable
as List<TorrentResult>,unfiltered: null == unfiltered ? _self._unfiltered : unfiltered // ignore: cast_nullable_to_non_nullable
as List<TorrentResult>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TorrentStatus {

 String get torrentId; String get name; String get status; double get progress; double get speed; int get seeders; int get linksCount; String get title; String get mediaType; int? get season; int? get episode; double get elapsedSeconds; String get message;
/// Create a copy of TorrentStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TorrentStatusCopyWith<TorrentStatus> get copyWith => _$TorrentStatusCopyWithImpl<TorrentStatus>(this as TorrentStatus, _$identity);

  /// Serializes this TorrentStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TorrentStatus&&(identical(other.torrentId, torrentId) || other.torrentId == torrentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.seeders, seeders) || other.seeders == seeders)&&(identical(other.linksCount, linksCount) || other.linksCount == linksCount)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.season, season) || other.season == season)&&(identical(other.episode, episode) || other.episode == episode)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,torrentId,name,status,progress,speed,seeders,linksCount,title,mediaType,season,episode,elapsedSeconds,message);

@override
String toString() {
  return 'TorrentStatus(torrentId: $torrentId, name: $name, status: $status, progress: $progress, speed: $speed, seeders: $seeders, linksCount: $linksCount, title: $title, mediaType: $mediaType, season: $season, episode: $episode, elapsedSeconds: $elapsedSeconds, message: $message)';
}


}

/// @nodoc
abstract mixin class $TorrentStatusCopyWith<$Res>  {
  factory $TorrentStatusCopyWith(TorrentStatus value, $Res Function(TorrentStatus) _then) = _$TorrentStatusCopyWithImpl;
@useResult
$Res call({
 String torrentId, String name, String status, double progress, double speed, int seeders, int linksCount, String title, String mediaType, int? season, int? episode, double elapsedSeconds, String message
});




}
/// @nodoc
class _$TorrentStatusCopyWithImpl<$Res>
    implements $TorrentStatusCopyWith<$Res> {
  _$TorrentStatusCopyWithImpl(this._self, this._then);

  final TorrentStatus _self;
  final $Res Function(TorrentStatus) _then;

/// Create a copy of TorrentStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? torrentId = null,Object? name = null,Object? status = null,Object? progress = null,Object? speed = null,Object? seeders = null,Object? linksCount = null,Object? title = null,Object? mediaType = null,Object? season = freezed,Object? episode = freezed,Object? elapsedSeconds = null,Object? message = null,}) {
  return _then(_self.copyWith(
torrentId: null == torrentId ? _self.torrentId : torrentId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,seeders: null == seeders ? _self.seeders : seeders // ignore: cast_nullable_to_non_nullable
as int,linksCount: null == linksCount ? _self.linksCount : linksCount // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as int?,episode: freezed == episode ? _self.episode : episode // ignore: cast_nullable_to_non_nullable
as int?,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as double,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TorrentStatus].
extension TorrentStatusPatterns on TorrentStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TorrentStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TorrentStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TorrentStatus value)  $default,){
final _that = this;
switch (_that) {
case _TorrentStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TorrentStatus value)?  $default,){
final _that = this;
switch (_that) {
case _TorrentStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String torrentId,  String name,  String status,  double progress,  double speed,  int seeders,  int linksCount,  String title,  String mediaType,  int? season,  int? episode,  double elapsedSeconds,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TorrentStatus() when $default != null:
return $default(_that.torrentId,_that.name,_that.status,_that.progress,_that.speed,_that.seeders,_that.linksCount,_that.title,_that.mediaType,_that.season,_that.episode,_that.elapsedSeconds,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String torrentId,  String name,  String status,  double progress,  double speed,  int seeders,  int linksCount,  String title,  String mediaType,  int? season,  int? episode,  double elapsedSeconds,  String message)  $default,) {final _that = this;
switch (_that) {
case _TorrentStatus():
return $default(_that.torrentId,_that.name,_that.status,_that.progress,_that.speed,_that.seeders,_that.linksCount,_that.title,_that.mediaType,_that.season,_that.episode,_that.elapsedSeconds,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String torrentId,  String name,  String status,  double progress,  double speed,  int seeders,  int linksCount,  String title,  String mediaType,  int? season,  int? episode,  double elapsedSeconds,  String message)?  $default,) {final _that = this;
switch (_that) {
case _TorrentStatus() when $default != null:
return $default(_that.torrentId,_that.name,_that.status,_that.progress,_that.speed,_that.seeders,_that.linksCount,_that.title,_that.mediaType,_that.season,_that.episode,_that.elapsedSeconds,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TorrentStatus implements TorrentStatus {
  const _TorrentStatus({required this.torrentId, required this.name, required this.status, required this.progress, required this.speed, required this.seeders, required this.linksCount, required this.title, required this.mediaType, this.season, this.episode, required this.elapsedSeconds, required this.message});
  factory _TorrentStatus.fromJson(Map<String, dynamic> json) => _$TorrentStatusFromJson(json);

@override final  String torrentId;
@override final  String name;
@override final  String status;
@override final  double progress;
@override final  double speed;
@override final  int seeders;
@override final  int linksCount;
@override final  String title;
@override final  String mediaType;
@override final  int? season;
@override final  int? episode;
@override final  double elapsedSeconds;
@override final  String message;

/// Create a copy of TorrentStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TorrentStatusCopyWith<_TorrentStatus> get copyWith => __$TorrentStatusCopyWithImpl<_TorrentStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TorrentStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TorrentStatus&&(identical(other.torrentId, torrentId) || other.torrentId == torrentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.seeders, seeders) || other.seeders == seeders)&&(identical(other.linksCount, linksCount) || other.linksCount == linksCount)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.season, season) || other.season == season)&&(identical(other.episode, episode) || other.episode == episode)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,torrentId,name,status,progress,speed,seeders,linksCount,title,mediaType,season,episode,elapsedSeconds,message);

@override
String toString() {
  return 'TorrentStatus(torrentId: $torrentId, name: $name, status: $status, progress: $progress, speed: $speed, seeders: $seeders, linksCount: $linksCount, title: $title, mediaType: $mediaType, season: $season, episode: $episode, elapsedSeconds: $elapsedSeconds, message: $message)';
}


}

/// @nodoc
abstract mixin class _$TorrentStatusCopyWith<$Res> implements $TorrentStatusCopyWith<$Res> {
  factory _$TorrentStatusCopyWith(_TorrentStatus value, $Res Function(_TorrentStatus) _then) = __$TorrentStatusCopyWithImpl;
@override @useResult
$Res call({
 String torrentId, String name, String status, double progress, double speed, int seeders, int linksCount, String title, String mediaType, int? season, int? episode, double elapsedSeconds, String message
});




}
/// @nodoc
class __$TorrentStatusCopyWithImpl<$Res>
    implements _$TorrentStatusCopyWith<$Res> {
  __$TorrentStatusCopyWithImpl(this._self, this._then);

  final _TorrentStatus _self;
  final $Res Function(_TorrentStatus) _then;

/// Create a copy of TorrentStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? torrentId = null,Object? name = null,Object? status = null,Object? progress = null,Object? speed = null,Object? seeders = null,Object? linksCount = null,Object? title = null,Object? mediaType = null,Object? season = freezed,Object? episode = freezed,Object? elapsedSeconds = null,Object? message = null,}) {
  return _then(_TorrentStatus(
torrentId: null == torrentId ? _self.torrentId : torrentId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,seeders: null == seeders ? _self.seeders : seeders // ignore: cast_nullable_to_non_nullable
as int,linksCount: null == linksCount ? _self.linksCount : linksCount // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as int?,episode: freezed == episode ? _self.episode : episode // ignore: cast_nullable_to_non_nullable
as int?,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as double,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TorrentResolveResponse {

 String get torrentId; String get status; String? get selectedFile; String get message;
/// Create a copy of TorrentResolveResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TorrentResolveResponseCopyWith<TorrentResolveResponse> get copyWith => _$TorrentResolveResponseCopyWithImpl<TorrentResolveResponse>(this as TorrentResolveResponse, _$identity);

  /// Serializes this TorrentResolveResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TorrentResolveResponse&&(identical(other.torrentId, torrentId) || other.torrentId == torrentId)&&(identical(other.status, status) || other.status == status)&&(identical(other.selectedFile, selectedFile) || other.selectedFile == selectedFile)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,torrentId,status,selectedFile,message);

@override
String toString() {
  return 'TorrentResolveResponse(torrentId: $torrentId, status: $status, selectedFile: $selectedFile, message: $message)';
}


}

/// @nodoc
abstract mixin class $TorrentResolveResponseCopyWith<$Res>  {
  factory $TorrentResolveResponseCopyWith(TorrentResolveResponse value, $Res Function(TorrentResolveResponse) _then) = _$TorrentResolveResponseCopyWithImpl;
@useResult
$Res call({
 String torrentId, String status, String? selectedFile, String message
});




}
/// @nodoc
class _$TorrentResolveResponseCopyWithImpl<$Res>
    implements $TorrentResolveResponseCopyWith<$Res> {
  _$TorrentResolveResponseCopyWithImpl(this._self, this._then);

  final TorrentResolveResponse _self;
  final $Res Function(TorrentResolveResponse) _then;

/// Create a copy of TorrentResolveResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? torrentId = null,Object? status = null,Object? selectedFile = freezed,Object? message = null,}) {
  return _then(_self.copyWith(
torrentId: null == torrentId ? _self.torrentId : torrentId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,selectedFile: freezed == selectedFile ? _self.selectedFile : selectedFile // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TorrentResolveResponse].
extension TorrentResolveResponsePatterns on TorrentResolveResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TorrentResolveResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TorrentResolveResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TorrentResolveResponse value)  $default,){
final _that = this;
switch (_that) {
case _TorrentResolveResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TorrentResolveResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TorrentResolveResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String torrentId,  String status,  String? selectedFile,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TorrentResolveResponse() when $default != null:
return $default(_that.torrentId,_that.status,_that.selectedFile,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String torrentId,  String status,  String? selectedFile,  String message)  $default,) {final _that = this;
switch (_that) {
case _TorrentResolveResponse():
return $default(_that.torrentId,_that.status,_that.selectedFile,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String torrentId,  String status,  String? selectedFile,  String message)?  $default,) {final _that = this;
switch (_that) {
case _TorrentResolveResponse() when $default != null:
return $default(_that.torrentId,_that.status,_that.selectedFile,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TorrentResolveResponse implements TorrentResolveResponse {
  const _TorrentResolveResponse({required this.torrentId, required this.status, this.selectedFile, required this.message});
  factory _TorrentResolveResponse.fromJson(Map<String, dynamic> json) => _$TorrentResolveResponseFromJson(json);

@override final  String torrentId;
@override final  String status;
@override final  String? selectedFile;
@override final  String message;

/// Create a copy of TorrentResolveResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TorrentResolveResponseCopyWith<_TorrentResolveResponse> get copyWith => __$TorrentResolveResponseCopyWithImpl<_TorrentResolveResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TorrentResolveResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TorrentResolveResponse&&(identical(other.torrentId, torrentId) || other.torrentId == torrentId)&&(identical(other.status, status) || other.status == status)&&(identical(other.selectedFile, selectedFile) || other.selectedFile == selectedFile)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,torrentId,status,selectedFile,message);

@override
String toString() {
  return 'TorrentResolveResponse(torrentId: $torrentId, status: $status, selectedFile: $selectedFile, message: $message)';
}


}

/// @nodoc
abstract mixin class _$TorrentResolveResponseCopyWith<$Res> implements $TorrentResolveResponseCopyWith<$Res> {
  factory _$TorrentResolveResponseCopyWith(_TorrentResolveResponse value, $Res Function(_TorrentResolveResponse) _then) = __$TorrentResolveResponseCopyWithImpl;
@override @useResult
$Res call({
 String torrentId, String status, String? selectedFile, String message
});




}
/// @nodoc
class __$TorrentResolveResponseCopyWithImpl<$Res>
    implements _$TorrentResolveResponseCopyWith<$Res> {
  __$TorrentResolveResponseCopyWithImpl(this._self, this._then);

  final _TorrentResolveResponse _self;
  final $Res Function(_TorrentResolveResponse) _then;

/// Create a copy of TorrentResolveResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? torrentId = null,Object? status = null,Object? selectedFile = freezed,Object? message = null,}) {
  return _then(_TorrentResolveResponse(
torrentId: null == torrentId ? _self.torrentId : torrentId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,selectedFile: freezed == selectedFile ? _self.selectedFile : selectedFile // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
