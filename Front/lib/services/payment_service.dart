import '../models/payment.dart';
import 'api_service.dart';

class PaymentService {
  // Create a payment record
  Future<String?> createPayment({
    required String propertyId,
    required String bookingId,
    required double amount,
    required String currency,
    required String paymentMethod,
    required Map<String, dynamic> paymentDetails,
  }) async {
    try {
      final response = await ApiService().dio.post('/payments', data: {
        'propertyId': propertyId,
        'bookingId': bookingId,
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod,
        'paymentDetails': paymentDetails,
        'status': 'completed',
      });
      if (response.data['success'] == true) {
        return response.data['data']['payment']?['_id'] ?? response.data['data']?['_id'];
      }
      return null;
    } catch (e) {
      print('Error creating payment: $e');
      return null;
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus(String paymentId, String status, {DateTime? processedAt}) async {
    try {
      final response = await ApiService().dio.patch('/payments/$paymentId/status', data: {
        'status': status,
      });
      return response.data['success'] == true;
    } catch (e) {
      print('Error updating payment status: $e');
      return false;
    }
  }

  // Get payment by ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final response = await ApiService().dio.get('/payments/$paymentId');
      if (response.data['success'] == true) {
        return PaymentModel.fromJson(response.data['data']['payment'] ?? response.data['data'], paymentId);
      }
      return null;
    } catch (e) {
      print('Error fetching payment: $e');
      return null;
    }
  }

  // Get payments for current user
  Stream<List<PaymentModel>> getUserPayments() async* {
    try {
      final response = await ApiService().dio.get('/payments/my-payments');
      if (response.data['success'] == true) {
        List<dynamic> data = response.data['data']['payments'] ?? response.data['data'] ?? [];
        yield data.map((e) => PaymentModel.fromJson(e, e['_id'] ?? '')).toList();
      } else {
        yield [];
      }
    } catch (e) {
      yield [];
    }
  }
}