import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../api/api_client.dart';
import '../models/auth.dart';
import '../models/debrid.dart';

part 'settings_provider.g.dart';

@riverpod
Future<ProvidersResponse> providersStatus(Ref ref) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>('/api/v1/settings/providers');
  return ProvidersResponse.fromJson(raw);
}

@riverpod
Future<AuthStatus> traktAuthStatus(Ref ref) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>('/api/v1/trakt/auth/status');
  return AuthStatus.fromJson(raw);
}

@riverpod
Future<AuthStatus> debridAuthStatus(Ref ref) async {
  final client = ref.watch(apiClientProvider);
  final raw = await client.get<Map<String, dynamic>>('/api/v1/debrid/auth/status');
  return AuthStatus.fromJson(raw);
}

@riverpod
Future<TraktUserProfile?> traktAccount(Ref ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final raw = await client.get<Map<String, dynamic>>('/api/v1/trakt/account');
    return TraktUserProfile.fromJson(raw);
  } catch (_) {
    return null;
  }
}

@riverpod
Future<DebridAccountInfo?> debridAccount(Ref ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final raw = await client.get<Map<String, dynamic>>('/api/v1/debrid/account');
    return DebridAccountInfo.fromJson(raw);
  } catch (_) {
    return null;
  }
}
