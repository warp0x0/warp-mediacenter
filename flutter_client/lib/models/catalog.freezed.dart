// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatalogResponse {

 String get category; String get mediaType; String? get source; String? get listId; int? get page; String? get period; int? get limit; int? get offset; int? get total;/// Whether more items exist past this window.
///
/// This — not `offset + count < total` — is what Load More must branch on.
/// `total` is a display hint that several sources cannot report at all
/// (Simkl's genre browse returns no count) and that TMDb reports in the
/// millions while capping how deep you can actually page. Nullable so a
/// response from an older backend still parses.
 bool? get hasMore; List<MediaItem> get items; int get count;
/// Create a copy of CatalogResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogResponseCopyWith<CatalogResponse> get copyWith => _$CatalogResponseCopyWithImpl<CatalogResponse>(this as CatalogResponse, _$identity);

  /// Serializes this CatalogResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogResponse&&(identical(other.category, category) || other.category == category)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.source, source) || other.source == source)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.page, page) || other.page == page)&&(identical(other.period, period) || other.period == period)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.total, total) || other.total == total)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,mediaType,source,listId,page,period,limit,offset,total,hasMore,const DeepCollectionEquality().hash(items),count);

@override
String toString() {
  return 'CatalogResponse(category: $category, mediaType: $mediaType, source: $source, listId: $listId, page: $page, period: $period, limit: $limit, offset: $offset, total: $total, hasMore: $hasMore, items: $items, count: $count)';
}


}

/// @nodoc
abstract mixin class $CatalogResponseCopyWith<$Res>  {
  factory $CatalogResponseCopyWith(CatalogResponse value, $Res Function(CatalogResponse) _then) = _$CatalogResponseCopyWithImpl;
@useResult
$Res call({
 String category, String mediaType, String? source, String? listId, int? page, String? period, int? limit, int? offset, int? total, bool? hasMore, List<MediaItem> items, int count
});




}
/// @nodoc
class _$CatalogResponseCopyWithImpl<$Res>
    implements $CatalogResponseCopyWith<$Res> {
  _$CatalogResponseCopyWithImpl(this._self, this._then);

  final CatalogResponse _self;
  final $Res Function(CatalogResponse) _then;

/// Create a copy of CatalogResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? mediaType = null,Object? source = freezed,Object? listId = freezed,Object? page = freezed,Object? period = freezed,Object? limit = freezed,Object? offset = freezed,Object? total = freezed,Object? hasMore = freezed,Object? items = null,Object? count = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,page: freezed == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int?,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String?,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int?,offset: freezed == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,hasMore: freezed == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogResponse].
extension CatalogResponsePatterns on CatalogResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogResponse value)  $default,){
final _that = this;
switch (_that) {
case _CatalogResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String category,  String mediaType,  String? source,  String? listId,  int? page,  String? period,  int? limit,  int? offset,  int? total,  bool? hasMore,  List<MediaItem> items,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogResponse() when $default != null:
return $default(_that.category,_that.mediaType,_that.source,_that.listId,_that.page,_that.period,_that.limit,_that.offset,_that.total,_that.hasMore,_that.items,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String category,  String mediaType,  String? source,  String? listId,  int? page,  String? period,  int? limit,  int? offset,  int? total,  bool? hasMore,  List<MediaItem> items,  int count)  $default,) {final _that = this;
switch (_that) {
case _CatalogResponse():
return $default(_that.category,_that.mediaType,_that.source,_that.listId,_that.page,_that.period,_that.limit,_that.offset,_that.total,_that.hasMore,_that.items,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String category,  String mediaType,  String? source,  String? listId,  int? page,  String? period,  int? limit,  int? offset,  int? total,  bool? hasMore,  List<MediaItem> items,  int count)?  $default,) {final _that = this;
switch (_that) {
case _CatalogResponse() when $default != null:
return $default(_that.category,_that.mediaType,_that.source,_that.listId,_that.page,_that.period,_that.limit,_that.offset,_that.total,_that.hasMore,_that.items,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogResponse implements CatalogResponse {
  const _CatalogResponse({required this.category, required this.mediaType, this.source, this.listId, this.page, this.period, this.limit, this.offset, this.total, this.hasMore, required final  List<MediaItem> items, required this.count}): _items = items;
  factory _CatalogResponse.fromJson(Map<String, dynamic> json) => _$CatalogResponseFromJson(json);

@override final  String category;
@override final  String mediaType;
@override final  String? source;
@override final  String? listId;
@override final  int? page;
@override final  String? period;
@override final  int? limit;
@override final  int? offset;
@override final  int? total;
/// Whether more items exist past this window.
///
/// This — not `offset + count < total` — is what Load More must branch on.
/// `total` is a display hint that several sources cannot report at all
/// (Simkl's genre browse returns no count) and that TMDb reports in the
/// millions while capping how deep you can actually page. Nullable so a
/// response from an older backend still parses.
@override final  bool? hasMore;
 final  List<MediaItem> _items;
@override List<MediaItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int count;

/// Create a copy of CatalogResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogResponseCopyWith<_CatalogResponse> get copyWith => __$CatalogResponseCopyWithImpl<_CatalogResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogResponse&&(identical(other.category, category) || other.category == category)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.source, source) || other.source == source)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.page, page) || other.page == page)&&(identical(other.period, period) || other.period == period)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.total, total) || other.total == total)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,mediaType,source,listId,page,period,limit,offset,total,hasMore,const DeepCollectionEquality().hash(_items),count);

@override
String toString() {
  return 'CatalogResponse(category: $category, mediaType: $mediaType, source: $source, listId: $listId, page: $page, period: $period, limit: $limit, offset: $offset, total: $total, hasMore: $hasMore, items: $items, count: $count)';
}


}

/// @nodoc
abstract mixin class _$CatalogResponseCopyWith<$Res> implements $CatalogResponseCopyWith<$Res> {
  factory _$CatalogResponseCopyWith(_CatalogResponse value, $Res Function(_CatalogResponse) _then) = __$CatalogResponseCopyWithImpl;
@override @useResult
$Res call({
 String category, String mediaType, String? source, String? listId, int? page, String? period, int? limit, int? offset, int? total, bool? hasMore, List<MediaItem> items, int count
});




}
/// @nodoc
class __$CatalogResponseCopyWithImpl<$Res>
    implements _$CatalogResponseCopyWith<$Res> {
  __$CatalogResponseCopyWithImpl(this._self, this._then);

  final _CatalogResponse _self;
  final $Res Function(_CatalogResponse) _then;

/// Create a copy of CatalogResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? mediaType = null,Object? source = freezed,Object? listId = freezed,Object? page = freezed,Object? period = freezed,Object? limit = freezed,Object? offset = freezed,Object? total = freezed,Object? hasMore = freezed,Object? items = null,Object? count = null,}) {
  return _then(_CatalogResponse(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,mediaType: null == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,page: freezed == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int?,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String?,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int?,offset: freezed == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,hasMore: freezed == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MediaItem>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CatalogListDef {

 String get id; String get title; List<String> get mediaTypes; String get group; String? get description; bool get supportsPagination; int get pageSize; Map<String, dynamic>? get params; String? get sortHint;
/// Create a copy of CatalogListDef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogListDefCopyWith<CatalogListDef> get copyWith => _$CatalogListDefCopyWithImpl<CatalogListDef>(this as CatalogListDef, _$identity);

  /// Serializes this CatalogListDef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogListDef&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.mediaTypes, mediaTypes)&&(identical(other.group, group) || other.group == group)&&(identical(other.description, description) || other.description == description)&&(identical(other.supportsPagination, supportsPagination) || other.supportsPagination == supportsPagination)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&const DeepCollectionEquality().equals(other.params, params)&&(identical(other.sortHint, sortHint) || other.sortHint == sortHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(mediaTypes),group,description,supportsPagination,pageSize,const DeepCollectionEquality().hash(params),sortHint);

@override
String toString() {
  return 'CatalogListDef(id: $id, title: $title, mediaTypes: $mediaTypes, group: $group, description: $description, supportsPagination: $supportsPagination, pageSize: $pageSize, params: $params, sortHint: $sortHint)';
}


}

/// @nodoc
abstract mixin class $CatalogListDefCopyWith<$Res>  {
  factory $CatalogListDefCopyWith(CatalogListDef value, $Res Function(CatalogListDef) _then) = _$CatalogListDefCopyWithImpl;
@useResult
$Res call({
 String id, String title, List<String> mediaTypes, String group, String? description, bool supportsPagination, int pageSize, Map<String, dynamic>? params, String? sortHint
});




}
/// @nodoc
class _$CatalogListDefCopyWithImpl<$Res>
    implements $CatalogListDefCopyWith<$Res> {
  _$CatalogListDefCopyWithImpl(this._self, this._then);

  final CatalogListDef _self;
  final $Res Function(CatalogListDef) _then;

/// Create a copy of CatalogListDef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? mediaTypes = null,Object? group = null,Object? description = freezed,Object? supportsPagination = null,Object? pageSize = null,Object? params = freezed,Object? sortHint = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,mediaTypes: null == mediaTypes ? _self.mediaTypes : mediaTypes // ignore: cast_nullable_to_non_nullable
as List<String>,group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,supportsPagination: null == supportsPagination ? _self.supportsPagination : supportsPagination // ignore: cast_nullable_to_non_nullable
as bool,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,params: freezed == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,sortHint: freezed == sortHint ? _self.sortHint : sortHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogListDef].
extension CatalogListDefPatterns on CatalogListDef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogListDef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogListDef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogListDef value)  $default,){
final _that = this;
switch (_that) {
case _CatalogListDef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogListDef value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogListDef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  List<String> mediaTypes,  String group,  String? description,  bool supportsPagination,  int pageSize,  Map<String, dynamic>? params,  String? sortHint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogListDef() when $default != null:
return $default(_that.id,_that.title,_that.mediaTypes,_that.group,_that.description,_that.supportsPagination,_that.pageSize,_that.params,_that.sortHint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  List<String> mediaTypes,  String group,  String? description,  bool supportsPagination,  int pageSize,  Map<String, dynamic>? params,  String? sortHint)  $default,) {final _that = this;
switch (_that) {
case _CatalogListDef():
return $default(_that.id,_that.title,_that.mediaTypes,_that.group,_that.description,_that.supportsPagination,_that.pageSize,_that.params,_that.sortHint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  List<String> mediaTypes,  String group,  String? description,  bool supportsPagination,  int pageSize,  Map<String, dynamic>? params,  String? sortHint)?  $default,) {final _that = this;
switch (_that) {
case _CatalogListDef() when $default != null:
return $default(_that.id,_that.title,_that.mediaTypes,_that.group,_that.description,_that.supportsPagination,_that.pageSize,_that.params,_that.sortHint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogListDef implements CatalogListDef {
  const _CatalogListDef({required this.id, required this.title, final  List<String> mediaTypes = const ['movie', 'show'], this.group = 'other', this.description, this.supportsPagination = false, this.pageSize = 20, final  Map<String, dynamic>? params, this.sortHint}): _mediaTypes = mediaTypes,_params = params;
  factory _CatalogListDef.fromJson(Map<String, dynamic> json) => _$CatalogListDefFromJson(json);

@override final  String id;
@override final  String title;
 final  List<String> _mediaTypes;
@override@JsonKey() List<String> get mediaTypes {
  if (_mediaTypes is EqualUnmodifiableListView) return _mediaTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mediaTypes);
}

@override@JsonKey() final  String group;
@override final  String? description;
@override@JsonKey() final  bool supportsPagination;
@override@JsonKey() final  int pageSize;
 final  Map<String, dynamic>? _params;
@override Map<String, dynamic>? get params {
  final value = _params;
  if (value == null) return null;
  if (_params is EqualUnmodifiableMapView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? sortHint;

/// Create a copy of CatalogListDef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogListDefCopyWith<_CatalogListDef> get copyWith => __$CatalogListDefCopyWithImpl<_CatalogListDef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogListDefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogListDef&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._mediaTypes, _mediaTypes)&&(identical(other.group, group) || other.group == group)&&(identical(other.description, description) || other.description == description)&&(identical(other.supportsPagination, supportsPagination) || other.supportsPagination == supportsPagination)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&const DeepCollectionEquality().equals(other._params, _params)&&(identical(other.sortHint, sortHint) || other.sortHint == sortHint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_mediaTypes),group,description,supportsPagination,pageSize,const DeepCollectionEquality().hash(_params),sortHint);

@override
String toString() {
  return 'CatalogListDef(id: $id, title: $title, mediaTypes: $mediaTypes, group: $group, description: $description, supportsPagination: $supportsPagination, pageSize: $pageSize, params: $params, sortHint: $sortHint)';
}


}

/// @nodoc
abstract mixin class _$CatalogListDefCopyWith<$Res> implements $CatalogListDefCopyWith<$Res> {
  factory _$CatalogListDefCopyWith(_CatalogListDef value, $Res Function(_CatalogListDef) _then) = __$CatalogListDefCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, List<String> mediaTypes, String group, String? description, bool supportsPagination, int pageSize, Map<String, dynamic>? params, String? sortHint
});




}
/// @nodoc
class __$CatalogListDefCopyWithImpl<$Res>
    implements _$CatalogListDefCopyWith<$Res> {
  __$CatalogListDefCopyWithImpl(this._self, this._then);

  final _CatalogListDef _self;
  final $Res Function(_CatalogListDef) _then;

/// Create a copy of CatalogListDef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? mediaTypes = null,Object? group = null,Object? description = freezed,Object? supportsPagination = null,Object? pageSize = null,Object? params = freezed,Object? sortHint = freezed,}) {
  return _then(_CatalogListDef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,mediaTypes: null == mediaTypes ? _self._mediaTypes : mediaTypes // ignore: cast_nullable_to_non_nullable
as List<String>,group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,supportsPagination: null == supportsPagination ? _self.supportsPagination : supportsPagination // ignore: cast_nullable_to_non_nullable
as bool,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,params: freezed == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,sortHint: freezed == sortHint ? _self.sortHint : sortHint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CatalogSourceDef {

 String get id; String get label; String get kind; String? get icon; List<CatalogListDef> get lists;
/// Create a copy of CatalogSourceDef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogSourceDefCopyWith<CatalogSourceDef> get copyWith => _$CatalogSourceDefCopyWithImpl<CatalogSourceDef>(this as CatalogSourceDef, _$identity);

  /// Serializes this CatalogSourceDef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogSourceDef&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other.lists, lists));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,kind,icon,const DeepCollectionEquality().hash(lists));

@override
String toString() {
  return 'CatalogSourceDef(id: $id, label: $label, kind: $kind, icon: $icon, lists: $lists)';
}


}

/// @nodoc
abstract mixin class $CatalogSourceDefCopyWith<$Res>  {
  factory $CatalogSourceDefCopyWith(CatalogSourceDef value, $Res Function(CatalogSourceDef) _then) = _$CatalogSourceDefCopyWithImpl;
@useResult
$Res call({
 String id, String label, String kind, String? icon, List<CatalogListDef> lists
});




}
/// @nodoc
class _$CatalogSourceDefCopyWithImpl<$Res>
    implements $CatalogSourceDefCopyWith<$Res> {
  _$CatalogSourceDefCopyWithImpl(this._self, this._then);

  final CatalogSourceDef _self;
  final $Res Function(CatalogSourceDef) _then;

/// Create a copy of CatalogSourceDef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? kind = null,Object? icon = freezed,Object? lists = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,lists: null == lists ? _self.lists : lists // ignore: cast_nullable_to_non_nullable
as List<CatalogListDef>,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogSourceDef].
extension CatalogSourceDefPatterns on CatalogSourceDef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogSourceDef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogSourceDef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogSourceDef value)  $default,){
final _that = this;
switch (_that) {
case _CatalogSourceDef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogSourceDef value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogSourceDef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String kind,  String? icon,  List<CatalogListDef> lists)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogSourceDef() when $default != null:
return $default(_that.id,_that.label,_that.kind,_that.icon,_that.lists);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String kind,  String? icon,  List<CatalogListDef> lists)  $default,) {final _that = this;
switch (_that) {
case _CatalogSourceDef():
return $default(_that.id,_that.label,_that.kind,_that.icon,_that.lists);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String kind,  String? icon,  List<CatalogListDef> lists)?  $default,) {final _that = this;
switch (_that) {
case _CatalogSourceDef() when $default != null:
return $default(_that.id,_that.label,_that.kind,_that.icon,_that.lists);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogSourceDef implements CatalogSourceDef {
  const _CatalogSourceDef({required this.id, required this.label, this.kind = 'builtin', this.icon, final  List<CatalogListDef> lists = const []}): _lists = lists;
  factory _CatalogSourceDef.fromJson(Map<String, dynamic> json) => _$CatalogSourceDefFromJson(json);

@override final  String id;
@override final  String label;
@override@JsonKey() final  String kind;
@override final  String? icon;
 final  List<CatalogListDef> _lists;
@override@JsonKey() List<CatalogListDef> get lists {
  if (_lists is EqualUnmodifiableListView) return _lists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lists);
}


/// Create a copy of CatalogSourceDef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogSourceDefCopyWith<_CatalogSourceDef> get copyWith => __$CatalogSourceDefCopyWithImpl<_CatalogSourceDef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogSourceDefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogSourceDef&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other._lists, _lists));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,kind,icon,const DeepCollectionEquality().hash(_lists));

@override
String toString() {
  return 'CatalogSourceDef(id: $id, label: $label, kind: $kind, icon: $icon, lists: $lists)';
}


}

/// @nodoc
abstract mixin class _$CatalogSourceDefCopyWith<$Res> implements $CatalogSourceDefCopyWith<$Res> {
  factory _$CatalogSourceDefCopyWith(_CatalogSourceDef value, $Res Function(_CatalogSourceDef) _then) = __$CatalogSourceDefCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String kind, String? icon, List<CatalogListDef> lists
});




}
/// @nodoc
class __$CatalogSourceDefCopyWithImpl<$Res>
    implements _$CatalogSourceDefCopyWith<$Res> {
  __$CatalogSourceDefCopyWithImpl(this._self, this._then);

  final _CatalogSourceDef _self;
  final $Res Function(_CatalogSourceDef) _then;

/// Create a copy of CatalogSourceDef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? kind = null,Object? icon = freezed,Object? lists = null,}) {
  return _then(_CatalogSourceDef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,lists: null == lists ? _self._lists : lists // ignore: cast_nullable_to_non_nullable
as List<CatalogListDef>,
  ));
}


}


/// @nodoc
mixin _$CatalogDefinitions {

 List<CatalogSourceDef> get sources;
/// Create a copy of CatalogDefinitions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogDefinitionsCopyWith<CatalogDefinitions> get copyWith => _$CatalogDefinitionsCopyWithImpl<CatalogDefinitions>(this as CatalogDefinitions, _$identity);

  /// Serializes this CatalogDefinitions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogDefinitions&&const DeepCollectionEquality().equals(other.sources, sources));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(sources));

@override
String toString() {
  return 'CatalogDefinitions(sources: $sources)';
}


}

/// @nodoc
abstract mixin class $CatalogDefinitionsCopyWith<$Res>  {
  factory $CatalogDefinitionsCopyWith(CatalogDefinitions value, $Res Function(CatalogDefinitions) _then) = _$CatalogDefinitionsCopyWithImpl;
@useResult
$Res call({
 List<CatalogSourceDef> sources
});




}
/// @nodoc
class _$CatalogDefinitionsCopyWithImpl<$Res>
    implements $CatalogDefinitionsCopyWith<$Res> {
  _$CatalogDefinitionsCopyWithImpl(this._self, this._then);

  final CatalogDefinitions _self;
  final $Res Function(CatalogDefinitions) _then;

/// Create a copy of CatalogDefinitions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sources = null,}) {
  return _then(_self.copyWith(
sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<CatalogSourceDef>,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogDefinitions].
extension CatalogDefinitionsPatterns on CatalogDefinitions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogDefinitions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogDefinitions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogDefinitions value)  $default,){
final _that = this;
switch (_that) {
case _CatalogDefinitions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogDefinitions value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogDefinitions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CatalogSourceDef> sources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogDefinitions() when $default != null:
return $default(_that.sources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CatalogSourceDef> sources)  $default,) {final _that = this;
switch (_that) {
case _CatalogDefinitions():
return $default(_that.sources);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CatalogSourceDef> sources)?  $default,) {final _that = this;
switch (_that) {
case _CatalogDefinitions() when $default != null:
return $default(_that.sources);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogDefinitions implements CatalogDefinitions {
  const _CatalogDefinitions({final  List<CatalogSourceDef> sources = const []}): _sources = sources;
  factory _CatalogDefinitions.fromJson(Map<String, dynamic> json) => _$CatalogDefinitionsFromJson(json);

 final  List<CatalogSourceDef> _sources;
@override@JsonKey() List<CatalogSourceDef> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}


/// Create a copy of CatalogDefinitions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogDefinitionsCopyWith<_CatalogDefinitions> get copyWith => __$CatalogDefinitionsCopyWithImpl<_CatalogDefinitions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogDefinitionsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogDefinitions&&const DeepCollectionEquality().equals(other._sources, _sources));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_sources));

@override
String toString() {
  return 'CatalogDefinitions(sources: $sources)';
}


}

/// @nodoc
abstract mixin class _$CatalogDefinitionsCopyWith<$Res> implements $CatalogDefinitionsCopyWith<$Res> {
  factory _$CatalogDefinitionsCopyWith(_CatalogDefinitions value, $Res Function(_CatalogDefinitions) _then) = __$CatalogDefinitionsCopyWithImpl;
@override @useResult
$Res call({
 List<CatalogSourceDef> sources
});




}
/// @nodoc
class __$CatalogDefinitionsCopyWithImpl<$Res>
    implements _$CatalogDefinitionsCopyWith<$Res> {
  __$CatalogDefinitionsCopyWithImpl(this._self, this._then);

  final _CatalogDefinitions _self;
  final $Res Function(_CatalogDefinitions) _then;

/// Create a copy of CatalogDefinitions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sources = null,}) {
  return _then(_CatalogDefinitions(
sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<CatalogSourceDef>,
  ));
}


}


/// @nodoc
mixin _$SearchResultItem {

 String get source; Object? get id; String get title; String get type; int? get year; String? get overview; String? get posterUrl; String? get posterPath; String? get backdropPath; String? get tmdbId; List<dynamic> get genres; double? get rating; Object? get media;
/// Create a copy of SearchResultItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultItemCopyWith<SearchResultItem> get copyWith => _$SearchResultItemCopyWithImpl<SearchResultItem>(this as SearchResultItem, _$identity);

  /// Serializes this SearchResultItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultItem&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.id, id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.year, year) || other.year == year)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.posterUrl, posterUrl) || other.posterUrl == posterUrl)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&const DeepCollectionEquality().equals(other.genres, genres)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.media, media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,const DeepCollectionEquality().hash(id),title,type,year,overview,posterUrl,posterPath,backdropPath,tmdbId,const DeepCollectionEquality().hash(genres),rating,const DeepCollectionEquality().hash(media));

@override
String toString() {
  return 'SearchResultItem(source: $source, id: $id, title: $title, type: $type, year: $year, overview: $overview, posterUrl: $posterUrl, posterPath: $posterPath, backdropPath: $backdropPath, tmdbId: $tmdbId, genres: $genres, rating: $rating, media: $media)';
}


}

/// @nodoc
abstract mixin class $SearchResultItemCopyWith<$Res>  {
  factory $SearchResultItemCopyWith(SearchResultItem value, $Res Function(SearchResultItem) _then) = _$SearchResultItemCopyWithImpl;
@useResult
$Res call({
 String source, Object? id, String title, String type, int? year, String? overview, String? posterUrl, String? posterPath, String? backdropPath, String? tmdbId, List<dynamic> genres, double? rating, Object? media
});




}
/// @nodoc
class _$SearchResultItemCopyWithImpl<$Res>
    implements $SearchResultItemCopyWith<$Res> {
  _$SearchResultItemCopyWithImpl(this._self, this._then);

  final SearchResultItem _self;
  final $Res Function(SearchResultItem) _then;

/// Create a copy of SearchResultItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? id = freezed,Object? title = null,Object? type = null,Object? year = freezed,Object? overview = freezed,Object? posterUrl = freezed,Object? posterPath = freezed,Object? backdropPath = freezed,Object? tmdbId = freezed,Object? genres = null,Object? rating = freezed,Object? media = freezed,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id ,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,posterUrl: freezed == posterUrl ? _self.posterUrl : posterUrl // ignore: cast_nullable_to_non_nullable
as String?,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<dynamic>,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,media: freezed == media ? _self.media : media ,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchResultItem].
extension SearchResultItemPatterns on SearchResultItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResultItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResultItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResultItem value)  $default,){
final _that = this;
switch (_that) {
case _SearchResultItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResultItem value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResultItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String source,  Object? id,  String title,  String type,  int? year,  String? overview,  String? posterUrl,  String? posterPath,  String? backdropPath,  String? tmdbId,  List<dynamic> genres,  double? rating,  Object? media)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResultItem() when $default != null:
return $default(_that.source,_that.id,_that.title,_that.type,_that.year,_that.overview,_that.posterUrl,_that.posterPath,_that.backdropPath,_that.tmdbId,_that.genres,_that.rating,_that.media);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String source,  Object? id,  String title,  String type,  int? year,  String? overview,  String? posterUrl,  String? posterPath,  String? backdropPath,  String? tmdbId,  List<dynamic> genres,  double? rating,  Object? media)  $default,) {final _that = this;
switch (_that) {
case _SearchResultItem():
return $default(_that.source,_that.id,_that.title,_that.type,_that.year,_that.overview,_that.posterUrl,_that.posterPath,_that.backdropPath,_that.tmdbId,_that.genres,_that.rating,_that.media);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String source,  Object? id,  String title,  String type,  int? year,  String? overview,  String? posterUrl,  String? posterPath,  String? backdropPath,  String? tmdbId,  List<dynamic> genres,  double? rating,  Object? media)?  $default,) {final _that = this;
switch (_that) {
case _SearchResultItem() when $default != null:
return $default(_that.source,_that.id,_that.title,_that.type,_that.year,_that.overview,_that.posterUrl,_that.posterPath,_that.backdropPath,_that.tmdbId,_that.genres,_that.rating,_that.media);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchResultItem implements SearchResultItem {
  const _SearchResultItem({required this.source, this.id, required this.title, required this.type, this.year, this.overview, this.posterUrl, this.posterPath, this.backdropPath, this.tmdbId, final  List<dynamic> genres = const [], this.rating, this.media}): _genres = genres;
  factory _SearchResultItem.fromJson(Map<String, dynamic> json) => _$SearchResultItemFromJson(json);

@override final  String source;
@override final  Object? id;
@override final  String title;
@override final  String type;
@override final  int? year;
@override final  String? overview;
@override final  String? posterUrl;
@override final  String? posterPath;
@override final  String? backdropPath;
@override final  String? tmdbId;
 final  List<dynamic> _genres;
@override@JsonKey() List<dynamic> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

@override final  double? rating;
@override final  Object? media;

/// Create a copy of SearchResultItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultItemCopyWith<_SearchResultItem> get copyWith => __$SearchResultItemCopyWithImpl<_SearchResultItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchResultItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResultItem&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.id, id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.year, year) || other.year == year)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.posterUrl, posterUrl) || other.posterUrl == posterUrl)&&(identical(other.posterPath, posterPath) || other.posterPath == posterPath)&&(identical(other.backdropPath, backdropPath) || other.backdropPath == backdropPath)&&(identical(other.tmdbId, tmdbId) || other.tmdbId == tmdbId)&&const DeepCollectionEquality().equals(other._genres, _genres)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.media, media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,const DeepCollectionEquality().hash(id),title,type,year,overview,posterUrl,posterPath,backdropPath,tmdbId,const DeepCollectionEquality().hash(_genres),rating,const DeepCollectionEquality().hash(media));

@override
String toString() {
  return 'SearchResultItem(source: $source, id: $id, title: $title, type: $type, year: $year, overview: $overview, posterUrl: $posterUrl, posterPath: $posterPath, backdropPath: $backdropPath, tmdbId: $tmdbId, genres: $genres, rating: $rating, media: $media)';
}


}

/// @nodoc
abstract mixin class _$SearchResultItemCopyWith<$Res> implements $SearchResultItemCopyWith<$Res> {
  factory _$SearchResultItemCopyWith(_SearchResultItem value, $Res Function(_SearchResultItem) _then) = __$SearchResultItemCopyWithImpl;
@override @useResult
$Res call({
 String source, Object? id, String title, String type, int? year, String? overview, String? posterUrl, String? posterPath, String? backdropPath, String? tmdbId, List<dynamic> genres, double? rating, Object? media
});




}
/// @nodoc
class __$SearchResultItemCopyWithImpl<$Res>
    implements _$SearchResultItemCopyWith<$Res> {
  __$SearchResultItemCopyWithImpl(this._self, this._then);

  final _SearchResultItem _self;
  final $Res Function(_SearchResultItem) _then;

/// Create a copy of SearchResultItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? id = freezed,Object? title = null,Object? type = null,Object? year = freezed,Object? overview = freezed,Object? posterUrl = freezed,Object? posterPath = freezed,Object? backdropPath = freezed,Object? tmdbId = freezed,Object? genres = null,Object? rating = freezed,Object? media = freezed,}) {
  return _then(_SearchResultItem(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id ,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as String?,posterUrl: freezed == posterUrl ? _self.posterUrl : posterUrl // ignore: cast_nullable_to_non_nullable
as String?,posterPath: freezed == posterPath ? _self.posterPath : posterPath // ignore: cast_nullable_to_non_nullable
as String?,backdropPath: freezed == backdropPath ? _self.backdropPath : backdropPath // ignore: cast_nullable_to_non_nullable
as String?,tmdbId: freezed == tmdbId ? _self.tmdbId : tmdbId // ignore: cast_nullable_to_non_nullable
as String?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<dynamic>,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,media: freezed == media ? _self.media : media ,
  ));
}


}


/// @nodoc
mixin _$SearchSourceCounts {

 int get local; int get tmdb; int get trakt;
/// Create a copy of SearchSourceCounts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchSourceCountsCopyWith<SearchSourceCounts> get copyWith => _$SearchSourceCountsCopyWithImpl<SearchSourceCounts>(this as SearchSourceCounts, _$identity);

  /// Serializes this SearchSourceCounts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchSourceCounts&&(identical(other.local, local) || other.local == local)&&(identical(other.tmdb, tmdb) || other.tmdb == tmdb)&&(identical(other.trakt, trakt) || other.trakt == trakt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,local,tmdb,trakt);

@override
String toString() {
  return 'SearchSourceCounts(local: $local, tmdb: $tmdb, trakt: $trakt)';
}


}

/// @nodoc
abstract mixin class $SearchSourceCountsCopyWith<$Res>  {
  factory $SearchSourceCountsCopyWith(SearchSourceCounts value, $Res Function(SearchSourceCounts) _then) = _$SearchSourceCountsCopyWithImpl;
@useResult
$Res call({
 int local, int tmdb, int trakt
});




}
/// @nodoc
class _$SearchSourceCountsCopyWithImpl<$Res>
    implements $SearchSourceCountsCopyWith<$Res> {
  _$SearchSourceCountsCopyWithImpl(this._self, this._then);

  final SearchSourceCounts _self;
  final $Res Function(SearchSourceCounts) _then;

/// Create a copy of SearchSourceCounts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? local = null,Object? tmdb = null,Object? trakt = null,}) {
  return _then(_self.copyWith(
local: null == local ? _self.local : local // ignore: cast_nullable_to_non_nullable
as int,tmdb: null == tmdb ? _self.tmdb : tmdb // ignore: cast_nullable_to_non_nullable
as int,trakt: null == trakt ? _self.trakt : trakt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchSourceCounts].
extension SearchSourceCountsPatterns on SearchSourceCounts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchSourceCounts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchSourceCounts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchSourceCounts value)  $default,){
final _that = this;
switch (_that) {
case _SearchSourceCounts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchSourceCounts value)?  $default,){
final _that = this;
switch (_that) {
case _SearchSourceCounts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int local,  int tmdb,  int trakt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchSourceCounts() when $default != null:
return $default(_that.local,_that.tmdb,_that.trakt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int local,  int tmdb,  int trakt)  $default,) {final _that = this;
switch (_that) {
case _SearchSourceCounts():
return $default(_that.local,_that.tmdb,_that.trakt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int local,  int tmdb,  int trakt)?  $default,) {final _that = this;
switch (_that) {
case _SearchSourceCounts() when $default != null:
return $default(_that.local,_that.tmdb,_that.trakt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchSourceCounts implements SearchSourceCounts {
  const _SearchSourceCounts({required this.local, required this.tmdb, required this.trakt});
  factory _SearchSourceCounts.fromJson(Map<String, dynamic> json) => _$SearchSourceCountsFromJson(json);

@override final  int local;
@override final  int tmdb;
@override final  int trakt;

/// Create a copy of SearchSourceCounts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchSourceCountsCopyWith<_SearchSourceCounts> get copyWith => __$SearchSourceCountsCopyWithImpl<_SearchSourceCounts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchSourceCountsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchSourceCounts&&(identical(other.local, local) || other.local == local)&&(identical(other.tmdb, tmdb) || other.tmdb == tmdb)&&(identical(other.trakt, trakt) || other.trakt == trakt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,local,tmdb,trakt);

@override
String toString() {
  return 'SearchSourceCounts(local: $local, tmdb: $tmdb, trakt: $trakt)';
}


}

/// @nodoc
abstract mixin class _$SearchSourceCountsCopyWith<$Res> implements $SearchSourceCountsCopyWith<$Res> {
  factory _$SearchSourceCountsCopyWith(_SearchSourceCounts value, $Res Function(_SearchSourceCounts) _then) = __$SearchSourceCountsCopyWithImpl;
@override @useResult
$Res call({
 int local, int tmdb, int trakt
});




}
/// @nodoc
class __$SearchSourceCountsCopyWithImpl<$Res>
    implements _$SearchSourceCountsCopyWith<$Res> {
  __$SearchSourceCountsCopyWithImpl(this._self, this._then);

  final _SearchSourceCounts _self;
  final $Res Function(_SearchSourceCounts) _then;

/// Create a copy of SearchSourceCounts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? local = null,Object? tmdb = null,Object? trakt = null,}) {
  return _then(_SearchSourceCounts(
local: null == local ? _self.local : local // ignore: cast_nullable_to_non_nullable
as int,tmdb: null == tmdb ? _self.tmdb : tmdb // ignore: cast_nullable_to_non_nullable
as int,trakt: null == trakt ? _self.trakt : trakt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SearchResponse {

 String get query; List<SearchResultItem> get results; int get count; SearchSourceCounts get sources;
/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResponseCopyWith<SearchResponse> get copyWith => _$SearchResponseCopyWithImpl<SearchResponse>(this as SearchResponse, _$identity);

  /// Serializes this SearchResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResponse&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other.results, results)&&(identical(other.count, count) || other.count == count)&&(identical(other.sources, sources) || other.sources == sources));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(results),count,sources);

@override
String toString() {
  return 'SearchResponse(query: $query, results: $results, count: $count, sources: $sources)';
}


}

/// @nodoc
abstract mixin class $SearchResponseCopyWith<$Res>  {
  factory $SearchResponseCopyWith(SearchResponse value, $Res Function(SearchResponse) _then) = _$SearchResponseCopyWithImpl;
@useResult
$Res call({
 String query, List<SearchResultItem> results, int count, SearchSourceCounts sources
});


$SearchSourceCountsCopyWith<$Res> get sources;

}
/// @nodoc
class _$SearchResponseCopyWithImpl<$Res>
    implements $SearchResponseCopyWith<$Res> {
  _$SearchResponseCopyWithImpl(this._self, this._then);

  final SearchResponse _self;
  final $Res Function(SearchResponse) _then;

/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? results = null,Object? count = null,Object? sources = null,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<SearchResultItem>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as SearchSourceCounts,
  ));
}
/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchSourceCountsCopyWith<$Res> get sources {
  
  return $SearchSourceCountsCopyWith<$Res>(_self.sources, (value) {
    return _then(_self.copyWith(sources: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchResponse].
extension SearchResponsePatterns on SearchResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResponse value)  $default,){
final _that = this;
switch (_that) {
case _SearchResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  List<SearchResultItem> results,  int count,  SearchSourceCounts sources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResponse() when $default != null:
return $default(_that.query,_that.results,_that.count,_that.sources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  List<SearchResultItem> results,  int count,  SearchSourceCounts sources)  $default,) {final _that = this;
switch (_that) {
case _SearchResponse():
return $default(_that.query,_that.results,_that.count,_that.sources);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  List<SearchResultItem> results,  int count,  SearchSourceCounts sources)?  $default,) {final _that = this;
switch (_that) {
case _SearchResponse() when $default != null:
return $default(_that.query,_that.results,_that.count,_that.sources);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchResponse implements SearchResponse {
  const _SearchResponse({required this.query, required final  List<SearchResultItem> results, required this.count, required this.sources}): _results = results;
  factory _SearchResponse.fromJson(Map<String, dynamic> json) => _$SearchResponseFromJson(json);

@override final  String query;
 final  List<SearchResultItem> _results;
@override List<SearchResultItem> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override final  int count;
@override final  SearchSourceCounts sources;

/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResponseCopyWith<_SearchResponse> get copyWith => __$SearchResponseCopyWithImpl<_SearchResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResponse&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other._results, _results)&&(identical(other.count, count) || other.count == count)&&(identical(other.sources, sources) || other.sources == sources));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(_results),count,sources);

@override
String toString() {
  return 'SearchResponse(query: $query, results: $results, count: $count, sources: $sources)';
}


}

/// @nodoc
abstract mixin class _$SearchResponseCopyWith<$Res> implements $SearchResponseCopyWith<$Res> {
  factory _$SearchResponseCopyWith(_SearchResponse value, $Res Function(_SearchResponse) _then) = __$SearchResponseCopyWithImpl;
@override @useResult
$Res call({
 String query, List<SearchResultItem> results, int count, SearchSourceCounts sources
});


@override $SearchSourceCountsCopyWith<$Res> get sources;

}
/// @nodoc
class __$SearchResponseCopyWithImpl<$Res>
    implements _$SearchResponseCopyWith<$Res> {
  __$SearchResponseCopyWithImpl(this._self, this._then);

  final _SearchResponse _self;
  final $Res Function(_SearchResponse) _then;

/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? results = null,Object? count = null,Object? sources = null,}) {
  return _then(_SearchResponse(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<SearchResultItem>,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as SearchSourceCounts,
  ));
}

/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SearchSourceCountsCopyWith<$Res> get sources {
  
  return $SearchSourceCountsCopyWith<$Res>(_self.sources, (value) {
    return _then(_self.copyWith(sources: value));
  });
}
}


/// @nodoc
mixin _$WidgetConfig {

 String get provider; String get category; String get title; String? get source; Map<String, dynamic>? get params;
/// Create a copy of WidgetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WidgetConfigCopyWith<WidgetConfig> get copyWith => _$WidgetConfigCopyWithImpl<WidgetConfig>(this as WidgetConfig, _$identity);

  /// Serializes this WidgetConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WidgetConfig&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.category, category) || other.category == category)&&(identical(other.title, title) || other.title == title)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.params, params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,category,title,source,const DeepCollectionEquality().hash(params));

@override
String toString() {
  return 'WidgetConfig(provider: $provider, category: $category, title: $title, source: $source, params: $params)';
}


}

/// @nodoc
abstract mixin class $WidgetConfigCopyWith<$Res>  {
  factory $WidgetConfigCopyWith(WidgetConfig value, $Res Function(WidgetConfig) _then) = _$WidgetConfigCopyWithImpl;
@useResult
$Res call({
 String provider, String category, String title, String? source, Map<String, dynamic>? params
});




}
/// @nodoc
class _$WidgetConfigCopyWithImpl<$Res>
    implements $WidgetConfigCopyWith<$Res> {
  _$WidgetConfigCopyWithImpl(this._self, this._then);

  final WidgetConfig _self;
  final $Res Function(WidgetConfig) _then;

/// Create a copy of WidgetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? category = null,Object? title = null,Object? source = freezed,Object? params = freezed,}) {
  return _then(_self.copyWith(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,params: freezed == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [WidgetConfig].
extension WidgetConfigPatterns on WidgetConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WidgetConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WidgetConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WidgetConfig value)  $default,){
final _that = this;
switch (_that) {
case _WidgetConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WidgetConfig value)?  $default,){
final _that = this;
switch (_that) {
case _WidgetConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String provider,  String category,  String title,  String? source,  Map<String, dynamic>? params)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WidgetConfig() when $default != null:
return $default(_that.provider,_that.category,_that.title,_that.source,_that.params);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String provider,  String category,  String title,  String? source,  Map<String, dynamic>? params)  $default,) {final _that = this;
switch (_that) {
case _WidgetConfig():
return $default(_that.provider,_that.category,_that.title,_that.source,_that.params);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String provider,  String category,  String title,  String? source,  Map<String, dynamic>? params)?  $default,) {final _that = this;
switch (_that) {
case _WidgetConfig() when $default != null:
return $default(_that.provider,_that.category,_that.title,_that.source,_that.params);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WidgetConfig implements WidgetConfig {
  const _WidgetConfig({required this.provider, required this.category, required this.title, this.source, final  Map<String, dynamic>? params}): _params = params;
  factory _WidgetConfig.fromJson(Map<String, dynamic> json) => _$WidgetConfigFromJson(json);

@override final  String provider;
@override final  String category;
@override final  String title;
@override final  String? source;
 final  Map<String, dynamic>? _params;
@override Map<String, dynamic>? get params {
  final value = _params;
  if (value == null) return null;
  if (_params is EqualUnmodifiableMapView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of WidgetConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WidgetConfigCopyWith<_WidgetConfig> get copyWith => __$WidgetConfigCopyWithImpl<_WidgetConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WidgetConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WidgetConfig&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.category, category) || other.category == category)&&(identical(other.title, title) || other.title == title)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other._params, _params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,category,title,source,const DeepCollectionEquality().hash(_params));

@override
String toString() {
  return 'WidgetConfig(provider: $provider, category: $category, title: $title, source: $source, params: $params)';
}


}

/// @nodoc
abstract mixin class _$WidgetConfigCopyWith<$Res> implements $WidgetConfigCopyWith<$Res> {
  factory _$WidgetConfigCopyWith(_WidgetConfig value, $Res Function(_WidgetConfig) _then) = __$WidgetConfigCopyWithImpl;
@override @useResult
$Res call({
 String provider, String category, String title, String? source, Map<String, dynamic>? params
});




}
/// @nodoc
class __$WidgetConfigCopyWithImpl<$Res>
    implements _$WidgetConfigCopyWith<$Res> {
  __$WidgetConfigCopyWithImpl(this._self, this._then);

  final _WidgetConfig _self;
  final $Res Function(_WidgetConfig) _then;

/// Create a copy of WidgetConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? category = null,Object? title = null,Object? source = freezed,Object? params = freezed,}) {
  return _then(_WidgetConfig(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,params: freezed == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$WidgetsConfigResponse {

 List<WidgetConfig> get movies; List<WidgetConfig> get shows; int get minWidgets; int get maxWidgets;
/// Create a copy of WidgetsConfigResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WidgetsConfigResponseCopyWith<WidgetsConfigResponse> get copyWith => _$WidgetsConfigResponseCopyWithImpl<WidgetsConfigResponse>(this as WidgetsConfigResponse, _$identity);

  /// Serializes this WidgetsConfigResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WidgetsConfigResponse&&const DeepCollectionEquality().equals(other.movies, movies)&&const DeepCollectionEquality().equals(other.shows, shows)&&(identical(other.minWidgets, minWidgets) || other.minWidgets == minWidgets)&&(identical(other.maxWidgets, maxWidgets) || other.maxWidgets == maxWidgets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(movies),const DeepCollectionEquality().hash(shows),minWidgets,maxWidgets);

@override
String toString() {
  return 'WidgetsConfigResponse(movies: $movies, shows: $shows, minWidgets: $minWidgets, maxWidgets: $maxWidgets)';
}


}

/// @nodoc
abstract mixin class $WidgetsConfigResponseCopyWith<$Res>  {
  factory $WidgetsConfigResponseCopyWith(WidgetsConfigResponse value, $Res Function(WidgetsConfigResponse) _then) = _$WidgetsConfigResponseCopyWithImpl;
@useResult
$Res call({
 List<WidgetConfig> movies, List<WidgetConfig> shows, int minWidgets, int maxWidgets
});




}
/// @nodoc
class _$WidgetsConfigResponseCopyWithImpl<$Res>
    implements $WidgetsConfigResponseCopyWith<$Res> {
  _$WidgetsConfigResponseCopyWithImpl(this._self, this._then);

  final WidgetsConfigResponse _self;
  final $Res Function(WidgetsConfigResponse) _then;

/// Create a copy of WidgetsConfigResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? movies = null,Object? shows = null,Object? minWidgets = null,Object? maxWidgets = null,}) {
  return _then(_self.copyWith(
movies: null == movies ? _self.movies : movies // ignore: cast_nullable_to_non_nullable
as List<WidgetConfig>,shows: null == shows ? _self.shows : shows // ignore: cast_nullable_to_non_nullable
as List<WidgetConfig>,minWidgets: null == minWidgets ? _self.minWidgets : minWidgets // ignore: cast_nullable_to_non_nullable
as int,maxWidgets: null == maxWidgets ? _self.maxWidgets : maxWidgets // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WidgetsConfigResponse].
extension WidgetsConfigResponsePatterns on WidgetsConfigResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WidgetsConfigResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WidgetsConfigResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WidgetsConfigResponse value)  $default,){
final _that = this;
switch (_that) {
case _WidgetsConfigResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WidgetsConfigResponse value)?  $default,){
final _that = this;
switch (_that) {
case _WidgetsConfigResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<WidgetConfig> movies,  List<WidgetConfig> shows,  int minWidgets,  int maxWidgets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WidgetsConfigResponse() when $default != null:
return $default(_that.movies,_that.shows,_that.minWidgets,_that.maxWidgets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<WidgetConfig> movies,  List<WidgetConfig> shows,  int minWidgets,  int maxWidgets)  $default,) {final _that = this;
switch (_that) {
case _WidgetsConfigResponse():
return $default(_that.movies,_that.shows,_that.minWidgets,_that.maxWidgets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<WidgetConfig> movies,  List<WidgetConfig> shows,  int minWidgets,  int maxWidgets)?  $default,) {final _that = this;
switch (_that) {
case _WidgetsConfigResponse() when $default != null:
return $default(_that.movies,_that.shows,_that.minWidgets,_that.maxWidgets);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WidgetsConfigResponse implements WidgetsConfigResponse {
  const _WidgetsConfigResponse({required final  List<WidgetConfig> movies, required final  List<WidgetConfig> shows, this.minWidgets = 1, this.maxWidgets = 10}): _movies = movies,_shows = shows;
  factory _WidgetsConfigResponse.fromJson(Map<String, dynamic> json) => _$WidgetsConfigResponseFromJson(json);

 final  List<WidgetConfig> _movies;
@override List<WidgetConfig> get movies {
  if (_movies is EqualUnmodifiableListView) return _movies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_movies);
}

 final  List<WidgetConfig> _shows;
@override List<WidgetConfig> get shows {
  if (_shows is EqualUnmodifiableListView) return _shows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shows);
}

@override@JsonKey() final  int minWidgets;
@override@JsonKey() final  int maxWidgets;

/// Create a copy of WidgetsConfigResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WidgetsConfigResponseCopyWith<_WidgetsConfigResponse> get copyWith => __$WidgetsConfigResponseCopyWithImpl<_WidgetsConfigResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WidgetsConfigResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WidgetsConfigResponse&&const DeepCollectionEquality().equals(other._movies, _movies)&&const DeepCollectionEquality().equals(other._shows, _shows)&&(identical(other.minWidgets, minWidgets) || other.minWidgets == minWidgets)&&(identical(other.maxWidgets, maxWidgets) || other.maxWidgets == maxWidgets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_movies),const DeepCollectionEquality().hash(_shows),minWidgets,maxWidgets);

@override
String toString() {
  return 'WidgetsConfigResponse(movies: $movies, shows: $shows, minWidgets: $minWidgets, maxWidgets: $maxWidgets)';
}


}

/// @nodoc
abstract mixin class _$WidgetsConfigResponseCopyWith<$Res> implements $WidgetsConfigResponseCopyWith<$Res> {
  factory _$WidgetsConfigResponseCopyWith(_WidgetsConfigResponse value, $Res Function(_WidgetsConfigResponse) _then) = __$WidgetsConfigResponseCopyWithImpl;
@override @useResult
$Res call({
 List<WidgetConfig> movies, List<WidgetConfig> shows, int minWidgets, int maxWidgets
});




}
/// @nodoc
class __$WidgetsConfigResponseCopyWithImpl<$Res>
    implements _$WidgetsConfigResponseCopyWith<$Res> {
  __$WidgetsConfigResponseCopyWithImpl(this._self, this._then);

  final _WidgetsConfigResponse _self;
  final $Res Function(_WidgetsConfigResponse) _then;

/// Create a copy of WidgetsConfigResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? movies = null,Object? shows = null,Object? minWidgets = null,Object? maxWidgets = null,}) {
  return _then(_WidgetsConfigResponse(
movies: null == movies ? _self._movies : movies // ignore: cast_nullable_to_non_nullable
as List<WidgetConfig>,shows: null == shows ? _self._shows : shows // ignore: cast_nullable_to_non_nullable
as List<WidgetConfig>,minWidgets: null == minWidgets ? _self.minWidgets : minWidgets // ignore: cast_nullable_to_non_nullable
as int,maxWidgets: null == maxWidgets ? _self.maxWidgets : maxWidgets // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SaveWidgetsResponse {

 String get message; int get moviesCount; int get showsCount;
/// Create a copy of SaveWidgetsResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveWidgetsResponseCopyWith<SaveWidgetsResponse> get copyWith => _$SaveWidgetsResponseCopyWithImpl<SaveWidgetsResponse>(this as SaveWidgetsResponse, _$identity);

  /// Serializes this SaveWidgetsResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveWidgetsResponse&&(identical(other.message, message) || other.message == message)&&(identical(other.moviesCount, moviesCount) || other.moviesCount == moviesCount)&&(identical(other.showsCount, showsCount) || other.showsCount == showsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,moviesCount,showsCount);

@override
String toString() {
  return 'SaveWidgetsResponse(message: $message, moviesCount: $moviesCount, showsCount: $showsCount)';
}


}

/// @nodoc
abstract mixin class $SaveWidgetsResponseCopyWith<$Res>  {
  factory $SaveWidgetsResponseCopyWith(SaveWidgetsResponse value, $Res Function(SaveWidgetsResponse) _then) = _$SaveWidgetsResponseCopyWithImpl;
@useResult
$Res call({
 String message, int moviesCount, int showsCount
});




}
/// @nodoc
class _$SaveWidgetsResponseCopyWithImpl<$Res>
    implements $SaveWidgetsResponseCopyWith<$Res> {
  _$SaveWidgetsResponseCopyWithImpl(this._self, this._then);

  final SaveWidgetsResponse _self;
  final $Res Function(SaveWidgetsResponse) _then;

/// Create a copy of SaveWidgetsResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? moviesCount = null,Object? showsCount = null,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,moviesCount: null == moviesCount ? _self.moviesCount : moviesCount // ignore: cast_nullable_to_non_nullable
as int,showsCount: null == showsCount ? _self.showsCount : showsCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SaveWidgetsResponse].
extension SaveWidgetsResponsePatterns on SaveWidgetsResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SaveWidgetsResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SaveWidgetsResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SaveWidgetsResponse value)  $default,){
final _that = this;
switch (_that) {
case _SaveWidgetsResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SaveWidgetsResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SaveWidgetsResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String message,  int moviesCount,  int showsCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SaveWidgetsResponse() when $default != null:
return $default(_that.message,_that.moviesCount,_that.showsCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String message,  int moviesCount,  int showsCount)  $default,) {final _that = this;
switch (_that) {
case _SaveWidgetsResponse():
return $default(_that.message,_that.moviesCount,_that.showsCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String message,  int moviesCount,  int showsCount)?  $default,) {final _that = this;
switch (_that) {
case _SaveWidgetsResponse() when $default != null:
return $default(_that.message,_that.moviesCount,_that.showsCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SaveWidgetsResponse implements SaveWidgetsResponse {
  const _SaveWidgetsResponse({required this.message, required this.moviesCount, required this.showsCount});
  factory _SaveWidgetsResponse.fromJson(Map<String, dynamic> json) => _$SaveWidgetsResponseFromJson(json);

@override final  String message;
@override final  int moviesCount;
@override final  int showsCount;

/// Create a copy of SaveWidgetsResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SaveWidgetsResponseCopyWith<_SaveWidgetsResponse> get copyWith => __$SaveWidgetsResponseCopyWithImpl<_SaveWidgetsResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SaveWidgetsResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaveWidgetsResponse&&(identical(other.message, message) || other.message == message)&&(identical(other.moviesCount, moviesCount) || other.moviesCount == moviesCount)&&(identical(other.showsCount, showsCount) || other.showsCount == showsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,moviesCount,showsCount);

@override
String toString() {
  return 'SaveWidgetsResponse(message: $message, moviesCount: $moviesCount, showsCount: $showsCount)';
}


}

/// @nodoc
abstract mixin class _$SaveWidgetsResponseCopyWith<$Res> implements $SaveWidgetsResponseCopyWith<$Res> {
  factory _$SaveWidgetsResponseCopyWith(_SaveWidgetsResponse value, $Res Function(_SaveWidgetsResponse) _then) = __$SaveWidgetsResponseCopyWithImpl;
@override @useResult
$Res call({
 String message, int moviesCount, int showsCount
});




}
/// @nodoc
class __$SaveWidgetsResponseCopyWithImpl<$Res>
    implements _$SaveWidgetsResponseCopyWith<$Res> {
  __$SaveWidgetsResponseCopyWithImpl(this._self, this._then);

  final _SaveWidgetsResponse _self;
  final $Res Function(_SaveWidgetsResponse) _then;

/// Create a copy of SaveWidgetsResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? moviesCount = null,Object? showsCount = null,}) {
  return _then(_SaveWidgetsResponse(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,moviesCount: null == moviesCount ? _self.moviesCount : moviesCount // ignore: cast_nullable_to_non_nullable
as int,showsCount: null == showsCount ? _self.showsCount : showsCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
