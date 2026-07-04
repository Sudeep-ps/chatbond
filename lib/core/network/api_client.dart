import 'package:dio/dio.dart';
import 'package:chatbond/core/storage/token_storage.dart';
import 'package:chatbond/core/storage/auth_session.dart';

class ApiClient {
  // Android emulator -> 10.0.2.2, iOS simulator/web -> localhost, physical device -> your LAN IP
  static const String baseUrl = 'http://192.168.220.14:3000/api/v1';

  late final Dio dio;
  Future<String?>? _refreshing;

  ApiClient() {
    dio = Dio(BaseOptions(
        baseUrl: baseUrl, connectTimeout: const Duration(seconds: 10)));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isAuthRoute = error.requestOptions.path.contains('/auth/');
        if (error.response?.statusCode == 401 && !isAuthRoute) {
          final newToken = await _refreshAccessToken();
          if (newToken != null) {
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            try {
              final retryResponse = await dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
              // fall through to reject below
            }
          } else {
            await TokenStorage.clear();
            AuthSession.update(null);
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<String?> _refreshAccessToken() {
    // guard against multiple concurrent refresh calls
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) return null;
    try {
      final plainDio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await plainDio
          .post('/auth/refresh', data: {'refreshToken': refreshToken});
      final accessToken = response.data['accessToken'] as String;
      final newRefreshToken = response.data['refreshToken'] as String;
      await TokenStorage.saveTokens(accessToken, newRefreshToken);
      return accessToken;
    } catch (_) {
      return null;
    }
  }
}
