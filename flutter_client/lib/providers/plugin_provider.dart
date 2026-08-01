import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_client.dart';
import '../models/plugin.dart';
import 'catalog_provider.dart';
import 'settings_provider.dart';

part 'plugin_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Plugin providers — /api/v1/plugins/*
// ─────────────────────────────────────────────────────────────────────────────

/// Every category and what is installed in it.  Drives the Plugins panel and
/// the dynamic sidebar in one request.
@riverpod
Future<List<PluginCategory>> pluginCategories(Ref ref) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>('/api/v1/plugins/categories');
  return PluginCategoriesResponse.fromJson(raw).categories;
}

/// Installed plugins that contribute a settings page, flattened across
/// categories in the order the backend lists them.
@riverpod
Future<List<PluginSummary>> configurablePlugins(Ref ref) async {
  final categories = await ref.watch(pluginCategoriesProvider.future);
  return [
    for (final category in categories)
      for (final plugin in category.installed)
        if (plugin.hasSettings) plugin,
  ];
}

@riverpod
Future<PluginSettingsSchema> pluginSettingsSchema(Ref ref, String pluginId) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>(
    '/api/v1/plugins/$pluginId/settings-schema',
  );
  return PluginSettingsSchema.fromJson(raw);
}

@riverpod
Future<PluginAuthState> pluginAuthStatus(Ref ref, String pluginId) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>(
    '/api/v1/plugins/$pluginId/auth/status',
  );
  return PluginAuthState.fromJson(raw);
}

// ─────────────────────────────────────────────────────────────────────────────
// Mutations
//
// Anything that changes which tracker is active also invalidates the catalog
// providers: Continue Watching comes from the active tracker, so leaving a stale
// row on screen would show one service's progress under another's name.
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _refreshPluginSurfaces(Ref ref) async {
  ref.invalidate(pluginCategoriesProvider);
  ref.invalidate(configurablePluginsProvider);
  ref.invalidate(providersStatusProvider);
  ref.invalidate(catalogDataProvider);
}

class PluginActions {
  final Ref _ref;
  const PluginActions(this._ref);

  ApiClient get _client => _ref.read(apiClientProvider);

  Future<PluginSummary> install(String sourcePath) async {
    final raw = await _client.post<Map<String, dynamic>>(
      '/api/v1/plugins/install',
      body: {'source': sourcePath},
    );
    await _refreshPluginSurfaces(_ref);
    return PluginSummary.fromJson(
      (raw['plugin'] as Map).cast<String, dynamic>(),
    );
  }

  Future<void> uninstall(String pluginId, {bool force = false}) async {
    await _client.delete(
      '/api/v1/plugins/$pluginId${force ? '?force=true' : ''}',
    );
    await _refreshPluginSurfaces(_ref);
  }

  Future<void> setEnabled(String pluginId, bool enabled) async {
    await _client.post<Map<String, dynamic>>(
      '/api/v1/plugins/$pluginId/${enabled ? 'enable' : 'disable'}',
    );
    await _refreshPluginSurfaces(_ref);
  }

  /// Select the active plugin for an exclusive category, or `null` for none.
  Future<void> setActive(String category, String? pluginId) async {
    await _client.put<Map<String, dynamic>>(
      '/api/v1/plugins/categories/$category/active',
      body: {'plugin_id': pluginId},
    );
    await _refreshPluginSurfaces(_ref);
  }

  Future<void> saveSettings(String pluginId, Map<String, Object?> values) async {
    await _client.put<Map<String, dynamic>>(
      '/api/v1/plugins/$pluginId/settings',
      body: {'values': values},
    );
    _ref.invalidate(pluginSettingsSchemaProvider(pluginId));
  }

  Future<void> runAction(String pluginId, String actionId) async {
    await _client.post<Map<String, dynamic>>(
      '/api/v1/plugins/$pluginId/actions/$actionId',
    );
    _ref.invalidate(pluginSettingsSchemaProvider(pluginId));
    // An action button can change watch state (clearing a cache, resetting
    // history), so refresh the rows that render it.
    _ref.invalidate(catalogDataProvider);
  }

  Future<Map<String, dynamic>> authStart(String pluginId) async {
    return _client.post<Map<String, dynamic>>(
      '/api/v1/plugins/$pluginId/auth/start',
    );
  }

  Future<PluginAuthState> authPoll(String pluginId) async {
    final raw = await _client.post<Map<String, dynamic>>(
      '/api/v1/plugins/$pluginId/auth/poll',
    );
    return PluginAuthState.fromJson(raw);
  }

  Future<void> authClear(String pluginId) async {
    await _client.post<Map<String, dynamic>>(
      '/api/v1/plugins/$pluginId/auth/clear',
    );
    _ref.invalidate(pluginAuthStatusProvider(pluginId));
    _ref.invalidate(pluginSettingsSchemaProvider(pluginId));
    await _refreshPluginSurfaces(_ref);
  }
}

// keepAlive: this is only ever `ref.read()` to invoke a method, never
// `ref.watch()`ed by a widget — so nothing would otherwise keep it alive, and
// the default autoDispose behavior tears it down (and the internal `ref` it
// handed to PluginActions along with it) while an in-flight action is still
// awaiting its HTTP call, so the post-request `ref.invalidate(...)` calls
// throw against an already-disposed ref.
@Riverpod(keepAlive: true)
PluginActions pluginActions(Ref ref) => PluginActions(ref);
