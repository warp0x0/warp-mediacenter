// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthStatus {

 bool get authenticated; bool get pending; bool get expired; bool get denied; String? get error; String? get reason; String? get expiresAt; String? get lastRefreshYmd;
/// Create a copy of AuthStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthStatusCopyWith<AuthStatus> get copyWith => _$AuthStatusCopyWithImpl<AuthStatus>(this as AuthStatus, _$identity);

  /// Serializes this AuthStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthStatus&&(identical(other.authenticated, authenticated) || other.authenticated == authenticated)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.expired, expired) || other.expired == expired)&&(identical(other.denied, denied) || other.denied == denied)&&(identical(other.error, error) || other.error == error)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.lastRefreshYmd, lastRefreshYmd) || other.lastRefreshYmd == lastRefreshYmd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,authenticated,pending,expired,denied,error,reason,expiresAt,lastRefreshYmd);

@override
String toString() {
  return 'AuthStatus(authenticated: $authenticated, pending: $pending, expired: $expired, denied: $denied, error: $error, reason: $reason, expiresAt: $expiresAt, lastRefreshYmd: $lastRefreshYmd)';
}


}

/// @nodoc
abstract mixin class $AuthStatusCopyWith<$Res>  {
  factory $AuthStatusCopyWith(AuthStatus value, $Res Function(AuthStatus) _then) = _$AuthStatusCopyWithImpl;
@useResult
$Res call({
 bool authenticated, bool pending, bool expired, bool denied, String? error, String? reason, String? expiresAt, String? lastRefreshYmd
});




}
/// @nodoc
class _$AuthStatusCopyWithImpl<$Res>
    implements $AuthStatusCopyWith<$Res> {
  _$AuthStatusCopyWithImpl(this._self, this._then);

  final AuthStatus _self;
  final $Res Function(AuthStatus) _then;

/// Create a copy of AuthStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? authenticated = null,Object? pending = null,Object? expired = null,Object? denied = null,Object? error = freezed,Object? reason = freezed,Object? expiresAt = freezed,Object? lastRefreshYmd = freezed,}) {
  return _then(_self.copyWith(
authenticated: null == authenticated ? _self.authenticated : authenticated // ignore: cast_nullable_to_non_nullable
as bool,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,expired: null == expired ? _self.expired : expired // ignore: cast_nullable_to_non_nullable
as bool,denied: null == denied ? _self.denied : denied // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,lastRefreshYmd: freezed == lastRefreshYmd ? _self.lastRefreshYmd : lastRefreshYmd // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthStatus].
extension AuthStatusPatterns on AuthStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthStatus value)  $default,){
final _that = this;
switch (_that) {
case _AuthStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthStatus value)?  $default,){
final _that = this;
switch (_that) {
case _AuthStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool authenticated,  bool pending,  bool expired,  bool denied,  String? error,  String? reason,  String? expiresAt,  String? lastRefreshYmd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthStatus() when $default != null:
return $default(_that.authenticated,_that.pending,_that.expired,_that.denied,_that.error,_that.reason,_that.expiresAt,_that.lastRefreshYmd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool authenticated,  bool pending,  bool expired,  bool denied,  String? error,  String? reason,  String? expiresAt,  String? lastRefreshYmd)  $default,) {final _that = this;
switch (_that) {
case _AuthStatus():
return $default(_that.authenticated,_that.pending,_that.expired,_that.denied,_that.error,_that.reason,_that.expiresAt,_that.lastRefreshYmd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool authenticated,  bool pending,  bool expired,  bool denied,  String? error,  String? reason,  String? expiresAt,  String? lastRefreshYmd)?  $default,) {final _that = this;
switch (_that) {
case _AuthStatus() when $default != null:
return $default(_that.authenticated,_that.pending,_that.expired,_that.denied,_that.error,_that.reason,_that.expiresAt,_that.lastRefreshYmd);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthStatus implements AuthStatus {
  const _AuthStatus({required this.authenticated, required this.pending, required this.expired, required this.denied, this.error, this.reason, this.expiresAt, this.lastRefreshYmd});
  factory _AuthStatus.fromJson(Map<String, dynamic> json) => _$AuthStatusFromJson(json);

@override final  bool authenticated;
@override final  bool pending;
@override final  bool expired;
@override final  bool denied;
@override final  String? error;
@override final  String? reason;
@override final  String? expiresAt;
@override final  String? lastRefreshYmd;

/// Create a copy of AuthStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthStatusCopyWith<_AuthStatus> get copyWith => __$AuthStatusCopyWithImpl<_AuthStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthStatus&&(identical(other.authenticated, authenticated) || other.authenticated == authenticated)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.expired, expired) || other.expired == expired)&&(identical(other.denied, denied) || other.denied == denied)&&(identical(other.error, error) || other.error == error)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.lastRefreshYmd, lastRefreshYmd) || other.lastRefreshYmd == lastRefreshYmd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,authenticated,pending,expired,denied,error,reason,expiresAt,lastRefreshYmd);

@override
String toString() {
  return 'AuthStatus(authenticated: $authenticated, pending: $pending, expired: $expired, denied: $denied, error: $error, reason: $reason, expiresAt: $expiresAt, lastRefreshYmd: $lastRefreshYmd)';
}


}

/// @nodoc
abstract mixin class _$AuthStatusCopyWith<$Res> implements $AuthStatusCopyWith<$Res> {
  factory _$AuthStatusCopyWith(_AuthStatus value, $Res Function(_AuthStatus) _then) = __$AuthStatusCopyWithImpl;
@override @useResult
$Res call({
 bool authenticated, bool pending, bool expired, bool denied, String? error, String? reason, String? expiresAt, String? lastRefreshYmd
});




}
/// @nodoc
class __$AuthStatusCopyWithImpl<$Res>
    implements _$AuthStatusCopyWith<$Res> {
  __$AuthStatusCopyWithImpl(this._self, this._then);

  final _AuthStatus _self;
  final $Res Function(_AuthStatus) _then;

/// Create a copy of AuthStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? authenticated = null,Object? pending = null,Object? expired = null,Object? denied = null,Object? error = freezed,Object? reason = freezed,Object? expiresAt = freezed,Object? lastRefreshYmd = freezed,}) {
  return _then(_AuthStatus(
authenticated: null == authenticated ? _self.authenticated : authenticated // ignore: cast_nullable_to_non_nullable
as bool,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,expired: null == expired ? _self.expired : expired // ignore: cast_nullable_to_non_nullable
as bool,denied: null == denied ? _self.denied : denied // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,lastRefreshYmd: freezed == lastRefreshYmd ? _self.lastRefreshYmd : lastRefreshYmd // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TraktAuthStartResponse {

 String get deviceCode; String get userCode; String get verificationUrl; int get expiresIn; int get interval;
/// Create a copy of TraktAuthStartResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TraktAuthStartResponseCopyWith<TraktAuthStartResponse> get copyWith => _$TraktAuthStartResponseCopyWithImpl<TraktAuthStartResponse>(this as TraktAuthStartResponse, _$identity);

  /// Serializes this TraktAuthStartResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TraktAuthStartResponse&&(identical(other.deviceCode, deviceCode) || other.deviceCode == deviceCode)&&(identical(other.userCode, userCode) || other.userCode == userCode)&&(identical(other.verificationUrl, verificationUrl) || other.verificationUrl == verificationUrl)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.interval, interval) || other.interval == interval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceCode,userCode,verificationUrl,expiresIn,interval);

@override
String toString() {
  return 'TraktAuthStartResponse(deviceCode: $deviceCode, userCode: $userCode, verificationUrl: $verificationUrl, expiresIn: $expiresIn, interval: $interval)';
}


}

/// @nodoc
abstract mixin class $TraktAuthStartResponseCopyWith<$Res>  {
  factory $TraktAuthStartResponseCopyWith(TraktAuthStartResponse value, $Res Function(TraktAuthStartResponse) _then) = _$TraktAuthStartResponseCopyWithImpl;
@useResult
$Res call({
 String deviceCode, String userCode, String verificationUrl, int expiresIn, int interval
});




}
/// @nodoc
class _$TraktAuthStartResponseCopyWithImpl<$Res>
    implements $TraktAuthStartResponseCopyWith<$Res> {
  _$TraktAuthStartResponseCopyWithImpl(this._self, this._then);

  final TraktAuthStartResponse _self;
  final $Res Function(TraktAuthStartResponse) _then;

/// Create a copy of TraktAuthStartResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceCode = null,Object? userCode = null,Object? verificationUrl = null,Object? expiresIn = null,Object? interval = null,}) {
  return _then(_self.copyWith(
deviceCode: null == deviceCode ? _self.deviceCode : deviceCode // ignore: cast_nullable_to_non_nullable
as String,userCode: null == userCode ? _self.userCode : userCode // ignore: cast_nullable_to_non_nullable
as String,verificationUrl: null == verificationUrl ? _self.verificationUrl : verificationUrl // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TraktAuthStartResponse].
extension TraktAuthStartResponsePatterns on TraktAuthStartResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TraktAuthStartResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TraktAuthStartResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TraktAuthStartResponse value)  $default,){
final _that = this;
switch (_that) {
case _TraktAuthStartResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TraktAuthStartResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TraktAuthStartResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String deviceCode,  String userCode,  String verificationUrl,  int expiresIn,  int interval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TraktAuthStartResponse() when $default != null:
return $default(_that.deviceCode,_that.userCode,_that.verificationUrl,_that.expiresIn,_that.interval);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String deviceCode,  String userCode,  String verificationUrl,  int expiresIn,  int interval)  $default,) {final _that = this;
switch (_that) {
case _TraktAuthStartResponse():
return $default(_that.deviceCode,_that.userCode,_that.verificationUrl,_that.expiresIn,_that.interval);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String deviceCode,  String userCode,  String verificationUrl,  int expiresIn,  int interval)?  $default,) {final _that = this;
switch (_that) {
case _TraktAuthStartResponse() when $default != null:
return $default(_that.deviceCode,_that.userCode,_that.verificationUrl,_that.expiresIn,_that.interval);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TraktAuthStartResponse implements TraktAuthStartResponse {
  const _TraktAuthStartResponse({required this.deviceCode, required this.userCode, required this.verificationUrl, required this.expiresIn, required this.interval});
  factory _TraktAuthStartResponse.fromJson(Map<String, dynamic> json) => _$TraktAuthStartResponseFromJson(json);

@override final  String deviceCode;
@override final  String userCode;
@override final  String verificationUrl;
@override final  int expiresIn;
@override final  int interval;

/// Create a copy of TraktAuthStartResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TraktAuthStartResponseCopyWith<_TraktAuthStartResponse> get copyWith => __$TraktAuthStartResponseCopyWithImpl<_TraktAuthStartResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TraktAuthStartResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TraktAuthStartResponse&&(identical(other.deviceCode, deviceCode) || other.deviceCode == deviceCode)&&(identical(other.userCode, userCode) || other.userCode == userCode)&&(identical(other.verificationUrl, verificationUrl) || other.verificationUrl == verificationUrl)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.interval, interval) || other.interval == interval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceCode,userCode,verificationUrl,expiresIn,interval);

@override
String toString() {
  return 'TraktAuthStartResponse(deviceCode: $deviceCode, userCode: $userCode, verificationUrl: $verificationUrl, expiresIn: $expiresIn, interval: $interval)';
}


}

/// @nodoc
abstract mixin class _$TraktAuthStartResponseCopyWith<$Res> implements $TraktAuthStartResponseCopyWith<$Res> {
  factory _$TraktAuthStartResponseCopyWith(_TraktAuthStartResponse value, $Res Function(_TraktAuthStartResponse) _then) = __$TraktAuthStartResponseCopyWithImpl;
@override @useResult
$Res call({
 String deviceCode, String userCode, String verificationUrl, int expiresIn, int interval
});




}
/// @nodoc
class __$TraktAuthStartResponseCopyWithImpl<$Res>
    implements _$TraktAuthStartResponseCopyWith<$Res> {
  __$TraktAuthStartResponseCopyWithImpl(this._self, this._then);

  final _TraktAuthStartResponse _self;
  final $Res Function(_TraktAuthStartResponse) _then;

/// Create a copy of TraktAuthStartResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceCode = null,Object? userCode = null,Object? verificationUrl = null,Object? expiresIn = null,Object? interval = null,}) {
  return _then(_TraktAuthStartResponse(
deviceCode: null == deviceCode ? _self.deviceCode : deviceCode // ignore: cast_nullable_to_non_nullable
as String,userCode: null == userCode ? _self.userCode : userCode // ignore: cast_nullable_to_non_nullable
as String,verificationUrl: null == verificationUrl ? _self.verificationUrl : verificationUrl // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TraktUserProfile {

 String get username; String get name; bool get private; bool get vip; String? get about; String? get avatarUrl;
/// Create a copy of TraktUserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TraktUserProfileCopyWith<TraktUserProfile> get copyWith => _$TraktUserProfileCopyWithImpl<TraktUserProfile>(this as TraktUserProfile, _$identity);

  /// Serializes this TraktUserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TraktUserProfile&&(identical(other.username, username) || other.username == username)&&(identical(other.name, name) || other.name == name)&&(identical(other.private, private) || other.private == private)&&(identical(other.vip, vip) || other.vip == vip)&&(identical(other.about, about) || other.about == about)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,name,private,vip,about,avatarUrl);

@override
String toString() {
  return 'TraktUserProfile(username: $username, name: $name, private: $private, vip: $vip, about: $about, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $TraktUserProfileCopyWith<$Res>  {
  factory $TraktUserProfileCopyWith(TraktUserProfile value, $Res Function(TraktUserProfile) _then) = _$TraktUserProfileCopyWithImpl;
@useResult
$Res call({
 String username, String name, bool private, bool vip, String? about, String? avatarUrl
});




}
/// @nodoc
class _$TraktUserProfileCopyWithImpl<$Res>
    implements $TraktUserProfileCopyWith<$Res> {
  _$TraktUserProfileCopyWithImpl(this._self, this._then);

  final TraktUserProfile _self;
  final $Res Function(TraktUserProfile) _then;

/// Create a copy of TraktUserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? username = null,Object? name = null,Object? private = null,Object? vip = null,Object? about = freezed,Object? avatarUrl = freezed,}) {
  return _then(_self.copyWith(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,private: null == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool,vip: null == vip ? _self.vip : vip // ignore: cast_nullable_to_non_nullable
as bool,about: freezed == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TraktUserProfile].
extension TraktUserProfilePatterns on TraktUserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TraktUserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TraktUserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TraktUserProfile value)  $default,){
final _that = this;
switch (_that) {
case _TraktUserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TraktUserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _TraktUserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String username,  String name,  bool private,  bool vip,  String? about,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TraktUserProfile() when $default != null:
return $default(_that.username,_that.name,_that.private,_that.vip,_that.about,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String username,  String name,  bool private,  bool vip,  String? about,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _TraktUserProfile():
return $default(_that.username,_that.name,_that.private,_that.vip,_that.about,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String username,  String name,  bool private,  bool vip,  String? about,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _TraktUserProfile() when $default != null:
return $default(_that.username,_that.name,_that.private,_that.vip,_that.about,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TraktUserProfile implements TraktUserProfile {
  const _TraktUserProfile({required this.username, required this.name, required this.private, required this.vip, this.about, this.avatarUrl});
  factory _TraktUserProfile.fromJson(Map<String, dynamic> json) => _$TraktUserProfileFromJson(json);

@override final  String username;
@override final  String name;
@override final  bool private;
@override final  bool vip;
@override final  String? about;
@override final  String? avatarUrl;

/// Create a copy of TraktUserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TraktUserProfileCopyWith<_TraktUserProfile> get copyWith => __$TraktUserProfileCopyWithImpl<_TraktUserProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TraktUserProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TraktUserProfile&&(identical(other.username, username) || other.username == username)&&(identical(other.name, name) || other.name == name)&&(identical(other.private, private) || other.private == private)&&(identical(other.vip, vip) || other.vip == vip)&&(identical(other.about, about) || other.about == about)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,name,private,vip,about,avatarUrl);

@override
String toString() {
  return 'TraktUserProfile(username: $username, name: $name, private: $private, vip: $vip, about: $about, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$TraktUserProfileCopyWith<$Res> implements $TraktUserProfileCopyWith<$Res> {
  factory _$TraktUserProfileCopyWith(_TraktUserProfile value, $Res Function(_TraktUserProfile) _then) = __$TraktUserProfileCopyWithImpl;
@override @useResult
$Res call({
 String username, String name, bool private, bool vip, String? about, String? avatarUrl
});




}
/// @nodoc
class __$TraktUserProfileCopyWithImpl<$Res>
    implements _$TraktUserProfileCopyWith<$Res> {
  __$TraktUserProfileCopyWithImpl(this._self, this._then);

  final _TraktUserProfile _self;
  final $Res Function(_TraktUserProfile) _then;

/// Create a copy of TraktUserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? username = null,Object? name = null,Object? private = null,Object? vip = null,Object? about = freezed,Object? avatarUrl = freezed,}) {
  return _then(_TraktUserProfile(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,private: null == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool,vip: null == vip ? _self.vip : vip // ignore: cast_nullable_to_non_nullable
as bool,about: freezed == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProviderStatus {

 String get status; bool? get authenticated; bool? get apiKeyConfigured; String? get url; String? get error;
/// Create a copy of ProviderStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProviderStatusCopyWith<ProviderStatus> get copyWith => _$ProviderStatusCopyWithImpl<ProviderStatus>(this as ProviderStatus, _$identity);

  /// Serializes this ProviderStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProviderStatus&&(identical(other.status, status) || other.status == status)&&(identical(other.authenticated, authenticated) || other.authenticated == authenticated)&&(identical(other.apiKeyConfigured, apiKeyConfigured) || other.apiKeyConfigured == apiKeyConfigured)&&(identical(other.url, url) || other.url == url)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,authenticated,apiKeyConfigured,url,error);

@override
String toString() {
  return 'ProviderStatus(status: $status, authenticated: $authenticated, apiKeyConfigured: $apiKeyConfigured, url: $url, error: $error)';
}


}

/// @nodoc
abstract mixin class $ProviderStatusCopyWith<$Res>  {
  factory $ProviderStatusCopyWith(ProviderStatus value, $Res Function(ProviderStatus) _then) = _$ProviderStatusCopyWithImpl;
@useResult
$Res call({
 String status, bool? authenticated, bool? apiKeyConfigured, String? url, String? error
});




}
/// @nodoc
class _$ProviderStatusCopyWithImpl<$Res>
    implements $ProviderStatusCopyWith<$Res> {
  _$ProviderStatusCopyWithImpl(this._self, this._then);

  final ProviderStatus _self;
  final $Res Function(ProviderStatus) _then;

/// Create a copy of ProviderStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? authenticated = freezed,Object? apiKeyConfigured = freezed,Object? url = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,authenticated: freezed == authenticated ? _self.authenticated : authenticated // ignore: cast_nullable_to_non_nullable
as bool?,apiKeyConfigured: freezed == apiKeyConfigured ? _self.apiKeyConfigured : apiKeyConfigured // ignore: cast_nullable_to_non_nullable
as bool?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProviderStatus].
extension ProviderStatusPatterns on ProviderStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProviderStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProviderStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProviderStatus value)  $default,){
final _that = this;
switch (_that) {
case _ProviderStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProviderStatus value)?  $default,){
final _that = this;
switch (_that) {
case _ProviderStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  bool? authenticated,  bool? apiKeyConfigured,  String? url,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProviderStatus() when $default != null:
return $default(_that.status,_that.authenticated,_that.apiKeyConfigured,_that.url,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  bool? authenticated,  bool? apiKeyConfigured,  String? url,  String? error)  $default,) {final _that = this;
switch (_that) {
case _ProviderStatus():
return $default(_that.status,_that.authenticated,_that.apiKeyConfigured,_that.url,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  bool? authenticated,  bool? apiKeyConfigured,  String? url,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _ProviderStatus() when $default != null:
return $default(_that.status,_that.authenticated,_that.apiKeyConfigured,_that.url,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProviderStatus implements ProviderStatus {
  const _ProviderStatus({required this.status, this.authenticated, this.apiKeyConfigured, this.url, this.error});
  factory _ProviderStatus.fromJson(Map<String, dynamic> json) => _$ProviderStatusFromJson(json);

@override final  String status;
@override final  bool? authenticated;
@override final  bool? apiKeyConfigured;
@override final  String? url;
@override final  String? error;

/// Create a copy of ProviderStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProviderStatusCopyWith<_ProviderStatus> get copyWith => __$ProviderStatusCopyWithImpl<_ProviderStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProviderStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProviderStatus&&(identical(other.status, status) || other.status == status)&&(identical(other.authenticated, authenticated) || other.authenticated == authenticated)&&(identical(other.apiKeyConfigured, apiKeyConfigured) || other.apiKeyConfigured == apiKeyConfigured)&&(identical(other.url, url) || other.url == url)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,authenticated,apiKeyConfigured,url,error);

@override
String toString() {
  return 'ProviderStatus(status: $status, authenticated: $authenticated, apiKeyConfigured: $apiKeyConfigured, url: $url, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ProviderStatusCopyWith<$Res> implements $ProviderStatusCopyWith<$Res> {
  factory _$ProviderStatusCopyWith(_ProviderStatus value, $Res Function(_ProviderStatus) _then) = __$ProviderStatusCopyWithImpl;
@override @useResult
$Res call({
 String status, bool? authenticated, bool? apiKeyConfigured, String? url, String? error
});




}
/// @nodoc
class __$ProviderStatusCopyWithImpl<$Res>
    implements _$ProviderStatusCopyWith<$Res> {
  __$ProviderStatusCopyWithImpl(this._self, this._then);

  final _ProviderStatus _self;
  final $Res Function(_ProviderStatus) _then;

/// Create a copy of ProviderStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? authenticated = freezed,Object? apiKeyConfigured = freezed,Object? url = freezed,Object? error = freezed,}) {
  return _then(_ProviderStatus(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,authenticated: freezed == authenticated ? _self.authenticated : authenticated // ignore: cast_nullable_to_non_nullable
as bool?,apiKeyConfigured: freezed == apiKeyConfigured ? _self.apiKeyConfigured : apiKeyConfigured // ignore: cast_nullable_to_non_nullable
as bool?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProvidersResponse {

 ProviderStatus get tmdb; ProviderStatus get trakt; ProviderStatus get realdebrid; ProviderStatus get torrentApi;
/// Create a copy of ProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProvidersResponseCopyWith<ProvidersResponse> get copyWith => _$ProvidersResponseCopyWithImpl<ProvidersResponse>(this as ProvidersResponse, _$identity);

  /// Serializes this ProvidersResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProvidersResponse&&(identical(other.tmdb, tmdb) || other.tmdb == tmdb)&&(identical(other.trakt, trakt) || other.trakt == trakt)&&(identical(other.realdebrid, realdebrid) || other.realdebrid == realdebrid)&&(identical(other.torrentApi, torrentApi) || other.torrentApi == torrentApi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tmdb,trakt,realdebrid,torrentApi);

@override
String toString() {
  return 'ProvidersResponse(tmdb: $tmdb, trakt: $trakt, realdebrid: $realdebrid, torrentApi: $torrentApi)';
}


}

/// @nodoc
abstract mixin class $ProvidersResponseCopyWith<$Res>  {
  factory $ProvidersResponseCopyWith(ProvidersResponse value, $Res Function(ProvidersResponse) _then) = _$ProvidersResponseCopyWithImpl;
@useResult
$Res call({
 ProviderStatus tmdb, ProviderStatus trakt, ProviderStatus realdebrid, ProviderStatus torrentApi
});


$ProviderStatusCopyWith<$Res> get tmdb;$ProviderStatusCopyWith<$Res> get trakt;$ProviderStatusCopyWith<$Res> get realdebrid;$ProviderStatusCopyWith<$Res> get torrentApi;

}
/// @nodoc
class _$ProvidersResponseCopyWithImpl<$Res>
    implements $ProvidersResponseCopyWith<$Res> {
  _$ProvidersResponseCopyWithImpl(this._self, this._then);

  final ProvidersResponse _self;
  final $Res Function(ProvidersResponse) _then;

/// Create a copy of ProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tmdb = null,Object? trakt = null,Object? realdebrid = null,Object? torrentApi = null,}) {
  return _then(_self.copyWith(
tmdb: null == tmdb ? _self.tmdb : tmdb // ignore: cast_nullable_to_non_nullable
as ProviderStatus,trakt: null == trakt ? _self.trakt : trakt // ignore: cast_nullable_to_non_nullable
as ProviderStatus,realdebrid: null == realdebrid ? _self.realdebrid : realdebrid // ignore: cast_nullable_to_non_nullable
as ProviderStatus,torrentApi: null == torrentApi ? _self.torrentApi : torrentApi // ignore: cast_nullable_to_non_nullable
as ProviderStatus,
  ));
}
/// Create a copy of ProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderStatusCopyWith<$Res> get tmdb {
  
  return $ProviderStatusCopyWith<$Res>(_self.tmdb, (value) {
    return _then(_self.copyWith(tmdb: value));
  });
}/// Create a copy of ProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderStatusCopyWith<$Res> get trakt {
  
  return $ProviderStatusCopyWith<$Res>(_self.trakt, (value) {
    return _then(_self.copyWith(trakt: value));
  });
}/// Create a copy of ProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderStatusCopyWith<$Res> get realdebrid {
  
  return $ProviderStatusCopyWith<$Res>(_self.realdebrid, (value) {
    return _then(_self.copyWith(realdebrid: value));
  });
}/// Create a copy of ProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderStatusCopyWith<$Res> get torrentApi {
  
  return $ProviderStatusCopyWith<$Res>(_self.torrentApi, (value) {
    return _then(_self.copyWith(torrentApi: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProvidersResponse].
extension ProvidersResponsePatterns on ProvidersResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProvidersResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProvidersResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProvidersResponse value)  $default,){
final _that = this;
switch (_that) {
case _ProvidersResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProvidersResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ProvidersResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProviderStatus tmdb,  ProviderStatus trakt,  ProviderStatus realdebrid,  ProviderStatus torrentApi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProvidersResponse() when $default != null:
return $default(_that.tmdb,_that.trakt,_that.realdebrid,_that.torrentApi);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProviderStatus tmdb,  ProviderStatus trakt,  ProviderStatus realdebrid,  ProviderStatus torrentApi)  $default,) {final _that = this;
switch (_that) {
case _ProvidersResponse():
return $default(_that.tmdb,_that.trakt,_that.realdebrid,_that.torrentApi);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProviderStatus tmdb,  ProviderStatus trakt,  ProviderStatus realdebrid,  ProviderStatus torrentApi)?  $default,) {final _that = this;
switch (_that) {
case _ProvidersResponse() when $default != null:
return $default(_that.tmdb,_that.trakt,_that.realdebrid,_that.torrentApi);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProvidersResponse implements ProvidersResponse {
  const _ProvidersResponse({required this.tmdb, required this.trakt, required this.realdebrid, required this.torrentApi});
  factory _ProvidersResponse.fromJson(Map<String, dynamic> json) => _$ProvidersResponseFromJson(json);

@override final  ProviderStatus tmdb;
@override final  ProviderStatus trakt;
@override final  ProviderStatus realdebrid;
@override final  ProviderStatus torrentApi;

/// Create a copy of ProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProvidersResponseCopyWith<_ProvidersResponse> get copyWith => __$ProvidersResponseCopyWithImpl<_ProvidersResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProvidersResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProvidersResponse&&(identical(other.tmdb, tmdb) || other.tmdb == tmdb)&&(identical(other.trakt, trakt) || other.trakt == trakt)&&(identical(other.realdebrid, realdebrid) || other.realdebrid == realdebrid)&&(identical(other.torrentApi, torrentApi) || other.torrentApi == torrentApi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tmdb,trakt,realdebrid,torrentApi);

@override
String toString() {
  return 'ProvidersResponse(tmdb: $tmdb, trakt: $trakt, realdebrid: $realdebrid, torrentApi: $torrentApi)';
}


}

/// @nodoc
abstract mixin class _$ProvidersResponseCopyWith<$Res> implements $ProvidersResponseCopyWith<$Res> {
  factory _$ProvidersResponseCopyWith(_ProvidersResponse value, $Res Function(_ProvidersResponse) _then) = __$ProvidersResponseCopyWithImpl;
@override @useResult
$Res call({
 ProviderStatus tmdb, ProviderStatus trakt, ProviderStatus realdebrid, ProviderStatus torrentApi
});


@override $ProviderStatusCopyWith<$Res> get tmdb;@override $ProviderStatusCopyWith<$Res> get trakt;@override $ProviderStatusCopyWith<$Res> get realdebrid;@override $ProviderStatusCopyWith<$Res> get torrentApi;

}
/// @nodoc
class __$ProvidersResponseCopyWithImpl<$Res>
    implements _$ProvidersResponseCopyWith<$Res> {
  __$ProvidersResponseCopyWithImpl(this._self, this._then);

  final _ProvidersResponse _self;
  final $Res Function(_ProvidersResponse) _then;

/// Create a copy of ProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tmdb = null,Object? trakt = null,Object? realdebrid = null,Object? torrentApi = null,}) {
  return _then(_ProvidersResponse(
tmdb: null == tmdb ? _self.tmdb : tmdb // ignore: cast_nullable_to_non_nullable
as ProviderStatus,trakt: null == trakt ? _self.trakt : trakt // ignore: cast_nullable_to_non_nullable
as ProviderStatus,realdebrid: null == realdebrid ? _self.realdebrid : realdebrid // ignore: cast_nullable_to_non_nullable
as ProviderStatus,torrentApi: null == torrentApi ? _self.torrentApi : torrentApi // ignore: cast_nullable_to_non_nullable
as ProviderStatus,
  ));
}

/// Create a copy of ProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderStatusCopyWith<$Res> get tmdb {
  
  return $ProviderStatusCopyWith<$Res>(_self.tmdb, (value) {
    return _then(_self.copyWith(tmdb: value));
  });
}/// Create a copy of ProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderStatusCopyWith<$Res> get trakt {
  
  return $ProviderStatusCopyWith<$Res>(_self.trakt, (value) {
    return _then(_self.copyWith(trakt: value));
  });
}/// Create a copy of ProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderStatusCopyWith<$Res> get realdebrid {
  
  return $ProviderStatusCopyWith<$Res>(_self.realdebrid, (value) {
    return _then(_self.copyWith(realdebrid: value));
  });
}/// Create a copy of ProvidersResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProviderStatusCopyWith<$Res> get torrentApi {
  
  return $ProviderStatusCopyWith<$Res>(_self.torrentApi, (value) {
    return _then(_self.copyWith(torrentApi: value));
  });
}
}


/// @nodoc
mixin _$SettingsResponse {

 Map<String, String?> get settings;
/// Create a copy of SettingsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsResponseCopyWith<SettingsResponse> get copyWith => _$SettingsResponseCopyWithImpl<SettingsResponse>(this as SettingsResponse, _$identity);

  /// Serializes this SettingsResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsResponse&&const DeepCollectionEquality().equals(other.settings, settings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(settings));

@override
String toString() {
  return 'SettingsResponse(settings: $settings)';
}


}

/// @nodoc
abstract mixin class $SettingsResponseCopyWith<$Res>  {
  factory $SettingsResponseCopyWith(SettingsResponse value, $Res Function(SettingsResponse) _then) = _$SettingsResponseCopyWithImpl;
@useResult
$Res call({
 Map<String, String?> settings
});




}
/// @nodoc
class _$SettingsResponseCopyWithImpl<$Res>
    implements $SettingsResponseCopyWith<$Res> {
  _$SettingsResponseCopyWithImpl(this._self, this._then);

  final SettingsResponse _self;
  final $Res Function(SettingsResponse) _then;

/// Create a copy of SettingsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? settings = null,}) {
  return _then(_self.copyWith(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, String?>,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsResponse].
extension SettingsResponsePatterns on SettingsResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsResponse value)  $default,){
final _that = this;
switch (_that) {
case _SettingsResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, String?> settings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsResponse() when $default != null:
return $default(_that.settings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, String?> settings)  $default,) {final _that = this;
switch (_that) {
case _SettingsResponse():
return $default(_that.settings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, String?> settings)?  $default,) {final _that = this;
switch (_that) {
case _SettingsResponse() when $default != null:
return $default(_that.settings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SettingsResponse implements SettingsResponse {
  const _SettingsResponse({required final  Map<String, String?> settings}): _settings = settings;
  factory _SettingsResponse.fromJson(Map<String, dynamic> json) => _$SettingsResponseFromJson(json);

 final  Map<String, String?> _settings;
@override Map<String, String?> get settings {
  if (_settings is EqualUnmodifiableMapView) return _settings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_settings);
}


/// Create a copy of SettingsResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsResponseCopyWith<_SettingsResponse> get copyWith => __$SettingsResponseCopyWithImpl<_SettingsResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettingsResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsResponse&&const DeepCollectionEquality().equals(other._settings, _settings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_settings));

@override
String toString() {
  return 'SettingsResponse(settings: $settings)';
}


}

/// @nodoc
abstract mixin class _$SettingsResponseCopyWith<$Res> implements $SettingsResponseCopyWith<$Res> {
  factory _$SettingsResponseCopyWith(_SettingsResponse value, $Res Function(_SettingsResponse) _then) = __$SettingsResponseCopyWithImpl;
@override @useResult
$Res call({
 Map<String, String?> settings
});




}
/// @nodoc
class __$SettingsResponseCopyWithImpl<$Res>
    implements _$SettingsResponseCopyWith<$Res> {
  __$SettingsResponseCopyWithImpl(this._self, this._then);

  final _SettingsResponse _self;
  final $Res Function(_SettingsResponse) _then;

/// Create a copy of SettingsResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? settings = null,}) {
  return _then(_SettingsResponse(
settings: null == settings ? _self._settings : settings // ignore: cast_nullable_to_non_nullable
as Map<String, String?>,
  ));
}


}


/// @nodoc
mixin _$SettingsUpdateResponse {

 String get message; String get key;
/// Create a copy of SettingsUpdateResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsUpdateResponseCopyWith<SettingsUpdateResponse> get copyWith => _$SettingsUpdateResponseCopyWithImpl<SettingsUpdateResponse>(this as SettingsUpdateResponse, _$identity);

  /// Serializes this SettingsUpdateResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsUpdateResponse&&(identical(other.message, message) || other.message == message)&&(identical(other.key, key) || other.key == key));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,key);

@override
String toString() {
  return 'SettingsUpdateResponse(message: $message, key: $key)';
}


}

/// @nodoc
abstract mixin class $SettingsUpdateResponseCopyWith<$Res>  {
  factory $SettingsUpdateResponseCopyWith(SettingsUpdateResponse value, $Res Function(SettingsUpdateResponse) _then) = _$SettingsUpdateResponseCopyWithImpl;
@useResult
$Res call({
 String message, String key
});




}
/// @nodoc
class _$SettingsUpdateResponseCopyWithImpl<$Res>
    implements $SettingsUpdateResponseCopyWith<$Res> {
  _$SettingsUpdateResponseCopyWithImpl(this._self, this._then);

  final SettingsUpdateResponse _self;
  final $Res Function(SettingsUpdateResponse) _then;

/// Create a copy of SettingsUpdateResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? key = null,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsUpdateResponse].
extension SettingsUpdateResponsePatterns on SettingsUpdateResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsUpdateResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsUpdateResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsUpdateResponse value)  $default,){
final _that = this;
switch (_that) {
case _SettingsUpdateResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsUpdateResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsUpdateResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String message,  String key)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsUpdateResponse() when $default != null:
return $default(_that.message,_that.key);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String message,  String key)  $default,) {final _that = this;
switch (_that) {
case _SettingsUpdateResponse():
return $default(_that.message,_that.key);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String message,  String key)?  $default,) {final _that = this;
switch (_that) {
case _SettingsUpdateResponse() when $default != null:
return $default(_that.message,_that.key);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SettingsUpdateResponse implements SettingsUpdateResponse {
  const _SettingsUpdateResponse({required this.message, required this.key});
  factory _SettingsUpdateResponse.fromJson(Map<String, dynamic> json) => _$SettingsUpdateResponseFromJson(json);

@override final  String message;
@override final  String key;

/// Create a copy of SettingsUpdateResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsUpdateResponseCopyWith<_SettingsUpdateResponse> get copyWith => __$SettingsUpdateResponseCopyWithImpl<_SettingsUpdateResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettingsUpdateResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsUpdateResponse&&(identical(other.message, message) || other.message == message)&&(identical(other.key, key) || other.key == key));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,key);

@override
String toString() {
  return 'SettingsUpdateResponse(message: $message, key: $key)';
}


}

/// @nodoc
abstract mixin class _$SettingsUpdateResponseCopyWith<$Res> implements $SettingsUpdateResponseCopyWith<$Res> {
  factory _$SettingsUpdateResponseCopyWith(_SettingsUpdateResponse value, $Res Function(_SettingsUpdateResponse) _then) = __$SettingsUpdateResponseCopyWithImpl;
@override @useResult
$Res call({
 String message, String key
});




}
/// @nodoc
class __$SettingsUpdateResponseCopyWithImpl<$Res>
    implements _$SettingsUpdateResponseCopyWith<$Res> {
  __$SettingsUpdateResponseCopyWithImpl(this._self, this._then);

  final _SettingsUpdateResponse _self;
  final $Res Function(_SettingsUpdateResponse) _then;

/// Create a copy of SettingsUpdateResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? key = null,}) {
  return _then(_SettingsUpdateResponse(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
