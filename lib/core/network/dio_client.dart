import 'package:dio/dio.dart';

import '../../core/utils/logger.dart';
import '../constants/app_constants.dart';

final _log = AppLogger('DioClient');

/// Pre-configured [Dio] HTTP client for external API calls (e.g., Gemini).
///
/// Supabase operations use the built-in `supabase_flutter` client directly —
/// this Dio instance is reserved for non-Supabase HTTP traffic only.
class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectionTimeoutMs,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.httpTimeoutMs,
        ),
        sendTimeout: const Duration(
          milliseconds: AppConstants.httpTimeoutMs,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ── Logging Interceptor ───────────────────────────────────────────────
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _log.debug('→ ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _log.debug('← ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _log.error(
            '✗ ${error.requestOptions.method} ${error.requestOptions.uri} — '
            '${error.response?.statusCode ?? 'NO_RESPONSE'}: ${error.message}',
            error,
            error.stackTrace,
          );
          return handler.next(error);
        },
      ),
    );
  }

  /// The underlying [Dio] instance for adding custom interceptors.
  Dio get dio => _dio;

  /// Perform a GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  /// Perform a POST request.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  /// Perform a PUT request.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return _dio.put<T>(path, data: data, options: options);
  }

  /// Perform a DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return _dio.delete<T>(path, data: data, options: options);
  }
}
