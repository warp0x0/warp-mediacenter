// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'collection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserCollection {

 int get id; String get collectionType; String get tmdbId; String get type; String get title; int? get year; String? get overview; String? get posterPath; String? get backdropPath; double? get rating; int? get voteCount; List<String> get genres; String get addedAt;
/// Create a copy of UserCollection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCollectionCopyWith<UserCollection> get copyWith => _$UserCollectionCopyWithImpl<UserCollection>(this as UserCollection, _$identity);

  /// Serializes this UserCollection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserCollection&&(identical(other.id, id) || other.id == id)&&(identical(other.collectionType, collectionType) || other.collectionType == collectionType)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.year, year) || other.year == year)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&const DeepCollectionEquality().equals(other.genres, genres)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,collectionType,tmdbId,type,title,year,overview,posterPath,backdropPath,rating,voteCount,const DeepCollectionEquality().hash(genres),addedAt);

@override
String toString() {
  return 'UserCollection(id: $id, collectionType: $collectionType, tmdbId: $tmdbId, type: $type, title: $title, year: $year, overview: $overview, posterPath: $posterPath, backdropPath: $backdropPath, rating: $rating, voteCount: $voteCount, genres: $genres, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class $UserCollectionCopyWith<$Res>  {
  factory $UserCollectionCopyWith(UserCollection value, $Res Function(UserCollection) _then) = _$UserCollectionCopyWithImpl;
@useResult
$Res call({
 int id, String collectionType, String tmdbId, String type, String title, int? year, String? overview, String? posterPath, String? backdropPath, double? rating, int? voteCount, List<String> genres, String addedAt
});




}
/// @nodoc
class _$UserCollectionCopyWithImpl<$Res>
    implements $UserCollectionCopyWith<$Res> {
  _$UserCollectionCopyWithImpl(this._self, this._then);

  final UserCollection _self;
  final $Res Function(UserCollection) _then;

/// Create a copy of UserCollection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? collectionType = null,Object? tmdbId = null,Object? type = null,Object? title = null,Object? year = freezed,Object? overview = freezed,Object? posterPath = freezed,Object? backdropPath = freezed,Object? rating = freezed,Object? voteCount = freezed,Object? genres = null,Object? addedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,collectionType: null == collectionType ? _self.collectionType : collectionType // ignore: cast_nullable_to_non_nullable
as String,tmdbId: null == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,voteCount: freezed == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UserCollection].
extension UserCollectionPatterns on UserCollection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserCollection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserCollection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserCollection value)  $default,){
final _that = this;
switch (_that) {
case _UserCollection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserCollection value)?  $default,){
final _that = this;
switch (_that) {
case _UserCollection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String collectionType,  String tmdbId,  String type,  String title,  int? year,  String? overview,  String? posterPath,  String? backdropPath,  double? rating,  int? voteCount,  List<String> genres,  String addedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserCollection() when $default != null:
return $default(_that.id,_that.collectionType,_that.tmdbId,_that.type,_that.title,_that.year,_that.overview,_that.posterPath,_that.backdropPath,_that.rating,_that.voteCount,_that.genres,_that.addedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String collectionType,  String tmdbId,  String type,  String title,  int? year,  String? overview,  String? posterPath,  String? backdropPath,  double? rating,  int? voteCount,  List<String> genres,  String addedAt)  $default,) {final _that = this;
switch (_that) {
case _UserCollection():
return $default(_that.id,_that.collectionType,_that.tmdbId,_that.type,_that.title,_that.year,_that.overview,_that.posterPath,_that.backdropPath,_that.rating,_that.voteCount,_that.genres,_that.addedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String collectionType,  String tmdbId,  String type,  String title,  int? year,  String? overview,  String? posterPath,  String? backdropPath,  double? rating,  int? voteCount,  List<String> genres,  String addedAt)?  $default,) {final _that = this;
switch (_that) {
case _UserCollection() when $default != null:
return $default(_that.id,_that.collectionType,_that.tmdbId,_that.type,_that.title,_that.year,_that.overview,_that.posterPath,_that.backdropPath,_that.rating,_that.voteCount,_that.genres,_that.addedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserCollection implements UserCollection {
  const _UserCollection({required this.id, required this.collectionType, required this.tmdbId, required this.type, required this.title, this.year, this.overview, this.posterPath, this.backdropPath, this.rating, this.voteCount, final  List<String> genres = const [], required this.addedAt}): _genres = genres;
  factory _UserCollection.fromJson(Map<String, dynamic> json) => _$UserCollectionFromJson(json);

@override final  int id;
@override final  String collectionType;
@override final  String tmdbId;
@override final  String type;
@override final  String title;
@override final  int? year;
@override final  String? overview;
@override final  String? posterPath;
@override final  String? backdropPath;
@override final  double? rating;
@override final  int? voteCount;
 final  List<String> _genres;
@override@JsonKey() List<String> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

@override final  String addedAt;

/// Create a copy of UserCollection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCollectionCopyWith<_UserCollection> get copyWith => __$UserCollectionCopyWithImpl<_UserCollection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserCollectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserCollection&&(identical(other.id, id) || other.id == id)&&(identical(other.collectionType, collectionType) || other.collectionType == collectionType)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.year, year) || other.year == year)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&const DeepCollectionEquality().equals(other._genres, _genres)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,collectionType,tmdbId,type,title,year,overview,posterPath,backdropPath,rating,voteCount,const DeepCollectionEquality().hash(_genres),addedAt);

@override
String toString() {
  return 'UserCollection(id: $id, collectionType: $collectionType, tmdbId: $tmdbId, type: $type, title: $title, year: $year, overview: $overview, posterPath: $posterPath, backdropPath: $backdropPath, rating: $rating, voteCount: $voteCount, genres: $genres, addedAt: $addedAt)';
}


}

/// @nodoc
abstract mixin class _$UserCollectionCopyWith<$Res> implements $UserCollectionCopyWith<$Res> {
  factory _$UserCollectionCopyWith(_UserCollection value, $Res Function(_UserCollection) _then) = __$UserCollectionCopyWithImpl;
@override @useResult
$Res call({
 int id, String collectionType, String tmdbId, String type, String title, int? year, String? overview, String? posterPath, String? backdropPath, double? rating, int? voteCount, List<String> genres, String addedAt
});




}
/// @nodoc
class __$UserCollectionCopyWithImpl<$Res>
    implements _$UserCollectionCopyWith<$Res> {
  __$UserCollectionCopyWithImpl(this._self, this._then);

  final _UserCollection _self;
  final $Res Function(_UserCollection) _then;

/// Create a copy of UserCollection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? collectionType = null,Object? tmdbId = null,Object? type = null,Object? title = null,Object? year = freezed,Object? overview = freezed,Object? posterPath = freezed,Object? backdropPath = freezed,Object? rating = freezed,Object? voteCount = freezed,Object? genres = null,Object? addedAt = null,}) {
  return _then(_UserCollection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,collectionType: null == collectionType ? _self.collectionType : collectionType // ignore: cast_nullable_to_non_nullable
as String,tmdbId: null == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,voteCount: freezed == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CollectionResponse {

 String get collectionType; List<UserCollection> get items; int get count; int get page; int get limit;
/// Create a copy of CollectionResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionResponseCopyWith<CollectionResponse> get copyWith => _$CollectionResponseCopyWithImpl<CollectionResponse>(this as CollectionResponse, _$identity);

  /// Serializes this CollectionResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionResponse&&(identical(other.collectionType, collectionType) || other.collectionType == collectionType)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.count, count) || other.count == count)&&(identical(other.page, page) || other.page == page)&&(identical(other.limit, limit) || other.limit == limit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,collectionType,const DeepCollectionEquality().hash(items),count,page,limit);

@override
String toString() {
  return 'CollectionResponse(collectionType: $collectionType, items: $items, count: $count, page: $page, limit: $limit)';
}


}

/// @nodoc
abstract mixin class $CollectionResponseCopyWith<$Res>  {
  factory $CollectionResponseCopyWith(CollectionResponse value, $Res Function(CollectionResponse) _then) = _$CollectionResponseCopyWithImpl;
@useResult
$Res call({
 String collectionType, List<UserCollection> items, int count, int page, int limit
});




}
/// @nodoc
class _$CollectionResponseCopyWithImpl<$Res>
    implements $CollectionResponseCopyWith<$Res> {
  _$CollectionResponseCopyWithImpl(this._self, this._then);

  final CollectionResponse _self;
  final $Res Function(CollectionResponse) _then;

/// Create a copy of CollectionResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? collectionType = null,Object? items = null,Object? count = null,Object? page = null,Object? limit = null,}) {
  return _then(_self.copyWith(
collectionType: null == collectionType ? _self.collectionType : collectionType // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<UserCollection>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CollectionResponse].
extension CollectionResponsePatterns on CollectionResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionResponse value)  $default,){
final _that = this;
switch (_that) {
case _CollectionResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String collectionType,  List<UserCollection> items,  int count,  int page,  int limit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionResponse() when $default != null:
return $default(_that.collectionType,_that.items,_that.count,_that.page,_that.limit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String collectionType,  List<UserCollection> items,  int count,  int page,  int limit)  $default,) {final _that = this;
switch (_that) {
case _CollectionResponse():
return $default(_that.collectionType,_that.items,_that.count,_that.page,_that.limit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String collectionType,  List<UserCollection> items,  int count,  int page,  int limit)?  $default,) {final _that = this;
switch (_that) {
case _CollectionResponse() when $default != null:
return $default(_that.collectionType,_that.items,_that.count,_that.page,_that.limit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectionResponse implements CollectionResponse {
  const _CollectionResponse({required this.collectionType, required final  List<UserCollection> items, required this.count, required this.page, required this.limit}): _items = items;
  factory _CollectionResponse.fromJson(Map<String, dynamic> json) => _$CollectionResponseFromJson(json);

@override final  String collectionType;
 final  List<UserCollection> _items;
@override List<UserCollection> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int count;
@override final  int page;
@override final  int limit;

/// Create a copy of CollectionResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionResponseCopyWith<_CollectionResponse> get copyWith => __$CollectionResponseCopyWithImpl<_CollectionResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionResponse&&(identical(other.collectionType, collectionType) || other.collectionType == collectionType)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.count, count) || other.count == count)&&(identical(other.page, page) || other.page == page)&&(identical(other.limit, limit) || other.limit == limit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,collectionType,const DeepCollectionEquality().hash(_items),count,page,limit);

@override
String toString() {
  return 'CollectionResponse(collectionType: $collectionType, items: $items, count: $count, page: $page, limit: $limit)';
}


}

/// @nodoc
abstract mixin class _$CollectionResponseCopyWith<$Res> implements $CollectionResponseCopyWith<$Res> {
  factory _$CollectionResponseCopyWith(_CollectionResponse value, $Res Function(_CollectionResponse) _then) = __$CollectionResponseCopyWithImpl;
@override @useResult
$Res call({
 String collectionType, List<UserCollection> items, int count, int page, int limit
});




}
/// @nodoc
class __$CollectionResponseCopyWithImpl<$Res>
    implements _$CollectionResponseCopyWith<$Res> {
  __$CollectionResponseCopyWithImpl(this._self, this._then);

  final _CollectionResponse _self;
  final $Res Function(_CollectionResponse) _then;

/// Create a copy of CollectionResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? collectionType = null,Object? items = null,Object? count = null,Object? page = null,Object? limit = null,}) {
  return _then(_CollectionResponse(
collectionType: null == collectionType ? _self.collectionType : collectionType // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<UserCollection>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CollectionStatusResponse {

 String get tmdbId; bool get inCollection;
/// Create a copy of CollectionStatusResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionStatusResponseCopyWith<CollectionStatusResponse> get copyWith => _$CollectionStatusResponseCopyWithImpl<CollectionStatusResponse>(this as CollectionStatusResponse, _$identity);

  /// Serializes this CollectionStatusResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionStatusResponse&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.inCollection, inCollection) || other.inCollection == inCollection));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tmdbId,inCollection);

@override
String toString() {
  return 'CollectionStatusResponse(tmdbId: $tmdbId, inCollection: $inCollection)';
}


}

/// @nodoc
abstract mixin class $CollectionStatusResponseCopyWith<$Res>  {
  factory $CollectionStatusResponseCopyWith(CollectionStatusResponse value, $Res Function(CollectionStatusResponse) _then) = _$CollectionStatusResponseCopyWithImpl;
@useResult
$Res call({
 String tmdbId, bool inCollection
});




}
/// @nodoc
class _$CollectionStatusResponseCopyWithImpl<$Res>
    implements $CollectionStatusResponseCopyWith<$Res> {
  _$CollectionStatusResponseCopyWithImpl(this._self, this._then);

  final CollectionStatusResponse _self;
  final $Res Function(CollectionStatusResponse) _then;

/// Create a copy of CollectionStatusResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tmdbId = null,Object? inCollection = null,}) {
  return _then(_self.copyWith(
tmdbId: null == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String,inCollection: null == inCollection ? _self.inCollection : inCollection // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CollectionStatusResponse].
extension CollectionStatusResponsePatterns on CollectionStatusResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionStatusResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionStatusResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionStatusResponse value)  $default,){
final _that = this;
switch (_that) {
case _CollectionStatusResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionStatusResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionStatusResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tmdbId,  bool inCollection)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionStatusResponse() when $default != null:
return $default(_that.tmdbId,_that.inCollection);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tmdbId,  bool inCollection)  $default,) {final _that = this;
switch (_that) {
case _CollectionStatusResponse():
return $default(_that.tmdbId,_that.inCollection);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tmdbId,  bool inCollection)?  $default,) {final _that = this;
switch (_that) {
case _CollectionStatusResponse() when $default != null:
return $default(_that.tmdbId,_that.inCollection);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectionStatusResponse implements CollectionStatusResponse {
  const _CollectionStatusResponse({required this.tmdbId, required this.inCollection});
  factory _CollectionStatusResponse.fromJson(Map<String, dynamic> json) => _$CollectionStatusResponseFromJson(json);

@override final  String tmdbId;
@override final  bool inCollection;

/// Create a copy of CollectionStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionStatusResponseCopyWith<_CollectionStatusResponse> get copyWith => __$CollectionStatusResponseCopyWithImpl<_CollectionStatusResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionStatusResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionStatusResponse&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.inCollection, inCollection) || other.inCollection == inCollection));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tmdbId,inCollection);

@override
String toString() {
  return 'CollectionStatusResponse(tmdbId: $tmdbId, inCollection: $inCollection)';
}


}

/// @nodoc
abstract mixin class _$CollectionStatusResponseCopyWith<$Res> implements $CollectionStatusResponseCopyWith<$Res> {
  factory _$CollectionStatusResponseCopyWith(_CollectionStatusResponse value, $Res Function(_CollectionStatusResponse) _then) = __$CollectionStatusResponseCopyWithImpl;
@override @useResult
$Res call({
 String tmdbId, bool inCollection
});




}
/// @nodoc
class __$CollectionStatusResponseCopyWithImpl<$Res>
    implements _$CollectionStatusResponseCopyWith<$Res> {
  __$CollectionStatusResponseCopyWithImpl(this._self, this._then);

  final _CollectionStatusResponse _self;
  final $Res Function(_CollectionStatusResponse) _then;

/// Create a copy of CollectionStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tmdbId = null,Object? inCollection = null,}) {
  return _then(_CollectionStatusResponse(
tmdbId: null == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String,inCollection: null == inCollection ? _self.inCollection : inCollection // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$CollectionItemPayload {

 String get tmdbId; String get type; String get title; int? get year; String? get overview; String? get posterPath; String? get backdropPath; double? get rating; int? get voteCount; List<String> get genres;
/// Create a copy of CollectionItemPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionItemPayloadCopyWith<CollectionItemPayload> get copyWith => _$CollectionItemPayloadCopyWithImpl<CollectionItemPayload>(this as CollectionItemPayload, _$identity);

  /// Serializes this CollectionItemPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionItemPayload&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.year, year) || other.year == year)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&const DeepCollectionEquality().equals(other.genres, genres));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tmdbId,type,title,year,overview,posterPath,backdropPath,rating,voteCount,const DeepCollectionEquality().hash(genres));

@override
String toString() {
  return 'CollectionItemPayload(tmdbId: $tmdbId, type: $type, title: $title, year: $year, overview: $overview, posterPath: $posterPath, backdropPath: $backdropPath, rating: $rating, voteCount: $voteCount, genres: $genres)';
}


}

/// @nodoc
abstract mixin class $CollectionItemPayloadCopyWith<$Res>  {
  factory $CollectionItemPayloadCopyWith(CollectionItemPayload value, $Res Function(CollectionItemPayload) _then) = _$CollectionItemPayloadCopyWithImpl;
@useResult
$Res call({
 String tmdbId, String type, String title, int? year, String? overview, String? posterPath, String? backdropPath, double? rating, int? voteCount, List<String> genres
});




}
/// @nodoc
class _$CollectionItemPayloadCopyWithImpl<$Res>
    implements $CollectionItemPayloadCopyWith<$Res> {
  _$CollectionItemPayloadCopyWithImpl(this._self, this._then);

  final CollectionItemPayload _self;
  final $Res Function(CollectionItemPayload) _then;

/// Create a copy of CollectionItemPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tmdbId = null,Object? type = null,Object? title = null,Object? year = freezed,Object? overview = freezed,Object? posterPath = freezed,Object? backdropPath = freezed,Object? rating = freezed,Object? voteCount = freezed,Object? genres = null,}) {
  return _then(_self.copyWith(
tmdbId: null == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,voteCount: freezed == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CollectionItemPayload].
extension CollectionItemPayloadPatterns on CollectionItemPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CollectionItemPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CollectionItemPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CollectionItemPayload value)  $default,){
final _that = this;
switch (_that) {
case _CollectionItemPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CollectionItemPayload value)?  $default,){
final _that = this;
switch (_that) {
case _CollectionItemPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tmdbId,  String type,  String title,  int? year,  String? overview,  String? posterPath,  String? backdropPath,  double? rating,  int? voteCount,  List<String> genres)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CollectionItemPayload() when $default != null:
return $default(_that.tmdbId,_that.type,_that.title,_that.year,_that.overview,_that.posterPath,_that.backdropPath,_that.rating,_that.voteCount,_that.genres);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tmdbId,  String type,  String title,  int? year,  String? overview,  String? posterPath,  String? backdropPath,  double? rating,  int? voteCount,  List<String> genres)  $default,) {final _that = this;
switch (_that) {
case _CollectionItemPayload():
return $default(_that.tmdbId,_that.type,_that.title,_that.year,_that.overview,_that.posterPath,_that.backdropPath,_that.rating,_that.voteCount,_that.genres);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tmdbId,  String type,  String title,  int? year,  String? overview,  String? posterPath,  String? backdropPath,  double? rating,  int? voteCount,  List<String> genres)?  $default,) {final _that = this;
switch (_that) {
case _CollectionItemPayload() when $default != null:
return $default(_that.tmdbId,_that.type,_that.title,_that.year,_that.overview,_that.posterPath,_that.backdropPath,_that.rating,_that.voteCount,_that.genres);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CollectionItemPayload implements CollectionItemPayload {
  const _CollectionItemPayload({required this.tmdbId, required this.type, required this.title, this.year, this.overview, this.posterPath, this.backdropPath, this.rating, this.voteCount, final  List<String> genres = const []}): _genres = genres;
  factory _CollectionItemPayload.fromJson(Map<String, dynamic> json) => _$CollectionItemPayloadFromJson(json);

@override final  String tmdbId;
@override final  String type;
@override final  String title;
@override final  int? year;
@override final  String? overview;
@override final  String? posterPath;
@override final  String? backdropPath;
@override final  double? rating;
@override final  int? voteCount;
 final  List<String> _genres;
@override@JsonKey() List<String> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}


/// Create a copy of CollectionItemPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionItemPayloadCopyWith<_CollectionItemPayload> get copyWith => __$CollectionItemPayloadCopyWithImpl<_CollectionItemPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionItemPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CollectionItemPayload&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.year, year) || other.year == year)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.voteCount, voteCount) || other.voteCount == voteCount)&&const DeepCollectionEquality().equals(other._genres, _genres));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tmdbId,type,title,year,overview,posterPath,backdropPath,rating,voteCount,const DeepCollectionEquality().hash(_genres));

@override
String toString() {
  return 'CollectionItemPayload(tmdbId: $tmdbId, type: $type, title: $title, year: $year, overview: $overview, posterPath: $posterPath, backdropPath: $backdropPath, rating: $rating, voteCount: $voteCount, genres: $genres)';
}


}

/// @nodoc
abstract mixin class _$CollectionItemPayloadCopyWith<$Res> implements $CollectionItemPayloadCopyWith<$Res> {
  factory _$CollectionItemPayloadCopyWith(_CollectionItemPayload value, $Res Function(_CollectionItemPayload) _then) = __$CollectionItemPayloadCopyWithImpl;
@override @useResult
$Res call({
 String tmdbId, String type, String title, int? year, String? overview, String? posterPath, String? backdropPath, double? rating, int? voteCount, List<String> genres
});




}
/// @nodoc
class __$CollectionItemPayloadCopyWithImpl<$Res>
    implements _$CollectionItemPayloadCopyWith<$Res> {
  __$CollectionItemPayloadCopyWithImpl(this._self, this._then);

  final _CollectionItemPayload _self;
  final $Res Function(_CollectionItemPayload) _then;

/// Create a copy of CollectionItemPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tmdbId = null,Object? type = null,Object? title = null,Object? year = freezed,Object? overview = freezed,Object? posterPath = freezed,Object? backdropPath = freezed,Object? rating = freezed,Object? voteCount = freezed,Object? genres = null,}) {
  return _then(_CollectionItemPayload(
tmdbId: null == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,voteCount: freezed == voteCount ? _self.voteCount : voteCount // ignore: cast_nullable_to_non_nullable
as int?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ShowProgressEpisode {

 int get number; bool get completed; String? get lastWatchedAt; double? get scrobbleProgress; int? get playbackId;
/// Create a copy of ShowProgressEpisode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShowProgressEpisodeCopyWith<ShowProgressEpisode> get copyWith => _$ShowProgressEpisodeCopyWithImpl<ShowProgressEpisode>(this as ShowProgressEpisode, _$identity);

  /// Serializes this ShowProgressEpisode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShowProgressEpisode&&(identical(other.number, number) || other.number == number)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.lastWatchedAt, lastWatchedAt) || other.lastWatchedAt == lastWatchedAt)&&(identical(other.scrobbleProgress, scrobbleProgress) || other.scrobbleProgress == scrobbleProgress)&&(identical(other.playbackId, playbackId) || other.playbackId == playbackId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,completed,lastWatchedAt,scrobbleProgress,playbackId);

@override
String toString() {
  return 'ShowProgressEpisode(number: $number, completed: $completed, lastWatchedAt: $lastWatchedAt, scrobbleProgress: $scrobbleProgress, playbackId: $playbackId)';
}


}

/// @nodoc
abstract mixin class $ShowProgressEpisodeCopyWith<$Res>  {
  factory $ShowProgressEpisodeCopyWith(ShowProgressEpisode value, $Res Function(ShowProgressEpisode) _then) = _$ShowProgressEpisodeCopyWithImpl;
@useResult
$Res call({
 int number, bool completed, String? lastWatchedAt, double? scrobbleProgress, int? playbackId
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
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? completed = null,Object? lastWatchedAt = freezed,Object? scrobbleProgress = freezed,Object? playbackId = freezed,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,lastWatchedAt: freezed == lastWatchedAt ? _self.lastWatchedAt : lastWatchedAt // ignore: cast_nullable_to_non_nullable
as String?,scrobbleProgress: freezed == scrobbleProgress ? _self.scrobbleProgress : scrobbleProgress // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  bool completed,  String? lastWatchedAt,  double? scrobbleProgress,  int? playbackId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShowProgressEpisode() when $default != null:
return $default(_that.number,_that.completed,_that.lastWatchedAt,_that.scrobbleProgress,_that.playbackId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  bool completed,  String? lastWatchedAt,  double? scrobbleProgress,  int? playbackId)  $default,) {final _that = this;
switch (_that) {
case _ShowProgressEpisode():
return $default(_that.number,_that.completed,_that.lastWatchedAt,_that.scrobbleProgress,_that.playbackId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  bool completed,  String? lastWatchedAt,  double? scrobbleProgress,  int? playbackId)?  $default,) {final _that = this;
switch (_that) {
case _ShowProgressEpisode() when $default != null:
return $default(_that.number,_that.completed,_that.lastWatchedAt,_that.scrobbleProgress,_that.playbackId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShowProgressEpisode implements ShowProgressEpisode {
  const _ShowProgressEpisode({required this.number, required this.completed, this.lastWatchedAt, this.scrobbleProgress, this.playbackId});
  factory _ShowProgressEpisode.fromJson(Map<String, dynamic> json) => _$ShowProgressEpisodeFromJson(json);

@override final  int number;
@override final  bool completed;
@override final  String? lastWatchedAt;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowProgressEpisode&&(identical(other.number, number) || other.number == number)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.lastWatchedAt, lastWatchedAt) || other.lastWatchedAt == lastWatchedAt)&&(identical(other.scrobbleProgress, scrobbleProgress) || other.scrobbleProgress == scrobbleProgress)&&(identical(other.playbackId, playbackId) || other.playbackId == playbackId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,completed,lastWatchedAt,scrobbleProgress,playbackId);

@override
String toString() {
  return 'ShowProgressEpisode(number: $number, completed: $completed, lastWatchedAt: $lastWatchedAt, scrobbleProgress: $scrobbleProgress, playbackId: $playbackId)';
}


}

/// @nodoc
abstract mixin class _$ShowProgressEpisodeCopyWith<$Res> implements $ShowProgressEpisodeCopyWith<$Res> {
  factory _$ShowProgressEpisodeCopyWith(_ShowProgressEpisode value, $Res Function(_ShowProgressEpisode) _then) = __$ShowProgressEpisodeCopyWithImpl;
@override @useResult
$Res call({
 int number, bool completed, String? lastWatchedAt, double? scrobbleProgress, int? playbackId
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
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? completed = null,Object? lastWatchedAt = freezed,Object? scrobbleProgress = freezed,Object? playbackId = freezed,}) {
  return _then(_ShowProgressEpisode(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,lastWatchedAt: freezed == lastWatchedAt ? _self.lastWatchedAt : lastWatchedAt // ignore: cast_nullable_to_non_nullable
as String?,scrobbleProgress: freezed == scrobbleProgress ? _self.scrobbleProgress : scrobbleProgress // ignore: cast_nullable_to_non_nullable
as double?,playbackId: freezed == playbackId ? _self.playbackId : playbackId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ShowProgressSeason {

 int get number; int? get aired; int? get completed; List<ShowProgressEpisode> get episodes;
/// Create a copy of ShowProgressSeason
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShowProgressSeasonCopyWith<ShowProgressSeason> get copyWith => _$ShowProgressSeasonCopyWithImpl<ShowProgressSeason>(this as ShowProgressSeason, _$identity);

  /// Serializes this ShowProgressSeason to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShowProgressSeason&&(identical(other.number, number) || other.number == number)&&(identical(other.aired, aired) || other.aired == aired)&&(identical(other.completed, completed) || other.completed == completed)&&const DeepCollectionEquality().equals(other.episodes, episodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,aired,completed,const DeepCollectionEquality().hash(episodes));

@override
String toString() {
  return 'ShowProgressSeason(number: $number, aired: $aired, completed: $completed, episodes: $episodes)';
}


}

/// @nodoc
abstract mixin class $ShowProgressSeasonCopyWith<$Res>  {
  factory $ShowProgressSeasonCopyWith(ShowProgressSeason value, $Res Function(ShowProgressSeason) _then) = _$ShowProgressSeasonCopyWithImpl;
@useResult
$Res call({
 int number, int? aired, int? completed, List<ShowProgressEpisode> episodes
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
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? aired = freezed,Object? completed = freezed,Object? episodes = null,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,aired: freezed == aired ? _self.aired : aired // ignore: cast_nullable_to_non_nullable
as int?,completed: freezed == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int?,episodes: null == episodes ? _self.episodes : episodes // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int number,  int? aired,  int? completed,  List<ShowProgressEpisode> episodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShowProgressSeason() when $default != null:
return $default(_that.number,_that.aired,_that.completed,_that.episodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int number,  int? aired,  int? completed,  List<ShowProgressEpisode> episodes)  $default,) {final _that = this;
switch (_that) {
case _ShowProgressSeason():
return $default(_that.number,_that.aired,_that.completed,_that.episodes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int number,  int? aired,  int? completed,  List<ShowProgressEpisode> episodes)?  $default,) {final _that = this;
switch (_that) {
case _ShowProgressSeason() when $default != null:
return $default(_that.number,_that.aired,_that.completed,_that.episodes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShowProgressSeason implements ShowProgressSeason {
  const _ShowProgressSeason({required this.number, this.aired, this.completed, required final  List<ShowProgressEpisode> episodes}): _episodes = episodes;
  factory _ShowProgressSeason.fromJson(Map<String, dynamic> json) => _$ShowProgressSeasonFromJson(json);

@override final  int number;
@override final  int? aired;
@override final  int? completed;
 final  List<ShowProgressEpisode> _episodes;
@override List<ShowProgressEpisode> get episodes {
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowProgressSeason&&(identical(other.number, number) || other.number == number)&&(identical(other.aired, aired) || other.aired == aired)&&(identical(other.completed, completed) || other.completed == completed)&&const DeepCollectionEquality().equals(other._episodes, _episodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,number,aired,completed,const DeepCollectionEquality().hash(_episodes));

@override
String toString() {
  return 'ShowProgressSeason(number: $number, aired: $aired, completed: $completed, episodes: $episodes)';
}


}

/// @nodoc
abstract mixin class _$ShowProgressSeasonCopyWith<$Res> implements $ShowProgressSeasonCopyWith<$Res> {
  factory _$ShowProgressSeasonCopyWith(_ShowProgressSeason value, $Res Function(_ShowProgressSeason) _then) = __$ShowProgressSeasonCopyWithImpl;
@override @useResult
$Res call({
 int number, int? aired, int? completed, List<ShowProgressEpisode> episodes
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
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? aired = freezed,Object? completed = freezed,Object? episodes = null,}) {
  return _then(_ShowProgressSeason(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,aired: freezed == aired ? _self.aired : aired // ignore: cast_nullable_to_non_nullable
as int?,completed: freezed == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int?,episodes: null == episodes ? _self._episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<ShowProgressEpisode>,
  ));
}


}


/// @nodoc
mixin _$ShowProgressResponse {

 String get traktId; String get tmdbId; int? get aired; int? get completed; List<ShowProgressSeason> get seasons;
/// Create a copy of ShowProgressResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShowProgressResponseCopyWith<ShowProgressResponse> get copyWith => _$ShowProgressResponseCopyWithImpl<ShowProgressResponse>(this as ShowProgressResponse, _$identity);

  /// Serializes this ShowProgressResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShowProgressResponse&&(identical(other.traktId, traktId) || other.traktId == traktId)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.aired, aired) || other.aired == aired)&&(identical(other.completed, completed) || other.completed == completed)&&const DeepCollectionEquality().equals(other.seasons, seasons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,traktId,tmdbId,aired,completed,const DeepCollectionEquality().hash(seasons));

@override
String toString() {
  return 'ShowProgressResponse(traktId: $traktId, tmdbId: $tmdbId, aired: $aired, completed: $completed, seasons: $seasons)';
}


}

/// @nodoc
abstract mixin class $ShowProgressResponseCopyWith<$Res>  {
  factory $ShowProgressResponseCopyWith(ShowProgressResponse value, $Res Function(ShowProgressResponse) _then) = _$ShowProgressResponseCopyWithImpl;
@useResult
$Res call({
 String traktId, String tmdbId, int? aired, int? completed, List<ShowProgressSeason> seasons
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
@pragma('vm:prefer-inline') @override $Res call({Object? traktId = null,Object? tmdbId = null,Object? aired = freezed,Object? completed = freezed,Object? seasons = null,}) {
  return _then(_self.copyWith(
traktId: null == traktId ? _self.traktId : traktId // ignore: cast_nullable_to_non_nullable
as String,tmdbId: null == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String,aired: freezed == aired ? _self.aired : aired // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String traktId,  String tmdbId,  int? aired,  int? completed,  List<ShowProgressSeason> seasons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShowProgressResponse() when $default != null:
return $default(_that.traktId,_that.tmdbId,_that.aired,_that.completed,_that.seasons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String traktId,  String tmdbId,  int? aired,  int? completed,  List<ShowProgressSeason> seasons)  $default,) {final _that = this;
switch (_that) {
case _ShowProgressResponse():
return $default(_that.traktId,_that.tmdbId,_that.aired,_that.completed,_that.seasons);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String traktId,  String tmdbId,  int? aired,  int? completed,  List<ShowProgressSeason> seasons)?  $default,) {final _that = this;
switch (_that) {
case _ShowProgressResponse() when $default != null:
return $default(_that.traktId,_that.tmdbId,_that.aired,_that.completed,_that.seasons);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShowProgressResponse implements ShowProgressResponse {
  const _ShowProgressResponse({required this.traktId, required this.tmdbId, this.aired, this.completed, required final  List<ShowProgressSeason> seasons}): _seasons = seasons;
  factory _ShowProgressResponse.fromJson(Map<String, dynamic> json) => _$ShowProgressResponseFromJson(json);

@override final  String traktId;
@override final  String tmdbId;
@override final  int? aired;
@override final  int? completed;
 final  List<ShowProgressSeason> _seasons;
@override List<ShowProgressSeason> get seasons {
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowProgressResponse&&(identical(other.traktId, traktId) || other.traktId == traktId)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.aired, aired) || other.aired == aired)&&(identical(other.completed, completed) || other.completed == completed)&&const DeepCollectionEquality().equals(other._seasons, _seasons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,traktId,tmdbId,aired,completed,const DeepCollectionEquality().hash(_seasons));

@override
String toString() {
  return 'ShowProgressResponse(traktId: $traktId, tmdbId: $tmdbId, aired: $aired, completed: $completed, seasons: $seasons)';
}


}

/// @nodoc
abstract mixin class _$ShowProgressResponseCopyWith<$Res> implements $ShowProgressResponseCopyWith<$Res> {
  factory _$ShowProgressResponseCopyWith(_ShowProgressResponse value, $Res Function(_ShowProgressResponse) _then) = __$ShowProgressResponseCopyWithImpl;
@override @useResult
$Res call({
 String traktId, String tmdbId, int? aired, int? completed, List<ShowProgressSeason> seasons
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
@override @pragma('vm:prefer-inline') $Res call({Object? traktId = null,Object? tmdbId = null,Object? aired = freezed,Object? completed = freezed,Object? seasons = null,}) {
  return _then(_ShowProgressResponse(
traktId: null == traktId ? _self.traktId : traktId // ignore: cast_nullable_to_non_nullable
as String,tmdbId: null == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String,aired: freezed == aired ? _self.aired : aired // ignore: cast_nullable_to_non_nullable
as int?,completed: freezed == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int?,seasons: null == seasons ? _self._seasons : seasons // ignore: cast_nullable_to_non_nullable
as List<ShowProgressSeason>,
  ));
}


}

// dart format on
