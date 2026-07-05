// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subtitle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubtitleSearchResult {

 String get provider; String get language; double get score; String get release; String get downloadLink; String get fileName; bool get hearingImpaired; double? get rating; String? get uploadedAt; Map<String, dynamic> get metadata;
/// Create a copy of SubtitleSearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleSearchResultCopyWith<SubtitleSearchResult> get copyWith => _$SubtitleSearchResultCopyWithImpl<SubtitleSearchResult>(this as SubtitleSearchResult, _$identity);

  /// Serializes this SubtitleSearchResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleSearchResult&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.language, language) || other.language == language)&&(identical(other.score, score) || other.score == score)&&(identical(other.release, release) || other.release == release)&&(identical(other.downloadLink, downloadLink) || other.downloadLink == downloadLink)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.hearingImpaired, hearingImpaired) || other.hearingImpaired == hearingImpaired)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,language,score,release,downloadLink,fileName,hearingImpaired,rating,uploadedAt,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'SubtitleSearchResult(provider: $provider, language: $language, score: $score, release: $release, downloadLink: $downloadLink, fileName: $fileName, hearingImpaired: $hearingImpaired, rating: $rating, uploadedAt: $uploadedAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $SubtitleSearchResultCopyWith<$Res>  {
  factory $SubtitleSearchResultCopyWith(SubtitleSearchResult value, $Res Function(SubtitleSearchResult) _then) = _$SubtitleSearchResultCopyWithImpl;
@useResult
$Res call({
 String provider, String language, double score, String release, String downloadLink, String fileName, bool hearingImpaired, double? rating, String? uploadedAt, Map<String, dynamic> metadata
});




}
/// @nodoc
class _$SubtitleSearchResultCopyWithImpl<$Res>
    implements $SubtitleSearchResultCopyWith<$Res> {
  _$SubtitleSearchResultCopyWithImpl(this._self, this._then);

  final SubtitleSearchResult _self;
  final $Res Function(SubtitleSearchResult) _then;

/// Create a copy of SubtitleSearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? language = null,Object? score = null,Object? release = null,Object? downloadLink = null,Object? fileName = null,Object? hearingImpaired = null,Object? rating = freezed,Object? uploadedAt = freezed,Object? metadata = null,}) {
  return _then(_self.copyWith(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,release: null == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as String,downloadLink: null == downloadLink ? _self.downloadLink : downloadLink // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,hearingImpaired: null == hearingImpaired ? _self.hearingImpaired : hearingImpaired // ignore: cast_nullable_to_non_nullable
as bool,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleSearchResult].
extension SubtitleSearchResultPatterns on SubtitleSearchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleSearchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleSearchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleSearchResult value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleSearchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleSearchResult value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleSearchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String provider,  String language,  double score,  String release,  String downloadLink,  String fileName,  bool hearingImpaired,  double? rating,  String? uploadedAt,  Map<String, dynamic> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleSearchResult() when $default != null:
return $default(_that.provider,_that.language,_that.score,_that.release,_that.downloadLink,_that.fileName,_that.hearingImpaired,_that.rating,_that.uploadedAt,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String provider,  String language,  double score,  String release,  String downloadLink,  String fileName,  bool hearingImpaired,  double? rating,  String? uploadedAt,  Map<String, dynamic> metadata)  $default,) {final _that = this;
switch (_that) {
case _SubtitleSearchResult():
return $default(_that.provider,_that.language,_that.score,_that.release,_that.downloadLink,_that.fileName,_that.hearingImpaired,_that.rating,_that.uploadedAt,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String provider,  String language,  double score,  String release,  String downloadLink,  String fileName,  bool hearingImpaired,  double? rating,  String? uploadedAt,  Map<String, dynamic> metadata)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleSearchResult() when $default != null:
return $default(_that.provider,_that.language,_that.score,_that.release,_that.downloadLink,_that.fileName,_that.hearingImpaired,_that.rating,_that.uploadedAt,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleSearchResult implements SubtitleSearchResult {
  const _SubtitleSearchResult({required this.provider, required this.language, required this.score, required this.release, required this.downloadLink, required this.fileName, required this.hearingImpaired, this.rating, this.uploadedAt, final  Map<String, dynamic> metadata = const {}}): _metadata = metadata;
  factory _SubtitleSearchResult.fromJson(Map<String, dynamic> json) => _$SubtitleSearchResultFromJson(json);

@override final  String provider;
@override final  String language;
@override final  double score;
@override final  String release;
@override final  String downloadLink;
@override final  String fileName;
@override final  bool hearingImpaired;
@override final  double? rating;
@override final  String? uploadedAt;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of SubtitleSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleSearchResultCopyWith<_SubtitleSearchResult> get copyWith => __$SubtitleSearchResultCopyWithImpl<_SubtitleSearchResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleSearchResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleSearchResult&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.language, language) || other.language == language)&&(identical(other.score, score) || other.score == score)&&(identical(other.release, release) || other.release == release)&&(identical(other.downloadLink, downloadLink) || other.downloadLink == downloadLink)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.hearingImpaired, hearingImpaired) || other.hearingImpaired == hearingImpaired)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,language,score,release,downloadLink,fileName,hearingImpaired,rating,uploadedAt,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'SubtitleSearchResult(provider: $provider, language: $language, score: $score, release: $release, downloadLink: $downloadLink, fileName: $fileName, hearingImpaired: $hearingImpaired, rating: $rating, uploadedAt: $uploadedAt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$SubtitleSearchResultCopyWith<$Res> implements $SubtitleSearchResultCopyWith<$Res> {
  factory _$SubtitleSearchResultCopyWith(_SubtitleSearchResult value, $Res Function(_SubtitleSearchResult) _then) = __$SubtitleSearchResultCopyWithImpl;
@override @useResult
$Res call({
 String provider, String language, double score, String release, String downloadLink, String fileName, bool hearingImpaired, double? rating, String? uploadedAt, Map<String, dynamic> metadata
});




}
/// @nodoc
class __$SubtitleSearchResultCopyWithImpl<$Res>
    implements _$SubtitleSearchResultCopyWith<$Res> {
  __$SubtitleSearchResultCopyWithImpl(this._self, this._then);

  final _SubtitleSearchResult _self;
  final $Res Function(_SubtitleSearchResult) _then;

/// Create a copy of SubtitleSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? language = null,Object? score = null,Object? release = null,Object? downloadLink = null,Object? fileName = null,Object? hearingImpaired = null,Object? rating = freezed,Object? uploadedAt = freezed,Object? metadata = null,}) {
  return _then(_SubtitleSearchResult(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,release: null == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as String,downloadLink: null == downloadLink ? _self.downloadLink : downloadLink // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,hearingImpaired: null == hearingImpaired ? _self.hearingImpaired : hearingImpaired // ignore: cast_nullable_to_non_nullable
as bool,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,uploadedAt: freezed == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$SubtitleSearchResponse {

 String get query; String get mediaKind; String get language; List<SubtitleSearchResult> get results; int get count;
/// Create a copy of SubtitleSearchResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleSearchResponseCopyWith<SubtitleSearchResponse> get copyWith => _$SubtitleSearchResponseCopyWithImpl<SubtitleSearchResponse>(this as SubtitleSearchResponse, _$identity);

  /// Serializes this SubtitleSearchResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleSearchResponse&&(identical(other.query, query) || other.query == query)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other.results, results)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,mediaKind,language,const DeepCollectionEquality().hash(results),count);

@override
String toString() {
  return 'SubtitleSearchResponse(query: $query, mediaKind: $mediaKind, language: $language, results: $results, count: $count)';
}


}

/// @nodoc
abstract mixin class $SubtitleSearchResponseCopyWith<$Res>  {
  factory $SubtitleSearchResponseCopyWith(SubtitleSearchResponse value, $Res Function(SubtitleSearchResponse) _then) = _$SubtitleSearchResponseCopyWithImpl;
@useResult
$Res call({
 String query, String mediaKind, String language, List<SubtitleSearchResult> results, int count
});




}
/// @nodoc
class _$SubtitleSearchResponseCopyWithImpl<$Res>
    implements $SubtitleSearchResponseCopyWith<$Res> {
  _$SubtitleSearchResponseCopyWithImpl(this._self, this._then);

  final SubtitleSearchResponse _self;
  final $Res Function(SubtitleSearchResponse) _then;

/// Create a copy of SubtitleSearchResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? mediaKind = null,Object? language = null,Object? results = null,Object? count = null,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,mediaKind: null == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<SubtitleSearchResult>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleSearchResponse].
extension SubtitleSearchResponsePatterns on SubtitleSearchResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleSearchResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleSearchResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleSearchResponse value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleSearchResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleSearchResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleSearchResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  String mediaKind,  String language,  List<SubtitleSearchResult> results,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleSearchResponse() when $default != null:
return $default(_that.query,_that.mediaKind,_that.language,_that.results,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  String mediaKind,  String language,  List<SubtitleSearchResult> results,  int count)  $default,) {final _that = this;
switch (_that) {
case _SubtitleSearchResponse():
return $default(_that.query,_that.mediaKind,_that.language,_that.results,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  String mediaKind,  String language,  List<SubtitleSearchResult> results,  int count)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleSearchResponse() when $default != null:
return $default(_that.query,_that.mediaKind,_that.language,_that.results,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleSearchResponse implements SubtitleSearchResponse {
  const _SubtitleSearchResponse({required this.query, required this.mediaKind, required this.language, required final  List<SubtitleSearchResult> results, required this.count}): _results = results;
  factory _SubtitleSearchResponse.fromJson(Map<String, dynamic> json) => _$SubtitleSearchResponseFromJson(json);

@override final  String query;
@override final  String mediaKind;
@override final  String language;
 final  List<SubtitleSearchResult> _results;
@override List<SubtitleSearchResult> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override final  int count;

/// Create a copy of SubtitleSearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleSearchResponseCopyWith<_SubtitleSearchResponse> get copyWith => __$SubtitleSearchResponseCopyWithImpl<_SubtitleSearchResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleSearchResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleSearchResponse&&(identical(other.query, query) || other.query == query)&&(identical(other.mediaKind, mediaKind) || other.mediaKind == mediaKind)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other._results, _results)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,mediaKind,language,const DeepCollectionEquality().hash(_results),count);

@override
String toString() {
  return 'SubtitleSearchResponse(query: $query, mediaKind: $mediaKind, language: $language, results: $results, count: $count)';
}


}

/// @nodoc
abstract mixin class _$SubtitleSearchResponseCopyWith<$Res> implements $SubtitleSearchResponseCopyWith<$Res> {
  factory _$SubtitleSearchResponseCopyWith(_SubtitleSearchResponse value, $Res Function(_SubtitleSearchResponse) _then) = __$SubtitleSearchResponseCopyWithImpl;
@override @useResult
$Res call({
 String query, String mediaKind, String language, List<SubtitleSearchResult> results, int count
});




}
/// @nodoc
class __$SubtitleSearchResponseCopyWithImpl<$Res>
    implements _$SubtitleSearchResponseCopyWith<$Res> {
  __$SubtitleSearchResponseCopyWithImpl(this._self, this._then);

  final _SubtitleSearchResponse _self;
  final $Res Function(_SubtitleSearchResponse) _then;

/// Create a copy of SubtitleSearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? mediaKind = null,Object? language = null,Object? results = null,Object? count = null,}) {
  return _then(_SubtitleSearchResponse(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,mediaKind: null == mediaKind ? _self.mediaKind : mediaKind // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<SubtitleSearchResult>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SubtitleDownloadResponse {

 String get id; String get fileName; String get path; String get url;
/// Create a copy of SubtitleDownloadResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleDownloadResponseCopyWith<SubtitleDownloadResponse> get copyWith => _$SubtitleDownloadResponseCopyWithImpl<SubtitleDownloadResponse>(this as SubtitleDownloadResponse, _$identity);

  /// Serializes this SubtitleDownloadResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleDownloadResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.path, path) || other.path == path)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fileName,path,url);

@override
String toString() {
  return 'SubtitleDownloadResponse(id: $id, fileName: $fileName, path: $path, url: $url)';
}


}

/// @nodoc
abstract mixin class $SubtitleDownloadResponseCopyWith<$Res>  {
  factory $SubtitleDownloadResponseCopyWith(SubtitleDownloadResponse value, $Res Function(SubtitleDownloadResponse) _then) = _$SubtitleDownloadResponseCopyWithImpl;
@useResult
$Res call({
 String id, String fileName, String path, String url
});




}
/// @nodoc
class _$SubtitleDownloadResponseCopyWithImpl<$Res>
    implements $SubtitleDownloadResponseCopyWith<$Res> {
  _$SubtitleDownloadResponseCopyWithImpl(this._self, this._then);

  final SubtitleDownloadResponse _self;
  final $Res Function(SubtitleDownloadResponse) _then;

/// Create a copy of SubtitleDownloadResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fileName = null,Object? path = null,Object? url = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleDownloadResponse].
extension SubtitleDownloadResponsePatterns on SubtitleDownloadResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleDownloadResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleDownloadResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleDownloadResponse value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleDownloadResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleDownloadResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleDownloadResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fileName,  String path,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleDownloadResponse() when $default != null:
return $default(_that.id,_that.fileName,_that.path,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fileName,  String path,  String url)  $default,) {final _that = this;
switch (_that) {
case _SubtitleDownloadResponse():
return $default(_that.id,_that.fileName,_that.path,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fileName,  String path,  String url)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleDownloadResponse() when $default != null:
return $default(_that.id,_that.fileName,_that.path,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleDownloadResponse implements SubtitleDownloadResponse {
  const _SubtitleDownloadResponse({required this.id, required this.fileName, required this.path, required this.url});
  factory _SubtitleDownloadResponse.fromJson(Map<String, dynamic> json) => _$SubtitleDownloadResponseFromJson(json);

@override final  String id;
@override final  String fileName;
@override final  String path;
@override final  String url;

/// Create a copy of SubtitleDownloadResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleDownloadResponseCopyWith<_SubtitleDownloadResponse> get copyWith => __$SubtitleDownloadResponseCopyWithImpl<_SubtitleDownloadResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleDownloadResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleDownloadResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.path, path) || other.path == path)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fileName,path,url);

@override
String toString() {
  return 'SubtitleDownloadResponse(id: $id, fileName: $fileName, path: $path, url: $url)';
}


}

/// @nodoc
abstract mixin class _$SubtitleDownloadResponseCopyWith<$Res> implements $SubtitleDownloadResponseCopyWith<$Res> {
  factory _$SubtitleDownloadResponseCopyWith(_SubtitleDownloadResponse value, $Res Function(_SubtitleDownloadResponse) _then) = __$SubtitleDownloadResponseCopyWithImpl;
@override @useResult
$Res call({
 String id, String fileName, String path, String url
});




}
/// @nodoc
class __$SubtitleDownloadResponseCopyWithImpl<$Res>
    implements _$SubtitleDownloadResponseCopyWith<$Res> {
  __$SubtitleDownloadResponseCopyWithImpl(this._self, this._then);

  final _SubtitleDownloadResponse _self;
  final $Res Function(_SubtitleDownloadResponse) _then;

/// Create a copy of SubtitleDownloadResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fileName = null,Object? path = null,Object? url = null,}) {
  return _then(_SubtitleDownloadResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SubtitleLoadResponse {

 String get status; String get path; String? get url;
/// Create a copy of SubtitleLoadResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleLoadResponseCopyWith<SubtitleLoadResponse> get copyWith => _$SubtitleLoadResponseCopyWithImpl<SubtitleLoadResponse>(this as SubtitleLoadResponse, _$identity);

  /// Serializes this SubtitleLoadResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleLoadResponse&&(identical(other.status, status) || other.status == status)&&(identical(other.path, path) || other.path == path)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,path,url);

@override
String toString() {
  return 'SubtitleLoadResponse(status: $status, path: $path, url: $url)';
}


}

/// @nodoc
abstract mixin class $SubtitleLoadResponseCopyWith<$Res>  {
  factory $SubtitleLoadResponseCopyWith(SubtitleLoadResponse value, $Res Function(SubtitleLoadResponse) _then) = _$SubtitleLoadResponseCopyWithImpl;
@useResult
$Res call({
 String status, String path, String? url
});




}
/// @nodoc
class _$SubtitleLoadResponseCopyWithImpl<$Res>
    implements $SubtitleLoadResponseCopyWith<$Res> {
  _$SubtitleLoadResponseCopyWithImpl(this._self, this._then);

  final SubtitleLoadResponse _self;
  final $Res Function(SubtitleLoadResponse) _then;

/// Create a copy of SubtitleLoadResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? path = null,Object? url = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleLoadResponse].
extension SubtitleLoadResponsePatterns on SubtitleLoadResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleLoadResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleLoadResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleLoadResponse value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleLoadResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleLoadResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleLoadResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String path,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleLoadResponse() when $default != null:
return $default(_that.status,_that.path,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String path,  String? url)  $default,) {final _that = this;
switch (_that) {
case _SubtitleLoadResponse():
return $default(_that.status,_that.path,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String path,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleLoadResponse() when $default != null:
return $default(_that.status,_that.path,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleLoadResponse implements SubtitleLoadResponse {
  const _SubtitleLoadResponse({required this.status, required this.path, this.url});
  factory _SubtitleLoadResponse.fromJson(Map<String, dynamic> json) => _$SubtitleLoadResponseFromJson(json);

@override final  String status;
@override final  String path;
@override final  String? url;

/// Create a copy of SubtitleLoadResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleLoadResponseCopyWith<_SubtitleLoadResponse> get copyWith => __$SubtitleLoadResponseCopyWithImpl<_SubtitleLoadResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleLoadResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleLoadResponse&&(identical(other.status, status) || other.status == status)&&(identical(other.path, path) || other.path == path)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,path,url);

@override
String toString() {
  return 'SubtitleLoadResponse(status: $status, path: $path, url: $url)';
}


}

/// @nodoc
abstract mixin class _$SubtitleLoadResponseCopyWith<$Res> implements $SubtitleLoadResponseCopyWith<$Res> {
  factory _$SubtitleLoadResponseCopyWith(_SubtitleLoadResponse value, $Res Function(_SubtitleLoadResponse) _then) = __$SubtitleLoadResponseCopyWithImpl;
@override @useResult
$Res call({
 String status, String path, String? url
});




}
/// @nodoc
class __$SubtitleLoadResponseCopyWithImpl<$Res>
    implements _$SubtitleLoadResponseCopyWith<$Res> {
  __$SubtitleLoadResponseCopyWithImpl(this._self, this._then);

  final _SubtitleLoadResponse _self;
  final $Res Function(_SubtitleLoadResponse) _then;

/// Create a copy of SubtitleLoadResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? path = null,Object? url = freezed,}) {
  return _then(_SubtitleLoadResponse(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SubtitleTrack {

 String get id; String get language; String get name; String? get url;
/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleTrackCopyWith<SubtitleTrack> get copyWith => _$SubtitleTrackCopyWithImpl<SubtitleTrack>(this as SubtitleTrack, _$identity);

  /// Serializes this SubtitleTrack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleTrack&&(identical(other.id, id) || other.id == id)&&(identical(other.language, language) || other.language == language)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,language,name,url);

@override
String toString() {
  return 'SubtitleTrack(id: $id, language: $language, name: $name, url: $url)';
}


}

/// @nodoc
abstract mixin class $SubtitleTrackCopyWith<$Res>  {
  factory $SubtitleTrackCopyWith(SubtitleTrack value, $Res Function(SubtitleTrack) _then) = _$SubtitleTrackCopyWithImpl;
@useResult
$Res call({
 String id, String language, String name, String? url
});




}
/// @nodoc
class _$SubtitleTrackCopyWithImpl<$Res>
    implements $SubtitleTrackCopyWith<$Res> {
  _$SubtitleTrackCopyWithImpl(this._self, this._then);

  final SubtitleTrack _self;
  final $Res Function(SubtitleTrack) _then;

/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? language = null,Object? name = null,Object? url = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleTrack].
extension SubtitleTrackPatterns on SubtitleTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleTrack value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleTrack value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String language,  String name,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
return $default(_that.id,_that.language,_that.name,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String language,  String name,  String? url)  $default,) {final _that = this;
switch (_that) {
case _SubtitleTrack():
return $default(_that.id,_that.language,_that.name,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String language,  String name,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
return $default(_that.id,_that.language,_that.name,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleTrack implements SubtitleTrack {
  const _SubtitleTrack({required this.id, required this.language, required this.name, this.url});
  factory _SubtitleTrack.fromJson(Map<String, dynamic> json) => _$SubtitleTrackFromJson(json);

@override final  String id;
@override final  String language;
@override final  String name;
@override final  String? url;

/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleTrackCopyWith<_SubtitleTrack> get copyWith => __$SubtitleTrackCopyWithImpl<_SubtitleTrack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleTrackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleTrack&&(identical(other.id, id) || other.id == id)&&(identical(other.language, language) || other.language == language)&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,language,name,url);

@override
String toString() {
  return 'SubtitleTrack(id: $id, language: $language, name: $name, url: $url)';
}


}

/// @nodoc
abstract mixin class _$SubtitleTrackCopyWith<$Res> implements $SubtitleTrackCopyWith<$Res> {
  factory _$SubtitleTrackCopyWith(_SubtitleTrack value, $Res Function(_SubtitleTrack) _then) = __$SubtitleTrackCopyWithImpl;
@override @useResult
$Res call({
 String id, String language, String name, String? url
});




}
/// @nodoc
class __$SubtitleTrackCopyWithImpl<$Res>
    implements _$SubtitleTrackCopyWith<$Res> {
  __$SubtitleTrackCopyWithImpl(this._self, this._then);

  final _SubtitleTrack _self;
  final $Res Function(_SubtitleTrack) _then;

/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? language = null,Object? name = null,Object? url = freezed,}) {
  return _then(_SubtitleTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
