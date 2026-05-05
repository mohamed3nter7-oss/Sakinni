import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String paymentId;
  final String userId;
  final String propertyId;
  final String bookingId;
  final double amount;
  final String currency;
  final String status; // pending, completed, failed, refunded
  final String paymentMethod; // card, paypal, etc.
  final Map<String, dynamic> paymentDetails; // card info, etc.
  final DateTime createdAt;
  final DateTime? processedAt;

  PaymentModel({
    required this.paymentId,
    required this.userId,
    required this.propertyId,
    required this.bookingId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.paymentDetails,
    required this.createdAt,
    this.processedAt,
  });

  factory PaymentModel.fromFirestore(Map<String, dynamic> data, String id) {
    return PaymentModel(
      paymentId: id,
      userId: data['userId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      bookingId: data['bookingId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'EGP',
      status: data['status'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? 'card',
      paymentDetails: data['paymentDetails'] ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'propertyId': propertyId,
      'bookingId': bookingId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentDetails': paymentDetails,
      'createdAt': Timestamp.fromDate(createdAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    };
  }
}