// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaCredits {

 List<CastMember> get cast; List<dynamic> get crew;
/// Create a copy of MediaCredits
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaCreditsCopyWith<MediaCredits> get copyWith => _$MediaCreditsCopyWithImpl<MediaCredits>(this as MediaCredits, _$identity);

  /// Serializes this MediaCredits to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaCredits&&const DeepCollectionEquality().equals(other.cast, cast)&&const DeepCollectionEquality().equals(other.crew, crew));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(cast),const DeepCollectionEquality().hash(crew));

@override
String toString() {
  return 'MediaCredits(cast: $cast, crew: $crew)';
}


}

/// @nodoc
abstract mixin class $MediaCreditsCopyWith<$Res>  {
  factory $MediaCreditsCopyWith(MediaCredits value, $Res Function(MediaCredits) _then) = _$MediaCreditsCopyWithImpl;
@useResult
$Res call({
 List<CastMember> cast, List<dynamic> crew
});




}
/// @nodoc
class _$MediaCreditsCopyWithImpl<$Res>
    implements $MediaCreditsCopyWith<$Res> {
  _$MediaCreditsCopyWithImpl(this._self, this._then);

  final MediaCredits _self;
  final $Res Function(MediaCredits) _then;

/// Create a copy of MediaCredits
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cast = null,Object? crew = null,}) {
  return _then(_self.copyWith(
cast: null == cast ? _self.cast : cast // ignore: cast_nullable_to_non_nullable
as List<CastMember>,crew: null == crew ? _self.crew : crew // ignore: cast_nullable_to_non_nullable
as List<dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaCredits].
extension MediaCreditsPatterns on MediaCredits {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaCredits value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaCredits() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaCredits value)  $default,){
final _that = this;
switch (_that) {
case _MediaCredits():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaCredits value)?  $default,){
final _that = this;
switch (_that) {
case _MediaCredits() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CastMember> cast,  List<dynamic> crew)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaCredits() when $default != null:
return $default(_that.cast,_that.crew);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CastMember> cast,  List<dynamic> crew)  $default,) {final _that = this;
switch (_that) {
case _MediaCredits():
return $default(_that.cast,_that.crew);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CastMember> cast,  List<dynamic> crew)?  $default,) {final _that = this;
switch (_that) {
case _MediaCredits() when $default != null:
return $default(_that.cast,_that.crew);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaCredits implements MediaCredits {
  const _MediaCredits({final  List<CastMember> cast = const [], final  List<dynamic> crew = const []}): _cast = cast,_crew = crew;
  factory _MediaCredits.fromJson(Map<String, dynamic> json) => _$MediaCreditsFromJson(json);

 final  List<CastMember> _cast;
@override@JsonKey() List<CastMember> get cast {
  if (_cast is EqualUnmodifiableListView) return _cast;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cast);
}

 final  List<dynamic> _crew;
@override@JsonKey() List<dynamic> get crew {
  if (_crew is EqualUnmodifiableListView) return _crew;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_crew);
}


/// Create a copy of MediaCredits
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaCreditsCopyWith<_MediaCredits> get copyWith => __$MediaCreditsCopyWithImpl<_MediaCredits>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaCreditsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaCredits&&const DeepCollectionEquality().equals(other._cast, _cast)&&const DeepCollectionEquality().equals(other._crew, _crew));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_cast),const DeepCollectionEquality().hash(_crew));

@override
String toString() {
  return 'MediaCredits(cast: $cast, crew: $crew)';
}


}

/// @nodoc
abstract mixin class _$MediaCreditsCopyWith<$Res> implements $MediaCreditsCopyWith<$Res> {
  factory _$MediaCreditsCopyWith(_MediaCredits value, $Res Function(_MediaCredits) _then) = __$MediaCreditsCopyWithImpl;
@override @useResult
$Res call({
 List<CastMember> cast, List<dynamic> crew
});




}
/// @nodoc
class __$MediaCreditsCopyWithImpl<$Res>
    implements _$MediaCreditsCopyWith<$Res> {
  __$MediaCreditsCopyWithImpl(this._self, this._then);

  final _MediaCredits _self;
  final $Res Function(_MediaCredits) _then;

/// Create a copy of MediaCredits
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cast = null,Object? crew = null,}) {
  return _then(_MediaCredits(
cast: null == cast ? _self._cast : cast // ignore: cast_nullable_to_non_nullable
as List<CastMember>,crew: null == crew ? _self._crew : crew // ignore: cast_nullable_to_non_nullable
as List<dynamic>,
  ));
}


}


/// @nodoc
mixin _$EpisodeDetail {

 String get id; String get title; int? get seasonNumber; int? get episodeNumber; String? get overview; String? get airDate; int? get runtimeMinutes; ImageAsset? get poster; ImageAsset? get stillFrame; double? get voteAverage;
/// Create a copy of EpisodeDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpisodeDetailCopyWith<EpisodeDetail> get copyWith => _$EpisodeDetailCopyWithImpl<EpisodeDetail>(this as EpisodeDetail, _$identity);

  /// Serializes this EpisodeDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EpisodeDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.seasonNumber, seasonNumber) || other.seasonNumber == seasonNumber)&&(identical(other.episodeNumber, episodeNumber) || other.episodeNumber == episodeNumber)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.airDate, airDate) || other.airDate == airDate)&&(identical(other.runtimeMinutes, runtimeMinutes) || other.runtimeMinutes == runtimeMinutes)&&(identical(other.poster, poster) || other.poster == poster)&&(identical(other.stillFrame, stillFrame) || other.stillFrame == stillFrame)&&(identical(other.voteAverage, voteAverage) || other.voteAverage == voteAverage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,seasonNumber,episodeNumber,overview,airDate,runtimeMinutes,poster,stillFrame,voteAverage);

@override
String toString() {
  return 'EpisodeDetail(id: $id, title: $title, seasonNumber: $seasonNumber, episodeNumber: $episodeNumber, overview: $overview, airDate: $airDate, runtimeMinutes: $runtimeMinutes, poster: $poster, stillFrame: $stillFrame, voteAverage: $voteAverage)';
}


}

/// @nodoc
abstract mixin class $EpisodeDetailCopyWith<$Res>  {
  factory $EpisodeDetailCopyWith(EpisodeDetail value, $Res Function(EpisodeDetail) _then) = _$EpisodeDetailCopyWithImpl;
@useResult
$Res call({
 String id, String title, int? seasonNumber, int? episodeNumber, String? overview, String? airDate, int? runtimeMinutes, ImageAsset? poster, ImageAsset? stillFrame, double? voteAverage
});


$ImageAssetCopyWith<$Res>? get poster;$ImageAssetCopyWith<$Res>? get stillFrame;

}
/// @nodoc
class _$EpisodeDetailCopyWithImpl<$Res>
    implements $EpisodeDetailCopyWith<$Res> {
  _$EpisodeDetailCopyWithImpl(this._self, this._then);

  final EpisodeDetail _self;
  final $Res Function(EpisodeDetail) _then;

/// Create a copy of EpisodeDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? seasonNumber = freezed,Object? episodeNumber = freezed,Object? overview = freezed,Object? airDate = freezed,Object? runtimeMinutes = freezed,Object? poster = freezed,Object? stillFrame = freezed,Object? voteAverage = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,seasonNumber: freezed == seasonNumber ? _self.seasonNumber : seasonNumber // ignore: cast_nullable_to_non_nullable
as int?,episodeNumber: freezed == episodeNumber ? _self.episodeNumber : episodeNumber // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,airDate: freezed == airDate ? _self.airDate : airDate // ignore: cast_nullable_to_non_nullable
as String?,runtimeMinutes: freezed == runtimeMinutes ? _self.runtimeMinutes : runtimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,poster: freezed == poster ? _self.poster : poster // ignore: cast_nullable_to_non_nullable
as ImageAsset?,stillFrame: freezed == stillFrame ? _self.stillFrame : stillFrame // ignore: cast_nullable_to_non_nullable
as ImageAsset?,voteAverage: freezed == voteAverage ? _self.voteAverage : voteAverage // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of EpisodeDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get poster {
    if (_self.poster == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.poster!, (value) {
    return _then(_self.copyWith(poster: value));
  });
}/// Create a copy of EpisodeDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get stillFrame {
    if (_self.stillFrame == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.stillFrame!, (value) {
    return _then(_self.copyWith(stillFrame: value));
  });
}
}


/// Adds pattern-matching-related methods to [EpisodeDetail].
extension EpisodeDetailPatterns on EpisodeDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EpisodeDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EpisodeDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EpisodeDetail value)  $default,){
final _that = this;
switch (_that) {
case _EpisodeDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EpisodeDetail value)?  $default,){
final _that = this;
switch (_that) {
case _EpisodeDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  int? seasonNumber,  int? episodeNumber,  String? overview,  String? airDate,  int? runtimeMinutes,  ImageAsset? poster,  ImageAsset? stillFrame,  double? voteAverage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EpisodeDetail() when $default != null:
return $default(_that.id,_that.title,_that.seasonNumber,_that.episodeNumber,_that.overview,_that.airDate,_that.runtimeMinutes,_that.poster,_that.stillFrame,_that.voteAverage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  int? seasonNumber,  int? episodeNumber,  String? overview,  String? airDate,  int? runtimeMinutes,  ImageAsset? poster,  ImageAsset? stillFrame,  double? voteAverage)  $default,) {final _that = this;
switch (_that) {
case _EpisodeDetail():
return $default(_that.id,_that.title,_that.seasonNumber,_that.episodeNumber,_that.overview,_that.airDate,_that.runtimeMinutes,_that.poster,_that.stillFrame,_that.voteAverage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  int? seasonNumber,  int? episodeNumber,  String? overview,  String? airDate,  int? runtimeMinutes,  ImageAsset? poster,  ImageAsset? stillFrame,  double? voteAverage)?  $default,) {final _that = this;
switch (_that) {
case _EpisodeDetail() when $default != null:
return $default(_that.id,_that.title,_that.seasonNumber,_that.episodeNumber,_that.overview,_that.airDate,_that.runtimeMinutes,_that.poster,_that.stillFrame,_that.voteAverage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EpisodeDetail implements EpisodeDetail {
  const _EpisodeDetail({required this.id, required this.title, this.seasonNumber, this.episodeNumber, this.overview, this.airDate, this.runtimeMinutes, this.poster, this.stillFrame, this.voteAverage});
  factory _EpisodeDetail.fromJson(Map<String, dynamic> json) => _$EpisodeDetailFromJson(json);

@override final  String id;
@override final  String title;
@override final  int? seasonNumber;
@override final  int? episodeNumber;
@override final  String? overview;
@override final  String? airDate;
@override final  int? runtimeMinutes;
@override final  ImageAsset? poster;
@override final  ImageAsset? stillFrame;
@override final  double? voteAverage;

/// Create a copy of EpisodeDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EpisodeDetailCopyWith<_EpisodeDetail> get copyWith => __$EpisodeDetailCopyWithImpl<_EpisodeDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EpisodeDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EpisodeDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.seasonNumber, seasonNumber) || other.seasonNumber == seasonNumber)&&(identical(other.episodeNumber, episodeNumber) || other.episodeNumber == episodeNumber)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.airDate, airDate) || other.airDate == airDate)&&(identical(other.runtimeMinutes, runtimeMinutes) || other.runtimeMinutes == runtimeMinutes)&&(identical(other.poster, poster) || other.poster == poster)&&(identical(other.stillFrame, stillFrame) || other.stillFrame == stillFrame)&&(identical(other.voteAverage, voteAverage) || other.voteAverage == voteAverage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,seasonNumber,episodeNumber,overview,airDate,runtimeMinutes,poster,stillFrame,voteAverage);

@override
String toString() {
  return 'EpisodeDetail(id: $id, title: $title, seasonNumber: $seasonNumber, episodeNumber: $episodeNumber, overview: $overview, airDate: $airDate, runtimeMinutes: $runtimeMinutes, poster: $poster, stillFrame: $stillFrame, voteAverage: $voteAverage)';
}


}

/// @nodoc
abstract mixin class _$EpisodeDetailCopyWith<$Res> implements $EpisodeDetailCopyWith<$Res> {
  factory _$EpisodeDetailCopyWith(_EpisodeDetail value, $Res Function(_EpisodeDetail) _then) = __$EpisodeDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, int? seasonNumber, int? episodeNumber, String? overview, String? airDate, int? runtimeMinutes, ImageAsset? poster, ImageAsset? stillFrame, double? voteAverage
});


@override $ImageAssetCopyWith<$Res>? get poster;@override $ImageAssetCopyWith<$Res>? get stillFrame;

}
/// @nodoc
class __$EpisodeDetailCopyWithImpl<$Res>
    implements _$EpisodeDetailCopyWith<$Res> {
  __$EpisodeDetailCopyWithImpl(this._self, this._then);

  final _EpisodeDetail _self;
  final $Res Function(_EpisodeDetail) _then;

/// Create a copy of EpisodeDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? seasonNumber = freezed,Object? episodeNumber = freezed,Object? overview = freezed,Object? airDate = freezed,Object? runtimeMinutes = freezed,Object? poster = freezed,Object? stillFrame = freezed,Object? voteAverage = freezed,}) {
  return _then(_EpisodeDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,seasonNumber: freezed == seasonNumber ? _self.seasonNumber : seasonNumber // ignore: cast_nullable_to_non_nullable
as int?,episodeNumber: freezed == episodeNumber ? _self.episodeNumber : episodeNumber // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,airDate: freezed == airDate ? _self.airDate : airDate // ignore: cast_nullable_to_non_nullable
as String?,runtimeMinutes: freezed == runtimeMinutes ? _self.runtimeMinutes : runtimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,poster: freezed == poster ? _self.poster : poster // ignore: cast_nullable_to_non_nullable
as ImageAsset?,stillFrame: freezed == stillFrame ? _self.stillFrame : stillFrame // ignore: cast_nullable_to_non_nullable
as ImageAsset?,voteAverage: freezed == voteAverage ? _self.voteAverage : voteAverage // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of EpisodeDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get poster {
    if (_self.poster == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.poster!, (value) {
    return _then(_self.copyWith(poster: value));
  });
}/// Create a copy of EpisodeDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get stillFrame {
    if (_self.stillFrame == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.stillFrame!, (value) {
    return _then(_self.copyWith(stillFrame: value));
  });
}
}


/// @nodoc
mixin _$SeasonDetail {

 int get seasonNumber; int? get episodeCount; String? get title; String? get overview; ImageAsset? get poster; List<EpisodeDetail>? get episodes;
/// Create a copy of SeasonDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeasonDetailCopyWith<SeasonDetail> get copyWith => _$SeasonDetailCopyWithImpl<SeasonDetail>(this as SeasonDetail, _$identity);

  /// Serializes this SeasonDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeasonDetail&&(identical(other.seasonNumber, seasonNumber) || other.seasonNumber == seasonNumber)&&(identical(other.episodeCount, episodeCount) || other.episodeCount == episodeCount)&&(identical(other.title, title) || other.title == title)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.poster, poster) || other.poster == poster)&&const DeepCollectionEquality().equals(other.episodes, episodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seasonNumber,episodeCount,title,overview,poster,const DeepCollectionEquality().hash(episodes));

@override
String toString() {
  return 'SeasonDetail(seasonNumber: $seasonNumber, episodeCount: $episodeCount, title: $title, overview: $overview, poster: $poster, episodes: $episodes)';
}


}

/// @nodoc
abstract mixin class $SeasonDetailCopyWith<$Res>  {
  factory $SeasonDetailCopyWith(SeasonDetail value, $Res Function(SeasonDetail) _then) = _$SeasonDetailCopyWithImpl;
@useResult
$Res call({
 int seasonNumber, int? episodeCount, String? title, String? overview, ImageAsset? poster, List<EpisodeDetail>? episodes
});


$ImageAssetCopyWith<$Res>? get poster;

}
/// @nodoc
class _$SeasonDetailCopyWithImpl<$Res>
    implements $SeasonDetailCopyWith<$Res> {
  _$SeasonDetailCopyWithImpl(this._self, this._then);

  final SeasonDetail _self;
  final $Res Function(SeasonDetail) _then;

/// Create a copy of SeasonDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seasonNumber = null,Object? episodeCount = freezed,Object? title = freezed,Object? overview = freezed,Object? poster = freezed,Object? episodes = freezed,}) {
  return _then(_self.copyWith(
seasonNumber: null == seasonNumber ? _self.seasonNumber : seasonNumber // ignore: cast_nullable_to_non_nullable
as int,episodeCount: freezed == episodeCount ? _self.episodeCount : episodeCount // ignore: cast_nullable_to_non_nullable
as int?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,poster: freezed == poster ? _self.poster : poster // ignore: cast_nullable_to_non_nullable
as ImageAsset?,episodes: freezed == episodes ? _self.episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<EpisodeDetail>?,
  ));
}
/// Create a copy of SeasonDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get poster {
    if (_self.poster == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.poster!, (value) {
    return _then(_self.copyWith(poster: value));
  });
}
}


/// Adds pattern-matching-related methods to [SeasonDetail].
extension SeasonDetailPatterns on SeasonDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeasonDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeasonDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeasonDetail value)  $default,){
final _that = this;
switch (_that) {
case _SeasonDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeasonDetail value)?  $default,){
final _that = this;
switch (_that) {
case _SeasonDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int seasonNumber,  int? episodeCount,  String? title,  String? overview,  ImageAsset? poster,  List<EpisodeDetail>? episodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeasonDetail() when $default != null:
return $default(_that.seasonNumber,_that.episodeCount,_that.title,_that.overview,_that.poster,_that.episodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int seasonNumber,  int? episodeCount,  String? title,  String? overview,  ImageAsset? poster,  List<EpisodeDetail>? episodes)  $default,) {final _that = this;
switch (_that) {
case _SeasonDetail():
return $default(_that.seasonNumber,_that.episodeCount,_that.title,_that.overview,_that.poster,_that.episodes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int seasonNumber,  int? episodeCount,  String? title,  String? overview,  ImageAsset? poster,  List<EpisodeDetail>? episodes)?  $default,) {final _that = this;
switch (_that) {
case _SeasonDetail() when $default != null:
return $default(_that.seasonNumber,_that.episodeCount,_that.title,_that.overview,_that.poster,_that.episodes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeasonDetail implements SeasonDetail {
  const _SeasonDetail({required this.seasonNumber, this.episodeCount, this.title, this.overview, this.poster, final  List<EpisodeDetail>? episodes}): _episodes = episodes;
  factory _SeasonDetail.fromJson(Map<String, dynamic> json) => _$SeasonDetailFromJson(json);

@override final  int seasonNumber;
@override final  int? episodeCount;
@override final  String? title;
@override final  String? overview;
@override final  ImageAsset? poster;
 final  List<EpisodeDetail>? _episodes;
@override List<EpisodeDetail>? get episodes {
  final value = _episodes;
  if (value == null) return null;
  if (_episodes is EqualUnmodifiableListView) return _episodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of SeasonDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeasonDetailCopyWith<_SeasonDetail> get copyWith => __$SeasonDetailCopyWithImpl<_SeasonDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeasonDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeasonDetail&&(identical(other.seasonNumber, seasonNumber) || other.seasonNumber == seasonNumber)&&(identical(other.episodeCount, episodeCount) || other.episodeCount == episodeCount)&&(identical(other.title, title) || other.title == title)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.poster, poster) || other.poster == poster)&&const DeepCollectionEquality().equals(other._episodes, _episodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,seasonNumber,episodeCount,title,overview,poster,const DeepCollectionEquality().hash(_episodes));

@override
String toString() {
  return 'SeasonDetail(seasonNumber: $seasonNumber, episodeCount: $episodeCount, title: $title, overview: $overview, poster: $poster, episodes: $episodes)';
}


}

/// @nodoc
abstract mixin class _$SeasonDetailCopyWith<$Res> implements $SeasonDetailCopyWith<$Res> {
  factory _$SeasonDetailCopyWith(_SeasonDetail value, $Res Function(_SeasonDetail) _then) = __$SeasonDetailCopyWithImpl;
@override @useResult
$Res call({
 int seasonNumber, int? episodeCount, String? title, String? overview, ImageAsset? poster, List<EpisodeDetail>? episodes
});


@override $ImageAssetCopyWith<$Res>? get poster;

}
/// @nodoc
class __$SeasonDetailCopyWithImpl<$Res>
    implements _$SeasonDetailCopyWith<$Res> {
  __$SeasonDetailCopyWithImpl(this._self, this._then);

  final _SeasonDetail _self;
  final $Res Function(_SeasonDetail) _then;

/// Create a copy of SeasonDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seasonNumber = null,Object? episodeCount = freezed,Object? title = freezed,Object? overview = freezed,Object? poster = freezed,Object? episodes = freezed,}) {
  return _then(_SeasonDetail(
seasonNumber: null == seasonNumber ? _self.seasonNumber : seasonNumber // ignore: cast_nullable_to_non_nullable
as int,episodeCount: freezed == episodeCount ? _self.episodeCount : episodeCount // ignore: cast_nullable_to_non_nullable
as int?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,poster: freezed == poster ? _self.poster : poster // ignore: cast_nullable_to_non_nullable
as ImageAsset?,episodes: freezed == episodes ? _self._episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<EpisodeDetail>?,
  ));
}

/// Create a copy of SeasonDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get poster {
    if (_self.poster == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.poster!, (value) {
    return _then(_self.copyWith(poster: value));
  });
}
}


/// @nodoc
mixin _$MovieDetail {

 String get id; String get title; String? get overview; ImageAsset? get poster; ImageAsset? get backdrop; List<String> get genres; String? get releaseDate; int? get runtimeMinutes; String? get tagline; double? get voteAverage; int? get voteCount; MediaCredits get credits; List<Trailer> get trailers; String? get imdbId;
/// Create a copy of MovieDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MovieDetailCopyWith<MovieDetail> get copyWith => _$MovieDetailCopyWithImpl<MovieDetail>(this as MovieDetail, _$identity);

  /// Serializes this MovieDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovieDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.poster, poster) || other.poster == poster)&&(identical(other.backdrop, backdrop) || other.backdrop == backdrop)&&const DeepCollectionEquality().equals(other.genres, genres)&&(identical(other.releaseDate, releaseDate) || other.releaseDate == releaseDate)&&(identical(other.runtimeMinutes, runtimeMinutes) || other.runtimeMinutes == runtimeMinutes)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.voteAverage, voteAverage) || other.voteAverage == voteAverage)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&(identical(other.credits, credits) || other.credits == credits)&&const DeepCollectionEquality().equals(other.trailers, trailers)&&(identical(other.imdbId, imdbId) || other.imdbId == imdbId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,overview,poster,backdrop,const DeepCollectionEquality().hash(genres),releaseDate,runtimeMinutes,tagline,voteAverage,voteCount,credits,const DeepCollectionEquality().hash(trailers),imdbId);

@override
String toString() {
  return 'MovieDetail(id: $id, title: $title, overview: $overview, poster: $poster, backdrop: $backdrop, genres: $genres, releaseDate: $releaseDate, runtimeMinutes: $runtimeMinutes, tagline: $tagline, voteAverage: $voteAverage, voteCount: $voteCount, credits: $credits, trailers: $trailers, imdbId: $imdbId)';
}


}

/// @nodoc
abstract mixin class $MovieDetailCopyWith<$Res>  {
  factory $MovieDetailCopyWith(MovieDetail value, $Res Function(MovieDetail) _then) = _$MovieDetailCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? overview, ImageAsset? poster, ImageAsset? backdrop, List<String> genres, String? releaseDate, int? runtimeMinutes, String? tagline, double? voteAverage, int? voteCount, MediaCredits credits, List<Trailer> trailers, String? imdbId
});


$ImageAssetCopyWith<$Res>? get poster;$ImageAssetCopyWith<$Res>? get backdrop;$MediaCreditsCopyWith<$Res> get credits;

}
/// @nodoc
class _$MovieDetailCopyWithImpl<$Res>
    implements $MovieDetailCopyWith<$Res> {
  _$MovieDetailCopyWithImpl(this._self, this._then);

  final MovieDetail _self;
  final $Res Function(MovieDetail) _then;

/// Create a copy of MovieDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? overview = freezed,Object? poster = freezed,Object? backdrop = freezed,Object? genres = null,Object? releaseDate = freezed,Object? runtimeMinutes = freezed,Object? tagline = freezed,Object? voteAverage = freezed,Object? voteCount = freezed,Object? credits = null,Object? trailers = null,Object? imdbId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,poster: freezed == poster ? _self.poster : poster // ignore: cast_nullable_to_non_nullable
as ImageAsset?,backdrop: freezed == backdrop ? _self.backdrop : backdrop // ignore: cast_nullable_to_non_nullable
as ImageAsset?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,releaseDate: freezed == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String?,runtimeMinutes: freezed == runtimeMinutes ? _self.runtimeMinutes : runtimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,voteAverage: freezed == voteAverage ? _self.voteAverage : voteAverage // ignore: cast_nullable_to_non_nullable
as double?,voteCount: freezed == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int?,credits: null == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as MediaCredits,trailers: null == trailers ? _self.trailers : trailers // ignore: cast_nullable_to_non_nullable
as List<Trailer>,imdbId: freezed == imdbId ? _self.imdbId : imdbId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of MovieDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get poster {
    if (_self.poster == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.poster!, (value) {
    return _then(_self.copyWith(poster: value));
  });
}/// Create a copy of MovieDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get backdrop {
    if (_self.backdrop == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.backdrop!, (value) {
    return _then(_self.copyWith(backdrop: value));
  });
}/// Create a copy of MovieDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaCreditsCopyWith<$Res> get credits {
  
  return $MediaCreditsCopyWith<$Res>(_self.credits, (value) {
    return _then(_self.copyWith(credits: value));
  });
}
}


/// Adds pattern-matching-related methods to [MovieDetail].
extension MovieDetailPatterns on MovieDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MovieDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MovieDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MovieDetail value)  $default,){
final _that = this;
switch (_that) {
case _MovieDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MovieDetail value)?  $default,){
final _that = this;
switch (_that) {
case _MovieDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? overview,  ImageAsset? poster,  ImageAsset? backdrop,  List<String> genres,  String? releaseDate,  int? runtimeMinutes,  String? tagline,  double? voteAverage,  int? voteCount,  MediaCredits credits,  List<Trailer> trailers,  String? imdbId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MovieDetail() when $default != null:
return $default(_that.id,_that.title,_that.overview,_that.poster,_that.backdrop,_that.genres,_that.releaseDate,_that.runtimeMinutes,_that.tagline,_that.voteAverage,_that.voteCount,_that.credits,_that.trailers,_that.imdbId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? overview,  ImageAsset? poster,  ImageAsset? backdrop,  List<String> genres,  String? releaseDate,  int? runtimeMinutes,  String? tagline,  double? voteAverage,  int? voteCount,  MediaCredits credits,  List<Trailer> trailers,  String? imdbId)  $default,) {final _that = this;
switch (_that) {
case _MovieDetail():
return $default(_that.id,_that.title,_that.overview,_that.poster,_that.backdrop,_that.genres,_that.releaseDate,_that.runtimeMinutes,_that.tagline,_that.voteAverage,_that.voteCount,_that.credits,_that.trailers,_that.imdbId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? overview,  ImageAsset? poster,  ImageAsset? backdrop,  List<String> genres,  String? releaseDate,  int? runtimeMinutes,  String? tagline,  double? voteAverage,  int? voteCount,  MediaCredits credits,  List<Trailer> trailers,  String? imdbId)?  $default,) {final _that = this;
switch (_that) {
case _MovieDetail() when $default != null:
return $default(_that.id,_that.title,_that.overview,_that.poster,_that.backdrop,_that.genres,_that.releaseDate,_that.runtimeMinutes,_that.tagline,_that.voteAverage,_that.voteCount,_that.credits,_that.trailers,_that.imdbId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MovieDetail implements MovieDetail {
  const _MovieDetail({required this.id, required this.title, this.overview, this.poster, this.backdrop, final  List<String> genres = const [], this.releaseDate, this.runtimeMinutes, this.tagline, this.voteAverage, this.voteCount, required this.credits, final  List<Trailer> trailers = const [], this.imdbId}): _genres = genres,_trailers = trailers;
  factory _MovieDetail.fromJson(Map<String, dynamic> json) => _$MovieDetailFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? overview;
@override final  ImageAsset? poster;
@override final  ImageAsset? backdrop;
 final  List<String> _genres;
@override@JsonKey() List<String> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

@override final  String? releaseDate;
@override final  int? runtimeMinutes;
@override final  String? tagline;
@override final  double? voteAverage;
@override final  int? voteCount;
@override final  MediaCredits credits;
 final  List<Trailer> _trailers;
@override@JsonKey() List<Trailer> get trailers {
  if (_trailers is EqualUnmodifiableListView) return _trailers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trailers);
}

@override final  String? imdbId;

/// Create a copy of MovieDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MovieDetailCopyWith<_MovieDetail> get copyWith => __$MovieDetailCopyWithImpl<_MovieDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MovieDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MovieDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.poster, poster) || other.poster == poster)&&(identical(other.backdrop, backdrop) || other.backdrop == backdrop)&&const DeepCollectionEquality().equals(other._genres, _genres)&&(identical(other.releaseDate, releaseDate) || other.releaseDate == releaseDate)&&(identical(other.runtimeMinutes, runtimeMinutes) || other.runtimeMinutes == runtimeMinutes)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.voteAverage, voteAverage) || other.voteAverage == voteAverage)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&(identical(other.credits, credits) || other.credits == credits)&&const DeepCollectionEquality().equals(other._trailers, _trailers)&&(identical(other.imdbId, imdbId) || other.imdbId == imdbId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,overview,poster,backdrop,const DeepCollectionEquality().hash(_genres),releaseDate,runtimeMinutes,tagline,voteAverage,voteCount,credits,const DeepCollectionEquality().hash(_trailers),imdbId);

@override
String toString() {
  return 'MovieDetail(id: $id, title: $title, overview: $overview, poster: $poster, backdrop: $backdrop, genres: $genres, releaseDate: $releaseDate, runtimeMinutes: $runtimeMinutes, tagline: $tagline, voteAverage: $voteAverage, voteCount: $voteCount, credits: $credits, trailers: $trailers, imdbId: $imdbId)';
}


}

/// @nodoc
abstract mixin class _$MovieDetailCopyWith<$Res> implements $MovieDetailCopyWith<$Res> {
  factory _$MovieDetailCopyWith(_MovieDetail value, $Res Function(_MovieDetail) _then) = __$MovieDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? overview, ImageAsset? poster, ImageAsset? backdrop, List<String> genres, String? releaseDate, int? runtimeMinutes, String? tagline, double? voteAverage, int? voteCount, MediaCredits credits, List<Trailer> trailers, String? imdbId
});


@override $ImageAssetCopyWith<$Res>? get poster;@override $ImageAssetCopyWith<$Res>? get backdrop;@override $MediaCreditsCopyWith<$Res> get credits;

}
/// @nodoc
class __$MovieDetailCopyWithImpl<$Res>
    implements _$MovieDetailCopyWith<$Res> {
  __$MovieDetailCopyWithImpl(this._self, this._then);

  final _MovieDetail _self;
  final $Res Function(_MovieDetail) _then;

/// Create a copy of MovieDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? overview = freezed,Object? poster = freezed,Object? backdrop = freezed,Object? genres = null,Object? releaseDate = freezed,Object? runtimeMinutes = freezed,Object? tagline = freezed,Object? voteAverage = freezed,Object? voteCount = freezed,Object? credits = null,Object? trailers = null,Object? imdbId = freezed,}) {
  return _then(_MovieDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,poster: freezed == poster ? _self.poster : poster // ignore: cast_nullable_to_non_nullable
as ImageAsset?,backdrop: freezed == backdrop ? _self.backdrop : backdrop // ignore: cast_nullable_to_non_nullable
as ImageAsset?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,releaseDate: freezed == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String?,runtimeMinutes: freezed == runtimeMinutes ? _self.runtimeMinutes : runtimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,voteAverage: freezed == voteAverage ? _self.voteAverage : voteAverage // ignore: cast_nullable_to_non_nullable
as double?,voteCount: freezed == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int?,credits: null == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as MediaCredits,trailers: null == trailers ? _self._trailers : trailers // ignore: cast_nullable_to_non_nullable
as List<Trailer>,imdbId: freezed == imdbId ? _self.imdbId : imdbId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of MovieDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get poster {
    if (_self.poster == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.poster!, (value) {
    return _then(_self.copyWith(poster: value));
  });
}/// Create a copy of MovieDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get backdrop {
    if (_self.backdrop == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.backdrop!, (value) {
    return _then(_self.copyWith(backdrop: value));
  });
}/// Create a copy of MovieDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaCreditsCopyWith<$Res> get credits {
  
  return $MediaCreditsCopyWith<$Res>(_self.credits, (value) {
    return _then(_self.copyWith(credits: value));
  });
}
}


/// @nodoc
mixin _$ShowDetail {

 String get id; String get title; String? get overview; ImageAsset? get poster; ImageAsset? get backdrop; List<String> get genres; String? get firstAirDate; String? get lastAirDate; int? get numberOfSeasons; int? get numberOfEpisodes; double? get voteAverage; int? get voteCount; MediaCredits get credits; List<Trailer> get trailers; List<SeasonDetail> get seasons; String? get imdbId;
/// Create a copy of ShowDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShowDetailCopyWith<ShowDetail> get copyWith => _$ShowDetailCopyWithImpl<ShowDetail>(this as ShowDetail, _$identity);

  /// Serializes this ShowDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShowDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.poster, poster) || other.poster == poster)&&(identical(other.backdrop, backdrop) || other.backdrop == backdrop)&&const DeepCollectionEquality().equals(other.genres, genres)&&(identical(other.firstAirDate, firstAirDate) || other.firstAirDate == firstAirDate)&&(identical(other.lastAirDate, lastAirDate) || other.lastAirDate == lastAirDate)&&(identical(other.numberOfSeasons, numberOfSeasons) || other.numberOfSeasons == numberOfSeasons)&&(identical(other.numberOfEpisodes, numberOfEpisodes) || other.numberOfEpisodes == numberOfEpisodes)&&(identical(other.voteAverage, voteAverage) || other.voteAverage == voteAverage)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&(identical(other.credits, credits) || other.credits == credits)&&const DeepCollectionEquality().equals(other.trailers, trailers)&&const DeepCollectionEquality().equals(other.seasons, seasons)&&(identical(other.imdbId, imdbId) || other.imdbId == imdbId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,overview,poster,backdrop,const DeepCollectionEquality().hash(genres),firstAirDate,lastAirDate,numberOfSeasons,numberOfEpisodes,voteAverage,voteCount,credits,const DeepCollectionEquality().hash(trailers),const DeepCollectionEquality().hash(seasons),imdbId);

@override
String toString() {
  return 'ShowDetail(id: $id, title: $title, overview: $overview, poster: $poster, backdrop: $backdrop, genres: $genres, firstAirDate: $firstAirDate, lastAirDate: $lastAirDate, numberOfSeasons: $numberOfSeasons, numberOfEpisodes: $numberOfEpisodes, voteAverage: $voteAverage, voteCount: $voteCount, credits: $credits, trailers: $trailers, seasons: $seasons, imdbId: $imdbId)';
}


}

/// @nodoc
abstract mixin class $ShowDetailCopyWith<$Res>  {
  factory $ShowDetailCopyWith(ShowDetail value, $Res Function(ShowDetail) _then) = _$ShowDetailCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? overview, ImageAsset? poster, ImageAsset? backdrop, List<String> genres, String? firstAirDate, String? lastAirDate, int? numberOfSeasons, int? numberOfEpisodes, double? voteAverage, int? voteCount, MediaCredits credits, List<Trailer> trailers, List<SeasonDetail> seasons, String? imdbId
});


$ImageAssetCopyWith<$Res>? get poster;$ImageAssetCopyWith<$Res>? get backdrop;$MediaCreditsCopyWith<$Res> get credits;

}
/// @nodoc
class _$ShowDetailCopyWithImpl<$Res>
    implements $ShowDetailCopyWith<$Res> {
  _$ShowDetailCopyWithImpl(this._self, this._then);

  final ShowDetail _self;
  final $Res Function(ShowDetail) _then;

/// Create a copy of ShowDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? overview = freezed,Object? poster = freezed,Object? backdrop = freezed,Object? genres = null,Object? firstAirDate = freezed,Object? lastAirDate = freezed,Object? numberOfSeasons = freezed,Object? numberOfEpisodes = freezed,Object? voteAverage = freezed,Object? voteCount = freezed,Object? credits = null,Object? trailers = null,Object? seasons = null,Object? imdbId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,poster: freezed == poster ? _self.poster : poster // ignore: cast_nullable_to_non_nullable
as ImageAsset?,backdrop: freezed == backdrop ? _self.backdrop : backdrop // ignore: cast_nullable_to_non_nullable
as ImageAsset?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,firstAirDate: freezed == firstAirDate ? _self.firstAirDate : firstAirDate // ignore: cast_nullable_to_non_nullable
as String?,lastAirDate: freezed == lastAirDate ? _self.lastAirDate : lastAirDate // ignore: cast_nullable_to_non_nullable
as String?,numberOfSeasons: freezed == numberOfSeasons ? _self.numberOfSeasons : numberOfSeasons // ignore: cast_nullable_to_non_nullable
as int?,numberOfEpisodes: freezed == numberOfEpisodes ? _self.numberOfEpisodes : numberOfEpisodes // ignore: cast_nullable_to_non_nullable
as int?,voteAverage: freezed == voteAverage ? _self.voteAverage : voteAverage // ignore: cast_nullable_to_non_nullable
as double?,voteCount: freezed == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int?,credits: null == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as MediaCredits,trailers: null == trailers ? _self.trailers : trailers // ignore: cast_nullable_to_non_nullable
as List<Trailer>,seasons: null == seasons ? _self.seasons : seasons // ignore: cast_nullable_to_non_nullable
as List<SeasonDetail>,imdbId: freezed == imdbId ? _self.imdbId : imdbId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ShowDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get poster {
    if (_self.poster == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.poster!, (value) {
    return _then(_self.copyWith(poster: value));
  });
}/// Create a copy of ShowDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get backdrop {
    if (_self.backdrop == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.backdrop!, (value) {
    return _then(_self.copyWith(backdrop: value));
  });
}/// Create a copy of ShowDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaCreditsCopyWith<$Res> get credits {
  
  return $MediaCreditsCopyWith<$Res>(_self.credits, (value) {
    return _then(_self.copyWith(credits: value));
  });
}
}


/// Adds pattern-matching-related methods to [ShowDetail].
extension ShowDetailPatterns on ShowDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShowDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShowDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShowDetail value)  $default,){
final _that = this;
switch (_that) {
case _ShowDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShowDetail value)?  $default,){
final _that = this;
switch (_that) {
case _ShowDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? overview,  ImageAsset? poster,  ImageAsset? backdrop,  List<String> genres,  String? firstAirDate,  String? lastAirDate,  int? numberOfSeasons,  int? numberOfEpisodes,  double? voteAverage,  int? voteCount,  MediaCredits credits,  List<Trailer> trailers,  List<SeasonDetail> seasons,  String? imdbId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShowDetail() when $default != null:
return $default(_that.id,_that.title,_that.overview,_that.poster,_that.backdrop,_that.genres,_that.firstAirDate,_that.lastAirDate,_that.numberOfSeasons,_that.numberOfEpisodes,_that.voteAverage,_that.voteCount,_that.credits,_that.trailers,_that.seasons,_that.imdbId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? overview,  ImageAsset? poster,  ImageAsset? backdrop,  List<String> genres,  String? firstAirDate,  String? lastAirDate,  int? numberOfSeasons,  int? numberOfEpisodes,  double? voteAverage,  int? voteCount,  MediaCredits credits,  List<Trailer> trailers,  List<SeasonDetail> seasons,  String? imdbId)  $default,) {final _that = this;
switch (_that) {
case _ShowDetail():
return $default(_that.id,_that.title,_that.overview,_that.poster,_that.backdrop,_that.genres,_that.firstAirDate,_that.lastAirDate,_that.numberOfSeasons,_that.numberOfEpisodes,_that.voteAverage,_that.voteCount,_that.credits,_that.trailers,_that.seasons,_that.imdbId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? overview,  ImageAsset? poster,  ImageAsset? backdrop,  List<String> genres,  String? firstAirDate,  String? lastAirDate,  int? numberOfSeasons,  int? numberOfEpisodes,  double? voteAverage,  int? voteCount,  MediaCredits credits,  List<Trailer> trailers,  List<SeasonDetail> seasons,  String? imdbId)?  $default,) {final _that = this;
switch (_that) {
case _ShowDetail() when $default != null:
return $default(_that.id,_that.title,_that.overview,_that.poster,_that.backdrop,_that.genres,_that.firstAirDate,_that.lastAirDate,_that.numberOfSeasons,_that.numberOfEpisodes,_that.voteAverage,_that.voteCount,_that.credits,_that.trailers,_that.seasons,_that.imdbId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShowDetail implements ShowDetail {
  const _ShowDetail({required this.id, required this.title, this.overview, this.poster, this.backdrop, final  List<String> genres = const [], this.firstAirDate, this.lastAirDate, this.numberOfSeasons, this.numberOfEpisodes, this.voteAverage, this.voteCount, required this.credits, final  List<Trailer> trailers = const [], final  List<SeasonDetail> seasons = const [], this.imdbId}): _genres = genres,_trailers = trailers,_seasons = seasons;
  factory _ShowDetail.fromJson(Map<String, dynamic> json) => _$ShowDetailFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? overview;
@override final  ImageAsset? poster;
@override final  ImageAsset? backdrop;
 final  List<String> _genres;
@override@JsonKey() List<String> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

@override final  String? firstAirDate;
@override final  String? lastAirDate;
@override final  int? numberOfSeasons;
@override final  int? numberOfEpisodes;
@override final  double? voteAverage;
@override final  int? voteCount;
@override final  MediaCredits credits;
 final  List<Trailer> _trailers;
@override@JsonKey() List<Trailer> get trailers {
  if (_trailers is EqualUnmodifiableListView) return _trailers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trailers);
}

 final  List<SeasonDetail> _seasons;
@override@JsonKey() List<SeasonDetail> get seasons {
  if (_seasons is EqualUnmodifiableListView) return _seasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_seasons);
}

@override final  String? imdbId;

/// Create a copy of ShowDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShowDetailCopyWith<_ShowDetail> get copyWith => __$ShowDetailCopyWithImpl<_ShowDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShowDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.poster, poster) || other.poster == poster)&&(identical(other.backdrop, backdrop) || other.backdrop == backdrop)&&const DeepCollectionEquality().equals(other._genres, _genres)&&(identical(other.firstAirDate, firstAirDate) || other.firstAirDate == firstAirDate)&&(identical(other.lastAirDate, lastAirDate) || other.lastAirDate == lastAirDate)&&(identical(other.numberOfSeasons, numberOfSeasons) || other.numberOfSeasons == numberOfSeasons)&&(identical(other.numberOfEpisodes, numberOfEpisodes) || other.numberOfEpisodes == numberOfEpisodes)&&(identical(other.voteAverage, voteAverage) || other.voteAverage == voteAverage)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&(identical(other.credits, credits) || other.credits == credits)&&const DeepCollectionEquality().equals(other._trailers, _trailers)&&const DeepCollectionEquality().equals(other._seasons, _seasons)&&(identical(other.imdbId, imdbId) || other.imdbId == imdbId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,overview,poster,backdrop,const DeepCollectionEquality().hash(_genres),firstAirDate,lastAirDate,numberOfSeasons,numberOfEpisodes,voteAverage,voteCount,credits,const DeepCollectionEquality().hash(_trailers),const DeepCollectionEquality().hash(_seasons),imdbId);

@override
String toString() {
  return 'ShowDetail(id: $id, title: $title, overview: $overview, poster: $poster, backdrop: $backdrop, genres: $genres, firstAirDate: $firstAirDate, lastAirDate: $lastAirDate, numberOfSeasons: $numberOfSeasons, numberOfEpisodes: $numberOfEpisodes, voteAverage: $voteAverage, voteCount: $voteCount, credits: $credits, trailers: $trailers, seasons: $seasons, imdbId: $imdbId)';
}


}

/// @nodoc
abstract mixin class _$ShowDetailCopyWith<$Res> implements $ShowDetailCopyWith<$Res> {
  factory _$ShowDetailCopyWith(_ShowDetail value, $Res Function(_ShowDetail) _then) = __$ShowDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? overview, ImageAsset? poster, ImageAsset? backdrop, List<String> genres, String? firstAirDate, String? lastAirDate, int? numberOfSeasons, int? numberOfEpisodes, double? voteAverage, int? voteCount, MediaCredits credits, List<Trailer> trailers, List<SeasonDetail> seasons, String? imdbId
});


@override $ImageAssetCopyWith<$Res>? get poster;@override $ImageAssetCopyWith<$Res>? get backdrop;@override $MediaCreditsCopyWith<$Res> get credits;

}
/// @nodoc
class __$ShowDetailCopyWithImpl<$Res>
    implements _$ShowDetailCopyWith<$Res> {
  __$ShowDetailCopyWithImpl(this._self, this._then);

  final _ShowDetail _self;
  final $Res Function(_ShowDetail) _then;

/// Create a copy of ShowDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? overview = freezed,Object? poster = freezed,Object? backdrop = freezed,Object? genres = null,Object? firstAirDate = freezed,Object? lastAirDate = freezed,Object? numberOfSeasons = freezed,Object? numberOfEpisodes = freezed,Object? voteAverage = freezed,Object? voteCount = freezed,Object? credits = null,Object? trailers = null,Object? seasons = null,Object? imdbId = freezed,}) {
  return _then(_ShowDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,poster: freezed == poster ? _self.poster : poster // ignore: cast_nullable_to_non_nullable
as ImageAsset?,backdrop: freezed == backdrop ? _self.backdrop : backdrop // ignore: cast_nullable_to_non_nullable
as ImageAsset?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,firstAirDate: freezed == firstAirDate ? _self.firstAirDate : firstAirDate // ignore: cast_nullable_to_non_nullable
as String?,lastAirDate: freezed == lastAirDate ? _self.lastAirDate : lastAirDate // ignore: cast_nullable_to_non_nullable
as String?,numberOfSeasons: freezed == numberOfSeasons ? _self.numberOfSeasons : numberOfSeasons // ignore: cast_nullable_to_non_nullable
as int?,numberOfEpisodes: freezed == numberOfEpisodes ? _self.numberOfEpisodes : numberOfEpisodes // ignore: cast_nullable_to_non_nullable
as int?,voteAverage: freezed == voteAverage ? _self.voteAverage : voteAverage // ignore: cast_nullable_to_non_nullable
as double?,voteCount: freezed == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int?,credits: null == credits ? _self.credits : credits // ignore: cast_nullable_to_non_nullable
as MediaCredits,trailers: null == trailers ? _self._trailers : trailers // ignore: cast_nullable_to_non_nullable
as List<Trailer>,seasons: null == seasons ? _self._seasons : seasons // ignore: cast_nullable_to_non_nullable
as List<SeasonDetail>,imdbId: freezed == imdbId ? _self.imdbId : imdbId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ShowDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get poster {
    if (_self.poster == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.poster!, (value) {
    return _then(_self.copyWith(poster: value));
  });
}/// Create a copy of ShowDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get backdrop {
    if (_self.backdrop == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.backdrop!, (value) {
    return _then(_self.copyWith(backdrop: value));
  });
}/// Create a copy of ShowDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaCreditsCopyWith<$Res> get credits {
  
  return $MediaCreditsCopyWith<$Res>(_self.credits, (value) {
    return _then(_self.copyWith(credits: value));
  });
}
}


/// @nodoc
mixin _$ImdbRatingResponse {

 String get imdbId; double? get rating; int? get voteCount;
/// Create a copy of ImdbRatingResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImdbRatingResponseCopyWith<ImdbRatingResponse> get copyWith => _$ImdbRatingResponseCopyWithImpl<ImdbRatingResponse>(this as ImdbRatingResponse, _$identity);

  /// Serializes this ImdbRatingResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImdbRatingResponse&&(identical(other.imdbId, imdbId) || other.imdbId == imdbId)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,imdbId,rating,voteCount);

@override
String toString() {
  return 'ImdbRatingResponse(imdbId: $imdbId, rating: $rating, voteCount: $voteCount)';
}


}

/// @nodoc
abstract mixin class $ImdbRatingResponseCopyWith<$Res>  {
  factory $ImdbRatingResponseCopyWith(ImdbRatingResponse value, $Res Function(ImdbRatingResponse) _then) = _$ImdbRatingResponseCopyWithImpl;
@useResult
$Res call({
 String imdbId, double? rating, int? voteCount
});




}
/// @nodoc
class _$ImdbRatingResponseCopyWithImpl<$Res>
    implements $ImdbRatingResponseCopyWith<$Res> {
  _$ImdbRatingResponseCopyWithImpl(this._self, this._then);

  final ImdbRatingResponse _self;
  final $Res Function(ImdbRatingResponse) _then;

/// Create a copy of ImdbRatingResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? imdbId = null,Object? rating = freezed,Object? voteCount = freezed,}) {
  return _then(_self.copyWith(
imdbId: null == imdbId ? _self.imdbId : imdbId // ignore: cast_nullable_to_non_nullable
as String,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,voteCount: freezed == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ImdbRatingResponse].
extension ImdbRatingResponsePatterns on ImdbRatingResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImdbRatingResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImdbRatingResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImdbRatingResponse value)  $default,){
final _that = this;
switch (_that) {
case _ImdbRatingResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImdbRatingResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ImdbRatingResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String imdbId,  double? rating,  int? voteCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImdbRatingResponse() when $default != null:
return $default(_that.imdbId,_that.rating,_that.voteCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String imdbId,  double? rating,  int? voteCount)  $default,) {final _that = this;
switch (_that) {
case _ImdbRatingResponse():
return $default(_that.imdbId,_that.rating,_that.voteCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String imdbId,  double? rating,  int? voteCount)?  $default,) {final _that = this;
switch (_that) {
case _ImdbRatingResponse() when $default != null:
return $default(_that.imdbId,_that.rating,_that.voteCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ImdbRatingResponse implements ImdbRatingResponse {
  const _ImdbRatingResponse({required this.imdbId, this.rating, this.voteCount});
  factory _ImdbRatingResponse.fromJson(Map<String, dynamic> json) => _$ImdbRatingResponseFromJson(json);

@override final  String imdbId;
@override final  double? rating;
@override final  int? voteCount;

/// Create a copy of ImdbRatingResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImdbRatingResponseCopyWith<_ImdbRatingResponse> get copyWith => __$ImdbRatingResponseCopyWithImpl<_ImdbRatingResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImdbRatingResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImdbRatingResponse&&(identical(other.imdbId, imdbId) || other.imdbId == imdbId)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,imdbId,rating,voteCount);

@override
String toString() {
  return 'ImdbRatingResponse(imdbId: $imdbId, rating: $rating, voteCount: $voteCount)';
}


}

/// @nodoc
abstract mixin class _$ImdbRatingResponseCopyWith<$Res> implements $ImdbRatingResponseCopyWith<$Res> {
  factory _$ImdbRatingResponseCopyWith(_ImdbRatingResponse value, $Res Function(_ImdbRatingResponse) _then) = __$ImdbRatingResponseCopyWithImpl;
@override @useResult
$Res call({
 String imdbId, double? rating, int? voteCount
});




}
/// @nodoc
class __$ImdbRatingResponseCopyWithImpl<$Res>
    implements _$ImdbRatingResponseCopyWith<$Res> {
  __$ImdbRatingResponseCopyWithImpl(this._self, this._then);

  final _ImdbRatingResponse _self;
  final $Res Function(_ImdbRatingResponse) _then;

/// Create a copy of ImdbRatingResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? imdbId = null,Object? rating = freezed,Object? voteCount = freezed,}) {
  return _then(_ImdbRatingResponse(
imdbId: null == imdbId ? _self.imdbId : imdbId // ignore: cast_nullable_to_non_nullable
as String,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,voteCount: freezed == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ShowSeasonsResponse {

 String get showId; String get title; int get seasonsCount; List<SeasonDetail> get seasons;
/// Create a copy of ShowSeasonsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShowSeasonsResponseCopyWith<ShowSeasonsResponse> get copyWith => _$ShowSeasonsResponseCopyWithImpl<ShowSeasonsResponse>(this as ShowSeasonsResponse, _$identity);

  /// Serializes this ShowSeasonsResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShowSeasonsResponse&&(identical(other.showId, showId) || other.showId == showId)&&(identical(other.title, title) || other.title == title)&&(identical(other.seasonsCount, seasonsCount) || other.seasonsCount == seasonsCount)&&const DeepCollectionEquality().equals(other.seasons, seasons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,showId,title,seasonsCount,const DeepCollectionEquality().hash(seasons));

@override
String toString() {
  return 'ShowSeasonsResponse(showId: $showId, title: $title, seasonsCount: $seasonsCount, seasons: $seasons)';
}


}

/// @nodoc
abstract mixin class $ShowSeasonsResponseCopyWith<$Res>  {
  factory $ShowSeasonsResponseCopyWith(ShowSeasonsResponse value, $Res Function(ShowSeasonsResponse) _then) = _$ShowSeasonsResponseCopyWithImpl;
@useResult
$Res call({
 String showId, String title, int seasonsCount, List<SeasonDetail> seasons
});




}
/// @nodoc
class _$ShowSeasonsResponseCopyWithImpl<$Res>
    implements $ShowSeasonsResponseCopyWith<$Res> {
  _$ShowSeasonsResponseCopyWithImpl(this._self, this._then);

  final ShowSeasonsResponse _self;
  final $Res Function(ShowSeasonsResponse) _then;

/// Create a copy of ShowSeasonsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? showId = null,Object? title = null,Object? seasonsCount = null,Object? seasons = null,}) {
  return _then(_self.copyWith(
showId: null == showId ? _self.showId : showId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,seasonsCount: null == seasonsCount ? _self.seasonsCount : seasonsCount // ignore: cast_nullable_to_non_nullable
as int,seasons: null == seasons ? _self.seasons : seasons // ignore: cast_nullable_to_non_nullable
as List<SeasonDetail>,
  ));
}

}


/// Adds pattern-matching-related methods to [ShowSeasonsResponse].
extension ShowSeasonsResponsePatterns on ShowSeasonsResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShowSeasonsResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShowSeasonsResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShowSeasonsResponse value)  $default,){
final _that = this;
switch (_that) {
case _ShowSeasonsResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShowSeasonsResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ShowSeasonsResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String showId,  String title,  int seasonsCount,  List<SeasonDetail> seasons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShowSeasonsResponse() when $default != null:
return $default(_that.showId,_that.title,_that.seasonsCount,_that.seasons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String showId,  String title,  int seasonsCount,  List<SeasonDetail> seasons)  $default,) {final _that = this;
switch (_that) {
case _ShowSeasonsResponse():
return $default(_that.showId,_that.title,_that.seasonsCount,_that.seasons);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String showId,  String title,  int seasonsCount,  List<SeasonDetail> seasons)?  $default,) {final _that = this;
switch (_that) {
case _ShowSeasonsResponse() when $default != null:
return $default(_that.showId,_that.title,_that.seasonsCount,_that.seasons);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShowSeasonsResponse implements ShowSeasonsResponse {
  const _ShowSeasonsResponse({required this.showId, required this.title, required this.seasonsCount, required final  List<SeasonDetail> seasons}): _seasons = seasons;
  factory _ShowSeasonsResponse.fromJson(Map<String, dynamic> json) => _$ShowSeasonsResponseFromJson(json);

@override final  String showId;
@override final  String title;
@override final  int seasonsCount;
 final  List<SeasonDetail> _seasons;
@override List<SeasonDetail> get seasons {
  if (_seasons is EqualUnmodifiableListView) return _seasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_seasons);
}


/// Create a copy of ShowSeasonsResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShowSeasonsResponseCopyWith<_ShowSeasonsResponse> get copyWith => __$ShowSeasonsResponseCopyWithImpl<_ShowSeasonsResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShowSeasonsResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowSeasonsResponse&&(identical(other.showId, showId) || other.showId == showId)&&(identical(other.title, title) || other.title == title)&&(identical(other.seasonsCount, seasonsCount) || other.seasonsCount == seasonsCount)&&const DeepCollectionEquality().equals(other._seasons, _seasons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,showId,title,seasonsCount,const DeepCollectionEquality().hash(_seasons));

@override
String toString() {
  return 'ShowSeasonsResponse(showId: $showId, title: $title, seasonsCount: $seasonsCount, seasons: $seasons)';
}


}

/// @nodoc
abstract mixin class _$ShowSeasonsResponseCopyWith<$Res> implements $ShowSeasonsResponseCopyWith<$Res> {
  factory _$ShowSeasonsResponseCopyWith(_ShowSeasonsResponse value, $Res Function(_ShowSeasonsResponse) _then) = __$ShowSeasonsResponseCopyWithImpl;
@override @useResult
$Res call({
 String showId, String title, int seasonsCount, List<SeasonDetail> seasons
});




}
/// @nodoc
class __$ShowSeasonsResponseCopyWithImpl<$Res>
    implements _$ShowSeasonsResponseCopyWith<$Res> {
  __$ShowSeasonsResponseCopyWithImpl(this._self, this._then);

  final _ShowSeasonsResponse _self;
  final $Res Function(_ShowSeasonsResponse) _then;

/// Create a copy of ShowSeasonsResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? showId = null,Object? title = null,Object? seasonsCount = null,Object? seasons = null,}) {
  return _then(_ShowSeasonsResponse(
showId: null == showId ? _self.showId : showId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,seasonsCount: null == seasonsCount ? _self.seasonsCount : seasonsCount // ignore: cast_nullable_to_non_nullable
as int,seasons: null == seasons ? _self._seasons : seasons // ignore: cast_nullable_to_non_nullable
as List<SeasonDetail>,
  ));
}


}


/// @nodoc
mixin _$ShowProgressEpisode {

 int get number; bool get completed; double? get scrobbleProgress; int? get playbackId;
/// Create a copy of ShowProgressEpisode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShowProgressEpisodeCopyWith<ShowProgressEpisode> get copyWith => _$ShowProgressEpisodeCopyWithImpl<ShowProgressEpisode>(this as ShowProgressEpisode, _$identity);

  /// Serializes this ShowProgressEpisode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShowProgressEpisode&&(identical(other.number, number) || other.number == number)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.scrobbleProgress, scrobbleProgress) || other.scrobbleProgress == scrobbleProgress)&&(identical(other.playbackId, playbackId) || other.playbackId == playbackId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,completed,scrobbleProgress,playbackId);

@override
String toString() {
  return 'ShowProgressEpisode(number: $number, completed: $completed, scrobbleProgress: $scrobbleProgress, playbackId: $playbackId)';
}


}

/// @nodoc
abstract mixin class $ShowProgressEpisodeCopyWith<$Res>  {
  factory $ShowProgressEpisodeCopyWith(ShowProgressEpisode value, $Res Function(ShowProgressEpisode) _then) = _$ShowProgressEpisodeCopyWithImpl;
@useResult
$Res call({
 int number, bool completed, double? scrobbleProgress, int? playbackId
});




}
/// @nodoc
class _$ShowProgressEpisodeCopyWithImpl<$Res>
    implements $ShowProgressEpisodeCopyWith<$Res> {
  _$ShowProgressEpisodeCopyWithImpl(this._self, this._then);

  final ShowProgressEpisode _self;
  final $Res Function(ShowProgressEpisode) _then;

/// Create a copy of ShowProgressEpisode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? completed = null,Object? scrobbleProgress = freezed,Object? playbackId = freezed,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,scrobbleProgress: freezed == scrobbleProgress ? _self.scrobbleProgress : scrobbleProgress // ignore: cast_nullable_to_non_nullable
as double?,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShowProgressEpisode].
extension ShowProgressEpisodePatterns on ShowProgressEpisode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShowProgressEpisode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShowProgressEpisode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShowProgressEpisode value)  $default,){
final _that = this;
switch (_that) {
case _ShowProgressEpisode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShowProgressEpisode value)?  $default,){
final _that = this;
switch (_that) {
case _ShowProgressEpisode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  bool completed,  double? scrobbleProgress,  int? playbackId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShowProgressEpisode() when $default != null:
return $default(_that.number,_that.completed,_that.scrobbleProgress,_that.playbackId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  bool completed,  double? scrobbleProgress,  int? playbackId)  $default,) {final _that = this;
switch (_that) {
case _ShowProgressEpisode():
return $default(_that.number,_that.completed,_that.scrobbleProgress,_that.playbackId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  bool completed,  double? scrobbleProgress,  int? playbackId)?  $default,) {final _that = this;
switch (_that) {
case _ShowProgressEpisode() when $default != null:
return $default(_that.number,_that.completed,_that.scrobbleProgress,_that.playbackId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShowProgressEpisode implements ShowProgressEpisode {
  const _ShowProgressEpisode({required this.number, this.completed = false, this.scrobbleProgress, this.playbackId});
  factory _ShowProgressEpisode.fromJson(Map<String, dynamic> json) => _$ShowProgressEpisodeFromJson(json);

@override final  int number;
@override@JsonKey() final  bool completed;
@override final  double? scrobbleProgress;
@override final  int? playbackId;

/// Create a copy of ShowProgressEpisode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShowProgressEpisodeCopyWith<_ShowProgressEpisode> get copyWith => __$ShowProgressEpisodeCopyWithImpl<_ShowProgressEpisode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShowProgressEpisodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowProgressEpisode&&(identical(other.number, number) || other.number == number)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.scrobbleProgress, scrobbleProgress) || other.scrobbleProgress == scrobbleProgress)&&(identical(other.playbackId, playbackId) || other.playbackId == playbackId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,completed,scrobbleProgress,playbackId);

@override
String toString() {
  return 'ShowProgressEpisode(number: $number, completed: $completed, scrobbleProgress: $scrobbleProgress, playbackId: $playbackId)';
}


}

/// @nodoc
abstract mixin class _$ShowProgressEpisodeCopyWith<$Res> implements $ShowProgressEpisodeCopyWith<$Res> {
  factory _$ShowProgressEpisodeCopyWith(_ShowProgressEpisode value, $Res Function(_ShowProgressEpisode) _then) = __$ShowProgressEpisodeCopyWithImpl;
@override @useResult
$Res call({
 int number, bool completed, double? scrobbleProgress, int? playbackId
});




}
/// @nodoc
class __$ShowProgressEpisodeCopyWithImpl<$Res>
    implements _$ShowProgressEpisodeCopyWith<$Res> {
  __$ShowProgressEpisodeCopyWithImpl(this._self, this._then);

  final _ShowProgressEpisode _self;
  final $Res Function(_ShowProgressEpisode) _then;

/// Create a copy of ShowProgressEpisode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? completed = null,Object? scrobbleProgress = freezed,Object? playbackId = freezed,}) {
  return _then(_ShowProgressEpisode(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,scrobbleProgress: freezed == scrobbleProgress ? _self.scrobbleProgress : scrobbleProgress // ignore: cast_nullable_to_non_nullable
as double?,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ShowProgressSeason {

 int get number; List<ShowProgressEpisode> get episodes;
/// Create a copy of ShowProgressSeason
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShowProgressSeasonCopyWith<ShowProgressSeason> get copyWith => _$ShowProgressSeasonCopyWithImpl<ShowProgressSeason>(this as ShowProgressSeason, _$identity);

  /// Serializes this ShowProgressSeason to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShowProgressSeason&&(identical(other.number, number) || other.number == number)&&const DeepCollectionEquality().equals(other.episodes, episodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,const DeepCollectionEquality().hash(episodes));

@override
String toString() {
  return 'ShowProgressSeason(number: $number, episodes: $episodes)';
}


}

/// @nodoc
abstract mixin class $ShowProgressSeasonCopyWith<$Res>  {
  factory $ShowProgressSeasonCopyWith(ShowProgressSeason value, $Res Function(ShowProgressSeason) _then) = _$ShowProgressSeasonCopyWithImpl;
@useResult
$Res call({
 int number, List<ShowProgressEpisode> episodes
});




}
/// @nodoc
class _$ShowProgressSeasonCopyWithImpl<$Res>
    implements $ShowProgressSeasonCopyWith<$Res> {
  _$ShowProgressSeasonCopyWithImpl(this._self, this._then);

  final ShowProgressSeason _self;
  final $Res Function(ShowProgressSeason) _then;

/// Create a copy of ShowProgressSeason
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? episodes = null,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,episodes: null == episodes ? _self.episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<ShowProgressEpisode>,
  ));
}

}


/// Adds pattern-matching-related methods to [ShowProgressSeason].
extension ShowProgressSeasonPatterns on ShowProgressSeason {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShowProgressSeason value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShowProgressSeason() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShowProgressSeason value)  $default,){
final _that = this;
switch (_that) {
case _ShowProgressSeason():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShowProgressSeason value)?  $default,){
final _that = this;
switch (_that) {
case _ShowProgressSeason() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  List<ShowProgressEpisode> episodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShowProgressSeason() when $default != null:
return $default(_that.number,_that.episodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  List<ShowProgressEpisode> episodes)  $default,) {final _that = this;
switch (_that) {
case _ShowProgressSeason():
return $default(_that.number,_that.episodes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  List<ShowProgressEpisode> episodes)?  $default,) {final _that = this;
switch (_that) {
case _ShowProgressSeason() when $default != null:
return $default(_that.number,_that.episodes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShowProgressSeason implements ShowProgressSeason {
  const _ShowProgressSeason({required this.number, final  List<ShowProgressEpisode> episodes = const []}): _episodes = episodes;
  factory _ShowProgressSeason.fromJson(Map<String, dynamic> json) => _$ShowProgressSeasonFromJson(json);

@override final  int number;
 final  List<ShowProgressEpisode> _episodes;
@override@JsonKey() List<ShowProgressEpisode> get episodes {
  if (_episodes is EqualUnmodifiableListView) return _episodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_episodes);
}


/// Create a copy of ShowProgressSeason
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShowProgressSeasonCopyWith<_ShowProgressSeason> get copyWith => __$ShowProgressSeasonCopyWithImpl<_ShowProgressSeason>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShowProgressSeasonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowProgressSeason&&(identical(other.number, number) || other.number == number)&&const DeepCollectionEquality().equals(other._episodes, _episodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,const DeepCollectionEquality().hash(_episodes));

@override
String toString() {
  return 'ShowProgressSeason(number: $number, episodes: $episodes)';
}


}

/// @nodoc
abstract mixin class _$ShowProgressSeasonCopyWith<$Res> implements $ShowProgressSeasonCopyWith<$Res> {
  factory _$ShowProgressSeasonCopyWith(_ShowProgressSeason value, $Res Function(_ShowProgressSeason) _then) = __$ShowProgressSeasonCopyWithImpl;
@override @useResult
$Res call({
 int number, List<ShowProgressEpisode> episodes
});




}
/// @nodoc
class __$ShowProgressSeasonCopyWithImpl<$Res>
    implements _$ShowProgressSeasonCopyWith<$Res> {
  __$ShowProgressSeasonCopyWithImpl(this._self, this._then);

  final _ShowProgressSeason _self;
  final $Res Function(_ShowProgressSeason) _then;

/// Create a copy of ShowProgressSeason
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? episodes = null,}) {
  return _then(_ShowProgressSeason(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,episodes: null == episodes ? _self._episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<ShowProgressEpisode>,
  ));
}


}


/// @nodoc
mixin _$ShowProgressResponse {

 int? get aired; int? get completed; List<ShowProgressSeason> get seasons;
/// Create a copy of ShowProgressResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShowProgressResponseCopyWith<ShowProgressResponse> get copyWith => _$ShowProgressResponseCopyWithImpl<ShowProgressResponse>(this as ShowProgressResponse, _$identity);

  /// Serializes this ShowProgressResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShowProgressResponse&&(identical(other.aired, aired) || other.aired == aired)&&(identical(other.completed, completed) || other.completed == completed)&&const DeepCollectionEquality().equals(other.seasons, seasons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,aired,completed,const DeepCollectionEquality().hash(seasons));

@override
String toString() {
  return 'ShowProgressResponse(aired: $aired, completed: $completed, seasons: $seasons)';
}


}

/// @nodoc
abstract mixin class $ShowProgressResponseCopyWith<$Res>  {
  factory $ShowProgressResponseCopyWith(ShowProgressResponse value, $Res Function(ShowProgressResponse) _then) = _$ShowProgressResponseCopyWithImpl;
@useResult
$Res call({
 int? aired, int? completed, List<ShowProgressSeason> seasons
});




}
/// @nodoc
class _$ShowProgressResponseCopyWithImpl<$Res>
    implements $ShowProgressResponseCopyWith<$Res> {
  _$ShowProgressResponseCopyWithImpl(this._self, this._then);

  final ShowProgressResponse _self;
  final $Res Function(ShowProgressResponse) _then;

/// Create a copy of ShowProgressResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? aired = freezed,Object? completed = freezed,Object? seasons = null,}) {
  return _then(_self.copyWith(
aired: freezed == aired ? _self.aired : aired // ignore: cast_nullable_to_non_nullable
as int?,completed: freezed == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int?,seasons: null == seasons ? _self.seasons : seasons // ignore: cast_nullable_to_non_nullable
as List<ShowProgressSeason>,
  ));
}

}


/// Adds pattern-matching-related methods to [ShowProgressResponse].
extension ShowProgressResponsePatterns on ShowProgressResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShowProgressResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShowProgressResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShowProgressResponse value)  $default,){
final _that = this;
switch (_that) {
case _ShowProgressResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShowProgressResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ShowProgressResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? aired,  int? completed,  List<ShowProgressSeason> seasons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShowProgressResponse() when $default != null:
return $default(_that.aired,_that.completed,_that.seasons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? aired,  int? completed,  List<ShowProgressSeason> seasons)  $default,) {final _that = this;
switch (_that) {
case _ShowProgressResponse():
return $default(_that.aired,_that.completed,_that.seasons);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? aired,  int? completed,  List<ShowProgressSeason> seasons)?  $default,) {final _that = this;
switch (_that) {
case _ShowProgressResponse() when $default != null:
return $default(_that.aired,_that.completed,_that.seasons);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShowProgressResponse implements ShowProgressResponse {
  const _ShowProgressResponse({this.aired, this.completed, final  List<ShowProgressSeason> seasons = const []}): _seasons = seasons;
  factory _ShowProgressResponse.fromJson(Map<String, dynamic> json) => _$ShowProgressResponseFromJson(json);

@override final  int? aired;
@override final  int? completed;
 final  List<ShowProgressSeason> _seasons;
@override@JsonKey() List<ShowProgressSeason> get seasons {
  if (_seasons is EqualUnmodifiableListView) return _seasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_seasons);
}


/// Create a copy of ShowProgressResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShowProgressResponseCopyWith<_ShowProgressResponse> get copyWith => __$ShowProgressResponseCopyWithImpl<_ShowProgressResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShowProgressResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowProgressResponse&&(identical(other.aired, aired) || other.aired == aired)&&(identical(other.completed, completed) || other.completed == completed)&&const DeepCollectionEquality().equals(other._seasons, _seasons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,aired,completed,const DeepCollectionEquality().hash(_seasons));

@override
String toString() {
  return 'ShowProgressResponse(aired: $aired, completed: $completed, seasons: $seasons)';
}


}

/// @nodoc
abstract mixin class _$ShowProgressResponseCopyWith<$Res> implements $ShowProgressResponseCopyWith<$Res> {
  factory _$ShowProgressResponseCopyWith(_ShowProgressResponse value, $Res Function(_ShowProgressResponse) _then) = __$ShowProgressResponseCopyWithImpl;
@override @useResult
$Res call({
 int? aired, int? completed, List<ShowProgressSeason> seasons
});




}
/// @nodoc
class __$ShowProgressResponseCopyWithImpl<$Res>
    implements _$ShowProgressResponseCopyWith<$Res> {
  __$ShowProgressResponseCopyWithImpl(this._self, this._then);

  final _ShowProgressResponse _self;
  final $Res Function(_ShowProgressResponse) _then;

/// Create a copy of ShowProgressResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aired = freezed,Object? completed = freezed,Object? seasons = null,}) {
  return _then(_ShowProgressResponse(
aired: freezed == aired ? _self.aired : aired // ignore: cast_nullable_to_non_nullable
as int?,completed: freezed == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int?,seasons: null == seasons ? _self._seasons : seasons // ignore: cast_nullable_to_non_nullable
as List<ShowProgressSeason>,
  ));
}


}


/// @nodoc
mixin _$WatchProvider {

 int? get providerId; String get providerName; String? get logoPath;
/// Create a copy of WatchProvider
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchProviderCopyWith<WatchProvider> get copyWith => _$WatchProviderCopyWithImpl<WatchProvider>(this as WatchProvider, _$identity);

  /// Serializes this WatchProvider to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchProvider&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.logoPath, logoPath) || other.logoPath == logoPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,providerName,logoPath);

@override
String toString() {
  return 'WatchProvider(providerId: $providerId, providerName: $providerName, logoPath: $logoPath)';
}


}

/// @nodoc
abstract mixin class $WatchProviderCopyWith<$Res>  {
  factory $WatchProviderCopyWith(WatchProvider value, $Res Function(WatchProvider) _then) = _$WatchProviderCopyWithImpl;
@useResult
$Res call({
 int? providerId, String providerName, String? logoPath
});




}
/// @nodoc
class _$WatchProviderCopyWithImpl<$Res>
    implements $WatchProviderCopyWith<$Res> {
  _$WatchProviderCopyWithImpl(this._self, this._then);

  final WatchProvider _self;
  final $Res Function(WatchProvider) _then;

/// Create a copy of WatchProvider
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? providerId = freezed,Object? providerName = null,Object? logoPath = freezed,}) {
  return _then(_self.copyWith(
providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as int?,providerName: null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,logoPath: freezed == logoPath ? _self.logoPath : logoPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WatchProvider].
extension WatchProviderPatterns on WatchProvider {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WatchProvider value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WatchProvider() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WatchProvider value)  $default,){
final _that = this;
switch (_that) {
case _WatchProvider():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WatchProvider value)?  $default,){
final _that = this;
switch (_that) {
case _WatchProvider() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? providerId,  String providerName,  String? logoPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WatchProvider() when $default != null:
return $default(_that.providerId,_that.providerName,_that.logoPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? providerId,  String providerName,  String? logoPath)  $default,) {final _that = this;
switch (_that) {
case _WatchProvider():
return $default(_that.providerId,_that.providerName,_that.logoPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? providerId,  String providerName,  String? logoPath)?  $default,) {final _that = this;
switch (_that) {
case _WatchProvider() when $default != null:
return $default(_that.providerId,_that.providerName,_that.logoPath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WatchProvider implements WatchProvider {
  const _WatchProvider({this.providerId, required this.providerName, this.logoPath});
  factory _WatchProvider.fromJson(Map<String, dynamic> json) => _$WatchProviderFromJson(json);

@override final  int? providerId;
@override final  String providerName;
@override final  String? logoPath;

/// Create a copy of WatchProvider
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WatchProviderCopyWith<_WatchProvider> get copyWith => __$WatchProviderCopyWithImpl<_WatchProvider>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WatchProviderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WatchProvider&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.logoPath, logoPath) || other.logoPath == logoPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,providerId,providerName,logoPath);

@override
String toString() {
  return 'WatchProvider(providerId: $providerId, providerName: $providerName, logoPath: $logoPath)';
}


}

/// @nodoc
abstract mixin class _$WatchProviderCopyWith<$Res> implements $WatchProviderCopyWith<$Res> {
  factory _$WatchProviderCopyWith(_WatchProvider value, $Res Function(_WatchProvider) _then) = __$WatchProviderCopyWithImpl;
@override @useResult
$Res call({
 int? providerId, String providerName, String? logoPath
});




}
/// @nodoc
class __$WatchProviderCopyWithImpl<$Res>
    implements _$WatchProviderCopyWith<$Res> {
  __$WatchProviderCopyWithImpl(this._self, this._then);

  final _WatchProvider _self;
  final $Res Function(_WatchProvider) _then;

/// Create a copy of WatchProvider
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? providerId = freezed,Object? providerName = null,Object? logoPath = freezed,}) {
  return _then(_WatchProvider(
providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as int?,providerName: null == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String,logoPath: freezed == logoPath ? _self.logoPath : logoPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$WatchProvidersResponse {

 String get movieId; List<WatchProvider> get streaming; List<WatchProvider> get rent; List<WatchProvider> get buy;
/// Create a copy of WatchProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchProvidersResponseCopyWith<WatchProvidersResponse> get copyWith => _$WatchProvidersResponseCopyWithImpl<WatchProvidersResponse>(this as WatchProvidersResponse, _$identity);

  /// Serializes this WatchProvidersResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchProvidersResponse&&(identical(other.movieId, movieId) || other.movieId == movieId)&&const DeepCollectionEquality().equals(other.streaming, streaming)&&const DeepCollectionEquality().equals(other.rent, rent)&&const DeepCollectionEquality().equals(other.buy, buy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,movieId,const DeepCollectionEquality().hash(streaming),const DeepCollectionEquality().hash(rent),const DeepCollectionEquality().hash(buy));

@override
String toString() {
  return 'WatchProvidersResponse(movieId: $movieId, streaming: $streaming, rent: $rent, buy: $buy)';
}


}

/// @nodoc
abstract mixin class $WatchProvidersResponseCopyWith<$Res>  {
  factory $WatchProvidersResponseCopyWith(WatchProvidersResponse value, $Res Function(WatchProvidersResponse) _then) = _$WatchProvidersResponseCopyWithImpl;
@useResult
$Res call({
 String movieId, List<WatchProvider> streaming, List<WatchProvider> rent, List<WatchProvider> buy
});




}
/// @nodoc
class _$WatchProvidersResponseCopyWithImpl<$Res>
    implements $WatchProvidersResponseCopyWith<$Res> {
  _$WatchProvidersResponseCopyWithImpl(this._self, this._then);

  final WatchProvidersResponse _self;
  final $Res Function(WatchProvidersResponse) _then;

/// Create a copy of WatchProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? movieId = null,Object? streaming = null,Object? rent = null,Object? buy = null,}) {
  return _then(_self.copyWith(
movieId: null == movieId ? _self.movieId : movieId // ignore: cast_nullable_to_non_nullable
as String,streaming: null == streaming ? _self.streaming : streaming // ignore: cast_nullable_to_non_nullable
as List<WatchProvider>,rent: null == rent ? _self.rent : rent // ignore: cast_nullable_to_non_nullable
as List<WatchProvider>,buy: null == buy ? _self.buy : buy // ignore: cast_nullable_to_non_nullable
as List<WatchProvider>,
  ));
}

}


/// Adds pattern-matching-related methods to [WatchProvidersResponse].
extension WatchProvidersResponsePatterns on WatchProvidersResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WatchProvidersResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WatchProvidersResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WatchProvidersResponse value)  $default,){
final _that = this;
switch (_that) {
case _WatchProvidersResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WatchProvidersResponse value)?  $default,){
final _that = this;
switch (_that) {
case _WatchProvidersResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String movieId,  List<WatchProvider> streaming,  List<WatchProvider> rent,  List<WatchProvider> buy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WatchProvidersResponse() when $default != null:
return $default(_that.movieId,_that.streaming,_that.rent,_that.buy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String movieId,  List<WatchProvider> streaming,  List<WatchProvider> rent,  List<WatchProvider> buy)  $default,) {final _that = this;
switch (_that) {
case _WatchProvidersResponse():
return $default(_that.movieId,_that.streaming,_that.rent,_that.buy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String movieId,  List<WatchProvider> streaming,  List<WatchProvider> rent,  List<WatchProvider> buy)?  $default,) {final _that = this;
switch (_that) {
case _WatchProvidersResponse() when $default != null:
return $default(_that.movieId,_that.streaming,_that.rent,_that.buy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WatchProvidersResponse implements WatchProvidersResponse {
  const _WatchProvidersResponse({required this.movieId, final  List<WatchProvider> streaming = const [], final  List<WatchProvider> rent = const [], final  List<WatchProvider> buy = const []}): _streaming = streaming,_rent = rent,_buy = buy;
  factory _WatchProvidersResponse.fromJson(Map<String, dynamic> json) => _$WatchProvidersResponseFromJson(json);

@override final  String movieId;
 final  List<WatchProvider> _streaming;
@override@JsonKey() List<WatchProvider> get streaming {
  if (_streaming is EqualUnmodifiableListView) return _streaming;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_streaming);
}

 final  List<WatchProvider> _rent;
@override@JsonKey() List<WatchProvider> get rent {
  if (_rent is EqualUnmodifiableListView) return _rent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rent);
}

 final  List<WatchProvider> _buy;
@override@JsonKey() List<WatchProvider> get buy {
  if (_buy is EqualUnmodifiableListView) return _buy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_buy);
}


/// Create a copy of WatchProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WatchProvidersResponseCopyWith<_WatchProvidersResponse> get copyWith => __$WatchProvidersResponseCopyWithImpl<_WatchProvidersResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WatchProvidersResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WatchProvidersResponse&&(identical(other.movieId, movieId) || other.movieId == movieId)&&const DeepCollectionEquality().equals(other._streaming, _streaming)&&const DeepCollectionEquality().equals(other._rent, _rent)&&const DeepCollectionEquality().equals(other._buy, _buy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,movieId,const DeepCollectionEquality().hash(_streaming),const DeepCollectionEquality().hash(_rent),const DeepCollectionEquality().hash(_buy));

@override
String toString() {
  return 'WatchProvidersResponse(movieId: $movieId, streaming: $streaming, rent: $rent, buy: $buy)';
}


}

/// @nodoc
abstract mixin class _$WatchProvidersResponseCopyWith<$Res> implements $WatchProvidersResponseCopyWith<$Res> {
  factory _$WatchProvidersResponseCopyWith(_WatchProvidersResponse value, $Res Function(_WatchProvidersResponse) _then) = __$WatchProvidersResponseCopyWithImpl;
@override @useResult
$Res call({
 String movieId, List<WatchProvider> streaming, List<WatchProvider> rent, List<WatchProvider> buy
});




}
/// @nodoc
class __$WatchProvidersResponseCopyWithImpl<$Res>
    implements _$WatchProvidersResponseCopyWith<$Res> {
  __$WatchProvidersResponseCopyWithImpl(this._self, this._then);

  final _WatchProvidersResponse _self;
  final $Res Function(_WatchProvidersResponse) _then;

/// Create a copy of WatchProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? movieId = null,Object? streaming = null,Object? rent = null,Object? buy = null,}) {
  return _then(_WatchProvidersResponse(
movieId: null == movieId ? _self.movieId : movieId // ignore: cast_nullable_to_non_nullable
as String,streaming: null == streaming ? _self._streaming : streaming // ignore: cast_nullable_to_non_nullable
as List<WatchProvider>,rent: null == rent ? _self._rent : rent // ignore: cast_nullable_to_non_nullable
as List<WatchProvider>,buy: null == buy ? _self._buy : buy // ignore: cast_nullable_to_non_nullable
as List<WatchProvider>,
  ));
}


}

// dart format on
