import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:flutter_application_1/view/Doctor/DoctorNotificationsPage.dart';
import 'package:flutter_application_1/view/Doctor/doctor_chat_screen.dart';
import 'package:flutter_application_1/view/Doctor/doctor_profile_page.dart';
import 'package:flutter_application_1/view/auth/login/login.dart';
import 'package:flutter_application_1/services/Appointment Service/appointment_services.dart';
import 'package:flutter_application_1/services/notification service/notification_service.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/view/Doctor/DoctorAppointmentRequests.dart';
import 'package:flutter_application_1/view/Doctor/DoctorNotifications.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
       
      
        title: const Text(
          'DignoVet',
          style: TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87, size: 26),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorNotificationsPage()),
              );
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.person_outline, color: Colors.black87, size: 26),
          //   onPressed: ()async {
          //     log(  'Doctor Logged Out');
          //   await  AuthService().signOut();
              
          //   },
          // ),
         IconButton(
  icon: const Icon(
    Icons.person_outline,
    color: Colors.black87,
    size: 26,
  ),
onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const DoctorProfilePage(), // no doctorId parameter
    ),
  );
},
         ),

          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card with Doctor Image
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF80CBC4),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Welcome',
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Dr. Emelle',
                            style: TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'You are Doing Great Today',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Doctor Image (use your own asset or CircleAvatar)
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 46,
                        child: Icon(Icons.person, size: 60, color: Colors.teal), // Add your doctor image here
                        // If no image, use placeholder
                        // backgroundColor: Colors.teal[100],
                        // child: Icon(Icons.person, size: 60, color: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Stats Cards
              Row(
                children: [
                  Expanded(child: _buildStatCard('80+', 'Appointments\nCompleted', Icons.check_circle_outline)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('05', 'Appointments\nPending', Icons.schedule)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('4.5', 'Messages', Icons.message_outlined)),
                ],
              ),

              const SizedBox(height: 32),

              // Daily Appointments Section
              _buildAppointmentSectionWithDetails(),

              const SizedBox(height: 40),
              const SizedBox(height: 32),

// Chat Module Card
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DoctorChatListScreen()),
    );
  },
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFF80CBC4),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: const [
        Icon(Icons.chat_bubble_outline, size: 50, color: Colors.white),
        SizedBox(width: 20),
        Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
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

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F3),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.teal[700]),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.teal[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentSection({
    required String title,
    required List<AppointmentModel> appointments,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0EF),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.teal[900],
            ),
          ),
          const SizedBox(height: 20),
          ...appointments.map((appointment) => _buildAppointmentItem(appointment)).toList(),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(AppointmentModel appointment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF80CBC4),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Animal: ${appointment.animalName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              'Date: ${appointment.date} at ${appointment.time}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            Text(
              'Problem: ${appointment.problem}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveAppointment(appointment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Approve', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _declineAppointment(appointment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Decline', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveAppointment(AppointmentModel appointment) async {
    await _appointmentService.updateStatus(appointment.id, 'approved');
    await _notificationService.sendNotification(
      receiverId: appointment.userId,
      title: 'Appointment Approved',
      message: 'Your appointment with ${appointment.animalName} has been approved.',
      appointmentId: appointment.id,
      type: 'appointment_approved',
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment approved')));
  }

  Future<void> _declineAppointment(AppointmentModel appointment) async {
    await _appointmentService.updateStatus(appointment.id, 'declined');
    await _notificationService.sendNotification(
      receiverId: appointment.userId,
      title: 'Appointment Declined',
      message: 'Your appointment with ${appointment.animalName} has been declined.',
      appointmentId: appointment.id,
      type: 'appointment_declined',
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment declined')));
  }

  Widget _buildAppointmentSectionWithDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0EF),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Appointments',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00796B),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorAppointmentRequestsPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF80CBC4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 6,
            ),
            child: const Text(
              'View Details',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// Doctor Welcome Splash Screen (3 seconds)
class DoctorWelcomeSplashScreen extends StatefulWidget {
  const DoctorWelcomeSplashScreen({super.key});

  @override
  State<DoctorWelcomeSplashScreen> createState() => _DoctorWelcomeSplashScreenState();
}

class _DoctorWelcomeSplashScreenState extends State<DoctorWelcomeSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8)),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.7)),
    );

    _controller.forward();

    // After 3 seconds → Doctor Dashboard
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (_, __, ___) => const DoctorDashboardPage(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2DFDB),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/login/cow.png', scale: 4),
                const SizedBox(height: 50),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.indigo,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Dr. Emelle',
                  style: TextStyle(
                    fontSize: 52,
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ready to care for more pets today?',
                  style: TextStyle(fontSize: 20, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
// import 'package:flutter_application_1/view/Doctor/doctor_chat_screen.dart';
// import 'package:flutter_application_1/view/auth/login/login.dart';
// import 'package:flutter_application_1/view/Doctor/DoctorAppointmentRequests.dart';
// import 'package:flutter_application_1/view/Doctor/DoctorNotifications.dart';

// class DoctorDashboardPage extends StatelessWidget {
//   const DoctorDashboardPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final doctor = AuthService.currentUser;

//     if (doctor == null) {
//       return const Scaffold(
//         body: Center(child: Text('Doctor not logged in')),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: _buildAppBar(context),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             _buildWelcomeCard(doctor.displayName ?? 'Doctor'),
//             const SizedBox(height: 30),
//             _buildStatsRow(doctor.uid),
//             const SizedBox(height: 30),
//             _buildQuickActions(context),
//             const SizedBox(height: 30),
//             _buildChatCard(context),
//           ],
//         ),
//       ),
//     );
//   }

//   // ---------------- APP BAR ----------------
//   AppBar _buildAppBar(BuildContext context) {
//     return AppBar(
//       backgroundColor: Colors.white,
//       elevation: 0,
//       title: const Text(
//         'DignoVet',
//         style: TextStyle(
//           color: Colors.teal,
//           fontWeight: FontWeight.bold,
//           fontSize: 24,
//         ),
//       ),
//       actions: [
//         IconButton(
//           icon: const Icon(Icons.notifications_outlined),
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const DoctorNotificationsPage()),
//             );
//           },
//         ),
//         IconButton(
//           icon: const Icon(Icons.logout),
//           onPressed: () async {
//             log('Doctor Logged Out');
//             await AuthService().signOut();

//             if (context.mounted) {
//               Navigator.pushAndRemoveUntil(
//                 context,
//                 MaterialPageRoute(builder: (_) => const LoginPage()),
//                 (_) => false,
//               );
//             }
//           },
//         ),
//       ],
//     );
//   }

//   // ---------------- WELCOME CARD ----------------
//   Widget _buildWelcomeCard(String name) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: const Color(0xFF80CBC4),
//         borderRadius: BorderRadius.circular(28),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Welcome Back',
//                   style: TextStyle(color: Colors.white70, fontSize: 20),
//                 ),
//                 Text(
//                   'Dr. $name',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 const Text(
//                   'You are doing great today!',
//                   style: TextStyle(color: Colors.white70),
//                 ),
//               ],
//             ),
//           ),
//           const CircleAvatar(
//             radius: 36,
//             backgroundColor: Colors.white,
//             child: Icon(Icons.person, size: 40, color: Colors.teal),
//           ),
//         ],
//       ),
//     );
//   }

//   // ---------------- STATS ----------------
//   Widget _buildStatsRow(String doctorId) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('appointments')
//           .where('doctorId', isEqualTo: doctorId)
//           .snapshots(),
//       builder: (context, snapshot) {
//         int total = 0;
//         int pending = 0;
//         int approved = 0;

//         if (snapshot.hasData) {
//           total = snapshot.data!.docs.length;
//           pending = snapshot.data!.docs
//               .where((e) => e['status'] == 'pending')
//               .length;
//           approved = snapshot.data!.docs
//               .where((e) => e['status'] == 'approved')
//               .length;
//         }

//         return Row(
//           children: [
//             _statCard('Total', total.toString(), Icons.assignment),
//             const SizedBox(width: 12),
//             _statCard('Pending', pending.toString(), Icons.schedule),
//             const SizedBox(width: 12),
//             _statCard('Approved', approved.toString(), Icons.check_circle),
//           ],
//         );
//       },
//     );
//   }

//   Widget _statCard(String label, String value, IconData icon) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(18),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF1F5F4),
//           borderRadius: BorderRadius.circular(22),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, size: 30, color: Colors.teal),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 26,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             Text(label, style: const TextStyle(color: Colors.grey)),
//           ],
//         ),
//       ),
//     );
//   }

//   // ---------------- QUICK ACTIONS ----------------
//   Widget _buildQuickActions(BuildContext context) {
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: const Color(0xFF80CBC4),
//         padding: const EdgeInsets.symmetric(vertical: 18),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(30),
//         ),
//       ),
//       onPressed: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => const DoctorAppointmentRequestsPage(),
//           ),
//         );
//       },
//       child: const Text(
//         'View Pending Appointments',
//         style: TextStyle(fontSize: 18, color: Colors.black87),
//       ),
//     );
//   }

//   // ---------------- CHAT CARD ----------------
//   Widget _buildChatCard(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const DoctorChatListScreen()),
//         );
//       },
//       child: Container(
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: const Color(0xFF80CBC4),
//           borderRadius: BorderRadius.circular(28),
//         ),
//         child: Row(
//           children: const [
//             Icon(Icons.chat_bubble_outline, size: 40, color: Colors.white),
//             SizedBox(width: 16),
//             Text(
//               'Chats',
//               style: TextStyle(
//                 fontSize: 26,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
