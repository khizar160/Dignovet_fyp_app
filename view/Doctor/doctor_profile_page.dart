// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../model/app_user.dart';
// import '../../model/doctor_model.dart';
// import '../auth/login/login.dart';
// import 'edit_doctor_profile.dart';

// class DoctorProfilePage extends StatefulWidget {
//   const DoctorProfilePage({super.key});

//   @override
//   State<DoctorProfilePage> createState() => _DoctorProfilePageState();
// }

// class _DoctorProfilePageState extends State<DoctorProfilePage> {
//   AppUser? user;
//   DoctorProfile? doctor;
//   bool loading = true;

//   final Color primaryTeal = const Color(0xFF80CBC4);
//   final Color darkTeal = const Color(0xFF00796B);
//   final Color lightBg = const Color(0xFFE8F5F3);

//   @override
//   void initState() {
//     super.initState();
//     _loadProfile();
//   }

//   Future<void> _loadProfile() async {
//     setState(() => loading = true);
//     try {
//       final currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) return;

//       final uid = currentUser.uid;

//       final userDoc =
//           await FirebaseFirestore.instance.collection('users').doc(uid).get();
//       final doctorDoc =
//           await FirebaseFirestore.instance.collection('doctors').doc(uid).get();

//       if (userDoc.exists) {
//         user = AppUser.fromMap(userDoc.data()!, userDoc.id);
//       }

//       if (doctorDoc.exists) {
//         doctor = DoctorProfile.fromMap(doctorDoc.data()!, doctorDoc.id);
//       } else {
//         doctor = null;
//       }

//       setState(() => loading = false);
//     } catch (e) {
//       setState(() => loading = false);
//       debugPrint("Error loading doctor profile: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser == null) {
//       return const Scaffold(
//         body: Center(child: Text("No logged in user")),
//       );
//     }

//     return Scaffold(
//       backgroundColor: lightBg,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: primaryTeal,
//         title: const Text("Doctor Profile"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: _logout,
//           ),
//         ],
//       ),
//       body: doctor == null
//           ? _buildIncompleteProfile(currentUser.uid)
//           : _buildProfileView(currentUser.uid),
//     );
//   }

//   /// Profile Incomplete Card
//   Widget _buildIncompleteProfile(String uid) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Card(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//           elevation: 8,
//           child: Padding(
//             padding: const EdgeInsets.all(28),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.person_outline, size: 80, color: darkTeal),
//                 const SizedBox(height: 20),
//                 const Text(
//                   "Profile Incomplete",
//                   style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   "Complete your profile to start receiving appointments.",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(color: Colors.grey),
//                 ),
//                 const SizedBox(height: 30),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: darkTeal,
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   onPressed: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => EditDoctorProfilePage(
//                           doctorId: uid,
//                           doctor: null,
//                         ),
//                       ),
//                     );
//                   },
//                   child: const Text("Complete Profile"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   /// Complete Doctor Profile View
//   Widget _buildProfileView(String uid) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           /// HEADER CARD WITH IMAGE
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: primaryTeal,
//               borderRadius: BorderRadius.circular(28),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.12),
//                   blurRadius: 12,
//                   offset: const Offset(0, 6),
//                 )
//               ],
//             ),
//             child: Column(
//               children: [
//                 CircleAvatar(
//                   radius: 55,
//                   backgroundColor: Colors.white,
//                   backgroundImage: doctor!.imageUrl.isNotEmpty
//                       ? NetworkImage(doctor!.imageUrl)
//                       : null,
//                   child: doctor!.imageUrl.isEmpty
//                       ? Icon(Icons.person, size: 60, color: darkTeal)
//                       : null,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   user!.name,
//                   style: const TextStyle(
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   doctor!.specialization,
//                   style: const TextStyle(color: Colors.white70),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 30),

//           _infoCard("Experience", "${doctor!.experience} Years", Icons.work),
//           _infoCard("Clinic Name", doctor!.clinicName, Icons.local_hospital),
//           _infoCard("Clinic Address", doctor!.clinicAddress, Icons.location_on),
//           _infoCard("About", doctor!.about, Icons.info_outline),

//           const SizedBox(height: 20),

//           _sectionTitle("Available Days"),
//           Wrap(
//             spacing: 8,
//             children: doctor!.availableDays
//                 .map((day) => Chip(label: Text(day)))
//                 .toList(),
//           ),

//           const SizedBox(height: 16),

//           _sectionTitle("Time Slots"),
//           Wrap(
//             spacing: 8,
//             children: doctor!.availableSlots
//                 .map((slot) => Chip(label: Text(slot)))
//                 .toList(),
//           ),

//           const SizedBox(height: 40),

//           ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: darkTeal,
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(30),
//               ),
//             ),
//             icon: const Icon(Icons.edit),
//             label: const Text("Edit Profile"),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => EditDoctorProfilePage(
//                     doctorId: uid,
//                     doctor: doctor,
//                   ),
//                 ),
//               ).then((_) => _loadProfile());
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _infoCard(String title, String value, IconData icon) {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       elevation: 6,
//       margin: const EdgeInsets.only(bottom: 16),
//       child: ListTile(
//         leading: Icon(icon, color: darkTeal),
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
//         subtitle: Text(value),
//       ),
//     );
//   }

//   Widget _sectionTitle(String text) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Padding(
//         padding: const EdgeInsets.only(bottom: 8),
//         child: Text(
//           text,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }

//   Future<void> _logout() async {
//     await FirebaseAuth.instance.signOut();
//     if (mounted) {
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (_) => const LoginPage()),
//         (route) => false,
//       );
//     }
//   }
// }



import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/app_user.dart';
import '../auth/login/login.dart';
import 'edit_doctor_profile.dart';

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  AppUser? user;
  bool loading = true;

  final Color primaryTeal = Color(0xFF00796B);
  final Color lightTeal = Color(0xFF4DB6AC);
  final Color cardGrey = Color(0xFFF8F9FA);
  final Color darkGrey = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => loading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final uid = currentUser.uid;

      // Get user data from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        user = AppUser.fromMap(userDoc.data()!, userDoc.id);
      }

      setState(() => loading = false);
    } catch (e) {
      setState(() => loading = false);
      debugPrint("Error loading doctor profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: primaryTeal),
        ),
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || user == null) {
      return const Scaffold(
        body: Center(child: Text("No logged in user")),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryTeal, lightTeal.withOpacity(0.3), Colors.white],
            stops: [0.0, 0.3, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: user!.isDoctorProfileComplete()
                    ? _buildProfileView()
                    : _buildIncompleteProfile(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Doctor Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  /// Profile Incomplete Card
  Widget _buildIncompleteProfile() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Image
              CircleAvatar(
                radius: 60,
                backgroundColor: cardGrey,
                backgroundImage: user!.imageUrl.isNotEmpty
                    ? NetworkImage(user!.imageUrl)
                    : null,
                child: user!.imageUrl.isEmpty
                    ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                    : null,
              ),
              const SizedBox(height: 20),
              // Name & Email
              Text(
                user!.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkGrey,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user!.email,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              // Incomplete Message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      "Profile Incomplete",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Complete your professional profile to start receiving appointments from patients.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Complete Profile Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text(
                    "Complete Profile",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditDoctorProfilePage(user: user!),
                      ),
                    ).then((_) => _loadProfile());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Complete Doctor Profile View
  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Profile Image
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: cardGrey,
                      backgroundImage: user!.imageUrl.isNotEmpty
                          ? NetworkImage(user!.imageUrl)
                          : null,
                      child: user!.imageUrl.isEmpty
                          ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  user!.name,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: darkGrey,
                  ),
                ),
                const SizedBox(height: 6),
                // Specialization
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user!.specialization ?? 'Veterinarian',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryTeal,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Email
                Text(
                  user!.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Professional Details
          _buildSectionTitle("Professional Details"),
          _infoCard("Experience", "${user!.experience ?? 0} Years", Icons.work_outline),
          _infoCard("Clinic Name", user!.clinicName ?? 'N/A', Icons.local_hospital_outlined),
          _infoCard("Clinic Address", user!.clinicAddress ?? 'N/A', Icons.location_on_outlined),
          _infoCard("Phone", user!.phone.isNotEmpty ? user!.phone : 'Not provided', Icons.phone_outlined),

          const SizedBox(height: 20),

          // About Section
          _buildSectionTitle("About"),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              user!.about ?? 'No description provided.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Available Days
          _buildSectionTitle("Available Days"),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (user!.availableDays ?? []).map((day) {
                return Chip(
                  label: Text(day),
                  backgroundColor: primaryTeal.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: primaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Time Slots
          _buildSectionTitle("Available Time Slots"),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (user!.availableSlots ?? []).map((slot) {
                return Chip(
                  label: Text(slot),
                  backgroundColor: lightTeal.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: primaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 40),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditDoctorProfilePage(user: user!),
                  ),
                ).then((_) => _loadProfile());
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkGrey,
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
            child: Icon(icon, color: primaryTeal, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: darkGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}