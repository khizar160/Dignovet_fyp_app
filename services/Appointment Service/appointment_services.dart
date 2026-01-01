import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/appointment_model.dart';


class AppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create a new appointment and return its document ID
  Future<String> createAppointment(AppointmentModel model) async {
    final docRef = await _db.collection('appointments').add(model.toMap());
    return docRef.id;
  }

  /// Stream of pending appointments for a doctor
  Stream<QuerySnapshot> doctorAppointments(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Stream of all appointments for a user, ordered by creation time
  Stream<QuerySnapshot> userAppointments(String userId) {
    return _db
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  /// Update status of appointment
  Future<void> updateStatus(String id, String status) async {
    final docRef = _db.collection('appointments').doc(id);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await docRef.update({'status': status});
    } else {
      throw Exception("Appointment not found");
    }
  }
}
