import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../api/api_client.dart';
import '../models/catalog.dart';

part 'catalog_provider.g.dart';

@riverpod
Future<CatalogResponse> catalogData(
  Ref ref, {
  required String provider,
  required String category,
  required String mediaType,
}) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>(
    '/api/v1/catalog/$provider/$category',
    params: {'media_type': mediaType, 'limit': 40},
  );
  return CatalogResponse.fromJson(raw);
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
