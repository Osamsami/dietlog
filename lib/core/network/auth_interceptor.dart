import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/logger.dart';

final _log = AppLogger('AuthInterceptor');

/// Dio interceptor that attaches the current Supabase JWT Bearer token
/// to outgoing requests.
///
/// If the user is not authenticated, requests pass through without
/// an Authorization header. If a 401 response is received, the
/// interceptor logs the event for upstream handling.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      _log.debug('JWT attached to ${options.method} ${options.uri}');
    } else {
      _log.warning('No active session — request sent without JWT');
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _log.warning(
        'Received 401 Unauthorized for ${err.requestOptions.uri} — '
        'session may have expired',
      );
      // Upstream consumers (repositories/providers) handle re-auth logic.
    }

    return handler.next(err);
  }
}
