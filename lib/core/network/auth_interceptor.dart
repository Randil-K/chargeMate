import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:charge_mate/core/constants/api_endpoints.dart';
import 'package:charge_mate/core/constants/app_constants.dart';

/// JWT Authentication Interceptor using QueuedInterceptor.
///
/// Automatically:
/// - Attaches Bearer token to all outgoing requests
/// - Handles 401 responses by refreshing the token
/// - Queues concurrent requests during token refresh (prevents duplicate refresh calls)
/// - Redirects to login on permanent auth failure
class AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final void Function() onSessionExpired;

  AuthInterceptor({
    required Dio dio,
    required FlutterSecureStorage storage,
    required this.onSessionExpired,
  })  : _dio = dio,
        _storage = storage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = await _storage.read(
      key: AppConstants.refreshTokenKey,
    );

    if (refreshToken == null) {
      _handleSessionExpired();
      return handler.reject(err);
    }

    try {
      // Use a clean Dio instance to avoid interceptor loops.
      final tokenDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));

      final response = await tokenDio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'] as String;
      final newRefreshToken = response.data['refresh_token'] as String;

      // Persist new tokens.
      await Future.wait([
        _storage.write(
          key: AppConstants.accessTokenKey,
          value: newAccessToken,
        ),
        _storage.write(
          key: AppConstants.refreshTokenKey,
          value: newRefreshToken,
        ),
      ]);

      // Replay the original failed request with new token.
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final clonedResponse = await _dio.fetch(retryOptions);
      return handler.resolve(clonedResponse);
    } catch (_) {
      _handleSessionExpired();
      return handler.reject(err);
    }
  }

  void _handleSessionExpired() {
    _storage.delete(key: AppConstants.accessTokenKey);
    _storage.delete(key: AppConstants.refreshTokenKey);
    onSessionExpired();
  }
}
