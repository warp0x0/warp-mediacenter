// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'debrid.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DebridAccountInfo {

 int get id; String get username; String get email; int get points; String get locale; String get avatar; String get type; int get premium; String get expiration;
/// Create a copy of DebridAccountInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebridAccountInfoCopyWith<DebridAccountInfo> get copyWith => _$DebridAccountInfoCopyWithImpl<DebridAccountInfo>(this as DebridAccountInfo, _$identity);

  /// Serializes this DebridAccountInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebridAccountInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.points, points) || other.points == points)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.type, type) || other.type == type)&&(identical(other.premium, premium) || other.premium == premium)&&(identical(other.expiration, expiration) || other.expiration == expiration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,email,points,locale,avatar,type,premium,expiration);

@override
String toString() {
  return 'DebridAccountInfo(id: $id, username: $username, email: $email, points: $points, locale: $locale, avatar: $avatar, type: $type, premium: $premium, expiration: $expiration)';
}


}

/// @nodoc
abstract mixin class $DebridAccountInfoCopyWith<$Res>  {
  factory $DebridAccountInfoCopyWith(DebridAccountInfo value, $Res Function(DebridAccountInfo) _then) = _$DebridAccountInfoCopyWithImpl;
@useResult
$Res call({
 int id, String username, String email, int points, String locale, String avatar, String type, int premium, String expiration
});




}
/// @nodoc
class _$DebridAccountInfoCopyWithImpl<$Res>
    implements $DebridAccountInfoCopyWith<$Res> {
  _$DebridAccountInfoCopyWithImpl(this._self, this._then);

  final DebridAccountInfo _self;
  final $Res Function(DebridAccountInfo) _then;

/// Create a copy of DebridAccountInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,Object? email = null,Object? points = null,Object? locale = null,Object? avatar = null,Object? type = null,Object? premium = null,Object? expiration = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,premium: null == premium ? _self.premium : premium // ignore: cast_nullable_to_non_nullable
as int,expiration: null == expiration ? _self.expiration : expiration // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DebridAccountInfo].
extension DebridAccountInfoPatterns on DebridAccountInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DebridAccountInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DebridAccountInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DebridAccountInfo value)  $default,){
final _that = this;
switch (_that) {
case _DebridAccountInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DebridAccountInfo value)?  $default,){
final _that = this;
switch (_that) {
case _DebridAccountInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String username,  String email,  int points,  String locale,  String avatar,  String type,  int premium,  String expiration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DebridAccountInfo() when $default != null:
return $default(_that.id,_that.username,_that.email,_that.points,_that.locale,_that.avatar,_that.type,_that.premium,_that.expiration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String username,  String email,  int points,  String locale,  String avatar,  String type,  int premium,  String expiration)  $default,) {final _that = this;
switch (_that) {
case _DebridAccountInfo():
return $default(_that.id,_that.username,_that.email,_that.points,_that.locale,_that.avatar,_that.type,_that.premium,_that.expiration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String username,  String email,  int points,  String locale,  String avatar,  String type,  int premium,  String expiration)?  $default,) {final _that = this;
switch (_that) {
case _DebridAccountInfo() when $default != null:
return $default(_that.id,_that.username,_that.email,_that.points,_that.locale,_that.avatar,_that.type,_that.premium,_that.expiration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DebridAccountInfo implements DebridAccountInfo {
  const _DebridAccountInfo({required this.id, required this.username, required this.email, required this.points, required this.locale, required this.avatar, required this.type, required this.premium, required this.expiration});
  factory _DebridAccountInfo.fromJson(Map<String, dynamic> json) => _$DebridAccountInfoFromJson(json);

@override final  int id;
@override final  String username;
@override final  String email;
@override final  int points;
@override final  String locale;
@override final  String avatar;
@override final  String type;
@override final  int premium;
@override final  String expiration;

/// Create a copy of DebridAccountInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebridAccountInfoCopyWith<_DebridAccountInfo> get copyWith => __$DebridAccountInfoCopyWithImpl<_DebridAccountInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DebridAccountInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DebridAccountInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.points, points) || other.points == points)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.type, type) || other.type == type)&&(identical(other.premium, premium) || other.premium == premium)&&(identical(other.expiration, expiration) || other.expiration == expiration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,email,points,locale,avatar,type,premium,expiration);

@override
String toString() {
  return 'DebridAccountInfo(id: $id, username: $username, email: $email, points: $points, locale: $locale, avatar: $avatar, type: $type, premium: $premium, expiration: $expiration)';
}


}

/// @nodoc
abstract mixin class _$DebridAccountInfoCopyWith<$Res> implements $DebridAccountInfoCopyWith<$Res> {
  factory _$DebridAccountInfoCopyWith(_DebridAccountInfo value, $Res Function(_DebridAccountInfo) _then) = __$DebridAccountInfoCopyWithImpl;
@override @useResult
$Res call({
 int id, String username, String email, int points, String locale, String avatar, String type, int premium, String expiration
});




}
/// @nodoc
class __$DebridAccountInfoCopyWithImpl<$Res>
    implements _$DebridAccountInfoCopyWith<$Res> {
  __$DebridAccountInfoCopyWithImpl(this._self, this._then);

  final _DebridAccountInfo _self;
  final $Res Function(_DebridAccountInfo) _then;

/// Create a copy of DebridAccountInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? email = null,Object? points = null,Object? locale = null,Object? avatar = null,Object? type = null,Object? premium = null,Object? expiration = null,}) {
  return _then(_DebridAccountInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,premium: null == premium ? _self.premium : premium // ignore: cast_nullable_to_non_nullable
as int,expiration: null == expiration ? _self.expiration : expiration // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DebridTorrentFile {

 int get id; String get path; int get bytes; int get selected;
/// Create a copy of DebridTorrentFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebridTorrentFileCopyWith<DebridTorrentFile> get copyWith => _$DebridTorrentFileCopyWithImpl<DebridTorrentFile>(this as DebridTorrentFile, _$identity);

  /// Serializes this DebridTorrentFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebridTorrentFile&&(identical(other.id, id) || other.id == id)&&(identical(other.path, path) || other.path == path)&&(identical(other.bytes, bytes) || other.bytes == bytes)&&(identical(other.selected, selected) || other.selected == selected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,path,bytes,selected);

@override
String toString() {
  return 'DebridTorrentFile(id: $id, path: $path, bytes: $bytes, selected: $selected)';
}


}

/// @nodoc
abstract mixin class $DebridTorrentFileCopyWith<$Res>  {
  factory $DebridTorrentFileCopyWith(DebridTorrentFile value, $Res Function(DebridTorrentFile) _then) = _$DebridTorrentFileCopyWithImpl;
@useResult
$Res call({
 int id, String path, int bytes, int selected
});




}
/// @nodoc
class _$DebridTorrentFileCopyWithImpl<$Res>
    implements $DebridTorrentFileCopyWith<$Res> {
  _$DebridTorrentFileCopyWithImpl(this._self, this._then);

  final DebridTorrentFile _self;
  final $Res Function(DebridTorrentFile) _then;

/// Create a copy of DebridTorrentFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? path = null,Object? bytes = null,Object? selected = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int,selected: null == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DebridTorrentFile].
extension DebridTorrentFilePatterns on DebridTorrentFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DebridTorrentFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DebridTorrentFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DebridTorrentFile value)  $default,){
final _that = this;
switch (_that) {
case _DebridTorrentFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DebridTorrentFile value)?  $default,){
final _that = this;
switch (_that) {
case _DebridTorrentFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String path,  int bytes,  int selected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DebridTorrentFile() when $default != null:
return $default(_that.id,_that.path,_that.bytes,_that.selected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String path,  int bytes,  int selected)  $default,) {final _that = this;
switch (_that) {
case _DebridTorrentFile():
return $default(_that.id,_that.path,_that.bytes,_that.selected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String path,  int bytes,  int selected)?  $default,) {final _that = this;
switch (_that) {
case _DebridTorrentFile() when $default != null:
return $default(_that.id,_that.path,_that.bytes,_that.selected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DebridTorrentFile implements DebridTorrentFile {
  const _DebridTorrentFile({required this.id, required this.path, required this.bytes, required this.selected});
  factory _DebridTorrentFile.fromJson(Map<String, dynamic> json) => _$DebridTorrentFileFromJson(json);

@override final  int id;
@override final  String path;
@override final  int bytes;
@override final  int selected;

/// Create a copy of DebridTorrentFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebridTorrentFileCopyWith<_DebridTorrentFile> get copyWith => __$DebridTorrentFileCopyWithImpl<_DebridTorrentFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DebridTorrentFileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DebridTorrentFile&&(identical(other.id, id) || other.id == id)&&(identical(other.path, path) || other.path == path)&&(identical(other.bytes, bytes) || other.bytes == bytes)&&(identical(other.selected, selected) || other.selected == selected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,path,bytes,selected);

@override
String toString() {
  return 'DebridTorrentFile(id: $id, path: $path, bytes: $bytes, selected: $selected)';
}


}

/// @nodoc
abstract mixin class _$DebridTorrentFileCopyWith<$Res> implements $DebridTorrentFileCopyWith<$Res> {
  factory _$DebridTorrentFileCopyWith(_DebridTorrentFile value, $Res Function(_DebridTorrentFile) _then) = __$DebridTorrentFileCopyWithImpl;
@override @useResult
$Res call({
 int id, String path, int bytes, int selected
});




}
/// @nodoc
class __$DebridTorrentFileCopyWithImpl<$Res>
    implements _$DebridTorrentFileCopyWith<$Res> {
  __$DebridTorrentFileCopyWithImpl(this._self, this._then);

  final _DebridTorrentFile _self;
  final $Res Function(_DebridTorrentFile) _then;

/// Create a copy of DebridTorrentFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? path = null,Object? bytes = null,Object? selected = null,}) {
  return _then(_DebridTorrentFile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int,selected: null == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DebridTorrentInfo {

 String get id; String get filename; String get originalFilename; String get hash; int get bytes; int get originalBytes; String get host; int get split; double get progress; String get status; String get added; List<DebridTorrentFile> get files; List<String> get links; String? get ended; double? get speed; int? get seeders;
/// Create a copy of DebridTorrentInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebridTorrentInfoCopyWith<DebridTorrentInfo> get copyWith => _$DebridTorrentInfoCopyWithImpl<DebridTorrentInfo>(this as DebridTorrentInfo, _$identity);

  /// Serializes this DebridTorrentInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebridTorrentInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.originalFilename, originalFilename) || other.originalFilename == originalFilename)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.bytes, bytes) || other.bytes == bytes)&&(identical(other.originalBytes, originalBytes) || other.originalBytes == originalBytes)&&(identical(other.host, host) || other.host == host)&&(identical(other.split, split) || other.split == split)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.status, status) || other.status == status)&&(identical(other.added, added) || other.added == added)&&const DeepCollectionEquality().equals(other.files, files)&&const DeepCollectionEquality().equals(other.links, links)&&(identical(other.ended, ended) || other.ended == ended)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.seeders, seeders) || other.seeders == seeders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,filename,originalFilename,hash,bytes,originalBytes,host,split,progress,status,added,const DeepCollectionEquality().hash(files),const DeepCollectionEquality().hash(links),ended,speed,seeders);

@override
String toString() {
  return 'DebridTorrentInfo(id: $id, filename: $filename, originalFilename: $originalFilename, hash: $hash, bytes: $bytes, originalBytes: $originalBytes, host: $host, split: $split, progress: $progress, status: $status, added: $added, files: $files, links: $links, ended: $ended, speed: $speed, seeders: $seeders)';
}


}

/// @nodoc
abstract mixin class $DebridTorrentInfoCopyWith<$Res>  {
  factory $DebridTorrentInfoCopyWith(DebridTorrentInfo value, $Res Function(DebridTorrentInfo) _then) = _$DebridTorrentInfoCopyWithImpl;
@useResult
$Res call({
 String id, String filename, String originalFilename, String hash, int bytes, int originalBytes, String host, int split, double progress, String status, String added, List<DebridTorrentFile> files, List<String> links, String? ended, double? speed, int? seeders
});




}
/// @nodoc
class _$DebridTorrentInfoCopyWithImpl<$Res>
    implements $DebridTorrentInfoCopyWith<$Res> {
  _$DebridTorrentInfoCopyWithImpl(this._self, this._then);

  final DebridTorrentInfo _self;
  final $Res Function(DebridTorrentInfo) _then;

/// Create a copy of DebridTorrentInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? filename = null,Object? originalFilename = null,Object? hash = null,Object? bytes = null,Object? originalBytes = null,Object? host = null,Object? split = null,Object? progress = null,Object? status = null,Object? added = null,Object? files = null,Object? links = null,Object? ended = freezed,Object? speed = freezed,Object? seeders = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,filename: null == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String,originalFilename: null == originalFilename ? _self.originalFilename : originalFilename // ignore: cast_nullable_to_non_nullable
as String,hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int,originalBytes: null == originalBytes ? _self.originalBytes : originalBytes // ignore: cast_nullable_to_non_nullable
as int,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,split: null == split ? _self.split : split // ignore: cast_nullable_to_non_nullable
as int,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,added: null == added ? _self.added : added // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<DebridTorrentFile>,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as List<String>,ended: freezed == ended ? _self.ended : ended // ignore: cast_nullable_to_non_nullable
as String?,speed: freezed == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double?,seeders: freezed == seeders ? _self.seeders : seeders // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DebridTorrentInfo].
extension DebridTorrentInfoPatterns on DebridTorrentInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DebridTorrentInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DebridTorrentInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DebridTorrentInfo value)  $default,){
final _that = this;
switch (_that) {
case _DebridTorrentInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DebridTorrentInfo value)?  $default,){
final _that = this;
switch (_that) {
case _DebridTorrentInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String filename,  String originalFilename,  String hash,  int bytes,  int originalBytes,  String host,  int split,  double progress,  String status,  String added,  List<DebridTorrentFile> files,  List<String> links,  String? ended,  double? speed,  int? seeders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DebridTorrentInfo() when $default != null:
return $default(_that.id,_that.filename,_that.originalFilename,_that.hash,_that.bytes,_that.originalBytes,_that.host,_that.split,_that.progress,_that.status,_that.added,_that.files,_that.links,_that.ended,_that.speed,_that.seeders);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String filename,  String originalFilename,  String hash,  int bytes,  int originalBytes,  String host,  int split,  double progress,  String status,  String added,  List<DebridTorrentFile> files,  List<String> links,  String? ended,  double? speed,  int? seeders)  $default,) {final _that = this;
switch (_that) {
case _DebridTorrentInfo():
return $default(_that.id,_that.filename,_that.originalFilename,_that.hash,_that.bytes,_that.originalBytes,_that.host,_that.split,_that.progress,_that.status,_that.added,_that.files,_that.links,_that.ended,_that.speed,_that.seeders);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String filename,  String originalFilename,  String hash,  int bytes,  int originalBytes,  String host,  int split,  double progress,  String status,  String added,  List<DebridTorrentFile> files,  List<String> links,  String? ended,  double? speed,  int? seeders)?  $default,) {final _that = this;
switch (_that) {
case _DebridTorrentInfo() when $default != null:
return $default(_that.id,_that.filename,_that.originalFilename,_that.hash,_that.bytes,_that.originalBytes,_that.host,_that.split,_that.progress,_that.status,_that.added,_that.files,_that.links,_that.ended,_that.speed,_that.seeders);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DebridTorrentInfo implements DebridTorrentInfo {
  const _DebridTorrentInfo({required this.id, required this.filename, required this.originalFilename, required this.hash, required this.bytes, required this.originalBytes, required this.host, required this.split, required this.progress, required this.status, required this.added, required final  List<DebridTorrentFile> files, required final  List<String> links, this.ended, this.speed, this.seeders}): _files = files,_links = links;
  factory _DebridTorrentInfo.fromJson(Map<String, dynamic> json) => _$DebridTorrentInfoFromJson(json);

@override final  String id;
@override final  String filename;
@override final  String originalFilename;
@override final  String hash;
@override final  int bytes;
@override final  int originalBytes;
@override final  String host;
@override final  int split;
@override final  double progress;
@override final  String status;
@override final  String added;
 final  List<DebridTorrentFile> _files;
@override List<DebridTorrentFile> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}

 final  List<String> _links;
@override List<String> get links {
  if (_links is EqualUnmodifiableListView) return _links;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_links);
}

@override final  String? ended;
@override final  double? speed;
@override final  int? seeders;

/// Create a copy of DebridTorrentInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebridTorrentInfoCopyWith<_DebridTorrentInfo> get copyWith => __$DebridTorrentInfoCopyWithImpl<_DebridTorrentInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DebridTorrentInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DebridTorrentInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.originalFilename, originalFilename) || other.originalFilename == originalFilename)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.bytes, bytes) || other.bytes == bytes)&&(identical(other.originalBytes, originalBytes) || other.originalBytes == originalBytes)&&(identical(other.host, host) || other.host == host)&&(identical(other.split, split) || other.split == split)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.status, status) || other.status == status)&&(identical(other.added, added) || other.added == added)&&const DeepCollectionEquality().equals(other._files, _files)&&const DeepCollectionEquality().equals(other._links, _links)&&(identical(other.ended, ended) || other.ended == ended)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.seeders, seeders) || other.seeders == seeders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,filename,originalFilename,hash,bytes,originalBytes,host,split,progress,status,added,const DeepCollectionEquality().hash(_files),const DeepCollectionEquality().hash(_links),ended,speed,seeders);

@override
String toString() {
  return 'DebridTorrentInfo(id: $id, filename: $filename, originalFilename: $originalFilename, hash: $hash, bytes: $bytes, originalBytes: $originalBytes, host: $host, split: $split, progress: $progress, status: $status, added: $added, files: $files, links: $links, ended: $ended, speed: $speed, seeders: $seeders)';
}


}

/// @nodoc
abstract mixin class _$DebridTorrentInfoCopyWith<$Res> implements $DebridTorrentInfoCopyWith<$Res> {
  factory _$DebridTorrentInfoCopyWith(_DebridTorrentInfo value, $Res Function(_DebridTorrentInfo) _then) = __$DebridTorrentInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String filename, String originalFilename, String hash, int bytes, int originalBytes, String host, int split, double progress, String status, String added, List<DebridTorrentFile> files, List<String> links, String? ended, double? speed, int? seeders
});




}
/// @nodoc
class __$DebridTorrentInfoCopyWithImpl<$Res>
    implements _$DebridTorrentInfoCopyWith<$Res> {
  __$DebridTorrentInfoCopyWithImpl(this._self, this._then);

  final _DebridTorrentInfo _self;
  final $Res Function(_DebridTorrentInfo) _then;

/// Create a copy of DebridTorrentInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? filename = null,Object? originalFilename = null,Object? hash = null,Object? bytes = null,Object? originalBytes = null,Object? host = null,Object? split = null,Object? progress = null,Object? status = null,Object? added = null,Object? files = null,Object? links = null,Object? ended = freezed,Object? speed = freezed,Object? seeders = freezed,}) {
  return _then(_DebridTorrentInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,filename: null == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String,originalFilename: null == originalFilename ? _self.originalFilename : originalFilename // ignore: cast_nullable_to_non_nullable
as String,hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,bytes: null == bytes ? _self.bytes : bytes // ignore: cast_nullable_to_non_nullable
as int,originalBytes: null == originalBytes ? _self.originalBytes : originalBytes // ignore: cast_nullable_to_non_nullable
as int,host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,split: null == split ? _self.split : split // ignore: cast_nullable_to_non_nullable
as int,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,added: null == added ? _self.added : added // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<DebridTorrentFile>,links: null == links ? _self._links : links // ignore: cast_nullable_to_non_nullable
as List<String>,ended: freezed == ended ? _self.ended : ended // ignore: cast_nullable_to_non_nullable
as String?,speed: freezed == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double?,seeders: freezed == seeders ? _self.seeders : seeders // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$DebridStreamResponse {

 String get torrentId; int get fileId; String get fileName; String get streamUrl;
/// Create a copy of DebridStreamResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebridStreamResponseCopyWith<DebridStreamResponse> get copyWith => _$DebridStreamResponseCopyWithImpl<DebridStreamResponse>(this as DebridStreamResponse, _$identity);

  /// Serializes this DebridStreamResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebridStreamResponse&&(identical(other.torrentId, torrentId) || other.torrentId == torrentId)&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.streamUrl, streamUrl) || other.streamUrl == streamUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,torrentId,fileId,fileName,streamUrl);

@override
String toString() {
  return 'DebridStreamResponse(torrentId: $torrentId, fileId: $fileId, fileName: $fileName, streamUrl: $streamUrl)';
}


}

/// @nodoc
abstract mixin class $DebridStreamResponseCopyWith<$Res>  {
  factory $DebridStreamResponseCopyWith(DebridStreamResponse value, $Res Function(DebridStreamResponse) _then) = _$DebridStreamResponseCopyWithImpl;
@useResult
$Res call({
 String torrentId, int fileId, String fileName, String streamUrl
});




}
/// @nodoc
class _$DebridStreamResponseCopyWithImpl<$Res>
    implements $DebridStreamResponseCopyWith<$Res> {
  _$DebridStreamResponseCopyWithImpl(this._self, this._then);

  final DebridStreamResponse _self;
  final $Res Function(DebridStreamResponse) _then;

/// Create a copy of DebridStreamResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? torrentId = null,Object? fileId = null,Object? fileName = null,Object? streamUrl = null,}) {
  return _then(_self.copyWith(
torrentId: null == torrentId ? _self.torrentId : torrentId // ignore: cast_nullable_to_non_nullable
as String,fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as int,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,streamUrl: null == streamUrl ? _self.streamUrl : streamUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DebridStreamResponse].
extension DebridStreamResponsePatterns on DebridStreamResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DebridStreamResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DebridStreamResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DebridStreamResponse value)  $default,){
final _that = this;
switch (_that) {
case _DebridStreamResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DebridStreamResponse value)?  $default,){
final _that = this;
switch (_that) {
case _DebridStreamResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String torrentId,  int fileId,  String fileName,  String streamUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DebridStreamResponse() when $default != null:
return $default(_that.torrentId,_that.fileId,_that.fileName,_that.streamUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String torrentId,  int fileId,  String fileName,  String streamUrl)  $default,) {final _that = this;
switch (_that) {
case _DebridStreamResponse():
return $default(_that.torrentId,_that.fileId,_that.fileName,_that.streamUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String torrentId,  int fileId,  String fileName,  String streamUrl)?  $default,) {final _that = this;
switch (_that) {
case _DebridStreamResponse() when $default != null:
return $default(_that.torrentId,_that.fileId,_that.fileName,_that.streamUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DebridStreamResponse implements DebridStreamResponse {
  const _DebridStreamResponse({required this.torrentId, required this.fileId, required this.fileName, required this.streamUrl});
  factory _DebridStreamResponse.fromJson(Map<String, dynamic> json) => _$DebridStreamResponseFromJson(json);

@override final  String torrentId;
@override final  int fileId;
@override final  String fileName;
@override final  String streamUrl;

/// Create a copy of DebridStreamResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebridStreamResponseCopyWith<_DebridStreamResponse> get copyWith => __$DebridStreamResponseCopyWithImpl<_DebridStreamResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DebridStreamResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DebridStreamResponse&&(identical(other.torrentId, torrentId) || other.torrentId == torrentId)&&(identical(other.fileId, fileId) || other.fileId == fileId)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.streamUrl, streamUrl) || other.streamUrl == streamUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,torrentId,fileId,fileName,streamUrl);

@override
String toString() {
  return 'DebridStreamResponse(torrentId: $torrentId, fileId: $fileId, fileName: $fileName, streamUrl: $streamUrl)';
}


}

/// @nodoc
abstract mixin class _$DebridStreamResponseCopyWith<$Res> implements $DebridStreamResponseCopyWith<$Res> {
  factory _$DebridStreamResponseCopyWith(_DebridStreamResponse value, $Res Function(_DebridStreamResponse) _then) = __$DebridStreamResponseCopyWithImpl;
@override @useResult
$Res call({
 String torrentId, int fileId, String fileName, String streamUrl
});




}
/// @nodoc
class __$DebridStreamResponseCopyWithImpl<$Res>
    implements _$DebridStreamResponseCopyWith<$Res> {
  __$DebridStreamResponseCopyWithImpl(this._self, this._then);

  final _DebridStreamResponse _self;
  final $Res Function(_DebridStreamResponse) _then;

/// Create a copy of DebridStreamResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? torrentId = null,Object? fileId = null,Object? fileName = null,Object? streamUrl = null,}) {
  return _then(_DebridStreamResponse(
torrentId: null == torrentId ? _self.torrentId : torrentId // ignore: cast_nullable_to_non_nullable
as String,fileId: null == fileId ? _self.fileId : fileId // ignore: cast_nullable_to_non_nullable
as int,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,streamUrl: null == streamUrl ? _self.streamUrl : streamUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
