import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/services/Appointment Service/appointment_services.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:flutter_application_1/services/notification service/notification_service.dart';
import 'package:flutter_application_1/view/Doctor/Apponitment_approval_page.dart';

class DoctorAppointmentRequestsPage extends StatefulWidget {
  const DoctorAppointmentRequestsPage({super.key});

  @override
  State<DoctorAppointmentRequestsPage> createState() =>
      _DoctorAppointmentRequestsPageState();
}

class _DoctorAppointmentRequestsPageState
    extends State<DoctorAppointmentRequestsPage>
    with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  final NotificationService _notificationService = NotificationService();

  final Color primaryTeal = Color(0xFF00796B);
  final Color lightTeal = Color(0xFF4DB6AC);
  final Color cardGrey = Color(0xFFF8F9FA);
  final Color darkGrey = Color(0xFF2C3E50);
  final Color scaffoldBg = Color(0xFFF5F7FA);

  late TabController _tabController;
  String selectedStatus = 'requested';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            selectedStatus = 'requested';
            break;
          case 1:
            selectedStatus = 'approved';
            break;
          case 2:
            selectedStatus = 'declined';
            break;
          case 3:
            selectedStatus = 'all';
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate().toLocal();
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference < 7 && difference > 0) return '$difference days from now';
    if (difference > -7 && difference < 0) return '${difference.abs()} days ago';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = AuthService.currentUser?.uid;
    log('DoctorAppointmentRequestsPage built for doctorId: $doctorId');

    if (doctorId == null) {
      log('No doctor logged in');
      return _errorScaffold('Please log in as doctor');
    }

    return Scaffold(
      backgroundColor: primaryTeal,
      body: Column(
        children: [
          _buildModernHeader(),
          _buildTabBar(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 5),
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
                    log('Pull-to-refresh triggered');
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: primaryTeal,
                  child: StreamBuilder<QuerySnapshot>(
                    key: ValueKey('doctor_appointment_requests_$doctorId'),
                    stream: _appointmentService.doctorAppointments(doctorId),
                    builder: (context, snapshot) {
                      log('StreamBuilder state: ${snapshot.connectionState}');
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: primaryTeal),
                        );
                      }

                      if (snapshot.hasError) {
                        log('Error loading appointments: ${snapshot.error}');
                        return _errorState('Failed to load appointments');
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        log('No appointments found');
                        return _emptyState('No appointments found');
                      }

                      log(
                        'Appointments data received: ${snapshot.data!.docs.length} items',
                      );
                      final allAppointments = snapshot.data!.docs.map((doc) {
                        final appointment = AppointmentModel.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        );
                        return appointment;
                      }).toList();

                      // Filter based on selected status
                      final filteredAppointments = selectedStatus == 'all'
                          ? allAppointments
                          : allAppointments
                              .where((apt) => apt.status == selectedStatus)
                              .toList();

                      if (filteredAppointments.isEmpty) {
                        return _emptyState('No $selectedStatus appointments');
                      }

                      filteredAppointments
                          .sort((a, b) => b.date.compareTo(a.date));

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredAppointments.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return _buildModernAppointmentCard(
                            filteredAppointments[index],
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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                      log('Back button pressed');
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
            const SizedBox(height: 20),
            const Text(
              'Appointments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your appointment requests',
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

  Widget _buildTabBar() {
    return Container(
      color: primaryTeal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Declined'),
            Tab(text: 'All'),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppointmentCard(
    AppointmentModel appointment,
    int index,
  ) {
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
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAppointmentDetails(appointment),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final animalData = data['animal'] as Map<String, dynamic>?;
          final userData = data['user'] as Map<String, dynamic>?;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  log('Card tapped for appointment id: ${appointment.id}');
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AppointmentApprovalPage(appointment: appointment),
                    ),
                  );
                  if (mounted) {
                    log('Returned from appointment details, refreshing');
                    setState(() {});
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(appointment.status),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(appointment.date),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _buildAnimalImage(animalData),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  animalData?['name'] ?? appointment.animalName,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${animalData?['type'] ?? 'Pet'} • ${animalData?['breed'] ?? 'Unknown Breed'}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.person_outline_rounded,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      userData?['name'] ?? 'Unknown Owner',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scaffoldBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded,
                                    size: 18, color: primaryTeal),
                                const SizedBox(width: 10),
                                Text(
                                  appointment.time,
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.medical_services_outlined,
                                    size: 18, color: primaryTeal),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    appointment.problem,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AppointmentApprovalPage(
                                      appointment: appointment),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
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
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimalImage(Map<String, dynamic>? animalData) {
    String? imageUrl;

    if (animalData != null && animalData['imageUrls'] != null) {
      final imageUrls = animalData['imageUrls'] as List;
      if (imageUrls.isNotEmpty) {
        imageUrl = imageUrls[0] as String;
      }
    }

    return Container(
      height: 85,
      width: 85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal.withOpacity(0.1), lightTeal.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryTeal.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.pets_rounded, size: 40, color: primaryTeal);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: primaryTeal,
                      strokeWidth: 2,
                    ),
                  );
                },
              )
            : Icon(Icons.pets_rounded, size: 40, color: primaryTeal),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        bgColor = Colors.green.withOpacity(0.15);
        textColor = Colors.green.shade700;
        label = 'Approved';
        icon = Icons.check_circle_rounded;
        break;
      case 'declined':
        bgColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red.shade700;
        label = 'Declined';
        icon = Icons.cancel_rounded;
        break;
      case 'completed':
        bgColor = Colors.blue.withOpacity(0.15);
        textColor = Colors.blue.shade700;
        label = 'Completed';
        icon = Icons.done_all_rounded;
        break;
      default:
        bgColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange.shade700;
        label = 'Pending';
        icon = Icons.schedule_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchAppointmentDetails(
      AppointmentModel appointment) async {
    try {
      final animalSnapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where('userId', isEqualTo: appointment.userId)
          .where('name', isEqualTo: appointment.animalName)
          .limit(1)
          .get();

      Map<String, dynamic>? animalData;
      if (animalSnapshot.docs.isNotEmpty) {
        animalData = animalSnapshot.docs.first.data();
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(appointment.userId)
          .get();

      Map<String, dynamic>? userData;
      if (userDoc.exists) {
        userData = userDoc.data();
      }

      return {
        'animal': animalData,
        'user': userData,
      };
    } catch (e) {
      log('Error fetching appointment details: $e');
      return {
        'animal': null,
        'user': null,
      };
    }
  }

  Widget _emptyState(String message) {
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
                  Icons.event_busy_rounded,
                  size: 80,
                  color: primaryTeal,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pull down to refresh',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 80, color: Colors.red[400]),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryTeal, lightTeal]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryTeal.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                log('Retry button pressed');
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text(
                'Retry',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Scaffold _errorScaffold(String message) {
    return Scaffold(
      backgroundColor: primaryTeal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
