// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatalogResponse _$CatalogResponseFromJson(Map<String, dynamic> json) =>
    _CatalogResponse(
      category: json['category'] as String,
      mediaType: json['media_type'] as String,
      page: (json['page'] as num?)?.toInt(),
      period: json['period'] as String?,
      limit: (json['limit'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$CatalogResponseToJson(_CatalogResponse instance) =>
    <String, dynamic>{
      'category': instance.category,
      'media_type': instance.mediaType,
      'page': instance.page,
      'period': instance.period,
      'limit': instance.limit,
      'offset': instance.offset,
      'total': instance.total,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'count': instance.count,
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
    );

Map<String, dynamic> _$WidgetConfigToJson(_WidgetConfig instance) =>
    <String, dynamic>{
      'provider': instance.provider,
      'category': instance.category,
      'title': instance.title,
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
);

Map<String, dynamic> _$WidgetsConfigResponseToJson(
  _WidgetsConfigResponse instance,
) => <String, dynamic>{
  'movies': instance.movies.map((e) => e.toJson()).toList(),
  'shows': instance.shows.map((e) => e.toJson()).toList(),
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
