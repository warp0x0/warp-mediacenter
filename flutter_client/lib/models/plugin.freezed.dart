// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plugin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PluginAuthState {

 bool get required; bool get connected; bool get configured; String? get status; String? get username; String? get detail; String? get plan; bool get reauthRequired; String? get reauthReason; double? get expiresAt; PluginAuthFlow? get flow;
/// Create a copy of PluginAuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PluginAuthStateCopyWith<PluginAuthState> get copyWith => _$PluginAuthStateCopyWithImpl<PluginAuthState>(this as PluginAuthState, _$identity);

  /// Serializes this PluginAuthState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PluginAuthState&&(identical(other.required, required) || other.required == required)&&(identical(other.connected, connected) || other.connected == connected)&&(identical(other.configured, configured) || other.configured == configured)&&(identical(other.status, status) || other.status == status)&&(identical(other.username, username) || other.username == username)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.reauthRequired, reauthRequired) || other.reauthRequired == reauthRequired)&&(identical(other.reauthReason, reauthReason) || other.reauthReason == reauthReason)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.flow, flow) || other.flow == flow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,required,connected,configured,status,username,detail,plan,reauthRequired,reauthReason,expiresAt,flow);

@override
String toString() {
  return 'PluginAuthState(required: $required, connected: $connected, configured: $configured, status: $status, username: $username, detail: $detail, plan: $plan, reauthRequired: $reauthRequired, reauthReason: $reauthReason, expiresAt: $expiresAt, flow: $flow)';
}


}

/// @nodoc
abstract mixin class $PluginAuthStateCopyWith<$Res>  {
  factory $PluginAuthStateCopyWith(PluginAuthState value, $Res Function(PluginAuthState) _then) = _$PluginAuthStateCopyWithImpl;
@useResult
$Res call({
 bool required, bool connected, bool configured, String? status, String? username, String? detail, String? plan, bool reauthRequired, String? reauthReason, double? expiresAt, PluginAuthFlow? flow
});


$PluginAuthFlowCopyWith<$Res>? get flow;

}
/// @nodoc
class _$PluginAuthStateCopyWithImpl<$Res>
    implements $PluginAuthStateCopyWith<$Res> {
  _$PluginAuthStateCopyWithImpl(this._self, this._then);

  final PluginAuthState _self;
  final $Res Function(PluginAuthState) _then;

/// Create a copy of PluginAuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? required = null,Object? connected = null,Object? configured = null,Object? status = freezed,Object? username = freezed,Object? detail = freezed,Object? plan = freezed,Object? reauthRequired = null,Object? reauthReason = freezed,Object? expiresAt = freezed,Object? flow = freezed,}) {
  return _then(_self.copyWith(
required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,connected: null == connected ? _self.connected : connected // ignore: cast_nullable_to_non_nullable
as bool,configured: null == configured ? _self.configured : configured // ignore: cast_nullable_to_non_nullable
as bool,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String?,reauthRequired: null == reauthRequired ? _self.reauthRequired : reauthRequired // ignore: cast_nullable_to_non_nullable
as bool,reauthReason: freezed == reauthReason ? _self.reauthReason : reauthReason // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as double?,flow: freezed == flow ? _self.flow : flow // ignore: cast_nullable_to_non_nullable
as PluginAuthFlow?,
  ));
}
/// Create a copy of PluginAuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PluginAuthFlowCopyWith<$Res>? get flow {
    if (_self.flow == null) {
    return null;
  }

  return $PluginAuthFlowCopyWith<$Res>(_self.flow!, (value) {
    return _then(_self.copyWith(flow: value));
  });
}
}


/// Adds pattern-matching-related methods to [PluginAuthState].
extension PluginAuthStatePatterns on PluginAuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PluginAuthState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PluginAuthState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PluginAuthState value)  $default,){
final _that = this;
switch (_that) {
case _PluginAuthState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PluginAuthState value)?  $default,){
final _that = this;
switch (_that) {
case _PluginAuthState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool required,  bool connected,  bool configured,  String? status,  String? username,  String? detail,  String? plan,  bool reauthRequired,  String? reauthReason,  double? expiresAt,  PluginAuthFlow? flow)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PluginAuthState() when $default != null:
return $default(_that.required,_that.connected,_that.configured,_that.status,_that.username,_that.detail,_that.plan,_that.reauthRequired,_that.reauthReason,_that.expiresAt,_that.flow);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool required,  bool connected,  bool configured,  String? status,  String? username,  String? detail,  String? plan,  bool reauthRequired,  String? reauthReason,  double? expiresAt,  PluginAuthFlow? flow)  $default,) {final _that = this;
switch (_that) {
case _PluginAuthState():
return $default(_that.required,_that.connected,_that.configured,_that.status,_that.username,_that.detail,_that.plan,_that.reauthRequired,_that.reauthReason,_that.expiresAt,_that.flow);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool required,  bool connected,  bool configured,  String? status,  String? username,  String? detail,  String? plan,  bool reauthRequired,  String? reauthReason,  double? expiresAt,  PluginAuthFlow? flow)?  $default,) {final _that = this;
switch (_that) {
case _PluginAuthState() when $default != null:
return $default(_that.required,_that.connected,_that.configured,_that.status,_that.username,_that.detail,_that.plan,_that.reauthRequired,_that.reauthReason,_that.expiresAt,_that.flow);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PluginAuthState implements PluginAuthState {
  const _PluginAuthState({this.required = false, this.connected = false, this.configured = false, this.status, this.username, this.detail, this.plan, this.reauthRequired = false, this.reauthReason, this.expiresAt, this.flow});
  factory _PluginAuthState.fromJson(Map<String, dynamic> json) => _$PluginAuthStateFromJson(json);

@override@JsonKey() final  bool required;
@override@JsonKey() final  bool connected;
@override@JsonKey() final  bool configured;
@override final  String? status;
@override final  String? username;
@override final  String? detail;
@override final  String? plan;
@override@JsonKey() final  bool reauthRequired;
@override final  String? reauthReason;
@override final  double? expiresAt;
@override final  PluginAuthFlow? flow;

/// Create a copy of PluginAuthState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PluginAuthStateCopyWith<_PluginAuthState> get copyWith => __$PluginAuthStateCopyWithImpl<_PluginAuthState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PluginAuthStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PluginAuthState&&(identical(other.required, required) || other.required == required)&&(identical(other.connected, connected) || other.connected == connected)&&(identical(other.configured, configured) || other.configured == configured)&&(identical(other.status, status) || other.status == status)&&(identical(other.username, username) || other.username == username)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.reauthRequired, reauthRequired) || other.reauthRequired == reauthRequired)&&(identical(other.reauthReason, reauthReason) || other.reauthReason == reauthReason)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.flow, flow) || other.flow == flow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,required,connected,configured,status,username,detail,plan,reauthRequired,reauthReason,expiresAt,flow);

@override
String toString() {
  return 'PluginAuthState(required: $required, connected: $connected, configured: $configured, status: $status, username: $username, detail: $detail, plan: $plan, reauthRequired: $reauthRequired, reauthReason: $reauthReason, expiresAt: $expiresAt, flow: $flow)';
}


}

/// @nodoc
abstract mixin class _$PluginAuthStateCopyWith<$Res> implements $PluginAuthStateCopyWith<$Res> {
  factory _$PluginAuthStateCopyWith(_PluginAuthState value, $Res Function(_PluginAuthState) _then) = __$PluginAuthStateCopyWithImpl;
@override @useResult
$Res call({
 bool required, bool connected, bool configured, String? status, String? username, String? detail, String? plan, bool reauthRequired, String? reauthReason, double? expiresAt, PluginAuthFlow? flow
});


@override $PluginAuthFlowCopyWith<$Res>? get flow;

}
/// @nodoc
class __$PluginAuthStateCopyWithImpl<$Res>
    implements _$PluginAuthStateCopyWith<$Res> {
  __$PluginAuthStateCopyWithImpl(this._self, this._then);

  final _PluginAuthState _self;
  final $Res Function(_PluginAuthState) _then;

/// Create a copy of PluginAuthState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? required = null,Object? connected = null,Object? configured = null,Object? status = freezed,Object? username = freezed,Object? detail = freezed,Object? plan = freezed,Object? reauthRequired = null,Object? reauthReason = freezed,Object? expiresAt = freezed,Object? flow = freezed,}) {
  return _then(_PluginAuthState(
required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,connected: null == connected ? _self.connected : connected // ignore: cast_nullable_to_non_nullable
as bool,configured: null == configured ? _self.configured : configured // ignore: cast_nullable_to_non_nullable
as bool,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String?,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String?,reauthRequired: null == reauthRequired ? _self.reauthRequired : reauthRequired // ignore: cast_nullable_to_non_nullable
as bool,reauthReason: freezed == reauthReason ? _self.reauthReason : reauthReason // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as double?,flow: freezed == flow ? _self.flow : flow // ignore: cast_nullable_to_non_nullable
as PluginAuthFlow?,
  ));
}

/// Create a copy of PluginAuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PluginAuthFlowCopyWith<$Res>? get flow {
    if (_self.flow == null) {
    return null;
  }

  return $PluginAuthFlowCopyWith<$Res>(_self.flow!, (value) {
    return _then(_self.copyWith(flow: value));
  });
}
}


/// @nodoc
mixin _$PluginAuthFlow {

 String get status; String? get error; String? get userCode; String? get verificationUrl; double? get expiresAt; int get interval;
/// Create a copy of PluginAuthFlow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PluginAuthFlowCopyWith<PluginAuthFlow> get copyWith => _$PluginAuthFlowCopyWithImpl<PluginAuthFlow>(this as PluginAuthFlow, _$identity);

  /// Serializes this PluginAuthFlow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PluginAuthFlow&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error)&&(identical(other.userCode, userCode) || other.userCode == userCode)&&(identical(other.verificationUrl, verificationUrl) || other.verificationUrl == verificationUrl)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.interval, interval) || other.interval == interval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,error,userCode,verificationUrl,expiresAt,interval);

@override
String toString() {
  return 'PluginAuthFlow(status: $status, error: $error, userCode: $userCode, verificationUrl: $verificationUrl, expiresAt: $expiresAt, interval: $interval)';
}


}

/// @nodoc
abstract mixin class $PluginAuthFlowCopyWith<$Res>  {
  factory $PluginAuthFlowCopyWith(PluginAuthFlow value, $Res Function(PluginAuthFlow) _then) = _$PluginAuthFlowCopyWithImpl;
@useResult
$Res call({
 String status, String? error, String? userCode, String? verificationUrl, double? expiresAt, int interval
});




}
/// @nodoc
class _$PluginAuthFlowCopyWithImpl<$Res>
    implements $PluginAuthFlowCopyWith<$Res> {
  _$PluginAuthFlowCopyWithImpl(this._self, this._then);

  final PluginAuthFlow _self;
  final $Res Function(PluginAuthFlow) _then;

/// Create a copy of PluginAuthFlow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? error = freezed,Object? userCode = freezed,Object? verificationUrl = freezed,Object? expiresAt = freezed,Object? interval = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,userCode: freezed == userCode ? _self.userCode : userCode // ignore: cast_nullable_to_non_nullable
as String?,verificationUrl: freezed == verificationUrl ? _self.verificationUrl : verificationUrl // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as double?,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PluginAuthFlow].
extension PluginAuthFlowPatterns on PluginAuthFlow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PluginAuthFlow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PluginAuthFlow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PluginAuthFlow value)  $default,){
final _that = this;
switch (_that) {
case _PluginAuthFlow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PluginAuthFlow value)?  $default,){
final _that = this;
switch (_that) {
case _PluginAuthFlow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String? error,  String? userCode,  String? verificationUrl,  double? expiresAt,  int interval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PluginAuthFlow() when $default != null:
return $default(_that.status,_that.error,_that.userCode,_that.verificationUrl,_that.expiresAt,_that.interval);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String? error,  String? userCode,  String? verificationUrl,  double? expiresAt,  int interval)  $default,) {final _that = this;
switch (_that) {
case _PluginAuthFlow():
return $default(_that.status,_that.error,_that.userCode,_that.verificationUrl,_that.expiresAt,_that.interval);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String? error,  String? userCode,  String? verificationUrl,  double? expiresAt,  int interval)?  $default,) {final _that = this;
switch (_that) {
case _PluginAuthFlow() when $default != null:
return $default(_that.status,_that.error,_that.userCode,_that.verificationUrl,_that.expiresAt,_that.interval);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PluginAuthFlow implements PluginAuthFlow {
  const _PluginAuthFlow({this.status = 'none', this.error, this.userCode, this.verificationUrl, this.expiresAt, this.interval = 5});
  factory _PluginAuthFlow.fromJson(Map<String, dynamic> json) => _$PluginAuthFlowFromJson(json);

@override@JsonKey() final  String status;
@override final  String? error;
@override final  String? userCode;
@override final  String? verificationUrl;
@override final  double? expiresAt;
@override@JsonKey() final  int interval;

/// Create a copy of PluginAuthFlow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PluginAuthFlowCopyWith<_PluginAuthFlow> get copyWith => __$PluginAuthFlowCopyWithImpl<_PluginAuthFlow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PluginAuthFlowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PluginAuthFlow&&(identical(other.status, status) || other.status == status)&&(identical(other.error, error) || other.error == error)&&(identical(other.userCode, userCode) || other.userCode == userCode)&&(identical(other.verificationUrl, verificationUrl) || other.verificationUrl == verificationUrl)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.interval, interval) || other.interval == interval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,error,userCode,verificationUrl,expiresAt,interval);

@override
String toString() {
  return 'PluginAuthFlow(status: $status, error: $error, userCode: $userCode, verificationUrl: $verificationUrl, expiresAt: $expiresAt, interval: $interval)';
}


}

/// @nodoc
abstract mixin class _$PluginAuthFlowCopyWith<$Res> implements $PluginAuthFlowCopyWith<$Res> {
  factory _$PluginAuthFlowCopyWith(_PluginAuthFlow value, $Res Function(_PluginAuthFlow) _then) = __$PluginAuthFlowCopyWithImpl;
@override @useResult
$Res call({
 String status, String? error, String? userCode, String? verificationUrl, double? expiresAt, int interval
});




}
/// @nodoc
class __$PluginAuthFlowCopyWithImpl<$Res>
    implements _$PluginAuthFlowCopyWith<$Res> {
  __$PluginAuthFlowCopyWithImpl(this._self, this._then);

  final _PluginAuthFlow _self;
  final $Res Function(_PluginAuthFlow) _then;

/// Create a copy of PluginAuthFlow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? error = freezed,Object? userCode = freezed,Object? verificationUrl = freezed,Object? expiresAt = freezed,Object? interval = null,}) {
  return _then(_PluginAuthFlow(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,userCode: freezed == userCode ? _self.userCode : userCode // ignore: cast_nullable_to_non_nullable
as String?,verificationUrl: freezed == verificationUrl ? _self.verificationUrl : verificationUrl // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as double?,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PluginSummary {

 String get pluginId; String get category; String get name; String get version; bool get enabled; bool get exclusive; bool get hasSettings; String? get description; String? get icon; String? get author; String? get homepage; String? get authKind; List<String> get capabilities; PluginAuthState? get auth;
/// Create a copy of PluginSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PluginSummaryCopyWith<PluginSummary> get copyWith => _$PluginSummaryCopyWithImpl<PluginSummary>(this as PluginSummary, _$identity);

  /// Serializes this PluginSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PluginSummary&&(identical(other.pluginId, pluginId) || other.pluginId == pluginId)&&(identical(other.category, category) || other.category == category)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.exclusive, exclusive) || other.exclusive == exclusive)&&(identical(other.hasSettings, hasSettings) || other.hasSettings == hasSettings)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.author, author) || other.author == author)&&(identical(other.homepage, homepage) || other.homepage == homepage)&&(identical(other.authKind, authKind) || other.authKind == authKind)&&const DeepCollectionEquality().equals(other.capabilities, capabilities)&&(identical(other.auth, auth) || other.auth == auth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pluginId,category,name,version,enabled,exclusive,hasSettings,description,icon,author,homepage,authKind,const DeepCollectionEquality().hash(capabilities),auth);

@override
String toString() {
  return 'PluginSummary(pluginId: $pluginId, category: $category, name: $name, version: $version, enabled: $enabled, exclusive: $exclusive, hasSettings: $hasSettings, description: $description, icon: $icon, author: $author, homepage: $homepage, authKind: $authKind, capabilities: $capabilities, auth: $auth)';
}


}

/// @nodoc
abstract mixin class $PluginSummaryCopyWith<$Res>  {
  factory $PluginSummaryCopyWith(PluginSummary value, $Res Function(PluginSummary) _then) = _$PluginSummaryCopyWithImpl;
@useResult
$Res call({
 String pluginId, String category, String name, String version, bool enabled, bool exclusive, bool hasSettings, String? description, String? icon, String? author, String? homepage, String? authKind, List<String> capabilities, PluginAuthState? auth
});


$PluginAuthStateCopyWith<$Res>? get auth;

}
/// @nodoc
class _$PluginSummaryCopyWithImpl<$Res>
    implements $PluginSummaryCopyWith<$Res> {
  _$PluginSummaryCopyWithImpl(this._self, this._then);

  final PluginSummary _self;
  final $Res Function(PluginSummary) _then;

/// Create a copy of PluginSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pluginId = null,Object? category = null,Object? name = null,Object? version = null,Object? enabled = null,Object? exclusive = null,Object? hasSettings = null,Object? description = freezed,Object? icon = freezed,Object? author = freezed,Object? homepage = freezed,Object? authKind = freezed,Object? capabilities = null,Object? auth = freezed,}) {
  return _then(_self.copyWith(
pluginId: null == pluginId ? _self.pluginId : pluginId // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,exclusive: null == exclusive ? _self.exclusive : exclusive // ignore: cast_nullable_to_non_nullable
as bool,hasSettings: null == hasSettings ? _self.hasSettings : hasSettings // ignore: cast_nullable_to_non_nullable
as bool,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,homepage: freezed == homepage ? _self.homepage : homepage // ignore: cast_nullable_to_non_nullable
as String?,authKind: freezed == authKind ? _self.authKind : authKind // ignore: cast_nullable_to_non_nullable
as String?,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as List<String>,auth: freezed == auth ? _self.auth : auth // ignore: cast_nullable_to_non_nullable
as PluginAuthState?,
  ));
}
/// Create a copy of PluginSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PluginAuthStateCopyWith<$Res>? get auth {
    if (_self.auth == null) {
    return null;
  }

  return $PluginAuthStateCopyWith<$Res>(_self.auth!, (value) {
    return _then(_self.copyWith(auth: value));
  });
}
}


/// Adds pattern-matching-related methods to [PluginSummary].
extension PluginSummaryPatterns on PluginSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PluginSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PluginSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PluginSummary value)  $default,){
final _that = this;
switch (_that) {
case _PluginSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PluginSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PluginSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String pluginId,  String category,  String name,  String version,  bool enabled,  bool exclusive,  bool hasSettings,  String? description,  String? icon,  String? author,  String? homepage,  String? authKind,  List<String> capabilities,  PluginAuthState? auth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PluginSummary() when $default != null:
return $default(_that.pluginId,_that.category,_that.name,_that.version,_that.enabled,_that.exclusive,_that.hasSettings,_that.description,_that.icon,_that.author,_that.homepage,_that.authKind,_that.capabilities,_that.auth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String pluginId,  String category,  String name,  String version,  bool enabled,  bool exclusive,  bool hasSettings,  String? description,  String? icon,  String? author,  String? homepage,  String? authKind,  List<String> capabilities,  PluginAuthState? auth)  $default,) {final _that = this;
switch (_that) {
case _PluginSummary():
return $default(_that.pluginId,_that.category,_that.name,_that.version,_that.enabled,_that.exclusive,_that.hasSettings,_that.description,_that.icon,_that.author,_that.homepage,_that.authKind,_that.capabilities,_that.auth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String pluginId,  String category,  String name,  String version,  bool enabled,  bool exclusive,  bool hasSettings,  String? description,  String? icon,  String? author,  String? homepage,  String? authKind,  List<String> capabilities,  PluginAuthState? auth)?  $default,) {final _that = this;
switch (_that) {
case _PluginSummary() when $default != null:
return $default(_that.pluginId,_that.category,_that.name,_that.version,_that.enabled,_that.exclusive,_that.hasSettings,_that.description,_that.icon,_that.author,_that.homepage,_that.authKind,_that.capabilities,_that.auth);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PluginSummary implements PluginSummary {
  const _PluginSummary({required this.pluginId, required this.category, required this.name, required this.version, this.enabled = false, this.exclusive = false, this.hasSettings = false, this.description, this.icon, this.author, this.homepage, this.authKind, final  List<String> capabilities = const [], this.auth}): _capabilities = capabilities;
  factory _PluginSummary.fromJson(Map<String, dynamic> json) => _$PluginSummaryFromJson(json);

@override final  String pluginId;
@override final  String category;
@override final  String name;
@override final  String version;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  bool exclusive;
@override@JsonKey() final  bool hasSettings;
@override final  String? description;
@override final  String? icon;
@override final  String? author;
@override final  String? homepage;
@override final  String? authKind;
 final  List<String> _capabilities;
@override@JsonKey() List<String> get capabilities {
  if (_capabilities is EqualUnmodifiableListView) return _capabilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_capabilities);
}

@override final  PluginAuthState? auth;

/// Create a copy of PluginSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PluginSummaryCopyWith<_PluginSummary> get copyWith => __$PluginSummaryCopyWithImpl<_PluginSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PluginSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PluginSummary&&(identical(other.pluginId, pluginId) || other.pluginId == pluginId)&&(identical(other.category, category) || other.category == category)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.exclusive, exclusive) || other.exclusive == exclusive)&&(identical(other.hasSettings, hasSettings) || other.hasSettings == hasSettings)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.author, author) || other.author == author)&&(identical(other.homepage, homepage) || other.homepage == homepage)&&(identical(other.authKind, authKind) || other.authKind == authKind)&&const DeepCollectionEquality().equals(other._capabilities, _capabilities)&&(identical(other.auth, auth) || other.auth == auth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pluginId,category,name,version,enabled,exclusive,hasSettings,description,icon,author,homepage,authKind,const DeepCollectionEquality().hash(_capabilities),auth);

@override
String toString() {
  return 'PluginSummary(pluginId: $pluginId, category: $category, name: $name, version: $version, enabled: $enabled, exclusive: $exclusive, hasSettings: $hasSettings, description: $description, icon: $icon, author: $author, homepage: $homepage, authKind: $authKind, capabilities: $capabilities, auth: $auth)';
}


}

/// @nodoc
abstract mixin class _$PluginSummaryCopyWith<$Res> implements $PluginSummaryCopyWith<$Res> {
  factory _$PluginSummaryCopyWith(_PluginSummary value, $Res Function(_PluginSummary) _then) = __$PluginSummaryCopyWithImpl;
@override @useResult
$Res call({
 String pluginId, String category, String name, String version, bool enabled, bool exclusive, bool hasSettings, String? description, String? icon, String? author, String? homepage, String? authKind, List<String> capabilities, PluginAuthState? auth
});


@override $PluginAuthStateCopyWith<$Res>? get auth;

}
/// @nodoc
class __$PluginSummaryCopyWithImpl<$Res>
    implements _$PluginSummaryCopyWith<$Res> {
  __$PluginSummaryCopyWithImpl(this._self, this._then);

  final _PluginSummary _self;
  final $Res Function(_PluginSummary) _then;

/// Create a copy of PluginSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pluginId = null,Object? category = null,Object? name = null,Object? version = null,Object? enabled = null,Object? exclusive = null,Object? hasSettings = null,Object? description = freezed,Object? icon = freezed,Object? author = freezed,Object? homepage = freezed,Object? authKind = freezed,Object? capabilities = null,Object? auth = freezed,}) {
  return _then(_PluginSummary(
pluginId: null == pluginId ? _self.pluginId : pluginId // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,exclusive: null == exclusive ? _self.exclusive : exclusive // ignore: cast_nullable_to_non_nullable
as bool,hasSettings: null == hasSettings ? _self.hasSettings : hasSettings // ignore: cast_nullable_to_non_nullable
as bool,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String?,homepage: freezed == homepage ? _self.homepage : homepage // ignore: cast_nullable_to_non_nullable
as String?,authKind: freezed == authKind ? _self.authKind : authKind // ignore: cast_nullable_to_non_nullable
as String?,capabilities: null == capabilities ? _self._capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as List<String>,auth: freezed == auth ? _self.auth : auth // ignore: cast_nullable_to_non_nullable
as PluginAuthState?,
  ));
}

/// Create a copy of PluginSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PluginAuthStateCopyWith<$Res>? get auth {
    if (_self.auth == null) {
    return null;
  }

  return $PluginAuthStateCopyWith<$Res>(_self.auth!, (value) {
    return _then(_self.copyWith(auth: value));
  });
}
}


/// @nodoc
mixin _$PluginCategory {

 String get id; String get label; String get description; bool get exclusive; List<PluginSummary> get installed; String? get activePluginId;
/// Create a copy of PluginCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PluginCategoryCopyWith<PluginCategory> get copyWith => _$PluginCategoryCopyWithImpl<PluginCategory>(this as PluginCategory, _$identity);

  /// Serializes this PluginCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PluginCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description)&&(identical(other.exclusive, exclusive) || other.exclusive == exclusive)&&const DeepCollectionEquality().equals(other.installed, installed)&&(identical(other.activePluginId, activePluginId) || other.activePluginId == activePluginId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,description,exclusive,const DeepCollectionEquality().hash(installed),activePluginId);

@override
String toString() {
  return 'PluginCategory(id: $id, label: $label, description: $description, exclusive: $exclusive, installed: $installed, activePluginId: $activePluginId)';
}


}

/// @nodoc
abstract mixin class $PluginCategoryCopyWith<$Res>  {
  factory $PluginCategoryCopyWith(PluginCategory value, $Res Function(PluginCategory) _then) = _$PluginCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String label, String description, bool exclusive, List<PluginSummary> installed, String? activePluginId
});




}
/// @nodoc
class _$PluginCategoryCopyWithImpl<$Res>
    implements $PluginCategoryCopyWith<$Res> {
  _$PluginCategoryCopyWithImpl(this._self, this._then);

  final PluginCategory _self;
  final $Res Function(PluginCategory) _then;

/// Create a copy of PluginCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? description = null,Object? exclusive = null,Object? installed = null,Object? activePluginId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,exclusive: null == exclusive ? _self.exclusive : exclusive // ignore: cast_nullable_to_non_nullable
as bool,installed: null == installed ? _self.installed : installed // ignore: cast_nullable_to_non_nullable
as List<PluginSummary>,activePluginId: freezed == activePluginId ? _self.activePluginId : activePluginId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PluginCategory].
extension PluginCategoryPatterns on PluginCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PluginCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PluginCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PluginCategory value)  $default,){
final _that = this;
switch (_that) {
case _PluginCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PluginCategory value)?  $default,){
final _that = this;
switch (_that) {
case _PluginCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String description,  bool exclusive,  List<PluginSummary> installed,  String? activePluginId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PluginCategory() when $default != null:
return $default(_that.id,_that.label,_that.description,_that.exclusive,_that.installed,_that.activePluginId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String description,  bool exclusive,  List<PluginSummary> installed,  String? activePluginId)  $default,) {final _that = this;
switch (_that) {
case _PluginCategory():
return $default(_that.id,_that.label,_that.description,_that.exclusive,_that.installed,_that.activePluginId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String description,  bool exclusive,  List<PluginSummary> installed,  String? activePluginId)?  $default,) {final _that = this;
switch (_that) {
case _PluginCategory() when $default != null:
return $default(_that.id,_that.label,_that.description,_that.exclusive,_that.installed,_that.activePluginId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PluginCategory implements PluginCategory {
  const _PluginCategory({required this.id, required this.label, this.description = '', this.exclusive = false, final  List<PluginSummary> installed = const [], this.activePluginId}): _installed = installed;
  factory _PluginCategory.fromJson(Map<String, dynamic> json) => _$PluginCategoryFromJson(json);

@override final  String id;
@override final  String label;
@override@JsonKey() final  String description;
@override@JsonKey() final  bool exclusive;
 final  List<PluginSummary> _installed;
@override@JsonKey() List<PluginSummary> get installed {
  if (_installed is EqualUnmodifiableListView) return _installed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_installed);
}

@override final  String? activePluginId;

/// Create a copy of PluginCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PluginCategoryCopyWith<_PluginCategory> get copyWith => __$PluginCategoryCopyWithImpl<_PluginCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PluginCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PluginCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description)&&(identical(other.exclusive, exclusive) || other.exclusive == exclusive)&&const DeepCollectionEquality().equals(other._installed, _installed)&&(identical(other.activePluginId, activePluginId) || other.activePluginId == activePluginId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,description,exclusive,const DeepCollectionEquality().hash(_installed),activePluginId);

@override
String toString() {
  return 'PluginCategory(id: $id, label: $label, description: $description, exclusive: $exclusive, installed: $installed, activePluginId: $activePluginId)';
}


}

/// @nodoc
abstract mixin class _$PluginCategoryCopyWith<$Res> implements $PluginCategoryCopyWith<$Res> {
  factory _$PluginCategoryCopyWith(_PluginCategory value, $Res Function(_PluginCategory) _then) = __$PluginCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String description, bool exclusive, List<PluginSummary> installed, String? activePluginId
});




}
/// @nodoc
class __$PluginCategoryCopyWithImpl<$Res>
    implements _$PluginCategoryCopyWith<$Res> {
  __$PluginCategoryCopyWithImpl(this._self, this._then);

  final _PluginCategory _self;
  final $Res Function(_PluginCategory) _then;

/// Create a copy of PluginCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? description = null,Object? exclusive = null,Object? installed = null,Object? activePluginId = freezed,}) {
  return _then(_PluginCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,exclusive: null == exclusive ? _self.exclusive : exclusive // ignore: cast_nullable_to_non_nullable
as bool,installed: null == installed ? _self._installed : installed // ignore: cast_nullable_to_non_nullable
as List<PluginSummary>,activePluginId: freezed == activePluginId ? _self.activePluginId : activePluginId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PluginCategoriesResponse {

 List<PluginCategory> get categories;
/// Create a copy of PluginCategoriesResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PluginCategoriesResponseCopyWith<PluginCategoriesResponse> get copyWith => _$PluginCategoriesResponseCopyWithImpl<PluginCategoriesResponse>(this as PluginCategoriesResponse, _$identity);

  /// Serializes this PluginCategoriesResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PluginCategoriesResponse&&const DeepCollectionEquality().equals(other.categories, categories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categories));

@override
String toString() {
  return 'PluginCategoriesResponse(categories: $categories)';
}


}

/// @nodoc
abstract mixin class $PluginCategoriesResponseCopyWith<$Res>  {
  factory $PluginCategoriesResponseCopyWith(PluginCategoriesResponse value, $Res Function(PluginCategoriesResponse) _then) = _$PluginCategoriesResponseCopyWithImpl;
@useResult
$Res call({
 List<PluginCategory> categories
});




}
/// @nodoc
class _$PluginCategoriesResponseCopyWithImpl<$Res>
    implements $PluginCategoriesResponseCopyWith<$Res> {
  _$PluginCategoriesResponseCopyWithImpl(this._self, this._then);

  final PluginCategoriesResponse _self;
  final $Res Function(PluginCategoriesResponse) _then;

/// Create a copy of PluginCategoriesResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categories = null,}) {
  return _then(_self.copyWith(
categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<PluginCategory>,
  ));
}

}


/// Adds pattern-matching-related methods to [PluginCategoriesResponse].
extension PluginCategoriesResponsePatterns on PluginCategoriesResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PluginCategoriesResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PluginCategoriesResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PluginCategoriesResponse value)  $default,){
final _that = this;
switch (_that) {
case _PluginCategoriesResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PluginCategoriesResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PluginCategoriesResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PluginCategory> categories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PluginCategoriesResponse() when $default != null:
return $default(_that.categories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PluginCategory> categories)  $default,) {final _that = this;
switch (_that) {
case _PluginCategoriesResponse():
return $default(_that.categories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PluginCategory> categories)?  $default,) {final _that = this;
switch (_that) {
case _PluginCategoriesResponse() when $default != null:
return $default(_that.categories);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PluginCategoriesResponse implements PluginCategoriesResponse {
  const _PluginCategoriesResponse({final  List<PluginCategory> categories = const []}): _categories = categories;
  factory _PluginCategoriesResponse.fromJson(Map<String, dynamic> json) => _$PluginCategoriesResponseFromJson(json);

 final  List<PluginCategory> _categories;
@override@JsonKey() List<PluginCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}


/// Create a copy of PluginCategoriesResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PluginCategoriesResponseCopyWith<_PluginCategoriesResponse> get copyWith => __$PluginCategoriesResponseCopyWithImpl<_PluginCategoriesResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PluginCategoriesResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PluginCategoriesResponse&&const DeepCollectionEquality().equals(other._categories, _categories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories));

@override
String toString() {
  return 'PluginCategoriesResponse(categories: $categories)';
}


}

/// @nodoc
abstract mixin class _$PluginCategoriesResponseCopyWith<$Res> implements $PluginCategoriesResponseCopyWith<$Res> {
  factory _$PluginCategoriesResponseCopyWith(_PluginCategoriesResponse value, $Res Function(_PluginCategoriesResponse) _then) = __$PluginCategoriesResponseCopyWithImpl;
@override @useResult
$Res call({
 List<PluginCategory> categories
});




}
/// @nodoc
class __$PluginCategoriesResponseCopyWithImpl<$Res>
    implements _$PluginCategoriesResponseCopyWith<$Res> {
  __$PluginCategoriesResponseCopyWithImpl(this._self, this._then);

  final _PluginCategoriesResponse _self;
  final $Res Function(_PluginCategoriesResponse) _then;

/// Create a copy of PluginCategoriesResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categories = null,}) {
  return _then(_PluginCategoriesResponse(
categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<PluginCategory>,
  ));
}


}

// dart format on
