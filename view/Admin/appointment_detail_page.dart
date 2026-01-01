import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/app_user.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/view/Admin/edit_profile_page.dart';
import 'package:flutter_application_1/view/Admin/manage_appointments.dart';
import 'package:flutter_application_1/view/Admin/manage_doctor.dart';
import 'package:flutter_application_1/view/Admin/manage_user.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {

  // Professional Color Palette
  static const Color primaryTeal = Color(0xFF00796B);
  static const Color lightTeal = Color(0xFF4DB6AC);
  static const Color cardGrey = Color(0xFFF8F9FA);
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
                    const SizedBox(height: 32),
                    _buildManagementSection(),
                    const SizedBox(height: 32),
                    _buildAppointmentsList(),
                    const SizedBox(height: 20),
                    _buildActiveDoctorsList(),
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
        _professionalStatsCard("80+", "Total Doctors", Icons.medical_services_rounded, const Color(0xFF3498DB)),
        _professionalStatsCard("05", "Total Patients", Icons.pets_rounded, const Color(0xFFE67E22)),
        _professionalStatsCard("900", "Total Appointments", Icons.event_note_rounded, const Color(0xFF27AE60)),
        _professionalStatsCard("4.5", "App Ratings", Icons.star_rounded, const Color(0xFFF39C12)),
      ],
    );
  }

  Widget _professionalStatsCard(String value, String label, IconData icon, Color accentColor) {
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
              Text(
                value,
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
            _professionalManageBtn("Manage Admins", Icons.admin_panel_settings_outlined),
            _professionalManageBtn("Appointments", Icons.calendar_today_outlined),
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
            // Navigate based on button title
            if (title == "Manage Users") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageUsersPage()),
              );
            } else if (title == "Manage Doctors") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageDoctorsPage()),
              );
            } else if (title == "Appointments") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageAppointmentsPage()),
              );
            }
            // Add Manage Admins navigation here if needed
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

  // Enhanced Recent Appointments List
  Widget _buildAppointmentsList() {
    return _professionalListWrapper(
      "Recent Appointments",
      Icons.event_note_rounded,
      [
        _professionalListTile("Appointment #1234", "Dr. Smith • 10:00 AM", Icons.schedule_rounded, const Color(0xFF3498DB)),
        _professionalListTile("Appointment #1235", "Dr. Johnson • 11:30 AM", Icons.schedule_rounded, const Color(0xFF9B59B6)),
        _professionalListTile("Appointment #1236", "Dr. Williams • 02:00 PM", Icons.schedule_rounded, const Color(0xFFE67E22)),
      ],
    );
  }

  // Enhanced Active Doctors List
  Widget _buildActiveDoctorsList() {
    return _professionalListWrapper(
      "Active Doctors",
      Icons.medical_services_rounded,
      [
        _professionalListTile("Dr. Heather Arkin", "Veterinary Surgeon", Icons.person_rounded, const Color(0xFF27AE60)),
        _professionalListTile("Dr. Brian Adam", "Animal Specialist", Icons.person_rounded, const Color(0xFF3498DB)),
        _professionalListTile("Dr. Sarah Mitchell", "Emergency Care", Icons.person_rounded, const Color(0xFFE74C3C)),
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
}