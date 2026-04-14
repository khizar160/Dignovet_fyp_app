import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create a new appointment and return its document ID
  Future<String> createAppointment(AppointmentModel model) async {
    print('\n📅 Creating appointment in Firestore...');
    print('   User ID: ${model.userId}');
    print('   Doctor ID: ${model.doctorId}');
    print('   Animal: ${model.animalName}');
    print('   Date: ${model.date.toDate()}');
    print('   Time: ${model.time}');
    print('   Consultation Type: ${model.consultationType}');
    print('   Payment Amount: \$${model.paymentAmount.toStringAsFixed(2)}');
    
    final docRef = await _db.collection('appointments').add(model.toMap());
    
    print('✅ Appointment created successfully!');
    print('   Appointment ID: ${docRef.id}');
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
  /// Status must be: "pending", "approved", "declined", "completed"
  Future<void> updateStatus(String id, String status) async {
    final normalizedStatus = status.toLowerCase().trim();
    
    // Validate status
    const validStatuses = ['pending', 'approved', 'declined', 'completed'];
    if (!validStatuses.contains(normalizedStatus)) {
      throw Exception('Invalid status: $status. Must be: ${validStatuses.join(", ")}');
    }
    
    print('\n🔄 [UpdateStatus] Updating appointment status...');
    print('   Appointment ID: $id');
    print('   New Status: $normalizedStatus');
    
    final docRef = _db.collection('appointments').doc(id);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await docRef.update({
        'status': normalizedStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ [UpdateStatus] Status updated to "$normalizedStatus" with serverTimestamp');
    } else {
      print('❌ [UpdateStatus] Appointment not found!');
      throw Exception("Appointment not found");
    }
  }

  /// Update payment status of appointment
  Future<void> updatePaymentStatus({
    required String appointmentId,
    required String paymentStatus,
    String? refundId,
  }) async {
    print('\n💳 Updating appointment payment status...');
    print('   Appointment ID: $appointmentId');
    print('   Payment Status: $paymentStatus');
    if (refundId != null) {
      print('   Refund ID: $refundId');
    }
    
    final docRef = _db.collection('appointments').doc(appointmentId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final Map<String, dynamic> updateData = {
        'paymentStatus': paymentStatus,
      };

      if (refundId != null) {
        updateData['refundId'] = refundId;
      }

      await docRef.update(updateData);
      print('✅ Appointment payment status updated successfully!');
    } else {
      print('❌ Appointment not found!');
      throw Exception("Appointment not found");
    }
  }

  /// Get appointment by ID
  Future<AppointmentModel?> getAppointmentById(String id) async {
    try {
      final docSnapshot = await _db.collection('appointments').doc(id).get();
      if (docSnapshot.exists) {
        return AppointmentModel.fromMap(docSnapshot.data()!, docSnapshot.id);
      }
      return null;
    } catch (e) {
      print('Error getting appointment: $e');
      return null;
    }
  }

  /// Get appointments by payment status
  Future<List<AppointmentModel>> getAppointmentsByPaymentStatus({
    required String userId,
    required String paymentStatus,
  }) async {
    try {
      final querySnapshot = await _db
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .where('paymentStatus', isEqualTo: paymentStatus)
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting appointments by payment status: $e');
      return [];
    }
  }
}
