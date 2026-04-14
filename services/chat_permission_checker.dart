import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class to check chat permissions based on appointment status
class ChatPermissionChecker {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the current chat permission for an appointment
  Future<Map<String, bool>> getChatPermissions({
    required String appointmentId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      // Get appointment document
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        print('[ChatPermissionChecker] ⚠️  Appointment not found: $appointmentId');
        return {'canRead': false, 'canSend': false, 'canDelete': true};
      }

      final data = appointmentDoc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? '')
          .toString()
          .toLowerCase()
          .trim(); // Normalize status
      final doctorId = data['doctorId'] as String?;
      final isDoctor = doctorId == currentUserId;

      print('[ChatPermissionChecker] 📊 Checking permissions - status: $status, isDoctor: $isDoctor, doctorId: $doctorId, currentUserId: $currentUserId');

      // If appointment is not approved yet
      if (status != 'approved' && status != 'active' && status != 'completed') {
        print('[ChatPermissionChecker] 🔒 Appointment not approved/active/completed yet (status: $status)');
        return {'canRead': false, 'canSend': false, 'canDelete': true};
      }

      // DOCTOR PERMISSIONS: Doctor can ALWAYS read and send throughout entire appointment
      // Even after appointment ends, doctor can still see and send (for follow-ups)
      if (isDoctor) {
        print('[ChatPermissionChecker] ✅ Doctor permissions granted - ALWAYS enabled');
        return {
          'canRead': true,
          'canSend': true,
          'canDelete': true,
        };
      }

      // USER (PATIENT) PERMISSIONS: Restricted based on appointment status and time
      final chatStatus = data['chatStatus'] ?? 'disabled';
      final appointmentEndTime = data['consultationEndTime'] as Timestamp?;
      final now = DateTime.now();
      final hasEnded =
          appointmentEndTime != null && appointmentEndTime.toDate().isBefore(now);

      print('[ChatPermissionChecker] 👤 User permissions - status: $status, chatStatus: $chatStatus, hasEnded: $hasEnded');

      // User permissions based on appointment lifecycle
      if (status == 'approved') {
        // Appointment approved but not started - user can READ but not SEND until active
        return {
          'canRead': true,
          'canSend': false,
          'canDelete': true,
        };
      } else if (status == 'active') {
        // Active consultation - user can fully chat
        return {
          'canRead': true,
          'canSend': true,
          'canDelete': true,
        };
      } else if (status == 'completed') {
        // Appointment completed - user can read but not send (for rating/reference)
        return {
          'canRead': true,
          'canSend': false,
          'canDelete': true,
        };
      } else {
        // Default: no access
        return {'canRead': false, 'canSend': false, 'canDelete': true};
      }
    } catch (e) {
      print('[ChatPermissionChecker] ❌ Error getting permissions: $e');
      // On ANY error, allow doctor to proceed, deny patient
      return {'canRead': false, 'canSend': false, 'canDelete': true};
    }
  }

  /// Check if user can send messages
  Future<bool> canSendMessage({
    required String appointmentId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    final permissions = await getChatPermissions(
      appointmentId: appointmentId,
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );
    return permissions['canSend'] ?? false;
  }

  /// Check if user can read messages
  Future<bool> canReadMessages({
    required String appointmentId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    final permissions = await getChatPermissions(
      appointmentId: appointmentId,
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );
    return permissions['canRead'] ?? false;
  }

  /// Check if doctor can start conversation before appointment time
  /// Doctor can always message once appointment is approved
  Future<bool> canDoctorStartMessaging({
    required String appointmentId,
    required String doctorId,
  }) async {
    try {
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) return false;

      final data = appointmentDoc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'pending';

      // Doctor can start messaging once appointment is approved
      return status == 'approved' || status == 'active' || status == 'completed';
    } catch (e) {
      print('[ChatPermissionChecker] ⚠️ Error checking doctor messaging: $e');
      return false;
    }
  }

  /// Get message why doctor cannot message yet
  String getDoctorMessagingBlockReason({
    required String appointmentId,
    required String status,
    required String appointmentTime,
  }) {
    if (status != 'approved') return 'Appointment is not approved yet';
    
    return '⏰ You can start messaging when the appointment time arrives ($appointmentTime).\n\n'
        'This ensures patient privacy until the scheduled consultation time.';
  }

  /// Get remaining time until doctor can message
  Future<Duration?> getTimeUntilDoctorCanMessage({
    required String appointmentId,
  }) async {
    try {
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) return null;

      final data = appointmentDoc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'pending';

      if (status != 'approved') return null;

      try {
        final appointmentDate = (data['date'] as Timestamp).toDate();
        final timeStr = (data['time'] as String);
        
        // Handle different time formats (HH:MM or HH-MM)
        final timeParts = timeStr.contains(':') 
            ? timeStr.split(':') 
            : timeStr.split('-');
        
        if (timeParts.length < 2) return null;
        
        final scheduledTime = DateTime(
          appointmentDate.year,
          appointmentDate.month,
          appointmentDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        final now = DateTime.now();
        if (now.isAfter(scheduledTime)) return Duration.zero;

        return scheduledTime.difference(now);
      } catch (timeError) {
        print('[ChatPermissionChecker] ⚠️ Error parsing appointment time: $timeError');
        return null;
      }
    } catch (e) {
      print('[ChatPermissionChecker] ❌ Error getting time until message allowed: $e');
      return null;
    }
  }
}
