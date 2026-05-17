

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

  factory PaymentModel.fromJson(Map<String, dynamic> data, String id) {
    return PaymentModel(
      paymentId: data['_id'] ?? id,
      userId: data['user']?['_id'] ?? data['userId'] ?? '',
      propertyId: data['property']?['_id'] ?? data['propertyId'] ?? '',
      bookingId: data['booking']?['_id'] ?? data['bookingId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'EGP',
      status: data['status'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? 'card',
      paymentDetails: data['paymentDetails'] ?? {},
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
      processedAt: data['processedAt'] != null ? DateTime.tryParse(data['processedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'propertyId': propertyId,
      'bookingId': bookingId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentDetails': paymentDetails,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }
}