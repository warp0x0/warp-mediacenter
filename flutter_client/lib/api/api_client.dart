import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ApiClient — Dio-backed HTTP client
//
// Mirrors src/lib/api.ts:
//   apiGet()    → client.get()
//   apiPost()   → client.post()
//   apiPut()    → client.put()
//   apiDelete() → client.delete()
//
// Base URL is configurable from Settings (persisted to SharedPreferences).
// Default: http://localhost:8000
// ─────────────────────────────────────────────────────────────────────────────

const _kBaseUrlKey = 'api_base_url';
const _kDefaultBaseUrl = 'http://localhost:8000';

class ApiClient {
  late final Dio _dio;

  ApiClient(String baseUrl) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _ErrorInterceptor(),
      LogInterceptor(requestBody: false, responseBody: false, error: true),
    ]);
  }

  Dio get dio => _dio;

  // ── REST helpers — mirror api.ts ───────────────────────────────────────────

  Future<T> get<T>(String path, {Map<String, dynamic>? params}) async {
    final resp = await _dio.get<T>(path, queryParameters: params);
    return resp.data as T;
  }

  Future<T> post<T>(String path, {Object? body, Options? options}) async {
    final resp = await _dio.post<T>(path, data: body, options: options);
    return resp.data as T;
  }

  Future<T> put<T>(String path, {Object? body}) async {
    final resp = await _dio.put<T>(path, data: body);
    return resp.data as T;
  }

  Future<void> delete(String path, {Map<String, dynamic>? params}) async {
    await _dio.delete(path, queryParameters: params);
  }

  // ── SSE streaming ─────────────────────────────────────────────────────────
  //
  // Provides a reconnecting SSE stream. On disconnect, retries after 2s.
  // Usage:
  //   client.sseStream('/api/v1/player/status/events').listen((data) {
  //     final status = PlayerStatus.fromJson(jsonDecode(data));
  //   });

  Stream<String> sseStream(String path) async* {
    while (true) {
      try {
        final resp = await _dio.get<ResponseBody>(
          path,
          options: Options(
            responseType: ResponseType.stream,
            receiveTimeout: const Duration(days: 1),
            headers: {'Accept': 'text/event-stream'},
          ),
        );

        final stream = resp.data!.stream;
        StringBuffer buffer = StringBuffer();

        await for (final chunk in stream) {
          buffer.write(utf8.decode(chunk));
          final text = buffer.toString();
          final lines = text.split('\n');

          // Keep last partial line in buffer
          buffer.clear();
          buffer.write(lines.last);

          for (var i = 0; i < lines.length - 1; i++) {
            final line = lines[i].trim();
            if (line.startsWith('data: ')) {
              yield line.substring(6);
            }
          }
        }
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          return; // cancelled intentionally
        }
        // Network error — reconnect after backoff
        await Future.delayed(const Duration(seconds: 2));
      } catch (_) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ApiError — mirrors src/lib/api.ts ApiError class
// ─────────────────────────────────────────────────────────────────────────────

class ApiError implements Exception {
  final int statusCode;
  final String message;

  const ApiError(this.statusCode, this.message);

  @override
  String toString() => 'ApiError($statusCode): $message';

  bool get isNotFound => statusCode == 404;
  bool get isUnauthorized => statusCode == 401;
  bool get isRateLimited => statusCode == 429;
  bool get isServerError => statusCode >= 500;
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorInterceptor — converts Dio HTTP errors to ApiError
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      final detail = _extractDetail(response.data);
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: response,
          type: err.type,
          error: ApiError(response.statusCode ?? 0, detail),
        ),
      );
    } else {
      handler.next(err);
    }
  }

  String _extractDetail(dynamic data) {
    if (data is Map) return data['detail']?.toString() ?? 'Unknown error';
    if (data is String) return data;
    return 'Unknown error';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod providers
// ─────────────────────────────────────────────────────────────────────────────

// Base URL — loaded from SharedPreferences, overridden at startup in main.dart
final apiBaseUrlProvider = NotifierProvider<ApiBaseUrlNotifier, String>(
  ApiBaseUrlNotifier.new,
);

class ApiBaseUrlNotifier extends Notifier<String> {
  final String _initial;
  ApiBaseUrlNotifier([this._initial = _kDefaultBaseUrl]);

  @override
  String build() => _initial;

  void update(String url) => state = url;
}

// ApiClient singleton — recreated when baseUrl changes
final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return ApiClient(baseUrl);
});

// Helper to load saved base URL on app startup
Future<String> loadSavedBaseUrl() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kBaseUrlKey) ?? _kDefaultBaseUrl;
}

Future<void> saveBaseUrl(String url) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kBaseUrlKey, url);
}
