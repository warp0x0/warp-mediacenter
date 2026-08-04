// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatalogResponse _$CatalogResponseFromJson(Map<String, dynamic> json) =>
    _CatalogResponse(
      category: json['category'] as String,
      mediaType: json['media_type'] as String,
      source: json['source'] as String?,
      listId: json['list_id'] as String?,
      page: (json['page'] as num?)?.toInt(),
      period: json['period'] as String?,
      limit: (json['limit'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      hasMore: json['has_more'] as bool?,
      items: (json['items'] as List<dynamic>)
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$CatalogResponseToJson(_CatalogResponse instance) =>
    <String, dynamic>{
      'category': instance.category,
      'media_type': instance.mediaType,
      'source': instance.source,
      'list_id': instance.listId,
      'page': instance.page,
      'period': instance.period,
      'limit': instance.limit,
      'offset': instance.offset,
      'total': instance.total,
      'has_more': instance.hasMore,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'count': instance.count,
    };

_CatalogListDef _$CatalogListDefFromJson(Map<String, dynamic> json) =>
    _CatalogListDef(
      id: json['id'] as String,
      title: json['title'] as String,
      mediaTypes:
          (json['media_types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['movie', 'show'],
      group: json['group'] as String? ?? 'other',
      description: json['description'] as String?,
      supportsPagination: json['supports_pagination'] as bool? ?? false,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      params: json['params'] as Map<String, dynamic>?,
      sortHint: json['sort_hint'] as String?,
    );

Map<String, dynamic> _$CatalogListDefToJson(_CatalogListDef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'media_types': instance.mediaTypes,
      'group': instance.group,
      'description': instance.description,
      'supports_pagination': instance.supportsPagination,
      'page_size': instance.pageSize,
      'params': instance.params,
      'sort_hint': instance.sortHint,
    };

_CatalogSourceDef _$CatalogSourceDefFromJson(Map<String, dynamic> json) =>
    _CatalogSourceDef(
      id: json['id'] as String,
      label: json['label'] as String,
      kind: json['kind'] as String? ?? 'builtin',
      icon: json['icon'] as String?,
      lists:
          (json['lists'] as List<dynamic>?)
              ?.map((e) => CatalogListDef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CatalogSourceDefToJson(_CatalogSourceDef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'kind': instance.kind,
      'icon': instance.icon,
      'lists': instance.lists.map((e) => e.toJson()).toList(),
    };

_CatalogDefinitions _$CatalogDefinitionsFromJson(Map<String, dynamic> json) =>
    _CatalogDefinitions(
      sources:
          (json['sources'] as List<dynamic>?)
              ?.map((e) => CatalogSourceDef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CatalogDefinitionsToJson(_CatalogDefinitions instance) =>
    <String, dynamic>{
      'sources': instance.sources.map((e) => e.toJson()).toList(),
    };

_SearchResultItem _$SearchResultItemFromJson(Map<String, dynamic> json) =>
    _SearchResultItem(
      source: json['source'] as String,
      id: json['id'],
      title: json['title'] as String,
      type: json['type'] as String,
      year: (json['year'] as num?)?.toInt(),
      overview: json['overview'] as String?,
      posterUrl: json['poster_url'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      tmdbId: json['tmdb_id'] as String?,
      genres: json['genres'] as List<dynamic>? ?? const [],
      rating: (json['rating'] as num?)?.toDouble(),
      media: json['media'],
    );

Map<String, dynamic> _$SearchResultItemToJson(_SearchResultItem instance) =>
    <String, dynamic>{
      'source': instance.source,
      'id': instance.id,
      'title': instance.title,
      'type': instance.type,
      'year': instance.year,
      'overview': instance.overview,
      'poster_url': instance.posterUrl,
      'poster_path': instance.posterPath,
      'backdrop_path': instance.backdropPath,
      'tmdb_id': instance.tmdbId,
      'genres': instance.genres,
      'rating': instance.rating,
      'media': instance.media,
    };

_SearchSourceCounts _$SearchSourceCountsFromJson(Map<String, dynamic> json) =>
    _SearchSourceCounts(
      local: (json['local'] as num).toInt(),
      tmdb: (json['tmdb'] as num).toInt(),
      trakt: (json['trakt'] as num).toInt(),
    );

Map<String, dynamic> _$SearchSourceCountsToJson(_SearchSourceCounts instance) =>
    <String, dynamic>{
      'local': instance.local,
      'tmdb': instance.tmdb,
      'trakt': instance.trakt,
    };

_SearchResponse _$SearchResponseFromJson(Map<String, dynamic> json) =>
    _SearchResponse(
      query: json['query'] as String,
      results: (json['results'] as List<dynamic>)
          .map((e) => SearchResultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
      sources: SearchSourceCounts.fromJson(
        json['sources'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SearchResponseToJson(_SearchResponse instance) =>
    <String, dynamic>{
      'query': instance.query,
      'results': instance.results.map((e) => e.toJson()).toList(),
      'count': instance.count,
      'sources': instance.sources.toJson(),
    };

_WidgetConfig _$WidgetConfigFromJson(Map<String, dynamic> json) =>
    _WidgetConfig(
      provider: json['provider'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      source: json['source'] as String?,
      params: json['params'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$WidgetConfigToJson(_WidgetConfig instance) =>
    <String, dynamic>{
      'provider': instance.provider,
      'category': instance.category,
      'title': instance.title,
      'source': instance.source,
      'params': instance.params,
    };

_WidgetsConfigResponse _$WidgetsConfigResponseFromJson(
  Map<String, dynamic> json,
) => _WidgetsConfigResponse(
  movies: (json['movies'] as List<dynamic>)
      .map((e) => WidgetConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
  shows: (json['shows'] as List<dynamic>)
      .map((e) => WidgetConfig.fromJson(e as Map<String, dynamic>))
      .toList(),
  minWidgets: (json['min_widgets'] as num?)?.toInt() ?? 1,
  maxWidgets: (json['max_widgets'] as num?)?.toInt() ?? 10,
);

Map<String, dynamic> _$WidgetsConfigResponseToJson(
  _WidgetsConfigResponse instance,
) => <String, dynamic>{
  'movies': instance.movies.map((e) => e.toJson()).toList(),
  'shows': instance.shows.map((e) => e.toJson()).toList(),
  'min_widgets': instance.minWidgets,
  'max_widgets': instance.maxWidgets,
};

_SaveWidgetsResponse _$SaveWidgetsResponseFromJson(Map<String, dynamic> json) =>
    _SaveWidgetsResponse(
      message: json['message'] as String,
      moviesCount: (json['movies_count'] as num).toInt(),
      showsCount: (json['shows_count'] as num).toInt(),
    );

Map<String, dynamic> _$SaveWidgetsResponseToJson(
  _SaveWidgetsResponse instance,
) => <String, dynamic>{
  'message': instance.message,
  'movies_count': instance.moviesCount,
  'shows_count': instance.showsCount,
};
