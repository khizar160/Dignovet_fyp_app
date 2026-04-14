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
import 'package:flutter_application_1/services/file_download_service.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

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
      case 'active':
        statusColor = Colors.blue;
        statusIcon = Icons.phone_in_talk_rounded;
        statusText = languageProvider.t('Active', 'فعال');
        break;
      case 'completed':
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.done_all;
        statusText = languageProvider.t('Completed', 'مکمل');
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
                  "${languageProvider.t("Reason for visit", "ملاقات کی وجہ")}:",
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
                if (appointment.status.toLowerCase() == 'declined') ...[
                  const SizedBox(height: 14),
                  _buildDoctorNoteCard(appointment, languageProvider),
                ],
                const SizedBox(height: 16),

                _buildSecondaryActionButton(
                  languageProvider.t('View Details', 'تفصیل دیکھیں'),
                  Icons.timeline_rounded,
                  () => _showAppointmentDetailsSheet(appointment, languageProvider),
                ),

                const SizedBox(height: 10),

                // Dashboard Styled Action Button - Show chat for approved & active
                if (appointment.status.toLowerCase() == 'approved' ||
                    appointment.status.toLowerCase() == 'active')
                  _buildActionButton(
                    appointment.status.toLowerCase() == 'active'
                        ? languageProvider.t('Continue Chat', 'چیٹ جاری رکھیں')
                        : languageProvider.translate('chat_with_doctor'),
                    Icons.chat_bubble_outline,
                    () => _handleChatNavigation(appointment),
                  )
                else if (appointment.status.toLowerCase() == 'completed')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF4CAF50),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            languageProvider.t('Completed', 'مکمل'),
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildSecondaryActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryTeal.withOpacity(0.24), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryTeal, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: primaryTeal,
                fontWeight: FontWeight.w700,
                fontSize: 14,
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
              appointmentId: appointment.id,
              animalName: appointment.animalName,
            ),
          ),
        );
      }
    } catch (e) {
      log('Error: $e');
    }
  }

  Future<void> _showAppointmentDetailsSheet(
    AppointmentModel appointment,
    LanguageProvider languageProvider,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    Icon(Icons.event_note_rounded, color: primaryTeal),
                    const SizedBox(width: 8),
                    Text(
                      languageProvider.t('Appointment Details', 'ملاقات کی تفصیل'),
                      style: TextStyle(
                        color: primaryTeal,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _detailRow('Pet', appointment.animalName),
                _detailRow('Date', DateFormat('dd MMM, yyyy').format(appointment.date.toDate())),
                _detailRow('Time', appointment.time),
                _detailRow('Problem', appointment.problem),
                _detailRow('Status', appointment.status.toUpperCase()),
                if (appointment.status.toLowerCase() == 'declined') ...[
                  const SizedBox(height: 10),
                  _buildDoctorNoteCard(
                    appointment,
                    languageProvider,
                    compact: false,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  languageProvider.t('Prescription Timeline', 'نسخہ ٹائم لائن'),
                  style: TextStyle(
                    color: primaryTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPrescriptionTimeline(appointment.id),
                const SizedBox(height: 16),
                Text(
                  languageProvider.t('Prescriptions', 'نسخے'),
                  style: TextStyle(
                    color: primaryTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAppointmentPrescriptionList(appointment),
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorNoteCard(
    AppointmentModel appointment,
    LanguageProvider languageProvider, {
    bool compact = true,
  }) {
    final doctorNote = (appointment.doctorDeclineMessage ?? '').trim();
    final reasonText = (appointment.declineReasonText ?? '').trim();
    final fallbackReason = (appointment.declineReason ?? '').trim();
    final noteText = doctorNote.isNotEmpty
        ? doctorNote
        : reasonText.isNotEmpty
            ? reasonText
            : fallbackReason.isNotEmpty
                ? fallbackReason
                : languageProvider.t(
                    'No additional details provided by doctor.',
                    'ڈاکٹر کی جانب سے مزید تفصیل فراہم نہیں کی گئی۔',
                  );

    final refundText = appointment.refundRequired == null
        ? null
        : appointment.refundRequired!
            ? languageProvider.t(
                'Refund will be processed',
                'رقم کی واپسی جلد پروسیس کی جائے گی',
              )
            : languageProvider.t(
                'No refund due to invalid payment proof',
                'غلط ادائیگی ثبوت کی وجہ سے رقم واپس نہیں کی جائے گی',
              );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                languageProvider.t('Doctor Note', 'ڈاکٹر کا نوٹ'),
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 13 : 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            noteText,
            style: const TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (refundText != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: appointment.refundRequired! ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: appointment.refundRequired! ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Text(
                refundText,
                style: TextStyle(
                  color: appointment.refundRequired! ? Colors.green.shade800 : Colors.orange.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrescriptionTimeline(String appointmentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .collection('prescriptionTimeline')
          .orderBy('eventAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryTeal));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'No prescription events yet.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final eventType = (data['eventType'] ?? '').toString();
            final summary = (data['summary'] ?? '').toString();
            final ts = data['eventAt'] as Timestamp?;
            final eventAt = ts == null
                ? 'Unknown time'
                : DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate());

            IconData icon;
            Color color;
            String eventLabel;
            if (eventType == 'prescription_downloaded') {
              icon = Icons.download_rounded;
              color = Colors.indigo;
              eventLabel = 'Downloaded';
            } else {
              icon = Icons.receipt_long_rounded;
              color = primaryTeal;
              eventLabel = 'Prescription Sent';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventLabel,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(summary, style: const TextStyle(fontSize: 12.5)),
                        const SizedBox(height: 2),
                        Text(
                          eventAt,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAppointmentPrescriptionList(AppointmentModel appointment) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prescriptions')
          .where('patientId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryTeal));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'No prescription files found for this appointment.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          );
        }

        final docs = snapshot.data!.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['appointmentId'] ?? '').toString() == appointment.id;
            })
            .toList()
          ..sort((a, b) {
            final ad = ((a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?);
            final bd = ((b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?);
            final aDate = ad?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = bd?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              'No prescription files found for this appointment.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final pdfUrl = (data['pdfUrl'] ?? '').toString();
            final fileName = (data['pdfFileName'] ?? 'prescription.pdf').toString();
            final doctorName = (data['doctorName'] ?? data['doctor'] ?? 'Doctor').toString();
            final summary = (data['summary'] ?? '').toString();
            final followUp = (data['followUp'] ?? '').toString();
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final downloadsRaw = data['downloadCount'] ?? 0;
            final downloads = downloadsRaw is int
                ? downloadsRaw
                : int.tryParse(downloadsRaw.toString()) ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryTeal.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, color: primaryTeal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Doctor: $doctorName',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  if (summary.trim().isNotEmpty)
                    Text(
                      summary,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (followUp.trim().isNotEmpty)
                    Text(
                      'Follow-up: $followUp',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  Row(
                    children: [
                      Text(
                        'Downloads: $downloads',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 10),
                      if (createdAt != null)
                        Text(
                          DateFormat('MMM dd, yyyy').format(createdAt),
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: pdfUrl.isEmpty
                            ? null
                            : () => _previewPrescriptionInline(
                                  prescriptionId: doc.id,
                                  pdfUrl: pdfUrl,
                                  appointmentId: appointment.id,
                                ),
                        icon: const Icon(Icons.visibility_rounded, size: 17),
                        label: const Text('Preview'),
                      ),
                      TextButton.icon(
                        onPressed: pdfUrl.isEmpty
                            ? null
                            : () => _downloadPrescriptionFromHistory(
                                  appointmentId: appointment.id,
                                  prescriptionId: doc.id,
                                  pdfUrl: pdfUrl,
                                  fileName: fileName,
                                ),
                        icon: const Icon(Icons.download_rounded, size: 17),
                        label: const Text('Download'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _downloadPrescriptionFromHistory({
    required String appointmentId,
    required String prescriptionId,
    required String pdfUrl,
    required String fileName,
  }) async {
    if (pdfUrl.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid prescription URL.')),
      );
      return;
    }

    final savedPath = await FileDownloadService.downloadPdf(
      url: pdfUrl,
      fileName: fileName,
    );
    if (savedPath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to download prescription.')),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Prescription saved: $savedPath')),
      );
    }

    log('[MyAppointments] ✅ Prescription downloaded successfully: $fileName to $savedPath');
  }

  Future<void> _previewPrescriptionInline({
    required String prescriptionId,
    required String pdfUrl,
    required String appointmentId,
  }) async {
    try {
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load PDF preview.')),
        );
        return;
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF content is empty.')),
        );
        return;
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return Dialog(
            insetPadding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: primaryTeal,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Prescription Preview',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PdfPreview(
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    build: (_) async => bytes,
                  ),
                ),
              ],
            ),
          );
        },
      );

      log('[MyAppointments] ✅ Prescription preview displayed: $prescriptionId');
    } catch (e) {
      log('[MyAppointments] ❌ Inline PDF preview failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to preview prescription right now.')),
      );
    }
  }
}
