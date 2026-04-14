import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeVisitChatMessage {
  final String id;
  final String homeVisitId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'doctor' or 'user'
  final String message;
  final DateTime timestamp;
  final String messageType; // 'text', 'location', 'image', 'status'
  final String? locationLatitude; // For location messages
  final String? locationLongitude;
  final String? locationAddress;
  final bool isRead;
  final String? replyToMessageId;

  HomeVisitChatMessage({
    required this.id,
    required this.homeVisitId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.messageType = 'text',
    this.locationLatitude,
    this.locationLongitude,
    this.locationAddress,
    this.isRead = false,
    this.replyToMessageId,
  });

  Map<String, dynamic> toMap() {
    return {
      'homeVisitId': homeVisitId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType,
      'locationLatitude': locationLatitude,
      'locationLongitude': locationLongitude,
      'locationAddress': locationAddress,
      'isRead': isRead,
      'replyToMessageId': replyToMessageId,
    };
  }

  factory HomeVisitChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return HomeVisitChatMessage(
      id: id,
      homeVisitId: map['homeVisitId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      senderRole: map['senderRole'] ?? 'user',
      message: map['message'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      messageType: map['messageType'] ?? 'text',
      locationLatitude: map['locationLatitude']?.toString(),
      locationLongitude: map['locationLongitude']?.toString(),
      locationAddress: map['locationAddress'],
      isRead: map['isRead'] ?? false,
      replyToMessageId: map['replyToMessageId'],
    );
  }
}

class HomeVisitChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send a text message
  static Future<void> sendMessage({
    required String homeVisitId,
    required String message,
    required String senderName,
    required String senderRole,
  }) async {
    try {
      final senderId = _auth.currentUser?.uid ?? '';
      
      await _firestore
          .collection('home_visit_appointments')
          .doc(homeVisitId)
          .collection('chat_messages')
          .add({
        'homeVisitId': homeVisitId,
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'messageType': 'text',
        'isRead': false,
      });

      // Update last message timestamp
      await _firestore
          .collection('home_visit_appointments')
          .doc(homeVisitId)
          .update({
        'lastMessageTime': DateTime.now().toIso8601String(),
      });

      print('✅ Message sent for home visit: $homeVisitId');
    } catch (e) {
      print('❌ Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Send location message
  static Future<void> sendLocationMessage({
    required String homeVisitId,
    required double latitude,
    required double longitude,
    required String address,
    required String senderName,
    required String senderRole,
  }) async {
    try {
      final senderId = _auth.currentUser?.uid ?? '';
      
      await _firestore
          .collection('home_visit_appointments')
          .doc(homeVisitId)
          .collection('chat_messages')
          .add({
        'homeVisitId': homeVisitId,
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'message': '📍 Sent location: $address',
        'timestamp': DateTime.now().toIso8601String(),
        'messageType': 'location',
        'locationLatitude': latitude.toString(),
        'locationLongitude': longitude.toString(),
        'locationAddress': address,
        'isRead': false,
      });

      // Update home visit with current doctor location
      if (senderRole == 'doctor') {
        await _firestore
            .collection('home_visit_appointments')
            .doc(homeVisitId)
            .update({
          'doctorCurrentLatitude': latitude,
          'doctorCurrentLongitude': longitude,
          'doctorCurrentAddress': address,
          'doctorLocationUpdatedAt': DateTime.now().toIso8601String(),
          'lastMessageTime': DateTime.now().toIso8601String(),
        });
      }

      print('✅ Location message sent for home visit: $homeVisitId');
    } catch (e) {
      print('❌ Error sending location message: $e');
      throw Exception('Failed to send location message: $e');
    }
  }

  /// Get chat messages stream
  static Stream<List<HomeVisitChatMessage>> getChatMessages(String homeVisitId) {
    return _firestore
        .collection('home_visit_appointments')
        .doc(homeVisitId)
        .collection('chat_messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HomeVisitChatMessage.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// Mark message as read
  static Future<void> markMessageAsRead(String homeVisitId, String messageId) async {
    try {
      await _firestore
          .collection('home_visit_appointments')
          .doc(homeVisitId)
          .collection('chat_messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Error marking message as read: $e');
    }
  }

  /// Mark all messages as read
  static Future<void> markAllMessagesAsRead(String homeVisitId) async {
    try {
      final snapshot = await _firestore
          .collection('home_visit_appointments')
          .doc(homeVisitId)
          .collection('chat_messages')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print('❌ Error marking all messages as read: $e');
    }
  }

  /// Send status update message (system message)
  static Future<void> sendStatusMessage({
    required String homeVisitId,
    required String statusMessage,
  }) async {
    try {
      await _firestore
          .collection('home_visit_appointments')
          .doc(homeVisitId)
          .collection('chat_messages')
          .add({
        'homeVisitId': homeVisitId,
        'senderId': 'system',
        'senderName': 'System',
        'senderRole': 'system',
        'message': statusMessage,
        'timestamp': DateTime.now().toIso8601String(),
        'messageType': 'status',
        'isRead': false,
      });
    } catch (e) {
      print('❌ Error sending status message: $e');
    }
  }

  /// Get doctor's current location from home visit
  static Future<Map<String, dynamic>?> getDoctorCurrentLocation(
      String homeVisitId) async {
    try {
      final doc = await _firestore
          .collection('home_visit_appointments')
          .doc(homeVisitId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return {
          'latitude': double.tryParse(data?['doctorCurrentLatitude']?.toString() ?? '0'),
          'longitude': double.tryParse(data?['doctorCurrentLongitude']?.toString() ?? '0'),
          'address': data?['doctorCurrentAddress'] ?? 'Location unknown',
          'updatedAt': data?['doctorLocationUpdatedAt'],
        };
      }
      return null;
    } catch (e) {
      print('❌ Error getting doctor location: $e');
      return null;
    }
  }

  /// Stream for doctor's real-time location
  static Stream<Map<String, dynamic>?> getDoctorLocationStream(String homeVisitId) {
    return _firestore
        .collection('home_visit_appointments')
        .doc(homeVisitId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      
      final data = doc.data();
      return {
        'latitude': double.tryParse(data?['doctorCurrentLatitude']?.toString() ?? '0'),
        'longitude': double.tryParse(data?['doctorCurrentLongitude']?.toString() ?? '0'),
        'address': data?['doctorCurrentAddress'] ?? 'Location unknown',
        'updatedAt': data?['doctorLocationUpdatedAt'],
        'eta': data?['doctorEstimatedArrival'],
      };
    });
  }

  /// Get unread message count
  static Future<int> getUnreadMessageCount(String homeVisitId) async {
    try {
      final snapshot = await _firestore
          .collection('home_visit_appointments')
          .doc(homeVisitId)
          .collection('chat_messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Delete message (only for sender)
  static Future<void> deleteMessage(String homeVisitId, String messageId) async {
    try {
      await _firestore
          .collection('home_visit_appointments')
          .doc(homeVisitId)
          .collection('chat_messages')
          .doc(messageId)
          .delete();

      print('✅ Message deleted: $messageId');
    } catch (e) {
      print('❌ Error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Get chat history (for backup/export)
  static Future<List<HomeVisitChatMessage>> getChatHistory(String homeVisitId) async {
    try {
      final snapshot = await _firestore
          .collection('home_visit_appointments')
          .doc(homeVisitId)
          .collection('chat_messages')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => HomeVisitChatMessage.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('❌ Error getting chat history: $e');
      return [];
    }
  }
}
