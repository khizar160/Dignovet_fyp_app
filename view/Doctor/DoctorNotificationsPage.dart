import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:flutter_application_1/services/notification service/notification_service.dart';
import 'package:flutter_application_1/view/Doctor/Apponitment_approval_page_new.dart';
import 'package:flutter_application_1/view/User/ChatScreen.dart';

class DoctorNotificationsPage extends StatefulWidget {
  const DoctorNotificationsPage({super.key});

  @override
  State<DoctorNotificationsPage> createState() =>
      _DoctorNotificationsPageState();
}

class _DoctorNotificationsPageState extends State<DoctorNotificationsPage> with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final Color primaryTeal = Color(0xFF00796B);
  final Color lightTeal = Color(0xFF4DB6AC);
  final Color cardGrey = Color(0xFFF8F9FA);
  final Color darkGrey = Color(0xFF2C3E50);
  final Color scaffoldBg = Color(0xFFF5F7FA);
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  bool _isReapprovableDeclinedAppointment({
    required String status,
    required String declineReason,
    required Timestamp? declinedAt,
  }) {
    if (status != 'declined') return false;
    if (declinedAt == null) return false;
    final diff = DateTime.now().difference(declinedAt.toDate());
    return diff.inSeconds >= 0 && diff <= const Duration(days: 1);
  }

  String _formatReapproveTimeLeft(Timestamp declinedAt) {
    final expiry = declinedAt.toDate().add(const Duration(days: 1));
    final remaining = expiry.difference(DateTime.now());
    if (remaining.inSeconds <= 0) return 'Window closed';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return 'Re-approve in ${hours}h ${minutes}m';
    }
    return 'Re-approve in ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = AuthService.currentUser?.uid;
    log('[DoctorNotificationsPage] build() called - doctorId: $doctorId');

    if (doctorId == null) {
      log('[DoctorNotificationsPage] User not logged in');
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: const Center(child: Text('Please log in as doctor')),
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
        child: SafeArea(
          child: Column(
            children: [
              _buildModernHeader(),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: scaffoldBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      log('[DoctorNotificationsPage] Refresh triggered');
                      await Future.delayed(const Duration(seconds: 1));
                      setState(() {});
                    },
                    color: primaryTeal,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('notifications')
                          .where('receiverId', isEqualTo: doctorId)
                          .where('type', isEqualTo: 'appointment_request') // ✅ ONLY PENDING APPOINTMENTS
                          .snapshots(),
                      builder: (context, snapshot) {
                        log(
                          '[DoctorNotificationsPage] ✅ StreamBuilder filtering for PENDING only - state = ${snapshot.connectionState}',
                        );

                        if (!snapshot.hasData) {
                          log(
                            '[DoctorNotificationsPage] No data yet, showing loading indicator',
                          );
                          return Center(
                            child: CircularProgressIndicator(color: primaryTeal),
                          );
                        }

                        final notifications = snapshot.data!.docs;
                        // Sort by createdAt descending (temporary workaround while index builds)
                        notifications.sort((a, b) {
                          final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
                          final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
                          return bTime.compareTo(aTime);
                        });
                        log(
                          '[DoctorNotificationsPage] ✅ PENDING notifications received: ${notifications.length} items',
                        );

                        if (notifications.isEmpty) {
                          log('[DoctorNotificationsPage] ✅ No PENDING notifications - all caught up!');
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          key: PageStorageKey<String>('doctor_notifications_list'),
                          padding: const EdgeInsets.fromLTRB(20, 30, 20, 80),
                          itemCount: notifications.length,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final notif =
                                notifications[index].data() as Map<String, dynamic>;
                            log(
                              '[DoctorNotificationsPage] Rendering notification #$index, id=${notifications[index].id}',
                            );
                            return _buildModernNotificationCard(
                              notif,
                              notifications[index].id,
                              index,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    log('[DoctorNotificationsPage] Building modern header');
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  onPressed: () {
                    log('[DoctorNotificationsPage] Back button pressed');
                    Navigator.pop(context);
                  },
                ),
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search, color: Colors.white, size: 24),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stay updated with your appointments',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: primaryTeal.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkGrey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "You'll see new notifications here",
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernNotificationCard(
      Map<String, dynamic> data, String notifId, int index) {
    final bool isAppointmentRequest = data['type'] == 'appointment_request';
    final bool isRead = data['isRead'] ?? false;
    final appointmentId = data['appointmentId'] as String?;

    log(
      '[DoctorNotificationsPage] Building notification item - id=$notifId, isRead=$isRead',
    );

    if (!isAppointmentRequest || appointmentId == null) {
      return _buildSimpleNotificationCard(data, notifId, index);
    }

    // For appointment requests, fetch appointment and user details
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .get(),
      builder: (context, apptSnapshot) {
        if (apptSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(index);
        }

        if (!apptSnapshot.hasData || apptSnapshot.hasError) {
          log('[DoctorNotificationsPage] Error loading appointment: ${apptSnapshot.error}');
          return _buildSimpleNotificationCard(data, notifId, index);
        }

        final apptData = apptSnapshot.data!.data() as Map<String, dynamic>?;
        if (apptData == null) {
          return _buildSimpleNotificationCard(data, notifId, index);
        }

        final userId = apptData['userId'] as String?;
        if (userId == null || userId.isEmpty) {
          return _buildSimpleNotificationCard(data, notifId, index);
        }

        // Fetch user data
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingCard(index);
            }

            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
            final userName = userData?['name'] ?? 'Unknown';
            final userPhone = userData?['phone'] ?? 'N/A';

            log('[DoctorNotificationsPage] Data loaded - name: $userName, animal: ${apptData['animalName']}');

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () => _handleNotificationTap(data, notifId),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryTeal.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Appointment Request',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: primaryTeal,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(data['createdAt']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Patient Info Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient Information',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              userPhone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Appointment Details Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appointment Details',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDetailsInfo('Animal', apptData['animalName'] ?? 'N/A'),
                            const SizedBox(height: 6),
                            _buildDetailsInfo('Date', _formatDate(apptData['date'])),
                            const SizedBox(height: 6),
                            _buildDetailsInfo('Time', apptData['time'] ?? 'N/A'),
                            const SizedBox(height: 6),
                            _buildDetailsInfo('Type', apptData['consultationType'] ?? 'N/A'),
                            const SizedBox(height: 6),
                            _buildDetailsInfo(
                              'Amount',
                              '\$${(apptData['paymentAmount'] ?? 0).toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                      ),

                      // Problem Box (if exists)
                      if ((apptData['problem'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Problem Description',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                apptData['problem'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleViewDetails(data),
                          icon: const Icon(Icons.visibility_rounded, size: 17),
                          label: const Text('Review Request'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingCard(int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryTeal.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryTeal.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryTeal,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Loading appointment details...',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleNotificationCard(Map<String, dynamic> data, String notifId, [int index = 0]) {
    final isRead = data['isRead'] ?? false;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _handleNotificationTap(data, notifId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['title'] ?? 'Notification',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Text(
                    _formatTime(data['createdAt']),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data['message'] ?? '',
                style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = (status ?? '').toString().toLowerCase();
    if (statusStr == 'approved') return Colors.green;
    if (statusStr == 'declined') return Colors.red;
    if (statusStr == 'pending') return Colors.orange;
    return Colors.grey;
  }

  String _formatDate(dynamic dateField) {
    if (dateField is Timestamp) {
      final date = dateField.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'N/A';
  }

  Future<void> _handleNotificationTap(
    Map<String, dynamic> data,
    String notifId,
  ) async {
    log('[DoctorNotificationsPage] Notification tapped: id=$notifId');
    if (!(data['isRead'] ?? false)) {
      log('[DoctorNotificationsPage] Marking as read: id=$notifId');
      await _notificationService.markAsRead(notifId);
    }
    if (data['type'] == 'appointment_request') {
      await _handleAppointmentNotification(data);
      // Force refresh after returning from appointment details
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _handleAppointmentNotification(Map<String, dynamic> data) async {
    final appointmentId = data['appointmentId'];
    log(
      '[DoctorNotificationsPage] Handling appointment notification: appointmentId=$appointmentId',
    );

    if (appointmentId == null || appointmentId.isEmpty) {
      _showSnackBar('Appointment information not available');
      log('[DoctorNotificationsPage] Appointment info missing');
      return;
    }

    try {
      _showSnackBar('Loading appointment details...', isLoading: true);

      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        _showSnackBar('Appointment not found');
        log('[DoctorNotificationsPage] Appointment not found');
        return;
      }

      final appointmentData = appointmentDoc.data()!;
      log(
        '[DoctorNotificationsPage] Appointment data retrieved: $appointmentData',
      );

      final appointment = AppointmentModel.fromMap(
        appointmentData,
        appointmentDoc.id,
      );

      final currentStatus = (appointment.status).toLowerCase();
      final declineReason = (appointmentData['declineReason'] ?? '').toString();
      final declinedAt = appointmentData['declinedAt'] as Timestamp?;
      final canReapprove = _isReapprovableDeclinedAppointment(
        status: currentStatus,
        declineReason: declineReason,
        declinedAt: declinedAt,
      );

      final readOnly = !(currentStatus == 'pending' || canReapprove);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppointmentApprovalPage(
            appointment: appointment,
            readOnly: readOnly,
          ),
        ),
      );
      log('[DoctorNotificationsPage] Navigated to AppointmentApprovalPage');

      // Force refresh after returning
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showSnackBar('Error loading appointment details');
      log('[DoctorNotificationsPage] Error loading appointment details: $e');
    }
  }

  void _showSnackBar(String message, {bool isLoading = false}) {
    log('[DoctorNotificationsPage] Showing SnackBar: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: darkGrey,
        duration: isLoading
            ? const Duration(seconds: 30)
            : const Duration(seconds: 15), // Increased from 3 to 15 seconds
      ),
    );
  }

  Future<void> _handleViewDetails(Map<String, dynamic> data) async {
    log('[DoctorNotificationsPage] View Details tapped');
    await _handleAppointmentNotification(data);
  }

  Widget _buildAppointmentActionArea(Map<String, dynamic> data) {
    final appointmentId = data['appointmentId'] as String?;
    if (appointmentId == null || appointmentId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: const Text(
                  'Status: Syncing...',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildNotificationActionButton(
                      label: 'View Details',
                      icon: Icons.visibility_rounded,
                      onTap: () => _handleViewDetails(data),
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        final hasAppointment = snapshot.hasData && snapshot.data!.exists;
        final snapData = hasAppointment
            ? (snapshot.data!.data() ?? <String, dynamic>{})
            : <String, dynamic>{};

        final status = (snapData['status'] ?? 'pending').toString().toLowerCase();
        final declineReason = (snapData['declineReason'] ?? '').toString();
        final declinedAt = snapData['declinedAt'] as Timestamp?;

        final isPending = status == 'pending';
        final isApproved = status == 'approved';
        final isDeclined = status == 'declined';
        final canReapprove = _isReapprovableDeclinedAppointment(
          status: status,
          declineReason: declineReason,
          declinedAt: declinedAt,
        );
        final reapproveTimeText = canReapprove && declinedAt != null
            ? _formatReapproveTimeLeft(declinedAt)
            : null;

        final statusColor = canReapprove
            ? Colors.blue
            : isApproved
            ? Colors.green
            : isDeclined
                ? Colors.red
                : Colors.orange;
        final statusLabel = canReapprove
            ? 'Declined - Re-approve (24h)'
            : isApproved
            ? 'Approved'
            : isDeclined
                ? 'Declined'
                : 'Pending';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Text(
                'Status: $statusLabel',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (reapproveTimeText != null) ...[
              const SizedBox(height: 8),
              Text(
                reapproveTimeText,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNotificationActionButton(
                    label: isPending
                        ? 'Review Request'
                        : canReapprove
                            ? 'Re-Approve Now'
                            : 'View Details',
                    icon: Icons.visibility_rounded,
                    onTap: () => _handleViewDetails(data),
                    isPrimary: true,
                  ),
                ),
                if (isApproved) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildNotificationActionButton(
                      label: 'Open Chat',
                      icon: Icons.chat_bubble_rounded,
                      onTap: () => _openChatForAppointment(appointmentId),
                      isPrimary: false,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    final gradient = LinearGradient(colors: [primaryTeal, lightTeal]);

    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary ? gradient : null,
        color: isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? null : Border.all(color: primaryTeal.withOpacity(0.4)),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: primaryTeal.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: isPrimary ? Colors.white : primaryTeal,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : primaryTeal,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openChatForAppointment(String appointmentId) async {
    try {
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .get();
      if (!appointmentDoc.exists) {
        _showSnackBar('Appointment not found');
        return;
      }

      final appointmentData = appointmentDoc.data()!;
      final appointment = AppointmentModel.fromMap(appointmentData, appointmentDoc.id);
      final status = appointment.status.toLowerCase();
      final isAppointmentChatReady = status == 'approved' || status == 'active';
      
      if (!isAppointmentChatReady) {
        _showSnackBar('Chat is available after approval');
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(appointment.userId)
          .get();
      if (!userDoc.exists) {
        _showSnackBar('User details not found');
        return;
      }

      final userData = userDoc.data()!;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            receiverId: appointment.userId,
            receiverName: (userData['name'] ?? 'User').toString(),
            receiverImage: (userData['imageUrl'] ?? '').toString(),
            isOnline: true,
            appointmentId: appointment.id,
            animalName: appointment.animalName,
          ),
        ),
      );
    } catch (_) {
      _showSnackBar('Unable to open chat right now');
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}



// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/model/appointment_model.dart';
// import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
// import 'package:flutter_application_1/services/notification service/notification_service.dart';
// import 'package:flutter_application_1/view/Doctor/Apponitment_approval_page.dart';

// class DoctorNotificationsPage extends StatefulWidget {
//   const DoctorNotificationsPage({super.key});

//   @override
//   State<DoctorNotificationsPage> createState() =>
//       _DoctorNotificationsPageState();
// }

// class _DoctorNotificationsPageState extends State<DoctorNotificationsPage> {
//   final NotificationService _notificationService = NotificationService();

//   final Color primaryTeal = const Color(0xFF80CBC4);
//   final Color darkTeal = const Color(0xFF00796B);

//   @override
//   Widget build(BuildContext context) {
//     final doctorId = AuthService.currentUser?.uid;

//     if (doctorId == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please log in as doctor')),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           _buildHeader(),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('notifications')
//                   .where('receiverId', isEqualTo: doctorId)
//                   .orderBy('createdAt', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState ==
//                     ConnectionState.waiting) {
//                   return const Center(
//                       child: CircularProgressIndicator());
//                 }

//                 if (!snapshot.hasData ||
//                     snapshot.data!.docs.isEmpty) {
//                   return _emptyState();
//                 }

//                 return ListView.builder(
//                   padding:
//                       const EdgeInsets.only(top: 10, bottom: 80),
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     final data = snapshot.data!.docs[index]
//                         .data() as Map<String, dynamic>;
//                     return _notificationTile(
//                       data,
//                       snapshot.data!.docs[index].id,
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ---------------- HEADER ----------------
//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
//       color: primaryTeal,
//       child: Row(
//         children: [
//           IconButton(
//             icon:
//                 const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//           const SizedBox(width: 10),
//           const Text(
//             'Notifications',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ---------------- EMPTY ----------------
//   Widget _emptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.notifications_none,
//               size: 70, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text('No notifications yet',
//               style: TextStyle(color: Colors.grey[600])),
//         ],
//       ),
//     );
//   }

//   // ---------------- TILE ----------------
//   Widget _notificationTile(
//       Map<String, dynamic> data, String id) {
//     final bool isRead = data['isRead'] ?? false;
//     final bool isAppointment =
//         data['type'] == 'appointment_request';

//     return InkWell(
//       onTap: () =>
//           _openNotification(data, id),
//       child: Container(
//         margin:
//             const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color:
//               isRead ? Colors.white : primaryTeal.withOpacity(0.06),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               isAppointment
//                   ? Icons.event_note
//                   : Icons.notifications,
//               color: darkTeal,
//               size: 30,
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     data['title'] ?? '',
//                     style: const TextStyle(
//                         fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(data['message'] ?? '',
//                       style: TextStyle(
//                           color: Colors.grey[700])),
//                   const SizedBox(height: 6),
//                   Text(
//                     _formatTime(data['createdAt']),
//                     style: const TextStyle(
//                         fontSize: 12, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//             if (!isRead)
//               Container(
//                 width: 8,
//                 height: 8,
//                 decoration: BoxDecoration(
//                     color: darkTeal,
//                     shape: BoxShape.circle),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ---------------- OPEN ----------------
//   Future<void> _openNotification(
//       Map<String, dynamic> data, String notifId) async {
//     ScaffoldMessenger.of(context).hideCurrentSnackBar();

//     if (!(data['isRead'] ?? false)) {
//       await _notificationService.markAsRead(notifId);
//     }

//     if (data['type'] == 'appointment_request') {
//       await _openAppointment(data['appointmentId']);
//     }
//   }

//   // ---------------- APPOINTMENT ----------------
//   Future<void> _openAppointment(String? appointmentId) async {
//     if (appointmentId == null) {
//       _showSnack('Appointment not found');
//       return;
//     }

//     _showSnack('Loading appointment...', loading: true);

//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('appointments')
//           .doc(appointmentId)
//           .get();

//       if (!doc.exists) {
//         _showSnack('Appointment deleted');
//         return;
//       }

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();

//       final appointment =
//           AppointmentModel.fromMap(doc.data()!, doc.id);

//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) =>
//               AppointmentApprovalPage(appointment: appointment),
//         ),
//       );
//     } catch (_) {
//       _showSnack('Failed to load appointment');
//     }
//   }

//   // ---------------- UTIL ----------------
//   String _formatTime(Timestamp? t) {
//     if (t == null) return '';
//     final diff = DateTime.now().difference(t.toDate());
//     if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
//     if (diff.inHours < 24) return '${diff.inHours}h ago';
//     return '${diff.inDays}d ago';
//   }

//   void _showSnack(String msg, {bool loading = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         duration: loading
//             ? const Duration(seconds: 30)
//             : const Duration(seconds: 3),
//         content: Row(
//           children: [
//             if (loading)
//               const SizedBox(
//                 width: 18,
//                 height: 18,
//                 child:
//                     CircularProgressIndicator(strokeWidth: 2),
//               ),
//             if (loading) const SizedBox(width: 12),
//             Expanded(child: Text(msg)),
//           ],
//         ),
//       ),
//     );
//   }
// }
//============================================
// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/model/appointment_model.dart';
// import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
// import 'package:flutter_application_1/services/notification service/notification_service.dart';
// import 'package:flutter_application_1/view/Doctor/Apponitment_approval_page.dart';

// class DoctorNotificationsPage extends StatefulWidget {
//   const DoctorNotificationsPage({super.key});

//   @override
//   State<DoctorNotificationsPage> createState() => _DoctorNotificationsPageState();
// }

// class _DoctorNotificationsPageState extends State<DoctorNotificationsPage> {
//   final NotificationService _notificationService = NotificationService();
//   final Color primaryTeal = const Color(0xFF00796B);
//   final Color lightTeal = const Color(0xFF4DB6AC);

//   String? _currentDoctorId;

//   @override
//   void initState() {
//     super.initState();
//     _currentDoctorId = AuthService.currentUser?.uid;
//     log('[DoctorNotifications] initState - DoctorId: $_currentDoctorId');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final doctorId = AuthService.currentUser?.uid;
    
//     log('[DoctorNotifications] build() - Current DoctorId: $doctorId');

//     if (doctorId == null || doctorId.isEmpty) {
//       return Scaffold(
//         body: const Center(child: Text('Please log in as doctor')),
//       );
//     }

//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [primaryTeal, lightTeal],
//             stops: const [0.0, 0.3],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               _buildHeader(),
//               Expanded(
//                 child: Container(
//                   decoration: const BoxDecoration(
//                     color: Color(0xFFF5F7FA),
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(30),
//                       topRight: Radius.circular(30),
//                     ),
//                   ),
//                   child: RefreshIndicator(
//                     onRefresh: () async {
//                       log('[DoctorNotifications] Refresh triggered');
//                       setState(() {
//                         _currentDoctorId = AuthService.currentUser?.uid;
//                       });
//                       await Future.delayed(const Duration(milliseconds: 500));
//                     },
//                     child: StreamBuilder<QuerySnapshot>(
//                       key: ValueKey('doctor_notifications_$doctorId'),
//                       stream: FirebaseFirestore.instance
//                           .collection('notifications')
//                           .where('receiverId', isEqualTo: doctorId)
//                           .where('type', isEqualTo: 'appointment_request') // CRITICAL FIX
//                           // .orderBy('createdAt', descending: true) // COMMENTED - Create index first!
//                           .snapshots(),
//                       builder: (context, snapshot) {
//                         log('[DoctorNotifications] Stream state: ${snapshot.connectionState}');

//                         if (snapshot.connectionState == ConnectionState.waiting) {
//                           return const Center(child: CircularProgressIndicator());
//                         }

//                         if (snapshot.hasError) {
//                           log('[DoctorNotifications] Stream error: ${snapshot.error}');
//                           return Center(child: Text('Error: ${snapshot.error}'));
//                         }

//                         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                           log('[DoctorNotifications] No notifications');
//                           return _buildEmptyState();
//                         }

//                         // ADDITIONAL SAFETY CHECK: Filter on client-side too
//                         final allDocs = snapshot.data!.docs;
//                         final notifications = allDocs.where((doc) {
//                           final data = doc.data() as Map<String, dynamic>;
//                           final isForDoctor = data['receiverId'] == doctorId;
//                           final isAppointmentRequest = data['type'] == 'appointment_request';
                          
//                           if (!isForDoctor || !isAppointmentRequest) {
//                             log('[DoctorNotifications] FILTERED OUT: ${doc.id} - receiverId: ${data['receiverId']}, type: ${data['type']}');
//                           }
                          
//                           return isForDoctor && isAppointmentRequest;
//                         }).toList();

//                         log('[DoctorNotifications] ${notifications.length} valid notifications (filtered from ${allDocs.length})');

//                         if (notifications.isEmpty) {
//                           return _buildEmptyState();
//                         }

//                         return ListView.builder(
//                           padding: const EdgeInsets.all(20),
//                           physics: const AlwaysScrollableScrollPhysics(),
//                           itemCount: notifications.length,
//                           itemBuilder: (context, index) {
//                             final notif = notifications[index].data() as Map<String, dynamic>;
//                             log('[DoctorNotifications] Notification #$index - Type: ${notif['type']}, Receiver: ${notif['receiverId']}');
//                             return _buildNotificationCard(notif, notifications[index].id);
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//           const SizedBox(width: 8),
//           const Text(
//             'Appointment Requests',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               letterSpacing: -0.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return ListView(
//       padding: const EdgeInsets.all(20),
//       children: [
//         const SizedBox(height: 100),
//         Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: primaryTeal.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.event_available_rounded,
//                   size: 64,
//                   color: primaryTeal,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 'No pending requests',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF2C3E50),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'New appointment requests will appear here',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildNotificationCard(Map<String, dynamic> data, String notifId) {
//     final bool isRead = data['isRead'] ?? false;

//     return GestureDetector(
//       onTap: () => _handleNotificationTap(data, notifId),
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: isRead ? Colors.white : primaryTeal.withOpacity(0.05),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isRead ? Colors.grey[200]! : primaryTeal.withOpacity(0.3),
//             width: 1.5,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.03),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: primaryTeal.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(
//                     Icons.event_note_rounded,
//                     color: primaryTeal,
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(width: 14),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               data['title'] ?? 'New Appointment Request',
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                                 color: Color(0xFF2C3E50),
//                               ),
//                             ),
//                           ),
//                           if (!isRead)
//                             Container(
//                               width: 8,
//                               height: 8,
//                               decoration: BoxDecoration(
//                                 color: primaryTeal,
//                                 shape: BoxShape.circle,
//                               ),
//                             ),
//                         ],
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         data['message'] ?? '',
//                         style: TextStyle(
//                           color: Colors.grey[700],
//                           fontSize: 14,
//                           height: 1.4,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         _formatTime(data['createdAt']),
//                         style: TextStyle(
//                           color: Colors.grey[500],
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 14),
//             Container(
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [primaryTeal, lightTeal],
//                 ),
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: primaryTeal.withOpacity(0.3),
//                     blurRadius: 8,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: ElevatedButton.icon(
//                 onPressed: () => _handleAppointmentNotification(data),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.transparent,
//                   shadowColor: Colors.transparent,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 icon: const Icon(Icons.visibility_rounded, size: 20, color: Colors.white),
//                 label: const Text(
//                   'View Details',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 15,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _handleNotificationTap(Map<String, dynamic> data, String notifId) async {
//     log('[DoctorNotifications] Notification tapped: $notifId');
//     if (!(data['isRead'] ?? false)) {
//       await _notificationService.markAsRead(notifId);
//     }
//   }

//   Future<void> _handleAppointmentNotification(Map<String, dynamic> data) async {
//     final appointmentId = data['appointmentId'];
//     log('[DoctorNotifications] Opening appointment: $appointmentId');

//     if (appointmentId == null) {
//       _showSnackBar('Appointment information not available');
//       return;
//     }

//     try {
//       final appointmentDoc = await FirebaseFirestore.instance
//           .collection('appointments')
//           .doc(appointmentId)
//           .get();

//       if (!appointmentDoc.exists) {
//         _showSnackBar('Appointment not found');
//         return;
//       }

//       final appointment = AppointmentModel.fromMap(
//         appointmentDoc.data()!,
//         appointmentDoc.id,
//       );

//       await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => AppointmentApprovalPage(appointment: appointment),
//         ),
//       );
      
//       setState(() {});
//     } catch (e) {
//       log('[DoctorNotifications] Error: $e');
//       _showSnackBar('Error loading appointment');
//     }
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }

//   String _formatTime(Timestamp? timestamp) {
//     if (timestamp == null) return '';
//     final now = DateTime.now();
//     final diff = now.difference(timestamp.toDate());
//     if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
//     if (diff.inHours < 24) return '${diff.inHours}h ago';
//     return '${diff.inDays}d ago';
//   }
// }