// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ImageAsset {

 String get url; int? get width; int? get height; double? get aspectRatio; String? get language;
/// Create a copy of ImageAsset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<ImageAsset> get copyWith => _$ImageAssetCopyWithImpl<ImageAsset>(this as ImageAsset, _$identity);

  /// Serializes this ImageAsset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageAsset&&(identical(other.url, url) || other.url == url)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.aspectRatio, aspectRatio) || other.aspectRatio == aspectRatio)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,width,height,aspectRatio,language);

@override
String toString() {
  return 'ImageAsset(url: $url, width: $width, height: $height, aspectRatio: $aspectRatio, language: $language)';
}


}

/// @nodoc
abstract mixin class $ImageAssetCopyWith<$Res>  {
  factory $ImageAssetCopyWith(ImageAsset value, $Res Function(ImageAsset) _then) = _$ImageAssetCopyWithImpl;
@useResult
$Res call({
 String url, int? width, int? height, double? aspectRatio, String? language
});




}
/// @nodoc
class _$ImageAssetCopyWithImpl<$Res>
    implements $ImageAssetCopyWith<$Res> {
  _$ImageAssetCopyWithImpl(this._self, this._then);

  final ImageAsset _self;
  final $Res Function(ImageAsset) _then;

/// Create a copy of ImageAsset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? width = freezed,Object? height = freezed,Object? aspectRatio = freezed,Object? language = freezed,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,aspectRatio: freezed == aspectRatio ? _self.aspectRatio : aspectRatio // ignore: cast_nullable_to_non_nullable
as double?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ImageAsset].
extension ImageAssetPatterns on ImageAsset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageAsset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageAsset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageAsset value)  $default,){
final _that = this;
switch (_that) {
case _ImageAsset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageAsset value)?  $default,){
final _that = this;
switch (_that) {
case _ImageAsset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  int? width,  int? height,  double? aspectRatio,  String? language)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImageAsset() when $default != null:
return $default(_that.url,_that.width,_that.height,_that.aspectRatio,_that.language);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  int? width,  int? height,  double? aspectRatio,  String? language)  $default,) {final _that = this;
switch (_that) {
case _ImageAsset():
return $default(_that.url,_that.width,_that.height,_that.aspectRatio,_that.language);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  int? width,  int? height,  double? aspectRatio,  String? language)?  $default,) {final _that = this;
switch (_that) {
case _ImageAsset() when $default != null:
return $default(_that.url,_that.width,_that.height,_that.aspectRatio,_that.language);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ImageAsset implements ImageAsset {
  const _ImageAsset({required this.url, this.width, this.height, this.aspectRatio, this.language});
  factory _ImageAsset.fromJson(Map<String, dynamic> json) => _$ImageAssetFromJson(json);

@override final  String url;
@override final  int? width;
@override final  int? height;
@override final  double? aspectRatio;
@override final  String? language;

/// Create a copy of ImageAsset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageAssetCopyWith<_ImageAsset> get copyWith => __$ImageAssetCopyWithImpl<_ImageAsset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImageAssetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageAsset&&(identical(other.url, url) || other.url == url)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.aspectRatio, aspectRatio) || other.aspectRatio == aspectRatio)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,width,height,aspectRatio,language);

@override
String toString() {
  return 'ImageAsset(url: $url, width: $width, height: $height, aspectRatio: $aspectRatio, language: $language)';
}


}

/// @nodoc
abstract mixin class _$ImageAssetCopyWith<$Res> implements $ImageAssetCopyWith<$Res> {
  factory _$ImageAssetCopyWith(_ImageAsset value, $Res Function(_ImageAsset) _then) = __$ImageAssetCopyWithImpl;
@override @useResult
$Res call({
 String url, int? width, int? height, double? aspectRatio, String? language
});




}
/// @nodoc
class __$ImageAssetCopyWithImpl<$Res>
    implements _$ImageAssetCopyWith<$Res> {
  __$ImageAssetCopyWithImpl(this._self, this._then);

  final _ImageAsset _self;
  final $Res Function(_ImageAsset) _then;

/// Create a copy of ImageAsset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? width = freezed,Object? height = freezed,Object? aspectRatio = freezed,Object? language = freezed,}) {
  return _then(_ImageAsset(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int?,aspectRatio: freezed == aspectRatio ? _self.aspectRatio : aspectRatio // ignore: cast_nullable_to_non_nullable
as double?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Genre {

 int? get id; String get name;
/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenreCopyWith<Genre> get copyWith => _$GenreCopyWithImpl<Genre>(this as Genre, _$identity);

  /// Serializes this Genre to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Genre&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'Genre(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $GenreCopyWith<$Res>  {
  factory $GenreCopyWith(Genre value, $Res Function(Genre) _then) = _$GenreCopyWithImpl;
@useResult
$Res call({
 int? id, String name
});




}
/// @nodoc
class _$GenreCopyWithImpl<$Res>
    implements $GenreCopyWith<$Res> {
  _$GenreCopyWithImpl(this._self, this._then);

  final Genre _self;
  final $Res Function(Genre) _then;

/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Genre].
extension GenrePatterns on Genre {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Genre value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Genre() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Genre value)  $default,){
final _that = this;
switch (_that) {
case _Genre():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Genre value)?  $default,){
final _that = this;
switch (_that) {
case _Genre() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Genre() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String name)  $default,) {final _that = this;
switch (_that) {
case _Genre():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _Genre() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Genre implements Genre {
  const _Genre({this.id, required this.name});
  factory _Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);

@override final  int? id;
@override final  String name;

/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GenreCopyWith<_Genre> get copyWith => __$GenreCopyWithImpl<_Genre>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GenreToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Genre&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'Genre(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$GenreCopyWith<$Res> implements $GenreCopyWith<$Res> {
  factory _$GenreCopyWith(_Genre value, $Res Function(_Genre) _then) = __$GenreCopyWithImpl;
@override @useResult
$Res call({
 int? id, String name
});




}
/// @nodoc
class __$GenreCopyWithImpl<$Res>
    implements _$GenreCopyWith<$Res> {
  __$GenreCopyWithImpl(this._self, this._then);

  final _Genre _self;
  final $Res Function(_Genre) _then;

/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,}) {
  return _then(_Genre(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MediaNested {

 String get id; String get title; String get name; int? get year; String? get overview; String? get posterPath; String? get backdropPath; double? get rating; List<Genre> get genres;
/// Create a copy of MediaNested
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaNestedCopyWith<MediaNested> get copyWith => _$MediaNestedCopyWithImpl<MediaNested>(this as MediaNested, _$identity);

  /// Serializes this MediaNested to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaNested&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.name, name) || other.name == name)&&(identical(other.year, year) || other.year == year)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.genres, genres));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,name,year,overview,posterPath,backdropPath,rating,const DeepCollectionEquality().hash(genres));

@override
String toString() {
  return 'MediaNested(id: $id, title: $title, name: $name, year: $year, overview: $overview, posterPath: $posterPath, backdropPath: $backdropPath, rating: $rating, genres: $genres)';
}


}

/// @nodoc
abstract mixin class $MediaNestedCopyWith<$Res>  {
  factory $MediaNestedCopyWith(MediaNested value, $Res Function(MediaNested) _then) = _$MediaNestedCopyWithImpl;
@useResult
$Res call({
 String id, String title, String name, int? year, String? overview, String? posterPath, String? backdropPath, double? rating, List<Genre> genres
});




}
/// @nodoc
class _$MediaNestedCopyWithImpl<$Res>
    implements $MediaNestedCopyWith<$Res> {
  _$MediaNestedCopyWithImpl(this._self, this._then);

  final MediaNested _self;
  final $Res Function(MediaNested) _then;

/// Create a copy of MediaNested
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? name = null,Object? year = freezed,Object? overview = freezed,Object? posterPath = freezed,Object? backdropPath = freezed,Object? rating = freezed,Object? genres = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<Genre>,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaNested].
extension MediaNestedPatterns on MediaNested {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaNested value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaNested() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaNested value)  $default,){
final _that = this;
switch (_that) {
case _MediaNested():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaNested value)?  $default,){
final _that = this;
switch (_that) {
case _MediaNested() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String name,  int? year,  String? overview,  String? posterPath,  String? backdropPath,  double? rating,  List<Genre> genres)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaNested() when $default != null:
return $default(_that.id,_that.title,_that.name,_that.year,_that.overview,_that.posterPath,_that.backdropPath,_that.rating,_that.genres);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String name,  int? year,  String? overview,  String? posterPath,  String? backdropPath,  double? rating,  List<Genre> genres)  $default,) {final _that = this;
switch (_that) {
case _MediaNested():
return $default(_that.id,_that.title,_that.name,_that.year,_that.overview,_that.posterPath,_that.backdropPath,_that.rating,_that.genres);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String name,  int? year,  String? overview,  String? posterPath,  String? backdropPath,  double? rating,  List<Genre> genres)?  $default,) {final _that = this;
switch (_that) {
case _MediaNested() when $default != null:
return $default(_that.id,_that.title,_that.name,_that.year,_that.overview,_that.posterPath,_that.backdropPath,_that.rating,_that.genres);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaNested implements MediaNested {
  const _MediaNested({required this.id, required this.title, required this.name, this.year, this.overview, this.posterPath, this.backdropPath, this.rating, final  List<Genre> genres = const []}): _genres = genres;
  factory _MediaNested.fromJson(Map<String, dynamic> json) => _$MediaNestedFromJson(json);

@override final  String id;
@override final  String title;
@override final  String name;
@override final  int? year;
@override final  String? overview;
@override final  String? posterPath;
@override final  String? backdropPath;
@override final  double? rating;
 final  List<Genre> _genres;
@override@JsonKey() List<Genre> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}


/// Create a copy of MediaNested
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaNestedCopyWith<_MediaNested> get copyWith => __$MediaNestedCopyWithImpl<_MediaNested>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaNestedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaNested&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.name, name) || other.name == name)&&(identical(other.year, year) || other.year == year)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other._genres, _genres));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,name,year,overview,posterPath,backdropPath,rating,const DeepCollectionEquality().hash(_genres));

@override
String toString() {
  return 'MediaNested(id: $id, title: $title, name: $name, year: $year, overview: $overview, posterPath: $posterPath, backdropPath: $backdropPath, rating: $rating, genres: $genres)';
}


}

/// @nodoc
abstract mixin class _$MediaNestedCopyWith<$Res> implements $MediaNestedCopyWith<$Res> {
  factory _$MediaNestedCopyWith(_MediaNested value, $Res Function(_MediaNested) _then) = __$MediaNestedCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String name, int? year, String? overview, String? posterPath, String? backdropPath, double? rating, List<Genre> genres
});




}
/// @nodoc
class __$MediaNestedCopyWithImpl<$Res>
    implements _$MediaNestedCopyWith<$Res> {
  __$MediaNestedCopyWithImpl(this._self, this._then);

  final _MediaNested _self;
  final $Res Function(_MediaNested) _then;

/// Create a copy of MediaNested
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? name = null,Object? year = freezed,Object? overview = freezed,Object? posterPath = freezed,Object? backdropPath = freezed,Object? rating = freezed,Object? genres = null,}) {
  return _then(_MediaNested(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<Genre>,
  ));
}


}


/// @nodoc
mixin _$MediaItem {

 String get id; String get title; String get type; String get sourceTag; int? get year; String? get overview; ImageAsset? get poster; String? get license; double? get rating; List<String> get genres; String? get originCountry; String? get externalUrl; Map<String, dynamic> get extra; String? get posterPath; String? get backdropPath; String? get tmdbId; String? get traktId; MediaNested get media;
/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaItemCopyWith<MediaItem> get copyWith => _$MediaItemCopyWithImpl<MediaItem>(this as MediaItem, _$identity);

  /// Serializes this MediaItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.sourceTag, sourceTag) || other.sourceTag == sourceTag)&&(identical(other.year, year) || other.year == year)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.poster, poster) || other.poster == poster)&&(identical(other.license, license) || other.license == license)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.genres, genres)&&(identical(other.originCountry, originCountry) || other.originCountry == originCountry)&&(identical(other.externalUrl, externalUrl) || other.externalUrl == externalUrl)&&const DeepCollectionEquality().equals(other.extra, extra)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.traktId, traktId) || other.traktId == traktId)&&(identical(other.media, media) || other.media == media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,type,sourceTag,year,overview,poster,license,rating,const DeepCollectionEquality().hash(genres),originCountry,externalUrl,const DeepCollectionEquality().hash(extra),posterPath,backdropPath,tmdbId,traktId,media);

@override
String toString() {
  return 'MediaItem(id: $id, title: $title, type: $type, sourceTag: $sourceTag, year: $year, overview: $overview, poster: $poster, license: $license, rating: $rating, genres: $genres, originCountry: $originCountry, externalUrl: $externalUrl, extra: $extra, posterPath: $posterPath, backdropPath: $backdropPath, tmdbId: $tmdbId, traktId: $traktId, media: $media)';
}


}

/// @nodoc
abstract mixin class $MediaItemCopyWith<$Res>  {
  factory $MediaItemCopyWith(MediaItem value, $Res Function(MediaItem) _then) = _$MediaItemCopyWithImpl;
@useResult
$Res call({
 String id, String title, String type, String sourceTag, int? year, String? overview, ImageAsset? poster, String? license, double? rating, List<String> genres, String? originCountry, String? externalUrl, Map<String, dynamic> extra, String? posterPath, String? backdropPath, String? tmdbId, String? traktId, MediaNested media
});


$ImageAssetCopyWith<$Res>? get poster;$MediaNestedCopyWith<$Res> get media;

}
/// @nodoc
class _$MediaItemCopyWithImpl<$Res>
    implements $MediaItemCopyWith<$Res> {
  _$MediaItemCopyWithImpl(this._self, this._then);

  final MediaItem _self;
  final $Res Function(MediaItem) _then;

/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? type = null,Object? sourceTag = null,Object? year = freezed,Object? overview = freezed,Object? poster = freezed,Object? license = freezed,Object? rating = freezed,Object? genres = null,Object? originCountry = freezed,Object? externalUrl = freezed,Object? extra = null,Object? posterPath = freezed,Object? backdropPath = freezed,Object? tmdbId = freezed,Object? traktId = freezed,Object? media = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,sourceTag: null == sourceTag ? _self.sourceTag : sourceTag // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,poster: freezed == poster ? _self.poster : poster // ignore: cast_nullable_to_non_nullable
as ImageAsset?,license: freezed == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,originCountry: freezed == originCountry ? _self.originCountry : originCountry // ignore: cast_nullable_to_non_nullable
as String?,externalUrl: freezed == externalUrl ? _self.externalUrl : externalUrl // ignore: cast_nullable_to_non_nullable
as String?,extra: null == extra ? _self.extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,traktId: freezed == traktId ? _self.traktId : traktId // ignore: cast_nullable_to_non_nullable
as String?,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as MediaNested,
  ));
}
/// Create a copy of MediaItem
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
}/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaNestedCopyWith<$Res> get media {
  
  return $MediaNestedCopyWith<$Res>(_self.media, (value) {
    return _then(_self.copyWith(media: value));
  });
}
}


/// Adds pattern-matching-related methods to [MediaItem].
extension MediaItemPatterns on MediaItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaItem value)  $default,){
final _that = this;
switch (_that) {
case _MediaItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaItem value)?  $default,){
final _that = this;
switch (_that) {
case _MediaItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String type,  String sourceTag,  int? year,  String? overview,  ImageAsset? poster,  String? license,  double? rating,  List<String> genres,  String? originCountry,  String? externalUrl,  Map<String, dynamic> extra,  String? posterPath,  String? backdropPath,  String? tmdbId,  String? traktId,  MediaNested media)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaItem() when $default != null:
return $default(_that.id,_that.title,_that.type,_that.sourceTag,_that.year,_that.overview,_that.poster,_that.license,_that.rating,_that.genres,_that.originCountry,_that.externalUrl,_that.extra,_that.posterPath,_that.backdropPath,_that.tmdbId,_that.traktId,_that.media);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String type,  String sourceTag,  int? year,  String? overview,  ImageAsset? poster,  String? license,  double? rating,  List<String> genres,  String? originCountry,  String? externalUrl,  Map<String, dynamic> extra,  String? posterPath,  String? backdropPath,  String? tmdbId,  String? traktId,  MediaNested media)  $default,) {final _that = this;
switch (_that) {
case _MediaItem():
return $default(_that.id,_that.title,_that.type,_that.sourceTag,_that.year,_that.overview,_that.poster,_that.license,_that.rating,_that.genres,_that.originCountry,_that.externalUrl,_that.extra,_that.posterPath,_that.backdropPath,_that.tmdbId,_that.traktId,_that.media);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String type,  String sourceTag,  int? year,  String? overview,  ImageAsset? poster,  String? license,  double? rating,  List<String> genres,  String? originCountry,  String? externalUrl,  Map<String, dynamic> extra,  String? posterPath,  String? backdropPath,  String? tmdbId,  String? traktId,  MediaNested media)?  $default,) {final _that = this;
switch (_that) {
case _MediaItem() when $default != null:
return $default(_that.id,_that.title,_that.type,_that.sourceTag,_that.year,_that.overview,_that.poster,_that.license,_that.rating,_that.genres,_that.originCountry,_that.externalUrl,_that.extra,_that.posterPath,_that.backdropPath,_that.tmdbId,_that.traktId,_that.media);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaItem implements MediaItem {
  const _MediaItem({required this.id, required this.title, required this.type, required this.sourceTag, this.year, this.overview, this.poster, this.license, this.rating, final  List<String> genres = const [], this.originCountry, this.externalUrl, final  Map<String, dynamic> extra = const {}, this.posterPath, this.backdropPath, this.tmdbId, this.traktId, required this.media}): _genres = genres,_extra = extra;
  factory _MediaItem.fromJson(Map<String, dynamic> json) => _$MediaItemFromJson(json);

@override final  String id;
@override final  String title;
@override final  String type;
@override final  String sourceTag;
@override final  int? year;
@override final  String? overview;
@override final  ImageAsset? poster;
@override final  String? license;
@override final  double? rating;
 final  List<String> _genres;
@override@JsonKey() List<String> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

@override final  String? originCountry;
@override final  String? externalUrl;
 final  Map<String, dynamic> _extra;
@override@JsonKey() Map<String, dynamic> get extra {
  if (_extra is EqualUnmodifiableMapView) return _extra;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extra);
}

@override final  String? posterPath;
@override final  String? backdropPath;
@override final  String? tmdbId;
@override final  String? traktId;
@override final  MediaNested media;

/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaItemCopyWith<_MediaItem> get copyWith => __$MediaItemCopyWithImpl<_MediaItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.sourceTag, sourceTag) || other.sourceTag == sourceTag)&&(identical(other.year, year) || other.year == year)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.poster, poster) || other.poster == poster)&&(identical(other.license, license) || other.license == license)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other._genres, _genres)&&(identical(other.originCountry, originCountry) || other.originCountry == originCountry)&&(identical(other.externalUrl, externalUrl) || other.externalUrl == externalUrl)&&const DeepCollectionEquality().equals(other._extra, _extra)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.traktId, traktId) || other.traktId == traktId)&&(identical(other.media, media) || other.media == media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,type,sourceTag,year,overview,poster,license,rating,const DeepCollectionEquality().hash(_genres),originCountry,externalUrl,const DeepCollectionEquality().hash(_extra),posterPath,backdropPath,tmdbId,traktId,media);

@override
String toString() {
  return 'MediaItem(id: $id, title: $title, type: $type, sourceTag: $sourceTag, year: $year, overview: $overview, poster: $poster, license: $license, rating: $rating, genres: $genres, originCountry: $originCountry, externalUrl: $externalUrl, extra: $extra, posterPath: $posterPath, backdropPath: $backdropPath, tmdbId: $tmdbId, traktId: $traktId, media: $media)';
}


}

/// @nodoc
abstract mixin class _$MediaItemCopyWith<$Res> implements $MediaItemCopyWith<$Res> {
  factory _$MediaItemCopyWith(_MediaItem value, $Res Function(_MediaItem) _then) = __$MediaItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String type, String sourceTag, int? year, String? overview, ImageAsset? poster, String? license, double? rating, List<String> genres, String? originCountry, String? externalUrl, Map<String, dynamic> extra, String? posterPath, String? backdropPath, String? tmdbId, String? traktId, MediaNested media
});


@override $ImageAssetCopyWith<$Res>? get poster;@override $MediaNestedCopyWith<$Res> get media;

}
/// @nodoc
class __$MediaItemCopyWithImpl<$Res>
    implements _$MediaItemCopyWith<$Res> {
  __$MediaItemCopyWithImpl(this._self, this._then);

  final _MediaItem _self;
  final $Res Function(_MediaItem) _then;

/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? type = null,Object? sourceTag = null,Object? year = freezed,Object? overview = freezed,Object? poster = freezed,Object? license = freezed,Object? rating = freezed,Object? genres = null,Object? originCountry = freezed,Object? externalUrl = freezed,Object? extra = null,Object? posterPath = freezed,Object? backdropPath = freezed,Object? tmdbId = freezed,Object? traktId = freezed,Object? media = null,}) {
  return _then(_MediaItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,sourceTag: null == sourceTag ? _self.sourceTag : sourceTag // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,poster: freezed == poster ? _self.poster : poster // ignore: cast_nullable_to_non_nullable
as ImageAsset?,license: freezed == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,originCountry: freezed == originCountry ? _self.originCountry : originCountry // ignore: cast_nullable_to_non_nullable
as String?,externalUrl: freezed == externalUrl ? _self.externalUrl : externalUrl // ignore: cast_nullable_to_non_nullable
as String?,extra: null == extra ? _self._extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,traktId: freezed == traktId ? _self.traktId : traktId // ignore: cast_nullable_to_non_nullable
as String?,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as MediaNested,
  ));
}

/// Create a copy of MediaItem
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
}/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaNestedCopyWith<$Res> get media {
  
  return $MediaNestedCopyWith<$Res>(_self.media, (value) {
    return _then(_self.copyWith(media: value));
  });
}
}


/// @nodoc
mixin _$CastMember {

 Object? get id; String get name; String? get character; String? get profilePath; ImageAsset? get profileImage; int? get order;
/// Create a copy of CastMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CastMemberCopyWith<CastMember> get copyWith => _$CastMemberCopyWithImpl<CastMember>(this as CastMember, _$identity);

  /// Serializes this CastMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CastMember&&const DeepCollectionEquality().equals(other.id, id)&&(identical(other.name, name) || other.name == name)&&(identical(other.character, character) || other.character == character)&&(identical(other.profilePath, profilePath) || other.profilePath == profilePath)&&(identical(other.profileImage, profileImage) || other.profileImage == profileImage)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(id),name,character,profilePath,profileImage,order);

@override
String toString() {
  return 'CastMember(id: $id, name: $name, character: $character, profilePath: $profilePath, profileImage: $profileImage, order: $order)';
}


}

/// @nodoc
abstract mixin class $CastMemberCopyWith<$Res>  {
  factory $CastMemberCopyWith(CastMember value, $Res Function(CastMember) _then) = _$CastMemberCopyWithImpl;
@useResult
$Res call({
 Object? id, String name, String? character, String? profilePath, ImageAsset? profileImage, int? order
});


$ImageAssetCopyWith<$Res>? get profileImage;

}
/// @nodoc
class _$CastMemberCopyWithImpl<$Res>
    implements $CastMemberCopyWith<$Res> {
  _$CastMemberCopyWithImpl(this._self, this._then);

  final CastMember _self;
  final $Res Function(CastMember) _then;

/// Create a copy of CastMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,Object? character = freezed,Object? profilePath = freezed,Object? profileImage = freezed,Object? order = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id ,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,character: freezed == character ? _self.character : character // ignore: cast_nullable_to_non_nullable
as String?,profilePath: freezed == profilePath ? _self.profilePath : profilePath // ignore: cast_nullable_to_non_nullable
as String?,profileImage: freezed == profileImage ? _self.profileImage : profileImage // ignore: cast_nullable_to_non_nullable
as ImageAsset?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of CastMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get profileImage {
    if (_self.profileImage == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.profileImage!, (value) {
    return _then(_self.copyWith(profileImage: value));
  });
}
}


/// Adds pattern-matching-related methods to [CastMember].
extension CastMemberPatterns on CastMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CastMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CastMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CastMember value)  $default,){
final _that = this;
switch (_that) {
case _CastMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CastMember value)?  $default,){
final _that = this;
switch (_that) {
case _CastMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object? id,  String name,  String? character,  String? profilePath,  ImageAsset? profileImage,  int? order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CastMember() when $default != null:
return $default(_that.id,_that.name,_that.character,_that.profilePath,_that.profileImage,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object? id,  String name,  String? character,  String? profilePath,  ImageAsset? profileImage,  int? order)  $default,) {final _that = this;
switch (_that) {
case _CastMember():
return $default(_that.id,_that.name,_that.character,_that.profilePath,_that.profileImage,_that.order);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object? id,  String name,  String? character,  String? profilePath,  ImageAsset? profileImage,  int? order)?  $default,) {final _that = this;
switch (_that) {
case _CastMember() when $default != null:
return $default(_that.id,_that.name,_that.character,_that.profilePath,_that.profileImage,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CastMember implements CastMember {
  const _CastMember({this.id, required this.name, this.character, this.profilePath, this.profileImage, this.order});
  factory _CastMember.fromJson(Map<String, dynamic> json) => _$CastMemberFromJson(json);

@override final  Object? id;
@override final  String name;
@override final  String? character;
@override final  String? profilePath;
@override final  ImageAsset? profileImage;
@override final  int? order;

/// Create a copy of CastMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CastMemberCopyWith<_CastMember> get copyWith => __$CastMemberCopyWithImpl<_CastMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CastMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CastMember&&const DeepCollectionEquality().equals(other.id, id)&&(identical(other.name, name) || other.name == name)&&(identical(other.character, character) || other.character == character)&&(identical(other.profilePath, profilePath) || other.profilePath == profilePath)&&(identical(other.profileImage, profileImage) || other.profileImage == profileImage)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(id),name,character,profilePath,profileImage,order);

@override
String toString() {
  return 'CastMember(id: $id, name: $name, character: $character, profilePath: $profilePath, profileImage: $profileImage, order: $order)';
}


}

/// @nodoc
abstract mixin class _$CastMemberCopyWith<$Res> implements $CastMemberCopyWith<$Res> {
  factory _$CastMemberCopyWith(_CastMember value, $Res Function(_CastMember) _then) = __$CastMemberCopyWithImpl;
@override @useResult
$Res call({
 Object? id, String name, String? character, String? profilePath, ImageAsset? profileImage, int? order
});


@override $ImageAssetCopyWith<$Res>? get profileImage;

}
/// @nodoc
class __$CastMemberCopyWithImpl<$Res>
    implements _$CastMemberCopyWith<$Res> {
  __$CastMemberCopyWithImpl(this._self, this._then);

  final _CastMember _self;
  final $Res Function(_CastMember) _then;

/// Create a copy of CastMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,Object? character = freezed,Object? profilePath = freezed,Object? profileImage = freezed,Object? order = freezed,}) {
  return _then(_CastMember(
id: freezed == id ? _self.id : id ,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,character: freezed == character ? _self.character : character // ignore: cast_nullable_to_non_nullable
as String?,profilePath: freezed == profilePath ? _self.profilePath : profilePath // ignore: cast_nullable_to_non_nullable
as String?,profileImage: freezed == profileImage ? _self.profileImage : profileImage // ignore: cast_nullable_to_non_nullable
as ImageAsset?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of CastMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImageAssetCopyWith<$Res>? get profileImage {
    if (_self.profileImage == null) {
    return null;
  }

  return $ImageAssetCopyWith<$Res>(_self.profileImage!, (value) {
    return _then(_self.copyWith(profileImage: value));
  });
}
}


/// @nodoc
mixin _$Trailer {

 String get url; String? get quality; String? get mimeType; int? get sizeBytes; String? get license; List<dynamic> get captions; bool? get isDownload; String? get sourceTag;
/// Create a copy of Trailer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrailerCopyWith<Trailer> get copyWith => _$TrailerCopyWithImpl<Trailer>(this as Trailer, _$identity);

  /// Serializes this Trailer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Trailer&&(identical(other.url, url) || other.url == url)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.license, license) || other.license == license)&&const DeepCollectionEquality().equals(other.captions, captions)&&(identical(other.isDownload, isDownload) || other.isDownload == isDownload)&&(identical(other.sourceTag, sourceTag) || other.sourceTag == sourceTag));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,quality,mimeType,sizeBytes,license,const DeepCollectionEquality().hash(captions),isDownload,sourceTag);

@override
String toString() {
  return 'Trailer(url: $url, quality: $quality, mimeType: $mimeType, sizeBytes: $sizeBytes, license: $license, captions: $captions, isDownload: $isDownload, sourceTag: $sourceTag)';
}


}

/// @nodoc
abstract mixin class $TrailerCopyWith<$Res>  {
  factory $TrailerCopyWith(Trailer value, $Res Function(Trailer) _then) = _$TrailerCopyWithImpl;
@useResult
$Res call({
 String url, String? quality, String? mimeType, int? sizeBytes, String? license, List<dynamic> captions, bool? isDownload, String? sourceTag
});




}
/// @nodoc
class _$TrailerCopyWithImpl<$Res>
    implements $TrailerCopyWith<$Res> {
  _$TrailerCopyWithImpl(this._self, this._then);

  final Trailer _self;
  final $Res Function(Trailer) _then;

/// Create a copy of Trailer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? quality = freezed,Object? mimeType = freezed,Object? sizeBytes = freezed,Object? license = freezed,Object? captions = null,Object? isDownload = freezed,Object? sourceTag = freezed,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,quality: freezed == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,license: freezed == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as String?,captions: null == captions ? _self.captions : captions // ignore: cast_nullable_to_non_nullable
as List<dynamic>,isDownload: freezed == isDownload ? _self.isDownload : isDownload // ignore: cast_nullable_to_non_nullable
as bool?,sourceTag: freezed == sourceTag ? _self.sourceTag : sourceTag // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Trailer].
extension TrailerPatterns on Trailer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Trailer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Trailer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Trailer value)  $default,){
final _that = this;
switch (_that) {
case _Trailer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Trailer value)?  $default,){
final _that = this;
switch (_that) {
case _Trailer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String? quality,  String? mimeType,  int? sizeBytes,  String? license,  List<dynamic> captions,  bool? isDownload,  String? sourceTag)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Trailer() when $default != null:
return $default(_that.url,_that.quality,_that.mimeType,_that.sizeBytes,_that.license,_that.captions,_that.isDownload,_that.sourceTag);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String? quality,  String? mimeType,  int? sizeBytes,  String? license,  List<dynamic> captions,  bool? isDownload,  String? sourceTag)  $default,) {final _that = this;
switch (_that) {
case _Trailer():
return $default(_that.url,_that.quality,_that.mimeType,_that.sizeBytes,_that.license,_that.captions,_that.isDownload,_that.sourceTag);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String? quality,  String? mimeType,  int? sizeBytes,  String? license,  List<dynamic> captions,  bool? isDownload,  String? sourceTag)?  $default,) {final _that = this;
switch (_that) {
case _Trailer() when $default != null:
return $default(_that.url,_that.quality,_that.mimeType,_that.sizeBytes,_that.license,_that.captions,_that.isDownload,_that.sourceTag);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Trailer implements Trailer {
  const _Trailer({required this.url, this.quality, this.mimeType, this.sizeBytes, this.license, final  List<dynamic> captions = const [], this.isDownload, this.sourceTag}): _captions = captions;
  factory _Trailer.fromJson(Map<String, dynamic> json) => _$TrailerFromJson(json);

@override final  String url;
@override final  String? quality;
@override final  String? mimeType;
@override final  int? sizeBytes;
@override final  String? license;
 final  List<dynamic> _captions;
@override@JsonKey() List<dynamic> get captions {
  if (_captions is EqualUnmodifiableListView) return _captions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_captions);
}

@override final  bool? isDownload;
@override final  String? sourceTag;

/// Create a copy of Trailer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrailerCopyWith<_Trailer> get copyWith => __$TrailerCopyWithImpl<_Trailer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrailerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Trailer&&(identical(other.url, url) || other.url == url)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.license, license) || other.license == license)&&const DeepCollectionEquality().equals(other._captions, _captions)&&(identical(other.isDownload, isDownload) || other.isDownload == isDownload)&&(identical(other.sourceTag, sourceTag) || other.sourceTag == sourceTag));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,quality,mimeType,sizeBytes,license,const DeepCollectionEquality().hash(_captions),isDownload,sourceTag);

@override
String toString() {
  return 'Trailer(url: $url, quality: $quality, mimeType: $mimeType, sizeBytes: $sizeBytes, license: $license, captions: $captions, isDownload: $isDownload, sourceTag: $sourceTag)';
}


}

/// @nodoc
abstract mixin class _$TrailerCopyWith<$Res> implements $TrailerCopyWith<$Res> {
  factory _$TrailerCopyWith(_Trailer value, $Res Function(_Trailer) _then) = __$TrailerCopyWithImpl;
@override @useResult
$Res call({
 String url, String? quality, String? mimeType, int? sizeBytes, String? license, List<dynamic> captions, bool? isDownload, String? sourceTag
});




}
/// @nodoc
class __$TrailerCopyWithImpl<$Res>
    implements _$TrailerCopyWith<$Res> {
  __$TrailerCopyWithImpl(this._self, this._then);

  final _Trailer _self;
  final $Res Function(_Trailer) _then;

/// Create a copy of Trailer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? quality = freezed,Object? mimeType = freezed,Object? sizeBytes = freezed,Object? license = freezed,Object? captions = null,Object? isDownload = freezed,Object? sourceTag = freezed,}) {
  return _then(_Trailer(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,quality: freezed == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,license: freezed == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as String?,captions: null == captions ? _self._captions : captions // ignore: cast_nullable_to_non_nullable
as List<dynamic>,isDownload: freezed == isDownload ? _self.isDownload : isDownload // ignore: cast_nullable_to_non_nullable
as bool?,sourceTag: freezed == sourceTag ? _self.sourceTag : sourceTag // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
