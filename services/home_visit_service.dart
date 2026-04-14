import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/home_visit_appointment_model.dart';

class HomeVisitService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new home visit request
  static Future<String> createHomeVisitRequest(
    HomeVisitAppointmentModel request,
  ) async {
    try {
      final docRef = await _firestore
          .collection('home_visit_appointments')
          .add(request.toMap());
      
      print('✅ Home visit request created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating home visit request: $e');
      throw Exception('Failed to create home visit request: $e');
    }
  }

  /// Get home visit requests for a doctor (pending only)
  static Stream<List<HomeVisitAppointmentModel>> getDoctorHomeVisitRequests(
    String doctorId,
  ) {
    return _firestore
        .collection('home_visit_appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => HomeVisitAppointmentModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ))
          .toList();
      return requests;
    });
  }

  /// Get home visit requests for a user
  static Stream<List<HomeVisitAppointmentModel>> getUserHomeVisitRequests(
    String userId,
  ) {
    return _firestore
        .collection('home_visit_appointments')
        .where('userId', isEqualTo: userId)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => HomeVisitAppointmentModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ))
          .toList();
      return requests;
    });
  }

  /// Doctor accepts home visit request
  static Future<void> acceptHomeVisitRequest(
    String requestId,
    String doctorId,
    String estimatedArrival,
  ) async {
    try {
      await _firestore
          .collection('home_visit_appointments')
          .doc(requestId)
          .update({
        'status': 'accepted',
        'doctorStatus': 'accepted',
        'doctorAcceptanceTime': DateTime.now().toIso8601String(),
        'doctorEstimatedArrival': estimatedArrival,
        'chatEnabled': true, // Enable chat after acceptance
        'chatEnabledAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      print('✅ Home visit request accepted: $requestId');
    } catch (e) {
      print('❌ Error accepting home visit request: $e');
      throw Exception('Failed to accept request: $e');
    }
  }

  /// Doctor rejects home visit request
  static Future<void> rejectHomeVisitRequest(
    String requestId,
    String rejectionReason,
  ) async {
    try {
      await _firestore
          .collection('home_visit_appointments')
          .doc(requestId)
          .update({
        'status': 'rejected',
        'doctorRejectionReason': rejectionReason,
        'updatedAt': Timestamp.now(),
      });

      print('✅ Home visit request rejected: $requestId');
    } catch (e) {
      print('❌ Error rejecting home visit request: $e');
      throw Exception('Failed to reject request: $e');
    }
  }

  /// Update doctor location (for live tracking)
  static Future<void> updateDoctorLocation(
    String requestId,
    double latitude,
    double longitude,
    String status, // 'on_the_way', 'arrived', 'in_progress'
  ) async {
    try {
      await _firestore
          .collection('home_visit_appointments')
          .doc(requestId)
          .update({
        'doctorCurrentLatitude': latitude,
        'doctorCurrentLongitude': longitude,
        'doctorStatus': status,
        'liveLocationEnabled': true,
        'updatedAt': Timestamp.now(),
      });

      print('✅ Doctor location updated: $requestId');
    } catch (e) {
      print('❌ Error updating doctor location: $e');
      throw Exception('Failed to update location: $e');
    }
  }

  /// Mark visit as completed
  static Future<void> completeHomeVisit(
    String requestId,
    String visitNotes,
    String paymentMethod, // 'cash' or 'online'
  ) async {
    try {
      await _firestore
          .collection('home_visit_appointments')
          .doc(requestId)
          .update({
        'status': 'completed',
        'doctorStatus': 'completed',
        'chatEnabled': false, // Disable chat after completion
        'visitCompletedAt': Timestamp.now(),
        'visitNotes': visitNotes,
        'paymentMethod': paymentMethod,
        'paymentStatus': 'completed',
        'updatedAt': Timestamp.now(),
      });

      print('✅ Home visit completed: $requestId');
    } catch (e) {
      print('❌ Error completing home visit: $e');
      throw Exception('Failed to complete visit: $e');
    }
  }

  /// Get home visit request by ID
  static Future<HomeVisitAppointmentModel?> getHomeVisitRequest(
    String requestId,
  ) async {
    try {
      final doc = await _firestore
          .collection('home_visit_appointments')
          .doc(requestId)
          .get();

      if (doc.exists) {
        return HomeVisitAppointmentModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error fetching home visit request: $e');
      return null;
    }
  }

  /// Stream to watch a specific home visit request
  static Stream<HomeVisitAppointmentModel?> watchHomeVisitRequest(
    String requestId,
  ) {
    return _firestore
        .collection('home_visit_appointments')
        .doc(requestId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return HomeVisitAppointmentModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    });
  }

  /// Stream doctor's live location updates
  static Stream<Map<String, dynamic>> getDoctorLiveLocation(String requestId) {
    return _firestore
        .collection('home_visit_appointments')
        .doc(requestId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return {};
      
      final data = doc.data() ?? {};
      return {
        'latitude': double.tryParse(data['doctorCurrentLatitude']?.toString() ?? '0') ?? 0.0,
        'longitude': double.tryParse(data['doctorCurrentLongitude']?.toString() ?? '0') ?? 0.0,
        'address': data['doctorCurrentAddress'] ?? 'En route',
        'status': data['doctorStatus'] ?? 'accepted',
        'eta': data['doctorEstimatedArrival'] ?? 'Calculating...',
        'updatedAt': data['updatedAt'],
      };
    });
  }

  /// Enable live location sharing for doctor
  static Future<void> enableLiveLocation(String requestId) async {
    try {
      await _firestore
          .collection('home_visit_appointments')
          .doc(requestId)
          .update({
        'liveLocationEnabled': true,
        'liveLocationEnabledAt': Timestamp.now(),
      });

      print('✅ Live location enabled: $requestId');
    } catch (e) {
      print('❌ Error enabling live location: $e');
      throw Exception('Failed to enable location: $e');
    }
  }

  /// Disable live location sharing for doctor
  static Future<void> disableLiveLocation(String requestId) async {
    try {
      await _firestore
          .collection('home_visit_appointments')
          .doc(requestId)
          .update({
        'liveLocationEnabled': false,
      });

      print('✅ Live location disabled: $requestId');
    } catch (e) {
      print('❌ Error disabling live location: $e');
      throw Exception('Failed to disable location: $e');
    }
  }

  /// Get doctor's current location
  static Future<Map<String, dynamic>?> getDoctorCurrentLocation(String requestId) async {
    try {
      final doc = await _firestore
          .collection('home_visit_appointments')
          .doc(requestId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return {
          'latitude': double.tryParse(data?['doctorCurrentLatitude']?.toString() ?? '0'),
          'longitude': double.tryParse(data?['doctorCurrentLongitude']?.toString() ?? '0'),
          'address': data?['doctorCurrentAddress'] ?? 'Location unknown',
          'eta': data?['doctorEstimatedArrival'],
          'status': data?['doctorStatus'],
        };
      }
      return null;
    } catch (e) {
      print('❌ Error fetching doctor location: $e');
      return null;
    }
  }

  /// Get all active home visits for a doctor (for map view)
  static Stream<List<HomeVisitAppointmentModel>> getDoctorActiveVisits(String doctorId) {
    return _firestore
        .collection('home_visit_appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', whereIn: ['accepted', 'on_the_way'])
        .orderBy('status')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HomeVisitAppointmentModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// Update doctor status
  static Future<void> updateDoctorStatus(String requestId, String newStatus) async {
    try {
      await _firestore
          .collection('home_visit_appointments')
          .doc(requestId)
          .update({
        'doctorStatus': newStatus,
        'status': newStatus == 'completed' ? 'completed' : newStatus,
        'updatedAt': Timestamp.now(),
      });

      print('✅ Doctor status updated to: $newStatus');
    } catch (e) {
      print('❌ Error updating doctor status: $e');
      throw Exception('Failed to update status: $e');
    }
  }

  /// Cancel home visit
  static Future<void> cancelHomeVisit(String requestId, String reason) async {
    try {
      await _firestore
          .collection('home_visit_appointments')
          .doc(requestId)
          .update({
        'status': 'cancelled',
        'doctorStatus': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      print('✅ Home visit cancelled: $requestId');
    } catch (e) {
      print('❌ Error cancelling home visit: $e');
      throw Exception('Failed to cancel visit: $e');
    }
  }
}
