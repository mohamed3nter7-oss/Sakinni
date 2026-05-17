import 'package:sakkeny_app/services/api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await _api.get('/users/$userId');
      return response.data as Map<String, dynamic>;
    } catch (error) {
      return {'success': false, 'message': '$error'};
    }
  }

  Future<Map<String, dynamic>> updateUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _api.patch('/users/$userId', data: data);
      return response.data as Map<String, dynamic>;
    } catch (error) {
      return {'success': false, 'message': '$error'};
    }
  }
}
