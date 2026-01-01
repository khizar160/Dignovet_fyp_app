// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/view/User/ChatScreen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
// import 'package:flutter_application_1/services/notification service/notification_service.dart';

// class NotificationsPage extends StatefulWidget {
//   const NotificationsPage({super.key});

//   @override
//   State<NotificationsPage> createState() => _NotificationsPageState();
// }

// class _NotificationsPageState extends State<NotificationsPage> {
//   final NotificationService _notificationService = NotificationService();
//   // Theme Colors from your design
//   final Color primaryTeal = const Color(0xFF80CBC4); // Light Teal from Header
//   final Color darkTeal = const Color(0xFF00796B);
//   final Color scaffoldBg = Colors.white;

//   // Sample Data for Notifications
//   final List<Map<String, dynamic>> _notifications = [
//     {
//       'type': 'appointment',
//       'title': 'Appointment Approved!',
//       'desc': 'Dr. Kashif has approved your appointment for Tommy (Dog) at 04:00 PM.',
//       'time': '2m ago',
//       'isRead': false,
//       'doctorName': 'Dr. Kashif',
//     },
//     {
//       'type': 'chat',
//       'title': 'New Message from Dr. Sarah',
//       'desc': 'Please bring the previous medical reports of your cat Luna.',
//       'time': '15m ago',
//       'isRead': true,
//       'doctorName': 'Dr. Sarah',
//     },
//     {
//       'type': 'system',
//       'title': 'Medicine Reminder',
//       'desc': 'It\'s time to give the second dose of Multivitamins to Max.',
//       'time': '1h ago',
//       'isRead': true,
//       'doctorName': '',
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final userId = AuthService.currentUser?.uid;

//     return Scaffold(
//       backgroundColor: scaffoldBg,
//       // Custom Top Header matching your screenshot
//       body: Column(
//         children: [
//           _buildTopHeader(),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('notifications')
//                   .where('receiverId', isEqualTo: userId)
//                   .orderBy('createdAt', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
//                 final notifications = snapshot.data!.docs;
//                 if (notifications.isEmpty) return const Center(child: Text('No notifications'));
//                 return ListView.builder(
//                   padding: const EdgeInsets.only(top: 10, bottom: 80),
//                   itemCount: notifications.length,
//                   physics: const BouncingScrollPhysics(),
//                   itemBuilder: (context, index) {
//                     final notif = notifications[index].data() as Map<String, dynamic>;
//                     return _buildNotificationItem(notif, notifications[index].id);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       // bottomNavigationBar: _buildBottomNav(),
//     );
//   }

//   // --- Header Section (Matching Image) ---
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

//   // --- Notification Card ---
//   Widget _buildNotificationItem(Map<String, dynamic> data, String notifId) {
//     bool isApproved = data['type'] == 'appointment_approved';
//     bool isDeclined = data['type'] == 'appointment_declined';

//     return GestureDetector(
//       onTap: () async {
//         if (!data['isRead']) {
//           await _notificationService.markAsRead(notifId);
//         }
//       },
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
//         padding: const EdgeInsets.all(15),
//         decoration: BoxDecoration(
//           color: data['isRead'] ? Colors.white : Colors.teal.withOpacity(0.05),
//           borderRadius: BorderRadius.circular(15),
//           border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
//       ),
//       child: Column(
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Icon Placeholder (Square like your image)
//               Container(
//                 height: 60,
//                 width: 60,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[200],
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey.shade400),
//                 ),
//                 child: Icon(
//                   isApproved ? Icons.event_available : isDeclined ? Icons.event_busy : Icons.notifications_active_outlined,
//                   color: isApproved ? Colors.green : isDeclined ? Colors.red : Colors.grey[600],
//                   size: 30,
//                 ),
//               ),
//               const SizedBox(width: 15),
//               // Text Content
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                         Text(_formatTime(data['createdAt']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
//                       ],
//                     ),
//                     const SizedBox(height: 5),
//                     Text(
//                       data['message'],
//                       style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.3),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           // --- Interactive Chat Button for Approved Appointments ---
//           if (isApproved)
//             Padding(
//               padding: const EdgeInsets.only(top: 15, left: 75),
//               child: Row(
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: () async {
//                       // Get doctor info from appointment
//                       final appointmentDoc = await FirebaseFirestore.instance.collection('appointments').doc(data['appointmentId']).get();
//                       if (appointmentDoc.exists) {
//                         final appointment = appointmentDoc.data()!;
//                         final doctorDoc = await FirebaseFirestore.instance.collection('users').doc(appointment['doctorId']).get();
//                         if (doctorDoc.exists) {
//                           final doctor = doctorDoc.data()!;
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => ChatScreen(
//                               receiverId: appointment['doctorId'],
//                               receiverName: doctor['name'],
//                               receiverImage: doctor['imageUrl'] ?? '',
//                               isOnline: true,
//                             )),
//                           );
//                         }
//                       }
//                     },
//                     icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
//                     label: const Text("Chat with Doctor"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: darkTeal,
//                       foregroundColor: Colors.white,
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     ),
//   );
// }

//   String _formatTime(Timestamp? timestamp) {
//     if (timestamp == null) return '';
//     final now = DateTime.now();
//     final diff = now.difference(timestamp.toDate());
//     if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
//     if (diff.inHours < 24) return '${diff.inHours}h ago';
//     return '${diff.inDays}d ago';
//   }

//   // --- Bottom Nav (Matching your screenshot) ---

// }

// -----------------------Better UI-------------------------
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/view/User/ChatScreen.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:flutter_application_1/services/notification%20service/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();

  // --- Premium Theme Colors ---
  final Color darkTeal = const Color(0xFF00796B);
  final Color mediumTeal = const Color(0xFF4DB6AC);
  final Color lightTeal = const Color(0xFFE0F2F1); // Extra light for background
  final Color accentGold = const Color(0xFFFFB300); // For important highlights

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUser?.uid;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // 1. Top Decorative Background
              Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [darkTeal, mediumTeal],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    _buildCustomAppBar(languageProvider),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        key: ValueKey('user_notifications_$userId'),
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where('receiverId', isEqualTo: userId)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(color: darkTeal),
                            );
                          }

                          final notifications = snapshot.data?.docs ?? [];

                          if (notifications.isEmpty) {
                            return _buildEmptyState();
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.only(top: 25, bottom: 20),
                            itemCount: notifications.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final notifDoc = notifications[index];
                              final notif =
                                  notifDoc.data() as Map<String, dynamic>;
                              return _buildBeautifulNotifCard(
                                notif,
                                notifDoc.id,
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
        ],
      ),
    );
      },
    );
  }

  Widget _buildCustomAppBar(LanguageProvider languageProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: IconButton(
                  icon: Icon(
                    languageProvider.isUrdu ? Icons.arrow_forward : Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Text(
                languageProvider.translate('activity_center'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            languageProvider.translate('stay_updated'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeautifulNotifCard(Map<String, dynamic> data, String notifId) {
    bool isRead = data['isRead'] ?? false;
    String type = data['type'] ?? '';
    bool isApproved = type == 'appointment_approved';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : lightTeal.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRead ? Colors.grey.shade100 : mediumTeal.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isRead
                ? Colors.black.withOpacity(0.02)
                : darkTeal.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => isRead ? null : _notificationService.markAsRead(notifId),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with status indicator
                    Stack(
                      children: [
                        Container(
                          height: 55,
                          width: 55,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getIconColor(type).withOpacity(0.2),
                                _getIconColor(type).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            _getIconData(type),
                            color: _getIconColor(type),
                            size: 28,
                          ),
                        ),
                        if (!isRead)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              height: 12,
                              width: 12,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getTypeLabel(type),
                                style: TextStyle(
                                  color: _getIconColor(type),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                _formatTime(data['createdAt']),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['title'] ?? 'New Update',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['message'] ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isApproved) ...[
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [darkTeal, mediumTeal]),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _handleChatNavigation(data),
                      icon: const Icon(
                        Icons.chat_bubble_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text("Open Consultation"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Methods for UI Polish ---

  String _getTypeLabel(String type) {
    switch (type) {
      case 'appointment_approved':
        return 'APPROVED';
      case 'appointment_declined':
        return 'DECLINED';
      case 'chat':
        return 'MESSAGE';
      default:
        return 'SYSTEM';
    }
  }

  IconData _getIconData(String type) {
    if (type == 'appointment_approved') return Icons.verified_user_rounded;
    if (type == 'appointment_declined') return Icons.event_busy_rounded;
    if (type == 'chat') return Icons.forum_rounded;
    return Icons.notifications_active_rounded;
  }

  Color _getIconColor(String type) {
    if (type == 'appointment_approved') return Colors.green.shade600;
    if (type == 'appointment_declined') return Colors.red.shade600;
    if (type == 'chat') return Colors.blue.shade600;
    return darkTeal;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder Image or Lottie could go here
          Icon(Icons.notifications_none_rounded, size: 100, color: lightTeal),
          const SizedBox(height: 20),
          const Text(
            "All Caught Up!",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Your notifications will appear here",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // Same logic as before for navigation and formatting
  Future<void> _handleChatNavigation(Map<String, dynamic> data) async {
    try {
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(data['appointmentId'])
          .get();
      if (appointmentDoc.exists) {
        final appointment = appointmentDoc.data()!;
        final doctorDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(appointment['doctorId'])
            .get();
        if (doctorDoc.exists) {
          final doctor = doctorDoc.data()!;
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                receiverId: appointment['doctorId'],
                receiverName: doctor['name'],
                receiverImage: doctor['imageUrl'] ?? '',
                isOnline: true,
              ),
            ),
          );
          // Force refresh after returning from chat
          if (mounted) {
            setState(() {});
          }
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
