// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/model/appointment_model.dart';
// import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
// import 'package:flutter_application_1/view/Doctor/Apponitment_approval_page.dart';

// class DoctorAppointmentsPage extends StatefulWidget {
//   const DoctorAppointmentsPage({super.key});

//   @override
//   State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
// }

// class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
//   final Color primaryTeal = const Color(0xFF80CBC4);
//   final Color darkTeal = const Color(0xFF00796B);

//   @override
//   Widget build(BuildContext context) {
//     final doctorId = AuthService.currentUser?.uid;

//     if (doctorId == null) {
//       return Scaffold(
//         body: const Center(child: Text('Please log in as doctor')),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Appointments'),
//         backgroundColor: primaryTeal,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('appointments')
//             .where('doctorId', isEqualTo: doctorId)
//             .orderBy('date', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final appointments = snapshot.data!.docs;

//           if (appointments.isEmpty) {
//             return const Center(child: Text('No appointments'));
//           }

//           return ListView.builder(
//             itemCount: appointments.length,
//             itemBuilder: (context, index) {
//               final appointment = AppointmentModel.fromMap(
//                   appointments[index].data() as Map<String, dynamic>, appointments[index].id);
//               return ListTile(
//                 title: Text('Appointment for ${appointment.animalName}'),
//                 subtitle: Text('${appointment.date.toDate()} at ${appointment.time} - ${appointment.status}'),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => AppointmentApprovalPage(appointment: appointment),
//                     ),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:flutter_application_1/view/Doctor/Apponitment_approval_page.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  const DoctorAppointmentsPage({super.key});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  final Color primaryTeal = Color(0xFF00796B);
  final Color lightTeal = Color(0xFF4DB6AC);
  final Color cardGrey = Color(0xFFF8F9FA);
  final Color darkGrey = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    final doctorId = AuthService.currentUser?.uid;
    
    log('[DoctorAppointments] build() - DoctorId: $doctorId');

    if (doctorId == null || doctorId.isEmpty) {
      return Scaffold(
        body: const Center(child: Text('Please log in as doctor')),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryTeal, lightTeal],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      log('[DoctorAppointments] Refresh triggered');
                      setState(() {});
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: StreamBuilder<QuerySnapshot>(
                      key: ValueKey('doctor_appointments_$doctorId'),
                      // SIMPLIFIED QUERY - No composite index needed
                      stream: FirebaseFirestore.instance
                          .collection('appointments')
                          .where('doctorId', isEqualTo: doctorId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        log('[DoctorAppointments] Stream state: ${snapshot.connectionState}');

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          log('[DoctorAppointments] Stream error: ${snapshot.error}');
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          log('[DoctorAppointments] No appointments');
                          return _buildEmptyState();
                        }

                        // CLIENT-SIDE FILTERING for pending status
                        final allAppointments = snapshot.data!.docs;
                        final pendingAppointments = allAppointments.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['status'] == 'pending';
                        }).toList();

                        // Sort by date (client-side)
                        pendingAppointments.sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          final aDate = (aData['date'] as Timestamp).toDate();
                          final bDate = (bData['date'] as Timestamp).toDate();
                          return bDate.compareTo(aDate); // Descending order
                        });

                        log('[DoctorAppointments] Total: ${allAppointments.length}, Pending: ${pendingAppointments.length}');

                        if (pendingAppointments.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(20),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: pendingAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = AppointmentModel.fromMap(
                              pendingAppointments[index].data() as Map<String, dynamic>,
                              pendingAppointments[index].id,
                            );
                            log('[DoctorAppointments] Appointment #$index - ${appointment.animalName}');
                            return _buildAppointmentCard(appointment);
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () {
              log('[DoctorAppointments] Back button pressed');
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
          const Text(
            'Pending Requests',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  size: 64,
                  color: primaryTeal,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No pending appointments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All caught up!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final dateTime = appointment.date.toDate();
    final formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';

    return GestureDetector(
      onTap: () async {
        log('[DoctorAppointments] Opening appointment: ${appointment.id}');
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppointmentApprovalPage(appointment: appointment),
          ),
        );
        
        // Force refresh after returning
        if (mounted) {
          log('[DoctorAppointments] Returned from appointment details, refreshing');
          setState(() {});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.pets_rounded, color: primaryTeal, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.animalName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        appointment.time,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pending_rounded, size: 12, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: primaryTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}