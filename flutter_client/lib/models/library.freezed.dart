// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LibrarySection {

 int get id; String get name; String get kind; List<String> get paths; int get enabled; String get createdAt; String get updatedAt;
/// Create a copy of LibrarySection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibrarySectionCopyWith<LibrarySection> get copyWith => _$LibrarySectionCopyWithImpl<LibrarySection>(this as LibrarySection, _$identity);

  /// Serializes this LibrarySection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibrarySection&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.paths, paths)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,kind,const DeepCollectionEquality().hash(paths),enabled,createdAt,updatedAt);

@override
String toString() {
  return 'LibrarySection(id: $id, name: $name, kind: $kind, paths: $paths, enabled: $enabled, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $LibrarySectionCopyWith<$Res>  {
  factory $LibrarySectionCopyWith(LibrarySection value, $Res Function(LibrarySection) _then) = _$LibrarySectionCopyWithImpl;
@useResult
$Res call({
 int id, String name, String kind, List<String> paths, int enabled, String createdAt, String updatedAt
});




}
/// @nodoc
class _$LibrarySectionCopyWithImpl<$Res>
    implements $LibrarySectionCopyWith<$Res> {
  _$LibrarySectionCopyWithImpl(this._self, this._then);

  final LibrarySection _self;
  final $Res Function(LibrarySection) _then;

/// Create a copy of LibrarySection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? paths = null,Object? enabled = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,paths: null == paths ? _self.paths : paths // ignore: cast_nullable_to_non_nullable
as List<String>,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LibrarySection].
extension LibrarySectionPatterns on LibrarySection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibrarySection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibrarySection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibrarySection value)  $default,){
final _that = this;
switch (_that) {
case _LibrarySection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibrarySection value)?  $default,){
final _that = this;
switch (_that) {
case _LibrarySection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String kind,  List<String> paths,  int enabled,  String createdAt,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibrarySection() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.paths,_that.enabled,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String kind,  List<String> paths,  int enabled,  String createdAt,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LibrarySection():
return $default(_that.id,_that.name,_that.kind,_that.paths,_that.enabled,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String kind,  List<String> paths,  int enabled,  String createdAt,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LibrarySection() when $default != null:
return $default(_that.id,_that.name,_that.kind,_that.paths,_that.enabled,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LibrarySection implements LibrarySection {
  const _LibrarySection({required this.id, required this.name, required this.kind, required final  List<String> paths, required this.enabled, required this.createdAt, required this.updatedAt}): _paths = paths;
  factory _LibrarySection.fromJson(Map<String, dynamic> json) => _$LibrarySectionFromJson(json);

@override final  int id;
@override final  String name;
@override final  String kind;
 final  List<String> _paths;
@override List<String> get paths {
  if (_paths is EqualUnmodifiableListView) return _paths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_paths);
}

@override final  int enabled;
@override final  String createdAt;
@override final  String updatedAt;

/// Create a copy of LibrarySection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibrarySectionCopyWith<_LibrarySection> get copyWith => __$LibrarySectionCopyWithImpl<_LibrarySection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibrarySectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibrarySection&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other._paths, _paths)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,kind,const DeepCollectionEquality().hash(_paths),enabled,createdAt,updatedAt);

@override
String toString() {
  return 'LibrarySection(id: $id, name: $name, kind: $kind, paths: $paths, enabled: $enabled, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LibrarySectionCopyWith<$Res> implements $LibrarySectionCopyWith<$Res> {
  factory _$LibrarySectionCopyWith(_LibrarySection value, $Res Function(_LibrarySection) _then) = __$LibrarySectionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String kind, List<String> paths, int enabled, String createdAt, String updatedAt
});




}
/// @nodoc
class __$LibrarySectionCopyWithImpl<$Res>
    implements _$LibrarySectionCopyWith<$Res> {
  __$LibrarySectionCopyWithImpl(this._self, this._then);

  final _LibrarySection _self;
  final $Res Function(_LibrarySection) _then;

/// Create a copy of LibrarySection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? kind = null,Object? paths = null,Object? enabled = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_LibrarySection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,paths: null == paths ? _self._paths : paths // ignore: cast_nullable_to_non_nullable
as List<String>,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LibrarySectionsResponse {

 List<LibrarySection> get sections; int get count;
/// Create a copy of LibrarySectionsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibrarySectionsResponseCopyWith<LibrarySectionsResponse> get copyWith => _$LibrarySectionsResponseCopyWithImpl<LibrarySectionsResponse>(this as LibrarySectionsResponse, _$identity);

  /// Serializes this LibrarySectionsResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibrarySectionsResponse&&const DeepCollectionEquality().equals(other.sections, sections)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(sections),count);

@override
String toString() {
  return 'LibrarySectionsResponse(sections: $sections, count: $count)';
}


}

/// @nodoc
abstract mixin class $LibrarySectionsResponseCopyWith<$Res>  {
  factory $LibrarySectionsResponseCopyWith(LibrarySectionsResponse value, $Res Function(LibrarySectionsResponse) _then) = _$LibrarySectionsResponseCopyWithImpl;
@useResult
$Res call({
 List<LibrarySection> sections, int count
});




}
/// @nodoc
class _$LibrarySectionsResponseCopyWithImpl<$Res>
    implements $LibrarySectionsResponseCopyWith<$Res> {
  _$LibrarySectionsResponseCopyWithImpl(this._self, this._then);

  final LibrarySectionsResponse _self;
  final $Res Function(LibrarySectionsResponse) _then;

/// Create a copy of LibrarySectionsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sections = null,Object? count = null,}) {
  return _then(_self.copyWith(
sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<LibrarySection>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LibrarySectionsResponse].
extension LibrarySectionsResponsePatterns on LibrarySectionsResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibrarySectionsResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibrarySectionsResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibrarySectionsResponse value)  $default,){
final _that = this;
switch (_that) {
case _LibrarySectionsResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibrarySectionsResponse value)?  $default,){
final _that = this;
switch (_that) {
case _LibrarySectionsResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LibrarySection> sections,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibrarySectionsResponse() when $default != null:
return $default(_that.sections,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LibrarySection> sections,  int count)  $default,) {final _that = this;
switch (_that) {
case _LibrarySectionsResponse():
return $default(_that.sections,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LibrarySection> sections,  int count)?  $default,) {final _that = this;
switch (_that) {
case _LibrarySectionsResponse() when $default != null:
return $default(_that.sections,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LibrarySectionsResponse implements LibrarySectionsResponse {
  const _LibrarySectionsResponse({required final  List<LibrarySection> sections, required this.count}): _sections = sections;
  factory _LibrarySectionsResponse.fromJson(Map<String, dynamic> json) => _$LibrarySectionsResponseFromJson(json);

 final  List<LibrarySection> _sections;
@override List<LibrarySection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

@override final  int count;

/// Create a copy of LibrarySectionsResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibrarySectionsResponseCopyWith<_LibrarySectionsResponse> get copyWith => __$LibrarySectionsResponseCopyWithImpl<_LibrarySectionsResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibrarySectionsResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibrarySectionsResponse&&const DeepCollectionEquality().equals(other._sections, _sections)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_sections),count);

@override
String toString() {
  return 'LibrarySectionsResponse(sections: $sections, count: $count)';
}


}

/// @nodoc
abstract mixin class _$LibrarySectionsResponseCopyWith<$Res> implements $LibrarySectionsResponseCopyWith<$Res> {
  factory _$LibrarySectionsResponseCopyWith(_LibrarySectionsResponse value, $Res Function(_LibrarySectionsResponse) _then) = __$LibrarySectionsResponseCopyWithImpl;
@override @useResult
$Res call({
 List<LibrarySection> sections, int count
});




}
/// @nodoc
class __$LibrarySectionsResponseCopyWithImpl<$Res>
    implements _$LibrarySectionsResponseCopyWith<$Res> {
  __$LibrarySectionsResponseCopyWithImpl(this._self, this._then);

  final _LibrarySectionsResponse _self;
  final $Res Function(_LibrarySectionsResponse) _then;

/// Create a copy of LibrarySectionsResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sections = null,Object? count = null,}) {
  return _then(_LibrarySectionsResponse(
sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<LibrarySection>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SourceRow {

 int get id; int get titleId; String get url; String? get filePath; String get sourceType; String? get quality; int? get sizeBytes; String? get scraper; String? get lastChecked; int? get fileSize; String? get fileMtime; String? get fileHash; String get status;
/// Create a copy of SourceRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SourceRowCopyWith<SourceRow> get copyWith => _$SourceRowCopyWithImpl<SourceRow>(this as SourceRow, _$identity);

  /// Serializes this SourceRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourceRow&&(identical(other.id, id) || other.id == id)&&(identical(other.titleId, titleId) || other.titleId == titleId)&&(identical(other.url, url) || other.url == url)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.scraper, scraper) || other.scraper == scraper)&&(identical(other.lastChecked, lastChecked) || other.lastChecked == lastChecked)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.fileMtime, fileMtime) || other.fileMtime == fileMtime)&&(identical(other.fileHash, fileHash) || other.fileHash == fileHash)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titleId,url,filePath,sourceType,quality,sizeBytes,scraper,lastChecked,fileSize,fileMtime,fileHash,status);

@override
String toString() {
  return 'SourceRow(id: $id, titleId: $titleId, url: $url, filePath: $filePath, sourceType: $sourceType, quality: $quality, sizeBytes: $sizeBytes, scraper: $scraper, lastChecked: $lastChecked, fileSize: $fileSize, fileMtime: $fileMtime, fileHash: $fileHash, status: $status)';
}


}

/// @nodoc
abstract mixin class $SourceRowCopyWith<$Res>  {
  factory $SourceRowCopyWith(SourceRow value, $Res Function(SourceRow) _then) = _$SourceRowCopyWithImpl;
@useResult
$Res call({
 int id, int titleId, String url, String? filePath, String sourceType, String? quality, int? sizeBytes, String? scraper, String? lastChecked, int? fileSize, String? fileMtime, String? fileHash, String status
});




}
/// @nodoc
class _$SourceRowCopyWithImpl<$Res>
    implements $SourceRowCopyWith<$Res> {
  _$SourceRowCopyWithImpl(this._self, this._then);

  final SourceRow _self;
  final $Res Function(SourceRow) _then;

/// Create a copy of SourceRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? titleId = null,Object? url = null,Object? filePath = freezed,Object? sourceType = null,Object? quality = freezed,Object? sizeBytes = freezed,Object? scraper = freezed,Object? lastChecked = freezed,Object? fileSize = freezed,Object? fileMtime = freezed,Object? fileHash = freezed,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,titleId: null == titleId ? _self.titleId : titleId // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String,quality: freezed == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,scraper: freezed == scraper ? _self.scraper : scraper // ignore: cast_nullable_to_non_nullable
as String?,lastChecked: freezed == lastChecked ? _self.lastChecked : lastChecked // ignore: cast_nullable_to_non_nullable
as String?,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,fileMtime: freezed == fileMtime ? _self.fileMtime : fileMtime // ignore: cast_nullable_to_non_nullable
as String?,fileHash: freezed == fileHash ? _self.fileHash : fileHash // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SourceRow].
extension SourceRowPatterns on SourceRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SourceRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SourceRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SourceRow value)  $default,){
final _that = this;
switch (_that) {
case _SourceRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SourceRow value)?  $default,){
final _that = this;
switch (_that) {
case _SourceRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int titleId,  String url,  String? filePath,  String sourceType,  String? quality,  int? sizeBytes,  String? scraper,  String? lastChecked,  int? fileSize,  String? fileMtime,  String? fileHash,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SourceRow() when $default != null:
return $default(_that.id,_that.titleId,_that.url,_that.filePath,_that.sourceType,_that.quality,_that.sizeBytes,_that.scraper,_that.lastChecked,_that.fileSize,_that.fileMtime,_that.fileHash,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int titleId,  String url,  String? filePath,  String sourceType,  String? quality,  int? sizeBytes,  String? scraper,  String? lastChecked,  int? fileSize,  String? fileMtime,  String? fileHash,  String status)  $default,) {final _that = this;
switch (_that) {
case _SourceRow():
return $default(_that.id,_that.titleId,_that.url,_that.filePath,_that.sourceType,_that.quality,_that.sizeBytes,_that.scraper,_that.lastChecked,_that.fileSize,_that.fileMtime,_that.fileHash,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int titleId,  String url,  String? filePath,  String sourceType,  String? quality,  int? sizeBytes,  String? scraper,  String? lastChecked,  int? fileSize,  String? fileMtime,  String? fileHash,  String status)?  $default,) {final _that = this;
switch (_that) {
case _SourceRow() when $default != null:
return $default(_that.id,_that.titleId,_that.url,_that.filePath,_that.sourceType,_that.quality,_that.sizeBytes,_that.scraper,_that.lastChecked,_that.fileSize,_that.fileMtime,_that.fileHash,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SourceRow implements SourceRow {
  const _SourceRow({required this.id, required this.titleId, required this.url, this.filePath, required this.sourceType, this.quality, this.sizeBytes, this.scraper, this.lastChecked, this.fileSize, this.fileMtime, this.fileHash, required this.status});
  factory _SourceRow.fromJson(Map<String, dynamic> json) => _$SourceRowFromJson(json);

@override final  int id;
@override final  int titleId;
@override final  String url;
@override final  String? filePath;
@override final  String sourceType;
@override final  String? quality;
@override final  int? sizeBytes;
@override final  String? scraper;
@override final  String? lastChecked;
@override final  int? fileSize;
@override final  String? fileMtime;
@override final  String? fileHash;
@override final  String status;

/// Create a copy of SourceRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SourceRowCopyWith<_SourceRow> get copyWith => __$SourceRowCopyWithImpl<_SourceRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SourceRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SourceRow&&(identical(other.id, id) || other.id == id)&&(identical(other.titleId, titleId) || other.titleId == titleId)&&(identical(other.url, url) || other.url == url)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.scraper, scraper) || other.scraper == scraper)&&(identical(other.lastChecked, lastChecked) || other.lastChecked == lastChecked)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.fileMtime, fileMtime) || other.fileMtime == fileMtime)&&(identical(other.fileHash, fileHash) || other.fileHash == fileHash)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titleId,url,filePath,sourceType,quality,sizeBytes,scraper,lastChecked,fileSize,fileMtime,fileHash,status);

@override
String toString() {
  return 'SourceRow(id: $id, titleId: $titleId, url: $url, filePath: $filePath, sourceType: $sourceType, quality: $quality, sizeBytes: $sizeBytes, scraper: $scraper, lastChecked: $lastChecked, fileSize: $fileSize, fileMtime: $fileMtime, fileHash: $fileHash, status: $status)';
}


}

/// @nodoc
abstract mixin class _$SourceRowCopyWith<$Res> implements $SourceRowCopyWith<$Res> {
  factory _$SourceRowCopyWith(_SourceRow value, $Res Function(_SourceRow) _then) = __$SourceRowCopyWithImpl;
@override @useResult
$Res call({
 int id, int titleId, String url, String? filePath, String sourceType, String? quality, int? sizeBytes, String? scraper, String? lastChecked, int? fileSize, String? fileMtime, String? fileHash, String status
});




}
/// @nodoc
class __$SourceRowCopyWithImpl<$Res>
    implements _$SourceRowCopyWith<$Res> {
  __$SourceRowCopyWithImpl(this._self, this._then);

  final _SourceRow _self;
  final $Res Function(_SourceRow) _then;

/// Create a copy of SourceRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? titleId = null,Object? url = null,Object? filePath = freezed,Object? sourceType = null,Object? quality = freezed,Object? sizeBytes = freezed,Object? scraper = freezed,Object? lastChecked = freezed,Object? fileSize = freezed,Object? fileMtime = freezed,Object? fileHash = freezed,Object? status = null,}) {
  return _then(_SourceRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,titleId: null == titleId ? _self.titleId : titleId // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,filePath: freezed == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String?,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String,quality: freezed == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,scraper: freezed == scraper ? _self.scraper : scraper // ignore: cast_nullable_to_non_nullable
as String?,lastChecked: freezed == lastChecked ? _self.lastChecked : lastChecked // ignore: cast_nullable_to_non_nullable
as String?,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,fileMtime: freezed == fileMtime ? _self.fileMtime : fileMtime // ignore: cast_nullable_to_non_nullable
as String?,fileHash: freezed == fileHash ? _self.fileHash : fileHash // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LibraryTitleDetail {

 int get id; String? get tmdbId; String get type; String get title; int? get year; String? get overview; String? get posterUrl; String? get backdropUrl; String? get posterPath; String? get backdropPath; String get addedAt; String get updatedAt; bool? get hasLocalSource; int? get sourceCount; List<String>? get sourceTypes;
/// Create a copy of LibraryTitleDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryTitleDetailCopyWith<LibraryTitleDetail> get copyWith => _$LibraryTitleDetailCopyWithImpl<LibraryTitleDetail>(this as LibraryTitleDetail, _$identity);

  /// Serializes this LibraryTitleDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryTitleDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.year, year) || other.year == year)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.posterUrl, posterUrl) || other.posterUrl == posterUrl)&&(identical(other.backdropUrl, backdropUrl) || other.backdropUrl == backdropUrl)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.hasLocalSource, hasLocalSource) || other.hasLocalSource == hasLocalSource)&&(identical(other.sourceCount, sourceCount) || other.sourceCount == sourceCount)&&const DeepCollectionEquality().equals(other.sourceTypes, sourceTypes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tmdbId,type,title,year,overview,posterUrl,backdropUrl,posterPath,backdropPath,addedAt,updatedAt,hasLocalSource,sourceCount,const DeepCollectionEquality().hash(sourceTypes));

@override
String toString() {
  return 'LibraryTitleDetail(id: $id, tmdbId: $tmdbId, type: $type, title: $title, year: $year, overview: $overview, posterUrl: $posterUrl, backdropUrl: $backdropUrl, posterPath: $posterPath, backdropPath: $backdropPath, addedAt: $addedAt, updatedAt: $updatedAt, hasLocalSource: $hasLocalSource, sourceCount: $sourceCount, sourceTypes: $sourceTypes)';
}


}

/// @nodoc
abstract mixin class $LibraryTitleDetailCopyWith<$Res>  {
  factory $LibraryTitleDetailCopyWith(LibraryTitleDetail value, $Res Function(LibraryTitleDetail) _then) = _$LibraryTitleDetailCopyWithImpl;
@useResult
$Res call({
 int id, String? tmdbId, String type, String title, int? year, String? overview, String? posterUrl, String? backdropUrl, String? posterPath, String? backdropPath, String addedAt, String updatedAt, bool? hasLocalSource, int? sourceCount, List<String>? sourceTypes
});




}
/// @nodoc
class _$LibraryTitleDetailCopyWithImpl<$Res>
    implements $LibraryTitleDetailCopyWith<$Res> {
  _$LibraryTitleDetailCopyWithImpl(this._self, this._then);

  final LibraryTitleDetail _self;
  final $Res Function(LibraryTitleDetail) _then;

/// Create a copy of LibraryTitleDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tmdbId = freezed,Object? type = null,Object? title = null,Object? year = freezed,Object? overview = freezed,Object? posterUrl = freezed,Object? backdropUrl = freezed,Object? posterPath = freezed,Object? backdropPath = freezed,Object? addedAt = null,Object? updatedAt = null,Object? hasLocalSource = freezed,Object? sourceCount = freezed,Object? sourceTypes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,posterUrl: freezed == posterUrl ? _self.posterUrl : posterUrl // ignore: cast_nullable_to_non_nullable
as String?,backdropUrl: freezed == backdropUrl ? _self.backdropUrl : backdropUrl // ignore: cast_nullable_to_non_nullable
as String?,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,hasLocalSource: freezed == hasLocalSource ? _self.hasLocalSource : hasLocalSource // ignore: cast_nullable_to_non_nullable
as bool?,sourceCount: freezed == sourceCount ? _self.sourceCount : sourceCount // ignore: cast_nullable_to_non_nullable
as int?,sourceTypes: freezed == sourceTypes ? _self.sourceTypes : sourceTypes // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [LibraryTitleDetail].
extension LibraryTitleDetailPatterns on LibraryTitleDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryTitleDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryTitleDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryTitleDetail value)  $default,){
final _that = this;
switch (_that) {
case _LibraryTitleDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryTitleDetail value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryTitleDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? tmdbId,  String type,  String title,  int? year,  String? overview,  String? posterUrl,  String? backdropUrl,  String? posterPath,  String? backdropPath,  String addedAt,  String updatedAt,  bool? hasLocalSource,  int? sourceCount,  List<String>? sourceTypes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryTitleDetail() when $default != null:
return $default(_that.id,_that.tmdbId,_that.type,_that.title,_that.year,_that.overview,_that.posterUrl,_that.backdropUrl,_that.posterPath,_that.backdropPath,_that.addedAt,_that.updatedAt,_that.hasLocalSource,_that.sourceCount,_that.sourceTypes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? tmdbId,  String type,  String title,  int? year,  String? overview,  String? posterUrl,  String? backdropUrl,  String? posterPath,  String? backdropPath,  String addedAt,  String updatedAt,  bool? hasLocalSource,  int? sourceCount,  List<String>? sourceTypes)  $default,) {final _that = this;
switch (_that) {
case _LibraryTitleDetail():
return $default(_that.id,_that.tmdbId,_that.type,_that.title,_that.year,_that.overview,_that.posterUrl,_that.backdropUrl,_that.posterPath,_that.backdropPath,_that.addedAt,_that.updatedAt,_that.hasLocalSource,_that.sourceCount,_that.sourceTypes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? tmdbId,  String type,  String title,  int? year,  String? overview,  String? posterUrl,  String? backdropUrl,  String? posterPath,  String? backdropPath,  String addedAt,  String updatedAt,  bool? hasLocalSource,  int? sourceCount,  List<String>? sourceTypes)?  $default,) {final _that = this;
switch (_that) {
case _LibraryTitleDetail() when $default != null:
return $default(_that.id,_that.tmdbId,_that.type,_that.title,_that.year,_that.overview,_that.posterUrl,_that.backdropUrl,_that.posterPath,_that.backdropPath,_that.addedAt,_that.updatedAt,_that.hasLocalSource,_that.sourceCount,_that.sourceTypes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LibraryTitleDetail implements LibraryTitleDetail {
  const _LibraryTitleDetail({required this.id, this.tmdbId, required this.type, required this.title, this.year, this.overview, this.posterUrl, this.backdropUrl, this.posterPath, this.backdropPath, required this.addedAt, required this.updatedAt, this.hasLocalSource, this.sourceCount, final  List<String>? sourceTypes}): _sourceTypes = sourceTypes;
  factory _LibraryTitleDetail.fromJson(Map<String, dynamic> json) => _$LibraryTitleDetailFromJson(json);

@override final  int id;
@override final  String? tmdbId;
@override final  String type;
@override final  String title;
@override final  int? year;
@override final  String? overview;
@override final  String? posterUrl;
@override final  String? backdropUrl;
@override final  String? posterPath;
@override final  String? backdropPath;
@override final  String addedAt;
@override final  String updatedAt;
@override final  bool? hasLocalSource;
@override final  int? sourceCount;
 final  List<String>? _sourceTypes;
@override List<String>? get sourceTypes {
  final value = _sourceTypes;
  if (value == null) return null;
  if (_sourceTypes is EqualUnmodifiableListView) return _sourceTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of LibraryTitleDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryTitleDetailCopyWith<_LibraryTitleDetail> get copyWith => __$LibraryTitleDetailCopyWithImpl<_LibraryTitleDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibraryTitleDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryTitleDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.year, year) || other.year == year)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.posterUrl, posterUrl) || other.posterUrl == posterUrl)&&(identical(other.backdropUrl, backdropUrl) || other.backdropUrl == backdropUrl)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.hasLocalSource, hasLocalSource) || other.hasLocalSource == hasLocalSource)&&(identical(other.sourceCount, sourceCount) || other.sourceCount == sourceCount)&&const DeepCollectionEquality().equals(other._sourceTypes, _sourceTypes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tmdbId,type,title,year,overview,posterUrl,backdropUrl,posterPath,backdropPath,addedAt,updatedAt,hasLocalSource,sourceCount,const DeepCollectionEquality().hash(_sourceTypes));

@override
String toString() {
  return 'LibraryTitleDetail(id: $id, tmdbId: $tmdbId, type: $type, title: $title, year: $year, overview: $overview, posterUrl: $posterUrl, backdropUrl: $backdropUrl, posterPath: $posterPath, backdropPath: $backdropPath, addedAt: $addedAt, updatedAt: $updatedAt, hasLocalSource: $hasLocalSource, sourceCount: $sourceCount, sourceTypes: $sourceTypes)';
}


}

/// @nodoc
abstract mixin class _$LibraryTitleDetailCopyWith<$Res> implements $LibraryTitleDetailCopyWith<$Res> {
  factory _$LibraryTitleDetailCopyWith(_LibraryTitleDetail value, $Res Function(_LibraryTitleDetail) _then) = __$LibraryTitleDetailCopyWithImpl;
@override @useResult
$Res call({
 int id, String? tmdbId, String type, String title, int? year, String? overview, String? posterUrl, String? backdropUrl, String? posterPath, String? backdropPath, String addedAt, String updatedAt, bool? hasLocalSource, int? sourceCount, List<String>? sourceTypes
});




}
/// @nodoc
class __$LibraryTitleDetailCopyWithImpl<$Res>
    implements _$LibraryTitleDetailCopyWith<$Res> {
  __$LibraryTitleDetailCopyWithImpl(this._self, this._then);

  final _LibraryTitleDetail _self;
  final $Res Function(_LibraryTitleDetail) _then;

/// Create a copy of LibraryTitleDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tmdbId = freezed,Object? type = null,Object? title = null,Object? year = freezed,Object? overview = freezed,Object? posterUrl = freezed,Object? backdropUrl = freezed,Object? posterPath = freezed,Object? backdropPath = freezed,Object? addedAt = null,Object? updatedAt = null,Object? hasLocalSource = freezed,Object? sourceCount = freezed,Object? sourceTypes = freezed,}) {
  return _then(_LibraryTitleDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,posterUrl: freezed == posterUrl ? _self.posterUrl : posterUrl // ignore: cast_nullable_to_non_nullable
as String?,backdropUrl: freezed == backdropUrl ? _self.backdropUrl : backdropUrl // ignore: cast_nullable_to_non_nullable
as String?,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,hasLocalSource: freezed == hasLocalSource ? _self.hasLocalSource : hasLocalSource // ignore: cast_nullable_to_non_nullable
as bool?,sourceCount: freezed == sourceCount ? _self.sourceCount : sourceCount // ignore: cast_nullable_to_non_nullable
as int?,sourceTypes: freezed == sourceTypes ? _self._sourceTypes : sourceTypes // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}


/// @nodoc
mixin _$TitleSourcesResponse {

 int get titleId; String get title; String? get sourceTypeFilter; List<SourceRow> get sources; int get count;
/// Create a copy of TitleSourcesResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TitleSourcesResponseCopyWith<TitleSourcesResponse> get copyWith => _$TitleSourcesResponseCopyWithImpl<TitleSourcesResponse>(this as TitleSourcesResponse, _$identity);

  /// Serializes this TitleSourcesResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TitleSourcesResponse&&(identical(other.titleId, titleId) || other.titleId == titleId)&&(identical(other.title, title) || other.title == title)&&(identical(other.sourceTypeFilter, sourceTypeFilter) || other.sourceTypeFilter == sourceTypeFilter)&&const DeepCollectionEquality().equals(other.sources, sources)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,titleId,title,sourceTypeFilter,const DeepCollectionEquality().hash(sources),count);

@override
String toString() {
  return 'TitleSourcesResponse(titleId: $titleId, title: $title, sourceTypeFilter: $sourceTypeFilter, sources: $sources, count: $count)';
}


}

/// @nodoc
abstract mixin class $TitleSourcesResponseCopyWith<$Res>  {
  factory $TitleSourcesResponseCopyWith(TitleSourcesResponse value, $Res Function(TitleSourcesResponse) _then) = _$TitleSourcesResponseCopyWithImpl;
@useResult
$Res call({
 int titleId, String title, String? sourceTypeFilter, List<SourceRow> sources, int count
});




}
/// @nodoc
class _$TitleSourcesResponseCopyWithImpl<$Res>
    implements $TitleSourcesResponseCopyWith<$Res> {
  _$TitleSourcesResponseCopyWithImpl(this._self, this._then);

  final TitleSourcesResponse _self;
  final $Res Function(TitleSourcesResponse) _then;

/// Create a copy of TitleSourcesResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? titleId = null,Object? title = null,Object? sourceTypeFilter = freezed,Object? sources = null,Object? count = null,}) {
  return _then(_self.copyWith(
titleId: null == titleId ? _self.titleId : titleId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sourceTypeFilter: freezed == sourceTypeFilter ? _self.sourceTypeFilter : sourceTypeFilter // ignore: cast_nullable_to_non_nullable
as String?,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<SourceRow>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TitleSourcesResponse].
extension TitleSourcesResponsePatterns on TitleSourcesResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TitleSourcesResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TitleSourcesResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TitleSourcesResponse value)  $default,){
final _that = this;
switch (_that) {
case _TitleSourcesResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TitleSourcesResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TitleSourcesResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int titleId,  String title,  String? sourceTypeFilter,  List<SourceRow> sources,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TitleSourcesResponse() when $default != null:
return $default(_that.titleId,_that.title,_that.sourceTypeFilter,_that.sources,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int titleId,  String title,  String? sourceTypeFilter,  List<SourceRow> sources,  int count)  $default,) {final _that = this;
switch (_that) {
case _TitleSourcesResponse():
return $default(_that.titleId,_that.title,_that.sourceTypeFilter,_that.sources,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int titleId,  String title,  String? sourceTypeFilter,  List<SourceRow> sources,  int count)?  $default,) {final _that = this;
switch (_that) {
case _TitleSourcesResponse() when $default != null:
return $default(_that.titleId,_that.title,_that.sourceTypeFilter,_that.sources,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TitleSourcesResponse implements TitleSourcesResponse {
  const _TitleSourcesResponse({required this.titleId, required this.title, this.sourceTypeFilter, required final  List<SourceRow> sources, required this.count}): _sources = sources;
  factory _TitleSourcesResponse.fromJson(Map<String, dynamic> json) => _$TitleSourcesResponseFromJson(json);

@override final  int titleId;
@override final  String title;
@override final  String? sourceTypeFilter;
 final  List<SourceRow> _sources;
@override List<SourceRow> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}

@override final  int count;

/// Create a copy of TitleSourcesResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TitleSourcesResponseCopyWith<_TitleSourcesResponse> get copyWith => __$TitleSourcesResponseCopyWithImpl<_TitleSourcesResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TitleSourcesResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TitleSourcesResponse&&(identical(other.titleId, titleId) || other.titleId == titleId)&&(identical(other.title, title) || other.title == title)&&(identical(other.sourceTypeFilter, sourceTypeFilter) || other.sourceTypeFilter == sourceTypeFilter)&&const DeepCollectionEquality().equals(other._sources, _sources)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,titleId,title,sourceTypeFilter,const DeepCollectionEquality().hash(_sources),count);

@override
String toString() {
  return 'TitleSourcesResponse(titleId: $titleId, title: $title, sourceTypeFilter: $sourceTypeFilter, sources: $sources, count: $count)';
}


}

/// @nodoc
abstract mixin class _$TitleSourcesResponseCopyWith<$Res> implements $TitleSourcesResponseCopyWith<$Res> {
  factory _$TitleSourcesResponseCopyWith(_TitleSourcesResponse value, $Res Function(_TitleSourcesResponse) _then) = __$TitleSourcesResponseCopyWithImpl;
@override @useResult
$Res call({
 int titleId, String title, String? sourceTypeFilter, List<SourceRow> sources, int count
});




}
/// @nodoc
class __$TitleSourcesResponseCopyWithImpl<$Res>
    implements _$TitleSourcesResponseCopyWith<$Res> {
  __$TitleSourcesResponseCopyWithImpl(this._self, this._then);

  final _TitleSourcesResponse _self;
  final $Res Function(_TitleSourcesResponse) _then;

/// Create a copy of TitleSourcesResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? titleId = null,Object? title = null,Object? sourceTypeFilter = freezed,Object? sources = null,Object? count = null,}) {
  return _then(_TitleSourcesResponse(
titleId: null == titleId ? _self.titleId : titleId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sourceTypeFilter: freezed == sourceTypeFilter ? _self.sourceTypeFilter : sourceTypeFilter // ignore: cast_nullable_to_non_nullable
as String?,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<SourceRow>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TitleEpisode {

 int get id; String? get tmdbId; int get titleId; int get season; int get episode; String? get name; String? get airDate; String get addedAt; String get updatedAt;
/// Create a copy of TitleEpisode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TitleEpisodeCopyWith<TitleEpisode> get copyWith => _$TitleEpisodeCopyWithImpl<TitleEpisode>(this as TitleEpisode, _$identity);

  /// Serializes this TitleEpisode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TitleEpisode&&(identical(other.id, id) || other.id == id)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.titleId, titleId) || other.titleId == titleId)&&(identical(other.season, season) || other.season == season)&&(identical(other.episode, episode) || other.episode == episode)&&(identical(other.name, name) || other.name == name)&&(identical(other.airDate, airDate) || other.airDate == airDate)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tmdbId,titleId,season,episode,name,airDate,addedAt,updatedAt);

@override
String toString() {
  return 'TitleEpisode(id: $id, tmdbId: $tmdbId, titleId: $titleId, season: $season, episode: $episode, name: $name, airDate: $airDate, addedAt: $addedAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TitleEpisodeCopyWith<$Res>  {
  factory $TitleEpisodeCopyWith(TitleEpisode value, $Res Function(TitleEpisode) _then) = _$TitleEpisodeCopyWithImpl;
@useResult
$Res call({
 int id, String? tmdbId, int titleId, int season, int episode, String? name, String? airDate, String addedAt, String updatedAt
});




}
/// @nodoc
class _$TitleEpisodeCopyWithImpl<$Res>
    implements $TitleEpisodeCopyWith<$Res> {
  _$TitleEpisodeCopyWithImpl(this._self, this._then);

  final TitleEpisode _self;
  final $Res Function(TitleEpisode) _then;

/// Create a copy of TitleEpisode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tmdbId = freezed,Object? titleId = null,Object? season = null,Object? episode = null,Object? name = freezed,Object? airDate = freezed,Object? addedAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,titleId: null == titleId ? _self.titleId : titleId // ignore: cast_nullable_to_non_nullable
as int,season: null == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as int,episode: null == episode ? _self.episode : episode // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,airDate: freezed == airDate ? _self.airDate : airDate // ignore: cast_nullable_to_non_nullable
as String?,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TitleEpisode].
extension TitleEpisodePatterns on TitleEpisode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TitleEpisode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TitleEpisode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TitleEpisode value)  $default,){
final _that = this;
switch (_that) {
case _TitleEpisode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TitleEpisode value)?  $default,){
final _that = this;
switch (_that) {
case _TitleEpisode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? tmdbId,  int titleId,  int season,  int episode,  String? name,  String? airDate,  String addedAt,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TitleEpisode() when $default != null:
return $default(_that.id,_that.tmdbId,_that.titleId,_that.season,_that.episode,_that.name,_that.airDate,_that.addedAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? tmdbId,  int titleId,  int season,  int episode,  String? name,  String? airDate,  String addedAt,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TitleEpisode():
return $default(_that.id,_that.tmdbId,_that.titleId,_that.season,_that.episode,_that.name,_that.airDate,_that.addedAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? tmdbId,  int titleId,  int season,  int episode,  String? name,  String? airDate,  String addedAt,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TitleEpisode() when $default != null:
return $default(_that.id,_that.tmdbId,_that.titleId,_that.season,_that.episode,_that.name,_that.airDate,_that.addedAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TitleEpisode implements TitleEpisode {
  const _TitleEpisode({required this.id, this.tmdbId, required this.titleId, required this.season, required this.episode, this.name, this.airDate, required this.addedAt, required this.updatedAt});
  factory _TitleEpisode.fromJson(Map<String, dynamic> json) => _$TitleEpisodeFromJson(json);

@override final  int id;
@override final  String? tmdbId;
@override final  int titleId;
@override final  int season;
@override final  int episode;
@override final  String? name;
@override final  String? airDate;
@override final  String addedAt;
@override final  String updatedAt;

/// Create a copy of TitleEpisode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TitleEpisodeCopyWith<_TitleEpisode> get copyWith => __$TitleEpisodeCopyWithImpl<_TitleEpisode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TitleEpisodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TitleEpisode&&(identical(other.id, id) || other.id == id)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.titleId, titleId) || other.titleId == titleId)&&(identical(other.season, season) || other.season == season)&&(identical(other.episode, episode) || other.episode == episode)&&(identical(other.name, name) || other.name == name)&&(identical(other.airDate, airDate) || other.airDate == airDate)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tmdbId,titleId,season,episode,name,airDate,addedAt,updatedAt);

@override
String toString() {
  return 'TitleEpisode(id: $id, tmdbId: $tmdbId, titleId: $titleId, season: $season, episode: $episode, name: $name, airDate: $airDate, addedAt: $addedAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TitleEpisodeCopyWith<$Res> implements $TitleEpisodeCopyWith<$Res> {
  factory _$TitleEpisodeCopyWith(_TitleEpisode value, $Res Function(_TitleEpisode) _then) = __$TitleEpisodeCopyWithImpl;
@override @useResult
$Res call({
 int id, String? tmdbId, int titleId, int season, int episode, String? name, String? airDate, String addedAt, String updatedAt
});




}
/// @nodoc
class __$TitleEpisodeCopyWithImpl<$Res>
    implements _$TitleEpisodeCopyWith<$Res> {
  __$TitleEpisodeCopyWithImpl(this._self, this._then);

  final _TitleEpisode _self;
  final $Res Function(_TitleEpisode) _then;

/// Create a copy of TitleEpisode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tmdbId = freezed,Object? titleId = null,Object? season = null,Object? episode = null,Object? name = freezed,Object? airDate = freezed,Object? addedAt = null,Object? updatedAt = null,}) {
  return _then(_TitleEpisode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,titleId: null == titleId ? _self.titleId : titleId // ignore: cast_nullable_to_non_nullable
as int,season: null == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as int,episode: null == episode ? _self.episode : episode // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,airDate: freezed == airDate ? _self.airDate : airDate // ignore: cast_nullable_to_non_nullable
as String?,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TitleEpisodesResponse {

 int get titleId; String get title; int? get seasonFilter; List<TitleEpisode> get episodes; int get count;
/// Create a copy of TitleEpisodesResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TitleEpisodesResponseCopyWith<TitleEpisodesResponse> get copyWith => _$TitleEpisodesResponseCopyWithImpl<TitleEpisodesResponse>(this as TitleEpisodesResponse, _$identity);

  /// Serializes this TitleEpisodesResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TitleEpisodesResponse&&(identical(other.titleId, titleId) || other.titleId == titleId)&&(identical(other.title, title) || other.title == title)&&(identical(other.seasonFilter, seasonFilter) || other.seasonFilter == seasonFilter)&&const DeepCollectionEquality().equals(other.episodes, episodes)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,titleId,title,seasonFilter,const DeepCollectionEquality().hash(episodes),count);

@override
String toString() {
  return 'TitleEpisodesResponse(titleId: $titleId, title: $title, seasonFilter: $seasonFilter, episodes: $episodes, count: $count)';
}


}

/// @nodoc
abstract mixin class $TitleEpisodesResponseCopyWith<$Res>  {
  factory $TitleEpisodesResponseCopyWith(TitleEpisodesResponse value, $Res Function(TitleEpisodesResponse) _then) = _$TitleEpisodesResponseCopyWithImpl;
@useResult
$Res call({
 int titleId, String title, int? seasonFilter, List<TitleEpisode> episodes, int count
});




}
/// @nodoc
class _$TitleEpisodesResponseCopyWithImpl<$Res>
    implements $TitleEpisodesResponseCopyWith<$Res> {
  _$TitleEpisodesResponseCopyWithImpl(this._self, this._then);

  final TitleEpisodesResponse _self;
  final $Res Function(TitleEpisodesResponse) _then;

/// Create a copy of TitleEpisodesResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? titleId = null,Object? title = null,Object? seasonFilter = freezed,Object? episodes = null,Object? count = null,}) {
  return _then(_self.copyWith(
titleId: null == titleId ? _self.titleId : titleId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,seasonFilter: freezed == seasonFilter ? _self.seasonFilter : seasonFilter // ignore: cast_nullable_to_non_nullable
as int?,episodes: null == episodes ? _self.episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<TitleEpisode>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TitleEpisodesResponse].
extension TitleEpisodesResponsePatterns on TitleEpisodesResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TitleEpisodesResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TitleEpisodesResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TitleEpisodesResponse value)  $default,){
final _that = this;
switch (_that) {
case _TitleEpisodesResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TitleEpisodesResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TitleEpisodesResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int titleId,  String title,  int? seasonFilter,  List<TitleEpisode> episodes,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TitleEpisodesResponse() when $default != null:
return $default(_that.titleId,_that.title,_that.seasonFilter,_that.episodes,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int titleId,  String title,  int? seasonFilter,  List<TitleEpisode> episodes,  int count)  $default,) {final _that = this;
switch (_that) {
case _TitleEpisodesResponse():
return $default(_that.titleId,_that.title,_that.seasonFilter,_that.episodes,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int titleId,  String title,  int? seasonFilter,  List<TitleEpisode> episodes,  int count)?  $default,) {final _that = this;
switch (_that) {
case _TitleEpisodesResponse() when $default != null:
return $default(_that.titleId,_that.title,_that.seasonFilter,_that.episodes,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TitleEpisodesResponse implements TitleEpisodesResponse {
  const _TitleEpisodesResponse({required this.titleId, required this.title, this.seasonFilter, required final  List<TitleEpisode> episodes, required this.count}): _episodes = episodes;
  factory _TitleEpisodesResponse.fromJson(Map<String, dynamic> json) => _$TitleEpisodesResponseFromJson(json);

@override final  int titleId;
@override final  String title;
@override final  int? seasonFilter;
 final  List<TitleEpisode> _episodes;
@override List<TitleEpisode> get episodes {
  if (_episodes is EqualUnmodifiableListView) return _episodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_episodes);
}

@override final  int count;

/// Create a copy of TitleEpisodesResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TitleEpisodesResponseCopyWith<_TitleEpisodesResponse> get copyWith => __$TitleEpisodesResponseCopyWithImpl<_TitleEpisodesResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TitleEpisodesResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TitleEpisodesResponse&&(identical(other.titleId, titleId) || other.titleId == titleId)&&(identical(other.title, title) || other.title == title)&&(identical(other.seasonFilter, seasonFilter) || other.seasonFilter == seasonFilter)&&const DeepCollectionEquality().equals(other._episodes, _episodes)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,titleId,title,seasonFilter,const DeepCollectionEquality().hash(_episodes),count);

@override
String toString() {
  return 'TitleEpisodesResponse(titleId: $titleId, title: $title, seasonFilter: $seasonFilter, episodes: $episodes, count: $count)';
}


}

/// @nodoc
abstract mixin class _$TitleEpisodesResponseCopyWith<$Res> implements $TitleEpisodesResponseCopyWith<$Res> {
  factory _$TitleEpisodesResponseCopyWith(_TitleEpisodesResponse value, $Res Function(_TitleEpisodesResponse) _then) = __$TitleEpisodesResponseCopyWithImpl;
@override @useResult
$Res call({
 int titleId, String title, int? seasonFilter, List<TitleEpisode> episodes, int count
});




}
/// @nodoc
class __$TitleEpisodesResponseCopyWithImpl<$Res>
    implements _$TitleEpisodesResponseCopyWith<$Res> {
  __$TitleEpisodesResponseCopyWithImpl(this._self, this._then);

  final _TitleEpisodesResponse _self;
  final $Res Function(_TitleEpisodesResponse) _then;

/// Create a copy of TitleEpisodesResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? titleId = null,Object? title = null,Object? seasonFilter = freezed,Object? episodes = null,Object? count = null,}) {
  return _then(_TitleEpisodesResponse(
titleId: null == titleId ? _self.titleId : titleId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,seasonFilter: freezed == seasonFilter ? _self.seasonFilter : seasonFilter // ignore: cast_nullable_to_non_nullable
as int?,episodes: null == episodes ? _self._episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<TitleEpisode>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LibrarySearchItem {

 int get id; String? get tmdbId; String get type; String get title; int? get year; String? get overview; String? get posterUrl; String? get backdropUrl; String? get posterPath; String? get backdropPath; String get addedAt; String get updatedAt;
/// Create a copy of LibrarySearchItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibrarySearchItemCopyWith<LibrarySearchItem> get copyWith => _$LibrarySearchItemCopyWithImpl<LibrarySearchItem>(this as LibrarySearchItem, _$identity);

  /// Serializes this LibrarySearchItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibrarySearchItem&&(identical(other.id, id) || other.id == id)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.year, year) || other.year == year)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.posterUrl, posterUrl) || other.posterUrl == posterUrl)&&(identical(other.backdropUrl, backdropUrl) || other.backdropUrl == backdropUrl)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tmdbId,type,title,year,overview,posterUrl,backdropUrl,posterPath,backdropPath,addedAt,updatedAt);

@override
String toString() {
  return 'LibrarySearchItem(id: $id, tmdbId: $tmdbId, type: $type, title: $title, year: $year, overview: $overview, posterUrl: $posterUrl, backdropUrl: $backdropUrl, posterPath: $posterPath, backdropPath: $backdropPath, addedAt: $addedAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $LibrarySearchItemCopyWith<$Res>  {
  factory $LibrarySearchItemCopyWith(LibrarySearchItem value, $Res Function(LibrarySearchItem) _then) = _$LibrarySearchItemCopyWithImpl;
@useResult
$Res call({
 int id, String? tmdbId, String type, String title, int? year, String? overview, String? posterUrl, String? backdropUrl, String? posterPath, String? backdropPath, String addedAt, String updatedAt
});




}
/// @nodoc
class _$LibrarySearchItemCopyWithImpl<$Res>
    implements $LibrarySearchItemCopyWith<$Res> {
  _$LibrarySearchItemCopyWithImpl(this._self, this._then);

  final LibrarySearchItem _self;
  final $Res Function(LibrarySearchItem) _then;

/// Create a copy of LibrarySearchItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tmdbId = freezed,Object? type = null,Object? title = null,Object? year = freezed,Object? overview = freezed,Object? posterUrl = freezed,Object? backdropUrl = freezed,Object? posterPath = freezed,Object? backdropPath = freezed,Object? addedAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,posterUrl: freezed == posterUrl ? _self.posterUrl : posterUrl // ignore: cast_nullable_to_non_nullable
as String?,backdropUrl: freezed == backdropUrl ? _self.backdropUrl : backdropUrl // ignore: cast_nullable_to_non_nullable
as String?,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LibrarySearchItem].
extension LibrarySearchItemPatterns on LibrarySearchItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibrarySearchItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibrarySearchItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibrarySearchItem value)  $default,){
final _that = this;
switch (_that) {
case _LibrarySearchItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibrarySearchItem value)?  $default,){
final _that = this;
switch (_that) {
case _LibrarySearchItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? tmdbId,  String type,  String title,  int? year,  String? overview,  String? posterUrl,  String? backdropUrl,  String? posterPath,  String? backdropPath,  String addedAt,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibrarySearchItem() when $default != null:
return $default(_that.id,_that.tmdbId,_that.type,_that.title,_that.year,_that.overview,_that.posterUrl,_that.backdropUrl,_that.posterPath,_that.backdropPath,_that.addedAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? tmdbId,  String type,  String title,  int? year,  String? overview,  String? posterUrl,  String? backdropUrl,  String? posterPath,  String? backdropPath,  String addedAt,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LibrarySearchItem():
return $default(_that.id,_that.tmdbId,_that.type,_that.title,_that.year,_that.overview,_that.posterUrl,_that.backdropUrl,_that.posterPath,_that.backdropPath,_that.addedAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? tmdbId,  String type,  String title,  int? year,  String? overview,  String? posterUrl,  String? backdropUrl,  String? posterPath,  String? backdropPath,  String addedAt,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LibrarySearchItem() when $default != null:
return $default(_that.id,_that.tmdbId,_that.type,_that.title,_that.year,_that.overview,_that.posterUrl,_that.backdropUrl,_that.posterPath,_that.backdropPath,_that.addedAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LibrarySearchItem implements LibrarySearchItem {
  const _LibrarySearchItem({required this.id, this.tmdbId, required this.type, required this.title, this.year, this.overview, this.posterUrl, this.backdropUrl, this.posterPath, this.backdropPath, required this.addedAt, required this.updatedAt});
  factory _LibrarySearchItem.fromJson(Map<String, dynamic> json) => _$LibrarySearchItemFromJson(json);

@override final  int id;
@override final  String? tmdbId;
@override final  String type;
@override final  String title;
@override final  int? year;
@override final  String? overview;
@override final  String? posterUrl;
@override final  String? backdropUrl;
@override final  String? posterPath;
@override final  String? backdropPath;
@override final  String addedAt;
@override final  String updatedAt;

/// Create a copy of LibrarySearchItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibrarySearchItemCopyWith<_LibrarySearchItem> get copyWith => __$LibrarySearchItemCopyWithImpl<_LibrarySearchItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibrarySearchItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibrarySearchItem&&(identical(other.id, id) || other.id == id)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.year, year) || other.year == year)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.posterUrl, posterUrl) || other.posterUrl == posterUrl)&&(identical(other.backdropUrl, backdropUrl) || other.backdropUrl == backdropUrl)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tmdbId,type,title,year,overview,posterUrl,backdropUrl,posterPath,backdropPath,addedAt,updatedAt);

@override
String toString() {
  return 'LibrarySearchItem(id: $id, tmdbId: $tmdbId, type: $type, title: $title, year: $year, overview: $overview, posterUrl: $posterUrl, backdropUrl: $backdropUrl, posterPath: $posterPath, backdropPath: $backdropPath, addedAt: $addedAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LibrarySearchItemCopyWith<$Res> implements $LibrarySearchItemCopyWith<$Res> {
  factory _$LibrarySearchItemCopyWith(_LibrarySearchItem value, $Res Function(_LibrarySearchItem) _then) = __$LibrarySearchItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String? tmdbId, String type, String title, int? year, String? overview, String? posterUrl, String? backdropUrl, String? posterPath, String? backdropPath, String addedAt, String updatedAt
});




}
/// @nodoc
class __$LibrarySearchItemCopyWithImpl<$Res>
    implements _$LibrarySearchItemCopyWith<$Res> {
  __$LibrarySearchItemCopyWithImpl(this._self, this._then);

  final _LibrarySearchItem _self;
  final $Res Function(_LibrarySearchItem) _then;

/// Create a copy of LibrarySearchItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tmdbId = freezed,Object? type = null,Object? title = null,Object? year = freezed,Object? overview = freezed,Object? posterUrl = freezed,Object? backdropUrl = freezed,Object? posterPath = freezed,Object? backdropPath = freezed,Object? addedAt = null,Object? updatedAt = null,}) {
  return _then(_LibrarySearchItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,posterUrl: freezed == posterUrl ? _self.posterUrl : posterUrl // ignore: cast_nullable_to_non_nullable
as String?,backdropUrl: freezed == backdropUrl ? _self.backdropUrl : backdropUrl // ignore: cast_nullable_to_non_nullable
as String?,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LibrarySearchResponse {

 String get query; List<LibrarySearchItem> get items; int get count;
/// Create a copy of LibrarySearchResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibrarySearchResponseCopyWith<LibrarySearchResponse> get copyWith => _$LibrarySearchResponseCopyWithImpl<LibrarySearchResponse>(this as LibrarySearchResponse, _$identity);

  /// Serializes this LibrarySearchResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibrarySearchResponse&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(items),count);

@override
String toString() {
  return 'LibrarySearchResponse(query: $query, items: $items, count: $count)';
}


}

/// @nodoc
abstract mixin class $LibrarySearchResponseCopyWith<$Res>  {
  factory $LibrarySearchResponseCopyWith(LibrarySearchResponse value, $Res Function(LibrarySearchResponse) _then) = _$LibrarySearchResponseCopyWithImpl;
@useResult
$Res call({
 String query, List<LibrarySearchItem> items, int count
});




}
/// @nodoc
class _$LibrarySearchResponseCopyWithImpl<$Res>
    implements $LibrarySearchResponseCopyWith<$Res> {
  _$LibrarySearchResponseCopyWithImpl(this._self, this._then);

  final LibrarySearchResponse _self;
  final $Res Function(LibrarySearchResponse) _then;

/// Create a copy of LibrarySearchResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? items = null,Object? count = null,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<LibrarySearchItem>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LibrarySearchResponse].
extension LibrarySearchResponsePatterns on LibrarySearchResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibrarySearchResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibrarySearchResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibrarySearchResponse value)  $default,){
final _that = this;
switch (_that) {
case _LibrarySearchResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibrarySearchResponse value)?  $default,){
final _that = this;
switch (_that) {
case _LibrarySearchResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  List<LibrarySearchItem> items,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibrarySearchResponse() when $default != null:
return $default(_that.query,_that.items,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  List<LibrarySearchItem> items,  int count)  $default,) {final _that = this;
switch (_that) {
case _LibrarySearchResponse():
return $default(_that.query,_that.items,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  List<LibrarySearchItem> items,  int count)?  $default,) {final _that = this;
switch (_that) {
case _LibrarySearchResponse() when $default != null:
return $default(_that.query,_that.items,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LibrarySearchResponse implements LibrarySearchResponse {
  const _LibrarySearchResponse({required this.query, required final  List<LibrarySearchItem> items, required this.count}): _items = items;
  factory _LibrarySearchResponse.fromJson(Map<String, dynamic> json) => _$LibrarySearchResponseFromJson(json);

@override final  String query;
 final  List<LibrarySearchItem> _items;
@override List<LibrarySearchItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int count;

/// Create a copy of LibrarySearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibrarySearchResponseCopyWith<_LibrarySearchResponse> get copyWith => __$LibrarySearchResponseCopyWithImpl<_LibrarySearchResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibrarySearchResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibrarySearchResponse&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(_items),count);

@override
String toString() {
  return 'LibrarySearchResponse(query: $query, items: $items, count: $count)';
}


}

/// @nodoc
abstract mixin class _$LibrarySearchResponseCopyWith<$Res> implements $LibrarySearchResponseCopyWith<$Res> {
  factory _$LibrarySearchResponseCopyWith(_LibrarySearchResponse value, $Res Function(_LibrarySearchResponse) _then) = __$LibrarySearchResponseCopyWithImpl;
@override @useResult
$Res call({
 String query, List<LibrarySearchItem> items, int count
});




}
/// @nodoc
class __$LibrarySearchResponseCopyWithImpl<$Res>
    implements _$LibrarySearchResponseCopyWith<$Res> {
  __$LibrarySearchResponseCopyWithImpl(this._self, this._then);

  final _LibrarySearchResponse _self;
  final $Res Function(_LibrarySearchResponse) _then;

/// Create a copy of LibrarySearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? items = null,Object? count = null,}) {
  return _then(_LibrarySearchResponse(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<LibrarySearchItem>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LibraryListResponse {

 List<LibrarySearchItem> get items; int get total; int get limit; int get offset; bool get hasNext;
/// Create a copy of LibraryListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryListResponseCopyWith<LibraryListResponse> get copyWith => _$LibraryListResponseCopyWithImpl<LibraryListResponse>(this as LibraryListResponse, _$identity);

  /// Serializes this LibraryListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryListResponse&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),total,limit,offset,hasNext);

@override
String toString() {
  return 'LibraryListResponse(items: $items, total: $total, limit: $limit, offset: $offset, hasNext: $hasNext)';
}


}

/// @nodoc
abstract mixin class $LibraryListResponseCopyWith<$Res>  {
  factory $LibraryListResponseCopyWith(LibraryListResponse value, $Res Function(LibraryListResponse) _then) = _$LibraryListResponseCopyWithImpl;
@useResult
$Res call({
 List<LibrarySearchItem> items, int total, int limit, int offset, bool hasNext
});




}
/// @nodoc
class _$LibraryListResponseCopyWithImpl<$Res>
    implements $LibraryListResponseCopyWith<$Res> {
  _$LibraryListResponseCopyWithImpl(this._self, this._then);

  final LibraryListResponse _self;
  final $Res Function(LibraryListResponse) _then;

/// Create a copy of LibraryListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? total = null,Object? limit = null,Object? offset = null,Object? hasNext = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<LibrarySearchItem>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LibraryListResponse].
extension LibraryListResponsePatterns on LibraryListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryListResponse value)  $default,){
final _that = this;
switch (_that) {
case _LibraryListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LibrarySearchItem> items,  int total,  int limit,  int offset,  bool hasNext)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryListResponse() when $default != null:
return $default(_that.items,_that.total,_that.limit,_that.offset,_that.hasNext);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LibrarySearchItem> items,  int total,  int limit,  int offset,  bool hasNext)  $default,) {final _that = this;
switch (_that) {
case _LibraryListResponse():
return $default(_that.items,_that.total,_that.limit,_that.offset,_that.hasNext);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LibrarySearchItem> items,  int total,  int limit,  int offset,  bool hasNext)?  $default,) {final _that = this;
switch (_that) {
case _LibraryListResponse() when $default != null:
return $default(_that.items,_that.total,_that.limit,_that.offset,_that.hasNext);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LibraryListResponse implements LibraryListResponse {
  const _LibraryListResponse({required final  List<LibrarySearchItem> items, required this.total, required this.limit, required this.offset, required this.hasNext}): _items = items;
  factory _LibraryListResponse.fromJson(Map<String, dynamic> json) => _$LibraryListResponseFromJson(json);

 final  List<LibrarySearchItem> _items;
@override List<LibrarySearchItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int total;
@override final  int limit;
@override final  int offset;
@override final  bool hasNext;

/// Create a copy of LibraryListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryListResponseCopyWith<_LibraryListResponse> get copyWith => __$LibraryListResponseCopyWithImpl<_LibraryListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibraryListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryListResponse&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),total,limit,offset,hasNext);

@override
String toString() {
  return 'LibraryListResponse(items: $items, total: $total, limit: $limit, offset: $offset, hasNext: $hasNext)';
}


}

/// @nodoc
abstract mixin class _$LibraryListResponseCopyWith<$Res> implements $LibraryListResponseCopyWith<$Res> {
  factory _$LibraryListResponseCopyWith(_LibraryListResponse value, $Res Function(_LibraryListResponse) _then) = __$LibraryListResponseCopyWithImpl;
@override @useResult
$Res call({
 List<LibrarySearchItem> items, int total, int limit, int offset, bool hasNext
});




}
/// @nodoc
class __$LibraryListResponseCopyWithImpl<$Res>
    implements _$LibraryListResponseCopyWith<$Res> {
  __$LibraryListResponseCopyWithImpl(this._self, this._then);

  final _LibraryListResponse _self;
  final $Res Function(_LibraryListResponse) _then;

/// Create a copy of LibraryListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? total = null,Object? limit = null,Object? offset = null,Object? hasNext = null,}) {
  return _then(_LibraryListResponse(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<LibrarySearchItem>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ScanStatus {

 String get scanId; String get status; int get sectionsTotal; int get sectionsCompleted; int get filesFound; int get titlesAdded; int get titlesUpdated; int get sourcesAdded; String? get currentFile; double get elapsedSeconds; bool get done;
/// Create a copy of ScanStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanStatusCopyWith<ScanStatus> get copyWith => _$ScanStatusCopyWithImpl<ScanStatus>(this as ScanStatus, _$identity);

  /// Serializes this ScanStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanStatus&&(identical(other.scanId, scanId) || other.scanId == scanId)&&(identical(other.status, status) || other.status == status)&&(identical(other.sectionsTotal, sectionsTotal) || other.sectionsTotal == sectionsTotal)&&(identical(other.sectionsCompleted, sectionsCompleted) || other.sectionsCompleted == sectionsCompleted)&&(identical(other.filesFound, filesFound) || other.filesFound == filesFound)&&(identical(other.titlesAdded, titlesAdded) || other.titlesAdded == titlesAdded)&&(identical(other.titlesUpdated, titlesUpdated) || other.titlesUpdated == titlesUpdated)&&(identical(other.sourcesAdded, sourcesAdded) || other.sourcesAdded == sourcesAdded)&&(identical(other.currentFile, currentFile) || other.currentFile == currentFile)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.done, done) || other.done == done));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,scanId,status,sectionsTotal,sectionsCompleted,filesFound,titlesAdded,titlesUpdated,sourcesAdded,currentFile,elapsedSeconds,done);

@override
String toString() {
  return 'ScanStatus(scanId: $scanId, status: $status, sectionsTotal: $sectionsTotal, sectionsCompleted: $sectionsCompleted, filesFound: $filesFound, titlesAdded: $titlesAdded, titlesUpdated: $titlesUpdated, sourcesAdded: $sourcesAdded, currentFile: $currentFile, elapsedSeconds: $elapsedSeconds, done: $done)';
}


}

/// @nodoc
abstract mixin class $ScanStatusCopyWith<$Res>  {
  factory $ScanStatusCopyWith(ScanStatus value, $Res Function(ScanStatus) _then) = _$ScanStatusCopyWithImpl;
@useResult
$Res call({
 String scanId, String status, int sectionsTotal, int sectionsCompleted, int filesFound, int titlesAdded, int titlesUpdated, int sourcesAdded, String? currentFile, double elapsedSeconds, bool done
});




}
/// @nodoc
class _$ScanStatusCopyWithImpl<$Res>
    implements $ScanStatusCopyWith<$Res> {
  _$ScanStatusCopyWithImpl(this._self, this._then);

  final ScanStatus _self;
  final $Res Function(ScanStatus) _then;

/// Create a copy of ScanStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? scanId = null,Object? status = null,Object? sectionsTotal = null,Object? sectionsCompleted = null,Object? filesFound = null,Object? titlesAdded = null,Object? titlesUpdated = null,Object? sourcesAdded = null,Object? currentFile = freezed,Object? elapsedSeconds = null,Object? done = null,}) {
  return _then(_self.copyWith(
scanId: null == scanId ? _self.scanId : scanId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,sectionsTotal: null == sectionsTotal ? _self.sectionsTotal : sectionsTotal // ignore: cast_nullable_to_non_nullable
as int,sectionsCompleted: null == sectionsCompleted ? _self.sectionsCompleted : sectionsCompleted // ignore: cast_nullable_to_non_nullable
as int,filesFound: null == filesFound ? _self.filesFound : filesFound // ignore: cast_nullable_to_non_nullable
as int,titlesAdded: null == titlesAdded ? _self.titlesAdded : titlesAdded // ignore: cast_nullable_to_non_nullable
as int,titlesUpdated: null == titlesUpdated ? _self.titlesUpdated : titlesUpdated // ignore: cast_nullable_to_non_nullable
as int,sourcesAdded: null == sourcesAdded ? _self.sourcesAdded : sourcesAdded // ignore: cast_nullable_to_non_nullable
as int,currentFile: freezed == currentFile ? _self.currentFile : currentFile // ignore: cast_nullable_to_non_nullable
as String?,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as double,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanStatus].
extension ScanStatusPatterns on ScanStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanStatus value)  $default,){
final _that = this;
switch (_that) {
case _ScanStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanStatus value)?  $default,){
final _that = this;
switch (_that) {
case _ScanStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String scanId,  String status,  int sectionsTotal,  int sectionsCompleted,  int filesFound,  int titlesAdded,  int titlesUpdated,  int sourcesAdded,  String? currentFile,  double elapsedSeconds,  bool done)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanStatus() when $default != null:
return $default(_that.scanId,_that.status,_that.sectionsTotal,_that.sectionsCompleted,_that.filesFound,_that.titlesAdded,_that.titlesUpdated,_that.sourcesAdded,_that.currentFile,_that.elapsedSeconds,_that.done);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String scanId,  String status,  int sectionsTotal,  int sectionsCompleted,  int filesFound,  int titlesAdded,  int titlesUpdated,  int sourcesAdded,  String? currentFile,  double elapsedSeconds,  bool done)  $default,) {final _that = this;
switch (_that) {
case _ScanStatus():
return $default(_that.scanId,_that.status,_that.sectionsTotal,_that.sectionsCompleted,_that.filesFound,_that.titlesAdded,_that.titlesUpdated,_that.sourcesAdded,_that.currentFile,_that.elapsedSeconds,_that.done);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String scanId,  String status,  int sectionsTotal,  int sectionsCompleted,  int filesFound,  int titlesAdded,  int titlesUpdated,  int sourcesAdded,  String? currentFile,  double elapsedSeconds,  bool done)?  $default,) {final _that = this;
switch (_that) {
case _ScanStatus() when $default != null:
return $default(_that.scanId,_that.status,_that.sectionsTotal,_that.sectionsCompleted,_that.filesFound,_that.titlesAdded,_that.titlesUpdated,_that.sourcesAdded,_that.currentFile,_that.elapsedSeconds,_that.done);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScanStatus implements ScanStatus {
  const _ScanStatus({required this.scanId, required this.status, required this.sectionsTotal, required this.sectionsCompleted, required this.filesFound, required this.titlesAdded, required this.titlesUpdated, required this.sourcesAdded, this.currentFile, required this.elapsedSeconds, required this.done});
  factory _ScanStatus.fromJson(Map<String, dynamic> json) => _$ScanStatusFromJson(json);

@override final  String scanId;
@override final  String status;
@override final  int sectionsTotal;
@override final  int sectionsCompleted;
@override final  int filesFound;
@override final  int titlesAdded;
@override final  int titlesUpdated;
@override final  int sourcesAdded;
@override final  String? currentFile;
@override final  double elapsedSeconds;
@override final  bool done;

/// Create a copy of ScanStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanStatusCopyWith<_ScanStatus> get copyWith => __$ScanStatusCopyWithImpl<_ScanStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScanStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanStatus&&(identical(other.scanId, scanId) || other.scanId == scanId)&&(identical(other.status, status) || other.status == status)&&(identical(other.sectionsTotal, sectionsTotal) || other.sectionsTotal == sectionsTotal)&&(identical(other.sectionsCompleted, sectionsCompleted) || other.sectionsCompleted == sectionsCompleted)&&(identical(other.filesFound, filesFound) || other.filesFound == filesFound)&&(identical(other.titlesAdded, titlesAdded) || other.titlesAdded == titlesAdded)&&(identical(other.titlesUpdated, titlesUpdated) || other.titlesUpdated == titlesUpdated)&&(identical(other.sourcesAdded, sourcesAdded) || other.sourcesAdded == sourcesAdded)&&(identical(other.currentFile, currentFile) || other.currentFile == currentFile)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.done, done) || other.done == done));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,scanId,status,sectionsTotal,sectionsCompleted,filesFound,titlesAdded,titlesUpdated,sourcesAdded,currentFile,elapsedSeconds,done);

@override
String toString() {
  return 'ScanStatus(scanId: $scanId, status: $status, sectionsTotal: $sectionsTotal, sectionsCompleted: $sectionsCompleted, filesFound: $filesFound, titlesAdded: $titlesAdded, titlesUpdated: $titlesUpdated, sourcesAdded: $sourcesAdded, currentFile: $currentFile, elapsedSeconds: $elapsedSeconds, done: $done)';
}


}

/// @nodoc
abstract mixin class _$ScanStatusCopyWith<$Res> implements $ScanStatusCopyWith<$Res> {
  factory _$ScanStatusCopyWith(_ScanStatus value, $Res Function(_ScanStatus) _then) = __$ScanStatusCopyWithImpl;
@override @useResult
$Res call({
 String scanId, String status, int sectionsTotal, int sectionsCompleted, int filesFound, int titlesAdded, int titlesUpdated, int sourcesAdded, String? currentFile, double elapsedSeconds, bool done
});




}
/// @nodoc
class __$ScanStatusCopyWithImpl<$Res>
    implements _$ScanStatusCopyWith<$Res> {
  __$ScanStatusCopyWithImpl(this._self, this._then);

  final _ScanStatus _self;
  final $Res Function(_ScanStatus) _then;

/// Create a copy of ScanStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? scanId = null,Object? status = null,Object? sectionsTotal = null,Object? sectionsCompleted = null,Object? filesFound = null,Object? titlesAdded = null,Object? titlesUpdated = null,Object? sourcesAdded = null,Object? currentFile = freezed,Object? elapsedSeconds = null,Object? done = null,}) {
  return _then(_ScanStatus(
scanId: null == scanId ? _self.scanId : scanId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,sectionsTotal: null == sectionsTotal ? _self.sectionsTotal : sectionsTotal // ignore: cast_nullable_to_non_nullable
as int,sectionsCompleted: null == sectionsCompleted ? _self.sectionsCompleted : sectionsCompleted // ignore: cast_nullable_to_non_nullable
as int,filesFound: null == filesFound ? _self.filesFound : filesFound // ignore: cast_nullable_to_non_nullable
as int,titlesAdded: null == titlesAdded ? _self.titlesAdded : titlesAdded // ignore: cast_nullable_to_non_nullable
as int,titlesUpdated: null == titlesUpdated ? _self.titlesUpdated : titlesUpdated // ignore: cast_nullable_to_non_nullable
as int,sourcesAdded: null == sourcesAdded ? _self.sourcesAdded : sourcesAdded // ignore: cast_nullable_to_non_nullable
as int,currentFile: freezed == currentFile ? _self.currentFile : currentFile // ignore: cast_nullable_to_non_nullable
as String?,elapsedSeconds: null == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as double,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ScanResultSummary {

 int get totalFiles; int get newTitles; int get updatedTitles; int get newEpisodes; double get durationSec;
/// Create a copy of ScanResultSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanResultSummaryCopyWith<ScanResultSummary> get copyWith => _$ScanResultSummaryCopyWithImpl<ScanResultSummary>(this as ScanResultSummary, _$identity);

  /// Serializes this ScanResultSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanResultSummary&&(identical(other.totalFiles, totalFiles) || other.totalFiles == totalFiles)&&(identical(other.newTitles, newTitles) || other.newTitles == newTitles)&&(identical(other.updatedTitles, updatedTitles) || other.updatedTitles == updatedTitles)&&(identical(other.newEpisodes, newEpisodes) || other.newEpisodes == newEpisodes)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalFiles,newTitles,updatedTitles,newEpisodes,durationSec);

@override
String toString() {
  return 'ScanResultSummary(totalFiles: $totalFiles, newTitles: $newTitles, updatedTitles: $updatedTitles, newEpisodes: $newEpisodes, durationSec: $durationSec)';
}


}

/// @nodoc
abstract mixin class $ScanResultSummaryCopyWith<$Res>  {
  factory $ScanResultSummaryCopyWith(ScanResultSummary value, $Res Function(ScanResultSummary) _then) = _$ScanResultSummaryCopyWithImpl;
@useResult
$Res call({
 int totalFiles, int newTitles, int updatedTitles, int newEpisodes, double durationSec
});




}
/// @nodoc
class _$ScanResultSummaryCopyWithImpl<$Res>
    implements $ScanResultSummaryCopyWith<$Res> {
  _$ScanResultSummaryCopyWithImpl(this._self, this._then);

  final ScanResultSummary _self;
  final $Res Function(ScanResultSummary) _then;

/// Create a copy of ScanResultSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalFiles = null,Object? newTitles = null,Object? updatedTitles = null,Object? newEpisodes = null,Object? durationSec = null,}) {
  return _then(_self.copyWith(
totalFiles: null == totalFiles ? _self.totalFiles : totalFiles // ignore: cast_nullable_to_non_nullable
as int,newTitles: null == newTitles ? _self.newTitles : newTitles // ignore: cast_nullable_to_non_nullable
as int,updatedTitles: null == updatedTitles ? _self.updatedTitles : updatedTitles // ignore: cast_nullable_to_non_nullable
as int,newEpisodes: null == newEpisodes ? _self.newEpisodes : newEpisodes // ignore: cast_nullable_to_non_nullable
as int,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanResultSummary].
extension ScanResultSummaryPatterns on ScanResultSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanResultSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanResultSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanResultSummary value)  $default,){
final _that = this;
switch (_that) {
case _ScanResultSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanResultSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ScanResultSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalFiles,  int newTitles,  int updatedTitles,  int newEpisodes,  double durationSec)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanResultSummary() when $default != null:
return $default(_that.totalFiles,_that.newTitles,_that.updatedTitles,_that.newEpisodes,_that.durationSec);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalFiles,  int newTitles,  int updatedTitles,  int newEpisodes,  double durationSec)  $default,) {final _that = this;
switch (_that) {
case _ScanResultSummary():
return $default(_that.totalFiles,_that.newTitles,_that.updatedTitles,_that.newEpisodes,_that.durationSec);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalFiles,  int newTitles,  int updatedTitles,  int newEpisodes,  double durationSec)?  $default,) {final _that = this;
switch (_that) {
case _ScanResultSummary() when $default != null:
return $default(_that.totalFiles,_that.newTitles,_that.updatedTitles,_that.newEpisodes,_that.durationSec);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScanResultSummary implements ScanResultSummary {
  const _ScanResultSummary({required this.totalFiles, required this.newTitles, required this.updatedTitles, required this.newEpisodes, required this.durationSec});
  factory _ScanResultSummary.fromJson(Map<String, dynamic> json) => _$ScanResultSummaryFromJson(json);

@override final  int totalFiles;
@override final  int newTitles;
@override final  int updatedTitles;
@override final  int newEpisodes;
@override final  double durationSec;

/// Create a copy of ScanResultSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanResultSummaryCopyWith<_ScanResultSummary> get copyWith => __$ScanResultSummaryCopyWithImpl<_ScanResultSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScanResultSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanResultSummary&&(identical(other.totalFiles, totalFiles) || other.totalFiles == totalFiles)&&(identical(other.newTitles, newTitles) || other.newTitles == newTitles)&&(identical(other.updatedTitles, updatedTitles) || other.updatedTitles == updatedTitles)&&(identical(other.newEpisodes, newEpisodes) || other.newEpisodes == newEpisodes)&&(identical(other.durationSec, durationSec) || other.durationSec == durationSec));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalFiles,newTitles,updatedTitles,newEpisodes,durationSec);

@override
String toString() {
  return 'ScanResultSummary(totalFiles: $totalFiles, newTitles: $newTitles, updatedTitles: $updatedTitles, newEpisodes: $newEpisodes, durationSec: $durationSec)';
}


}

/// @nodoc
abstract mixin class _$ScanResultSummaryCopyWith<$Res> implements $ScanResultSummaryCopyWith<$Res> {
  factory _$ScanResultSummaryCopyWith(_ScanResultSummary value, $Res Function(_ScanResultSummary) _then) = __$ScanResultSummaryCopyWithImpl;
@override @useResult
$Res call({
 int totalFiles, int newTitles, int updatedTitles, int newEpisodes, double durationSec
});




}
/// @nodoc
class __$ScanResultSummaryCopyWithImpl<$Res>
    implements _$ScanResultSummaryCopyWith<$Res> {
  __$ScanResultSummaryCopyWithImpl(this._self, this._then);

  final _ScanResultSummary _self;
  final $Res Function(_ScanResultSummary) _then;

/// Create a copy of ScanResultSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalFiles = null,Object? newTitles = null,Object? updatedTitles = null,Object? newEpisodes = null,Object? durationSec = null,}) {
  return _then(_ScanResultSummary(
totalFiles: null == totalFiles ? _self.totalFiles : totalFiles // ignore: cast_nullable_to_non_nullable
as int,newTitles: null == newTitles ? _self.newTitles : newTitles // ignore: cast_nullable_to_non_nullable
as int,updatedTitles: null == updatedTitles ? _self.updatedTitles : updatedTitles // ignore: cast_nullable_to_non_nullable
as int,newEpisodes: null == newEpisodes ? _self.newEpisodes : newEpisodes // ignore: cast_nullable_to_non_nullable
as int,durationSec: null == durationSec ? _self.durationSec : durationSec // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ScanStatusResponse {

 bool get running; double get progress; String get message; List<String> get logs; int? get filesDone; int? get filesTotal; ScanResultSummary? get result;
/// Create a copy of ScanStatusResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanStatusResponseCopyWith<ScanStatusResponse> get copyWith => _$ScanStatusResponseCopyWithImpl<ScanStatusResponse>(this as ScanStatusResponse, _$identity);

  /// Serializes this ScanStatusResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanStatusResponse&&(identical(other.running, running) || other.running == running)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.logs, logs)&&(identical(other.filesDone, filesDone) || other.filesDone == filesDone)&&(identical(other.filesTotal, filesTotal) || other.filesTotal == filesTotal)&&(identical(other.result, result) || other.result == result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,running,progress,message,const DeepCollectionEquality().hash(logs),filesDone,filesTotal,result);

@override
String toString() {
  return 'ScanStatusResponse(running: $running, progress: $progress, message: $message, logs: $logs, filesDone: $filesDone, filesTotal: $filesTotal, result: $result)';
}


}

/// @nodoc
abstract mixin class $ScanStatusResponseCopyWith<$Res>  {
  factory $ScanStatusResponseCopyWith(ScanStatusResponse value, $Res Function(ScanStatusResponse) _then) = _$ScanStatusResponseCopyWithImpl;
@useResult
$Res call({
 bool running, double progress, String message, List<String> logs, int? filesDone, int? filesTotal, ScanResultSummary? result
});


$ScanResultSummaryCopyWith<$Res>? get result;

}
/// @nodoc
class _$ScanStatusResponseCopyWithImpl<$Res>
    implements $ScanStatusResponseCopyWith<$Res> {
  _$ScanStatusResponseCopyWithImpl(this._self, this._then);

  final ScanStatusResponse _self;
  final $Res Function(ScanStatusResponse) _then;

/// Create a copy of ScanStatusResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? running = null,Object? progress = null,Object? message = null,Object? logs = null,Object? filesDone = freezed,Object? filesTotal = freezed,Object? result = freezed,}) {
  return _then(_self.copyWith(
running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,logs: null == logs ? _self.logs : logs // ignore: cast_nullable_to_non_nullable
as List<String>,filesDone: freezed == filesDone ? _self.filesDone : filesDone // ignore: cast_nullable_to_non_nullable
as int?,filesTotal: freezed == filesTotal ? _self.filesTotal : filesTotal // ignore: cast_nullable_to_non_nullable
as int?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ScanResultSummary?,
  ));
}
/// Create a copy of ScanStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScanResultSummaryCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $ScanResultSummaryCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScanStatusResponse].
extension ScanStatusResponsePatterns on ScanStatusResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanStatusResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanStatusResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanStatusResponse value)  $default,){
final _that = this;
switch (_that) {
case _ScanStatusResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanStatusResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ScanStatusResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool running,  double progress,  String message,  List<String> logs,  int? filesDone,  int? filesTotal,  ScanResultSummary? result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanStatusResponse() when $default != null:
return $default(_that.running,_that.progress,_that.message,_that.logs,_that.filesDone,_that.filesTotal,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool running,  double progress,  String message,  List<String> logs,  int? filesDone,  int? filesTotal,  ScanResultSummary? result)  $default,) {final _that = this;
switch (_that) {
case _ScanStatusResponse():
return $default(_that.running,_that.progress,_that.message,_that.logs,_that.filesDone,_that.filesTotal,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool running,  double progress,  String message,  List<String> logs,  int? filesDone,  int? filesTotal,  ScanResultSummary? result)?  $default,) {final _that = this;
switch (_that) {
case _ScanStatusResponse() when $default != null:
return $default(_that.running,_that.progress,_that.message,_that.logs,_that.filesDone,_that.filesTotal,_that.result);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScanStatusResponse implements ScanStatusResponse {
  const _ScanStatusResponse({required this.running, required this.progress, required this.message, required final  List<String> logs, this.filesDone, this.filesTotal, this.result}): _logs = logs;
  factory _ScanStatusResponse.fromJson(Map<String, dynamic> json) => _$ScanStatusResponseFromJson(json);

@override final  bool running;
@override final  double progress;
@override final  String message;
 final  List<String> _logs;
@override List<String> get logs {
  if (_logs is EqualUnmodifiableListView) return _logs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_logs);
}

@override final  int? filesDone;
@override final  int? filesTotal;
@override final  ScanResultSummary? result;

/// Create a copy of ScanStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanStatusResponseCopyWith<_ScanStatusResponse> get copyWith => __$ScanStatusResponseCopyWithImpl<_ScanStatusResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScanStatusResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanStatusResponse&&(identical(other.running, running) || other.running == running)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._logs, _logs)&&(identical(other.filesDone, filesDone) || other.filesDone == filesDone)&&(identical(other.filesTotal, filesTotal) || other.filesTotal == filesTotal)&&(identical(other.result, result) || other.result == result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,running,progress,message,const DeepCollectionEquality().hash(_logs),filesDone,filesTotal,result);

@override
String toString() {
  return 'ScanStatusResponse(running: $running, progress: $progress, message: $message, logs: $logs, filesDone: $filesDone, filesTotal: $filesTotal, result: $result)';
}


}

/// @nodoc
abstract mixin class _$ScanStatusResponseCopyWith<$Res> implements $ScanStatusResponseCopyWith<$Res> {
  factory _$ScanStatusResponseCopyWith(_ScanStatusResponse value, $Res Function(_ScanStatusResponse) _then) = __$ScanStatusResponseCopyWithImpl;
@override @useResult
$Res call({
 bool running, double progress, String message, List<String> logs, int? filesDone, int? filesTotal, ScanResultSummary? result
});


@override $ScanResultSummaryCopyWith<$Res>? get result;

}
/// @nodoc
class __$ScanStatusResponseCopyWithImpl<$Res>
    implements _$ScanStatusResponseCopyWith<$Res> {
  __$ScanStatusResponseCopyWithImpl(this._self, this._then);

  final _ScanStatusResponse _self;
  final $Res Function(_ScanStatusResponse) _then;

/// Create a copy of ScanStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? running = null,Object? progress = null,Object? message = null,Object? logs = null,Object? filesDone = freezed,Object? filesTotal = freezed,Object? result = freezed,}) {
  return _then(_ScanStatusResponse(
running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,logs: null == logs ? _self._logs : logs // ignore: cast_nullable_to_non_nullable
as List<String>,filesDone: freezed == filesDone ? _self.filesDone : filesDone // ignore: cast_nullable_to_non_nullable
as int?,filesTotal: freezed == filesTotal ? _self.filesTotal : filesTotal // ignore: cast_nullable_to_non_nullable
as int?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ScanResultSummary?,
  ));
}

/// Create a copy of ScanStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScanResultSummaryCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $ScanResultSummaryCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

// dart format on
