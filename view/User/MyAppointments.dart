// import 'dart:developer';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/model/appointment_model.dart';
// import 'package:flutter_application_1/services/Appointment Service/appointment_services.dart';
// import 'package:flutter_application_1/view/User/ChatScreen.dart';

// class MyAppointmentsPage extends StatefulWidget {
//   const MyAppointmentsPage({super.key});

//   @override
//   State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
// }

// class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
//   final AppointmentService _appointmentService = AppointmentService();
//   final Color primaryTeal = const Color(0xFF80CBC4);
//   final Color darkTeal = const Color(0xFF00796B);

//   @override
//   Widget build(BuildContext context) {
//     log('[MyAppointmentsPage] build() called');

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: primaryTeal,
//         elevation: 0,
//         title: const Text(
//           "My Appointments",
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//           onPressed: () {
//             log('[MyAppointmentsPage] Back button pressed');
//             Navigator.pop(context);
//           },
//         ),
//       ),
//       body: StreamBuilder<User?>(
//         stream: FirebaseAuth.instance.authStateChanges(),
//         builder: (context, authSnapshot) {
//           // Check authentication state
//           if (authSnapshot.connectionState == ConnectionState.waiting) {
//             log('[MyAppointmentsPage] Waiting for auth state');
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!authSnapshot.hasData || authSnapshot.data == null) {
//             log('[MyAppointmentsPage] No authenticated user');
//             return const Center(child: Text('Please log in to view appointments'));
//           }

//           final userId = authSnapshot.data!.uid;
//           log('[MyAppointmentsPage] Authenticated userId: $userId');

//           // Now build the appointments stream with the authenticated user ID
//           return StreamBuilder<QuerySnapshot>(
//             stream: _appointmentService.userAppointments(userId),
//             builder: (context, snapshot) {
//               log('[MyAppointmentsPage] StreamBuilder state: ${snapshot.connectionState}');

//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 log('[MyAppointmentsPage] No data yet, showing loading indicator');
//                 return const Center(child: CircularProgressIndicator());
//               }

//               if (snapshot.hasError) {
//                 log('[MyAppointmentsPage] Error: ${snapshot.error}');
//                 return Center(child: Text('Error: ${snapshot.error}'));
//               }

//               if (!snapshot.hasData || snapshot.data == null) {
//                 log('[MyAppointmentsPage] No data in snapshot');
//                 return const Center(child: Text('No appointments yet'));
//               }

//               final appointments = snapshot.data!.docs
//                   .map((doc) => AppointmentModel.fromMap(
//                       doc.data() as Map<String, dynamic>, doc.id))
//                   .toList();

//               log('[MyAppointmentsPage] Loaded ${appointments.length} appointments');

//               // Sort by date descending
//               appointments.sort((a, b) => b.date.compareTo(a.date));

//               if (appointments.isEmpty) {
//                 log('[MyAppointmentsPage] No appointments found');
//                 return const Center(child: Text('No appointments yet'));
//               }

//               return ListView.builder(
//                 padding: const EdgeInsets.all(20),
//                 itemCount: appointments.length,
//                 itemBuilder: (context, index) {
//                   final appointment = appointments[index];
//                   log('[MyAppointmentsPage] Rendering appointment #$index: ${appointment.id}');
//                   return _buildAppointmentCard(appointment);
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildAppointmentCard(AppointmentModel appointment) {
//     log('[MyAppointmentsPage] Building appointment card: ${appointment.id}');

//     String buttonText;
//     Color buttonColor;
//     VoidCallback? onPressed;

//     switch (appointment.status) {
//       case 'pending':
//         buttonText = 'Pending';
//         buttonColor = Colors.grey;
//         onPressed = null;
//         break;
//       case 'approved':
//         buttonText = 'Chat with Doctor';
//         buttonColor = darkTeal;
//         onPressed = () async {
//           log('[MyAppointmentsPage] Chat button pressed for appointment: ${appointment.id}');
//           try {
//             final doctorDoc = await FirebaseFirestore.instance
//                 .collection('users')
//                 .doc(appointment.doctorId)
//                 .get();
//             if (doctorDoc.exists) {
//               final doctor = doctorDoc.data()!;
//               log('[MyAppointmentsPage] Navigating to ChatScreen with doctor: ${doctor['name']}');
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ChatScreen(
//                     receiverId: appointment.doctorId,
//                     receiverName: doctor['name'],
//                     receiverImage: doctor['imageUrl'] ?? '',
//                     isOnline: true,
//                   ),
//                 ),
//               );
//             } else {
//               log('[MyAppointmentsPage] Doctor document not found for id: ${appointment.doctorId}');
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Doctor information not found')),
//               );
//             }
//           } catch (e) {
//             log('[MyAppointmentsPage] Error fetching doctor: $e');
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Error: $e')),
//             );
//           }
//         };
//         break;
//       case 'declined':
//         buttonText = 'Declined';
//         buttonColor = Colors.red;
//         onPressed = null;
//         break;
//       default:
//         buttonText = 'Unknown';
//         buttonColor = Colors.grey;
//         onPressed = null;
//     }

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Animal: ${appointment.animalName}',
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text('Date: ${appointment.date.toDate().toLocal().toString().split(' ')[0]} at ${appointment.time}'),
//           Text('Problem: ${appointment.problem}'),
//           Text('Status: ${appointment.status.toUpperCase()}'),
//           const SizedBox(height: 16),
//           SizedBox(
//             width: double.infinity,
//             height: 50,
//             child: ElevatedButton(
//               onPressed: onPressed,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: buttonColor,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15)),
//               ),
//               child: Text(buttonText,
//                   style: const TextStyle(color: Colors.white, fontSize: 16)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/services/Appointment%20Service/appointment_services.dart';
import 'package:flutter_application_1/view/User/ChatScreen.dart';
import 'package:intl/intl.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  final AppointmentService _appointmentService = AppointmentService();

  // --- Theme Colors from your Dashboard ---
  final Color primaryTeal = const Color(0xFF00796B);
  final Color accentTeal = const Color(0xFF4DB6AC);
  final Color lightTeal = const Color(0xFF80CBC4);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          // Background gradient exactly like Dashboard
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryTeal, accentTeal, lightTeal],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(languageProvider),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FBFB), // Soft white background
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: _buildAppointmentsList(languageProvider),
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

  Widget _buildAppBar(LanguageProvider languageProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              languageProvider.isUrdu
                  ? Icons.arrow_forward
                  : Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              languageProvider.translate('my_appointments'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balancing for back button
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(LanguageProvider languageProvider) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (!authSnapshot.hasData) {
          return Center(
            child: Text(
              languageProvider.t(
                "Please login to continue",
                "جاری رکھنے کے لیے لاگ ان کریں",
              ),
            ),
          );
        }

        final userId = authSnapshot.data!.uid;

        return StreamBuilder<QuerySnapshot>(
          stream: _appointmentService.userAppointments(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: primaryTeal),
              );
            }

            final appointments =
                snapshot.data?.docs
                    .map(
                      (doc) => AppointmentModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList() ??
                [];

            if (appointments.isEmpty) {
              return _buildEmptyState(languageProvider);
            }

            // Sorting by date
            appointments.sort((a, b) => b.date.compareTo(a.date));

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: appointments.length,
              itemBuilder: (context, index) =>
                  _buildAppointmentCard(appointments[index], languageProvider),
            );
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    AppointmentModel appointment,
    LanguageProvider languageProvider,
  ) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (appointment.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = languageProvider.translate('approved');
        break;
      case 'declined':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = languageProvider.translate('declined');
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        statusText = languageProvider.translate('pending');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd MMM, yyyy').format(appointment.date.toDate()),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Animal Icon Container (Dashboard style)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.pets, color: primaryTeal, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.animalName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${languageProvider.t('Time', 'وقت')}: ${appointment.time}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.t("Reason for visit", "ملاقات کی وجہ") + ":",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.problem,
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),

                // Dashboard Styled Action Button
                if (appointment.status.toLowerCase() == 'approved')
                  _buildActionButton(
                    languageProvider.translate('chat_with_doctor'),
                    Icons.chat_bubble_outline,
                    () => _handleChatNavigation(appointment),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Text(
                        appointment.status.toLowerCase() == 'pending'
                            ? languageProvider.t(
                                "Waiting for Approval",
                                "منظوری کا انتظار ہے",
                              )
                            : languageProvider.t(
                                "Appointment Declined",
                                "ملاقات مسترد",
                              ),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
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
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(colors: [primaryTeal, accentTeal]),
          boxShadow: [
            BoxShadow(
              color: primaryTeal.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider languageProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 80, color: primaryTeal.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            languageProvider.t("No appointments found", "کوئی ملاقات نہیں ملی"),
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChatNavigation(AppointmentModel appointment) async {
    try {
      final doctorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(appointment.doctorId)
          .get();
      if (doctorDoc.exists && mounted) {
        final doctor = doctorDoc.data()!;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              receiverId: appointment.doctorId,
              receiverName: doctor['name'],
              receiverImage: doctor['imageUrl'] ?? '',
              isOnline: true,
            ),
          ),
        );
      }
    } catch (e) {
      log('Error: $e');
    }
  }
}
