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


// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../model/app_user.dart';
// import '../auth/login/login.dart';
// import 'edit_doctor_profile.dart';
// import 'DoctorRatingsPage.dart';

// class DoctorProfilePage extends StatefulWidget {
//   const DoctorProfilePage({super.key});

//   @override
//   State<DoctorProfilePage> createState() => _DoctorProfilePageState();
// }

// class _DoctorProfilePageState extends State<DoctorProfilePage> {
//   AppUser? user;
//   bool loading = true;

//   final Color primaryTeal = Color(0xFF00796B);
//   final Color lightTeal = Color(0xFF4DB6AC);
//   final Color cardGrey = Color(0xFFF8F9FA);
//   final Color darkGrey = Color(0xFF2C3E50);

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

//       // Get user data from users collection
//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .get();

//       if (userDoc.exists) {
//         user = AppUser.fromMap(userDoc.data()!, userDoc.id);
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
//       return Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(color: primaryTeal),
//         ),
//       );
//     }

//     final currentUser = FirebaseAuth.instance.currentUser;
//     if (currentUser == null || user == null) {
//       return const Scaffold(
//         body: Center(child: Text("No logged in user")),
//       );
//     }

//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [primaryTeal, lightTeal.withOpacity(0.3), Colors.white],
//             stops: [0.0, 0.3, 0.5],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               _buildAppBar(),
//               Expanded(
//                 child: user!.isDoctorProfileComplete()
//                     ? _buildProfileView()
//                     : _buildIncompleteProfile(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAppBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text(
//             'Doctor Profile',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.logout, color: Colors.white),
//             onPressed: _logout,
//           ),
//         ],
//       ),
//     );
//   }

//   /// Profile Incomplete Card
//   Widget _buildIncompleteProfile() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Container(
//           padding: const EdgeInsets.all(32),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(24),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 20,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Profile Image
//               CircleAvatar(
//                 radius: 60,
//                 backgroundColor: cardGrey,
//                 backgroundImage: user!.imageUrl.isNotEmpty
//                     ? NetworkImage(user!.imageUrl)
//                     : null,
//                 child: user!.imageUrl.isEmpty
//                     ? Icon(Icons.person, size: 60, color: Colors.grey[400])
//                     : null,
//               ),
//               const SizedBox(height: 20),
//               // Name & Email
//               Text(
//                 user!.name,
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: darkGrey,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 user!.email,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               // Incomplete Message
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.orange, width: 1),
//                 ),
//                 child: Column(
//                   children: [
//                     Icon(Icons.info_outline, color: Colors.orange, size: 40),
//                     const SizedBox(height: 12),
//                     const Text(
//                       "Profile Incomplete",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       "Complete your professional profile to start receiving appointments from patients.",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 30),
//               // Complete Profile Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primaryTeal,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     elevation: 2,
//                   ),
//                   icon: const Icon(Icons.edit),
//                   label: const Text(
//                     "Complete Profile",
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => EditDoctorProfilePage(user: user!),
//                       ),
//                     ).then((_) => _loadProfile());
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Complete Doctor Profile View
//   Widget _buildProfileView() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           // Profile Header Card
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(24),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.08),
//                   blurRadius: 20,
//                   offset: const Offset(0, 10),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 // Profile Image
//                 Stack(
//                   children: [
//                     CircleAvatar(
//                       radius: 60,
//                       backgroundColor: cardGrey,
//                       backgroundImage: user!.imageUrl.isNotEmpty
//                           ? NetworkImage(user!.imageUrl)
//                           : null,
//                       child: user!.imageUrl.isEmpty
//                           ? Icon(Icons.person, size: 60, color: Colors.grey[400])
//                           : null,
//                     ),
//                     Positioned(
//                       bottom: 0,
//                       right: 0,
//                       child: Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.green,
//                           shape: BoxShape.circle,
//                           border: Border.all(color: Colors.white, width: 3),
//                         ),
//                         child: const Icon(
//                           Icons.verified,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 // Name
//                 Text(
//                   user!.name,
//                   style: TextStyle(
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                     color: darkGrey,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 // Specialization
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: primaryTeal.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     user!.specialization ?? 'Veterinarian',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: primaryTeal,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 // Email
//                 Text(
//                   user!.email,
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 20),

//           // Professional Details
//           _buildSectionTitle("Professional Details"),
//           _infoCard("Experience", "${user!.experience ?? 0} Years", Icons.work_outline),
//           _infoCard("Clinic Name", user!.clinicName ?? 'N/A', Icons.local_hospital_outlined),
//           _infoCard("Clinic Address", user!.clinicAddress ?? 'N/A', Icons.location_on_outlined),
//           _infoCard("Phone", user!.phone.isNotEmpty ? user!.phone : 'Not provided', Icons.phone_outlined),

//           const SizedBox(height: 20),

//           _buildSectionTitle("Patient Reviews"),
//           _buildPatientReviewsSection(),

//           const SizedBox(height: 20),

//           // About Section
//           _buildSectionTitle("About"),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.04),
//                   blurRadius: 10,
//                   offset: const Offset(0, 3),
//                 ),
//               ],
//             ),
//             child: Text(
//               user!.about ?? 'No description provided.',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[700],
//                 height: 1.5,
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),

//           // Available Days
//           _buildSectionTitle("Available Days"),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.04),
//                   blurRadius: 10,
//                   offset: const Offset(0, 3),
//                 ),
//               ],
//             ),
//             child: Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: (user!.availableDays ?? []).map((day) {
//                 return Chip(
//                   label: Text(day),
//                   backgroundColor: primaryTeal.withOpacity(0.1),
//                   labelStyle: TextStyle(
//                     color: primaryTeal,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),

//           const SizedBox(height: 20),

//           // Time Slots
//           _buildSectionTitle("Available Time Slots"),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.04),
//                   blurRadius: 10,
//                   offset: const Offset(0, 3),
//                 ),
//               ],
//             ),
//             child: Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: (user!.availableSlots ?? []).map((slot) {
//                 return Chip(
//                   label: Text(slot),
//                   backgroundColor: lightTeal.withOpacity(0.2),
//                   labelStyle: TextStyle(
//                     color: primaryTeal,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),

//           const SizedBox(height: 40),

//           // Edit Profile Button
//           SizedBox(
//             width: double.infinity,
//             height: 54,
//             child: ElevatedButton.icon(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryTeal,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 elevation: 2,
//               ),
//               icon: const Icon(Icons.edit_outlined),
//               label: const Text(
//                 "Edit Profile",
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => EditDoctorProfilePage(user: user!),
//                   ),
//                 ).then((_) => _loadProfile());
//               },
//             ),
//           ),
//           const SizedBox(height: 20),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12, left: 4),
//       child: Align(
//         alignment: Alignment.centerLeft,
//         child: Text(
//           title,
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: darkGrey,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _infoCard(String title, String value, IconData icon) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: primaryTeal.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(icon, color: primaryTeal, size: 24),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                     color: darkGrey,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPatientReviewsSection() {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return const SizedBox.shrink();

//     return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//       stream: FirebaseFirestore.instance
//           .collection('consultation_ratings')
//           .where('doctorId', isEqualTo: uid)
//           .orderBy('ratedAt', descending: true)
//           .limit(20)
//           .snapshots()
//           .handleError((error) {
//             print('[DoctorProfile] Error loading ratings: $error');
//           }),
//       builder: (context, snapshot) {
//         // Error handling
//         if (snapshot.hasError) {
//           print('[DoctorProfile] Stream error: ${snapshot.error}');
//           final errorMsg = snapshot.error.toString();
          
//           // Check if it's a composite index error
//           if (errorMsg.contains('composite') || errorMsg.contains('FAILED_PRECONDITION')) {
//             return _buildCompositeIndexErrorUI(uid);
//           }
          
//           // Other errors
//           return Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.red.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(color: Colors.red.withOpacity(0.3)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     const Icon(Icons.error_outline, color: Colors.red, size: 20),
//                     const SizedBox(width: 8),
//                     const Expanded(
//                       child: Text(
//                         'Unable to load ratings',
//                         style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   errorMsg,
//                   style: TextStyle(fontSize: 12, color: Colors.red[700]),
//                 ),
//               ],
//             ),
//           );
//         }
        
//         // Loading state
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: Padding(
//               padding: EdgeInsets.symmetric(vertical: 20),
//               child: CircularProgressIndicator(),
//             ),
//           );
//         }

//         final docs = snapshot.data?.docs ?? [];
        
//         if (docs.isEmpty) {
//           return Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.04),
//                   blurRadius: 10,
//                   offset: const Offset(0, 3),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(
//                     Icons.star_outline,
//                     size: 40,
//                     color: Colors.grey[400],
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'No Reviews Yet',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Patient ratings from completed consultations will appear here',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey[600],
//                     height: 1.4,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         // Calculate stats from actual rating data
//         double totalRating = 0;
//         for (var doc in docs) {
//           final data = doc.data();
//           totalRating += (data['doctorRating'] as num?)?.toDouble() ?? 0;
//         }
//         final averageRating = totalRating / docs.length;

//         // Sort for display
//         final displayDocs = docs.toList();
//         displayDocs.sort((a, b) {
//           final aTs = a.data()['ratedAt'] as Timestamp?;
//           final bTs = b.data()['ratedAt'] as Timestamp?;
//           final aMs = aTs?.millisecondsSinceEpoch ?? 0;
//           final bMs = bTs?.millisecondsSinceEpoch ?? 0;
//           return bMs.compareTo(aMs);
//         });

//         final top = displayDocs.take(3).toList();

//         return Column(
//           children: [
//             // Rating Summary Card (from actual consultation_ratings)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.04),
//                     blurRadius: 10,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.amber.withOpacity(0.15),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Icon(
//                       Icons.star_rounded,
//                       color: Colors.amber,
//                       size: 28,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           averageRating.toStringAsFixed(1),
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey[800],
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         _buildStaticStars(averageRating),
//                         const SizedBox(height: 4),
//                         Text(
//                           '${docs.length} verified ${docs.length == 1 ? 'review' : 'reviews'}',
//                           style: TextStyle(
//                             color: Colors.grey[700],
//                             fontSize: 13,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Recent Reviews List
//             ...top.map((doc) {
//               final data = doc.data();
//               final rating = (data['doctorRating'] as num?)?.toInt() ?? 0;
//               final review = (data['doctorFeedback'] ?? '').toString();
//               final ratedAt = data['ratedAt'] as Timestamp?;
//               final created = ratedAt?.toDate();
//               final dateLabel = created == null
//                   ? 'recent'
//                   : '${created.day}/${created.month}/${created.year}';

//               return Container(
//                 width: double.infinity,
//                 margin: const EdgeInsets.only(bottom: 10),
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(14),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.03),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: List.generate(5, (i) {
//                             return Icon(
//                               i < rating ? Icons.star : Icons.star_border,
//                               color: Colors.amber,
//                               size: 16,
//                             );
//                           }),
//                         ),
//                         Text(
//                           dateLabel,
//                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                         ),
//                       ],
//                     ),
//                     if (review.isNotEmpty) ...[
//                       const SizedBox(height: 8),
//                       Text(
//                         review,
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.grey[800],
//                           height: 1.35,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               );
//             }).toList(),

//             // View All Button (if more than 3 ratings exist)
//             if (docs.length > 3) ...[
//               const SizedBox(height: 12),
//               SizedBox(
//                 width: double.infinity,
//                 child: OutlinedButton.icon(
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 13),
//                     side: BorderSide(color: Colors.blue.withOpacity(0.5)),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const DoctorRatingsPage(),
//                       ),
//                     );
//                   },
//                   icon: const Icon(Icons.arrow_forward, size: 16),
//                   label: Text(
//                     'View All ${docs.length} Reviews',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 13,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildRatingSummaryCard() {
//     final average = ((user?.averageRating ?? 0) as num).toDouble();
//     final reviews = ((user?.totalReviews ?? 0) as num).toInt();

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: average > 0 ? Colors.amber.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               Icons.star_rounded,
//               color: average > 0 ? Colors.amber : Colors.grey[400],
//               size: 28,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   average > 0 ? average.toStringAsFixed(1) : 'No ratings yet',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: average > 0 ? darkGrey : Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 _buildStaticStars(average),
//                 const SizedBox(height: 4),
//                 Text(
//                   reviews > 0
//                       ? '$reviews verified ${reviews == 1 ? 'review' : 'reviews'}'
//                       : 'No verified reviews yet',
//                   style: TextStyle(
//                     color: reviews > 0 ? Colors.grey[700] : Colors.grey[600],
//                     fontSize: 13,
//                     fontWeight: reviews > 0 ? FontWeight.normal : FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStaticStars(double rating) {
//     final full = rating.floor();
//     final half = (rating - full) >= 0.5;

//     return Row(
//       children: List.generate(5, (i) {
//         if (i < full) {
//           return const Icon(Icons.star, color: Colors.amber, size: 18);
//         }
//         if (i == full && half) {
//           return const Icon(Icons.star_half, color: Colors.amber, size: 18);
//         }
//         return const Icon(Icons.star_border, color: Colors.amber, size: 18);
//       }),
//     );
//   }

//   Widget _buildRecentReviewsList() {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return const SizedBox.shrink();

//     return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//       stream: FirebaseFirestore.instance
//           .collection('consultation_ratings')
//           .where('doctorId', isEqualTo: uid)
//           .orderBy('ratedAt', descending: true)
//           .limit(20)
//           .snapshots()
//           .handleError((error) {
//             print('[DoctorProfile] Error loading ratings: $error');
//           }),
//       builder: (context, snapshot) {
//         // Error handling
//         if (snapshot.hasError) {
//           print('[DoctorProfile] Stream error: ${snapshot.error}');
//           final errorMsg = snapshot.error.toString();
          
//           // Check if it's a composite index error
//           if (errorMsg.contains('composite') || errorMsg.contains('FAILED_PRECONDITION')) {
//             return _buildCompositeIndexErrorUI(uid);
//           }
          
//           // Other errors
//           return Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.red.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(color: Colors.red.withOpacity(0.3)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     const Icon(Icons.error_outline, color: Colors.red, size: 20),
//                     const SizedBox(width: 8),
//                     const Expanded(
//                       child: Text(
//                         'Unable to load ratings',
//                         style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   errorMsg,
//                   style: TextStyle(fontSize: 12, color: Colors.red[700]),
//                 ),
//               ],
//             ),
//           );
//         }
        
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Text(
//               'No reviews yet. Ratings from completed consultations will appear here.',
//               style: TextStyle(color: Colors.grey[700]),
//             ),
//           );
//         }

//         final docs = snapshot.data!.docs.toList();
//         docs.sort((a, b) {
//           final aTs = a.data()['ratedAt'] as Timestamp?;
//           final bTs = b.data()['ratedAt'] as Timestamp?;
//           final aMs = aTs?.millisecondsSinceEpoch ?? 0;
//           final bMs = bTs?.millisecondsSinceEpoch ?? 0;
//           return bMs.compareTo(aMs);
//         });

//         final top = docs.take(3).toList();

//         return Column(
//           children: [
//             ...top.map((doc) {
//               final data = doc.data();
//               final rating = (data['doctorRating'] as num?)?.toInt() ?? 0;
//               final review = (data['doctorFeedback'] ?? '').toString();
//               final ratedAt = data['ratedAt'] as Timestamp?;
//               final created = ratedAt?.toDate();
//               final dateLabel = created == null
//                   ? 'recent'
//                   : '${created.day}/${created.month}/${created.year}';

//               return Container(
//                 width: double.infinity,
//                 margin: const EdgeInsets.only(bottom: 10),
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(14),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.03),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: List.generate(5, (i) {
//                             return Icon(
//                               i < rating ? Icons.star : Icons.star_border,
//                               color: Colors.amber,
//                               size: 16,
//                             );
//                           }),
//                         ),
//                         Text(
//                           dateLabel,
//                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                         ),
//                       ],
//                     ),
//                     if (review.isNotEmpty) ...[
//                     const SizedBox(height: 8),
//                     Text(
//                       review,
//                       style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.35),
//                     ),
//                   ],
//                 ],
//               ),
//             );
//           }).toList(),
//           // View All Button (if more than 3 ratings exist)
//           if (docs.length > 3) ...[
//             const SizedBox(height: 12),
//             SizedBox(
//               width: double.infinity,
//               child: OutlinedButton.icon(
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 13),
//                   side: BorderSide(color: Colors.blue.withOpacity(0.5)),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => const DoctorRatingsPage(),
//                     ),
//                   );
//                 },
//                 icon: const Icon(Icons.arrow_forward, size: 16),
//                 label: Text(
//                   'View All ${docs.length} Reviews',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 13,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ],
//         );
//       },
//     );
//   }

//   Widget _buildCompositeIndexErrorUI(String doctorId) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.blue.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.blue.withOpacity(0.4), width: 1.5),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Icon(Icons.info, color: Colors.blue, size: 20),
//               ),
//               const SizedBox(width: 12),
//               const Expanded(
//                 child: Text(
//                   'Setting up ratings display',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                     color: Colors.blue,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),

//           // Description
//           Text(
//             'Your ratings are being saved, but we need to set up a database index for them to display.',
//             style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.4),
//           ),
//           const SizedBox(height: 12),

//           // Quick Fix Section
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: Colors.grey[300]!),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   '🚀 Quick Fix (1-2 minutes):',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   '1. Open Firebase Console\n'
//                   '2. Go to Firestore Database > Indexes\n'
//                   '3. Click Create Index\n'
//                   '4. Collection: consultation_ratings\n'
//                   '5. Field 1: doctorId (Ascending ⬆️)\n'
//                   '6. Field 2: ratedAt (Descending ⬇️)\n'
//                   '7. Click Create & wait 1-2 minutes',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[700],
//                     height: 1.6,
//                     fontFamily: 'monospace',
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),

//           // Why This Happens
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Colors.amber.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '⚠️',
//                   style: TextStyle(fontSize: 14),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Firestore requires a composite index for queries that combine filters with sorting.',
//                     style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),

//           // Action Button
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               onPressed: () {
//                 // Copy helpful text to clipboard
//                 _copyIndexInstructions();
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Instructions copied! Open Firebase Console to create the index.'),
//                     duration: Duration(seconds: 2),
//                   ),
//                 );
//               },
//               child: const Text(
//                 'Copy Setup Instructions',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 13,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),

//           // Refresh Button
//           SizedBox(
//             width: double.infinity,
//             child: OutlinedButton(
//               style: OutlinedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 side: BorderSide(color: Colors.blue.withOpacity(0.4)),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               onPressed: () {
//                 setState(() {});
//               },
//               child: const Text(
//                 'Check Again (After Creating Index)',
//                 style: TextStyle(
//                   color: Colors.blue,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 13,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _copyIndexInstructions() {
//     final instructions = '''
// Firebase Composite Index Setup:

// 1. Go to Firebase Console: https://console.firebase.google.com
// 2. Select your project: dignovet-b6dd6
// 3. Navigate to Firestore Database > Indexes
// 4. Click "Create Index"
// 5. Fill in these details:
//    - Collection ID: consultation_ratings
//    - Query scope: Collection (not documents)
//    - Field 1: doctorId (Direction: Ascending ⬆️)
//    - Field 2: ratedAt (Direction: Descending ⬇️)
// 6. Click "Create Index"
// 7. Wait for status to show "Enabled" (1-2 minutes)
// 8. Refresh your app

// After this, your ratings will appear instantly!
// ''';
    
//     // In a real app, you'd use Clipboard, but for now showing the message
//     print('[DoctorProfile] Composite Index Setup Instructions:\n$instructions');
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
import 'DoctorRatingsPage.dart';

class DoctorProfilePage extends StatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  AppUser? user;
  bool loading = true;

  final Color primaryTeal = const Color(0xFF00796B);
  final Color lightTeal = const Color(0xFF4DB6AC);
  final Color cardGrey = const Color(0xFFF8F9FA);
  final Color darkGrey = const Color(0xFF2C3E50);

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
            stops: const [0.0, 0.3, 0.5],
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

  // ─── App Bar ───────────────────────────────────────────────────────────────

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

  // ─── Incomplete Profile ────────────────────────────────────────────────────

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
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.orange, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      "Profile Incomplete",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
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
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text(
                    "Complete Profile",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditDoctorProfilePage(user: user!)),
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

  // ─── Complete Profile View ─────────────────────────────────────────────────

  Widget _buildProfileView() {
    // ✅ FIX: Sirf wo slots dikhao jo doctor ne actually save ki hain
    final savedSlots = user!.availableSlots ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header Card
          _buildHeaderCard(),

          const SizedBox(height: 20),

          // Professional Details
          _buildSectionTitle("Professional Details"),
          _infoCard("Experience",
              "${user!.experience ?? 0} Years", Icons.work_outline),
          _infoCard("Clinic Name", user!.clinicName ?? 'N/A',
              Icons.local_hospital_outlined),
          _infoCard("Clinic Address", user!.clinicAddress ?? 'N/A',
              Icons.location_on_outlined),
          _infoCard(
            "Phone",
            user!.phone.isNotEmpty ? user!.phone : 'Not provided',
            Icons.phone_outlined,
          ),

          const SizedBox(height: 20),

          // Patient Reviews
          _buildSectionTitle("Patient Reviews"),
          _buildPatientReviewsSection(),

          const SizedBox(height: 20),

          // About
          _buildSectionTitle("About"),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Text(
              user!.about ?? 'No description provided.',
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[700], height: 1.5),
            ),
          ),

          const SizedBox(height: 20),

          // Available Days
          _buildSectionTitle("Available Days"),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: (user!.availableDays ?? []).isEmpty
                ? Text("No days selected",
                    style: TextStyle(color: Colors.grey[500]))
                : Wrap(
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

          // ✅ FIXED: Sirf selected/saved slots dikhenge — poori list nahi
          _buildSectionTitle("Available Time Slots"),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: savedSlots.isEmpty
                ? Text("No time slots selected",
                    style: TextStyle(color: Colors.grey[500]))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: savedSlots.map((slot) {
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
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text(
                "Edit Profile",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EditDoctorProfilePage(user: user!)),
                ).then((_) => _loadProfile());
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── Header Card ───────────────────────────────────────────────────────────

  Widget _buildHeaderCard() {
    return Container(
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
                  child: const Icon(Icons.verified,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user!.name,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: darkGrey,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Text(
            user!.email,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ─── Patient Reviews Section ───────────────────────────────────────────────

  Widget _buildPatientReviewsSection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('consultation_ratings')
          .where('doctorId', isEqualTo: uid)
          .orderBy('ratedAt', descending: true)
          .limit(20)
          .snapshots()
          .handleError((error) {
        debugPrint('[DoctorProfile] Error loading ratings: $error');
      }),
      builder: (context, snapshot) {
        // Error state
        if (snapshot.hasError) {
          final errorMsg = snapshot.error.toString();
          if (errorMsg.contains('composite') ||
              errorMsg.contains('FAILED_PRECONDITION')) {
            return _buildCompositeIndexErrorUI(uid);
          }
          return _buildErrorCard(errorMsg);
        }

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        // Empty state
        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.star_outline,
                      size: 40, color: Colors.grey[400]),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Reviews Yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Patient ratings from completed consultations will appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4),
                ),
              ],
            ),
          );
        }

        // Average calculate karo
        double totalRating = 0;
        for (var doc in docs) {
          totalRating +=
              (doc.data()['doctorRating'] as num?)?.toDouble() ?? 0;
        }
        final averageRating = totalRating / docs.length;

        // Date ke hisaab se sort
        final sorted = docs.toList()
          ..sort((a, b) {
            final aMs =
                (a.data()['ratedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final bMs =
                (b.data()['ratedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return bMs.compareTo(aMs);
          });

        final top3 = sorted.take(3).toList();

        return Column(
          children: [
            // Rating Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 2),
                        _buildStaticStars(averageRating),
                        const SizedBox(height: 4),
                        Text(
                          '${docs.length} verified ${docs.length == 1 ? 'review' : 'reviews'}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Top 3 Reviews
            ...top3.map((doc) => _buildReviewCard(doc.data())),

            // View All Button (agar 3 se zyada reviews hain)
            if (docs.length > 3) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: Colors.blue.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DoctorRatingsPage()),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(
                    'View All ${docs.length} Reviews',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> data) {
    final rating = (data['doctorRating'] as num?)?.toInt() ?? 0;
    final review = (data['doctorFeedback'] ?? '').toString();
    final ratedAt = data['ratedAt'] as Timestamp?;
    final created = ratedAt?.toDate();
    final dateLabel = created == null
        ? 'recent'
        : '${created.day}/${created.month}/${created.year}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
              Text(
                dateLabel,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          if (review.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[800], height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorCard(String errorMsg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Unable to load ratings',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(errorMsg,
              style: TextStyle(fontSize: 12, color: Colors.red[700])),
        ],
      ),
    );
  }

  // ─── Composite Index Error UI ──────────────────────────────────────────────

  Widget _buildCompositeIndexErrorUI(String doctorId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Setting up ratings display',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your ratings are being saved, but we need to set up a database index for them to display.',
            style: TextStyle(
                fontSize: 13, color: Colors.grey[800], height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🚀 Quick Fix (1-2 minutes):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  '1. Open Firebase Console\n'
                  '2. Go to Firestore Database > Indexes\n'
                  '3. Click Create Index\n'
                  '4. Collection: consultation_ratings\n'
                  '5. Field 1: doctorId (Ascending ⬆️)\n'
                  '6. Field 2: ratedAt (Descending ⬇️)\n'
                  '7. Click Create & wait 1-2 minutes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.6,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Firestore requires a composite index for queries that combine filters with sorting.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[700], height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.blue.withOpacity(0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => setState(() {}),
              child: const Text(
                'Check Again (After Creating Index)',
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Helpers ────────────────────────────────────────────────────────

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
      decoration: _cardDecoration(),
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
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: darkGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticStars(double rating) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    return Row(
      children: List.generate(5, (i) {
        if (i < full) {
          return const Icon(Icons.star, color: Colors.amber, size: 18);
        }
        if (i == full && half) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 18);
        }
        return const Icon(Icons.star_border, color: Colors.amber, size: 18);
      }),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  // ─── Logout ────────────────────────────────────────────────────────────────

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