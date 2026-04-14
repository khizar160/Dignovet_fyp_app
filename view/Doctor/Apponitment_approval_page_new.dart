import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/model/app_user.dart';
import 'package:flutter_application_1/services/Appointment Service/appointment_services.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:flutter_application_1/services/notification service/notification_service.dart';
import 'package:flutter_application_1/services/payment_service/supabase_payment_storage.dart';
import 'package:flutter_application_1/services/consultation_service.dart';
import 'package:flutter_application_1/view/Doctor/UserProfilePage.dart';
import 'package:flutter_application_1/view/User/ChatScreen.dart';
import 'package:flutter_application_1/utils/appointment_time_parser.dart';

class AppointmentApprovalPage extends StatefulWidget {
  final AppointmentModel appointment;
  final bool readOnly;

  const AppointmentApprovalPage({
    super.key,
    required this.appointment,
    this.readOnly = false,
  });

  @override
  State<AppointmentApprovalPage> createState() =>
      _AppointmentApprovalPageState();
}

class _DeclinePayload {
  final String reasonCode;
  final String doctorMessage;

  const _DeclinePayload({
    required this.reasonCode,
    required this.doctorMessage,
  });
}

class _AppointmentApprovalPageState extends State<AppointmentApprovalPage>
    with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  final NotificationService _notificationService = NotificationService();
  final ConsultationService _consultationService = ConsultationService();
  final SupabasePaymentStorage _paymentStorage = SupabasePaymentStorage();

  final Color primaryTeal = Color(0xFF00796B);
  final Color lightTeal = Color(0xFF4DB6AC);
  final Color cardGrey = Color(0xFFF8F9FA);
  final Color darkGrey = Color(0xFF2C3E50);
  final Color scaffoldBg = Color(0xFFF5F7FA);

  AppUser? user;
  AppUser? doctor;
  Map<String, dynamic>? animalData;
  bool isLoading = true;
  String? paymentImageUrl; // Signed URL for payment screenshot
  String _currentStatus = 'pending';
  Timestamp? _declinedAt;
  String? _declineReason;
  bool _isProcessingAction = false;
  bool _isLoadingDialogVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fetchData();
    // ✅ Subscribe to real-time status updates
    _subscribeToStatusUpdates();
  }

  /// ✅ NEW: Subscribe to real-time Firestore updates
  void _subscribeToStatusUpdates() {
    FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointment.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;
        final newStatus = (data['status'] ?? 'pending').toString().toLowerCase();
        final declinedAt = data['declinedAt'] as Timestamp?;
        final declineReason = (data['declineReason'] ?? '').toString();
        
        print('[AppointmentApproval] 🔄 Real-time status update: $_currentStatus → $newStatus');
        
        if (newStatus != _currentStatus) {
          setState(() {
            _currentStatus = newStatus;
            _declinedAt = declinedAt;
            _declineReason = declineReason;
          });
        }
      }
    }, onError: (error) {
      print('[AppointmentApproval] ❌ Error subscribing to status: $error');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      print('[AppointmentApproval] Loading appointment data...');
      print('[AppointmentApproval] Payment Screenshot URL: ${widget.appointment.paymentScreenshotUrl}');
      
      // Load user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.appointment.userId)
          .get();
      if (userDoc.exists) {
        user = AppUser.fromMap(userDoc.data()!, userDoc.id);
      }

      // Load doctor data
      final currentDoctorId = AuthService.currentUser?.uid;
      if (currentDoctorId != null) {
        final doctorDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentDoctorId)
            .get();
        if (doctorDoc.exists) {
          doctor = AppUser.fromMap(doctorDoc.data()!, doctorDoc.id);
        }
      }

      // Load animal data
      final animalSnapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where('userId', isEqualTo: widget.appointment.userId)
          .where('name', isEqualTo: widget.appointment.animalName)
          .get();

      if (animalSnapshot.docs.isNotEmpty) {
        animalData = animalSnapshot.docs.first.data();
      }

      // Load signed URL for payment screenshot
      if (widget.appointment.paymentScreenshotUrl != null && 
          widget.appointment.paymentScreenshotUrl!.isNotEmpty) {
        print('[AppointmentApproval] Loading signed URL for payment screenshot...');
        paymentImageUrl = await _paymentStorage.getSignedUrlForImage(
          widget.appointment.paymentScreenshotUrl!
        );
        print('[AppointmentApproval] Signed URL loaded: $paymentImageUrl');
      } else {
        print('[AppointmentApproval] No payment screenshot URL available');
      }

      // Always get fresh appointment status to prevent stale actions.
      final latestAppointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointment.id)
          .get();
      if (latestAppointmentDoc.exists) {
        final latestData = latestAppointmentDoc.data()!;
        _currentStatus = (latestData['status'] ?? widget.appointment.status)
            .toString()
            .toLowerCase();
        _declinedAt = latestData['declinedAt'] as Timestamp?;
        _declineReason = (latestData['declineReason'] ?? '').toString();
      } else {
        _currentStatus = widget.appointment.status.toLowerCase();
        _declinedAt = widget.appointment.declinedAt;
        _declineReason = (widget.appointment.declineReason ?? '').toString();
      }

      print('[AppointmentApproval] Data loaded successfully');
      if (!mounted) return;
      setState(() => isLoading = false);
      _animationController.forward();
    } catch (e) {
      print('[AppointmentApproval] Error loading data: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar('Some data could not be loaded', isError: true);
    }
  }

  bool get _isReapprovalWindowOpen {
    if (_declinedAt == null) return false;
    final declinedAtDate = _declinedAt!.toDate();
    final now = DateTime.now();
    if (now.isBefore(declinedAtDate)) return false;
    return now.difference(declinedAtDate) <= const Duration(days: 1);
  }

  bool get _canReapproveDeclined {
    return _currentStatus == 'declined' && _isReapprovalWindowOpen;
  }

  Future<void> _approveAppointment() async {
    if (_isProcessingAction) return;
    if (widget.readOnly) {
      _showSnackBar('This appointment is read-only');
      return;
    }

    final isPendingApproval = _currentStatus == 'pending';
    if (!isPendingApproval && !_canReapproveDeclined) {
      _showSnackBar('This appointment is already $_currentStatus');
      return;
    }

    var statusUpdated = false;
    var consultationInitialized = false;
    try {
      if (mounted) {
        setState(() => _isProcessingAction = true);
      }
      _showLoadingDialog(
        isPendingApproval
            ? 'Approving appointment...'
            : 'Re-approving appointment...',
      );

      // STEP 1: Update status (critical)
      print('[AppointmentApproval] Step 1: Updating appointment status...');
      try {
        await _appointmentService.updateStatus(widget.appointment.id, 'approved');
        statusUpdated = true;
        print('[AppointmentApproval] ✅ Status updated to approved');
      } catch (e) {
        print('[AppointmentApproval] ❌ Failed to update status: $e');
        rethrow;
      }
      
      // STEP 2: Calculate and set consultation times (critical)
      print('[AppointmentApproval] Step 2: Setting up appointment for consultation...');
      try {
        final appointmentDate = widget.appointment.date.toDate();
        
        // Parse the actual slot time range to get EXACT end time (not calculated from duration)
        // E.g., "1:00 PM - 1:10 PM" → start: 1:00 PM, end: 1:10 PM
        final timeRange = parseAppointmentTimeRange(
          widget.appointment.time,
          appointmentDate: appointmentDate,
        );
        
        final startTime = timeRange['start']!;
        final endTime = timeRange['end']!;
        
        // Calculate actual duration from slot times (e.g., 1:00-1:10 = 10 minutes)
        final calculatedDuration = endTime.difference(startTime).inMinutes;
        
        final consultationStartTime = Timestamp.fromDate(startTime);
        final consultationEndTime = Timestamp.fromDate(endTime);
        
        print('[AppointmentApproval] 📝 Slot Time Range: ${widget.appointment.time}');
        print('[AppointmentApproval] ⏰ Start: ${startTime.toIso8601String()}');
        print('[AppointmentApproval] ⏰ End:   ${endTime.toIso8601String()}');
        print('[AppointmentApproval] ⏱️  Duration: ${calculatedDuration} minutes');
        
        // Update appointment with chat system fields
        // IMPORTANT: DO NOT set consultationStartTime here!
        // It will be set by the reminder scheduler when appointment actually starts
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(widget.appointment.id)
            .set({
          'reapprovedAt': FieldValue.serverTimestamp(),
          'reapprovedFromDecline': !isPendingApproval,
          'declineReason': FieldValue.delete(),
          'declineReasonText': FieldValue.delete(),
          'declinedAt': FieldValue.delete(),
          'chatStatus': 'disabled', // Chat disabled until appointment starts
          // consultationStartTime will be set by scheduler when time arrives
          'consultationEndTime': consultationEndTime, // Use ACTUAL slot end time
          'slotDuration': calculatedDuration, // Store calculated duration from slot
        }, SetOptions(merge: true));
        print('[AppointmentApproval] ✅ Appointment ready for consultation (${calculatedDuration}m slot)');
      } catch (e) {
        print('[AppointmentApproval] ⚠️ Failed to set appointment details: $e');
        // Continue - this is non-critical for UI flow
      }

      // STEP 3: Handle refunds for re-approvals (non-critical)
      if (!isPendingApproval) {
        print('[AppointmentApproval] Step 3: Cancelling pending refunds...');
        try {
          final pendingRefunds = await FirebaseFirestore.instance
              .collection('refunds')
              .where('appointmentId', isEqualTo: widget.appointment.id)
              .where('status', isEqualTo: 'pending')
              .get();

          for (final refundDoc in pendingRefunds.docs) {
            await refundDoc.reference.set({
              'status': 'cancelled',
              'cancelledAt': FieldValue.serverTimestamp(),
              'cancelReason': 'doctor_reapproved_within_24h',
            }, SetOptions(merge: true));
          }
          print('[AppointmentApproval] ✅ Pending refunds cancelled');
        } catch (e) {
          print('[AppointmentApproval] ⚠️ Refund cancellation failed: $e');
        }
      }

      // STEP 4: Initialize consultation system (non-critical)
      print('[AppointmentApproval] Step 4: Initializing consultation system...');
      if (user != null) {
        try {
          // Send approval confirmation message from doctor
          final messageId = await _consultationService.sendApprovalConfirmationMessage(
            appointment: widget.appointment,
            user: user!,
          );
          print('[AppointmentApproval] ✅ Approval message sent: $messageId');

          // Update chat permissions: user can read, doctor can send
          await _consultationService.updatePermissionOnApproval(
            appointmentId: widget.appointment.id,
            userId: widget.appointment.userId,
            doctorId: widget.appointment.doctorId,
          );
          print('[AppointmentApproval] ✅ Chat permissions updated');

          if (messageId != null) {
            // Store the message ID in appointment for tracking
            await FirebaseFirestore.instance
                .collection('appointments')
                .doc(widget.appointment.id)
                .update({
              'autoConfirmationMessageId': messageId,
            });
          }

          consultationInitialized = true;
          print('[AppointmentApproval] ✅ Consultation system fully initialized');
        } catch (e) {
          print('[AppointmentApproval] ⚠️ Consultation system init failed: $e');
          // Don't throw - core approval is done
        }
      }

      if (mounted) {
        setState(() {
          _currentStatus = 'approved';
          _declinedAt = null;
          _declineReason = null;
        });
      }

      final dateTime = widget.appointment.date.toDate();
      final formattedDate =
          "${_getDayName(dateTime.weekday)}, ${_getMonthName(dateTime.month)} ${dateTime.day}";
      final appointmentTimeStr =
          "$formattedDate at ${widget.appointment.time}";
        final bookedAt = widget.appointment.createdAt?.toDate().toLocal();
        final bookedOn = bookedAt == null
          ? 'Not recorded'
          : '${_formatTimelineDate(bookedAt)} at ${_formatClock(bookedAt)}';

      // STEP 5: Send notification to user (non-critical)
      print('[AppointmentApproval] Step 5: Sending user notification...');
      try {
        await _notificationService.sendNotification(
          receiverId: widget.appointment.userId,
          title: isPendingApproval
              ? '✅ Appointment Approved!'
              : '✅ Appointment Re-Approved!',
          message:
              isPendingApproval
              ? 'Dr. ${doctor?.name ?? "Your doctor"} has approved your appointment for ${animalData?['name'] ?? widget.appointment.animalName}.\nAppointment On: $appointmentTimeStr\nBooked On: $bookedOn'
              : 'Dr. ${doctor?.name ?? "Your doctor"} has re-approved your appointment for ${animalData?['name'] ?? widget.appointment.animalName}.\nAppointment On: $appointmentTimeStr\nBooked On: $bookedOn',
          appointmentId: widget.appointment.id,
          type: isPendingApproval ? 'appointment_approved' : 'appointment_reapproved',
        );
        print('[AppointmentApproval] ✅ User notification sent');
      } catch (e) {
        print('[AppointmentApproval] ⚠️ Notification failed: $e');
      }

      if (!mounted) return;

      _closeLoadingDialogIfVisible();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            receiverId: widget.appointment.userId,
            receiverName: user!.name,
            receiverImage: user!.imageUrl ?? '',
            isOnline: true,
            appointmentId: widget.appointment.id,
            animalName: widget.appointment.animalName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _closeLoadingDialogIfVisible();
      }
      if (mounted) {
        if (statusUpdated) {
          _showSnackBar('Appointment approved successfully. Some follow-up actions may have failed.');
        } else {
          _showSnackBar('Error approving appointment', isError: true);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  Future<void> _declineAppointment() async {
    if (_isProcessingAction) return;
    if (widget.readOnly || _currentStatus != 'pending') {
      _showSnackBar('This appointment is already $_currentStatus');
      return;
    }

    // Step 1: Show decline reason selection
    final declineReason = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cancel_outlined, color: Colors.red[700], size: 30),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Decline Appointment',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Select reason for declining:',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _buildDeclineOption(
                context: context,
                icon: Icons.report_problem_outlined,
                iconColor: Colors.red,
                title: 'Fake/Invalid Payment Screenshot',
                badge: 'No Refund',
                badgeColor: Colors.red,
                onTap: () => Navigator.pop(context, 'fake_screenshot'),
              ),
              const SizedBox(height: 12),
              _buildDeclineOption(
                context: context,
                icon: Icons.access_time_outlined,
                iconColor: Colors.orange,
                title: 'Schedule Conflict / No Time',
                badge: 'Full Refund',
                badgeColor: Colors.green,
                onTap: () => Navigator.pop(context, 'no_time'),
              ),
              const SizedBox(height: 12),
              _buildDeclineOption(
                context: context,
                icon: Icons.info_outline,
                iconColor: Colors.blue,
                title: 'Other Reason',
                badge: 'Full Refund',
                badgeColor: Colors.green,
                onTap: () => Navigator.pop(context, 'other'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (declineReason == null) return;

    final doctorMessage = await _showDoctorDeclineMessageDialog(declineReason);
    if (doctorMessage == null) return;

    final declinePayload = _DeclinePayload(
      reasonCode: declineReason,
      doctorMessage: doctorMessage,
    );

    // Step 2: Confirm with refund info
    final confirmed = await _showDeclineConfirmDialog(declinePayload);
    if (!confirmed) return;

    // Step 3: Process decline
    try {
      if (mounted) {
        setState(() => _isProcessingAction = true);
      }
      _showLoadingDialog('Processing decline...');

      final bool needsRefund = declinePayload.reasonCode != 'fake_screenshot';
      final String reasonText = _getDeclineMessage(declinePayload.reasonCode);
      final String completeReasonText = _buildProfessionalDeclineReason(
        reasonText,
        declinePayload.doctorMessage,
      );
      final appointmentOn =
          '${_formatTimelineDate(widget.appointment.date.toDate().toLocal())} at ${widget.appointment.time.trim().isEmpty ? 'Time not provided' : widget.appointment.time.trim()}';
      final bookedAt = widget.appointment.createdAt?.toDate().toLocal();
      final bookedOn = bookedAt == null
          ? 'Not recorded'
          : '${_formatTimelineDate(bookedAt)} at ${_formatClock(bookedAt)}';

      await _appointmentService.updateStatus(widget.appointment.id, 'declined');
      _currentStatus = 'declined';

      // Store decline details
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointment.id)
          .update({
        'declineReason': declinePayload.reasonCode,
        'declineReasonText': completeReasonText,
        'doctorDeclineMessage': declinePayload.doctorMessage,
        'declineCategoryText': reasonText,
        'declinedAt': Timestamp.now(),
        'refundRequired': needsRefund,
      });

      if (needsRefund && widget.appointment.paymentAmount > 0) {
        // Create refund record
        await FirebaseFirestore.instance.collection('refunds').add({
          'appointmentId': widget.appointment.id,
          'userId': widget.appointment.userId,
          'doctorId': widget.appointment.doctorId,
          'amount': widget.appointment.paymentAmount,
          'paymentMethod': 'manual', // JazzCash/EasyPaisa
          'status': 'pending',
          'reason': declinePayload.reasonCode,
          'reasonText': completeReasonText,
          'doctorDeclineMessage': declinePayload.doctorMessage,
          'createdAt': Timestamp.now(),
          'processedAt': null,
        });

        print('[Decline] ✅ Refund record created for Rs. ${widget.appointment.paymentAmount}');

        // Notify admin
        await _notifyAdminForRefund(
          reasonText: reasonText,
          doctorMessage: declinePayload.doctorMessage,
          needsRefund: true,
        );

        // Notify user about refund
        await _notificationService.sendNotification(
          receiverId: widget.appointment.userId,
          title: '💰 Refund Initiated',
          message:
              'Your appointment has been declined.\nAppointment On: $appointmentOn\nBooked On: $bookedOn\nReason: $reasonText\nDoctor note: ${declinePayload.doctorMessage}\nRefund amount: Rs. ${widget.appointment.paymentAmount.toStringAsFixed(0)} (processing time 24-48 hours).',
          appointmentId: widget.appointment.id,
          type: 'refund_initiated',
        );
      } else {
        await _notifyAdminForRefund(
          reasonText: reasonText,
          doctorMessage: declinePayload.doctorMessage,
          needsRefund: false,
        );

        await _notificationService.sendNotification(
          receiverId: widget.appointment.userId,
          title: '❌ Appointment Declined',
          message:
              'Your appointment has been declined.\nAppointment On: $appointmentOn\nBooked On: $bookedOn\nReason: $reasonText\nDoctor note: ${declinePayload.doctorMessage}\nNo refund issued due to invalid payment proof.',
          appointmentId: widget.appointment.id,
          type: 'appointment_declined',
        );
      }

      if (!mounted) return;

      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Go back
      if (mounted) {
        _showSnackBar(
          needsRefund
              ? 'Declined with detailed message. Refund will be processed.'
              : 'Declined with detailed message. No refund issued.',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      if (mounted) {
        _showSnackBar('Error declining appointment', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  Future<String?> _showDoctorDeclineMessageDialog(String reasonCode) async {
    final messageController = TextEditingController();
    final reasonText = _getDeclineMessage(reasonCode);
    String? validationError;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add Professional Message'),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(dialogContext).size.height * 0.55,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason: $reasonText',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: darkGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Write a clear message for user and admin (minimum 10 characters).',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageController,
                        maxLines: 4,
                        maxLength: 280,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          if (validationError != null) {
                            setDialogState(() => validationError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Example: Screenshot did not match transaction details. Please rebook with valid proof.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryTeal, width: 1.6),
                          ),
                          errorText: validationError,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final message = messageController.text.trim();
                    if (message.length < 10) {
                      setDialogState(() {
                        validationError =
                            'Please enter at least 10 characters for professional explanation.';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, message);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Widget _buildDeclineOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: iconColor.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor, width: 1.5),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeclineConfirmDialog(_DeclinePayload payload) async {
    final bool needsRefund = payload.reasonCode != 'fake_screenshot';
    final String reasonText = _getDeclineMessage(payload.reasonCode);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Decline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reason: $reasonText', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.45)),
              ),
              child: Text(
                'Doctor note: ${payload.doctorMessage}',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            if (needsRefund)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rs. ${widget.appointment.paymentAmount.toStringAsFixed(0)} will be refunded.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No refund - Invalid payment proof.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _buildProfessionalDeclineReason(String categoryReason, String doctorMessage) {
    return '$categoryReason. Doctor note: $doctorMessage';
  }

  String _getDeclineMessage(String reason) {
    switch (reason) {
      case 'fake_screenshot':
        return 'Invalid/fake payment screenshot';
      case 'no_time':
        return 'Schedule conflict';
      case 'other':
        return 'Personal reasons';
      default:
        return 'Declined';
    }
  }

  Future<void> _notifyAdminForRefund({
    required String reasonText,
    required String doctorMessage,
    required bool needsRefund,
  }) async {
    try {
      final appointmentOn =
          '${_formatTimelineDate(widget.appointment.date.toDate().toLocal())} at ${widget.appointment.time.trim().isEmpty ? 'Time not provided' : widget.appointment.time.trim()}';
      final bookedAt = widget.appointment.createdAt?.toDate().toLocal();
      final bookedOn = bookedAt == null
          ? 'Not recorded'
          : '${_formatTimelineDate(bookedAt)} at ${_formatClock(bookedAt)}';

      final adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Admin')
          .get();

      for (var admin in adminSnapshot.docs) {
        await _notificationService.sendNotification(
          receiverId: admin.id,
          title: needsRefund ? '💰 Manual Refund Required' : '🚫 Declined Without Refund',
          message:
              needsRefund
                  ? 'Process refund of Rs. ${widget.appointment.paymentAmount.toStringAsFixed(0)} for appointment ${widget.appointment.id}.\nAppointment On: $appointmentOn\nBooked On: $bookedOn\nReason: $reasonText\nDoctor note: $doctorMessage'
                  : 'Appointment ${widget.appointment.id} declined without refund.\nAppointment On: $appointmentOn\nBooked On: $bookedOn\nReason: $reasonText\nDoctor note: $doctorMessage',
          appointmentId: widget.appointment.id,
          type: needsRefund ? 'admin_refund_request' : 'admin_decline_notice',
        );
      }
    } catch (e) {
      print('[Refund] Error notifying admin: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryTeal, lightTeal.withOpacity(0.3), Colors.white],
              stops: const [0.0, 0.3, 0.5],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryTeal.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CircularProgressIndicator(
                            color: primaryTeal,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Loading appointment details...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryTeal, lightTeal.withOpacity(0.3), Colors.white],
            stops: const [0.0, 0.3, 0.5],
          ),
        ),
        child: Column(
          children: [
            _buildModernHeader(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: scaffoldBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusBadge(),
                          const SizedBox(height: 24),
                          _sectionLabel("Owner Information", Icons.person_rounded),
                          _buildModernUserCard(),
                          const SizedBox(height: 24),
                          _sectionLabel("Animal Details", Icons.pets_rounded),
                          _buildModernAnimalCard(),
                          const SizedBox(height: 24),
                          _sectionLabel("Appointment Details", Icons.event_note_rounded),
                          _buildModernAppointmentDetails(),
                          const SizedBox(height: 24),
                          _sectionLabel("Payment Information", Icons.payment_rounded),
                          _buildPaymentScreenshotSection(),
                          const SizedBox(height: 32),
                                    if (!widget.readOnly &&
                                        (_currentStatus == 'pending' || _canReapproveDeclined))
                            _buildActionButtons()
                          else
                            _buildReadOnlyActions(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appointment Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Verified Request',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryTeal.withOpacity(0.2), lightTeal.withOpacity(0.2)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: primaryTeal),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    // ✅ CRITICAL: Normalize status to lowercase
    final status = _currentStatus.toLowerCase().trim();
    final isApproved = status == 'approved' || status == 'active';
    final isCompleted = status == 'completed';
    final isDeclined = status == 'declined';
    final isPending = status == 'pending';
    
    print('[AppointmentApproval] 🎨 Building status badge with status: "$status"');
    
    final badgeColors = isApproved
      ? [Colors.green.shade500, Colors.green.shade700]
      : isCompleted
        ? [Colors.blue.shade500, Colors.blue.shade700]
        : isDeclined
          ? [Colors.red.shade400, Colors.red.shade600]
          : [Colors.orange.shade400, Colors.orange.shade600];
    final badgeIcon = isApproved
      ? Icons.check_circle_rounded
      : isCompleted
        ? Icons.task_alt_rounded
        : isDeclined
          ? Icons.cancel_rounded
          : Icons.schedule_rounded;
    final badgeText = isApproved
      ? 'Approved ✅'
      : isCompleted
        ? 'Completed ✅'
        : isDeclined
          ? 'Declined ❌'
          : 'Pending Approval ⏳';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: badgeColors,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: badgeColors.first.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernUserCard() {
    if (user == null) {
      return _buildPlaceholderCard("User data not available");
    }

    final hasImage = user!.imageUrl.trim().isNotEmpty;
    final hasPhone = user!.phone.trim().isNotEmpty;
    final hasEmail = user!.email.trim().isNotEmpty;
    final joinedOn = _formatJoinedDate(user!.createdAt);
    final canMessageUser = true; // 🔥 Doctor can ALWAYS message - in ALL cases

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, primaryTeal.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryTeal.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryTeal, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: primaryTeal.withOpacity(0.1),
                  backgroundImage: hasImage ? NetworkImage(user!.imageUrl) : null,
                  child: hasImage
                      ? null
                      : Text(
                          user!.name.isNotEmpty
                              ? user!.name[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: primaryTeal,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryTeal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            user!.role.toUpperCase(),
                            style: TextStyle(
                              color: primaryTeal,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: user!.online ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user!.online ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_forward_ios_rounded,
                      color: primaryTeal, size: 18),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            UserProfilePage(userId: widget.appointment.userId),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildUserInfoChip(
                icon: Icons.email_outlined,
                label: 'Email',
                value: hasEmail ? user!.email : 'Not provided',
              ),
              _buildUserInfoChip(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: hasPhone ? user!.phone : 'Not provided',
              ),
              _buildUserInfoChip(
                icon: Icons.pets_rounded,
                label: 'Pet',
                value: widget.appointment.animalName,
              ),
              _buildUserInfoChip(
                icon: Icons.event_note_rounded,
                label: 'Joined',
                value: joinedOn,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (hasPhone)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _makePhoneCall(user!.phone);
                    },
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Contact'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryTeal,
                      side: BorderSide(color: primaryTeal.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (hasPhone) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openChatWithUser,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Chat with Pet Owner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryTeal.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primaryTeal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2C3E50),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatJoinedDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildReadOnlyActions() {
    final isApproved = _currentStatus == 'approved';
    final isDeclined = _currentStatus == 'declined';
    final isReapprovalWindowClosed = isDeclined && !_isReapprovalWindowOpen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isApproved
                ? Colors.green.withOpacity(0.08)
                : isDeclined
                    ? Colors.red.withOpacity(0.08)
                    : primaryTeal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isApproved
                  ? Colors.green.withOpacity(0.4)
                  : isDeclined
                      ? Colors.red.withOpacity(0.4)
                      : primaryTeal.withOpacity(0.4),
            ),
          ),
          child: Text(
            isApproved
                ? 'Appointment already approved. You can continue chat with this user.'
                : isDeclined
                ? isReapprovalWindowClosed
                  ? 'This no-time decline is older than 24 hours and can no longer be re-approved.'
                  : 'Appointment has been declined. Details are shown for reference.'
                    : 'Appointment status has already been updated.',
            style: TextStyle(
              color: darkGrey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
        if (isApproved && user != null) ...[
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryTeal, lightTeal]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _openChatWithUser,
                child: const SizedBox(
                  height: 54,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Chat with Pet Owner',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openChatWithUser() {
    final status = _currentStatus.toLowerCase();
    final isAppointmentChatReady = status == 'approved' || status == 'active' || status == 'completed';
    
    if (!isAppointmentChatReady) {
      _showSnackBar('Chat is allowed only for approved appointments.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          receiverId: widget.appointment.userId,
          receiverName: user?.name.isNotEmpty == true ? user!.name : 'Pet Owner',
          receiverImage: user?.imageUrl ?? '',
          isOnline: true,
          appointmentId: widget.appointment.id,
          animalName: widget.appointment.animalName,
        ),
      ),
    );
  }

  Widget _buildModernAnimalCard() {
    if (animalData == null) {
      return _buildPlaceholderCard("Animal data not available");
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryTeal.withOpacity(0.3), width: 3),
              boxShadow: [
                BoxShadow(
                  color: primaryTeal.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 70,
                height: 70,
                color: primaryTeal.withOpacity(0.1),
                child: animalData!['imageUrls'] != null &&
                        (animalData!['imageUrls'] as List).isNotEmpty
                    ? Image.network(
                        animalData!['imageUrls'][0],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.pets, color: primaryTeal, size: 35);
                        },
                      )
                    : Icon(Icons.pets, color: primaryTeal, size: 35),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${animalData!['name'] ?? 'Unknown'} (${animalData!['type'] ?? 'Animal'})",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.category_rounded,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      animalData!['breed'] ?? 'Unknown Breed',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.cake_rounded, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "${animalData!['age'] ?? 'N/A'} Years Old",
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppointmentDetails() {
    final appointmentDate = widget.appointment.date.toDate().toLocal();
    final bookedAt = widget.appointment.createdAt?.toDate().toLocal();
    final appointmentOn =
        '${_formatTimelineDate(appointmentDate)}  •  ${widget.appointment.time.trim().isEmpty ? 'Time not provided' : widget.appointment.time.trim()}';
    final bookedOn = bookedAt == null
        ? 'Not recorded'
        : '${_formatTimelineDate(bookedAt)}  •  ${_formatClock(bookedAt)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _detailRow(
            Icons.calendar_today_rounded,
            'Appointment On',
            appointmentOn,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _detailRow(
            Icons.schedule_send_rounded,
            'Booked On',
            bookedOn,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _detailRow(
            Icons.medical_services_rounded,
            "Reason for Visit",
            widget.appointment.problem,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryTeal.withOpacity(0.15), lightTeal.withOpacity(0.15)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryTeal, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isReapproval = _canReapproveDeclined;

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryTeal, lightTeal],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryTeal.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _approveAppointment,
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 26),
                      SizedBox(width: 12),
                      Text(
                        isReapproval ? "Re-Approve Appointment" : "Approve Appointment",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!isReapproval) ...[
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.shade400, width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _declineAppointment,
                  child: Container(
                    height: 60,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel_rounded,
                            color: Colors.red.shade600, size: 26),
                        const SizedBox(width: 12),
                        Text(
                          "Decline Request",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceholderCard(String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildPaymentScreenshotSection() {
    // Check if we have a valid payment screenshot URL
    final hasValidUrl = paymentImageUrl != null && paymentImageUrl!.isNotEmpty;
    
    print('[PaymentSection] Has Valid URL: $hasValidUrl');
    if (hasValidUrl) {
      print('[PaymentSection] Display URL: $paymentImageUrl');
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryTeal.withOpacity(0.15), lightTeal.withOpacity(0.15)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long_rounded, color: primaryTeal, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Screenshot',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${widget.appointment.paymentAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasValidUrl)
            Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _showFullScreenImage(paymentImageUrl!),
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: primaryTeal.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            paymentImageUrl!,
                            fit: BoxFit.cover,
                            headers: const {
                              'Cache-Control': 'no-cache',
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                print('[PaymentScreenshot] ✅ Image loaded successfully');
                                return child;
                              }
                              final progress = loadingProgress.expectedTotalBytes != null
                                  ? (loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes! * 100).toStringAsFixed(0)
                                  : 'Loading';
                              print('[PaymentScreenshot] Loading: $progress%');
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: primaryTeal,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Loading image... $progress%',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('[PaymentScreenshot] ❌ ERROR: $error');
                              print('[PaymentScreenshot] URL: $paymentImageUrl');
                              print('[PaymentScreenshot] StackTrace: $stackTrace');
                              
                              return Container(
                                color: Colors.red.shade50,
                                child: Center(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error_outline, 
                                          size: 60, 
                                          color: Colors.red[400]
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Failed to Load Image',
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          error.toString(),
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              isLoading = true;
                                            });
                                            _fetchData();
                                          },
                                          icon: const Icon(Icons.refresh, size: 18),
                                          label: const Text('Retry'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryTeal,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.zoom_in, color: Colors.white, size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tap to view',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Payment Screenshot',
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The user has not uploaded a payment screenshot yet.',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  headers: const {
                    'Cache-Control': 'no-cache',
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('[FullScreenImage] Error: $error');
                    print('[FullScreenImage] URL: $imageUrl');
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, 
                            size: 60, 
                            color: Colors.white
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load image',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check internet connection',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoadingDialog(String message) {
    _isLoadingDialogVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryTeal),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    ).then((_) {
      _isLoadingDialogVisible = false;
    });
  }

  void _closeLoadingDialogIfVisible() {
    if (!_isLoadingDialogVisible || !mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
    _isLoadingDialogVisible = false;
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        _showSnackBar('📞 Initiating call to $phoneNumber');
      } else {
        _showSnackBar('Cannot make calls on this device', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error initiating call: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String _formatTimelineDate(DateTime date) {
    return '${_getDayName(date.weekday)}, ${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  DateTime _combineAppointmentDateAndTime(DateTime date, String timeText) {
    var normalized = timeText.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Handle time ranges like "2:00 PM - 2:30 PM" or "10:00-11:00"
    // Extract just the START time
    if (normalized.contains(' - ')) {
      normalized = normalized.split(' - ')[0].trim();
    } else if (normalized.contains('-') && !normalized.startsWith('-')) {
      // Handle "10:00-11:00" but not negative numbers
      final parts = normalized.split('-');
      if (parts.length >= 2 && parts[0].trim().isNotEmpty) {
        normalized = parts[0].trim();
      }
    }

    // Handles values like "09:00 AM", "9:00 PM"
    final twelveHour = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$');
    final twelveHourMatch = twelveHour.firstMatch(normalized);
    if (twelveHourMatch != null) {
      int hour = int.parse(twelveHourMatch.group(1)!);
      final minute = int.parse(twelveHourMatch.group(2)!);
      final meridiem = twelveHourMatch.group(3)!.toUpperCase();

      if (hour < 1 || hour > 12 || minute < 0 || minute > 59) {
        throw FormatException('Invalid appointment time: $timeText');
      }

      if (hour == 12) hour = 0;
      if (meridiem == 'PM') hour += 12;

      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    // Handles values like "14:30"
    final twentyFourHour = RegExp(r'^(\d{1,2}):(\d{2})$');
    final twentyFourHourMatch = twentyFourHour.firstMatch(normalized);
    if (twentyFourHourMatch != null) {
      final hour = int.parse(twentyFourHourMatch.group(1)!);
      final minute = int.parse(twentyFourHourMatch.group(2)!);

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        throw FormatException('Invalid appointment time: $timeText');
      }

      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    throw FormatException('Unsupported appointment time format: $timeText');
  }

  String _formatClock(DateTime date) {
    final hour24 = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final isPm = hour24 >= 12;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final meridiem = isPm ? 'PM' : 'AM';
    return '$hour12:$minute $meridiem';
  }
}
