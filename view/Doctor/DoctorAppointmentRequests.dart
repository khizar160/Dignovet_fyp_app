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
    extends State<DoctorAppointmentRequestsPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final NotificationService _notificationService = NotificationService();

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate().toLocal();
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = AuthService.currentUser?.uid;
    log('DoctorAppointmentRequestsPage built for doctorId: $doctorId');

    if (doctorId == null) {
      log('No doctor logged in');
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF80CBC4),
          title: const Text('Pending Requests'),
        ),
        body: const Center(child: Text('Please log in as doctor')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF80CBC4),
        elevation: 0,
        title: const Text(
          'Pending Appointment Requests',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            log('Back button pressed');
            Navigator.pop(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          log('Pull-to-refresh triggered');
          setState(() {}); // Trigger rebuild to refresh stream
          await Future.delayed(const Duration(seconds: 1));
        },
        child: StreamBuilder<QuerySnapshot>(
          key: ValueKey('doctor_appointment_requests_$doctorId'),
          stream: _appointmentService.doctorAppointments(doctorId),
          builder: (context, snapshot) {
            log('StreamBuilder state: ${snapshot.connectionState}');
            if (snapshot.connectionState == ConnectionState.waiting) {
              log('Stream waiting for data...');
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              log('Error loading appointments: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error loading appointments: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        log('Retry button pressed');
                        setState(() {});
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              log('No pending appointment requests found');
              return const Center(child: Text('No pending requests'));
            }

            log(
              'Appointments data received: ${snapshot.data!.docs.length} items',
            );
            final appointments = snapshot.data!.docs.map((doc) {
              final appointment = AppointmentModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
              log(
                'Loaded appointment: ${appointment.id} for animal: ${appointment.animalName}',
              );
              return appointment;
            }).toList();

            // Sort by date descending
            appointments.sort((a, b) => b.date.compareTo(a.date));

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return _buildAppointmentItem(appointment);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(AppointmentModel appointment) {
    log(
      'Building appointment item for: ${appointment.animalName}, id: ${appointment.id}',
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            'Date: ${_formatDate(appointment.date)} at ${appointment.time}',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          Text(
            'Problem: ${appointment.problem}',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                log(
                  'View Details pressed for appointment id: ${appointment.id}',
                );
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AppointmentApprovalPage(appointment: appointment),
                  ),
                );
                // Force refresh after returning
                if (mounted) {
                  log('Returned from appointment details, refreshing');
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 30,
                ),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(color: Color(0xFF00796B)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/model/appointment_model.dart';
// import 'package:flutter_application_1/services/Appointment Service/appointment_services.dart';
// import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
// import 'package:flutter_application_1/view/Doctor/Apponitment_approval_page.dart';

// class DoctorAppointmentRequestsPage extends StatefulWidget {
//   const DoctorAppointmentRequestsPage({super.key});

//   @override
//   State<DoctorAppointmentRequestsPage> createState() =>
//       _DoctorAppointmentRequestsPageState();
// }

// class _DoctorAppointmentRequestsPageState
//     extends State<DoctorAppointmentRequestsPage> with SingleTickerProviderStateMixin {
//   final AppointmentService _appointmentService = AppointmentService();

//   final Color primaryTeal = const Color(0xFF80CBC4);
//   final Color darkTeal = const Color(0xFF00796B);
//   final Color scaffoldBg = Colors.white;

//   late TabController _tabController;
//   String selectedStatus = 'requested'; // requested, approved, declined, all

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//     _tabController.addListener(() {
//       setState(() {
//         switch (_tabController.index) {
//           case 0:
//             selectedStatus = 'requested';
//             break;
//           case 1:
//             selectedStatus = 'approved';
//             break;
//           case 2:
//             selectedStatus = 'declined';
//             break;
//           case 3:
//             selectedStatus = 'all';
//             break;
//         }
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   String _formatDate(Timestamp timestamp) {
//     final date = timestamp.toDate();
//     final now = DateTime.now();
//     final diff = now.difference(date).inDays;

//     if (diff == 0) return 'Today';
//     if (diff == 1) return 'Tomorrow';
//     if (diff == -1) return 'Yesterday';
//     if (diff < 7 && diff > 0) return '$diff days from now';
//     if (diff > -7 && diff < 0) return '${diff.abs()} days ago';

//     final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
//     return '${months[date.month - 1]} ${date.day}, ${date.year}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final doctorId = AuthService.currentUser?.uid;

//     if (doctorId == null) {
//       return _errorScaffold('Please login as doctor');
//     }

//     return Scaffold(
//       backgroundColor: scaffoldBg,
//       body: Column(
//         children: [
//           _buildHeader(),
//           _buildTabBar(),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _appointmentService.doctorAppointments(doctorId),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   return _errorState('Failed to load appointments');
//                 }

//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return _emptyState('No appointments found');
//                 }

//                 // Parse appointments
//                 final allAppointments = snapshot.data!.docs
//                     .map((doc) => AppointmentModel.fromMap(
//                           doc.data() as Map<String, dynamic>,
//                           doc.id,
//                         ))
//                     .toList();

//                 // Filter based on selected status
//                 final filteredAppointments = selectedStatus == 'all'
//                     ? allAppointments
//                     : allAppointments
//                         .where((apt) => apt.status == selectedStatus)
//                         .toList();

//                 if (filteredAppointments.isEmpty) {
//                   return _emptyState('No ${selectedStatus} appointments');
//                 }

//                 return ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: filteredAppointments.length,
//                   physics: const BouncingScrollPhysics(),
//                   itemBuilder: (context, index) {
//                     return _appointmentCard(filteredAppointments[index]);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= HEADER =================
//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
//       decoration: BoxDecoration(
//         color: primaryTeal,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back, color: Colors.white),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   const Text(
//                     'DignoVet',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//               Row(
//                 children: const [
//                   Icon(Icons.search, color: Colors.white, size: 26),
//                   SizedBox(width: 15),
//                   Icon(Icons.notifications_none, color: Colors.white, size: 26),
//                 ],
//               )
//             ],
//           ),
//           const SizedBox(height: 20),
//           const Text(
//             'Appointment Requests',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 28,
//               fontWeight: FontWeight.w600,
//               letterSpacing: 0.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= TAB BAR =================
//   Widget _buildTabBar() {
//     return Container(
//       color: Colors.white,
//       child: TabBar(
//         controller: _tabController,
//         labelColor: darkTeal,
//         unselectedLabelColor: Colors.grey,
//         indicatorColor: darkTeal,
//         indicatorWeight: 3,
//         labelStyle: const TextStyle(
//           fontWeight: FontWeight.bold,
//           fontSize: 14,
//         ),
//         tabs: const [
//           Tab(text: 'Pending'),
//           Tab(text: 'Approved'),
//           Tab(text: 'Declined'),
//           Tab(text: 'All'),
//         ],
//       ),
//     );
//   }

//   // ================= APPOINTMENT CARD =================
//   Widget _appointmentCard(AppointmentModel appointment) {
//     return FutureBuilder<Map<String, dynamic>>(
//       future: _fetchAppointmentDetails(appointment),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return Card(
//             elevation: 2,
//             margin: const EdgeInsets.only(bottom: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: const Padding(
//               padding: EdgeInsets.all(16),
//               child: Center(child: CircularProgressIndicator()),
//             ),
//           );
//         }

//         final data = snapshot.data!;
//         final animalData = data['animal'] as Map<String, dynamic>?;
//         final userData = data['user'] as Map<String, dynamic>?;

//         return Card(
//           elevation: 3,
//           margin: const EdgeInsets.only(bottom: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: InkWell(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => AppointmentApprovalPage(appointment: appointment),
//                 ),
//               );
//             },
//             borderRadius: BorderRadius.circular(20),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Status Badge
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       _buildStatusBadge(appointment.status),
//                       Text(
//                         _formatDate(appointment.date),
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 13,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),

//                   // Animal & Owner Info Row
//                   Row(
//                     children: [
//                       // Animal Image
//                       _buildAnimalImage(animalData),
//                       const SizedBox(width: 15),

//                       // Details
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Animal Name
//                             Text(
//                               animalData?['name'] ?? appointment.animalName,
//                               style: const TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                             const SizedBox(height: 4),

//                             // Animal Type & Breed
//                             Text(
//                               '${animalData?['type'] ?? 'Pet'} • ${animalData?['breed'] ?? 'Unknown Breed'}',
//                               style: TextStyle(
//                                 color: Colors.grey[700],
//                                 fontSize: 14,
//                               ),
//                             ),
//                             const SizedBox(height: 4),

//                             // Owner Name
//                             Row(
//                               children: [
//                                 Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   userData?['name'] ?? 'Unknown Owner',
//                                   style: TextStyle(
//                                     color: Colors.grey[600],
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),
//                   const Divider(height: 1),
//                   const SizedBox(height: 12),

//                   // Appointment Time
//                   Row(
//                     children: [
//                       Icon(Icons.access_time, size: 18, color: darkTeal),
//                       const SizedBox(width: 8),
//                       Text(
//                         appointment.time,
//                         style: TextStyle(
//                           color: Colors.grey[800],
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),

//                   // Problem/Reason
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(Icons.medical_services_outlined, size: 18, color: darkTeal),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           appointment.problem,
//                           style: TextStyle(
//                             color: Colors.grey[700],
//                             fontSize: 14,
//                             height: 1.3,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // View Details Button
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => AppointmentApprovalPage(appointment: appointment),
//                           ),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: darkTeal,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         elevation: 0,
//                       ),
//                       child: const Text(
//                         'View Details',
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // ================= ANIMAL IMAGE =================
//   Widget _buildAnimalImage(Map<String, dynamic>? animalData) {
//     String? imageUrl;
    
//     if (animalData != null && animalData['imageUrls'] != null) {
//       final imageUrls = animalData['imageUrls'] as List;
//       if (imageUrls.isNotEmpty) {
//         imageUrl = imageUrls[0] as String;
//       }
//     }

//     return Container(
//       height: 80,
//       width: 80,
//       decoration: BoxDecoration(
//         color: primaryTeal.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: primaryTeal.withOpacity(0.3),
//           width: 2,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(14),
//         child: imageUrl != null
//             ? Image.network(
//                 imageUrl,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) {
//                   return Icon(Icons.pets, size: 40, color: darkTeal);
//                 },
//                 loadingBuilder: (context, child, loadingProgress) {
//                   if (loadingProgress == null) return child;
//                   return Center(
//                     child: CircularProgressIndicator(
//                       value: loadingProgress.expectedTotalBytes != null
//                           ? loadingProgress.cumulativeBytesLoaded /
//                               loadingProgress.expectedTotalBytes!
//                           : null,
//                     ),
//                   );
//                 },
//               )
//             : Icon(Icons.pets, size: 40, color: darkTeal),
//       ),
//     );
//   }

//   // ================= STATUS BADGE =================
//   Widget _buildStatusBadge(String status) {
//     Color bgColor;
//     Color textColor;
//     String label;
//     IconData icon;

//     switch (status.toLowerCase()) {
//       case 'approved':
//         bgColor = Colors.green.withOpacity(0.1);
//         textColor = Colors.green.shade700;
//         label = 'Approved';
//         icon = Icons.check_circle_outline;
//         break;
//       case 'declined':
//         bgColor = Colors.red.withOpacity(0.1);
//         textColor = Colors.red.shade700;
//         label = 'Declined';
//         icon = Icons.cancel_outlined;
//         break;
//       case 'completed':
//         bgColor = Colors.blue.withOpacity(0.1);
//         textColor = Colors.blue.shade700;
//         label = 'Completed';
//         icon = Icons.done_all;
//         break;
//       default: // requested
//         bgColor = Colors.orange.withOpacity(0.1);
//         textColor = Colors.orange.shade700;
//         label = 'Pending';
//         icon = Icons.schedule;
//         break;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: textColor.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: textColor),
//           const SizedBox(width: 6),
//           Text(
//             label,
//             style: TextStyle(
//               color: textColor,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= FETCH DETAILS =================
//   Future<Map<String, dynamic>> _fetchAppointmentDetails(
//       AppointmentModel appointment) async {
//     try {
//       // Fetch animal data
//       final animalSnapshot = await FirebaseFirestore.instance
//           .collection('animals')
//           .where('userId', isEqualTo: appointment.userId)
//           .where('name', isEqualTo: appointment.animalName)
//           .limit(1)
//           .get();

//       Map<String, dynamic>? animalData;
//       if (animalSnapshot.docs.isNotEmpty) {
//         animalData = animalSnapshot.docs.first.data();
//       }

//       // Fetch user data
//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(appointment.userId)
//           .get();

//       Map<String, dynamic>? userData;
//       if (userDoc.exists) {
//         userData = userDoc.data();
//       }

//       return {
//         'animal': animalData,
//         'user': userData,
//       };
//     } catch (e) {
//       print('Error fetching appointment details: $e');
//       return {
//         'animal': null,
//         'user': null,
//       };
//     }
//   }

//   // ================= EMPTY STATE =================
//   Widget _emptyState(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.event_busy,
//             size: 80,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 20),
//           Text(
//             message,
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.grey[600],
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Pull down to refresh',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= ERROR STATE =================
//   Widget _errorState(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Icon(Icons.error_outline, size: 80, color: Colors.red),
//           const SizedBox(height: 20),
//           Text(
//             message,
//             style: const TextStyle(fontSize: 16, color: Colors.red),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 20),
//           ElevatedButton.icon(
//             onPressed: () {
//               setState(() {}); // Trigger rebuild
//             },
//             icon: const Icon(Icons.refresh),
//             label: const Text('Retry'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: darkTeal,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Scaffold _errorScaffold(String message) {
//     return Scaffold(
//       appBar: AppBar(backgroundColor: primaryTeal),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, size: 80, color: Colors.red),
//             const SizedBox(height: 20),
//             Text(
//               message,
//               style: const TextStyle(fontSize: 16),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


