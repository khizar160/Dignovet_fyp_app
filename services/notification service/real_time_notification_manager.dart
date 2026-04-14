import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';

class RealTimeNotificationManager {
  static final RealTimeNotificationManager _instance =
      RealTimeNotificationManager._internal();

  factory RealTimeNotificationManager() {
    return _instance;
  }

  RealTimeNotificationManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send push notification to a specific user
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? appointmentId,
    String? doctorName,
    String? patientName,
    Map<String, String>? customData,
  }) async {
    try {
      log('[RealTimeNotificationManager] Sending push notification to user: $userId');

      // Get user's FCM tokens from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        log('[RealTimeNotificationManager] User document not found: $userId');
        return;
      }

      final fcmTokens = (userDoc.get('fcmTokens') as List<dynamic>?)?.cast<String>() ?? [];
      
      if (fcmTokens.isEmpty) {
        log('[RealTimeNotificationManager] No FCM tokens found for user: $userId');
        return;
      }

      log('[RealTimeNotificationManager] Found ${fcmTokens.length} FCM tokens for user: $userId');

      // Save notification to Firestore (Cloud Functions will trigger automatically)
      // When Cloud Functions are deployed, they'll watch for new notifications
      // and send FCM messages to the user's FCM tokens
      await _saveNotificationDb(
        userId,
        title,
        body,
        type,
        appointmentId,
        doctorName: doctorName,
        patientName: patientName,
        customData: customData,
      );

      log('[RealTimeNotificationManager] Push notification saved and queued for delivery: $userId');
    } catch (e) {
      log('[RealTimeNotificationManager] Error sending notification: $e');
    }
  }

  /// Send appointment reminder notification
  Future<void> sendAppointmentReminder({
    required String userId,
    required String appointmentId,
    required String doctorName,
    required String timeRemaining,
  }) async {
    await sendPushNotification(
      userId: userId,
      title: '⏰ Appointment Reminder',
      body: 'Your consultation with Dr. $doctorName starts in $timeRemaining',
      type: 'appointment_reminder',
      appointmentId: appointmentId,
      doctorName: doctorName,
    );
  }

  /// Send appointment approved notification
  Future<void> sendAppointmentApproved({
    required String userId,
    required String doctorName,
    required String appointmentId,
  }) async {
    await sendPushNotification(
      userId: userId,
      title: '✅ Appointment Approved!',
      body: 'Dr. $doctorName has approved your appointment. Please wait for consultation to begin.',
      type: 'appointment_approved',
      appointmentId: appointmentId,
      doctorName: doctorName,
    );
  }

  /// Send consultation started notification
  Future<void> sendConsultationStarted({
    required String userId,
    required String doctorName,
    required String appointmentId,
  }) async {
    await sendPushNotification(
      userId: userId,
      title: '🟢 Consultation Started',
      body: 'Your consultation with Dr. $doctorName has begun. You can now chat.',
      type: 'consultation_started',
      appointmentId: appointmentId,
      doctorName: doctorName,
    );
  }

  /// Send consultation ending soon notification
  Future<void> sendConsultationEndingSoon({
    required String userId,
    required String doctorName,
    required String appointmentId,
  }) async {
    await sendPushNotification(
      userId: userId,
      title: '⏰ Consultation Ending Soon',
      body: 'Your consultation with Dr. $doctorName ends in 5 minutes.',
      type: 'consultation_ending_soon',
      appointmentId: appointmentId,
      doctorName: doctorName,
    );
  }

  /// Send new chat message notification
  Future<void> sendChatNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required String appointmentId,
  }) async {
    await sendPushNotification(
      userId: receiverId,
      title: '💬 $senderName',
      body: message,
      type: 'chat_message',
      appointmentId: appointmentId,
    );
  }

  /// Send prescription shared notification
  Future<void> sendPrescriptionNotification({
    required String userId,
    required String doctorName,
    required String patientName,
    required String appointmentId,
  }) async {
    await sendPushNotification(
      userId: userId,
      title: '📋 Prescription Shared',
      body: 'Dr. $doctorName has shared a prescription for $patientName',
      type: 'prescription_shared',
      appointmentId: appointmentId,
      doctorName: doctorName,
      patientName: patientName,
    );
  }

  /// Send appointment declined notification
  Future<void> sendAppointmentDeclined({
    required String userId,
    required String doctorName,
    required String appointmentId,
    String? reason,
  }) async {
    await sendPushNotification(
      userId: userId,
      title: '❌ Appointment Declined',
      body: 'Dr. $doctorName has declined your appointment${reason != null ? ': $reason' : ''}',
      type: 'appointment_declined',
      appointmentId: appointmentId,
      doctorName: doctorName,
      customData: reason != null ? {'reason': reason} : null,
    );
  }

  /// Send payment received notification (for doctors)
  Future<void> sendPaymentNotification({
    required String doctorId,
    required String patientName,
    required double amount,
    required String appointmentId,
  }) async {
    await sendPushNotification(
      userId: doctorId,
      title: '💰 Payment Received',
      body: '$patientName paid Rs $amount for your consultation',
      type: 'payment_received',
      appointmentId: appointmentId,
      patientName: patientName,
    );
  }

  /// Save notification to Firestore for in-app display
  Future<void> _saveNotificationDb(
    String userId,
    String title,
    String body,
    String type,
    String? appointmentId, {
    String? doctorName,
    String? patientName,
    Map<String, String>? customData,
  }) async {
    try {
      final notificationData = {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'appointmentId': appointmentId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'in_app',
        if (doctorName != null) 'doctorName': doctorName,
        if (patientName != null) 'patientName': patientName,
        if (customData != null) ...customData,
      };

      await _firestore.collection('notifications').add(notificationData);
    } catch (e) {
      log('[RealTimeNotificationManager] Error saving in-app notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('[RealTimeNotificationManager] Error marking notification as read: $e');
    }
  }

  /// Get user's notifications stream
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      log('[RealTimeNotificationManager] Error getting unread count: $e');
      return 0;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      log('[RealTimeNotificationManager] Error deleting notification: $e');
    }
  }

  /// Clear all notifications for a user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      log('[RealTimeNotificationManager] Cleared all notifications for user: $userId');
    } catch (e) {
      log('[RealTimeNotificationManager] Error clearing notifications: $e');
    }
  }
}
