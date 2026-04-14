// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:pdf/pdf.dart';
// import 'package:printing/printing.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_application_1/services/file_download_service.dart';
// import 'package:flutter_application_1/view/Doctor/DoctorNotificationsPage.dart';
// import 'package:flutter_application_1/view/Doctor/doctor_chat_screen.dart';
// import 'package:flutter_application_1/view/Doctor/doctor_profile_page.dart';
// import 'package:flutter_application_1/services/Appointment Service/appointment_services.dart';
// import 'package:flutter_application_1/services/notification service/notification_service.dart';
// import 'package:flutter_application_1/model/appointment_model.dart';
// import 'package:flutter_application_1/model/app_user.dart';
// import 'package:flutter_application_1/view/Doctor/DoctorAppointmentRequests.dart';
// import 'package:flutter_application_1/view/Doctor/Apponitment_approval_page_new.dart';
// import 'package:flutter_application_1/view/User/customer_support_chat.dart';

// class DoctorDashboardPage extends StatefulWidget {
//   const DoctorDashboardPage({super.key});

//   @override
//   State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
// }

// class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
//   final AppointmentService _appointmentService = AppointmentService();
//   final NotificationService _notificationService = NotificationService();
//   // Doctor profile data
//   AppUser? doctorProfile;
//   bool isLoadingProfile = true;
  
//   // Professional Color Scheme (matching doctor profile)
//   final Color primaryTeal = Color(0xFF00796B);
//   final Color lightTeal = Color(0xFF4DB6AC);
//   final Color cardGrey = Color(0xFFF8F9FA);
//   final Color darkGrey = Color(0xFF2C3E50);
//   String _selectedAnalyticsView = 'daily';
//   String _selectedDashboardTab = 'overview';
//   String _prescriptionOwnerSearch = '';
//   String _prescriptionAppointmentSearch = '';
//   String _prescriptionDateRange = 'all';
//   String _prescriptionStatusFilter = 'all';
//   String _prescriptionSortBy = 'latest';
//   int? _prescriptionMonthFilter;
//   int? _prescriptionYearFilter;
//   static const String _analyticsViewPrefKey = 'doctor_dashboard_analytics_view';

//   @override
//   void initState() {
//     super.initState();
//     _loadSavedAnalyticsView();
//     _loadDoctorProfile();
//   }

//   Future<void> _loadSavedAnalyticsView() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final saved = prefs.getString(_analyticsViewPrefKey);
//       if (!mounted) return;
//       if (saved == 'daily' || saved == 'weekly' || saved == 'monthly') {
//         setState(() {
//           _selectedAnalyticsView = saved!;
//         });
//       }
//     } catch (_) {}
//   }

//   Future<void> _setAnalyticsView(String value) async {
//     if (_selectedAnalyticsView == value) return;
//     setState(() {
//       _selectedAnalyticsView = value;
//     });
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(_analyticsViewPrefKey, value);
//     } catch (_) {}
//   }

//   Future<void> _loadDoctorProfile() async {
//     try {
//       final currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) return;

//       final docSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(currentUser.uid)
//           .get();

//       if (!mounted) return;
//       if (docSnapshot.exists) {
//         setState(() {
//           doctorProfile = AppUser.fromMap(docSnapshot.data()!, docSnapshot.id);
//           isLoadingProfile = false;
//         });
//       } else {
//         setState(() => isLoadingProfile = false);
//       }
//     } catch (e) {
//       log('Error loading doctor profile: $e');
//       if (!mounted) return;
//       setState(() => isLoadingProfile = false);
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     if (isLoadingProfile) {
//       return Scaffold(
//         body: Center(child: CircularProgressIndicator(color: primaryTeal)),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: Text(
//           'DignoVet',
//           style: TextStyle(
//             color: primaryTeal,
//             fontWeight: FontWeight.bold,
//             fontSize: 24,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.search, color: darkGrey, size: 26),
//             onPressed: () {},
//           ),
//           // Notifications Button with Indicator
//           Stack(
//             children: [
//               IconButton(
//                 icon: Icon(Icons.notifications_active_rounded, color: primaryTeal, size: 26),
//                 tooltip: 'Notifications',
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => const DoctorNotificationsPage(),
//                     ),
//                   );
//                 },
//               ),
//               Positioned(
//                 top: 6,
//                 right: 6,
//                 child: Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     color: Colors.red,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Text(
//                     '!',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           IconButton(
//             icon: Icon(Icons.person_outline, color: darkGrey, size: 26),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => const DoctorProfilePage()),
//               ).then((_) => _loadDoctorProfile());
//             },
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildDashboardTabSwitcher(),
//               const SizedBox(height: 20),
//               if (_selectedDashboardTab == 'overview') ...[
//                 // ===== TOP QUICK ACTION BUTTONS (Chat, Support & Requests) =====
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: [
//                       // Chat Module Card
//                       GestureDetector(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const DoctorChatListScreen(),
//                             ),
//                           );
//                         },
//                         child: Container(
//                           width: 140,
//                           padding: const EdgeInsets.all(18),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [primaryTeal, lightTeal],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             borderRadius: BorderRadius.circular(20),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: primaryTeal.withOpacity(0.25),
//                                 blurRadius: 12,
//                                 offset: const Offset(0, 6),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             children: [
//                               Icon(
//                                 Icons.chat_bubble_outline,
//                                 size: 40,
//                                 color: Colors.white,
//                               ),
//                               const SizedBox(height: 10),
//                               const Text(
//                                 'Chats',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),

//                       // Appointment Requests Card
//                       GestureDetector(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const DoctorAppointmentRequestsPage(),
//                             ),
//                           );
//                         },
//                         child: Container(
//                           width: 140,
//                           padding: const EdgeInsets.all(18),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [Colors.orange.shade600, Colors.orange.shade400],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             borderRadius: BorderRadius.circular(20),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.orange.withOpacity(0.25),
//                                 blurRadius: 12,
//                                 offset: const Offset(0, 6),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             children: [
//                               Icon(
//                                 Icons.calendar_today_rounded,
//                                 size: 40,
//                                 color: Colors.white,
//                               ),
//                               const SizedBox(height: 10),
//                               const Text(
//                                 'Requests',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),

//                       // Customer Support Card
//                       GestureDetector(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const CustomerSupportChatPage(),
//                             ),
//                           );
//                         },
//                         child: Container(
//                           width: 140,
//                           padding: const EdgeInsets.all(18),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: primaryTeal.withOpacity(0.12),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             children: [
//                               Icon(Icons.support_agent_rounded, color: primaryTeal, size: 40),
//                               const SizedBox(height: 10),
//                               Text(
//                                 'Support',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: darkGrey,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 28),

//                 // Professional Welcome Card with Complete Doctor Details
//                 _buildDoctorProfileCard(),
//                 const SizedBox(height: 32),

//                 // Stats Cards
//                 _buildProfessionalAppointmentsAnalytics(),

//                 const SizedBox(height: 32),
//               ] else ...[
//                 _buildPrescriptionHistorySection(),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Professional Doctor Profile Card with All Details
//   Widget _buildDoctorProfileCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [primaryTeal, lightTeal, lightTeal.withOpacity(0.5)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(28),
//         boxShadow: [
//           BoxShadow(
//             color: primaryTeal.withOpacity(0.3),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Doctor Profile Image
//               Container(
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.white, width: 4),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.2),
//                       blurRadius: 15,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: CircleAvatar(
//                   radius: 55,
//                   backgroundColor: Colors.white,
//                   backgroundImage: doctorProfile?.imageUrl.isNotEmpty == true
//                       ? NetworkImage(doctorProfile!.imageUrl)
//                       : null,
//                   child: doctorProfile?.imageUrl.isEmpty != false
//                       ? Icon(Icons.person, size: 60, color: primaryTeal)
//                       : null,
//                 ),
//               ),
//               const SizedBox(width: 20),
//               // Doctor Details
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Welcome Back,',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.white70,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       doctorProfile?.name ?? 'Doctor',
//                       style: const TextStyle(
//                         fontSize: 28,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 8),
//                     // Specialization Badge
//                     if (doctorProfile?.specialization != null)
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 14,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.25),
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(
//                             color: Colors.white.withOpacity(0.4),
//                           ),
//                         ),
//                         child: Text(
//                           doctorProfile!.specialization!,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 24),

//           // Professional Information Grid
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: Colors.white.withOpacity(0.3)),
//             ),
//             child: Column(
//               children: [
//                 // Experience & Clinic Name Row
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildInfoItem(
//                         Icons.work_outline,
//                         'Experience',
//                         '${doctorProfile?.experience ?? 0} Years',
//                       ),
//                     ),
//                     Container(
//                       width: 1,
//                       height: 40,
//                       color: Colors.white.withOpacity(0.3),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: _buildInfoItem(
//                         Icons.local_hospital_outlined,
//                         'Clinic',
//                         doctorProfile?.clinicName ?? 'N/A',
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 16),

//                 // Contact Information
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildInfoItem(
//                         Icons.email_outlined,
//                         'Email',
//                         doctorProfile?.email ?? 'N/A',
//                       ),
//                     ),
//                   ],
//                 ),

//                 if (doctorProfile?.phone.isNotEmpty == true) ...[
//                   const SizedBox(height: 16),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: _buildInfoItem(
//                           Icons.phone_outlined,
//                           'Phone',
//                           doctorProfile!.phone,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],

//                 if (doctorProfile?.clinicAddress != null &&
//                     doctorProfile!.clinicAddress!.isNotEmpty) ...[
//                   const SizedBox(height: 16),
//                   _buildInfoItem(
//                     Icons.location_on_outlined,
//                     'Clinic Address',
//                     doctorProfile!.clinicAddress!,
//                   ),
//                 ],
//               ],
//             ),
//           ),

//           const SizedBox(height: 16),

//           // Quick Status Message
//           Text(
//             'You are doing great today! 🌟',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.white.withOpacity(0.9),
//               fontStyle: FontStyle.italic,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Helper widget for info items in the profile card
//   Widget _buildInfoItem(IconData icon, String label, String value) {
//     return Row(
//       children: [
//         Icon(icon, color: Colors.white, size: 20),
//         const SizedBox(width: 8),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.8),
//                   fontSize: 11,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDashboardTabSwitcher() {
//     Widget buildTab({
//       required String label,
//       required String value,
//       required IconData icon,
//     }) {
//       final isSelected = _selectedDashboardTab == value;
//       return Expanded(
//         child: InkWell(
//           borderRadius: BorderRadius.circular(14),
//           onTap: () {
//             setState(() {
//               _selectedDashboardTab = value;
//             });
//           },
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 220),
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(14),
//               gradient: isSelected
//                   ? LinearGradient(colors: [primaryTeal, lightTeal])
//                   : null,
//               color: isSelected ? null : Colors.white,
//               border: Border.all(
//                 color: isSelected ? Colors.transparent : primaryTeal.withOpacity(0.2),
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(icon, size: 18, color: isSelected ? Colors.white : primaryTeal),
//                 const SizedBox(width: 7),
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w700,
//                     fontSize: 13,
//                     color: isSelected ? Colors.white : darkGrey,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     return Container(
//       padding: const EdgeInsets.all(6),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: primaryTeal.withOpacity(0.18)),
//       ),
//       child: Row(
//         children: [
//           buildTab(
//             label: 'Overview',
//             value: 'overview',
//             icon: Icons.space_dashboard_rounded,
//           ),
//           const SizedBox(width: 8),
//           buildTab(
//             label: 'Prescriptions',
//             value: 'prescriptions',
//             icon: Icons.receipt_long_rounded,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPrescriptionHistorySection() {
//     final doctorId = FirebaseAuth.instance.currentUser?.uid;
//     if (doctorId == null) {
//       return _buildPlaceholderCard('Doctor session not found');
//     }

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: lightTeal.withOpacity(0.28)),
//       ),
//       child: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('prescriptions')
//             .where('doctorId', isEqualTo: doctorId)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: CircularProgressIndicator(color: primaryTeal),
//               ),
//             );
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Prescription History',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: primaryTeal,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   'No prescription has been sent yet.',
//                   style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
//                 ),
//               ],
//             );
//           }

//           final docs = snapshot.data!.docs.toList()
//             ..sort((a, b) {
//               final at = (a.data() as Map<String, dynamic>)['createdAt'];
//               final bt = (b.data() as Map<String, dynamic>)['createdAt'];
//               final ad = at is Timestamp ? at.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
//               final bd = bt is Timestamp ? bt.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
//               return bd.compareTo(ad);
//             });

//           final filteredDocs = docs.where((d) {
//             final data = d.data() as Map<String, dynamic>;
//             final owner = (data['patientName'] ?? '').toString().toLowerCase();
//             final appointmentId = (data['appointmentId'] ?? '').toString().toLowerCase();
//             final animal = (data['animalName'] ?? '').toString().toLowerCase();
//             final status = (data['status'] ?? 'sent').toString().toLowerCase();
//             final rawDownloads = (data['downloadCount'] ?? 0);
//             final downloadCount = rawDownloads is int
//               ? rawDownloads
//               : int.tryParse(rawDownloads.toString()) ?? 0;
//             final normalizedStatus = downloadCount > 0 ? 'downloaded' : status;
//             final createdAt = data['createdAt'];
//             final createdDate = createdAt is Timestamp ? createdAt.toDate() : null;

//             final ownerQuery = _prescriptionOwnerSearch.trim().toLowerCase();
//             final appointmentQuery = _prescriptionAppointmentSearch.trim().toLowerCase();

//             final ownerMatch = ownerQuery.isEmpty || owner.contains(ownerQuery) || animal.contains(ownerQuery);
//             final appointmentMatch = appointmentQuery.isEmpty || appointmentId.contains(appointmentQuery);
//             final rangeMatch = _isInSelectedPrescriptionRange(createdDate);
//             final statusMatch = _prescriptionStatusFilter == 'all' || normalizedStatus == _prescriptionStatusFilter;
//             final monthYearMatch = _isInSelectedMonthYear(createdDate);

//             return ownerMatch && appointmentMatch && rangeMatch && statusMatch && monthYearMatch;
//           }).toList()
//             ..sort((a, b) {
//               final aData = a.data() as Map<String, dynamic>;
//               final bData = b.data() as Map<String, dynamic>;

//               if (_prescriptionSortBy == 'most_downloaded') {
//                 final aDownloads = (aData['downloadCount'] ?? 0);
//                 final bDownloads = (bData['downloadCount'] ?? 0);
//                 final aCount = aDownloads is int ? aDownloads : int.tryParse(aDownloads.toString()) ?? 0;
//                 final bCount = bDownloads is int ? bDownloads : int.tryParse(bDownloads.toString()) ?? 0;
//                 if (aCount != bCount) return bCount.compareTo(aCount);
//               }

//               final aTs = aData['createdAt'];
//               final bTs = bData['createdAt'];
//               final aDate = aTs is Timestamp ? aTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
//               final bDate = bTs is Timestamp ? bTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
//               return bDate.compareTo(aDate);
//             });

//           final thisMonthCount = docs.where((d) {
//             final map = d.data() as Map<String, dynamic>;
//             final ts = map['createdAt'];
//             if (ts is! Timestamp) return false;
//             final dt = ts.toDate();
//             final now = DateTime.now();
//             return dt.year == now.year && dt.month == now.month;
//           }).length;

//           final filteredDownloads = filteredDocs.fold<int>(0, (sum, d) {
//             final map = d.data() as Map<String, dynamic>;
//             final count = (map['downloadCount'] ?? 0);
//             return sum + (count is int ? count : int.tryParse(count.toString()) ?? 0);
//           });

//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.receipt_long_rounded, color: primaryTeal, size: 24),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Prescription History',
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: primaryTeal,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: [
//                   _buildMiniBadge('Total', docs.length.toString()),
//                   _buildMiniBadge('This Month', thisMonthCount.toString()),
//                   _buildMiniBadge('Filtered', filteredDocs.length.toString()),
//                   _buildMiniBadge('Downloads', filteredDownloads.toString()),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       onChanged: (v) {
//                         setState(() {
//                           _prescriptionOwnerSearch = v;
//                         });
//                       },
//                       decoration: InputDecoration(
//                         hintText: 'Search pet owner/pet',
//                         prefixIcon: const Icon(Icons.search_rounded, size: 18),
//                         isDense: true,
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: primaryTeal.withOpacity(0.2)),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: TextField(
//                       onChanged: (v) {
//                         setState(() {
//                           _prescriptionAppointmentSearch = v;
//                         });
//                       },
//                       decoration: InputDecoration(
//                         hintText: 'Appointment ID',
//                         prefixIcon: const Icon(Icons.confirmation_number_rounded, size: 18),
//                         isDense: true,
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: primaryTeal.withOpacity(0.2)),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: [
//                     _buildPrescriptionRangeChip('All', 'all'),
//                     const SizedBox(width: 8),
//                     _buildPrescriptionRangeChip('Last 7 days', '7d'),
//                     const SizedBox(width: 8),
//                     _buildPrescriptionRangeChip('Last 30 days', '30d'),
//                     const SizedBox(width: 8),
//                     _buildPrescriptionRangeChip('Last 90 days', '90d'),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Expanded(
//                     child: DropdownButtonFormField<String>(
//                       value: _prescriptionStatusFilter,
//                       isExpanded: true,
//                       decoration: InputDecoration(
//                         labelText: 'Status',
//                         isDense: true,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       items: const [
//                         DropdownMenuItem(value: 'all', child: Text('All')),
//                         DropdownMenuItem(value: 'sent', child: Text('Sent')),
//                         DropdownMenuItem(value: 'downloaded', child: Text('Downloaded')),
//                       ],
//                       onChanged: (value) {
//                         if (value == null) return;
//                         setState(() {
//                           _prescriptionStatusFilter = value;
//                         });
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: DropdownButtonFormField<String>(
//                       value: _prescriptionSortBy,
//                       isExpanded: true,
//                       decoration: InputDecoration(
//                         labelText: 'Sort By',
//                         isDense: true,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       items: const [
//                         DropdownMenuItem(value: 'latest', child: Text('Latest')),
//                         DropdownMenuItem(value: 'most_downloaded', child: Text('Most Downloads')),
//                       ],
//                       onChanged: (value) {
//                         if (value == null) return;
//                         setState(() {
//                           _prescriptionSortBy = value;
//                         });
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Expanded(
//                     child: DropdownButtonFormField<int?>(
//                       value: _prescriptionMonthFilter,
//                       isExpanded: true,
//                       decoration: InputDecoration(
//                         labelText: 'Month',
//                         isDense: true,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       items: [
//                         const DropdownMenuItem<int?>(value: null, child: Text('All Months')),
//                         ...List.generate(
//                           12,
//                           (i) => DropdownMenuItem<int?>(
//                             value: i + 1,
//                             child: Text('${i + 1}'),
//                           ),
//                         ),
//                       ],
//                       onChanged: (value) {
//                         setState(() {
//                           _prescriptionMonthFilter = value;
//                         });
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: DropdownButtonFormField<int?>(
//                       value: _prescriptionYearFilter,
//                       isExpanded: true,
//                       decoration: InputDecoration(
//                         labelText: 'Year',
//                         isDense: true,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       items: [
//                         const DropdownMenuItem<int?>(value: null, child: Text('All Years')),
//                         ...List.generate(
//                           6,
//                           (i) {
//                             final year = DateTime.now().year - i;
//                             return DropdownMenuItem<int?>(
//                               value: year,
//                               child: Text('$year'),
//                             );
//                           },
//                         ),
//                       ],
//                       onChanged: (value) {
//                         setState(() {
//                           _prescriptionYearFilter = value;
//                         });
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 14),
//               if (filteredDocs.isEmpty)
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade50,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.grey.shade200),
//                   ),
//                   child: Text(
//                     'No prescriptions matched current filters.',
//                     style: TextStyle(color: Colors.grey[700]),
//                   ),
//                 ),
//               ...filteredDocs.take(60).map((doc) {
//                 final data = doc.data() as Map<String, dynamic>;
//                 final ts = data['createdAt'];
//                 final dateText = _formatPrescriptionHistoryDate(ts);
//                 final pdfUrl = (data['pdfUrl'] ?? '').toString();
//                 final pdfFileName = (data['pdfFileName'] ?? 'prescription.pdf').toString();
//                 final patientName = (data['patientName'] ?? 'Pet Owner').toString();
//                 final animalName = (data['animalName'] ?? '').toString();
//                 final appointmentId = (data['appointmentId'] ?? '').toString();
//                 final downloadCount = (data['downloadCount'] ?? 0).toString();
//                 final followUpText = _normalizeFollowUpText(
//                   (data['followUp'] ?? '').toString(),
//                 );

//                 return Container(
//                   margin: const EdgeInsets.only(bottom: 10),
//                   padding: const EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     color: cardGrey,
//                     borderRadius: BorderRadius.circular(14),
//                     border: Border.all(color: primaryTeal.withOpacity(0.12)),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(Icons.picture_as_pdf_rounded, color: primaryTeal, size: 20),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               animalName.isEmpty ? patientName : '$patientName • $animalName',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 14,
//                                 color: darkGrey,
//                               ),
//                             ),
//                           ),
//                           Text(
//                             dateText,
//                             style: TextStyle(color: Colors.grey[700], fontSize: 12),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         appointmentId.isEmpty
//                             ? 'Appointment: Not linked'
//                             : 'Appointment ID: $appointmentId',
//                         style: TextStyle(color: Colors.grey[700], fontSize: 12),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Downloads: $downloadCount',
//                         style: TextStyle(color: Colors.grey[700], fontSize: 12),
//                       ),
//                       if (followUpText.isNotEmpty) ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           'Follow-up: $followUpText',
//                           style: TextStyle(color: Colors.grey[700], fontSize: 12),
//                         ),
//                       ],
//                       const SizedBox(height: 8),
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: Wrap(
//                           spacing: 8,
//                           children: [
//                             TextButton.icon(
//                               onPressed: pdfUrl.isEmpty ? null : () => _openPrescriptionPdf(pdfUrl),
//                               icon: const Icon(Icons.open_in_new_rounded, size: 18),
//                               label: const Text('Open'),
//                             ),
//                             TextButton.icon(
//                               onPressed: pdfUrl.isEmpty
//                                   ? null
//                                   : () => _downloadPrescriptionPdf(
//                                         pdfUrl: pdfUrl,
//                                         fileName: pdfFileName,
//                                       ),
//                               icon: const Icon(Icons.download_rounded, size: 18),
//                               label: const Text('Download'),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildMiniBadge(String label, String value) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: primaryTeal.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(30),
//       ),
//       child: Text(
//         '$label: $value',
//         style: TextStyle(color: primaryTeal, fontWeight: FontWeight.w700, fontSize: 12),
//       ),
//     );
//   }

//   String _formatPrescriptionHistoryDate(dynamic ts) {
//     if (ts is! Timestamp) return 'N/A';
//     return DateFormat('dd MMM yyyy').format(ts.toDate());
//   }

//   String _normalizeFollowUpText(String raw) {
//     final value = raw.trim();
//     if (value.isEmpty || value.toLowerCase() == 'n/a') return '';
//     if (RegExp(r'^\d+$').hasMatch(value)) {
//       return '$value days';
//     }
//     return value;
//   }

//   Widget _buildPrescriptionRangeChip(String label, String value) {
//     final isSelected = _prescriptionDateRange == value;
//     return ChoiceChip(
//       label: Text(label),
//       selected: isSelected,
//       onSelected: (_) {
//         setState(() {
//           _prescriptionDateRange = value;
//         });
//       },
//       selectedColor: primaryTeal.withOpacity(0.18),
//       labelStyle: TextStyle(
//         color: isSelected ? primaryTeal : darkGrey,
//         fontWeight: FontWeight.w700,
//       ),
//       side: BorderSide(color: primaryTeal.withOpacity(0.22)),
//       backgroundColor: Colors.white,
//     );
//   }

//   bool _isInSelectedPrescriptionRange(DateTime? createdAt) {
//     if (createdAt == null) return _prescriptionDateRange == 'all';
//     if (_prescriptionDateRange == 'all') return true;

//     final now = DateTime.now();
//     if (_prescriptionDateRange == '7d') {
//       return createdAt.isAfter(now.subtract(const Duration(days: 7)));
//     }
//     if (_prescriptionDateRange == '30d') {
//       return createdAt.isAfter(now.subtract(const Duration(days: 30)));
//     }
//     if (_prescriptionDateRange == '90d') {
//       return createdAt.isAfter(now.subtract(const Duration(days: 90)));
//     }
//     return true;
//   }

//   bool _isInSelectedMonthYear(DateTime? createdAt) {
//     if (createdAt == null) {
//       return _prescriptionMonthFilter == null && _prescriptionYearFilter == null;
//     }

//     if (_prescriptionMonthFilter != null && createdAt.month != _prescriptionMonthFilter) {
//       return false;
//     }
//     if (_prescriptionYearFilter != null && createdAt.year != _prescriptionYearFilter) {
//       return false;
//     }
//     return true;
//   }

//   Future<void> _openPrescriptionPdf(String url) async {
//     final uri = Uri.tryParse(url);
//     if (uri == null) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Invalid prescription URL.')),
//       );
//       return;
//     }

//     final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
//     if (!launched && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Unable to open PDF.')),
//       );
//     }
//   }

//   Future<void> _downloadPrescriptionPdf({
//     required String pdfUrl,
//     required String fileName,
//   }) async {
//     try {
//       final savedPath = await FileDownloadService.downloadPdf(
//         url: pdfUrl,
//         fileName: fileName,
//       );

//       if (!mounted) return;
//       if (savedPath == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Unable to download PDF.')),
//         );
//         return;
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Prescription saved: $savedPath')),
//       );
//     } catch (_) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Unable to download PDF.')),
//       );
//     }
//   }

//   Widget _buildStatCard(String value, String label, IconData icon) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [cardGrey, Colors.white],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: lightTeal.withOpacity(0.3)),
//         boxShadow: [
//           BoxShadow(
//             color: primaryTeal.withOpacity(0.1),
//             blurRadius: 12,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Icon(icon, size: 36, color: primaryTeal),
//           const SizedBox(height: 12),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 36,
//               fontWeight: FontWeight.bold,
//               color: primaryTeal,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 15,
//               color: darkGrey,
//               height: 1.3,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLiveStatsSection() {
//     return const SizedBox.shrink();
//   }

//   Widget _buildProfessionalAppointmentsAnalytics() {
//     final doctorId = FirebaseAuth.instance.currentUser?.uid;
//     if (doctorId == null) {
//       return _buildPlaceholderCard('Doctor session not found');
//     }

//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('appointments')
//           .where('doctorId', isEqualTo: doctorId)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(24),
//               border: Border.all(color: lightTeal.withOpacity(0.35)),
//             ),
//             child: Center(
//               child: CircularProgressIndicator(color: primaryTeal),
//             ),
//           );
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(24),
//               border: Border.all(color: lightTeal.withOpacity(0.35)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Appointments Analytics',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: primaryTeal,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'No appointment data yet. New requests and approvals will appear here.',
//                   style: TextStyle(
//                     color: Colors.grey[700],
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         final appointments = snapshot.data!.docs
//             .map((doc) => AppointmentModel.fromMap(
//                   doc.data() as Map<String, dynamic>,
//                   doc.id,
//                 ))
//             .toList()
//           ..sort((a, b) => b.date.compareTo(a.date));

//         final now = DateTime.now().toLocal();
//         final todayStart = DateTime(now.year, now.month, now.day);
//         final weekStart = todayStart
//             .subtract(Duration(days: now.weekday - 1));
//         final weekEnd = weekStart.add(const Duration(days: 7));
//         final monthStart = DateTime(now.year, now.month, 1);
//         final monthEnd = now.month == 12
//             ? DateTime(now.year + 1, 1, 1)
//             : DateTime(now.year, now.month + 1, 1);

//         final approvedAppointments = appointments
//           .where((a) => _statusBucket(a.status) == 'approved')
//           .toList();
//         final pendingAppointments = appointments
//           .where((a) => _statusBucket(a.status) == 'pending')
//           .toList();
//         final declinedAppointments = appointments
//           .where((a) => _statusBucket(a.status) == 'declined')
//           .toList();

//         final dailyAppointments = appointments.where((a) {
//           return _isTodayAppointment(a, todayStart);
//         }).toList();

//         final weeklyAppointments = appointments.where((a) {
//           final appointmentDay = _appointmentDay(a.date);
//           return !appointmentDay.isBefore(weekStart) && appointmentDay.isBefore(weekEnd);
//         }).toList();

//         final monthlyAppointments = appointments.where((a) {
//           final appointmentDay = _appointmentDay(a.date);
//           return !appointmentDay.isBefore(monthStart) && appointmentDay.isBefore(monthEnd);
//         }).toList();

//         final weeklyApproved = approvedAppointments.where((a) {
//           final appointmentDay = _appointmentDay(a.date);
//           return !appointmentDay.isBefore(weekStart) && appointmentDay.isBefore(weekEnd);
//         }).toList();

//         final monthlyApproved = approvedAppointments.where((a) {
//           final appointmentDay = _appointmentDay(a.date);
//           return !appointmentDay.isBefore(monthStart) && appointmentDay.isBefore(monthEnd);
//         }).toList();

//         final totalStats = _statusCounts(appointments);
//         final dailyStats = _statusCounts(dailyAppointments);
//         final weeklyStats = _statusCounts(weeklyAppointments);
//         final monthlyStats = _statusCounts(monthlyAppointments);

//         final sevenDayDates = List.generate(
//           7,
//           (index) => DateTime(now.year, now.month, now.day)
//               .subtract(Duration(days: 6 - index)),
//         );

//         final graphValues = <int>[];
//         final graphLabels = <String>[];
//         for (final day in sevenDayDates) {
//           final count = appointments.where((a) {
//             return _isSameDate(_appointmentDay(a.date), day);
//           }).length;
//           graphValues.add(count);
//           graphLabels.add(_weekdayLabel(day.weekday));
//         }

//         final selectedPeriodAppointments = _selectedAnalyticsView == 'daily'
//             ? dailyAppointments
//             : _selectedAnalyticsView == 'weekly'
//                 ? weeklyAppointments
//                 : monthlyAppointments;
//         final selectedPeriodTitle = _selectedAnalyticsView == 'daily'
//             ? 'Daily Appointments'
//             : _selectedAnalyticsView == 'weekly'
//                 ? 'Weekly Appointments'
//                 : 'Monthly Appointments';

//         final dynamicGraph = _buildDynamicGraphData(
//           selectedView: _selectedAnalyticsView,
//           now: now,
//           dailyAppointments: dailyAppointments,
//           weeklyAppointments: weeklyAppointments,
//           monthlyAppointments: monthlyAppointments,
//           weekStart: weekStart,
//           monthStart: monthStart,
//         );

//         return Container(
//           width: double.infinity,
//           padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [cardGrey, Colors.white],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.circular(28),
//             border: Border.all(color: lightTeal.withOpacity(0.28)),
//             boxShadow: [
//               BoxShadow(
//                 color: primaryTeal.withOpacity(0.1),
//                 blurRadius: 15,
//                 offset: const Offset(0, 8),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.analytics_rounded, color: primaryTeal, size: 24),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Text(
//                       'Appointments Analytics',
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: primaryTeal,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: () => _exportAnalyticsPdf(
//                       total: appointments.length,
//                       approved: approvedAppointments.length,
//                       pending: pendingAppointments.length,
//                       weeklyApproved: weeklyApproved.length,
//                       monthlyApproved: monthlyApproved.length,
//                       selectedTitle: selectedPeriodTitle,
//                       selectedAppointments: selectedPeriodAppointments,
//                     ),
//                     tooltip: 'Export PDF Report',
//                     icon: Icon(Icons.picture_as_pdf_rounded, color: primaryTeal),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 18),
//               Wrap(
//                 spacing: 10,
//                 runSpacing: 10,
//                 children: [
//                   _buildAnalyticsTile(
//                     title: 'Total',
//                     value: appointments.length.toString(),
//                     icon: Icons.list_alt_rounded,
//                     color: primaryTeal,
//                   ),
//                   _buildAnalyticsTile(
//                     title: 'Approved',
//                     value: totalStats['approved']!.toString(),
//                     icon: Icons.check_circle_rounded,
//                     color: Colors.green,
//                   ),
//                   _buildAnalyticsTile(
//                     title: 'Pending',
//                     value: totalStats['pending']!.toString(),
//                     icon: Icons.schedule_rounded,
//                     color: Colors.orange,
//                   ),
//                   _buildAnalyticsTile(
//                     title: 'Completed',
//                     value: totalStats['completed']!.toString(),
//                     icon: Icons.task_alt_rounded,
//                     color: Colors.blue,
//                   ),
//                   _buildAnalyticsTile(
//                     title: 'Declined',
//                     value: totalStats['declined']!.toString(),
//                     icon: Icons.cancel_rounded,
//                     color: Colors.red,
//                   ),
//                   _buildAnalyticsTile(
//                     title: 'Weekly Total',
//                     value: weeklyAppointments.length.toString(),
//                     icon: Icons.calendar_view_week_rounded,
//                     color: Colors.indigo,
//                   ),
//                   _buildAnalyticsTile(
//                     title: 'Monthly Total',
//                     value: monthlyAppointments.length.toString(),
//                     icon: Icons.calendar_month_rounded,
//                     color: Colors.deepPurple,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 22),
//               _buildTodaySummaryStrip(
//                 total: dailyAppointments.length,
//                 approved: dailyStats['approved']!,
//                 pending: dailyStats['pending']!,
//                 declined: dailyStats['declined']!,
//               ),
//               const SizedBox(height: 12),
//               _buildPeriodStatsCards(
//                 weeklyStats: weeklyStats,
//                 monthlyStats: monthlyStats,
//                 weeklyTotal: weeklyAppointments.length,
//                 monthlyTotal: monthlyAppointments.length,
//               ),
//               const SizedBox(height: 14),
//               _buildGraphCard(
//                 title: dynamicGraph['title'] as String,
//                 values: dynamicGraph['values'] as List<int>,
//                 labels: dynamicGraph['labels'] as List<String>,
//                 barColors: dynamicGraph['barColors'] as List<Color>,
//                 legendLabels: dynamicGraph['legendLabels'] as List<String>?,
//                 legendColors: dynamicGraph['legendColors'] as List<Color>?,
//               ),
//               const SizedBox(height: 16),
//               _buildTodayAppointmentsSection(
//                 dailyAppointments: dailyAppointments,
//                 approved: dailyStats['approved']!,
//                 pending: dailyStats['pending']!,
//                 declined: dailyStats['declined']!,
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 'Appointments Explorer',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: darkGrey,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildRangeButton(
//                       label: 'Daily',
//                       count: dailyAppointments.length,
//                       value: 'daily',
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: _buildRangeButton(
//                       label: 'Weekly',
//                       count: weeklyAppointments.length,
//                       value: 'weekly',
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: _buildRangeButton(
//                       label: 'Monthly',
//                       count: monthlyAppointments.length,
//                       value: 'monthly',
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 14),
//               if (_selectedAnalyticsView == 'daily')
//                 _buildPeriodAppointmentsSection(
//                   title: 'Daily Appointments',
//                   subtitle:
//                       'Today: ${dailyAppointments.length} appointments (Approved: ${dailyStats['approved']}, Pending: ${dailyStats['pending']}, Declined: ${dailyStats['declined']})',
//                   appointments: dailyAppointments,
//                   emptyText: 'No appointments scheduled for today.',
//                 ),
//               if (_selectedAnalyticsView == 'weekly')
//                 _buildPeriodAppointmentsSection(
//                   title: 'Weekly Appointments',
//                   subtitle: 'All appointments in current week',
//                   appointments: weeklyAppointments,
//                   emptyText: 'No appointments found in this week.',
//                 ),
//               if (_selectedAnalyticsView == 'monthly')
//                 _buildPeriodAppointmentsSection(
//                   title: 'Monthly Appointments',
//                   subtitle: 'All appointments in current month',
//                   appointments: monthlyAppointments,
//                   emptyText: 'No appointments found in this month.',
//                 ),
//               const SizedBox(height: 16),
//               _buildApprovedDetailsSection(
//                 title: 'Weekly Approved Summary',
//                 subtitle: 'Approved appointments in this week',
//                 appointments: weeklyApproved,
//                 emptyText: 'No approved appointments for this week yet.',
//               ),
//               const SizedBox(height: 16),
//               _buildApprovedDetailsSection(
//                 title: 'Monthly Approved Summary',
//                 subtitle: 'Approved appointments in this month',
//                 appointments: monthlyApproved,
//                 emptyText: 'No approved appointments for this month yet.',
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const DoctorAppointmentRequestsPage(),
//                       ),
//                     );
//                   },
//                   icon: const Icon(Icons.visibility_outlined),
//                   label: const Text(
//                     'Open Full Appointment Manager',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: primaryTeal,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildRangeButton({
//     required String label,
//     required int count,
//     required String value,
//   }) {
//     final isSelected = _selectedAnalyticsView == value;

//     return GestureDetector(
//       onTap: () {
//         _setAnalyticsView(value);
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 220),
//         curve: Curves.easeOut,
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
//         decoration: BoxDecoration(
//           gradient: isSelected
//               ? LinearGradient(colors: [primaryTeal, lightTeal])
//               : null,
//           color: isSelected ? null : Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isSelected ? Colors.transparent : primaryTeal.withOpacity(0.25),
//           ),
//           boxShadow: isSelected
//               ? [
//                   BoxShadow(
//                     color: primaryTeal.withOpacity(0.24),
//                     blurRadius: 8,
//                     offset: const Offset(0, 4),
//                   ),
//                 ]
//               : [],
//         ),
//         child: FittedBox(
//           fit: BoxFit.scaleDown,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w700,
//                   color: isSelected ? Colors.white : darkGrey,
//                 ),
//               ),
//               const SizedBox(width: 6),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: isSelected
//                       ? Colors.white.withOpacity(0.2)
//                       : primaryTeal.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(
//                   count.toString(),
//                   style: TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w800,
//                     color: isSelected ? Colors.white : primaryTeal,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPeriodAppointmentsSection({
//     required String title,
//     required String subtitle,
//     required List<AppointmentModel> appointments,
//     required String emptyText,
//   }) {
//     final items = appointments.take(8).toList();

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: lightTeal.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: darkGrey,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             subtitle,
//             style: TextStyle(
//               color: Colors.grey[700],
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 12),
//           if (items.isEmpty)
//             Text(
//               emptyText,
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             )
//           else
//             ...items.map(_buildPeriodAppointmentTile),
//         ],
//       ),
//     );
//   }

//   Widget _buildPeriodAppointmentTile(AppointmentModel appointment) {
//     final status = appointment.status.toLowerCase();
//     final isReapprovableDeclined =
//         status == 'declined' &&
//         appointment.declinedAt != null &&
//         DateTime.now().difference(appointment.declinedAt!.toDate()) <=
//             const Duration(days: 1) &&
//         DateTime.now().difference(appointment.declinedAt!.toDate()).inSeconds >= 0;
//     final isApproved = status == 'approved';
//     final isPending = status == 'pending';
//     final statusColor = isReapprovableDeclined
//         ? Colors.blue
//         : isApproved
//         ? Colors.green
//         : isPending
//             ? Colors.orange
//             : Colors.red;
//     final statusLabel = isReapprovableDeclined
//         ? 'Re-approve'
//         : isApproved
//         ? 'Approved'
//         : isPending
//             ? 'Pending'
//             : 'Declined';
//     final declineCategory = (appointment.declineCategoryText ?? '').trim();
//     final doctorNote = (appointment.doctorDeclineMessage ?? '').trim();
//     final declineText = (appointment.declineReasonText ?? '').trim();
//     final hasDeclineInfo = status == 'declined' &&
//       (doctorNote.isNotEmpty || declineText.isNotEmpty || declineCategory.isNotEmpty);

//     return InkWell(
//       onTap: (isPending || isReapprovableDeclined)
//           ? () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => AppointmentApprovalPage(appointment: appointment),
//                 ),
//               );
//             }
//           : null,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 10),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: cardGrey,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(7),
//                   decoration: BoxDecoration(
//                     color: statusColor.withOpacity(0.12),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(Icons.event_available_rounded, color: statusColor, size: 16),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         appointment.animalName,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w700,
//                           color: darkGrey,
//                         ),
//                       ),
//                       const SizedBox(height: 3),
//                       Text(
//                         'Appointment On: ${_formatAppointmentSchedule(appointment)}',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[700],
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         'Booked On: ${_formatBookedOn(appointment)}',
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: Colors.grey[600],
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
//                   decoration: BoxDecoration(
//                     color: statusColor.withOpacity(0.12),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Text(
//                     statusLabel,
//                     style: TextStyle(
//                       color: statusColor,
//                       fontSize: 11,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Problem: ${appointment.problem}',
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[800],
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             if (hasDeclineInfo) ...[
//               const SizedBox(height: 8),
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.red.withOpacity(0.06),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.red.withOpacity(0.25)),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (declineCategory.isNotEmpty)
//                       Text(
//                         'Reason: $declineCategory',
//                         style: TextStyle(
//                           color: Colors.red.shade800,
//                           fontWeight: FontWeight.w700,
//                           fontSize: 11,
//                         ),
//                       ),
//                     if (doctorNote.isNotEmpty) ...[
//                       const SizedBox(height: 4),
//                       Text(
//                         'Doctor note: $doctorNote',
//                         maxLines: 3,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           color: Colors.red.shade900,
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ] else if (declineText.isNotEmpty) ...[
//                       const SizedBox(height: 4),
//                       Text(
//                         declineText,
//                         maxLines: 3,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           color: Colors.red.shade900,
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAnalyticsTile({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Container(
//       width: 155,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: color.withOpacity(0.25)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: color, size: 18),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: darkGrey,
//                   ),
//                 ),
//                 Text(
//                   title,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: Colors.grey[700],
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGraphCard({
//     required String title,
//     required List<int> values,
//     required List<String> labels,
//     required List<Color> barColors,
//     List<String>? legendLabels,
//     List<Color>? legendColors,
//   }) {
//     final maxValue = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
//     final safeMax = maxValue == 0 ? 1 : maxValue;
//     final noData = values.every((v) => v == 0);

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: lightTeal.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: darkGrey,
//             ),
//           ),
//           if ((legendLabels ?? const <String>[]).isNotEmpty &&
//               (legendColors ?? const <Color>[]).isNotEmpty) ...[
//             const SizedBox(height: 8),
//             Wrap(
//               spacing: 10,
//               runSpacing: 8,
//               children: List.generate(legendLabels!.length, (index) {
//                 final color = legendColors![index % legendColors.length];
//                 return Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: color.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(color: color.withOpacity(0.35)),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         width: 8,
//                         height: 8,
//                         decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//                       ),
//                       const SizedBox(width: 6),
//                       Text(
//                         legendLabels[index],
//                         style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w700,
//                           color: darkGrey,
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }),
//             ),
//           ],
//           const SizedBox(height: 14),
//           SizedBox(
//             height: 170,
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: List.generate(values.length, (index) {
//                 final value = values[index];
//                 final ratio = value / safeMax;
//                 final barHeight = value == 0 ? 8.0 : 28 + (ratio * 98);

//                 return Expanded(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       Text(
//                         value.toString(),
//                         style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w700,
//                           color: darkGrey,
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Container(
//                         width: 20,
//                         height: barHeight,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                             colors: [
//                               barColors[index % barColors.length].withOpacity(0.7),
//                               barColors[index % barColors.length],
//                             ],
//                           ),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         labels[index],
//                         style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey[700],
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }),
//             ),
//           ),
//           if (noData) ...[
//             const SizedBox(height: 10),
//             Text(
//               'No appointments found for this selected period yet.',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[700],
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildTodaySummaryStrip({
//     required int total,
//     required int approved,
//     required int pending,
//     required int declined,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: lightTeal.withOpacity(0.25)),
//       ),
//       child: Wrap(
//         spacing: 8,
//         runSpacing: 8,
//         children: [
//           _buildStatusPill('Today', total.toString(), primaryTeal),
//           _buildStatusPill('Approved', approved.toString(), Colors.green),
//           _buildStatusPill('Pending', pending.toString(), Colors.orange),
//           _buildStatusPill('Declined', declined.toString(), Colors.red),
//         ],
//       ),
//     );
//   }

//   Widget _buildTodayAppointmentsSection({
//     required List<AppointmentModel> dailyAppointments,
//     required int approved,
//     required int pending,
//     required int declined,
//   }) {
//     final displayItems = dailyAppointments.take(6).toList();

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: lightTeal.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Today Appointments Snapshot',
//             style: TextStyle(
//               color: darkGrey,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Total: ${dailyAppointments.length} • Approved: $approved • Pending: $pending • Declined: $declined',
//             style: TextStyle(
//               color: Colors.grey[700],
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 10),
//           if (displayItems.isEmpty)
//             Text(
//               'No appointments captured for today yet.',
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             )
//           else
//             ...displayItems.map(_buildPeriodAppointmentTile),
//         ],
//       ),
//     );
//   }

//   Widget _buildPeriodStatsCards({
//     required Map<String, int> weeklyStats,
//     required Map<String, int> monthlyStats,
//     required int weeklyTotal,
//     required int monthlyTotal,
//   }) {
//     Widget buildCard({
//       required String title,
//       required int total,
//       required Map<String, int> stats,
//       required Color color,
//       required IconData icon,
//     }) {
//       return Expanded(
//         child: Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: color.withOpacity(0.28)),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, size: 16, color: color),
//                   const SizedBox(width: 6),
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: TextStyle(
//                         color: color,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 'Total: $total',
//                 style: TextStyle(
//                   color: darkGrey,
//                   fontWeight: FontWeight.w700,
//                   fontSize: 12,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 'A:${stats['approved']}  P:${stats['pending']}  D:${stats['declined']}',
//                 style: TextStyle(
//                   color: Colors.grey[700],
//                   fontWeight: FontWeight.w600,
//                   fontSize: 11,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Row(
//       children: [
//         buildCard(
//           title: 'This Week',
//           total: weeklyTotal,
//           stats: weeklyStats,
//           color: Colors.indigo,
//           icon: Icons.calendar_view_week_rounded,
//         ),
//         const SizedBox(width: 10),
//         buildCard(
//           title: 'This Month',
//           total: monthlyTotal,
//           stats: monthlyStats,
//           color: Colors.deepPurple,
//           icon: Icons.calendar_month_rounded,
//         ),
//       ],
//     );
//   }

//   Widget _buildStatusPill(String label, String value, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(22),
//         border: Border.all(color: color.withOpacity(0.35)),
//       ),
//       child: Text(
//         '$label: $value',
//         style: TextStyle(
//           color: color,
//           fontWeight: FontWeight.w700,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }

//   Widget _buildApprovedDetailsSection({
//     required String title,
//     required String subtitle,
//     required List<AppointmentModel> appointments,
//     required String emptyText,
//   }) {
//     final displayAppointments = appointments.take(5).toList();

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: lightTeal.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 17,
//               fontWeight: FontWeight.bold,
//               color: darkGrey,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             subtitle,
//             style: TextStyle(
//               color: Colors.grey[700],
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 12),
//           if (displayAppointments.isEmpty)
//             Text(
//               emptyText,
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             )
//           else
//             ...displayAppointments.map(_buildApprovedAppointmentTile),
//         ],
//       ),
//     );
//   }

//   Widget _buildApprovedAppointmentTile(AppointmentModel appointment) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: cardGrey,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.green.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   appointment.animalName,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w700,
//                     color: darkGrey,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   'Appointment On: ${_formatAppointmentSchedule(appointment)}',
//                   style: TextStyle(
//                     color: Colors.grey[700],
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   'Booked On: ${_formatBookedOn(appointment)}',
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 11,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 8),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
//             decoration: BoxDecoration(
//               color: primaryTeal.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Text(
//               'Approved',
//               style: TextStyle(
//                 color: primaryTeal,
//                 fontSize: 11,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _weekdayLabel(int weekday) {
//     switch (weekday) {
//       case DateTime.monday:
//         return 'Mon';
//       case DateTime.tuesday:
//         return 'Tue';
//       case DateTime.wednesday:
//         return 'Wed';
//       case DateTime.thursday:
//         return 'Thu';
//       case DateTime.friday:
//         return 'Fri';
//       case DateTime.saturday:
//         return 'Sat';
//       case DateTime.sunday:
//         return 'Sun';
//       default:
//         return '';
//     }
//   }

//   String _formatShortDate(Timestamp timestamp) {
//     final date = timestamp.toDate();
//     return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
//   }

//   String _formatAppointmentSchedule(AppointmentModel appointment) {
//     final date = appointment.date.toDate().toLocal();
//     final dayDate = DateFormat('EEE, dd MMM yyyy').format(date);
//     final time = appointment.time.trim();
//     return time.isEmpty ? dayDate : '$dayDate  •  $time';
//   }

//   String _formatBookedOn(AppointmentModel appointment) {
//     final bookedAt = appointment.createdAt;
//     if (bookedAt == null) {
//       return 'Not recorded';
//     }
//     final booked = bookedAt.toDate().toLocal();
//     return DateFormat('EEE, dd MMM yyyy  •  hh:mm a').format(booked);
//   }

//   Map<String, Object> _buildDynamicGraphData({
//     required String selectedView,
//     required DateTime now,
//     required List<AppointmentModel> dailyAppointments,
//     required List<AppointmentModel> weeklyAppointments,
//     required List<AppointmentModel> monthlyAppointments,
//     required DateTime weekStart,
//     required DateTime monthStart,
//   }) {
//     if (selectedView == 'daily') {
//         final approved =
//           dailyAppointments.where((a) => _statusBucket(a.status) == 'approved').length;
//         final pending =
//           dailyAppointments.where((a) => _statusBucket(a.status) == 'pending').length;
//         final declined =
//           dailyAppointments.where((a) => _statusBucket(a.status) == 'declined').length;
//       return {
//         'title': 'Today Status Distribution',
//         'labels': <String>['Approved', 'Pending', 'Declined'],
//         'values': <int>[approved, pending, declined],
//         'barColors': <Color>[Colors.green, Colors.orange, Colors.red],
//         'legendLabels': <String>['Approved', 'Pending', 'Declined'],
//         'legendColors': <Color>[Colors.green, Colors.orange, Colors.red],
//       };
//     }

//     if (selectedView == 'weekly') {
//       final labels = <String>[];
//       final values = <int>[];
//       for (int i = 0; i < 7; i++) {
//         final day = weekStart.add(Duration(days: i));
//         final count = weeklyAppointments.where((a) {
//           final d = a.date.toDate().toLocal();
//           return _isSameDate(d, day);
//         }).length;
//         labels.add(_weekdayLabel(day.weekday));
//         values.add(count);
//       }
//       return {
//         'title': 'Weekly Appointments Trend',
//         'labels': labels,
//         'values': values,
//         'barColors': List<Color>.filled(labels.length, primaryTeal),
//         'legendLabels': <String>[],
//         'legendColors': <Color>[],
//       };
//     }

//     final labels = <String>['W1', 'W2', 'W3', 'W4', 'W5'];
//     final values = List<int>.filled(5, 0);
//     for (final appointment in monthlyAppointments) {
//       final date = appointment.date.toDate().toLocal();
//       if (date.year != now.year || date.month != now.month) continue;
//       final weekIndex = ((date.day - 1) ~/ 7).clamp(0, 4);
//       values[weekIndex] += 1;
//     }
//     return {
//       'title': 'Monthly Week-wise Appointments',
//       'labels': labels,
//       'values': values,
//       'barColors': List<Color>.filled(labels.length, primaryTeal),
//       'legendLabels': <String>[],
//       'legendColors': <Color>[],
//     };
//   }

//   Future<void> _exportAnalyticsPdf({
//     required int total,
//     required int approved,
//     required int pending,
//     required int weeklyApproved,
//     required int monthlyApproved,
//     required String selectedTitle,
//     required List<AppointmentModel> selectedAppointments,
//   }) async {
//     try {
//       final doc = pw.Document();
//       final generatedAt = DateTime.now();
//       final doctorName = doctorProfile?.name ?? 'Doctor';
//       final clinicName = doctorProfile?.clinicName?.trim().isNotEmpty == true
//           ? doctorProfile!.clinicName!
//           : 'DignoVet Clinic';
//       final doctorSpecialization =
//           doctorProfile?.specialization?.trim().isNotEmpty == true
//               ? doctorProfile!.specialization!
//               : 'Veterinary Specialist';

//       Uint8List? logoBytes;
//       try {
//         final data = await rootBundle.load('assets/login/cow.png');
//         logoBytes = data.buffer.asUint8List();
//       } catch (_) {
//         logoBytes = null;
//       }

//       String rangeTitleUrduRoman;
//       switch (_selectedAnalyticsView) {
//         case 'daily':
//           rangeTitleUrduRoman = 'Rozana Appointments';
//           break;
//         case 'weekly':
//           rangeTitleUrduRoman = 'Haftewar Appointments';
//           break;
//         default:
//           rangeTitleUrduRoman = 'Mahana Appointments';
//       }

//       doc.addPage(
//         pw.MultiPage(
//           pageFormat: PdfPageFormat.a4,
//           margin: const pw.EdgeInsets.all(24),
//           footer: (context) => pw.Container(
//             alignment: pw.Alignment.centerRight,
//             margin: const pw.EdgeInsets.only(top: 8),
//             child: pw.Text(
//               'Page ${context.pageNumber} / ${context.pagesCount}',
//               style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
//             ),
//           ),
//           build: (context) => [
//             pw.Container(
//               padding: const pw.EdgeInsets.all(14),
//               decoration: pw.BoxDecoration(
//                 gradient: const pw.LinearGradient(
//                   colors: [PdfColors.teal700, PdfColors.teal400],
//                 ),
//                 borderRadius: pw.BorderRadius.circular(10),
//               ),
//               child: pw.Row(
//                 crossAxisAlignment: pw.CrossAxisAlignment.center,
//                 children: [
//                   if (logoBytes != null)
//                     pw.Container(
//                       height: 42,
//                       width: 42,
//                       margin: const pw.EdgeInsets.only(right: 12),
//                       child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.cover),
//                     ),
//                   pw.Expanded(
//                     child: pw.Column(
//                       crossAxisAlignment: pw.CrossAxisAlignment.start,
//                       children: [
//                         pw.Text(
//                           clinicName,
//                           style: pw.TextStyle(
//                             fontSize: 17,
//                             fontWeight: pw.FontWeight.bold,
//                             color: PdfColors.white,
//                           ),
//                         ),
//                         pw.SizedBox(height: 2),
//                         pw.Text(
//                           'Doctor Analytics Report / Doctor Report',
//                           style: const pw.TextStyle(
//                             fontSize: 11,
//                             color: PdfColors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             pw.SizedBox(height: 8),
//             pw.Text('Doctor Name / Doctor ka Naam: $doctorName'),
//             pw.Text('Specialization / Maharat: $doctorSpecialization'),
//             pw.Text('Generated / Banaya gaya: ${generatedAt.toLocal()}'),
//             pw.SizedBox(height: 16),
//             pw.Container(
//               padding: const pw.EdgeInsets.all(12),
//               decoration: pw.BoxDecoration(
//                 border: pw.Border.all(color: PdfColors.teal200),
//                 borderRadius: pw.BorderRadius.circular(8),
//               ),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(
//                     'Summary / Khulasa',
//                     style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                   ),
//                   pw.SizedBox(height: 6),
//                   pw.Text('Total Appointments / Kul Appointments: $total'),
//                   pw.Text('Approved / Manzoor: $approved'),
//                   pw.Text('Pending / Intezaar mein: $pending'),
//                   pw.Text('Weekly Approved / Haftewar Manzoor: $weeklyApproved'),
//                   pw.Text('Monthly Approved / Mahana Manzoor: $monthlyApproved'),
//                 ],
//               ),
//             ),
//             pw.SizedBox(height: 18),
//             pw.Text(
//               '$selectedTitle (${selectedAppointments.length})  |  $rangeTitleUrduRoman',
//               style: pw.TextStyle(
//                 fontSize: 16,
//                 fontWeight: pw.FontWeight.bold,
//                 color: PdfColors.teal700,
//               ),
//             ),
//             pw.SizedBox(height: 8),
//             if (selectedAppointments.isEmpty)
//               pw.Text('No appointments found for selected range. / Is range mein appointments nahi milin.')
//             else
//               pw.TableHelper.fromTextArray(
//                 headers: [
//                   'Animal / Janwar',
//                   'Date / Tareekh',
//                   'Time / Waqt',
//                   'Status / Halat',
//                   'Problem / Masla'
//                 ],
//                 data: selectedAppointments
//                     .take(20)
//                     .map(
//                       (a) => [
//                         a.animalName,
//                         _formatShortDate(a.date),
//                         a.time,
//                         a.status,
//                         a.problem,
//                       ],
//                     )
//                     .toList(),
//                 headerStyle: pw.TextStyle(
//                   color: PdfColors.white,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//                 headerDecoration: const pw.BoxDecoration(color: PdfColors.teal600),
//                 cellHeight: 28,
//                 cellStyle: const pw.TextStyle(fontSize: 10),
//               ),
//           ],
//         ),
//       );

//       final bytes = await doc.save();
//       await Printing.sharePdf(
//         bytes: bytes,
//         filename:
//             'doctor_analytics_${generatedAt.year}${generatedAt.month.toString().padLeft(2, '0')}${generatedAt.day.toString().padLeft(2, '0')}.pdf',
//       );
//     } catch (_) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Unable to export PDF report right now.')),
//       );
//     }
//   }

//   bool _isSameDate(DateTime first, DateTime second) {
//     return first.year == second.year &&
//         first.month == second.month &&
//         first.day == second.day;
//   }

//   String _normalizedStatus(String status) {
//     return status.trim().toLowerCase();
//   }

//   Map<String, int> _statusCounts(List<AppointmentModel> appointments) {
//     final counts = <String, int>{
//       'approved': 0,
//       'pending': 0,
//       'declined': 0,
//       'completed': 0,
//     };

//     for (final appointment in appointments) {
//       final bucket = _statusBucket(appointment.status);
//       counts[bucket] = (counts[bucket] ?? 0) + 1;
//     }
//     return counts;
//   }

//   DateTime _analyticsDay(AppointmentModel appointment) {
//     final createdAt = appointment.createdAt;
//     if (createdAt != null) {
//       return _appointmentDay(createdAt);
//     }
//     return _appointmentDay(appointment.date);
//   }

//   DateTime _appointmentDay(Timestamp timestamp) {
//     final local = timestamp.toDate().toLocal();
//     return DateTime(local.year, local.month, local.day);
//   }

//   bool _matchesDay(Timestamp timestamp, DateTime day) {
//     final target = DateTime(day.year, day.month, day.day);
//     final localDay = _appointmentDay(timestamp);
//     if (_isSameDate(localDay, target)) return true;

//     // Fallback for records saved with UTC date-only semantics.
//     final utc = timestamp.toDate().toUtc();
//     return utc.year == target.year &&
//         utc.month == target.month &&
//         utc.day == target.day;
//   }

//   bool _isTodayAppointment(AppointmentModel appointment, DateTime today) {
//     if (_matchesDay(appointment.date, today)) return true;
//     final created = appointment.createdAt;
//     if (created != null && _matchesDay(created, today)) return true;
//     return false;
//   }

//   String _statusBucket(String status) {
//     final s = _normalizedStatus(status);
//     if (s == 'approved' || s == 'reapproved' || s == 'appointment_approved' || s == 'active') {
//       return 'approved';
//     }
//     if (s == 'declined' || s == 'rejected' || s == 'appointment_declined') {
//       return 'declined';
//     }
//     if (s == 'completed') {
//       return 'completed';
//     }
//     return 'pending';
//   }

//   Widget _buildAppointmentSection({
//     required String title,
//     required List<AppointmentModel> appointments,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [cardGrey, Colors.white],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(28),
//         border: Border.all(color: lightTeal.withOpacity(0.3)),
//         boxShadow: [
//           BoxShadow(
//             color: primaryTeal.withOpacity(0.1),
//             blurRadius: 15,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: primaryTeal,
//             ),
//           ),
//           const SizedBox(height: 20),
//           ...appointments
//               .map((appointment) => _buildAppointmentItem(appointment))
//               ,
//         ],
//       ),
//     );
//   }

//   Widget _buildAppointmentItem(AppointmentModel appointment) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [lightTeal, primaryTeal],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: primaryTeal.withOpacity(0.2),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Animal: ${appointment.animalName}',
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//               ),
//             ),
//             Text(
//               'Appointment On: ${_formatAppointmentSchedule(appointment)}',
//               style: const TextStyle(fontSize: 14, color: Colors.white),
//             ),
//             Text(
//               'Booked On: ${_formatBookedOn(appointment)}',
//               style: const TextStyle(fontSize: 14, color: Colors.white),
//             ),
//             Text(
//               'Problem: ${appointment.problem}',
//               style: const TextStyle(fontSize: 14, color: Colors.white),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () => _approveAppointment(appointment),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       padding: const EdgeInsets.symmetric(vertical: 10),
//                       elevation: 3,
//                     ),
//                     child: const Text(
//                       'Approve',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () => _declineAppointment(appointment),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       padding: const EdgeInsets.symmetric(vertical: 10),
//                       elevation: 3,
//                     ),
//                     child: const Text(
//                       'Decline',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _approveAppointment(AppointmentModel appointment) async {
//     final latestDoc = await FirebaseFirestore.instance
//         .collection('appointments')
//         .doc(appointment.id)
//         .get();
//     final latestData = latestDoc.data() ?? <String, dynamic>{};
//     final wasDeclined =
//         (latestData['status'] ?? appointment.status).toString().toLowerCase() ==
//             'declined';

//     await _appointmentService.updateStatus(appointment.id, 'approved');
//     await FirebaseFirestore.instance.collection('appointments').doc(appointment.id).set({
//       'reapprovedAt': FieldValue.serverTimestamp(),
//       'reapprovedFromDecline': wasDeclined,
//       'declineReason': FieldValue.delete(),
//       'declineReasonText': FieldValue.delete(),
//       'declinedAt': FieldValue.delete(),
//     }, SetOptions(merge: true));

//     await _notificationService.sendNotification(
//       receiverId: appointment.userId,
//       title: wasDeclined ? 'Appointment Re-Approved' : 'Appointment Approved',
//       message: wasDeclined
//           ? 'Your appointment with ${appointment.animalName} has been re-approved.\nAppointment On: ${_formatAppointmentSchedule(appointment)}\nBooked On: ${_formatBookedOn(appointment)}'
//           : 'Your appointment with ${appointment.animalName} has been approved.\nAppointment On: ${_formatAppointmentSchedule(appointment)}\nBooked On: ${_formatBookedOn(appointment)}',
//       appointmentId: appointment.id,
//       type: wasDeclined ? 'appointment_reapproved' : 'appointment_approved',
//     );
//     if (!mounted) return;
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('Appointment approved')));
//   }

//   Future<void> _declineAppointment(AppointmentModel appointment) async {
//     final reasonCode = await _showDeclineReasonPicker();
//     if (reasonCode == null) return;

//     final reasonText = _getDeclineReasonLabel(reasonCode);
//     final doctorMessage = await _showDoctorDeclineMessageDialog(reasonText);
//     if (doctorMessage == null) return;

//     final needsRefund = reasonCode != 'fake_screenshot';

//     await _appointmentService.updateStatus(appointment.id, 'declined');
//     await FirebaseFirestore.instance.collection('appointments').doc(appointment.id).set({
//       'declineReason': reasonCode,
//       'declineReasonText': '$reasonText. Doctor note: $doctorMessage',
//       'doctorDeclineMessage': doctorMessage,
//       'declineCategoryText': reasonText,
//       'refundRequired': needsRefund,
//       'declinedAt': Timestamp.now(),
//     }, SetOptions(merge: true));

//     await _notificationService.sendNotification(
//       receiverId: appointment.userId,
//       title: 'Appointment Declined',
//       message:
//           'Your appointment with ${appointment.animalName} has been declined.\nAppointment On: ${_formatAppointmentSchedule(appointment)}\nBooked On: ${_formatBookedOn(appointment)}\nReason: $reasonText\nDoctor note: $doctorMessage${needsRefund ? '\nRefund will be processed in 24-48 hours.' : '\nNo refund issued due to invalid payment proof.'}',
//       appointmentId: appointment.id,
//       type: 'appointment_declined',
//     );

//     await _notifyAdminsForDecline(
//       appointment: appointment,
//       reasonText: reasonText,
//       doctorMessage: doctorMessage,
//       needsRefund: needsRefund,
//     );

//     if (!mounted) return;

//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('Appointment declined with professional note')));
//   }

//   Future<String?> _showDeclineReasonPicker() async {
//     return showDialog<String>(
//       context: context,
//       builder: (context) => SimpleDialog(
//         title: const Text('Select Decline Reason'),
//         children: [
//           SimpleDialogOption(
//             onPressed: () => Navigator.pop(context, 'fake_screenshot'),
//             child: const Text('Fake/Invalid Payment Screenshot'),
//           ),
//           SimpleDialogOption(
//             onPressed: () => Navigator.pop(context, 'no_time'),
//             child: const Text('Schedule Conflict / No Time'),
//           ),
//           SimpleDialogOption(
//             onPressed: () => Navigator.pop(context, 'other'),
//             child: const Text('Other Reason'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<String?> _showDoctorDeclineMessageDialog(String reasonText) async {
//     final controller = TextEditingController();
//     String? validationError;
//     final result = await showDialog<String>(
//       context: context,
//       builder: (dialogContext) => StatefulBuilder(
//         builder: (dialogContext, setDialogState) {
//           return AlertDialog(
//             title: const Text('Professional Explanation'),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Reason: $reasonText', style: const TextStyle(fontWeight: FontWeight.w700)),
//                 const SizedBox(height: 10),
//                 const Text(
//                   'Write a clear message for user and admin (minimum 10 characters).',
//                   style: TextStyle(fontSize: 13, color: Colors.black54),
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: controller,
//                   maxLines: 4,
//                   maxLength: 280,
//                   onChanged: (_) {
//                     if (validationError != null) {
//                       setDialogState(() => validationError = null);
//                     }
//                   },
//                   decoration: InputDecoration(
//                     hintText: 'Explain the issue briefly and professionally',
//                     border: const OutlineInputBorder(),
//                     errorText: validationError,
//                   ),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(dialogContext),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   final note = controller.text.trim();
//                   if (note.length < 10) {
//                     setDialogState(() {
//                       validationError = 'Please enter at least 10 characters.';
//                     });
//                     return;
//                   }
//                   Navigator.pop(dialogContext, note);
//                 },
//                 child: const Text('Continue'),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//     controller.dispose();
//     return result;
//   }

//   String _getDeclineReasonLabel(String reasonCode) {
//     switch (reasonCode) {
//       case 'fake_screenshot':
//         return 'Invalid/fake payment screenshot';
//       case 'no_time':
//         return 'Schedule conflict';
//       case 'other':
//         return 'Other reason';
//       default:
//         return 'Declined by doctor';
//     }
//   }

//   Future<void> _notifyAdminsForDecline({
//     required AppointmentModel appointment,
//     required String reasonText,
//     required String doctorMessage,
//     required bool needsRefund,
//   }) async {
//     try {
//       final adminSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .where('role', isEqualTo: 'Admin')
//           .get();

//       for (final admin in adminSnapshot.docs) {
//         await _notificationService.sendNotification(
//           receiverId: admin.id,
//           title: needsRefund ? 'Manual Refund Required' : 'Declined Without Refund',
//           message: needsRefund
//               ? 'Appointment ${appointment.id} declined. Process refund of Rs. ${appointment.paymentAmount.toStringAsFixed(0)}.\nAppointment On: ${_formatAppointmentSchedule(appointment)}\nBooked On: ${_formatBookedOn(appointment)}\nReason: $reasonText\nDoctor note: $doctorMessage'
//               : 'Appointment ${appointment.id} declined without refund.\nAppointment On: ${_formatAppointmentSchedule(appointment)}\nBooked On: ${_formatBookedOn(appointment)}\nReason: $reasonText\nDoctor note: $doctorMessage',
//           appointmentId: appointment.id,
//           type: needsRefund ? 'admin_refund_request' : 'admin_decline_notice',
//         );
//       }
//     } catch (e) {
//       debugPrint('Error notifying admins about decline: $e');
//     }
//   }

//   Widget _buildAppointmentSectionWithDetails() {
//     return const SizedBox.shrink();
//   }

//   Widget _buildPlaceholderCard(String message) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: lightTeal.withOpacity(0.3)),
//       ),
//       child: Text(
//         message,
//         style: TextStyle(
//           color: Colors.grey[700],
//           fontSize: 14,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
// }

// // Doctor Welcome Splash Screen (3 seconds)
// class DoctorWelcomeSplashScreen extends StatefulWidget {
//   const DoctorWelcomeSplashScreen({super.key});

//   @override
//   State<DoctorWelcomeSplashScreen> createState() =>
//       _DoctorWelcomeSplashScreenState();
// }

// class _DoctorWelcomeSplashScreenState extends State<DoctorWelcomeSplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       duration: const Duration(seconds: 3),
//       vsync: this,
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8)),
//     );

//     _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.7)),
//     );

//     _controller.forward();

//     // After 3 seconds → Doctor Dashboard
//     Future.delayed(const Duration(seconds: 3), () {
//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           PageRouteBuilder(
//             transitionDuration: const Duration(milliseconds: 800),
//             pageBuilder: (_, __, ___) => const DoctorDashboardPage(),
//             transitionsBuilder: (_, animation, __, child) {
//               return FadeTransition(opacity: animation, child: child);
//             },
//           ),
//         );
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFB2DFDB),
//       body: Center(
//         child: FadeTransition(
//           opacity: _fadeAnimation,
//           child: ScaleTransition(
//             scale: _scaleAnimation,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Image.asset('assets/login/cow.png', scale: 4),
//                 const SizedBox(height: 50),
//                 const Text(
//                   'Welcome Back',
//                   style: TextStyle(
//                     fontSize: 36,
//                     color: Colors.indigo,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const Text(
//                   'Dr. Emelle',
//                   style: TextStyle(
//                     fontSize: 52,
//                     color: Colors.teal,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'Ready to care for more pets today?',
//                   style: TextStyle(fontSize: 20, color: Colors.black87),
//                   textAlign: TextAlign.center,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // import 'dart:developer';
// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
// // import 'package:flutter_application_1/view/Doctor/doctor_chat_screen.dart';
// // import 'package:flutter_application_1/view/auth/login/login.dart';
// // import 'package:flutter_application_1/view/Doctor/DoctorAppointmentRequests.dart';
// // import 'package:flutter_application_1/view/Doctor/DoctorNotifications.dart';

// // class DoctorDashboardPage extends StatelessWidget {
// //   const DoctorDashboardPage({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     final doctor = AuthService.currentUser;

// //     if (doctor == null) {
// //       return const Scaffold(
// //         body: Center(child: Text('Doctor not logged in')),
// //       );
// //     }

// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: _buildAppBar(context),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(20),
// //         child: Column(
// //           children: [
// //             _buildWelcomeCard(doctor.displayName ?? 'Doctor'),
// //             const SizedBox(height: 30),
// //             _buildStatsRow(doctor.uid),
// //             const SizedBox(height: 30),
// //             _buildQuickActions(context),
// //             const SizedBox(height: 30),
// //             _buildChatCard(context),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   // ---------------- APP BAR ----------------
// //   AppBar _buildAppBar(BuildContext context) {
// //     return AppBar(
// //       backgroundColor: Colors.white,
// //       elevation: 0,
// //       title: const Text(
// //         'DignoVet',
// //         style: TextStyle(
// //           color: Colors.teal,
// //           fontWeight: FontWeight.bold,
// //           fontSize: 24,
// //         ),
// //       ),
// //       actions: [
// //         IconButton(
// //           icon: const Icon(Icons.notifications_outlined),
// //           onPressed: () {
// //             Navigator.push(
// //               context,
// //               MaterialPageRoute(builder: (_) => const DoctorNotificationsPage()),
// //             );
// //           },
// //         ),
// //         IconButton(
// //           icon: const Icon(Icons.logout),
// //           onPressed: () async {
// //             log('Doctor Logged Out');
// //             await AuthService().signOut();

// //             if (context.mounted) {
// //               Navigator.pushAndRemoveUntil(
// //                 context,
// //                 MaterialPageRoute(builder: (_) => const LoginPage()),
// //                 (_) => false,
// //               );
// //             }
// //           },
// //         ),
// //       ],
// //     );
// //   }

// //   // ---------------- WELCOME CARD ----------------
// //   Widget _buildWelcomeCard(String name) {
// //     return Container(
// //       padding: const EdgeInsets.all(24),
// //       decoration: BoxDecoration(
// //         color: const Color(0xFF80CBC4),
// //         borderRadius: BorderRadius.circular(28),
// //       ),
// //       child: Row(
// //         children: [
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 const Text(
// //                   'Welcome Back',
// //                   style: TextStyle(color: Colors.white70, fontSize: 20),
// //                 ),
// //                 Text(
// //                   'Dr. $name',
// //                   style: const TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 32,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 6),
// //                 const Text(
// //                   'You are doing great today!',
// //                   style: TextStyle(color: Colors.white70),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           const CircleAvatar(
// //             radius: 36,
// //             backgroundColor: Colors.white,
// //             child: Icon(Icons.person, size: 40, color: Colors.teal),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // ---------------- STATS ----------------
// //   Widget _buildStatsRow(String doctorId) {
// //     return StreamBuilder<QuerySnapshot>(
// //       stream: FirebaseFirestore.instance
// //           .collection('appointments')
// //           .where('doctorId', isEqualTo: doctorId)
// //           .snapshots(),
// //       builder: (context, snapshot) {
// //         int total = 0;
// //         int pending = 0;
// //         int approved = 0;

// //         if (snapshot.hasData) {
// //           total = snapshot.data!.docs.length;
// //           pending = snapshot.data!.docs
// //               .where((e) => e['status'] == 'pending')
// //               .length;
// //           approved = snapshot.data!.docs
// //               .where((e) => e['status'] == 'approved')
// //               .length;
// //         }

// //         return Row(
// //           children: [
// //             _statCard('Total', total.toString(), Icons.assignment),
// //             const SizedBox(width: 12),
// //             _statCard('Pending', pending.toString(), Icons.schedule),
// //             const SizedBox(width: 12),
// //             _statCard('Approved', approved.toString(), Icons.check_circle),
// //           ],
// //         );
// //       },
// //     );
// //   }

// //   Widget _statCard(String label, String value, IconData icon) {
// //     return Expanded(
// //       child: Container(
// //         padding: const EdgeInsets.all(18),
// //         decoration: BoxDecoration(
// //           color: const Color(0xFFF1F5F4),
// //           borderRadius: BorderRadius.circular(22),
// //         ),
// //         child: Column(
// //           children: [
// //             Icon(icon, size: 30, color: Colors.teal),
// //             const SizedBox(height: 8),
// //             Text(
// //               value,
// //               style: const TextStyle(
// //                 fontSize: 26,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             Text(label, style: const TextStyle(color: Colors.grey)),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   // ---------------- QUICK ACTIONS ----------------
// //   Widget _buildQuickActions(BuildContext context) {
// //     return ElevatedButton(
// //       style: ElevatedButton.styleFrom(
// //         backgroundColor: const Color(0xFF80CBC4),
// //         padding: const EdgeInsets.symmetric(vertical: 18),
// //         shape: RoundedRectangleBorder(
// //           borderRadius: BorderRadius.circular(30),
// //         ),
// //       ),
// //       onPressed: () {
// //         Navigator.push(
// //           context,
// //           MaterialPageRoute(
// //             builder: (_) => const DoctorAppointmentRequestsPage(),
// //           ),
// //         );
// //       },
// //       child: const Text(
// //         'View Pending Appointments',
// //         style: TextStyle(fontSize: 18, color: Colors.black87),
// //       ),
// //     );
// //   }

// //   // ---------------- CHAT CARD ----------------
// //   Widget _buildChatCard(BuildContext context) {
// //     return GestureDetector(
// //       onTap: () {
// //         Navigator.push(
// //           context,
// //           MaterialPageRoute(builder: (_) => const DoctorChatListScreen()),
// //         );
// //       },
// //       child: Container(
// //         padding: const EdgeInsets.all(24),
// //         decoration: BoxDecoration(
// //           color: const Color(0xFF80CBC4),
// //           borderRadius: BorderRadius.circular(28),
// //         ),
// //         child: Row(
// //           children: const [
// //             Icon(Icons.chat_bubble_outline, size: 40, color: Colors.white),
// //             SizedBox(width: 16),
// //             Text(
// //               'Chats',
// //               style: TextStyle(
// //                 fontSize: 26,
// //                 color: Colors.white,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }



import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/services/file_download_service.dart';
import 'package:flutter_application_1/view/Doctor/DoctorNotificationsPage.dart';
import 'package:flutter_application_1/view/Doctor/doctor_chat_screen.dart';
import 'package:flutter_application_1/view/Doctor/doctor_profile_page.dart';
import 'package:flutter_application_1/services/Appointment Service/appointment_services.dart';
import 'package:flutter_application_1/services/notification service/notification_service.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/model/app_user.dart';
import 'package:flutter_application_1/view/Doctor/DoctorAppointmentRequests.dart';
import 'package:flutter_application_1/view/Doctor/Apponitment_approval_page_new.dart';
import 'package:flutter_application_1/view/User/customer_support_chat.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final NotificationService _notificationService = NotificationService();

  AppUser? doctorProfile;
  bool isLoadingProfile = true;

  final Color primaryTeal = const Color(0xFF00796B);
  final Color lightTeal = const Color(0xFF4DB6AC);
  final Color cardGrey = const Color(0xFFF8F9FA);
  final Color darkGrey = const Color(0xFF2C3E50);

  String _selectedAnalyticsView = 'daily';
  String _selectedDashboardTab = 'overview';
  String _prescriptionOwnerSearch = '';
  String _prescriptionAppointmentSearch = '';
  String _prescriptionDateRange = 'all';
  String _prescriptionStatusFilter = 'all';
  String _prescriptionSortBy = 'latest';
  int? _prescriptionMonthFilter;
  int? _prescriptionYearFilter;

  static const String _analyticsViewPrefKey = 'doctor_dashboard_analytics_view';

  @override
  void initState() {
    super.initState();
    _loadSavedAnalyticsView();
    _loadDoctorProfile();
  }

  Future<void> _loadSavedAnalyticsView() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_analyticsViewPrefKey);
      if (!mounted) return;
      if (saved == 'daily' || saved == 'weekly' || saved == 'monthly') {
        setState(() => _selectedAnalyticsView = saved!);
      }
    } catch (_) {}
  }

  Future<void> _setAnalyticsView(String value) async {
    if (_selectedAnalyticsView == value) return;
    setState(() => _selectedAnalyticsView = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_analyticsViewPrefKey, value);
    } catch (_) {}
  }

  Future<void> _loadDoctorProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!mounted) return;
      if (docSnapshot.exists) {
        setState(() {
          doctorProfile = AppUser.fromMap(docSnapshot.data()!, docSnapshot.id);
          isLoadingProfile = false;
        });
      } else {
        setState(() => isLoadingProfile = false);
      }
    } catch (e) {
      log('Error loading doctor profile: $e');
      if (!mounted) return;
      setState(() => isLoadingProfile = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS HELPERS  (single source of truth for the whole file)
  // ─────────────────────────────────────────────────────────────────────────

  /// Normalises a raw Firestore status string to lowercase-trimmed form.
  String _normalizedStatus(String status) => status.trim().toLowerCase();

  /// Maps any raw status string → one of:  approved | pending | declined | completed
  String _statusBucket(String status) {
    final s = _normalizedStatus(status);
    if (s == 'approved' ||
        s == 'reapproved' ||
        s == 'appointment_approved' ||
        s == 'active') {
      return 'approved';
    }
    if (s == 'declined' ||
        s == 'rejected' ||
        s == 'appointment_declined') {
      return 'declined';
    }
    if (s == 'completed') return 'completed';
    return 'pending';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

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
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_active_rounded,
                    color: primaryTeal, size: 26),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DoctorNotificationsPage()),
                  );
                },
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
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
              _buildDashboardTabSwitcher(),
              const SizedBox(height: 20),
              if (_selectedDashboardTab == 'overview') ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Chats
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DoctorChatListScreen()),
                        ),
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient:
                                LinearGradient(colors: [primaryTeal, lightTeal]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: primaryTeal.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6)),
                            ],
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 40, color: Colors.white),
                              SizedBox(height: 10),
                              Text('Chats',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Requests
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const DoctorAppointmentRequestsPage()),
                        ),
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.orange.shade600,
                              Colors.orange.shade400
                            ]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.orange.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6)),
                            ],
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 40, color: Colors.white),
                              SizedBox(height: 10),
                              Text('Requests',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Support
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CustomerSupportChatPage()),
                        ),
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: primaryTeal.withOpacity(0.3), width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: primaryTeal.withOpacity(0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.support_agent_rounded,
                                  color: primaryTeal, size: 40),
                              const SizedBox(height: 10),
                              Text('Support',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: darkGrey)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _buildDoctorProfileCard(),
                const SizedBox(height: 32),
                _buildProfessionalAppointmentsAnalytics(),
                const SizedBox(height: 32),
              ] else ...[
                _buildPrescriptionHistorySection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DOCTOR PROFILE CARD
  // ─────────────────────────────────────────────────────────────────────────

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
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5)),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome Back,',
                        style:
                            TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      doctorProfile?.name ?? 'Doctor',
                      style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (doctorProfile?.specialization != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Text(
                          doctorProfile!.specialization!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(Icons.work_outline, 'Experience',
                          '${doctorProfile?.experience ?? 0} Years'),
                    ),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(Icons.local_hospital_outlined,
                          'Clinic', doctorProfile?.clinicName ?? 'N/A'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: _buildInfoItem(
                        Icons.email_outlined, 'Email', doctorProfile?.email ?? 'N/A'),
                  ),
                ]),
                if (doctorProfile?.phone.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: _buildInfoItem(
                          Icons.phone_outlined, 'Phone', doctorProfile!.phone),
                    ),
                  ]),
                ],
                if (doctorProfile?.clinicAddress != null &&
                    doctorProfile!.clinicAddress!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoItem(Icons.location_on_outlined, 'Clinic Address',
                      doctorProfile!.clinicAddress!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You are doing great today! 🌟',
            style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB SWITCHER
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDashboardTabSwitcher() {
    Widget buildTab(
        {required String label,
        required String value,
        required IconData icon}) {
      final isSelected = _selectedDashboardTab == value;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _selectedDashboardTab = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: isSelected
                  ? LinearGradient(colors: [primaryTeal, lightTeal])
                  : null,
              color: isSelected ? null : Colors.white,
              border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : primaryTeal.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18,
                    color: isSelected ? Colors.white : primaryTeal),
                const SizedBox(width: 7),
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isSelected ? Colors.white : darkGrey)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryTeal.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          buildTab(
              label: 'Overview',
              value: 'overview',
              icon: Icons.space_dashboard_rounded),
          const SizedBox(width: 8),
          buildTab(
              label: 'Prescriptions',
              value: 'prescriptions',
              icon: Icons.receipt_long_rounded),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRESCRIPTION HISTORY
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPrescriptionHistorySection() {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) return _buildPlaceholderCard('Doctor session not found');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lightTeal.withOpacity(0.28)),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('prescriptions')
            .where('doctorId', isEqualTo: doctorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(color: primaryTeal),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prescription History',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryTeal)),
                const SizedBox(height: 10),
                Text('No prescription has been sent yet.',
                    style: TextStyle(
                        color: Colors.grey[700], fontWeight: FontWeight.w500)),
              ],
            );
          }

          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final at = (a.data() as Map<String, dynamic>)['createdAt'];
              final bt = (b.data() as Map<String, dynamic>)['createdAt'];
              final ad = at is Timestamp
                  ? at.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              final bd = bt is Timestamp
                  ? bt.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              return bd.compareTo(ad);
            });

          final filteredDocs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final owner = (data['patientName'] ?? '').toString().toLowerCase();
            final appointmentId =
                (data['appointmentId'] ?? '').toString().toLowerCase();
            final animal = (data['animalName'] ?? '').toString().toLowerCase();
            final status = (data['status'] ?? 'sent').toString().toLowerCase();
            final rawDownloads = (data['downloadCount'] ?? 0);
            final downloadCount = rawDownloads is int
                ? rawDownloads
                : int.tryParse(rawDownloads.toString()) ?? 0;
            final normalizedStatus =
                downloadCount > 0 ? 'downloaded' : status;
            final createdAt = data['createdAt'];
            final createdDate =
                createdAt is Timestamp ? createdAt.toDate() : null;

            final ownerQuery = _prescriptionOwnerSearch.trim().toLowerCase();
            final appointmentQuery =
                _prescriptionAppointmentSearch.trim().toLowerCase();

            final ownerMatch = ownerQuery.isEmpty ||
                owner.contains(ownerQuery) ||
                animal.contains(ownerQuery);
            final appointmentMatch = appointmentQuery.isEmpty ||
                appointmentId.contains(appointmentQuery);
            final rangeMatch = _isInSelectedPrescriptionRange(createdDate);
            final statusMatch = _prescriptionStatusFilter == 'all' ||
                normalizedStatus == _prescriptionStatusFilter;
            final monthYearMatch = _isInSelectedMonthYear(createdDate);

            return ownerMatch &&
                appointmentMatch &&
                rangeMatch &&
                statusMatch &&
                monthYearMatch;
          }).toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;

              if (_prescriptionSortBy == 'most_downloaded') {
                final aDownloads = (aData['downloadCount'] ?? 0);
                final bDownloads = (bData['downloadCount'] ?? 0);
                final aCount = aDownloads is int
                    ? aDownloads
                    : int.tryParse(aDownloads.toString()) ?? 0;
                final bCount = bDownloads is int
                    ? bDownloads
                    : int.tryParse(bDownloads.toString()) ?? 0;
                if (aCount != bCount) return bCount.compareTo(aCount);
              }

              final aTs = aData['createdAt'];
              final bTs = bData['createdAt'];
              final aDate = aTs is Timestamp
                  ? aTs.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = bTs is Timestamp
                  ? bTs.toDate()
                  : DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });

          final thisMonthCount = docs.where((d) {
            final map = d.data() as Map<String, dynamic>;
            final ts = map['createdAt'];
            if (ts is! Timestamp) return false;
            final dt = ts.toDate();
            final now = DateTime.now();
            return dt.year == now.year && dt.month == now.month;
          }).length;

          final filteredDownloads = filteredDocs.fold<int>(0, (sum, d) {
            final map = d.data() as Map<String, dynamic>;
            final count = (map['downloadCount'] ?? 0);
            return sum +
                (count is int
                    ? count
                    : int.tryParse(count.toString()) ?? 0);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.receipt_long_rounded, color: primaryTeal, size: 24),
                const SizedBox(width: 8),
                Text('Prescription History',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryTeal)),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _buildMiniBadge('Total', docs.length.toString()),
                _buildMiniBadge('This Month', thisMonthCount.toString()),
                _buildMiniBadge('Filtered', filteredDocs.length.toString()),
                _buildMiniBadge('Downloads', filteredDownloads.toString()),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) =>
                        setState(() => _prescriptionOwnerSearch = v),
                    decoration: InputDecoration(
                      hintText: 'Search pet owner/pet',
                      prefixIcon:
                          const Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: primaryTeal.withOpacity(0.2))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) =>
                        setState(() => _prescriptionAppointmentSearch = v),
                    decoration: InputDecoration(
                      hintText: 'Appointment ID',
                      prefixIcon: const Icon(
                          Icons.confirmation_number_rounded,
                          size: 18),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: primaryTeal.withOpacity(0.2))),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _buildPrescriptionRangeChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildPrescriptionRangeChip('Last 7 days', '7d'),
                  const SizedBox(width: 8),
                  _buildPrescriptionRangeChip('Last 30 days', '30d'),
                  const SizedBox(width: 8),
                  _buildPrescriptionRangeChip('Last 90 days', '90d'),
                ]),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _prescriptionStatusFilter,
                    isExpanded: true,
                    decoration: InputDecoration(
                        labelText: 'Status',
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'sent', child: Text('Sent')),
                      DropdownMenuItem(
                          value: 'downloaded', child: Text('Downloaded')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _prescriptionStatusFilter = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _prescriptionSortBy,
                    isExpanded: true,
                    decoration: InputDecoration(
                        labelText: 'Sort By',
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    items: const [
                      DropdownMenuItem(
                          value: 'latest', child: Text('Latest')),
                      DropdownMenuItem(
                          value: 'most_downloaded',
                          child: Text('Most Downloads')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _prescriptionSortBy = value);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _prescriptionMonthFilter,
                    isExpanded: true,
                    decoration: InputDecoration(
                        labelText: 'Month',
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('All Months')),
                      ...List.generate(
                          12,
                          (i) => DropdownMenuItem<int?>(
                              value: i + 1, child: Text('${i + 1}'))),
                    ],
                    onChanged: (value) =>
                        setState(() => _prescriptionMonthFilter = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _prescriptionYearFilter,
                    isExpanded: true,
                    decoration: InputDecoration(
                        labelText: 'Year',
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('All Years')),
                      ...List.generate(6, (i) {
                        final year = DateTime.now().year - i;
                        return DropdownMenuItem<int?>(
                            value: year, child: Text('$year'));
                      }),
                    ],
                    onChanged: (value) =>
                        setState(() => _prescriptionYearFilter = value),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              if (filteredDocs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text('No prescriptions matched current filters.',
                      style: TextStyle(color: Colors.grey[700])),
                ),
              ...filteredDocs.take(60).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final ts = data['createdAt'];
                final dateText = _formatPrescriptionHistoryDate(ts);
                final pdfUrl = (data['pdfUrl'] ?? '').toString();
                final pdfFileName =
                    (data['pdfFileName'] ?? 'prescription.pdf').toString();
                final patientName =
                    (data['patientName'] ?? 'Pet Owner').toString();
                final animalName = (data['animalName'] ?? '').toString();
                final appointmentId =
                    (data['appointmentId'] ?? '').toString();
                final downloadCount =
                    (data['downloadCount'] ?? 0).toString();
                final followUpText = _normalizeFollowUpText(
                    (data['followUp'] ?? '').toString());

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardGrey,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: primaryTeal.withOpacity(0.12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.picture_as_pdf_rounded,
                            color: primaryTeal, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            animalName.isEmpty
                                ? patientName
                                : '$patientName • $animalName',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: darkGrey),
                          ),
                        ),
                        Text(dateText,
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 12)),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        appointmentId.isEmpty
                            ? 'Appointment: Not linked'
                            : 'Appointment ID: $appointmentId',
                        style: TextStyle(
                            color: Colors.grey[700], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text('Downloads: $downloadCount',
                          style: TextStyle(
                              color: Colors.grey[700], fontSize: 12)),
                      if (followUpText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Follow-up: $followUpText',
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 12)),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(spacing: 8, children: [
                          TextButton.icon(
                            onPressed: pdfUrl.isEmpty
                                ? null
                                : () => _openPrescriptionPdf(pdfUrl),
                            icon: const Icon(Icons.open_in_new_rounded,
                                size: 18),
                            label: const Text('Open'),
                          ),
                          TextButton.icon(
                            onPressed: pdfUrl.isEmpty
                                ? null
                                : () => _downloadPrescriptionPdf(
                                    pdfUrl: pdfUrl,
                                    fileName: pdfFileName),
                            icon: const Icon(Icons.download_rounded,
                                size: 18),
                            label: const Text('Download'),
                          ),
                        ]),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text('$label: $value',
          style: TextStyle(
              color: primaryTeal,
              fontWeight: FontWeight.w700,
              fontSize: 12)),
    );
  }

  String _formatPrescriptionHistoryDate(dynamic ts) {
    if (ts is! Timestamp) return 'N/A';
    return DateFormat('dd MMM yyyy').format(ts.toDate());
  }

  String _normalizeFollowUpText(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.toLowerCase() == 'n/a') return '';
    if (RegExp(r'^\d+$').hasMatch(value)) return '$value days';
    return value;
  }

  Widget _buildPrescriptionRangeChip(String label, String value) {
    final isSelected = _prescriptionDateRange == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) =>
          setState(() => _prescriptionDateRange = value),
      selectedColor: primaryTeal.withOpacity(0.18),
      labelStyle: TextStyle(
          color: isSelected ? primaryTeal : darkGrey,
          fontWeight: FontWeight.w700),
      side: BorderSide(color: primaryTeal.withOpacity(0.22)),
      backgroundColor: Colors.white,
    );
  }

  bool _isInSelectedPrescriptionRange(DateTime? createdAt) {
    if (createdAt == null) return _prescriptionDateRange == 'all';
    if (_prescriptionDateRange == 'all') return true;
    final now = DateTime.now();
    if (_prescriptionDateRange == '7d')
      return createdAt.isAfter(now.subtract(const Duration(days: 7)));
    if (_prescriptionDateRange == '30d')
      return createdAt.isAfter(now.subtract(const Duration(days: 30)));
    if (_prescriptionDateRange == '90d')
      return createdAt.isAfter(now.subtract(const Duration(days: 90)));
    return true;
  }

  bool _isInSelectedMonthYear(DateTime? createdAt) {
    if (createdAt == null) {
      return _prescriptionMonthFilter == null &&
          _prescriptionYearFilter == null;
    }
    if (_prescriptionMonthFilter != null &&
        createdAt.month != _prescriptionMonthFilter) return false;
    if (_prescriptionYearFilter != null &&
        createdAt.year != _prescriptionYearFilter) return false;
    return true;
  }

  Future<void> _openPrescriptionPdf(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid prescription URL.')));
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open PDF.')));
    }
  }

  Future<void> _downloadPrescriptionPdf(
      {required String pdfUrl, required String fileName}) async {
    try {
      final savedPath =
          await FileDownloadService.downloadPdf(url: pdfUrl, fileName: fileName);
      if (!mounted) return;
      if (savedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to download PDF.')));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prescription saved: $savedPath')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to download PDF.')));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ANALYTICS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildProfessionalAppointmentsAnalytics() {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    if (doctorId == null) return _buildPlaceholderCard('Doctor session not found');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: lightTeal.withOpacity(0.35))),
            child: Center(child: CircularProgressIndicator(color: primaryTeal)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: lightTeal.withOpacity(0.35))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Appointments Analytics',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryTeal)),
              const SizedBox(height: 16),
              Text(
                  'No appointment data yet. New requests and approvals will appear here.',
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ]),
          );
        }

        final appointments = snapshot.data!.docs
            .map((doc) => AppointmentModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        final now = DateTime.now().toLocal();
        final todayStart = DateTime(now.year, now.month, now.day);
        final weekStart =
            todayStart.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = now.month == 12
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, now.month + 1, 1);

        // ✅ FIX: All filtering uses _statusBucket — never raw .status
        final approvedAppointments = appointments
            .where((a) => _statusBucket(a.status) == 'approved')
            .toList();
        final pendingAppointments = appointments
            .where((a) => _statusBucket(a.status) == 'pending')
            .toList();
        final declinedAppointments = appointments
            .where((a) => _statusBucket(a.status) == 'declined')
            .toList();

        final dailyAppointments = appointments
            .where((a) => _isTodayAppointment(a, todayStart))
            .toList();

        final weeklyAppointments = appointments.where((a) {
          final d = _appointmentDay(a.date);
          return !d.isBefore(weekStart) && d.isBefore(weekEnd);
        }).toList();

        final monthlyAppointments = appointments.where((a) {
          final d = _appointmentDay(a.date);
          return !d.isBefore(monthStart) && d.isBefore(monthEnd);
        }).toList();

        final weeklyApproved = approvedAppointments.where((a) {
          final d = _appointmentDay(a.date);
          return !d.isBefore(weekStart) && d.isBefore(weekEnd);
        }).toList();

        final monthlyApproved = approvedAppointments.where((a) {
          final d = _appointmentDay(a.date);
          return !d.isBefore(monthStart) && d.isBefore(monthEnd);
        }).toList();

        final totalStats = _statusCounts(appointments);
        final dailyStats = _statusCounts(dailyAppointments);
        final weeklyStats = _statusCounts(weeklyAppointments);
        final monthlyStats = _statusCounts(monthlyAppointments);

        final selectedPeriodAppointments = _selectedAnalyticsView == 'daily'
            ? dailyAppointments
            : _selectedAnalyticsView == 'weekly'
                ? weeklyAppointments
                : monthlyAppointments;
        final selectedPeriodTitle = _selectedAnalyticsView == 'daily'
            ? 'Daily Appointments'
            : _selectedAnalyticsView == 'weekly'
                ? 'Weekly Appointments'
                : 'Monthly Appointments';

        final dynamicGraph = _buildDynamicGraphData(
          selectedView: _selectedAnalyticsView,
          now: now,
          dailyAppointments: dailyAppointments,
          weeklyAppointments: weeklyAppointments,
          monthlyAppointments: monthlyAppointments,
          weekStart: weekStart,
          monthStart: monthStart,
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [cardGrey, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: lightTeal.withOpacity(0.28)),
            boxShadow: [
              BoxShadow(
                  color: primaryTeal.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.analytics_rounded, color: primaryTeal, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Appointments Analytics',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryTeal)),
                ),
                IconButton(
                  onPressed: () => _exportAnalyticsPdf(
                    total: appointments.length,
                    approved: approvedAppointments.length,
                    pending: pendingAppointments.length,
                    weeklyApproved: weeklyApproved.length,
                    monthlyApproved: monthlyApproved.length,
                    selectedTitle: selectedPeriodTitle,
                    selectedAppointments: selectedPeriodAppointments,
                  ),
                  tooltip: 'Export PDF Report',
                  icon: Icon(Icons.picture_as_pdf_rounded, color: primaryTeal),
                ),
              ]),
              const SizedBox(height: 18),
              Wrap(spacing: 10, runSpacing: 10, children: [
                _buildAnalyticsTile(
                    title: 'Total',
                    value: appointments.length.toString(),
                    icon: Icons.list_alt_rounded,
                    color: primaryTeal),
                _buildAnalyticsTile(
                    title: 'Approved',
                    value: totalStats['approved']!.toString(),
                    icon: Icons.check_circle_rounded,
                    color: Colors.green),
                _buildAnalyticsTile(
                    title: 'Pending',
                    value: totalStats['pending']!.toString(),
                    icon: Icons.schedule_rounded,
                    color: Colors.orange),
                _buildAnalyticsTile(
                    title: 'Completed',
                    value: totalStats['completed']!.toString(),
                    icon: Icons.task_alt_rounded,
                    color: Colors.blue),
                _buildAnalyticsTile(
                    title: 'Declined',
                    value: totalStats['declined']!.toString(),
                    icon: Icons.cancel_rounded,
                    color: Colors.red),
                _buildAnalyticsTile(
                    title: 'Weekly Total',
                    value: weeklyAppointments.length.toString(),
                    icon: Icons.calendar_view_week_rounded,
                    color: Colors.indigo),
                _buildAnalyticsTile(
                    title: 'Monthly Total',
                    value: monthlyAppointments.length.toString(),
                    icon: Icons.calendar_month_rounded,
                    color: Colors.deepPurple),
              ]),
              const SizedBox(height: 22),
              _buildTodaySummaryStrip(
                total: dailyAppointments.length,
                approved: dailyStats['approved']!,
                pending: dailyStats['pending']!,
                declined: dailyStats['declined']!,
              ),
              const SizedBox(height: 12),
              _buildPeriodStatsCards(
                weeklyStats: weeklyStats,
                monthlyStats: monthlyStats,
                weeklyTotal: weeklyAppointments.length,
                monthlyTotal: monthlyAppointments.length,
              ),
              const SizedBox(height: 14),
              _buildGraphCard(
                title: dynamicGraph['title'] as String,
                values: dynamicGraph['values'] as List<int>,
                labels: dynamicGraph['labels'] as List<String>,
                barColors: dynamicGraph['barColors'] as List<Color>,
                legendLabels: dynamicGraph['legendLabels'] as List<String>?,
                legendColors: dynamicGraph['legendColors'] as List<Color>?,
              ),
              const SizedBox(height: 16),
              _buildTodayAppointmentsSection(
                dailyAppointments: dailyAppointments,
                approved: dailyStats['approved']!,
                pending: dailyStats['pending']!,
                declined: dailyStats['declined']!,
              ),
              const SizedBox(height: 20),
              Text('Appointments Explorer',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkGrey)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _buildRangeButton(
                        label: 'Daily',
                        count: dailyAppointments.length,
                        value: 'daily')),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildRangeButton(
                        label: 'Weekly',
                        count: weeklyAppointments.length,
                        value: 'weekly')),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildRangeButton(
                        label: 'Monthly',
                        count: monthlyAppointments.length,
                        value: 'monthly')),
              ]),
              const SizedBox(height: 14),
              if (_selectedAnalyticsView == 'daily')
                _buildPeriodAppointmentsSection(
                  title: 'Daily Appointments',
                  subtitle:
                      'Today: ${dailyAppointments.length} appointments (Approved: ${dailyStats['approved']}, Pending: ${dailyStats['pending']}, Declined: ${dailyStats['declined']})',
                  appointments: dailyAppointments,
                  emptyText: 'No appointments scheduled for today.',
                ),
              if (_selectedAnalyticsView == 'weekly')
                _buildPeriodAppointmentsSection(
                  title: 'Weekly Appointments',
                  subtitle: 'All appointments in current week',
                  appointments: weeklyAppointments,
                  emptyText: 'No appointments found in this week.',
                ),
              if (_selectedAnalyticsView == 'monthly')
                _buildPeriodAppointmentsSection(
                  title: 'Monthly Appointments',
                  subtitle: 'All appointments in current month',
                  appointments: monthlyAppointments,
                  emptyText: 'No appointments found in this month.',
                ),
              const SizedBox(height: 16),
              _buildApprovedDetailsSection(
                title: 'Weekly Approved Summary',
                subtitle: 'Approved appointments in this week',
                appointments: weeklyApproved,
                emptyText: 'No approved appointments for this week yet.',
              ),
              const SizedBox(height: 16),
              _buildApprovedDetailsSection(
                title: 'Monthly Approved Summary',
                subtitle: 'Approved appointments in this month',
                appointments: monthlyApproved,
                emptyText: 'No approved appointments for this month yet.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const DoctorAppointmentRequestsPage()),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Open Full Appointment Manager',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TILE — ✅ FIXED: uses _statusBucket() throughout, shows 'Completed' label
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPeriodAppointmentTile(AppointmentModel appointment) {
    // ✅ FIX: Always derive display state from _statusBucket, not raw status
    final bucket = _statusBucket(appointment.status);

    // A declined appointment is re-approvable only within 24 h of decline
    final isReapprovableDeclined = bucket == 'declined' &&
        appointment.declinedAt != null &&
        DateTime.now().isAfter(appointment.declinedAt!.toDate()) &&
        DateTime.now().difference(appointment.declinedAt!.toDate()) <=
            const Duration(days: 1);

    final isApproved   = bucket == 'approved';
    final isPending    = bucket == 'pending';
    final isCompleted  = bucket == 'completed';
    final isDeclined   = bucket == 'declined';

    // Colour
    final statusColor = isReapprovableDeclined
        ? Colors.blue
        : isApproved
            ? Colors.green
            : isPending
                ? Colors.orange
                : isCompleted
                    ? Colors.blue
                    : Colors.red; // declined

    // Label
    final statusLabel = isReapprovableDeclined
        ? 'Re-approve'
        : isApproved
            ? 'Approved'
            : isPending
                ? 'Pending'
                : isCompleted
                    ? 'Completed'   // ✅ FIX: was always showing 'Declined'
                    : 'Declined';

    final declineCategory =
        (appointment.declineCategoryText ?? '').trim();
    final doctorNote =
        (appointment.doctorDeclineMessage ?? '').trim();
    final declineText =
        (appointment.declineReasonText ?? '').trim();
    final hasDeclineInfo = isDeclined &&
        (doctorNote.isNotEmpty ||
            declineText.isNotEmpty ||
            declineCategory.isNotEmpty);

    return InkWell(
      // Only tappable if action is possible
      onTap: (isPending || isReapprovableDeclined)
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AppointmentApprovalPage(appointment: appointment),
                ),
              )
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.event_available_rounded,
                    color: statusColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.animalName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: darkGrey),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Appointment On: ${_formatAppointmentSchedule(appointment)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Booked On: ${_formatBookedOn(appointment)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              'Problem: ${appointment.problem}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600),
            ),
            if (hasDeclineInfo) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (declineCategory.isNotEmpty)
                      Text('Reason: $declineCategory',
                          style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    if (doctorNote.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Doctor note: $doctorNote',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.red.shade900,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ] else if (declineText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(declineText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.red.shade900,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SMALLER WIDGETS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAnalyticsTile(
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkGrey)),
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildGraphCard({
    required String title,
    required List<int> values,
    required List<String> labels,
    required List<Color> barColors,
    List<String>? legendLabels,
    List<Color>? legendColors,
  }) {
    final maxValue =
        values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue == 0 ? 1 : maxValue;
    final noData = values.every((v) => v == 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lightTeal.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkGrey)),
        if ((legendLabels ?? const <String>[]).isNotEmpty &&
            (legendColors ?? const <Color>[]).isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: List.generate(legendLabels!.length, (index) {
              final color = legendColors![index % legendColors.length];
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(legendLabels[index],
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: darkGrey)),
                ]),
              );
            }),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          height: 170,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(values.length, (index) {
              final value = values[index];
              final ratio = value / safeMax;
              final barHeight = value == 0 ? 8.0 : 28 + (ratio * 98);
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(value.toString(),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: darkGrey)),
                    const SizedBox(height: 6),
                    Container(
                      width: 20,
                      height: barHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            barColors[index % barColors.length]
                                .withOpacity(0.7),
                            barColors[index % barColors.length],
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(labels[index],
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700])),
                  ],
                ),
              );
            }),
          ),
        ),
        if (noData) ...[
          const SizedBox(height: 10),
          Text('No appointments found for this selected period yet.',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }

  Widget _buildTodaySummaryStrip(
      {required int total,
      required int approved,
      required int pending,
      required int declined}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lightTeal.withOpacity(0.25)),
      ),
      child: Wrap(spacing: 8, runSpacing: 8, children: [
        _buildStatusPill('Today', total.toString(), primaryTeal),
        _buildStatusPill('Approved', approved.toString(), Colors.green),
        _buildStatusPill('Pending', pending.toString(), Colors.orange),
        _buildStatusPill('Declined', declined.toString(), Colors.red),
      ]),
    );
  }

  Widget _buildTodayAppointmentsSection({
    required List<AppointmentModel> dailyAppointments,
    required int approved,
    required int pending,
    required int declined,
  }) {
    final displayItems = dailyAppointments.take(6).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightTeal.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Today Appointments Snapshot',
            style: TextStyle(
                color: darkGrey,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
            'Total: ${dailyAppointments.length} • Approved: $approved • Pending: $pending • Declined: $declined',
            style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (displayItems.isEmpty)
          Text('No appointments captured for today yet.',
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w600))
        else
          ...displayItems.map(_buildPeriodAppointmentTile),
      ]),
    );
  }

  Widget _buildPeriodStatsCards({
    required Map<String, int> weeklyStats,
    required Map<String, int> monthlyStats,
    required int weeklyTotal,
    required int monthlyTotal,
  }) {
    Widget buildCard(
        {required String title,
        required int total,
        required Map<String, int> stats,
        required Color color,
        required IconData icon}) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.28))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 6),
            Text('Total: $total',
                style: TextStyle(
                    color: darkGrey,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
            const SizedBox(height: 2),
            Text(
                'A:${stats['approved']}  P:${stats['pending']}  D:${stats['declined']}',
                style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 11)),
          ]),
        ),
      );
    }

    return Row(children: [
      buildCard(
          title: 'This Week',
          total: weeklyTotal,
          stats: weeklyStats,
          color: Colors.indigo,
          icon: Icons.calendar_view_week_rounded),
      const SizedBox(width: 10),
      buildCard(
          title: 'This Month',
          total: monthlyTotal,
          stats: monthlyStats,
          color: Colors.deepPurple,
          icon: Icons.calendar_month_rounded),
    ]);
  }

  Widget _buildStatusPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text('$label: $value',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _buildRangeButton(
      {required String label, required int count, required String value}) {
    final isSelected = _selectedAnalyticsView == value;
    return GestureDetector(
      onTap: () => _setAnalyticsView(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [primaryTeal, lightTeal])
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : primaryTeal.withOpacity(0.25)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: primaryTeal.withOpacity(0.24),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : darkGrey)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : primaryTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(count.toString(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color:
                            isSelected ? Colors.white : primaryTeal)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodAppointmentsSection({
    required String title,
    required String subtitle,
    required List<AppointmentModel> appointments,
    required String emptyText,
  }) {
    final items = appointments.take(8).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightTeal.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkGrey)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text(emptyText,
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500))
        else
          ...items.map(_buildPeriodAppointmentTile),
      ]),
    );
  }

  Widget _buildApprovedDetailsSection({
    required String title,
    required String subtitle,
    required List<AppointmentModel> appointments,
    required String emptyText,
  }) {
    final displayAppointments = appointments.take(5).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lightTeal.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: darkGrey)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        if (displayAppointments.isEmpty)
          Text(emptyText,
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500))
        else
          ...displayAppointments.map(_buildApprovedAppointmentTile),
      ]),
    );
  }

  Widget _buildApprovedAppointmentTile(AppointmentModel appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cardGrey, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appointment.animalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: darkGrey)),
              const SizedBox(height: 3),
              Text(
                  'Appointment On: ${_formatAppointmentSchedule(appointment)}',
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Booked On: ${_formatBookedOn(appointment)}',
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
              color: primaryTeal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Text('Approved',
              style: TextStyle(
                  color: primaryTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DECLINE / APPROVE  (dashboard quick-actions — kept identical to original)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _approveAppointment(AppointmentModel appointment) async {
    final latestDoc = await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointment.id)
        .get();
    final latestData = latestDoc.data() ?? <String, dynamic>{};
    final wasDeclined =
        _statusBucket((latestData['status'] ?? appointment.status).toString()) ==
            'declined';

    await _appointmentService.updateStatus(appointment.id, 'approved');
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointment.id)
        .set({
      'reapprovedAt': FieldValue.serverTimestamp(),
      'reapprovedFromDecline': wasDeclined,
      'declineReason': FieldValue.delete(),
      'declineReasonText': FieldValue.delete(),
      'declinedAt': FieldValue.delete(),
    }, SetOptions(merge: true));

    await _notificationService.sendNotification(
      receiverId: appointment.userId,
      title: wasDeclined ? 'Appointment Re-Approved' : 'Appointment Approved',
      message: wasDeclined
          ? 'Your appointment with ${appointment.animalName} has been re-approved.\nAppointment On: ${_formatAppointmentSchedule(appointment)}\nBooked On: ${_formatBookedOn(appointment)}'
          : 'Your appointment with ${appointment.animalName} has been approved.\nAppointment On: ${_formatAppointmentSchedule(appointment)}\nBooked On: ${_formatBookedOn(appointment)}',
      appointmentId: appointment.id,
      type: wasDeclined ? 'appointment_reapproved' : 'appointment_approved',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Appointment approved')));
  }

  Future<void> _declineAppointment(AppointmentModel appointment) async {
    final reasonCode = await _showDeclineReasonPicker();
    if (reasonCode == null) return;

    final reasonText = _getDeclineReasonLabel(reasonCode);
    final doctorMessage =
        await _showDoctorDeclineMessageDialog(reasonText);
    if (doctorMessage == null) return;

    final needsRefund = reasonCode != 'fake_screenshot';

    await _appointmentService.updateStatus(appointment.id, 'declined');
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointment.id)
        .set({
      'declineReason': reasonCode,
      'declineReasonText': '$reasonText. Doctor note: $doctorMessage',
      'doctorDeclineMessage': doctorMessage,
      'declineCategoryText': reasonText,
      'refundRequired': needsRefund,
      'declinedAt': Timestamp.now(),
    }, SetOptions(merge: true));

    await _notificationService.sendNotification(
      receiverId: appointment.userId,
      title: 'Appointment Declined',
      message:
          'Your appointment with ${appointment.animalName} has been declined.\n'
          'Appointment On: ${_formatAppointmentSchedule(appointment)}\n'
          'Booked On: ${_formatBookedOn(appointment)}\n'
          'Reason: $reasonText\nDoctor note: $doctorMessage'
          '${needsRefund ? '\nRefund will be processed in 24-48 hours.' : '\nNo refund issued due to invalid payment proof.'}',
      appointmentId: appointment.id,
      type: 'appointment_declined',
    );

    await _notifyAdminsForDecline(
      appointment: appointment,
      reasonText: reasonText,
      doctorMessage: doctorMessage,
      needsRefund: needsRefund,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Appointment declined with professional note')));
  }

  Future<String?> _showDeclineReasonPicker() async {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Decline Reason'),
        children: [
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'fake_screenshot'),
              child: const Text('Fake/Invalid Payment Screenshot')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'no_time'),
              child: const Text('Schedule Conflict / No Time')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'other'),
              child: const Text('Other Reason')),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<String?> _showDoctorDeclineMessageDialog(
      String reasonText) async {
    final controller = TextEditingController();
    String? validationError;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Professional Explanation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reason: $reasonText',
                  style:
                      const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const Text(
                  'Write a clear message for user and admin (minimum 10 characters).',
                  style:
                      TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                maxLength: 280,
                onChanged: (_) {
                  if (validationError != null) {
                    setDialogState(() => validationError = null);
                  }
                },
                decoration: InputDecoration(
                  hintText:
                      'Explain the issue briefly and professionally',
                  border: const OutlineInputBorder(),
                  errorText: validationError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final note = controller.text.trim();
                if (note.length < 10) {
                  setDialogState(() => validationError =
                      'Please enter at least 10 characters.');
                  return;
                }
                Navigator.pop(dialogContext, note);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  String _getDeclineReasonLabel(String reasonCode) {
    switch (reasonCode) {
      case 'fake_screenshot':
        return 'Invalid/fake payment screenshot';
      case 'no_time':
        return 'Schedule conflict';
      case 'other':
        return 'Other reason';
      default:
        return 'Declined by doctor';
    }
  }

  Future<void> _notifyAdminsForDecline({
    required AppointmentModel appointment,
    required String reasonText,
    required String doctorMessage,
    required bool needsRefund,
  }) async {
    try {
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Admin')
          .get();

      for (final admin in adminSnapshot.docs) {
        await _notificationService.sendNotification(
          receiverId: admin.id,
          title: needsRefund
              ? 'Manual Refund Required'
              : 'Declined Without Refund',
          message: needsRefund
              ? 'Appointment ${appointment.id} declined. Process refund of Rs. ${appointment.paymentAmount.toStringAsFixed(0)}.\n'
                  'Appointment On: ${_formatAppointmentSchedule(appointment)}\n'
                  'Booked On: ${_formatBookedOn(appointment)}\n'
                  'Reason: $reasonText\nDoctor note: $doctorMessage'
              : 'Appointment ${appointment.id} declined without refund.\n'
                  'Appointment On: ${_formatAppointmentSchedule(appointment)}\n'
                  'Booked On: ${_formatBookedOn(appointment)}\n'
                  'Reason: $reasonText\nDoctor note: $doctorMessage',
          appointmentId: appointment.id,
          type: needsRefund
              ? 'admin_refund_request'
              : 'admin_decline_notice',
        );
      }
    } catch (e) {
      debugPrint('Error notifying admins about decline: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DATE / STATUS UTILITIES
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, int> _statusCounts(List<AppointmentModel> appointments) {
    final counts = <String, int>{
      'approved': 0,
      'pending': 0,
      'declined': 0,
      'completed': 0,
    };
    for (final a in appointments) {
      final bucket = _statusBucket(a.status);
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    return counts;
  }

  DateTime _appointmentDay(Timestamp timestamp) {
    final local = timestamp.toDate().toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  bool _isSameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  bool _matchesDay(Timestamp timestamp, DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    if (_isSameDate(_appointmentDay(timestamp), target)) return true;
    final utc = timestamp.toDate().toUtc();
    return utc.year == target.year &&
        utc.month == target.month &&
        utc.day == target.day;
  }

  bool _isTodayAppointment(
      AppointmentModel appointment, DateTime today) {
    if (_matchesDay(appointment.date, today)) return true;
    final created = appointment.createdAt;
    if (created != null && _matchesDay(created, today)) return true;
    return false;
  }

  String _weekdayLabel(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1).clamp(0, 6)];
  }

  String _formatShortDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatAppointmentSchedule(AppointmentModel appointment) {
    final date = appointment.date.toDate().toLocal();
    final dayDate = DateFormat('EEE, dd MMM yyyy').format(date);
    final time = appointment.time.trim();
    return time.isEmpty ? dayDate : '$dayDate  •  $time';
  }

  String _formatBookedOn(AppointmentModel appointment) {
    final bookedAt = appointment.createdAt;
    if (bookedAt == null) return 'Not recorded';
    return DateFormat('EEE, dd MMM yyyy  •  hh:mm a')
        .format(bookedAt.toDate().toLocal());
  }

  Map<String, Object> _buildDynamicGraphData({
    required String selectedView,
    required DateTime now,
    required List<AppointmentModel> dailyAppointments,
    required List<AppointmentModel> weeklyAppointments,
    required List<AppointmentModel> monthlyAppointments,
    required DateTime weekStart,
    required DateTime monthStart,
  }) {
    if (selectedView == 'daily') {
      final approved = dailyAppointments
          .where((a) => _statusBucket(a.status) == 'approved')
          .length;
      final pending = dailyAppointments
          .where((a) => _statusBucket(a.status) == 'pending')
          .length;
      final declined = dailyAppointments
          .where((a) => _statusBucket(a.status) == 'declined')
          .length;
      return {
        'title': 'Today Status Distribution',
        'labels': <String>['Approved', 'Pending', 'Declined'],
        'values': <int>[approved, pending, declined],
        'barColors': <Color>[Colors.green, Colors.orange, Colors.red],
        'legendLabels': <String>['Approved', 'Pending', 'Declined'],
        'legendColors': <Color>[Colors.green, Colors.orange, Colors.red],
      };
    }

    if (selectedView == 'weekly') {
      final labels = <String>[];
      final values = <int>[];
      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        final count = weeklyAppointments.where((a) {
          final d = a.date.toDate().toLocal();
          return _isSameDate(d, day);
        }).length;
        labels.add(_weekdayLabel(day.weekday));
        values.add(count);
      }
      return {
        'title': 'Weekly Appointments Trend',
        'labels': labels,
        'values': values,
        'barColors': List<Color>.filled(labels.length, primaryTeal),
        'legendLabels': <String>[],
        'legendColors': <Color>[],
      };
    }

    // monthly
    final labels = <String>['W1', 'W2', 'W3', 'W4', 'W5'];
    final values = List<int>.filled(5, 0);
    for (final a in monthlyAppointments) {
      final date = a.date.toDate().toLocal();
      if (date.year != now.year || date.month != now.month) continue;
      final weekIndex = ((date.day - 1) ~/ 7).clamp(0, 4);
      values[weekIndex] += 1;
    }
    return {
      'title': 'Monthly Week-wise Appointments',
      'labels': labels,
      'values': values,
      'barColors': List<Color>.filled(labels.length, primaryTeal),
      'legendLabels': <String>[],
      'legendColors': <Color>[],
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PDF EXPORT
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _exportAnalyticsPdf({
    required int total,
    required int approved,
    required int pending,
    required int weeklyApproved,
    required int monthlyApproved,
    required String selectedTitle,
    required List<AppointmentModel> selectedAppointments,
  }) async {
    try {
      final doc = pw.Document();
      final generatedAt = DateTime.now();
      final doctorName = doctorProfile?.name ?? 'Doctor';
      final clinicName =
          doctorProfile?.clinicName?.trim().isNotEmpty == true
              ? doctorProfile!.clinicName!
              : 'DignoVet Clinic';
      final doctorSpecialization =
          doctorProfile?.specialization?.trim().isNotEmpty == true
              ? doctorProfile!.specialization!
              : 'Veterinary Specialist';

      Uint8List? logoBytes;
      try {
        final data = await rootBundle.load('assets/login/cow.png');
        logoBytes = data.buffer.asUint8List();
      } catch (_) {
        logoBytes = null;
      }

      final rangeTitleUrduRoman = _selectedAnalyticsView == 'daily'
          ? 'Rozana Appointments'
          : _selectedAnalyticsView == 'weekly'
              ? 'Haftewar Appointments'
              : 'Mahana Appointments';

      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
              'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600)),
        ),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                  colors: [PdfColors.teal700, PdfColors.teal400]),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoBytes != null)
                  pw.Container(
                    height: 42,
                    width: 42,
                    margin: const pw.EdgeInsets.only(right: 12),
                    child: pw.Image(pw.MemoryImage(logoBytes),
                        fit: pw.BoxFit.cover),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(clinicName,
                          style: pw.TextStyle(
                              fontSize: 17,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                      pw.SizedBox(height: 2),
                      pw.Text('Doctor Analytics Report / Doctor Report',
                          style: const pw.TextStyle(
                              fontSize: 11, color: PdfColors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Doctor Name / Doctor ka Naam: $doctorName'),
          pw.Text('Specialization / Maharat: $doctorSpecialization'),
          pw.Text(
              'Generated / Banaya gaya: ${generatedAt.toLocal()}'),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.teal200),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Summary / Khulasa',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Text(
                      'Total Appointments / Kul Appointments: $total'),
                  pw.Text('Approved / Manzoor: $approved'),
                  pw.Text('Pending / Intezaar mein: $pending'),
                  pw.Text(
                      'Weekly Approved / Haftewar Manzoor: $weeklyApproved'),
                  pw.Text(
                      'Monthly Approved / Mahana Manzoor: $monthlyApproved'),
                ]),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            '$selectedTitle (${selectedAppointments.length})  |  $rangeTitleUrduRoman',
            style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal700),
          ),
          pw.SizedBox(height: 8),
          if (selectedAppointments.isEmpty)
            pw.Text(
                'No appointments found for selected range. / Is range mein appointments nahi milin.')
          else
            pw.TableHelper.fromTextArray(
              headers: [
                'Animal / Janwar',
                'Date / Tareekh',
                'Time / Waqt',
                'Status / Halat',
                'Problem / Masla'
              ],
              data: selectedAppointments.take(20).map((a) => [
                    a.animalName,
                    _formatShortDate(a.date),
                    a.time,
                    a.status,
                    a.problem,
                  ]).toList(),
              headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.teal600),
              cellHeight: 28,
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
        ],
      ));

      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'doctor_analytics_${generatedAt.year}${generatedAt.month.toString().padLeft(2, '0')}${generatedAt.day.toString().padLeft(2, '0')}.pdf',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Unable to export PDF report right now.')));
    }
  }

  Widget _buildPlaceholderCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lightTeal.withOpacity(0.3)),
      ),
      child: Text(message,
          style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SPLASH SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class DoctorWelcomeSplashScreen extends StatefulWidget {
  const DoctorWelcomeSplashScreen({super.key});

  @override
  State<DoctorWelcomeSplashScreen> createState() =>
      _DoctorWelcomeSplashScreenState();
}

class _DoctorWelcomeSplashScreenState
    extends State<DoctorWelcomeSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(seconds: 3), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.8)));
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.1, 0.7)));
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (_, __, ___) => const DoctorDashboardPage(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
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
                const Text('Welcome Back',
                    style: TextStyle(
                        fontSize: 36,
                        color: Colors.indigo,
                        fontWeight: FontWeight.w500)),
                const Text('Dr. Emelle',
                    style: TextStyle(
                        fontSize: 52,
                        color: Colors.teal,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text('Ready to care for more pets today?',
                    style: TextStyle(
                        fontSize: 20, color: Colors.black87),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}