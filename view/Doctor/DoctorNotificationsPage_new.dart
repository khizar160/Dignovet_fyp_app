import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:flutter_application_1/services/notification service/notification_service.dart';
import 'package:flutter_application_1/view/Doctor/Apponitment_approval_page.dart';
import 'package:flutter_application_1/view/Doctor/DoctorAppointmentRequests.dart';

class DoctorNotificationsPage extends StatefulWidget {
  const DoctorNotificationsPage({super.key});

  @override
  State<DoctorNotificationsPage> createState() =>
      _DoctorNotificationsPageState();
}

class _DoctorNotificationsPageState extends State<DoctorNotificationsPage>
    with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      backgroundColor: primaryTeal,
      body: Column(
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
                child: RefreshIndicator(
                  onRefresh: () async {
                    log('[DoctorNotificationsPage] Refresh triggered');
                    await Future.delayed(const Duration(milliseconds: 500));
                    setState(() {});
                  },
                  color: primaryTeal,
                  child: StreamBuilder<QuerySnapshot>(
                    key: ValueKey('doctor_notifications_$doctorId'),
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .where('receiverId', isEqualTo: doctorId)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      log(
                        '[DoctorNotificationsPage] StreamBuilder snapshot state = ${snapshot.connectionState}',
                      );

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: primaryTeal),
                        );
                      }

                      if (snapshot.hasError) {
                        return _buildErrorState();
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        log('[DoctorNotificationsPage] No notifications found');
                        return _buildEmptyState();
                      }

                      final notifications = snapshot.data!.docs;
                      log(
                        '[DoctorNotificationsPage] Notifications received: ${notifications.length} items',
                      );

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: notifications.length,
                        physics: const BouncingScrollPhysics(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    log('[DoctorNotificationsPage] Building modern header');
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                const SizedBox(width: 15),
                const Text(
                  'DignoVet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
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
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay updated with your appointments',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernNotificationCard(
    Map<String, dynamic> data,
    String notifId,
    int index,
  ) {
    final bool isAppointmentRequest = data['type'] == 'appointment_request';
    final bool isRead = data['isRead'] ?? false;

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
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isRead
                ? null
                : Border.all(
                    color: primaryTeal.withOpacity(0.3),
                    width: 2,
                  ),
            boxShadow: [
              BoxShadow(
                color: isRead
                    ? Colors.black.withOpacity(0.04)
                    : primaryTeal.withOpacity(0.15),
                blurRadius: isRead ? 8 : 15,
                offset: Offset(0, isRead ? 2 : 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAppointmentRequest
                            ? [primaryTeal, lightTeal]
                            : [Colors.grey.shade400, Colors.grey.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (isAppointmentRequest
                                  ? primaryTeal
                                  : Colors.grey.shade400)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isAppointmentRequest
                          ? Icons.event_note_rounded
                          : Icons.notifications_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                data['title'] ?? 'Notification',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryTeal, lightTeal],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['message'] ?? '',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(data['createdAt']),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isAppointmentRequest) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryTeal, lightTeal],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: primaryTeal.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _handleViewDetails(data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.visibility_rounded,
                          size: 20, color: Colors.white),
                      label: const Text(
                        'View Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
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
                  color: primaryTeal,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'New appointment notifications will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 80, color: Colors.red[400]),
          const SizedBox(height: 20),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pull down to refresh',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
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
      if (mounted) setState(() {});
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

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppointmentApprovalPage(appointment: appointment),
        ),
      );
      log('[DoctorNotificationsPage] Navigated to AppointmentApprovalPage');

      if (mounted) setState(() {});
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: isLoading
            ? const Duration(seconds: 30)
            : const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleViewDetails(Map<String, dynamic> data) async {
    log('[DoctorNotificationsPage] View Details tapped');
    _showSnackBar('Loading appointments...', isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800));
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DoctorAppointmentRequestsPage()),
    );
    log('[DoctorNotificationsPage] Navigated to DoctorAppointmentRequestsPage');

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() {});
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }
}
