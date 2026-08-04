import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../api/api_client.dart';
import '../models/catalog.dart';

part 'catalog_provider.g.dart';

/// Items a home row loads up front.
///
/// Deep pagination happens on the browse grid ("See More"), which asks for
/// [kCatalogLoadMoreSize] at a time; a row only ever needs enough to fill the
/// visible ribbon plus a little scroll.
const kCatalogRowSize = 40;

/// Items each "Load More" press adds on the browse grid.
const kCatalogLoadMoreSize = 20;

/// Build the fetch path for a configured row.
///
/// Sources published by the catalog registry go through the canonical
/// `/source/{id}/{list}` route. The older `/{provider}/{category}` aliases still
/// exist and still work, but they only cover `tmdb` and `trakt` — a plugin's
/// lists are only reachable through the canonical path.
String catalogPath({required String source, required String listId}) =>
    '/api/v1/catalog/source/$source/$listId';

@riverpod
Future<CatalogResponse> catalogData(
  Ref ref, {
  required String provider,
  required String category,
  required String mediaType,
  String? source,
  Map<String, dynamic>? params,
}) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>(
    catalogPath(source: source ?? provider, listId: category),
    params: {
      'media_type': mediaType,
      'limit': kCatalogRowSize,
      if (params != null && params.isNotEmpty) 'params': jsonEncode(params),
    },
  );
  return CatalogResponse.fromJson(raw);
}

/// Every catalog source and the lists it publishes.
///
/// This is what makes the Settings picker plugin-aware: installing a catalog
/// plugin changes this response, and the picker rebuilds from it with no
/// client-side change. Invalidated whenever the plugin set moves — see
/// `pluginActionsProvider`.
@riverpod
Future<CatalogDefinitions> catalogDefinitions(Ref ref) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>(
    '/api/v1/catalog/definitions',
  );
  return CatalogDefinitions.fromJson(raw);
}

@riverpod
Future<WidgetsConfigResponse> widgetsConfig(Ref ref) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>('/api/v1/settings/widgets');
  return WidgetsConfigResponse.fromJson(raw);
}

Future<SaveWidgetsResponse> saveWidgets(
  ApiClient client,
  List<WidgetConfig> movies,
  List<WidgetConfig> shows,
) async {
  final raw = await client.put<Map<String, dynamic>>(
    '/api/v1/settings/widgets',
    body: {
      'movies': movies.map((w) => w.toJson()).toList(),
      'shows':  shows.map((w) => w.toJson()).toList(),
    },
  );
  return SaveWidgetsResponse.fromJson(raw);
}
