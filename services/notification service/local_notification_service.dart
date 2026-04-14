import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  /// Show a local notification (overlay style)
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    Duration duration = const Duration(seconds: 15), // Increased from 5 to 15 seconds
  }) async {
    try {
      log('[LocalNotificationService] Showing notification: $title - $body');

      final context = navigatorKey.currentContext;
      if (context == null) {
        log('[LocalNotificationService] No context available');
        return;
      }

      // Show ScaffoldMessenger notification
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00796B),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          dismissDirection: DismissDirection.horizontal, // Allow swipe to dismiss
          action: SnackBarAction(
            label: '✕',
            textColor: Colors.white,
            onPressed: () {
              // Action to dismiss
            },
          ),
        ),
      );
    } catch (e) {
      log('[LocalNotificationService] Error showing notification: $e');
    }
  }

  /// Show a high priority notification (like an alert)
  Future<void> showHighPriorityNotification({
    required BuildContext context,
    required String title,
    required String body,
    required IconData icon,
    Color backgroundColor = const Color(0xFF00796B),
    VoidCallback? onDismiss,
  }) async {
    try {
      log('[LocalNotificationService] Showing high priority notification: $title');

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 15), // Increased from 6 to 15 seconds
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 12,
          dismissDirection: DismissDirection.horizontal,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              onDismiss?.call();
            },
          ),
        ),
      );
    } catch (e) {
      log('[LocalNotificationService] Error showing high priority notification: $e');
    }
  }

  /// Show a dialog notification
  Future<void> showDialogNotification({
    required BuildContext context,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) async {
    try {
      log('[LocalNotificationService] Showing dialog notification: $title');

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onPressed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                foregroundColor: Colors.white,
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      );
    } catch (e) {
      log('[LocalNotificationService] Error showing dialog notification: $e');
    }
  }
}
