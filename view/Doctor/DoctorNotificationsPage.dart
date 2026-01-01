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

class _DoctorNotificationsPageState extends State<DoctorNotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final Color primaryTeal = const Color(0xFF80CBC4);
  final Color darkTeal = const Color(0xFF00796B);
  final Color scaffoldBg = Colors.white;

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
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                log('[DoctorNotificationsPage] Refresh triggered');
                await Future.delayed(const Duration(seconds: 1));
                setState(() {});
              },
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

                  if (!snapshot.hasData) {
                    log(
                      '[DoctorNotificationsPage] No data yet, showing loading indicator',
                    );
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notifications = snapshot.data!.docs;
                  log(
                    '[DoctorNotificationsPage] Notifications received: ${notifications.length} items',
                  );

                  if (notifications.isEmpty) {
                    log('[DoctorNotificationsPage] No notifications found');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 80),
                    itemCount: notifications.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final notif =
                          notifications[index].data() as Map<String, dynamic>;
                      log(
                        '[DoctorNotificationsPage] Rendering notification #$index, id=${notifications[index].id}',
                      );
                      return _buildNotificationItem(
                        notif,
                        notifications[index].id,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    log('[DoctorNotificationsPage] Building top header');
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 30, left: 20, right: 20),
      decoration: BoxDecoration(color: primaryTeal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      log('[DoctorNotificationsPage] Back button pressed');
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    'DignoVet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: const [
                  Icon(Icons.search, color: Colors.white, size: 26),
                  SizedBox(width: 15),
                  Icon(Icons.notifications_none, color: Colors.white, size: 26),
                  SizedBox(width: 15),
                  Icon(
                    Icons.account_circle_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Center(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> data, String notifId) {
    final bool isAppointmentRequest = data['type'] == 'appointment_request';
    final bool isRead = data['isRead'] ?? false;

    log(
      '[DoctorNotificationsPage] Building notification item - id=$notifId, isRead=$isRead',
    );

    return GestureDetector(
      onTap: () => _handleNotificationTap(data, notifId),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : primaryTeal.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          boxShadow: isRead
              ? null
              : [
                  BoxShadow(
                    color: primaryTeal.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(
                isAppointmentRequest
                    ? Icons.event_note
                    : Icons.notifications_outlined,
                color: isAppointmentRequest ? darkTeal : Colors.grey[600],
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
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
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatTime(data['createdAt']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          if (!isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: darkTeal,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['message'] ?? '',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (isAppointmentRequest) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleViewDetails(data),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppointmentApprovalPage(appointment: appointment),
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
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        duration: isLoading
            ? const Duration(seconds: 30)
            : const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleViewDetails(Map<String, dynamic> data) async {
    log('[DoctorNotificationsPage] View Details tapped');
    _showSnackBar('Loading appointments...', isLoading: true);
    await Future.delayed(const Duration(seconds: 2));
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DoctorAppointmentRequestsPage()),
    );
    log('[DoctorNotificationsPage] Navigated to DoctorAppointmentRequestsPage');

    // Force refresh after returning
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() {});
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