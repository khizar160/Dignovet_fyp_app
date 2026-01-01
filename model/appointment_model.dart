import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String userId;
  final String doctorId;
  final String animalName;
  final Timestamp date; // Use Timestamp instead of String
  final String time;
  final String problem;
  final String status;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.animalName,
    required this.date,
    required this.time,
    required this.problem,
    required this.status,
  });

  /// Convert model to map for Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'doctorId': doctorId,
        'animalName': animalName,
        'date': date,
        'time': time,
        'problem': problem,
        'status': status,
        'createdAt': Timestamp.now(),
      };

  /// Convert Firestore document to model
  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AppointmentModel(
      id: id,
      userId: map['userId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      animalName: map['animalName'] ?? '',
      date: map['date'] ?? Timestamp.now(),
      time: map['time'] ?? '',
      problem: map['problem'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }
}
