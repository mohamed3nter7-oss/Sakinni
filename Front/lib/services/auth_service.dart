import 'package:dio/dio.dart';
import 'package:sakkeny_app/services/api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _currentUser;
  String? _accessToken;

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Map<String, dynamic>? get user => _currentUser;
  bool get isLoggedIn => _accessToken != null;
  String? get userId => _currentUser?['_id'] as String?;

  void _setAuthState({
    required String accessToken,
    Map<String, dynamic>? user,
  }) {
    _accessToken = accessToken;
    _api.setAccessToken(accessToken);
    _currentUser = user;
  }

  void clearAuthState() {
    _accessToken = null;
    _currentUser = null;
    _api.clearAccessToken();
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      final response = await _api.post(
        '/auth/register',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          'userRole': 'user',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['data']?['accessToken'] as String?;
      final user = data['data']?['user'] as Map<String, dynamic>?;
      if (accessToken != null) {
        _setAuthState(accessToken: accessToken, user: user);
      }

      return data;
    } on DioException catch (error) {
      return {
        'success': false,
        'message': error.response?.data?['message'] ?? error.message,
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['data']?['accessToken'] as String?;
      final user = data['data']?['user'] as Map<String, dynamic>?;
      if (accessToken != null) {
        _setAuthState(accessToken: accessToken, user: user);
      }

      return data;
    } on DioException catch (error) {
      return {
        'success': false,
        'message': error.response?.data?['message'] ?? error.message,
      };
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final response = await _api.post('/auth/refresh-token');
      final data = response.data as Map<String, dynamic>;
      final accessToken = data['data']?['accessToken'] as String?;
      if (accessToken != null) {
        _setAuthState(accessToken: accessToken, user: _currentUser);
      }
      return data;
    } on DioException catch (error) {
      return {
        'success': false,
        'message': error.response?.data?['message'] ?? error.message,
      };
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _api.get('/auth/me');
      final data = response.data as Map<String, dynamic>;
      final user = data['data']?['user'] as Map<String, dynamic>?;
      if (user != null) {
        _currentUser = user;
      }
      return data;
    } on DioException catch (error) {
      return {
        'success': false,
        'message': error.response?.data?['message'] ?? error.message,
      };
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // ignore logout errors, but always clear local state
    }
    clearAuthState();
  }
}
