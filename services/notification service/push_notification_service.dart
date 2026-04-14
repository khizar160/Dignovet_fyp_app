import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/notification service/local_notification_service.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/model/home_visit_appointment_model.dart';
import 'package:flutter_application_1/view/home_visit_chat_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('[FCM] Background message received: ${message.messageId}');
  log('[FCM] Title: ${message.notification?.title}');
  log('[FCM] Body: ${message.notification?.body}');
  
  // Display notification even in background
  await LocalNotificationService.instance.showNotification(
    title: message.notification?.title ?? 'DignoVet',
    body: message.notification?.body ?? 'New notification',
    payload: message.data,
  );
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    log('[PushNotificationService] Initializing...');

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: true,
      carPlay: true,
      criticalAlert: true,
    );

    log('[PushNotificationService] Permission status: ${settings.authorizationStatus}');

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('[FCM] Foreground message received: ${message.messageId}');
      log('[FCM] Title: ${message.notification?.title}');
      log('[FCM] Body: ${message.notification?.body}');
      
      // Show notification even when app is in foreground
      LocalNotificationService.instance.showNotification(
        title: message.notification?.title ?? 'DignoVet',
        body: message.notification?.body ?? 'New notification',
        payload: message.data,
      );
    });

    // Handle notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('[FCM] Notification tapped: ${message.messageId}');
      // Handle navigation based on message data
      _handleNotificationTap(message.data);
    });

    // Check for initial message (when app is launched from notification)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      log('[FCM] App launched from notification: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage.data);
    }

    // Listen to auth changes
    _auth.authStateChanges().listen((user) async {
      if (user == null) return;
      log('[PushNotificationService] User logged in, registering FCM token');
      await _registerCurrentToken(user.uid);
    });

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((token) async {
      log('[PushNotificationService] FCM token refreshed');
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _saveToken(uid, token);
    });

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _registerCurrentToken(uid);
    }

    log('[PushNotificationService] Initialization complete');
  }

  Future<void> _registerCurrentToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        log('[PushNotificationService] Failed to get FCM token');
        return;
      }
      log('[PushNotificationService] FCM Token: $token');
      await _saveToken(uid, token);
    } catch (e) {
      log('[PushNotificationService] Error registering token: $e');
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      log('[PushNotificationService] FCM token saved for user: $uid');
    } catch (e) {
      log('[PushNotificationService] Failed to save FCM token: $e');
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    log('[PushNotificationService] Handling notification tap with data: $data');

    try {
      final appointmentId = data['appointmentId'] as String?;
      final notificationType = data['type'] as String?;

      if (appointmentId == null || notificationType == null) {
        log('[PushNotificationService] Missing appointmentId or type');
        return;
      }

      // Handle home visit notifications
      if (notificationType.contains('home_visit')) {
        log('[PushNotificationService] Routing to HomeVisitChatScreen for home visit: $appointmentId');
        _routeToHomeVisitChat(appointmentId);
      }
      // Handle regular appointment/consultation notifications
      else if (notificationType.contains('appointment') || notificationType.contains('consultation')) {
        log('[PushNotificationService] Routing to consultation chat for appointment: $appointmentId');
        // Route to regular appointment chat screen
        // This can be extended based on your appointment chat implementation
      }
      // Handle direct chat notifications
      else if (notificationType == 'chat' || notificationType.contains('message')) {
        log('[PushNotificationService] Routing based on appointment type');
        _routeToChatBasedOnAppointmentType(appointmentId);
      }
    } catch (e) {
      log('[PushNotificationService] Error handling notification tap: $e');
    }
  }

  /// Route to HomeVisitChatScreen if appointment is a home visit
  Future<void> _routeToHomeVisitChat(String appointmentId) async {
    try {
      final doc = await _firestore.collection('home_visit_appointments').doc(appointmentId).get();

      if (!doc.exists) {
        log('[PushNotificationService] Home visit appointment not found: $appointmentId');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final appointment = HomeVisitAppointmentModel.fromMap(data, appointmentId);

      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => HomeVisitChatScreen(appointment: appointment),
          ),
        );
        log('[PushNotificationService] Navigated to HomeVisitChatScreen');
      }
    } catch (e) {
      log('[PushNotificationService] Error routing to home visit chat: $e');
    }
  }

  /// Determine appointment type (home visit vs regular) and route accordingly
  Future<void> _routeToChatBasedOnAppointmentType(String appointmentId) async {
    try {
      // First check if it's a home visit
      final homeVisitDoc = await _firestore
          .collection('home_visit_appointments')
          .doc(appointmentId)
          .get();

      if (homeVisitDoc.exists) {
        log('[PushNotificationService] Found as home visit, routing to HomeVisitChatScreen');
        final data = homeVisitDoc.data() as Map<String, dynamic>;
        final appointment = HomeVisitAppointmentModel.fromMap(data, appointmentId);

        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => HomeVisitChatScreen(appointment: appointment),
            ),
          );
        }
        return;
      }

      // If not found in home_visit_appointments, it's a regular appointment
      log('[PushNotificationService] Not a home visit, would route to regular chat');
      // TODO: Route to AppointmentChatScreen or ChatScreen for regular appointments
      // navigatorKey.currentState!.push(...);
    } catch (e) {
      log('[PushNotificationService] Error routing chat: $e');
    }
  }

  /// Get FCM token for current user
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      log('[PushNotificationService] Error getting FCM token: $e');
      return null;
    }
  }
}
