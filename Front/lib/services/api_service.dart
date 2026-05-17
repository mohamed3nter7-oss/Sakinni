import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio dio;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    // Web (Chrome) needs localhost; Android emulator needs 10.0.2.2
    final String baseUrl = kIsWeb
        ? 'http://localhost:5000/api'
        : (dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000/api');

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await secureStorage.read(key: 'accessToken');
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          final refreshToken = await secureStorage.read(key: 'refreshToken');
          if (refreshToken != null) {
            options.headers['cookie'] = 'refreshToken=$refreshToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            // Attempt to refresh token
            bool refreshed = await _refreshToken();
            if (refreshed) {
              // Retry original request
              final options = e.requestOptions;
              final accessToken = await secureStorage.read(key: 'accessToken');
              if (accessToken != null) {
                options.headers['Authorization'] = 'Bearer $accessToken';
              }
              try {
                final response = await dio.fetch(options);
                return handler.resolve(response);
              } catch (err) {
                return handler.next(e);
              }
            } else {
              // Logout if refresh fails
              await logout();
            }
          }
          return handler.next(e);
        },
        onResponse: (response, handler) async {
          await _extractAndSaveCookie(response);
          return handler.next(response);
        }
      ),
    );
  }

  Future<void> _extractAndSaveCookie(Response response) async {
    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      for (var cookie in cookies) {
        if (cookie.contains('refreshToken=')) {
          final parts = cookie.split(';');
          final tokenPart = parts.firstWhere((p) => p.trim().startsWith('refreshToken='));
          final token = tokenPart.split('=')[1];
          await secureStorage.write(key: 'refreshToken', value: token);
          break;
        }
      }
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final response = await dio.post('/auth/refresh-token');
      if (response.statusCode == 200) {
        final newAccessToken = response.data['data']['accessToken'];
        await secureStorage.write(key: 'accessToken', value: newAccessToken);
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<void> saveAuthData(String accessToken, Map<String, dynamic> user) async {
    await secureStorage.write(key: 'accessToken', value: accessToken);
    // You could also store user info here if needed
  }

  Future<void> logout() async {
    try {
      await dio.post('/auth/logout');
    } catch (_) {}
    await secureStorage.delete(key: 'accessToken');
    await secureStorage.delete(key: 'refreshToken');
    // Navigate to login screen logic should be handled by the UI
  }
}
