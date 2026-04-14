import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/view/Admin/edit_profile_page.dart';
import 'package:flutter_application_1/view/Admin/manage_appointments.dart';
import 'package:flutter_application_1/view/Admin/manage_doctor.dart';
import 'package:flutter_application_1/view/Admin/manage_user.dart';
import 'package:flutter_application_1/view/Admin/manage_refunds.dart';
import 'package:flutter_application_1/view/Admin/admin_wallet.dart';
import 'package:flutter_application_1/view/Admin/admin_support_inbox.dart';
import 'package:flutter_application_1/view/Admin/prescription_management.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {

  // Professional Color Palette
  static const Color primaryTeal = Color(0xFF00796B);
  static const Color lightTeal = Color(0xFF4DB6AC);
  static const Color itemTeal = Color(0xFFB2DFDB);
  static const Color darkGrey = Color(0xFF2C3E50);
  static const Color lightGrey = Color(0xFF95A5A6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildProfessionalHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 28),
                    _buildStatsGrid(),
                    const SizedBox(height: 18),
                    _buildAdminAnalyticsSection(),
                    const SizedBox(height: 18),
                    _buildPrescriptionMonitoringSection(),
                    const SizedBox(height: 32),
                    _buildManagementSection(),
                    const SizedBox(height: 32),
                    _buildAppointmentsList(),
                    const SizedBox(height: 20),
                    _buildRecentDoctorsList(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Professional Header with Clean Design
  Widget _buildProfessionalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal, lightTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DignoVet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              // Navigate to Admin Edit Profile
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminEditProfile(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: const Icon(Icons.account_circle, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  // Welcome Section with Better Styling
  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkGrey,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Monitor and manage your veterinary system',
          style: TextStyle(
            fontSize: 15,
            color: lightGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Enhanced Statistics Grid
  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.5,
      children: [
        _liveCountStatsCard(
          label: 'Total Doctors',
          icon: Icons.medical_services_rounded,
          accentColor: const Color(0xFF3498DB),
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'doctor')
              .snapshots(),
        ),
        _liveCountStatsCard(
          label: 'Total Patients',
          icon: Icons.pets_rounded,
          accentColor: const Color(0xFFE67E22),
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'user')
              .snapshots(),
        ),
        _liveCountStatsCard(
          label: 'Appointments',
          icon: Icons.event_note_rounded,
          accentColor: const Color(0xFF27AE60),
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .snapshots(),
        ),
        _appRatingsCard(), // 🔥 App Ratings Card
        _liveCountStatsCard(
          label: 'Pending Refunds',
          icon: Icons.request_page_rounded,
          accentColor: const Color(0xFFF39C12),
          stream: FirebaseFirestore.instance
              .collection('refunds')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
        ),
      ],
    );
  }

  // 🔥 App Ratings Statistics Card
  Widget _appRatingsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('consultation_ratings')
          .snapshots(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final ratings = snapshot.data?.docs ?? [];
        
        double averageRating = 0.0;
        int ratingCount = 0;
        
        if (ratings.isNotEmpty) {
          double total = 0.0;
          for (var rating in ratings) {
            final appRating = (rating.data() as Map<String, dynamic>)['appRating'] as num?;
            if (appRating != null) {
              total += appRating.toDouble();
              ratingCount++;
            }
          }
          averageRating = ratingCount > 0 ? total / ratingCount : 0.0;
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB81C).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star_rounded, color: Color(0xFFFFB81C), size: 22),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color(0xFFFFB81C),
                          ),
                        )
                      : Text(
                          '${averageRating.toStringAsFixed(1)}/5',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: darkGrey,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                  const SizedBox(height: 2),
                  Text(
                    'App Rating ($ratingCount)',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: lightGrey,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _liveCountStatsCard({
    required String label,
    required IconData icon,
    required Color accentColor,
    required Stream<QuerySnapshot> stream,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final count = snapshot.data?.docs.length ?? 0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor,
                          ),
                        )
                      : Text(
                          count.toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: darkGrey,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: lightGrey,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminAnalyticsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        int approved = 0;
        int pending = 0;
        int declined = 0;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '').toString().toLowerCase();
          if (status == 'approved') approved++;
          if (status == 'pending') pending++;
          if (status == 'declined') declined++;
        }

        final total = docs.length;
        final approvedRatio = total == 0 ? 0.0 : approved / total;
        final pendingRatio = total == 0 ? 0.0 : pending / total;
        final declinedRatio = total == 0 ? 0.0 : declined / total;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Appointments Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkGrey,
                ),
              ),
              const SizedBox(height: 12),
              _buildAnalyticsRow('Approved', approved, approvedRatio, const Color(0xFF27AE60)),
              const SizedBox(height: 8),
              _buildAnalyticsRow('Pending', pending, pendingRatio, const Color(0xFFF39C12)),
              const SizedBox(height: 8),
              _buildAnalyticsRow('Declined', declined, declinedRatio, const Color(0xFFE74C3C)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsRow(String label, int count, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: darkGrey,
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.14),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionMonitoringSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('prescriptions').snapshots(),
      builder: (context, prescriptionSnapshot) {
        final prescriptionDocs = prescriptionSnapshot.data?.docs ?? [];

        int totalPrescriptions = prescriptionDocs.length;
        int downloadedPrescriptions = 0;
        int totalDownloads = 0;
        int thisMonthPrescriptions = 0;

        final Map<String, Map<String, int>> doctorStats = {};
        final now = DateTime.now();

        for (final doc in prescriptionDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final doctorId = (data['doctorId'] ?? '').toString();
          final downloadCountRaw = data['downloadCount'] ?? 0;
          final downloadCount = downloadCountRaw is int
              ? downloadCountRaw
              : int.tryParse(downloadCountRaw.toString()) ?? 0;

          if (downloadCount > 0) downloadedPrescriptions++;
          totalDownloads += downloadCount;

          final ts = data['createdAt'];
          if (ts is Timestamp) {
            final dt = ts.toDate();
            if (dt.year == now.year && dt.month == now.month) {
              thisMonthPrescriptions++;
            }
          }

          if (doctorId.isNotEmpty) {
            doctorStats.putIfAbsent(doctorId, () => {
                  'sent': 0,
                  'downloads': 0,
                });
            doctorStats[doctorId]!['sent'] = (doctorStats[doctorId]!['sent'] ?? 0) + 1;
            doctorStats[doctorId]!['downloads'] =
                (doctorStats[doctorId]!['downloads'] ?? 0) + downloadCount;
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'doctor')
              .snapshots(),
          builder: (context, doctorSnapshot) {
            final doctorDocs = doctorSnapshot.data?.docs ?? [];
            final doctorNames = <String, String>{};
            for (final doc in doctorDocs) {
              final data = doc.data() as Map<String, dynamic>;
              doctorNames[doc.id] = (data['name'] ?? 'Doctor').toString();
            }

            final doctorRows = doctorStats.entries.toList()
              ..sort((a, b) {
                final bSent = b.value['sent'] ?? 0;
                final aSent = a.value['sent'] ?? 0;
                if (bSent != aSent) return bSent.compareTo(aSent);
                return (b.value['downloads'] ?? 0).compareTo(a.value['downloads'] ?? 0);
              });

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prescription Monitoring',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPill('Total', totalPrescriptions.toString(), const Color(0xFF00796B)),
                      _buildPill('This Month', thisMonthPrescriptions.toString(), const Color(0xFF1E88E5)),
                      _buildPill('Downloaded', downloadedPrescriptions.toString(), const Color(0xFF43A047)),
                      _buildPill('Total Downloads', totalDownloads.toString(), const Color(0xFF8E24AA)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (doctorRows.isEmpty)
                    const Text(
                      'No prescription data available yet.',
                      style: TextStyle(fontSize: 13, color: lightGrey),
                    )
                  else
                    Column(
                      children: doctorRows.take(8).map((entry) {
                        final doctorId = entry.key;
                        final sent = entry.value['sent'] ?? 0;
                        final downloads = entry.value['downloads'] ?? 0;
                        final name = doctorNames[doctorId] ?? 'Doctor';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: itemTeal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: itemTeal.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: primaryTeal.withOpacity(0.14),
                                child: Text(
                                  name.isEmpty ? 'D' : name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: primaryTeal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: darkGrey,
                                  ),
                                ),
                              ),
                              Text(
                                'Sent: $sent',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF00796B),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Downloads: $downloads',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5E35B1),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  // Management Section with Enhanced Design
  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: darkGrey,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3.0,
          children: [
            _professionalManageBtn("Manage Users", Icons.people_outline_rounded),
            _professionalManageBtn("Manage Doctors", Icons.medical_information_outlined),
            _professionalManageBtn("Appointments", Icons.calendar_today_outlined),
            _professionalManageBtn("Prescription Management", Icons.receipt_long_rounded),
            _professionalManageBtn("Refund Management", Icons.monetization_on_outlined),
            _professionalManageBtn("Admin Wallet", Icons.account_balance_wallet_outlined),
            _professionalManageBtn("Support Inbox", Icons.support_agent),
          ],
        ),
      ],
    );
  }

  Widget _professionalManageBtn(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal, const Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to Manage Users page
            if (title == "Manage Users") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageUsersPage(),
                ),
              );
            }
            else if (title == "Manage Doctors") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageDoctorsPage(),
                ),
              );
            }
            else if (title == "Appointments") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageAppointmentsPage(),
                ),
              );
            }
            else if (title == "Prescription Management") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminPrescriptionManagementPage(),
                ),
              );
            }
            else if (title == "Refund Management") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageRefundsPage(),
                ),
              );
            }
            else if (title == "Admin Wallet") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminWalletPage(),
                ),
              );
            }
            else if (title == "Support Inbox") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminSupportInboxPage(),
                ),
              );
            }
            // Add other navigation here for other buttons
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildAppointmentsList() {
  return _professionalListWrapper(
    "Recent Appointments",
    Icons.event_note_rounded,
    [
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .orderBy('date', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text("No recent appointments");
          }

          return Column(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['date'] as Timestamp?;
              final time = (data['time'] ?? '').toString();
              final status = (data['status'] ?? 'pending').toString();
              final animalName = (data['animalName'] ?? 'Animal').toString();
              final shortId = doc.id.length > 6 ? doc.id.substring(0, 6) : doc.id;

              return _professionalListTile(
                "#$shortId • $animalName",
                "${_formatTimestampDate(timestamp)} • $time • $status",
                Icons.schedule_rounded,
                const Color(0xFF3498DB),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}

  // Enhanced Active Doctors List
// Recent Doctors List (Dynamic from Firestore)
Widget _buildRecentDoctorsList() {
  return _professionalListWrapper(
    "Recent Doctors",
    Icons.medical_services_rounded,
    [
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text(
              "No recent doctors found",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            );
          }

          final doctors = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['createdAt'] as Timestamp?;
              final bTime = bData['createdAt'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

          final latestDoctors = doctors.take(5).toList();

          return Column(
            children: latestDoctors.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final specialization = (data['specialization'] ?? 'Veterinary Doctor').toString();
              final experience = (data['experience'] ?? 0).toString();
              final isBlocked = data['isBlocked'] == true;

              return _professionalListTile(
                data['name'] ?? 'Doctor',
                '$specialization • ${experience}y exp • ${isBlocked ? 'Blocked' : 'Active'}',
                Icons.person_rounded,
                isBlocked ? const Color(0xFFE74C3C) : const Color(0xFF27AE60),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}


  Widget _professionalListWrapper(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: primaryTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: darkGrey,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _professionalListTile(String name, String subtitle, IconData icon, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            itemTeal.withOpacity(0.15),
            itemTeal.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: itemTeal.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: darkGrey,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: lightGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primaryTeal),
          ),
        ],
      ),
    );
  }

  String _formatTimestampDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    final date = timestamp.toDate();
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }
}