// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'files.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileBrowseEntry {

 String get name; String get path; bool get isDir;
/// Create a copy of FileBrowseEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileBrowseEntryCopyWith<FileBrowseEntry> get copyWith => _$FileBrowseEntryCopyWithImpl<FileBrowseEntry>(this as FileBrowseEntry, _$identity);

  /// Serializes this FileBrowseEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileBrowseEntry&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.isDir, isDir) || other.isDir == isDir));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,path,isDir);

@override
String toString() {
  return 'FileBrowseEntry(name: $name, path: $path, isDir: $isDir)';
}


}

/// @nodoc
abstract mixin class $FileBrowseEntryCopyWith<$Res>  {
  factory $FileBrowseEntryCopyWith(FileBrowseEntry value, $Res Function(FileBrowseEntry) _then) = _$FileBrowseEntryCopyWithImpl;
@useResult
$Res call({
 String name, String path, bool isDir
});




}
/// @nodoc
class _$FileBrowseEntryCopyWithImpl<$Res>
    implements $FileBrowseEntryCopyWith<$Res> {
  _$FileBrowseEntryCopyWithImpl(this._self, this._then);

  final FileBrowseEntry _self;
  final $Res Function(FileBrowseEntry) _then;

/// Create a copy of FileBrowseEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? path = null,Object? isDir = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,isDir: null == isDir ? _self.isDir : isDir // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FileBrowseEntry].
extension FileBrowseEntryPatterns on FileBrowseEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileBrowseEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileBrowseEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileBrowseEntry value)  $default,){
final _that = this;
switch (_that) {
case _FileBrowseEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileBrowseEntry value)?  $default,){
final _that = this;
switch (_that) {
case _FileBrowseEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String path,  bool isDir)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileBrowseEntry() when $default != null:
return $default(_that.name,_that.path,_that.isDir);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String path,  bool isDir)  $default,) {final _that = this;
switch (_that) {
case _FileBrowseEntry():
return $default(_that.name,_that.path,_that.isDir);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String path,  bool isDir)?  $default,) {final _that = this;
switch (_that) {
case _FileBrowseEntry() when $default != null:
return $default(_that.name,_that.path,_that.isDir);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileBrowseEntry implements FileBrowseEntry {
  const _FileBrowseEntry({required this.name, required this.path, required this.isDir});
  factory _FileBrowseEntry.fromJson(Map<String, dynamic> json) => _$FileBrowseEntryFromJson(json);

@override final  String name;
@override final  String path;
@override final  bool isDir;

/// Create a copy of FileBrowseEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileBrowseEntryCopyWith<_FileBrowseEntry> get copyWith => __$FileBrowseEntryCopyWithImpl<_FileBrowseEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileBrowseEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileBrowseEntry&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.isDir, isDir) || other.isDir == isDir));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,path,isDir);

@override
String toString() {
  return 'FileBrowseEntry(name: $name, path: $path, isDir: $isDir)';
}


}

/// @nodoc
abstract mixin class _$FileBrowseEntryCopyWith<$Res> implements $FileBrowseEntryCopyWith<$Res> {
  factory _$FileBrowseEntryCopyWith(_FileBrowseEntry value, $Res Function(_FileBrowseEntry) _then) = __$FileBrowseEntryCopyWithImpl;
@override @useResult
$Res call({
 String name, String path, bool isDir
});




}
/// @nodoc
class __$FileBrowseEntryCopyWithImpl<$Res>
    implements _$FileBrowseEntryCopyWith<$Res> {
  __$FileBrowseEntryCopyWithImpl(this._self, this._then);

  final _FileBrowseEntry _self;
  final $Res Function(_FileBrowseEntry) _then;

/// Create a copy of FileBrowseEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? path = null,Object? isDir = null,}) {
  return _then(_FileBrowseEntry(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,isDir: null == isDir ? _self.isDir : isDir // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$FileBrowseResponse {

 String get path; String? get parent; List<FileBrowseEntry> get entries;
/// Create a copy of FileBrowseResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileBrowseResponseCopyWith<FileBrowseResponse> get copyWith => _$FileBrowseResponseCopyWithImpl<FileBrowseResponse>(this as FileBrowseResponse, _$identity);

  /// Serializes this FileBrowseResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileBrowseResponse&&(identical(other.path, path) || other.path == path)&&(identical(other.parent, parent) || other.parent == parent)&&const DeepCollectionEquality().equals(other.entries, entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,parent,const DeepCollectionEquality().hash(entries));

@override
String toString() {
  return 'FileBrowseResponse(path: $path, parent: $parent, entries: $entries)';
}


}

/// @nodoc
abstract mixin class $FileBrowseResponseCopyWith<$Res>  {
  factory $FileBrowseResponseCopyWith(FileBrowseResponse value, $Res Function(FileBrowseResponse) _then) = _$FileBrowseResponseCopyWithImpl;
@useResult
$Res call({
 String path, String? parent, List<FileBrowseEntry> entries
});




}
/// @nodoc
class _$FileBrowseResponseCopyWithImpl<$Res>
    implements $FileBrowseResponseCopyWith<$Res> {
  _$FileBrowseResponseCopyWithImpl(this._self, this._then);

  final FileBrowseResponse _self;
  final $Res Function(FileBrowseResponse) _then;

/// Create a copy of FileBrowseResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? parent = freezed,Object? entries = null,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,parent: freezed == parent ? _self.parent : parent // ignore: cast_nullable_to_non_nullable
as String?,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<FileBrowseEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [FileBrowseResponse].
extension FileBrowseResponsePatterns on FileBrowseResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileBrowseResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileBrowseResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileBrowseResponse value)  $default,){
final _that = this;
switch (_that) {
case _FileBrowseResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileBrowseResponse value)?  $default,){
final _that = this;
switch (_that) {
case _FileBrowseResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String? parent,  List<FileBrowseEntry> entries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileBrowseResponse() when $default != null:
return $default(_that.path,_that.parent,_that.entries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String? parent,  List<FileBrowseEntry> entries)  $default,) {final _that = this;
switch (_that) {
case _FileBrowseResponse():
return $default(_that.path,_that.parent,_that.entries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String? parent,  List<FileBrowseEntry> entries)?  $default,) {final _that = this;
switch (_that) {
case _FileBrowseResponse() when $default != null:
return $default(_that.path,_that.parent,_that.entries);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileBrowseResponse implements FileBrowseResponse {
  const _FileBrowseResponse({required this.path, this.parent, required final  List<FileBrowseEntry> entries}): _entries = entries;
  factory _FileBrowseResponse.fromJson(Map<String, dynamic> json) => _$FileBrowseResponseFromJson(json);

@override final  String path;
@override final  String? parent;
 final  List<FileBrowseEntry> _entries;
@override List<FileBrowseEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}


/// Create a copy of FileBrowseResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileBrowseResponseCopyWith<_FileBrowseResponse> get copyWith => __$FileBrowseResponseCopyWithImpl<_FileBrowseResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileBrowseResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileBrowseResponse&&(identical(other.path, path) || other.path == path)&&(identical(other.parent, parent) || other.parent == parent)&&const DeepCollectionEquality().equals(other._entries, _entries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,parent,const DeepCollectionEquality().hash(_entries));

@override
String toString() {
  return 'FileBrowseResponse(path: $path, parent: $parent, entries: $entries)';
}


}

/// @nodoc
abstract mixin class _$FileBrowseResponseCopyWith<$Res> implements $FileBrowseResponseCopyWith<$Res> {
  factory _$FileBrowseResponseCopyWith(_FileBrowseResponse value, $Res Function(_FileBrowseResponse) _then) = __$FileBrowseResponseCopyWithImpl;
@override @useResult
$Res call({
 String path, String? parent, List<FileBrowseEntry> entries
});




}
/// @nodoc
class __$FileBrowseResponseCopyWithImpl<$Res>
    implements _$FileBrowseResponseCopyWith<$Res> {
  __$FileBrowseResponseCopyWithImpl(this._self, this._then);

  final _FileBrowseResponse _self;
  final $Res Function(_FileBrowseResponse) _then;

/// Create a copy of FileBrowseResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? parent = freezed,Object? entries = null,}) {
  return _then(_FileBrowseResponse(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,parent: freezed == parent ? _self.parent : parent // ignore: cast_nullable_to_non_nullable
as String?,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<FileBrowseEntry>,
  ));
}


}

// dart format on
