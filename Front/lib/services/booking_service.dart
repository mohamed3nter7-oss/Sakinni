import 'package:dio/dio.dart';
import 'package:sakkeny_app/services/api_service.dart';

class BookingService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>?> createBooking({
    required String propertyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _api.post(
        '/bookings',
        data: {
          'property': propertyId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      return {
        'success': false,
        'message': error.response?.data?['message'] ?? error.message,
      };
    }
  }

  Future<List<dynamic>> getMyBookings() async {
    try {
      final response = await _api.get('/bookings/my-bookings');
      return (response.data['data'] as List<dynamic>?) ?? [];
    } on DioException catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    try {
      final response = await _api.get('/bookings/$bookingId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      return {
        'success': false,
        'message': error.response?.data?['message'] ?? error.message,
      };
    }
  }
}
