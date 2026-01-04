import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:flutter_application_1/view/Doctor/DoctorNotificationsPage.dart';
import 'package:flutter_application_1/view/Doctor/doctor_chat_screen.dart';
import 'package:flutter_application_1/view/Doctor/doctor_profile_page.dart';
import 'package:flutter_application_1/view/auth/login/login.dart';
import 'package:flutter_application_1/services/Appointment Service/appointment_services.dart';
import 'package:flutter_application_1/services/notification service/notification_service.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/model/app_user.dart';
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
  // Doctor profile data
  AppUser? doctorProfile;
  bool isLoadingProfile = true;
  
  // Professional Color Scheme (matching doctor profile)
  final Color primaryTeal = Color(0xFF00796B);
  final Color lightTeal = Color(0xFF4DB6AC);
  final Color cardGrey = Color(0xFFF8F9FA);
  final Color darkGrey = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  Future<void> _loadDoctorProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          doctorProfile = AppUser.fromMap(docSnapshot.data()!, docSnapshot.id);
          isLoadingProfile = false;
        });
      }
    } catch (e) {
      log('Error loading doctor profile: $e');
      setState(() => isLoadingProfile = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (isLoadingProfile) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryTeal)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'DignoVet',
          style: TextStyle(
            color: primaryTeal,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: darkGrey, size: 26),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: darkGrey, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DoctorNotificationsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person_outline, color: darkGrey, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorProfilePage()),
              ).then((_) => _loadDoctorProfile());
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
              // Professional Welcome Card with Complete Doctor Details
            _buildDoctorProfileCard(),
            const SizedBox(height: 32),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '80+',
                      'Appointments\nCompleted',
                      Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      '05',
                      'Appointments\nPending',
                      Icons.schedule,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      '4.5',
                      'Messages',
                      Icons.message_outlined,
                    ),
                  ),
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
                    MaterialPageRoute(
                      builder: (_) => const DoctorChatListScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryTeal, lightTeal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primaryTeal.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 50,
                        color: Colors.white,
                      ),
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

  // Professional Doctor Profile Card with All Details
  Widget _buildDoctorProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal, lightTeal, lightTeal.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Profile Image
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  backgroundImage: doctorProfile?.imageUrl.isNotEmpty == true
                      ? NetworkImage(doctorProfile!.imageUrl)
                      : null,
                  child: doctorProfile?.imageUrl.isEmpty != false
                      ? Icon(Icons.person, size: 60, color: primaryTeal)
                      : null,
                ),
              ),
              const SizedBox(width: 20),
              // Doctor Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctorProfile?.name ?? 'Doctor',
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Specialization Badge
                    if (doctorProfile?.specialization != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          doctorProfile!.specialization!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Professional Information Grid
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                // Experience & Clinic Name Row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.work_outline,
                        'Experience',
                        '${doctorProfile?.experience ?? 0} Years',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.local_hospital_outlined,
                        'Clinic',
                        doctorProfile?.clinicName ?? 'N/A',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Contact Information
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.email_outlined,
                        'Email',
                        doctorProfile?.email ?? 'N/A',
                      ),
                    ),
                  ],
                ),

                if (doctorProfile?.phone.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.phone_outlined,
                          'Phone',
                          doctorProfile!.phone,
                        ),
                      ),
                    ],
                  ),
                ],

                if (doctorProfile?.clinicAddress != null &&
                    doctorProfile!.clinicAddress!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    Icons.location_on_outlined,
                    'Clinic Address',
                    doctorProfile!.clinicAddress!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Status Message
          Text(
            'You are doing great today! 🌟',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for info items in the profile card
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardGrey, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lightTeal.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: primaryTeal),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: primaryTeal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: darkGrey,
              height: 1.3,
              fontWeight: FontWeight.w500,
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
        gradient: LinearGradient(
          colors: [cardGrey, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: lightTeal.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.1),
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
              color: primaryTeal,
            ),
          ),
          const SizedBox(height: 20),
          ...appointments
              .map((appointment) => _buildAppointmentItem(appointment))
              .toList(),
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
          gradient: LinearGradient(
            colors: [lightTeal, primaryTeal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryTeal.withOpacity(0.2),
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
                color: Colors.white,
              ),
            ),
            Text(
              'Date: ${appointment.date} at ${appointment.time}',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            Text(
              'Problem: ${appointment.problem}',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveAppointment(appointment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Approve',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _declineAppointment(appointment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
      message:
          'Your appointment with ${appointment.animalName} has been approved.',
      appointmentId: appointment.id,
      type: 'appointment_approved',
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Appointment approved')));
  }

  Future<void> _declineAppointment(AppointmentModel appointment) async {
    await _appointmentService.updateStatus(appointment.id, 'declined');
    await _notificationService.sendNotification(
      receiverId: appointment.userId,
      title: 'Appointment Declined',
      message:
          'Your appointment with ${appointment.animalName} has been declined.',
      appointmentId: appointment.id,
      type: 'appointment_declined',
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Appointment declined')));
  }

  Widget _buildAppointmentSectionWithDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardGrey, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: lightTeal.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: primaryTeal, size: 24),
              const SizedBox(width: 12),
              Text(
                'Daily Appointments',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DoctorAppointmentRequestsPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.visibility_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'View All Appointments',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
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
  State<DoctorWelcomeSplashScreen> createState() =>
      _DoctorWelcomeSplashScreenState();
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
