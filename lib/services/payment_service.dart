import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final paymentData = {
        'userId': user.uid,
        'propertyId': propertyId,
        'bookingId': bookingId,
        'amount': amount,
        'currency': currency,
        'status': 'pending',
        'paymentMethod': paymentMethod,
        'paymentDetails': paymentDetails,
        'createdAt': FieldValue.serverTimestamp(),
        'processedAt': null,
      };

      final docRef = await _firestore.collection('payment').add(paymentData);
      return docRef.id;
    } catch (e) {
      print('Error creating payment: $e');
      return null;
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus(String paymentId, String status, {DateTime? processedAt}) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (processedAt != null) {
        updateData['processedAt'] = Timestamp.fromDate(processedAt);
      }

      await _firestore.collection('payment').doc(paymentId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating payment status: $e');
      return false;
    }
  }

  // Get payment by ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final doc = await _firestore.collection('payment').doc(paymentId).get();
      if (doc.exists) {
        return PaymentModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching payment: $e');
      return null;
    }
  }

  // Get payments for current user
  Stream<List<PaymentModel>> getUserPayments() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('payment')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PaymentModel.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }
}