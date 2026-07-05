// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DatabaseHealth {

 String get status; int? get schemaVersion; String? get message;
/// Create a copy of DatabaseHealth
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DatabaseHealthCopyWith<DatabaseHealth> get copyWith => _$DatabaseHealthCopyWithImpl<DatabaseHealth>(this as DatabaseHealth, _$identity);

  /// Serializes this DatabaseHealth to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DatabaseHealth&&(identical(other.status, status) || other.status == status)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,schemaVersion,message);

@override
String toString() {
  return 'DatabaseHealth(status: $status, schemaVersion: $schemaVersion, message: $message)';
}


}

/// @nodoc
abstract mixin class $DatabaseHealthCopyWith<$Res>  {
  factory $DatabaseHealthCopyWith(DatabaseHealth value, $Res Function(DatabaseHealth) _then) = _$DatabaseHealthCopyWithImpl;
@useResult
$Res call({
 String status, int? schemaVersion, String? message
});




}
/// @nodoc
class _$DatabaseHealthCopyWithImpl<$Res>
    implements $DatabaseHealthCopyWith<$Res> {
  _$DatabaseHealthCopyWithImpl(this._self, this._then);

  final DatabaseHealth _self;
  final $Res Function(DatabaseHealth) _then;

/// Create a copy of DatabaseHealth
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? schemaVersion = freezed,Object? message = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,schemaVersion: freezed == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DatabaseHealth].
extension DatabaseHealthPatterns on DatabaseHealth {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DatabaseHealth value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DatabaseHealth() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DatabaseHealth value)  $default,){
final _that = this;
switch (_that) {
case _DatabaseHealth():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DatabaseHealth value)?  $default,){
final _that = this;
switch (_that) {
case _DatabaseHealth() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  int? schemaVersion,  String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DatabaseHealth() when $default != null:
return $default(_that.status,_that.schemaVersion,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  int? schemaVersion,  String? message)  $default,) {final _that = this;
switch (_that) {
case _DatabaseHealth():
return $default(_that.status,_that.schemaVersion,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  int? schemaVersion,  String? message)?  $default,) {final _that = this;
switch (_that) {
case _DatabaseHealth() when $default != null:
return $default(_that.status,_that.schemaVersion,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DatabaseHealth implements DatabaseHealth {
  const _DatabaseHealth({required this.status, this.schemaVersion, this.message});
  factory _DatabaseHealth.fromJson(Map<String, dynamic> json) => _$DatabaseHealthFromJson(json);

@override final  String status;
@override final  int? schemaVersion;
@override final  String? message;

/// Create a copy of DatabaseHealth
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DatabaseHealthCopyWith<_DatabaseHealth> get copyWith => __$DatabaseHealthCopyWithImpl<_DatabaseHealth>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DatabaseHealthToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DatabaseHealth&&(identical(other.status, status) || other.status == status)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,schemaVersion,message);

@override
String toString() {
  return 'DatabaseHealth(status: $status, schemaVersion: $schemaVersion, message: $message)';
}


}

/// @nodoc
abstract mixin class _$DatabaseHealthCopyWith<$Res> implements $DatabaseHealthCopyWith<$Res> {
  factory _$DatabaseHealthCopyWith(_DatabaseHealth value, $Res Function(_DatabaseHealth) _then) = __$DatabaseHealthCopyWithImpl;
@override @useResult
$Res call({
 String status, int? schemaVersion, String? message
});




}
/// @nodoc
class __$DatabaseHealthCopyWithImpl<$Res>
    implements _$DatabaseHealthCopyWith<$Res> {
  __$DatabaseHealthCopyWithImpl(this._self, this._then);

  final _DatabaseHealth _self;
  final $Res Function(_DatabaseHealth) _then;

/// Create a copy of DatabaseHealth
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? schemaVersion = freezed,Object? message = freezed,}) {
  return _then(_DatabaseHealth(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,schemaVersion: freezed == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$HealthSubsystems {

 DatabaseHealth get database; Map<String, dynamic> get services;
/// Create a copy of HealthSubsystems
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthSubsystemsCopyWith<HealthSubsystems> get copyWith => _$HealthSubsystemsCopyWithImpl<HealthSubsystems>(this as HealthSubsystems, _$identity);

  /// Serializes this HealthSubsystems to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthSubsystems&&(identical(other.database, database) || other.database == database)&&const DeepCollectionEquality().equals(other.services, services));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,database,const DeepCollectionEquality().hash(services));

@override
String toString() {
  return 'HealthSubsystems(database: $database, services: $services)';
}


}

/// @nodoc
abstract mixin class $HealthSubsystemsCopyWith<$Res>  {
  factory $HealthSubsystemsCopyWith(HealthSubsystems value, $Res Function(HealthSubsystems) _then) = _$HealthSubsystemsCopyWithImpl;
@useResult
$Res call({
 DatabaseHealth database, Map<String, dynamic> services
});


$DatabaseHealthCopyWith<$Res> get database;

}
/// @nodoc
class _$HealthSubsystemsCopyWithImpl<$Res>
    implements $HealthSubsystemsCopyWith<$Res> {
  _$HealthSubsystemsCopyWithImpl(this._self, this._then);

  final HealthSubsystems _self;
  final $Res Function(HealthSubsystems) _then;

/// Create a copy of HealthSubsystems
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? database = null,Object? services = null,}) {
  return _then(_self.copyWith(
database: null == database ? _self.database : database // ignore: cast_nullable_to_non_nullable
as DatabaseHealth,services: null == services ? _self.services : services // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}
/// Create a copy of HealthSubsystems
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DatabaseHealthCopyWith<$Res> get database {
  
  return $DatabaseHealthCopyWith<$Res>(_self.database, (value) {
    return _then(_self.copyWith(database: value));
  });
}
}


/// Adds pattern-matching-related methods to [HealthSubsystems].
extension HealthSubsystemsPatterns on HealthSubsystems {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthSubsystems value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthSubsystems() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthSubsystems value)  $default,){
final _that = this;
switch (_that) {
case _HealthSubsystems():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthSubsystems value)?  $default,){
final _that = this;
switch (_that) {
case _HealthSubsystems() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DatabaseHealth database,  Map<String, dynamic> services)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthSubsystems() when $default != null:
return $default(_that.database,_that.services);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DatabaseHealth database,  Map<String, dynamic> services)  $default,) {final _that = this;
switch (_that) {
case _HealthSubsystems():
return $default(_that.database,_that.services);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DatabaseHealth database,  Map<String, dynamic> services)?  $default,) {final _that = this;
switch (_that) {
case _HealthSubsystems() when $default != null:
return $default(_that.database,_that.services);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HealthSubsystems implements HealthSubsystems {
  const _HealthSubsystems({required this.database, final  Map<String, dynamic> services = const {}}): _services = services;
  factory _HealthSubsystems.fromJson(Map<String, dynamic> json) => _$HealthSubsystemsFromJson(json);

@override final  DatabaseHealth database;
 final  Map<String, dynamic> _services;
@override@JsonKey() Map<String, dynamic> get services {
  if (_services is EqualUnmodifiableMapView) return _services;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_services);
}


/// Create a copy of HealthSubsystems
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthSubsystemsCopyWith<_HealthSubsystems> get copyWith => __$HealthSubsystemsCopyWithImpl<_HealthSubsystems>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthSubsystemsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthSubsystems&&(identical(other.database, database) || other.database == database)&&const DeepCollectionEquality().equals(other._services, _services));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,database,const DeepCollectionEquality().hash(_services));

@override
String toString() {
  return 'HealthSubsystems(database: $database, services: $services)';
}


}

/// @nodoc
abstract mixin class _$HealthSubsystemsCopyWith<$Res> implements $HealthSubsystemsCopyWith<$Res> {
  factory _$HealthSubsystemsCopyWith(_HealthSubsystems value, $Res Function(_HealthSubsystems) _then) = __$HealthSubsystemsCopyWithImpl;
@override @useResult
$Res call({
 DatabaseHealth database, Map<String, dynamic> services
});


@override $DatabaseHealthCopyWith<$Res> get database;

}
/// @nodoc
class __$HealthSubsystemsCopyWithImpl<$Res>
    implements _$HealthSubsystemsCopyWith<$Res> {
  __$HealthSubsystemsCopyWithImpl(this._self, this._then);

  final _HealthSubsystems _self;
  final $Res Function(_HealthSubsystems) _then;

/// Create a copy of HealthSubsystems
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? database = null,Object? services = null,}) {
  return _then(_HealthSubsystems(
database: null == database ? _self.database : database // ignore: cast_nullable_to_non_nullable
as DatabaseHealth,services: null == services ? _self._services : services // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

/// Create a copy of HealthSubsystems
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DatabaseHealthCopyWith<$Res> get database {
  
  return $DatabaseHealthCopyWith<$Res>(_self.database, (value) {
    return _then(_self.copyWith(database: value));
  });
}
}


/// @nodoc
mixin _$HealthResponse {

 String get status; String get service; HealthSubsystems get subsystems;
/// Create a copy of HealthResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthResponseCopyWith<HealthResponse> get copyWith => _$HealthResponseCopyWithImpl<HealthResponse>(this as HealthResponse, _$identity);

  /// Serializes this HealthResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthResponse&&(identical(other.status, status) || other.status == status)&&(identical(other.service, service) || other.service == service)&&(identical(other.subsystems, subsystems) || other.subsystems == subsystems));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,service,subsystems);

@override
String toString() {
  return 'HealthResponse(status: $status, service: $service, subsystems: $subsystems)';
}


}

/// @nodoc
abstract mixin class $HealthResponseCopyWith<$Res>  {
  factory $HealthResponseCopyWith(HealthResponse value, $Res Function(HealthResponse) _then) = _$HealthResponseCopyWithImpl;
@useResult
$Res call({
 String status, String service, HealthSubsystems subsystems
});


$HealthSubsystemsCopyWith<$Res> get subsystems;

}
/// @nodoc
class _$HealthResponseCopyWithImpl<$Res>
    implements $HealthResponseCopyWith<$Res> {
  _$HealthResponseCopyWithImpl(this._self, this._then);

  final HealthResponse _self;
  final $Res Function(HealthResponse) _then;

/// Create a copy of HealthResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? service = null,Object? subsystems = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as String,subsystems: null == subsystems ? _self.subsystems : subsystems // ignore: cast_nullable_to_non_nullable
as HealthSubsystems,
  ));
}
/// Create a copy of HealthResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HealthSubsystemsCopyWith<$Res> get subsystems {
  
  return $HealthSubsystemsCopyWith<$Res>(_self.subsystems, (value) {
    return _then(_self.copyWith(subsystems: value));
  });
}
}


/// Adds pattern-matching-related methods to [HealthResponse].
extension HealthResponsePatterns on HealthResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthResponse value)  $default,){
final _that = this;
switch (_that) {
case _HealthResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthResponse value)?  $default,){
final _that = this;
switch (_that) {
case _HealthResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String service,  HealthSubsystems subsystems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthResponse() when $default != null:
return $default(_that.status,_that.service,_that.subsystems);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String service,  HealthSubsystems subsystems)  $default,) {final _that = this;
switch (_that) {
case _HealthResponse():
return $default(_that.status,_that.service,_that.subsystems);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String service,  HealthSubsystems subsystems)?  $default,) {final _that = this;
switch (_that) {
case _HealthResponse() when $default != null:
return $default(_that.status,_that.service,_that.subsystems);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HealthResponse implements HealthResponse {
  const _HealthResponse({required this.status, required this.service, required this.subsystems});
  factory _HealthResponse.fromJson(Map<String, dynamic> json) => _$HealthResponseFromJson(json);

@override final  String status;
@override final  String service;
@override final  HealthSubsystems subsystems;

/// Create a copy of HealthResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthResponseCopyWith<_HealthResponse> get copyWith => __$HealthResponseCopyWithImpl<_HealthResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthResponse&&(identical(other.status, status) || other.status == status)&&(identical(other.service, service) || other.service == service)&&(identical(other.subsystems, subsystems) || other.subsystems == subsystems));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,service,subsystems);

@override
String toString() {
  return 'HealthResponse(status: $status, service: $service, subsystems: $subsystems)';
}


}

/// @nodoc
abstract mixin class _$HealthResponseCopyWith<$Res> implements $HealthResponseCopyWith<$Res> {
  factory _$HealthResponseCopyWith(_HealthResponse value, $Res Function(_HealthResponse) _then) = __$HealthResponseCopyWithImpl;
@override @useResult
$Res call({
 String status, String service, HealthSubsystems subsystems
});


@override $HealthSubsystemsCopyWith<$Res> get subsystems;

}
/// @nodoc
class __$HealthResponseCopyWithImpl<$Res>
    implements _$HealthResponseCopyWith<$Res> {
  __$HealthResponseCopyWithImpl(this._self, this._then);

  final _HealthResponse _self;
  final $Res Function(_HealthResponse) _then;

/// Create a copy of HealthResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? service = null,Object? subsystems = null,}) {
  return _then(_HealthResponse(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as String,subsystems: null == subsystems ? _self.subsystems : subsystems // ignore: cast_nullable_to_non_nullable
as HealthSubsystems,
  ));
}

/// Create a copy of HealthResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HealthSubsystemsCopyWith<$Res> get subsystems {
  
  return $HealthSubsystemsCopyWith<$Res>(_self.subsystems, (value) {
    return _then(_self.copyWith(subsystems: value));
  });
}
}

// dart format on
