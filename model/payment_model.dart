import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String userId;
  final String doctorId;
  final String appointmentId;
  final double amount;
  final String? paymentIntentId;
  final String? paymentScreenshotUrl;
  final String status; // 'pending', 'completed', 'refunded', 'failed'
  final String? refundId;
  final Timestamp createdAt;
  final Timestamp? completedAt;
  final String consultationType;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.appointmentId,
    required this.amount,
    this.paymentIntentId,
    this.paymentScreenshotUrl,
    required this.status,
    this.refundId,
    required this.createdAt,
    this.completedAt,
    required this.consultationType,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'doctorId': doctorId,
        'appointmentId': appointmentId,
        'amount': amount,
        'paymentIntentId': paymentIntentId,
        'paymentScreenshotUrl': paymentScreenshotUrl,
        'status': status,
        'refundId': refundId,
        'createdAt': createdAt,
        'completedAt': completedAt,
        'consultationType': consultationType,
      };

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      userId: map['userId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      appointmentId: map['appointmentId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentIntentId: map['paymentIntentId'],
      paymentScreenshotUrl: map['paymentScreenshotUrl'],
      status: map['status'] ?? 'pending',
      refundId: map['refundId'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      completedAt: map['completedAt'],
      consultationType: map['consultationType'] ?? 'online',
    );
  }
}
