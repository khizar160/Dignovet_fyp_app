import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;

  /// Send a notification to a specific user
  Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String message,
    required String appointmentId,
    required String type, // e.g., 'appointment', 'message', etc.
    String? screenshotUrl, // Optional: For refund proof screenshots
  }) async {
    try {
      final notificationData = {
        'receiverId': receiverId,
        'title': title,
        'message': message,
        'appointmentId': appointmentId,
        'type': type,
        'isRead': false,
        'createdAt': Timestamp.now(),
      };

      // Add screenshot URL if provided (for refund notifications)
      if (screenshotUrl != null && screenshotUrl.isNotEmpty) {
        notificationData['screenshotUrl'] = screenshotUrl;
        print('[Notification] Including screenshot: $screenshotUrl');
      }

      await _db.collection('notifications').add(notificationData);
      print('Notification sent to $receiverId: $title');
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String id) async {
    try {
      await _db.collection('notifications').doc(id).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Stream notifications for a specific user
  Stream<QuerySnapshot> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}


