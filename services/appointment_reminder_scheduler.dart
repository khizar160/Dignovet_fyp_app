import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/helpers/appointment_status_helper.dart';
import 'package:flutter_application_1/services/consultation_service.dart';
import 'package:flutter_application_1/services/notification%20service/notification_service.dart';
import 'package:flutter_application_1/utils/time_parser.dart';
import 'package:flutter_application_1/utils/appointment_time_parser.dart';

/// Manages periodic checks for appointment reminders, timing, and auto-start
/// This should be initialized when the app starts and kept alive in background
class AppointmentReminderScheduler {
  final ConsultationService _consultationService = ConsultationService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Timer? _reminderTimer;
  Timer? _appointmentStartTimer;
  final Duration checkInterval = const Duration(minutes: 1); // Check every 1 minute for accuracy
  final Duration appointmentStartCheckInterval = const Duration(seconds: 30); // Frequent check for auto-start

  /// Start the background reminder scheduler
  /// Call this from your main app initialization
  void start() {
    print('[ReminderScheduler] ⏰ Starting appointment reminder & auto-start scheduler...');
    
    // Run first check immediately
    _checkAndSendReminders();
    _checkAndAutoStartAppointments();
    _checkAndAutoCompleteAppointments();
    
    // Run periodic reminder checks
    _reminderTimer = Timer.periodic(checkInterval, (_) {
      _checkAndSendReminders();
      _checkAndAutoCompleteAppointments();
    });

    // Run appointment start checks frequently
    _appointmentStartTimer = Timer.periodic(appointmentStartCheckInterval, (_) {
      _checkAndAutoStartAppointments();
    });

    print('[ReminderScheduler] ✅ Scheduler running with 1-min & 30-sec intervals');
  }

  /// Stop the scheduler
  void stop() {
    _reminderTimer?.cancel();
    _appointmentStartTimer?.cancel();
    print('[ReminderScheduler] ⏹️ Scheduler stopped');
  }

  /// Check for appointments that need reminders
  /// 1. 15-minute before appointment
  /// 2. Appointment has ended
  Future<void> _checkAndSendReminders() async {
    try {
      // Send 15-minute reminders
      await _consultationService.schedule15MinReminderNotifications();
      
      // Notify when appointments have ended
      await _consultationService.checkAndNotifyAppointmentEnded();
      
    } catch (e) {
      print('[ReminderScheduler] ❌ Error in reminder check: $e');
    }
  }

  /// Check if any approved appointments should start NOW
  /// Auto-starts appointments when current time >= scheduled appointment time
  /// Both user and doctor get notification
  Future<void> _checkAndAutoStartAppointments() async {
    try {
      final now = DateTime.now();
      final currentUser = FirebaseAuth.instance.currentUser;

      // Only run if user is authenticated (required for permission check)
      if (currentUser == null) {
        print('[ReminderScheduler] ⚠️ Skipping auto-start check: No authenticated user');
        return;
      }

      final currentUserId = currentUser.uid;

      // Query 1: Appointments where current user is the patient
      final userAppointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'approved')
          .where('consultationStartTime', isEqualTo: null)
          .limit(50)
          .get();

      // Query 2: Appointments where current user is the doctor
      final doctorAppointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'approved')
          .where('consultationStartTime', isEqualTo: null)
          .limit(50)
          .get();

      // Combine results (avoiding duplicates)
      final appointmentIds = <String>{};
      final allDocs = <QueryDocumentSnapshot>[];
      
      for (var doc in userAppointmentsSnapshot.docs) {
        if (appointmentIds.add(doc.id)) {
          allDocs.add(doc);
        }
      }
      
      for (var doc in doctorAppointmentsSnapshot.docs) {
        if (appointmentIds.add(doc.id)) {
          allDocs.add(doc);
        }
      }

      final userAppointments = allDocs;

      for (var doc in userAppointments) {
        final appointmentData = doc.data() as Map<String, dynamic>;
        
        try {
          // Parse appointment time safely
          final appointmentDate = (appointmentData['date'] as Timestamp?)?.toDate();
          final timeString = appointmentData['time'] as String?;

          if (appointmentDate == null || timeString == null) {
            print('[ReminderScheduler] ⚠️ Skipping appointment ${doc.id}: missing date or time');
            continue;
          }

          // Use TimeParser for safe parsing
          final scheduledTime = TimeParser.createDateTime(appointmentDate, timeString);
          
          if (scheduledTime == null) {
            print('[ReminderScheduler] ⚠️ Skipping appointment ${doc.id}: invalid time format "$timeString"');
            continue;
          }

          // If current time is at or past appointment time (exact comparison, no buffer)
          if (now.isAfter(scheduledTime) || now.isAtSameMomentAs(scheduledTime)) {
            // DEBUG: Log exact times to identify any early-start buffer
            final differenceInSeconds = now.difference(scheduledTime).inSeconds;
            print('[ReminderScheduler] 📊 TIME COMPARISON DEBUG:');
            print('[ReminderScheduler]   Scheduled: ${scheduledTime.toIso8601String()}');
            print('[ReminderScheduler]   Now:       ${now.toIso8601String()}');
            print('[ReminderScheduler]   Diff:      ${differenceInSeconds}s (${(differenceInSeconds / 60).toStringAsFixed(2)} min)');
            
            // ONLY start if we're at or AFTER scheduled time (no early buffer)
            if (differenceInSeconds < 0) {
              print('[ReminderScheduler] ❌ BLOCKED: Appointment is ${(-differenceInSeconds / 60).toStringAsFixed(2)} minutes IN THE FUTURE');
              continue;
            }
            
            print('[ReminderScheduler] 🚀 Auto-starting appointment: ${doc.id}');
            
            // ⚠️ CRITICAL: Use stored consultationEndTime if available (set by doctor approval)
            // Otherwise fall back to calculating from slotDuration (for legacy appointments)
            Timestamp consultationEndTime;
            int slotDuration;
            
            final existingEndTime = appointmentData['consultationEndTime'] as Timestamp?;
            if (existingEndTime != null) {
              // Use the end time already set by doctor approval
              consultationEndTime = existingEndTime;
              slotDuration = existingEndTime.toDate().difference(scheduledTime).inMinutes;
              print('[ReminderScheduler] 📍 Using stored consultationEndTime:');
              print('[ReminderScheduler]   Start: ${scheduledTime.toIso8601String()}');
              print('[ReminderScheduler]   End:   ${existingEndTime.toDate().toIso8601String()}');
              print('[ReminderScheduler]   Duration: ${slotDuration} minutes');
            } else {
              // Fallback: Parse actual slot time range to get correct end time
              try {
                final appointmentDate = (appointmentData['date'] as Timestamp?)?.toDate() ?? scheduledTime;
                final timeRangeStr = appointmentData['time'] as String? ?? '';
                
                if (timeRangeStr.isNotEmpty) {
                  // Parse the actual slot range to get real end time
                  final timeRange = parseAppointmentTimeRange(timeRangeStr, appointmentDate: appointmentDate);
                  final actualEndTime = timeRange['end']!;
                  consultationEndTime = Timestamp.fromDate(actualEndTime);
                  slotDuration = actualEndTime.difference(scheduledTime).inMinutes;
                  print('[ReminderScheduler] 📍 Parsed slot end time (no stored value):');
                  print('[ReminderScheduler]   Start: ${scheduledTime.toIso8601String()}');
                  print('[ReminderScheduler]   End:   ${actualEndTime.toIso8601String()}');
                  print('[ReminderScheduler]   Duration: ${slotDuration} minutes');
                } else {
                  throw Exception('No time range found in appointment');
                }
              } catch (e) {
                // Ultimate fallback: Use default 30 minutes if parsing fails
                print('[ReminderScheduler] ⚠️ Could not parse slot time ($e), using default 30 min');
                slotDuration = 30;
                final endDateTime = scheduledTime.add(const Duration(minutes: 30));
                consultationEndTime = Timestamp.fromDate(endDateTime);
                print('[ReminderScheduler] 📍 Default end time (fallback):');
                print('[ReminderScheduler]   Start: ${scheduledTime.toIso8601String()}');
                print('[ReminderScheduler]   End:   ${endDateTime.toIso8601String()}');
                print('[ReminderScheduler]   Duration: 30 minutes (default)');
              }
            }
            
            final consultationStartTime = Timestamp.fromDate(scheduledTime);
            
            // Step 1: Update appointment to ACTIVE status
            await _firestore.collection('appointments').doc(doc.id).update({
              'status': 'active',  // Appointment is now LIVE
              'chatStatus': 'enabled',
              'consultationStartTime': consultationStartTime,
              'consultationEndTime': consultationEndTime,  // Use stored or calculated
              'autoStartedBySystem': true,
              'autoStartedAt': Timestamp.fromDate(now),
              'updatedAt': Timestamp.fromDate(now),
            });

            print('[ReminderScheduler] ✅ Appointment status: ACTIVE (Correct duration: ${slotDuration}m)');

            // Step 2: Set chat permissions - BOTH can chat
            final chatId = _generateChatId(
              appointmentData['userId'] as String? ?? '',
              appointmentData['doctorId'] as String? ?? '',
            );

            await _firestore.collection('chat_permissions').doc(doc.id).set({
              'appointmentId': doc.id,
              'chatId': chatId,
              'userId': appointmentData['userId'],
              'doctorId': appointmentData['doctorId'],
              // User can now FULL ACCESS
              'userCanRead': true,
              'userCanSend': true,
              'userCanDelete': true,
              // Doctor FULL ACCESS (always)
              'doctorCanRead': true,
              'doctorCanSend': true,
              'doctorCanDelete': true,
              'chatStatus': 'enabled',
              'consultationStartedAt': Timestamp.fromDate(now),
              'consultationEndTime': consultationEndTime,  // Already a Timestamp, use directly
              'updatedAt': Timestamp.fromDate(now),
            }, SetOptions(merge: true));

            print('[ReminderScheduler] ✅ Chat permissions set - both can send/read');

            // Send notifications to both
            final doctorId = appointmentData['doctorId'] as String?;
            final userId = appointmentData['userId'] as String?;
            final animalName = appointmentData['animalName'] as String?;

            if (doctorId == null || userId == null) {
              print('[ReminderScheduler] ⚠️ Skipping notifications for ${doc.id}: missing user/doctor IDs');
              continue;
            }

            try {
              // Fetch names
              final userDoc = await _firestore.collection('users').doc(userId).get();
              final doctorDoc = await _firestore.collection('users').doc(doctorId).get();
              
              final userName = (userDoc.data() as Map?)?['name'] ?? 'User';
              final doctorName = (doctorDoc.data() as Map?)?['name'] ?? 'Doctor';

              // Notification to user
              await _notificationService.sendNotification(
                receiverId: userId,
                appointmentId: doc.id,
                title: '🎯 Your Appointment is Starting!',
                message: 'Consultation with Dr. $doctorName for ${animalName ?? 'your pet'} is starting now!\n\n'
                    '💬 You can now chat directly.\n'
                    'Get ready and stay connected!',
                type: 'appointment_started',
              );

              // Notification to doctor
              await _notificationService.sendNotification(
                receiverId: doctorId,
                appointmentId: doc.id,
                title: '🎯 Appointment Starting Now!',
                message: 'Consultation with $userName for ${animalName ?? 'their pet'} is starting now!\n\n'
                    '💬 User can now chat with you.\n'
                    'Start your consultation!',
                type: 'appointment_started',
              );

              print('[ReminderScheduler] ✅ Auto-start complete for: ${doc.id}');
            } catch (notificationError) {
              print('[ReminderScheduler] ⚠️ Error sending notifications: $notificationError');
            }
          }
        } catch (e) {
          print('[ReminderScheduler] ! Error processing appointment ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('[ReminderScheduler] ❌ Error checking for appointment starts: $e');
    }
  }

  /// Manually trigger a reminder check (useful for testing)
  Future<void> checkNow() async {
    print('[ReminderScheduler] 🔍 Manual check triggered');
    await _checkAndSendReminders();
    await _checkAndAutoStartAppointments();
  }

  /// Get count of pending reminders
  Future<int> getPendingReminderCount() async {
    try {
      final now = DateTime.now();
      final in15Min = now.add(const Duration(minutes: 15));
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print('[ReminderScheduler] ⚠️ getPendingReminderCount: No authenticated user');
        return 0;
      }

      final currentUserId = currentUser.uid;
      
      final query = await _firestore
          .collection('appointments')
          .where('status', isEqualTo: 'approved')
          .where('appointmentReminder15minSent', isEqualTo: false)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(in15Min))
          .limit(50)
          .get();

      // Filter to only appointments where current user is involved
      final userAppointments = query.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String?;
        final doctorId = data['doctorId'] as String?;
        return userId == currentUserId || doctorId == currentUserId;
      }).toList();
      
      return userAppointments.length;
    } catch (e) {
      print('[ReminderScheduler] ❌ Error getting pending count: $e');
      return 0;
    }
  }

  /// Get count of appointments ready to auto-start
  Future<int> getReadyToStartCount() async {
    try {
      final now = DateTime.now();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print('[ReminderScheduler] ⚠️ getReadyToStartCount: No authenticated user');
        return 0;
      }

      final currentUserId = currentUser.uid;
      
      final query = await _firestore
          .collection('appointments')
          .where('status', isEqualTo: 'approved')
          .where('consultationStartTime', isEqualTo: null)
          .limit(50)
          .get();
      
      int count = 0;
      for (var doc in query.docs) {
        try {
          final data = doc.data();
          final userId = data['userId'] as String?;
          final doctorId = data['doctorId'] as String?;
          
          // FIXED: Filter to only appointments where current user is involved
          if (userId != currentUserId && doctorId != currentUserId) {
            continue;
          }

          final appointmentDate = (data['date'] as Timestamp?)?.toDate();
          final timeString = data['time'] as String?;

          if (appointmentDate == null || timeString == null) continue;

          final scheduledTime = TimeParser.createDateTime(appointmentDate, timeString);
          if (scheduledTime != null && now.isAfter(scheduledTime)) {
            count++;
          }
        } catch (e) {
          print('[ReminderScheduler] ⚠️ Error checking appointment: $e');
        }
      }
      
      return count;
    } catch (e) {
      print('[ReminderScheduler] ❌ Error getting ready-to-start count: $e');
      return 0;
    }
  }

  /// Get count of completed but not-yet-notified appointments
  Future<int> getCompletedAppointmentsCount() async {
    try {
      final now = DateTime.now();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print('[ReminderScheduler] ⚠️ getCompletedAppointmentsCount: No authenticated user');
        return 0;
      }

      final currentUserId = currentUser.uid;
      
      final query = await _firestore
          .collection('appointments')
          .where('status', isEqualTo: 'active')
          .limit(50)
          .get();
      
      int count = 0;
      for (var doc in query.docs) {
        try {
          final data = doc.data();
          final userId = data['userId'] as String?;
          final doctorId = data['doctorId'] as String?;
          
          // FIXED: Filter to only appointments where current user is involved
          if (userId != currentUserId && doctorId != currentUserId) {
            continue;
          }

          final endTime = data['consultationEndTime'] as Timestamp?;
          if (endTime != null && endTime.toDate().isBefore(now)) {
            count++;
          }
        } catch (e) {
          print('[ReminderScheduler] ⚠️ Error processing appointment: $e');
        }
      }
      
      return count;
    } catch (e) {
      print('[ReminderScheduler] ❌ Error getting completed count: $e');
      return 0;
    }
  }

  /// Auto-complete appointments whose end time has passed
  /// Sets status to 'completed' when consultationEndTime is reached
  Future<void> _checkAndAutoCompleteAppointments() async {
    try {
      final now = DateTime.now();
      final currentUser = FirebaseAuth.instance.currentUser;

      // Only run if user is authenticated
      if (currentUser == null) {
        print('[ReminderScheduler] ⚠️ Skipping auto-complete check: No authenticated user');
        return;
      }

      final currentUserId = currentUser.uid;

      // Query 1: Appointments where current user is the patient
      final userApptsSnapshot = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: currentUserId)
          .where('status', whereIn: ['approved', 'active'])
          .limit(100)
          .get();

      // Query 2: Appointments where current user is the doctor
      final doctorApptsSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: currentUserId)
          .where('status', whereIn: ['approved', 'active'])
          .limit(100)
          .get();

      // Combine results (avoiding duplicates)
      final appointmentIds = <String>{};
      final allDocs = <QueryDocumentSnapshot>[];
      
      for (var doc in userApptsSnapshot.docs) {
        if (appointmentIds.add(doc.id)) {
          allDocs.add(doc);
        }
      }
      
      for (var doc in doctorApptsSnapshot.docs) {
        if (appointmentIds.add(doc.id)) {
          allDocs.add(doc);
        }
      }

      // Process appointments where current user is involved AND end time has passed
      for (var doc in allDocs) {
        try {
          final appointmentData = doc.data() as Map<String, dynamic>;
          
          // Extract user and doctor IDs
          final userId = appointmentData['userId'] as String?;
          final doctorId = appointmentData['doctorId'] as String?;

          // Get the appointment model
          final appointment = AppointmentModel.fromMap(appointmentData, doc.id);

          // Check if this appointment should be completed
          final endTime = appointment.consultationEndTime?.toDate();
          if (endTime == null) continue; // Skip if no end time

          // If current time has passed the end time
          if (now.isAfter(endTime)) {
            // Only complete if not already completed
            if (appointment.status.toLowerCase() != 'completed') {
              print('[ReminderScheduler] 🏁 Auto-completing appointment: ${doc.id}');
              print('[ReminderScheduler]    End time: ${endTime.toIso8601String()}');
              print('[ReminderScheduler]    Current time: ${now.toIso8601String()}');

              await _firestore.collection('appointments').doc(doc.id).update({
                'status': 'completed',
                'completedAt': FieldValue.serverTimestamp(),
                'chatStatus': 'read-only', // Chat becomes read-only after appointment ends
                'updatedAt': FieldValue.serverTimestamp(),
              });

              print('[ReminderScheduler] ✅ Appointment marked as completed: ${doc.id}');

              // Send notifications that appointment has ended
              if (userId != null && doctorId != null) {
                try {
                  final userDoc = await _firestore.collection('users').doc(userId).get();
                  final userName = (userDoc.data() as Map?)?['name'] ?? 'User';

                  // Notify user
                  await _notificationService.sendNotification(
                    receiverId: userId,
                    appointmentId: doc.id,
                    title: '✅ Consultation Completed',
                    message: 'Your consultation has ended. Thank you for using DignoVet!',
                    type: 'appointment_completed',
                  );

                  // Notify doctor
                  await _notificationService.sendNotification(
                    receiverId: doctorId,
                    appointmentId: doc.id,
                    title: '✅ Consultation Completed',
                    message: 'Your consultation with $userName has ended.',
                    type: 'appointment_completed',
                  );

                  print('[ReminderScheduler] ✅ Completion notifications sent');
                } catch (nErr) {
                  print('[ReminderScheduler] ⚠️ Error sending completion notifications: $nErr');
                }
              } else {
                print('[ReminderScheduler] ⚠️ Skipping notifications: missing userId or doctorId');
              }
            }
          }
        } catch (e) {
          print('[ReminderScheduler] ⚠️ Error checking appointment ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('[ReminderScheduler] ❌ Error in auto-complete check: $e');
    }
  }

  /// Generate consistent chat ID from user and doctor IDs
  String _generateChatId(String userId, String doctorId) {
    final ids = [userId, doctorId];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }
}

/// Global singleton instance for reminder scheduler
final appointmentReminderScheduler = AppointmentReminderScheduler();
