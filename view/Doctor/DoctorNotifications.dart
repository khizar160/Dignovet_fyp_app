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
//   final Color primaryTeal = const Color(0xFF80CBC4);
//   final Color darkTeal = const Color(0xFF00796B);
//   final Color scaffoldBg = Colors.white;

//   @override
//   Widget build(BuildContext context) {
//     final doctorId = AuthService.currentUser?.uid;
//     log('Doctor ID: $doctorId');

//     if (doctorId == null) {
//       return Scaffold(
//         backgroundColor: scaffoldBg,
//         body: const Center(child: Text('Please log in as doctor')),
//       );
//     }

//     return Scaffold(
//       backgroundColor: scaffoldBg,
//       body: Column(
//         children: [
//           _buildTopHeader(),
//           Expanded(
//             child: RefreshIndicator(
//               onRefresh: () async {
//                 await Future.delayed(const Duration(seconds: 1));
//               },
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('notifications')
//                     .where('receiverId', isEqualTo: doctorId)
//                     .orderBy('createdAt', descending: true)
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   final notifications = snapshot.data!.docs;

//                   if (notifications.isEmpty) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
//                           const SizedBox(height: 16),
//                           Text(
//                             'No notifications yet',
//                             style: TextStyle(color: Colors.grey[600], fontSize: 16),
//                           ),
//                         ],
//                       ),
//                     );
//                   }

//                   return ListView.builder(
//                     padding: const EdgeInsets.only(top: 10, bottom: 80),
//                     itemCount: notifications.length,
//                     physics: const BouncingScrollPhysics(),
//                     itemBuilder: (context, index) {
//                       final notif = notifications[index].data() as Map<String, dynamic>;
//                       return _buildNotificationItem(notif, notifications[index].id);
//                     },
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTopHeader() {
//     return Container(
//       padding: const EdgeInsets.only(top: 50, bottom: 30, left: 20, right: 20),
//       decoration: BoxDecoration(
//         color: primaryTeal,
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(0),
//           bottomRight: Radius.circular(0),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back, color: Colors.white),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   const Text(
//                     'DignoVet',
//                     style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//               Row(
//                 children: const [
//                   Icon(Icons.search, color: Colors.white, size: 26),
//                   SizedBox(width: 15),
//                   Icon(Icons.notifications_none, color: Colors.white, size: 26),
//                   SizedBox(width: 15),
//                   Icon(Icons.account_circle_outlined, color: Colors.white, size: 26),
//                 ],
//               )
//             ],
//           ),
//           const SizedBox(height: 30),
//           const Center(
//             child: Text(
//               'Notifications',
//               style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: 1.2),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNotificationItem(Map<String, dynamic> data, String notifId) {
//     final bool isAppointmentRequest = data['type'] == 'appointment_request';
//     final bool isRead = data['isRead'] ?? false;

//     return GestureDetector(
//       onTap: () => _handleNotificationTap(data, notifId),
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
//         padding: const EdgeInsets.all(15),
//         decoration: BoxDecoration(
//           color: isRead ? Colors.white : primaryTeal.withOpacity(0.05),
//           borderRadius: BorderRadius.circular(15),
//           border: Border(
//             bottom: BorderSide(color: Colors.grey.shade300, width: 1),
//           ),
//           boxShadow: isRead
//               ? null
//               : [
//                   BoxShadow(
//                     color: primaryTeal.withOpacity(0.1),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               height: 60,
//               width: 60,
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: Icon(
//                 isAppointmentRequest ? Icons.event_note : Icons.notifications_outlined,
//                 color: isAppointmentRequest ? darkTeal : Colors.grey[600],
//                 size: 28,
//               ),
//             ),
//             const SizedBox(width: 15),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Text(
//                           data['title'] ?? 'Notification',
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ),
//                       Row(
//                         children: [
//                           Text(
//                             _formatTime(data['createdAt']),
//                             style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                           ),
//                           if (!isRead) ...[
//                             const SizedBox(width: 8),
//                             Container(
//                               width: 8,
//                               height: 8,
//                               decoration: BoxDecoration(
//                                 color: darkTeal,
//                                 shape: BoxShape.circle,
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     data['message'] ?? '',
//                     style: TextStyle(
//                       color: Colors.grey[700],
//                       fontSize: 14,
//                       height: 1.4,
//                     ),
//                   ),
//                   if (isAppointmentRequest) ...[
//                     const SizedBox(height: 10),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: darkTeal.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: darkTeal.withOpacity(0.3)),
//                       ),
//                       child: Text(
//                         'Tap to review appointment',
//                         style: TextStyle(
//                           color: darkTeal,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _handleNotificationTap(Map<String, dynamic> data, String notifId) async {
//     // Mark as read first
//     if (!(data['isRead'] ?? false)) {
//       await _notificationService.markAsRead(notifId);
//     }

//     if (data['type'] == 'appointment_request') {
//       await _handleAppointmentNotification(data);
//     } else {
//       // For other notification types, show a brief message
//       _showSnackBar('${data['title'] ?? 'Notification'}: ${data['message'] ?? ''}');
//     }
//   }

//   Future<void> _handleAppointmentNotification(Map<String, dynamic> data) async {
//     final appointmentId = data['appointmentId'];

//     if (appointmentId == null || appointmentId.isEmpty) {
//       _showSnackBar('Appointment information not available');
//       return;
//     }

//     try {
//       // Show loading indicator
//       _showSnackBar('Loading appointment details...', isLoading: true);

//       final appointmentDoc = await FirebaseFirestore.instance
//           .collection('appointments')
//           .doc(appointmentId)
//           .get();

//       if (!appointmentDoc.exists) {
//         _showSnackBar('Appointment not found');
//         return;
//       }

//       final appointmentData = appointmentDoc.data()!;
      
//       // Validate required fields
//       if (appointmentData['userId'] == null || appointmentData['doctorId'] == null) {
//         _showSnackBar('Invalid appointment data');
//         return;
//       }

//       final appointment = AppointmentModel.fromMap(appointmentData, appointmentDoc.id);

//       // Navigate to approval page
//       await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => AppointmentApprovalPage(appointment: appointment),
//         ),
//       );

//     } catch (e) {
//       _showSnackBar('Error loading appointment details');
//     }
//   }

//   String _formatTime(dynamic timestamp) {
//     if (timestamp == null) return '';
    
//     final DateTime dateTime = (timestamp is Timestamp)
//         ? timestamp.toDate()
//         : DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
    
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);
    
//     if (difference.inMinutes < 1) return 'now';
//     if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
//     if (difference.inHours < 24) return '${difference.inHours}h ago';
//     if (difference.inDays < 7) return '${difference.inDays}d ago';
    
//     return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
//   }

//   void _showSnackBar(String message, {bool isLoading = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             if (isLoading) ...[
//               const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//               const SizedBox(width: 12),
//             ],
//             Expanded(child: Text(message)),
//           ],
//         ),
//         duration: isLoading ? const Duration(seconds: 30) : const Duration(seconds: 3),
//       ),
//     );
//   }
// }






// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter_application_1/model/appointment_model.dart';
// // import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
// // import 'package:flutter_application_1/services/notification service/notification_service.dart';
// // import 'package:flutter_application_1/view/Doctor/Apponitment_approval_page.dart';

// // class DoctorNotificationsPage extends StatefulWidget {
// //   const DoctorNotificationsPage({super.key});

// //   @override
// //   State<DoctorNotificationsPage> createState() => _DoctorNotificationsPageState();
// // }

// // class _DoctorNotificationsPageState extends State<DoctorNotificationsPage> {
// //   final NotificationService _notificationService = NotificationService();

// //   final Color primaryTeal = const Color(0xFF80CBC4);
// //   final Color darkTeal = const Color(0xFF00796B);

// //   @override
// //   Widget build(BuildContext context) {
// //     final doctorId = AuthService.currentUser?.uid;

// //     if (doctorId == null) {
// //       return const Scaffold(
// //         body: Center(child: Text('Please log in as doctor')),
// //       );
// //     }

// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: Column(
// //         children: [
// //           _buildTopHeader(),
// //           Expanded(
// //             child: StreamBuilder<QuerySnapshot>(
// //               stream: FirebaseFirestore.instance
// //                   .collection('notifications')
// //                   .where('receiverId', isEqualTo: doctorId)
// //                   ⚠️ Make sure Firestore composite index exists
// //                   .orderBy('createdAt', descending: true)
// //                   .snapshots(),
// //               builder: (context, snapshot) {
// //                 if (snapshot.connectionState == ConnectionState.waiting) {
// //                   return const Center(child: CircularProgressIndicator());
// //                 }

// //                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// //                   return _emptyState();
// //                 }

// //                 return ListView.builder(
// //                   padding: const EdgeInsets.only(top: 10, bottom: 80),
// //                   itemCount: snapshot.data!.docs.length,
// //                   itemBuilder: (context, index) {
// //                     final data =
// //                         snapshot.data!.docs[index].data() as Map<String, dynamic>;
// //                     return _buildNotificationItem(
// //                       data,
// //                       snapshot.data!.docs[index].id,
// //                     );
// //                   },
// //                 );
// //               },
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   ---------------- HEADER ----------------
// //   Widget _buildTopHeader() {
// //     return Container(
// //       padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
// //       decoration: BoxDecoration(color: primaryTeal),
// //       child: Column(
// //         children: [
// //           Row(
// //             children: [
// //               IconButton(
// //                 icon: const Icon(Icons.arrow_back, color: Colors.white),
// //                 onPressed: () => Navigator.pop(context),
// //               ),
// //               const Text(
// //                 'Notifications',
// //                 style: TextStyle(
// //                   color: Colors.white,
// //                   fontSize: 22,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   ---------------- EMPTY STATE ----------------
// //   Widget _emptyState() {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(Icons.notifications_none, size: 70, color: Colors.grey[400]),
// //           const SizedBox(height: 16),
// //           Text(
// //             'No notifications yet',
// //             style: TextStyle(color: Colors.grey[600]),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   ---------------- NOTIFICATION ITEM ----------------
// //   Widget _buildNotificationItem(Map<String, dynamic> data, String notifId) {
// //     final bool isRead = data['isRead'] ?? false;
// //     final bool isAppointment = data['type'] == 'appointment_request';

// //     return InkWell(
// //       onTap: () => _onNotificationTap(data, notifId),
// //       child: Container(
// //         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //         padding: const EdgeInsets.all(16),
// //         decoration: BoxDecoration(
// //           color: isRead ? Colors.white : primaryTeal.withOpacity(0.07),
// //           borderRadius: BorderRadius.circular(16),
// //         ),
// //         child: Row(
// //           children: [
// //             Icon(
// //               isAppointment ? Icons.event_note : Icons.notifications,
// //               size: 32,
// //               color: darkTeal,
// //             ),
// //             const SizedBox(width: 16),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     data['title'] ?? 'Notification',
// //                     style: const TextStyle(
// //                       fontWeight: FontWeight.bold,
// //                       fontSize: 16,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 6),
// //                   Text(
// //                     data['message'] ?? '',
// //                     style: TextStyle(color: Colors.grey[700]),
// //                   ),
// //                   const SizedBox(height: 6),
// //                   Text(
// //                     _formatTime(data['createdAt']),
// //                     style: const TextStyle(fontSize: 12, color: Colors.grey),
// //                   ),
// //                   if (isAppointment) ...[
// //                     const SizedBox(height: 10),
// //                     Text(
// //                       'Tap to review appointment',
// //                       style: TextStyle(
// //                         color: darkTeal,
// //                         fontWeight: FontWeight.w600,
// //                         fontSize: 12,
// //                       ),
// //                     ),
// //                   ]
// //                 ],
// //               ),
// //             ),
// //             if (!isRead)
// //               Container(
// //                 width: 8,
// //                 height: 8,
// //                 decoration: BoxDecoration(
// //                   color: darkTeal,
// //                   shape: BoxShape.circle,
// //                 ),
// //               ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   ---------------- TAP HANDLER ----------------
// //   Future<void> _onNotificationTap(
// //       Map<String, dynamic> data, String notifId) async {
// //     ScaffoldMessenger.of(context).hideCurrentSnackBar();

// //     if (!(data['isRead'] ?? false)) {
// //       await _notificationService.markAsRead(notifId);
// //     }

// //     if (data['type'] == 'appointment_request') {
// //       await _openAppointment(data);
// //     }
// //   }

// //   ---------------- APPOINTMENT ----------------
// //   Future<void> _openAppointment(Map<String, dynamic> data) async {
// //     final appointmentId = data['appointmentId'];

// //     if (appointmentId == null) {
// //       _showSnack('Appointment data missing');
// //       return;
// //     }

// //     _showSnack('Loading appointment...', loading: true);

// //     try {
// //       final doc = await FirebaseFirestore.instance
// //           .collection('appointments')
// //           .doc(appointmentId)
// //           .get();

// //       if (!doc.exists) {
// //         _showSnack('Appointment not found');
// //         return;
// //       }

// //       if (!mounted) return;
// //       ScaffoldMessenger.of(context).hideCurrentSnackBar();

// //       final appointment =
// //           AppointmentModel.fromMap(doc.data()!, doc.id);

// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(
// //           builder: (_) =>
// //               AppointmentApprovalPage(appointment: appointment),
// //         ),
// //       );
// //     } catch (_) {
// //       _showSnack('Failed to load appointment');
// //     }
// //   }

// //   ---------------- UTILITIES ----------------
// //   String _formatTime(dynamic timestamp) {
// //     if (timestamp == null) return '';

// //     final DateTime time = timestamp is Timestamp
// //         ? timestamp.toDate()
// //         : DateTime.tryParse(timestamp.toString()) ?? DateTime.now();

// //     final diff = DateTime.now().difference(time);

// //     if (diff.inMinutes < 1) return 'now';
// //     if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
// //     if (diff.inHours < 24) return '${diff.inHours}h ago';
// //     if (diff.inDays < 7) return '${diff.inDays}d ago';

// //     return '${time.day}/${time.month}/${time.year}';
// //   }

// //   void _showSnack(String msg, {bool loading = false}) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         duration: loading
// //             ? const Duration(seconds: 30)
// //             : const Duration(seconds: 3),
// //         content: Row(
// //           children: [
// //             if (loading)
// //               const SizedBox(
// //                 width: 18,
// //                 height: 18,
// //                 child: CircularProgressIndicator(strokeWidth: 2),
// //               ),
// //             if (loading) const SizedBox(width: 12),
// //             Expanded(child: Text(msg)),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
