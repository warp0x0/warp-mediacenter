// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PreloadStatus {

 String get url; bool get active; int get bytesDownloaded; int get totalSize; double get percent; bool get downloadComplete;
/// Create a copy of PreloadStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreloadStatusCopyWith<PreloadStatus> get copyWith => _$PreloadStatusCopyWithImpl<PreloadStatus>(this as PreloadStatus, _$identity);

  /// Serializes this PreloadStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreloadStatus&&(identical(other.url, url) || other.url == url)&&(identical(other.active, active) || other.active == active)&&(identical(other.bytesDownloaded, bytesDownloaded) || other.bytesDownloaded == bytesDownloaded)&&(identical(other.totalSize, totalSize) || other.totalSize == totalSize)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.downloadComplete, downloadComplete) || other.downloadComplete == downloadComplete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,active,bytesDownloaded,totalSize,percent,downloadComplete);

@override
String toString() {
  return 'PreloadStatus(url: $url, active: $active, bytesDownloaded: $bytesDownloaded, totalSize: $totalSize, percent: $percent, downloadComplete: $downloadComplete)';
}


}

/// @nodoc
abstract mixin class $PreloadStatusCopyWith<$Res>  {
  factory $PreloadStatusCopyWith(PreloadStatus value, $Res Function(PreloadStatus) _then) = _$PreloadStatusCopyWithImpl;
@useResult
$Res call({
 String url, bool active, int bytesDownloaded, int totalSize, double percent, bool downloadComplete
});




}
/// @nodoc
class _$PreloadStatusCopyWithImpl<$Res>
    implements $PreloadStatusCopyWith<$Res> {
  _$PreloadStatusCopyWithImpl(this._self, this._then);

  final PreloadStatus _self;
  final $Res Function(PreloadStatus) _then;

/// Create a copy of PreloadStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? active = null,Object? bytesDownloaded = null,Object? totalSize = null,Object? percent = null,Object? downloadComplete = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,bytesDownloaded: null == bytesDownloaded ? _self.bytesDownloaded : bytesDownloaded // ignore: cast_nullable_to_non_nullable
as int,totalSize: null == totalSize ? _self.totalSize : totalSize // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as double,downloadComplete: null == downloadComplete ? _self.downloadComplete : downloadComplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PreloadStatus].
extension PreloadStatusPatterns on PreloadStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreloadStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreloadStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreloadStatus value)  $default,){
final _that = this;
switch (_that) {
case _PreloadStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreloadStatus value)?  $default,){
final _that = this;
switch (_that) {
case _PreloadStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  bool active,  int bytesDownloaded,  int totalSize,  double percent,  bool downloadComplete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreloadStatus() when $default != null:
return $default(_that.url,_that.active,_that.bytesDownloaded,_that.totalSize,_that.percent,_that.downloadComplete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  bool active,  int bytesDownloaded,  int totalSize,  double percent,  bool downloadComplete)  $default,) {final _that = this;
switch (_that) {
case _PreloadStatus():
return $default(_that.url,_that.active,_that.bytesDownloaded,_that.totalSize,_that.percent,_that.downloadComplete);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  bool active,  int bytesDownloaded,  int totalSize,  double percent,  bool downloadComplete)?  $default,) {final _that = this;
switch (_that) {
case _PreloadStatus() when $default != null:
return $default(_that.url,_that.active,_that.bytesDownloaded,_that.totalSize,_that.percent,_that.downloadComplete);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PreloadStatus implements PreloadStatus {
  const _PreloadStatus({required this.url, required this.active, required this.bytesDownloaded, required this.totalSize, required this.percent, required this.downloadComplete});
  factory _PreloadStatus.fromJson(Map<String, dynamic> json) => _$PreloadStatusFromJson(json);

@override final  String url;
@override final  bool active;
@override final  int bytesDownloaded;
@override final  int totalSize;
@override final  double percent;
@override final  bool downloadComplete;

/// Create a copy of PreloadStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreloadStatusCopyWith<_PreloadStatus> get copyWith => __$PreloadStatusCopyWithImpl<_PreloadStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PreloadStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreloadStatus&&(identical(other.url, url) || other.url == url)&&(identical(other.active, active) || other.active == active)&&(identical(other.bytesDownloaded, bytesDownloaded) || other.bytesDownloaded == bytesDownloaded)&&(identical(other.totalSize, totalSize) || other.totalSize == totalSize)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.downloadComplete, downloadComplete) || other.downloadComplete == downloadComplete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,active,bytesDownloaded,totalSize,percent,downloadComplete);

@override
String toString() {
  return 'PreloadStatus(url: $url, active: $active, bytesDownloaded: $bytesDownloaded, totalSize: $totalSize, percent: $percent, downloadComplete: $downloadComplete)';
}


}

/// @nodoc
abstract mixin class _$PreloadStatusCopyWith<$Res> implements $PreloadStatusCopyWith<$Res> {
  factory _$PreloadStatusCopyWith(_PreloadStatus value, $Res Function(_PreloadStatus) _then) = __$PreloadStatusCopyWithImpl;
@override @useResult
$Res call({
 String url, bool active, int bytesDownloaded, int totalSize, double percent, bool downloadComplete
});




}
/// @nodoc
class __$PreloadStatusCopyWithImpl<$Res>
    implements _$PreloadStatusCopyWith<$Res> {
  __$PreloadStatusCopyWithImpl(this._self, this._then);

  final _PreloadStatus _self;
  final $Res Function(_PreloadStatus) _then;

/// Create a copy of PreloadStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? active = null,Object? bytesDownloaded = null,Object? totalSize = null,Object? percent = null,Object? downloadComplete = null,}) {
  return _then(_PreloadStatus(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,bytesDownloaded: null == bytesDownloaded ? _self.bytesDownloaded : bytesDownloaded // ignore: cast_nullable_to_non_nullable
as int,totalSize: null == totalSize ? _self.totalSize : totalSize // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as double,downloadComplete: null == downloadComplete ? _self.downloadComplete : downloadComplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PreloadSessionCreateRequest {

 String? get streamUrl; String? get magnet; String? get title; String? get mediaKind; Map<String, dynamic>? get metadata; double? get startPercent;
/// Create a copy of PreloadSessionCreateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreloadSessionCreateRequestCopyWith<PreloadSessionCreateRequest> get copyWith => _$PreloadSessionCreateRequestCopyWithImpl<PreloadSessionCreateRequest>(this as PreloadSessionCreateRequest, _$identity);

  /// Serializes this PreloadSessionCreateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreloadSessionCreateRequest&&(identical(other.streamUrl, streamUrl) || other.streamUrl == streamUrl)&&(identical(other.magnet, magnet) || other.magnet == magnet)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.startPercent, startPercent) || other.startPercent == startPercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streamUrl,magnet,title,mediaKind,const DeepCollectionEquality().hash(metadata),startPercent);

@override
String toString() {
  return 'PreloadSessionCreateRequest(streamUrl: $streamUrl, magnet: $magnet, title: $title, mediaKind: $mediaKind, metadata: $metadata, startPercent: $startPercent)';
}


}

/// @nodoc
abstract mixin class $PreloadSessionCreateRequestCopyWith<$Res>  {
  factory $PreloadSessionCreateRequestCopyWith(PreloadSessionCreateRequest value, $Res Function(PreloadSessionCreateRequest) _then) = _$PreloadSessionCreateRequestCopyWithImpl;
@useResult
$Res call({
 String? streamUrl, String? magnet, String? title, String? mediaKind, Map<String, dynamic>? metadata, double? startPercent
});




}
/// @nodoc
class _$PreloadSessionCreateRequestCopyWithImpl<$Res>
    implements $PreloadSessionCreateRequestCopyWith<$Res> {
  _$PreloadSessionCreateRequestCopyWithImpl(this._self, this._then);

  final PreloadSessionCreateRequest _self;
  final $Res Function(PreloadSessionCreateRequest) _then;

/// Create a copy of PreloadSessionCreateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? streamUrl = freezed,Object? magnet = freezed,Object? title = freezed,Object? mediaKind = freezed,Object? metadata = freezed,Object? startPercent = freezed,}) {
  return _then(_self.copyWith(
streamUrl: freezed == streamUrl ? _self.streamUrl : streamUrl // ignore: cast_nullable_to_non_nullable
as String?,magnet: freezed == magnet ? _self.magnet : magnet // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,mediaKind: freezed == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,startPercent: freezed == startPercent ? _self.startPercent : startPercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PreloadSessionCreateRequest].
extension PreloadSessionCreateRequestPatterns on PreloadSessionCreateRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreloadSessionCreateRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreloadSessionCreateRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreloadSessionCreateRequest value)  $default,){
final _that = this;
switch (_that) {
case _PreloadSessionCreateRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreloadSessionCreateRequest value)?  $default,){
final _that = this;
switch (_that) {
case _PreloadSessionCreateRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? streamUrl,  String? magnet,  String? title,  String? mediaKind,  Map<String, dynamic>? metadata,  double? startPercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreloadSessionCreateRequest() when $default != null:
return $default(_that.streamUrl,_that.magnet,_that.title,_that.mediaKind,_that.metadata,_that.startPercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? streamUrl,  String? magnet,  String? title,  String? mediaKind,  Map<String, dynamic>? metadata,  double? startPercent)  $default,) {final _that = this;
switch (_that) {
case _PreloadSessionCreateRequest():
return $default(_that.streamUrl,_that.magnet,_that.title,_that.mediaKind,_that.metadata,_that.startPercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? streamUrl,  String? magnet,  String? title,  String? mediaKind,  Map<String, dynamic>? metadata,  double? startPercent)?  $default,) {final _that = this;
switch (_that) {
case _PreloadSessionCreateRequest() when $default != null:
return $default(_that.streamUrl,_that.magnet,_that.title,_that.mediaKind,_that.metadata,_that.startPercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PreloadSessionCreateRequest implements PreloadSessionCreateRequest {
  const _PreloadSessionCreateRequest({this.streamUrl, this.magnet, this.title, this.mediaKind, final  Map<String, dynamic>? metadata, this.startPercent}): _metadata = metadata;
  factory _PreloadSessionCreateRequest.fromJson(Map<String, dynamic> json) => _$PreloadSessionCreateRequestFromJson(json);

@override final  String? streamUrl;
@override final  String? magnet;
@override final  String? title;
@override final  String? mediaKind;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  double? startPercent;

/// Create a copy of PreloadSessionCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreloadSessionCreateRequestCopyWith<_PreloadSessionCreateRequest> get copyWith => __$PreloadSessionCreateRequestCopyWithImpl<_PreloadSessionCreateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PreloadSessionCreateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreloadSessionCreateRequest&&(identical(other.streamUrl, streamUrl) || other.streamUrl == streamUrl)&&(identical(other.magnet, magnet) || other.magnet == magnet)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.startPercent, startPercent) || other.startPercent == startPercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streamUrl,magnet,title,mediaKind,const DeepCollectionEquality().hash(_metadata),startPercent);

@override
String toString() {
  return 'PreloadSessionCreateRequest(streamUrl: $streamUrl, magnet: $magnet, title: $title, mediaKind: $mediaKind, metadata: $metadata, startPercent: $startPercent)';
}


}

/// @nodoc
abstract mixin class _$PreloadSessionCreateRequestCopyWith<$Res> implements $PreloadSessionCreateRequestCopyWith<$Res> {
  factory _$PreloadSessionCreateRequestCopyWith(_PreloadSessionCreateRequest value, $Res Function(_PreloadSessionCreateRequest) _then) = __$PreloadSessionCreateRequestCopyWithImpl;
@override @useResult
$Res call({
 String? streamUrl, String? magnet, String? title, String? mediaKind, Map<String, dynamic>? metadata, double? startPercent
});




}
/// @nodoc
class __$PreloadSessionCreateRequestCopyWithImpl<$Res>
    implements _$PreloadSessionCreateRequestCopyWith<$Res> {
  __$PreloadSessionCreateRequestCopyWithImpl(this._self, this._then);

  final _PreloadSessionCreateRequest _self;
  final $Res Function(_PreloadSessionCreateRequest) _then;

/// Create a copy of PreloadSessionCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? streamUrl = freezed,Object? magnet = freezed,Object? title = freezed,Object? mediaKind = freezed,Object? metadata = freezed,Object? startPercent = freezed,}) {
  return _then(_PreloadSessionCreateRequest(
streamUrl: freezed == streamUrl ? _self.streamUrl : streamUrl // ignore: cast_nullable_to_non_nullable
as String?,magnet: freezed == magnet ? _self.magnet : magnet // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,mediaKind: freezed == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,startPercent: freezed == startPercent ? _self.startPercent : startPercent // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$PreloadSessionCreateResponse {

 String get sessionId; String get playbackUrl; String? get localUrl; String get statusUrl; String get cleanupUrl; String get createdAt;
/// Create a copy of PreloadSessionCreateResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreloadSessionCreateResponseCopyWith<PreloadSessionCreateResponse> get copyWith => _$PreloadSessionCreateResponseCopyWithImpl<PreloadSessionCreateResponse>(this as PreloadSessionCreateResponse, _$identity);

  /// Serializes this PreloadSessionCreateResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreloadSessionCreateResponse&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.playbackUrl, playbackUrl) || other.playbackUrl == playbackUrl)&&(identical(other.localUrl, localUrl) || other.localUrl == localUrl)&&(identical(other.statusUrl, statusUrl) || other.statusUrl == statusUrl)&&(identical(other.cleanupUrl, cleanupUrl) || other.cleanupUrl == cleanupUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,playbackUrl,localUrl,statusUrl,cleanupUrl,createdAt);

@override
String toString() {
  return 'PreloadSessionCreateResponse(sessionId: $sessionId, playbackUrl: $playbackUrl, localUrl: $localUrl, statusUrl: $statusUrl, cleanupUrl: $cleanupUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PreloadSessionCreateResponseCopyWith<$Res>  {
  factory $PreloadSessionCreateResponseCopyWith(PreloadSessionCreateResponse value, $Res Function(PreloadSessionCreateResponse) _then) = _$PreloadSessionCreateResponseCopyWithImpl;
@useResult
$Res call({
 String sessionId, String playbackUrl, String? localUrl, String statusUrl, String cleanupUrl, String createdAt
});




}
/// @nodoc
class _$PreloadSessionCreateResponseCopyWithImpl<$Res>
    implements $PreloadSessionCreateResponseCopyWith<$Res> {
  _$PreloadSessionCreateResponseCopyWithImpl(this._self, this._then);

  final PreloadSessionCreateResponse _self;
  final $Res Function(PreloadSessionCreateResponse) _then;

/// Create a copy of PreloadSessionCreateResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? playbackUrl = null,Object? localUrl = freezed,Object? statusUrl = null,Object? cleanupUrl = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,playbackUrl: null == playbackUrl ? _self.playbackUrl : playbackUrl // ignore: cast_nullable_to_non_nullable
as String,localUrl: freezed == localUrl ? _self.localUrl : localUrl // ignore: cast_nullable_to_non_nullable
as String?,statusUrl: null == statusUrl ? _self.statusUrl : statusUrl // ignore: cast_nullable_to_non_nullable
as String,cleanupUrl: null == cleanupUrl ? _self.cleanupUrl : cleanupUrl // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PreloadSessionCreateResponse].
extension PreloadSessionCreateResponsePatterns on PreloadSessionCreateResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreloadSessionCreateResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreloadSessionCreateResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreloadSessionCreateResponse value)  $default,){
final _that = this;
switch (_that) {
case _PreloadSessionCreateResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreloadSessionCreateResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PreloadSessionCreateResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  String playbackUrl,  String? localUrl,  String statusUrl,  String cleanupUrl,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreloadSessionCreateResponse() when $default != null:
return $default(_that.sessionId,_that.playbackUrl,_that.localUrl,_that.statusUrl,_that.cleanupUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  String playbackUrl,  String? localUrl,  String statusUrl,  String cleanupUrl,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _PreloadSessionCreateResponse():
return $default(_that.sessionId,_that.playbackUrl,_that.localUrl,_that.statusUrl,_that.cleanupUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  String playbackUrl,  String? localUrl,  String statusUrl,  String cleanupUrl,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PreloadSessionCreateResponse() when $default != null:
return $default(_that.sessionId,_that.playbackUrl,_that.localUrl,_that.statusUrl,_that.cleanupUrl,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PreloadSessionCreateResponse implements PreloadSessionCreateResponse {
  const _PreloadSessionCreateResponse({required this.sessionId, required this.playbackUrl, this.localUrl, required this.statusUrl, required this.cleanupUrl, required this.createdAt});
  factory _PreloadSessionCreateResponse.fromJson(Map<String, dynamic> json) => _$PreloadSessionCreateResponseFromJson(json);

@override final  String sessionId;
@override final  String playbackUrl;
@override final  String? localUrl;
@override final  String statusUrl;
@override final  String cleanupUrl;
@override final  String createdAt;

/// Create a copy of PreloadSessionCreateResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreloadSessionCreateResponseCopyWith<_PreloadSessionCreateResponse> get copyWith => __$PreloadSessionCreateResponseCopyWithImpl<_PreloadSessionCreateResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PreloadSessionCreateResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreloadSessionCreateResponse&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.playbackUrl, playbackUrl) || other.playbackUrl == playbackUrl)&&(identical(other.localUrl, localUrl) || other.localUrl == localUrl)&&(identical(other.statusUrl, statusUrl) || other.statusUrl == statusUrl)&&(identical(other.cleanupUrl, cleanupUrl) || other.cleanupUrl == cleanupUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,playbackUrl,localUrl,statusUrl,cleanupUrl,createdAt);

@override
String toString() {
  return 'PreloadSessionCreateResponse(sessionId: $sessionId, playbackUrl: $playbackUrl, localUrl: $localUrl, statusUrl: $statusUrl, cleanupUrl: $cleanupUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PreloadSessionCreateResponseCopyWith<$Res> implements $PreloadSessionCreateResponseCopyWith<$Res> {
  factory _$PreloadSessionCreateResponseCopyWith(_PreloadSessionCreateResponse value, $Res Function(_PreloadSessionCreateResponse) _then) = __$PreloadSessionCreateResponseCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, String playbackUrl, String? localUrl, String statusUrl, String cleanupUrl, String createdAt
});




}
/// @nodoc
class __$PreloadSessionCreateResponseCopyWithImpl<$Res>
    implements _$PreloadSessionCreateResponseCopyWith<$Res> {
  __$PreloadSessionCreateResponseCopyWithImpl(this._self, this._then);

  final _PreloadSessionCreateResponse _self;
  final $Res Function(_PreloadSessionCreateResponse) _then;

/// Create a copy of PreloadSessionCreateResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? playbackUrl = null,Object? localUrl = freezed,Object? statusUrl = null,Object? cleanupUrl = null,Object? createdAt = null,}) {
  return _then(_PreloadSessionCreateResponse(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,playbackUrl: null == playbackUrl ? _self.playbackUrl : playbackUrl // ignore: cast_nullable_to_non_nullable
as String,localUrl: freezed == localUrl ? _self.localUrl : localUrl // ignore: cast_nullable_to_non_nullable
as String?,statusUrl: null == statusUrl ? _self.statusUrl : statusUrl // ignore: cast_nullable_to_non_nullable
as String,cleanupUrl: null == cleanupUrl ? _self.cleanupUrl : cleanupUrl // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PreloadSessionStatus {

 String get sessionId; String get url; bool get active; int get bytesDownloaded; int get totalSize; int? get remainingSize; double get percent; bool get downloadComplete; String? get error; String get state; String? get title; String? get mediaKind; String get playbackUrl; bool? get localTorrent; int get bufferAheadBytes; int get activeStreams; String get createdAt; String get updatedAt;
/// Create a copy of PreloadSessionStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreloadSessionStatusCopyWith<PreloadSessionStatus> get copyWith => _$PreloadSessionStatusCopyWithImpl<PreloadSessionStatus>(this as PreloadSessionStatus, _$identity);

  /// Serializes this PreloadSessionStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreloadSessionStatus&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.url, url) || other.url == url)&&(identical(other.active, active) || other.active == active)&&(identical(other.bytesDownloaded, bytesDownloaded) || other.bytesDownloaded == bytesDownloaded)&&(identical(other.totalSize, totalSize) || other.totalSize == totalSize)&&(identical(other.remainingSize, remainingSize) || other.remainingSize == remainingSize)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.downloadComplete, downloadComplete) || other.downloadComplete == downloadComplete)&&(identical(other.error, error) || other.error == error)&&(identical(other.state, state) || other.state == state)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind)&&(identical(other.playbackUrl, playbackUrl) || other.playbackUrl == playbackUrl)&&(identical(other.localTorrent, localTorrent) || other.localTorrent == localTorrent)&&(identical(other.bufferAheadBytes, bufferAheadBytes) || other.bufferAheadBytes == bufferAheadBytes)&&(identical(other.activeStreams, activeStreams) || other.activeStreams == activeStreams)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,url,active,bytesDownloaded,totalSize,remainingSize,percent,downloadComplete,error,state,title,mediaKind,playbackUrl,localTorrent,bufferAheadBytes,activeStreams,createdAt,updatedAt);

@override
String toString() {
  return 'PreloadSessionStatus(sessionId: $sessionId, url: $url, active: $active, bytesDownloaded: $bytesDownloaded, totalSize: $totalSize, remainingSize: $remainingSize, percent: $percent, downloadComplete: $downloadComplete, error: $error, state: $state, title: $title, mediaKind: $mediaKind, playbackUrl: $playbackUrl, localTorrent: $localTorrent, bufferAheadBytes: $bufferAheadBytes, activeStreams: $activeStreams, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PreloadSessionStatusCopyWith<$Res>  {
  factory $PreloadSessionStatusCopyWith(PreloadSessionStatus value, $Res Function(PreloadSessionStatus) _then) = _$PreloadSessionStatusCopyWithImpl;
@useResult
$Res call({
 String sessionId, String url, bool active, int bytesDownloaded, int totalSize, int? remainingSize, double percent, bool downloadComplete, String? error, String state, String? title, String? mediaKind, String playbackUrl, bool? localTorrent, int bufferAheadBytes, int activeStreams, String createdAt, String updatedAt
});




}
/// @nodoc
class _$PreloadSessionStatusCopyWithImpl<$Res>
    implements $PreloadSessionStatusCopyWith<$Res> {
  _$PreloadSessionStatusCopyWithImpl(this._self, this._then);

  final PreloadSessionStatus _self;
  final $Res Function(PreloadSessionStatus) _then;

/// Create a copy of PreloadSessionStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? url = null,Object? active = null,Object? bytesDownloaded = null,Object? totalSize = null,Object? remainingSize = freezed,Object? percent = null,Object? downloadComplete = null,Object? error = freezed,Object? state = null,Object? title = freezed,Object? mediaKind = freezed,Object? playbackUrl = null,Object? localTorrent = freezed,Object? bufferAheadBytes = null,Object? activeStreams = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,bytesDownloaded: null == bytesDownloaded ? _self.bytesDownloaded : bytesDownloaded // ignore: cast_nullable_to_non_nullable
as int,totalSize: null == totalSize ? _self.totalSize : totalSize // ignore: cast_nullable_to_non_nullable
as int,remainingSize: freezed == remainingSize ? _self.remainingSize : remainingSize // ignore: cast_nullable_to_non_nullable
as int?,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as double,downloadComplete: null == downloadComplete ? _self.downloadComplete : downloadComplete // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,mediaKind: freezed == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as String?,playbackUrl: null == playbackUrl ? _self.playbackUrl : playbackUrl // ignore: cast_nullable_to_non_nullable
as String,localTorrent: freezed == localTorrent ? _self.localTorrent : localTorrent // ignore: cast_nullable_to_non_nullable
as bool?,bufferAheadBytes: null == bufferAheadBytes ? _self.bufferAheadBytes : bufferAheadBytes // ignore: cast_nullable_to_non_nullable
as int,activeStreams: null == activeStreams ? _self.activeStreams : activeStreams // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PreloadSessionStatus].
extension PreloadSessionStatusPatterns on PreloadSessionStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreloadSessionStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreloadSessionStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreloadSessionStatus value)  $default,){
final _that = this;
switch (_that) {
case _PreloadSessionStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreloadSessionStatus value)?  $default,){
final _that = this;
switch (_that) {
case _PreloadSessionStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  String url,  bool active,  int bytesDownloaded,  int totalSize,  int? remainingSize,  double percent,  bool downloadComplete,  String? error,  String state,  String? title,  String? mediaKind,  String playbackUrl,  bool? localTorrent,  int bufferAheadBytes,  int activeStreams,  String createdAt,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreloadSessionStatus() when $default != null:
return $default(_that.sessionId,_that.url,_that.active,_that.bytesDownloaded,_that.totalSize,_that.remainingSize,_that.percent,_that.downloadComplete,_that.error,_that.state,_that.title,_that.mediaKind,_that.playbackUrl,_that.localTorrent,_that.bufferAheadBytes,_that.activeStreams,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  String url,  bool active,  int bytesDownloaded,  int totalSize,  int? remainingSize,  double percent,  bool downloadComplete,  String? error,  String state,  String? title,  String? mediaKind,  String playbackUrl,  bool? localTorrent,  int bufferAheadBytes,  int activeStreams,  String createdAt,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PreloadSessionStatus():
return $default(_that.sessionId,_that.url,_that.active,_that.bytesDownloaded,_that.totalSize,_that.remainingSize,_that.percent,_that.downloadComplete,_that.error,_that.state,_that.title,_that.mediaKind,_that.playbackUrl,_that.localTorrent,_that.bufferAheadBytes,_that.activeStreams,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  String url,  bool active,  int bytesDownloaded,  int totalSize,  int? remainingSize,  double percent,  bool downloadComplete,  String? error,  String state,  String? title,  String? mediaKind,  String playbackUrl,  bool? localTorrent,  int bufferAheadBytes,  int activeStreams,  String createdAt,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PreloadSessionStatus() when $default != null:
return $default(_that.sessionId,_that.url,_that.active,_that.bytesDownloaded,_that.totalSize,_that.remainingSize,_that.percent,_that.downloadComplete,_that.error,_that.state,_that.title,_that.mediaKind,_that.playbackUrl,_that.localTorrent,_that.bufferAheadBytes,_that.activeStreams,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PreloadSessionStatus implements PreloadSessionStatus {
  const _PreloadSessionStatus({required this.sessionId, required this.url, required this.active, required this.bytesDownloaded, required this.totalSize, this.remainingSize, required this.percent, required this.downloadComplete, this.error, required this.state, this.title, this.mediaKind, required this.playbackUrl, this.localTorrent, required this.bufferAheadBytes, required this.activeStreams, required this.createdAt, required this.updatedAt});
  factory _PreloadSessionStatus.fromJson(Map<String, dynamic> json) => _$PreloadSessionStatusFromJson(json);

@override final  String sessionId;
@override final  String url;
@override final  bool active;
@override final  int bytesDownloaded;
@override final  int totalSize;
@override final  int? remainingSize;
@override final  double percent;
@override final  bool downloadComplete;
@override final  String? error;
@override final  String state;
@override final  String? title;
@override final  String? mediaKind;
@override final  String playbackUrl;
@override final  bool? localTorrent;
@override final  int bufferAheadBytes;
@override final  int activeStreams;
@override final  String createdAt;
@override final  String updatedAt;

/// Create a copy of PreloadSessionStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreloadSessionStatusCopyWith<_PreloadSessionStatus> get copyWith => __$PreloadSessionStatusCopyWithImpl<_PreloadSessionStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PreloadSessionStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreloadSessionStatus&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.url, url) || other.url == url)&&(identical(other.active, active) || other.active == active)&&(identical(other.bytesDownloaded, bytesDownloaded) || other.bytesDownloaded == bytesDownloaded)&&(identical(other.totalSize, totalSize) || other.totalSize == totalSize)&&(identical(other.remainingSize, remainingSize) || other.remainingSize == remainingSize)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.downloadComplete, downloadComplete) || other.downloadComplete == downloadComplete)&&(identical(other.error, error) || other.error == error)&&(identical(other.state, state) || other.state == state)&&(identical(other.title, title) || other.title == title)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind)&&(identical(other.playbackUrl, playbackUrl) || other.playbackUrl == playbackUrl)&&(identical(other.localTorrent, localTorrent) || other.localTorrent == localTorrent)&&(identical(other.bufferAheadBytes, bufferAheadBytes) || other.bufferAheadBytes == bufferAheadBytes)&&(identical(other.activeStreams, activeStreams) || other.activeStreams == activeStreams)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,url,active,bytesDownloaded,totalSize,remainingSize,percent,downloadComplete,error,state,title,mediaKind,playbackUrl,localTorrent,bufferAheadBytes,activeStreams,createdAt,updatedAt);

@override
String toString() {
  return 'PreloadSessionStatus(sessionId: $sessionId, url: $url, active: $active, bytesDownloaded: $bytesDownloaded, totalSize: $totalSize, remainingSize: $remainingSize, percent: $percent, downloadComplete: $downloadComplete, error: $error, state: $state, title: $title, mediaKind: $mediaKind, playbackUrl: $playbackUrl, localTorrent: $localTorrent, bufferAheadBytes: $bufferAheadBytes, activeStreams: $activeStreams, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PreloadSessionStatusCopyWith<$Res> implements $PreloadSessionStatusCopyWith<$Res> {
  factory _$PreloadSessionStatusCopyWith(_PreloadSessionStatus value, $Res Function(_PreloadSessionStatus) _then) = __$PreloadSessionStatusCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, String url, bool active, int bytesDownloaded, int totalSize, int? remainingSize, double percent, bool downloadComplete, String? error, String state, String? title, String? mediaKind, String playbackUrl, bool? localTorrent, int bufferAheadBytes, int activeStreams, String createdAt, String updatedAt
});




}
/// @nodoc
class __$PreloadSessionStatusCopyWithImpl<$Res>
    implements _$PreloadSessionStatusCopyWith<$Res> {
  __$PreloadSessionStatusCopyWithImpl(this._self, this._then);

  final _PreloadSessionStatus _self;
  final $Res Function(_PreloadSessionStatus) _then;

/// Create a copy of PreloadSessionStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? url = null,Object? active = null,Object? bytesDownloaded = null,Object? totalSize = null,Object? remainingSize = freezed,Object? percent = null,Object? downloadComplete = null,Object? error = freezed,Object? state = null,Object? title = freezed,Object? mediaKind = freezed,Object? playbackUrl = null,Object? localTorrent = freezed,Object? bufferAheadBytes = null,Object? activeStreams = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_PreloadSessionStatus(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,bytesDownloaded: null == bytesDownloaded ? _self.bytesDownloaded : bytesDownloaded // ignore: cast_nullable_to_non_nullable
as int,totalSize: null == totalSize ? _self.totalSize : totalSize // ignore: cast_nullable_to_non_nullable
as int,remainingSize: freezed == remainingSize ? _self.remainingSize : remainingSize // ignore: cast_nullable_to_non_nullable
as int?,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as double,downloadComplete: null == downloadComplete ? _self.downloadComplete : downloadComplete // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,mediaKind: freezed == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as String?,playbackUrl: null == playbackUrl ? _self.playbackUrl : playbackUrl // ignore: cast_nullable_to_non_nullable
as String,localTorrent: freezed == localTorrent ? _self.localTorrent : localTorrent // ignore: cast_nullable_to_non_nullable
as bool?,bufferAheadBytes: null == bufferAheadBytes ? _self.bufferAheadBytes : bufferAheadBytes // ignore: cast_nullable_to_non_nullable
as int,activeStreams: null == activeStreams ? _self.activeStreams : activeStreams // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
