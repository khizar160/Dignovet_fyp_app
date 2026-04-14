import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultationRating {
  final String id;
  final String appointmentId;
  final String userId;
  final String userPhone;
  final String userName;
  final String doctorId;
  final String doctorName;
  final String animalName;
  final int doctorRating; // 1-5 stars
  final int appRating; // 1-5 stars
  final String? doctorFeedback;
  final String? appFeedback;
  final Timestamp ratedAt;
  final Timestamp consultationEndTime;

  ConsultationRating({
    required this.id,
    required this.appointmentId,
    required this.userId,
    required this.userPhone,
    required this.userName,
    required this.doctorId,
    required this.doctorName,
    required this.animalName,
    required this.doctorRating,
    required this.appRating,
    this.doctorFeedback,
    this.appFeedback,
    required this.ratedAt,
    required this.consultationEndTime,
  });

  /// Convert model to map for Firestore
  Map<String, dynamic> toMap() => {
        'appointmentId': appointmentId,
        'userId': userId,
        'userPhone': userPhone,
        'userName': userName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'animalName': animalName,
        'doctorRating': doctorRating,
        'appRating': appRating,
        'doctorFeedback': doctorFeedback,
        'appFeedback': appFeedback,
        'ratedAt': ratedAt,
        'consultationEndTime': consultationEndTime,
      };

  /// Convert Firestore document to model
  factory ConsultationRating.fromMap(Map<String, dynamic> map, String id) {
    return ConsultationRating(
      id: id,
      appointmentId: map['appointmentId'] ?? '',
      userId: map['userId'] ?? '',
      userPhone: map['userPhone'] ?? '',
      userName: map['userName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      animalName: map['animalName'] ?? '',
      doctorRating: map['doctorRating'] ?? 0,
      appRating: map['appRating'] ?? 0,
      doctorFeedback: map['doctorFeedback'],
      appFeedback: map['appFeedback'],
      ratedAt: map['ratedAt'] ?? Timestamp.now(),
      consultationEndTime: map['consultationEndTime'] ?? Timestamp.now(),
    );
  }
}
