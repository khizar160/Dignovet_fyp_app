// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/model/appointment_model.dart';
// import 'package:flutter_application_1/model/app_user.dart';
// import 'package:flutter_application_1/services/Appointment Service/appointment_services.dart';
// import 'package:flutter_application_1/services/notification service/notification_service.dart';
// import 'package:flutter_application_1/view/Doctor/UserProfilePage.dart';
// import 'package:flutter_application_1/view/User/ChatScreen.dart';

// class AppointmentApprovalPage extends StatefulWidget {
//   final AppointmentModel appointment;

//   const AppointmentApprovalPage({super.key, required this.appointment});

//   @override
//   State<AppointmentApprovalPage> createState() => _AppointmentApprovalPageState();
// }

// class _AppointmentApprovalPageState extends State<AppointmentApprovalPage> {
//   final AppointmentService _appointmentService = AppointmentService();
//   final NotificationService _notificationService = NotificationService();

//   // DignoVet Theme Colors
//   final Color primaryTeal = const Color(0xFF80CBC4);
//   final Color darkTeal = const Color(0xFF00796B);
//   final Color lightGrey = const Color(0xFFF5F5F5);

//   AppUser? user;
//   Map<String, dynamic>? animalData;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchData();
//   }

//   Future<void> _fetchData() async {
//     try {
//       // Fetch user data
//       final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.appointment.userId).get();
//       if (userDoc.exists) {
//         user = AppUser.fromMap(userDoc.data()!, userDoc.id);
//       }

//       // Fetch animal data - query by name and userId since animalName is the name, not ID
//       final animalSnapshot = await FirebaseFirestore.instance
//           .collection('animals')
//           .where('userId', isEqualTo: widget.appointment.userId)
//           .where('name', isEqualTo: widget.appointment.animalName)
//           .get();

//       if (animalSnapshot.docs.isNotEmpty) {
//         animalData = animalSnapshot.docs.first.data();
//       }

//       setState(() => isLoading = false);
//     } catch (e) {
//       // Handle errors gracefully
//       setState(() => isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Some data could not be loaded: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<void> _approveAppointment() async {
//     try {
//       await _appointmentService.updateStatus(widget.appointment.id, 'approved');
//       await _notificationService.sendNotification(
//         receiverId: widget.appointment.userId,
//         title: 'Appointment Approved',
//         message: 'Your appointment for ${animalData?['name'] ?? widget.appointment.animalName} has been approved.',
//         appointmentId: widget.appointment.id,
//         type: 'appointment_approved',
//       );

//       // Navigate to chat
//       if (user != null) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (_) => ChatScreen(
//               receiverId: widget.appointment.userId,
//               receiverName: user!.name,
//               receiverImage: user!.imageUrl,
//               isOnline: true,
//             ),
//           ),
//         );
//       } else {
//         // If user data not available, just go back
//         Navigator.pop(context);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Appointment approved successfully')),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error approving appointment: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<void> _declineAppointment() async {
//     try {
//       await _appointmentService.updateStatus(widget.appointment.id, 'declined');
//       await _notificationService.sendNotification(
//         receiverId: widget.appointment.userId,
//         title: 'Appointment Declined',
//         message: 'Your appointment for ${animalData?['name'] ?? widget.appointment.animalName} has been declined.',
//         appointmentId: widget.appointment.id,
//         type: 'appointment_declined',
//       );

//       Navigator.pop(context);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Appointment declined successfully')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error declining appointment: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           backgroundColor: primaryTeal,
//           title: const Text("Request Details"),
//         ),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: primaryTeal,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text("Request Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         physics: const BouncingScrollPhysics(),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildStatusHeader(),
//             const SizedBox(height: 20),

//             // 1. User/Owner Section
//             _sectionLabel("Owner Information"),
//             _buildUserCard(),

//             const SizedBox(height: 20),

//             // 2. Animal Section
//             _sectionLabel("Animal Details"),
//             _buildAnimalCard(),

//             const SizedBox(height: 20),

//             // 3. Appointment Information Section
//             _sectionLabel("Appointment Information"),
//             _buildAppointmentDetails(),

//             const SizedBox(height: 30),

//             // 4. Action Buttons (Accept / Decline)
//             _buildActionButtons(context),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _sectionLabel(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 4, bottom: 10),
//       child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
//     );
//   }

//   // Header Status Badge
//   Widget _buildStatusHeader() {
//     return Align(
//       alignment: Alignment.centerRight,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: Colors.orange.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: Colors.orange.shade300),
//         ),
//         child: const Text("Requested", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
//       ),
//     );
//   }

//   // User Card
//   Widget _buildUserCard() {
//     if (user == null) {
//       return Container(
//         padding: const EdgeInsets.all(15),
//         decoration: BoxDecoration(
//           color: lightGrey,
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: const Text("User data not available"),
//       );
//     }

//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: lightGrey,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: primaryTeal.withOpacity(0.2),
//             backgroundImage: user!.imageUrl != null ? NetworkImage(user!.imageUrl!) : null,
//             child: user!.imageUrl == null ? Icon(Icons.person, color: darkTeal) : null,
//           ),
//           const SizedBox(width: 15),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(user!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 Text(user!.role, style: const TextStyle(color: Colors.grey)),
//               ],
//             ),
//           ),
//           GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => UserProfilePage(userId: widget.appointment.userId),
//                 ),
//               );
//             },
//             child: Text("View Profile", style: TextStyle(color: darkTeal, fontWeight: FontWeight.bold, fontSize: 12)),
//           ),
//         ],
//       ),
//     );
//   }

//   // Animal Card
//   Widget _buildAnimalCard() {
//     if (animalData == null) {
//       return Container(
//         padding: const EdgeInsets.all(15),
//         decoration: BoxDecoration(
//           color: lightGrey,
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: const Text("Animal data not available"),
//       );
//     }

//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: lightGrey,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundColor: primaryTeal.withOpacity(0.2),
//             backgroundImage: animalData!['imageUrls'] != null && (animalData!['imageUrls'] as List).isNotEmpty
//                 ? NetworkImage(animalData!['imageUrls'][0])
//                 : null,
//             child: (animalData!['imageUrls'] == null || (animalData!['imageUrls'] as List).isEmpty) ? Icon(Icons.pets, color: darkTeal) : null,
//           ),
//           const SizedBox(width: 15),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("${animalData!['name'] ?? 'Unknown'} (${animalData!['type'] ?? 'Animal'})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 Text("${animalData!['breed'] ?? 'Unknown Breed'} • ${animalData!['age'] ?? 'N/A'} Years", style: const TextStyle(color: Colors.grey)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Appointment Specific Details (Matches image_1785c2.png)
//   Widget _buildAppointmentDetails() {
//     final dateTime = widget.appointment.date.toDate();
//     final formattedDate = "${_getDayName(dateTime.weekday)}, ${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year}";

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
//       ),
//       child: Column(
//         children: [
//           _detailRow(Icons.calendar_today_outlined, "Date & Time", "$formattedDate\n${widget.appointment.time}"),
//           const Divider(height: 30),
//           _detailRow(Icons.description_outlined, "Reason for Visit", widget.appointment.problem),
//           const Divider(height: 30),
//           _detailRow(Icons.error_outline, "Additional Notes", "Please provide more details if needed"),
//         ],
//       ),
//     );
//   }

//   String _getDayName(int weekday) {
//     const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
//     return days[weekday - 1];
//   }

//   String _getMonthName(int month) {
//     const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
//     return months[month - 1];
//   }

//   Widget _detailRow(IconData icon, String label, String value) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(icon, color: Colors.grey, size: 22),
//         const SizedBox(width: 15),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
//               const SizedBox(height: 4),
//               Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // Acceptance / Decline Buttons
//   Widget _buildActionButtons(BuildContext context) {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           height: 55,
//           child: ElevatedButton.icon(
//             onPressed: _approveAppointment,
//             icon: const Icon(Icons.check_circle_outline, color: Colors.white),
//             label: const Text("Accept Appointment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: darkTeal,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//             ),
//           ),
//         ),
//         const SizedBox(height: 15),
//         SizedBox(
//           width: double.infinity,
//           height: 55,
//           child: OutlinedButton.icon(
//             onPressed: _declineAppointment,
//             icon: const Icon(Icons.cancel_outlined, color: Colors.red),
//             label: const Text("Decline Request", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
//             style: OutlinedButton.styleFrom(
//               side: const BorderSide(color: Colors.red),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/model/app_user.dart';
import 'package:flutter_application_1/services/Appointment Service/appointment_services.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:flutter_application_1/services/notification service/notification_service.dart';
import 'package:flutter_application_1/view/Doctor/UserProfilePage.dart';
import 'package:flutter_application_1/view/User/ChatScreen.dart';

class AppointmentApprovalPage extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentApprovalPage({super.key, required this.appointment});

  @override
  State<AppointmentApprovalPage> createState() => _AppointmentApprovalPageState();
}

class _AppointmentApprovalPageState extends State<AppointmentApprovalPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final NotificationService _notificationService = NotificationService();

  // DignoVet Theme Colors (matching doctor_profile.dart)
  final Color primaryTeal = Color(0xFF00796B);
  final Color lightTeal = Color(0xFF4DB6AC);
  final Color cardGrey = Color(0xFFF8F9FA);
  final Color darkGrey = Color(0xFF2C3E50);
  final Color lightGrey = Color(0xFFF5F5F5);
  
  // Reference for backward compatibility
  Color get darkTeal => primaryTeal;

  AppUser? user;
  AppUser? doctor; // Current doctor info
  Map<String, dynamic>? animalData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.appointment.userId)
          .get();
      if (userDoc.exists) {
        user = AppUser.fromMap(userDoc.data()!, userDoc.id);
      }

      // Fetch current doctor (logged in) data
      final currentDoctorId = AuthService.currentUser?.uid;
      if (currentDoctorId != null) {
        final doctorDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentDoctorId)
            .get();
        if (doctorDoc.exists) {
          doctor = AppUser.fromMap(doctorDoc.data()!, doctorDoc.id);
        }
      }

      // Fetch animal data
      final animalSnapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where('userId', isEqualTo: widget.appointment.userId)
          .where('name', isEqualTo: widget.appointment.animalName)
          .get();

      if (animalSnapshot.docs.isNotEmpty) {
        animalData = animalSnapshot.docs.first.data();
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Some data could not be loaded: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _approveAppointment() async {
    try {
      // Update appointment status
      await _appointmentService.updateStatus(widget.appointment.id, 'approved');

      // Format appointment time
      final dateTime = widget.appointment.date.toDate();
      final formattedDate = "${_getDayName(dateTime.weekday)}, ${_getMonthName(dateTime.month)} ${dateTime.day}";
      final appointmentTimeStr = "$formattedDate at ${widget.appointment.time}";
      final bookedAt = widget.appointment.createdAt?.toDate().toLocal();
      final bookedOn = bookedAt == null
          ? 'Not recorded'
          : '${_formatTimelineDate(bookedAt)} at ${_formatClock(bookedAt)}';

      // Send notification with doctor's name
      await _notificationService.sendNotification(
        receiverId: widget.appointment.userId,
        title: 'Appointment Approved!',
        message: 'Dr. ${doctor?.name ?? "Your doctor"} has approved your appointment for ${animalData?['name'] ?? widget.appointment.animalName}.\nAppointment On: $appointmentTimeStr\nBooked On: $bookedOn',
        appointmentId: widget.appointment.id,
        type: 'appointment_approved',
      );

      // Navigate to chat
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              receiverId: widget.appointment.userId,
              receiverName: user!.name,
              receiverImage: user!.imageUrl,
              isOnline: true,
            ),
          ),
        );
      } else {
        Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment approved successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving appointment: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _declineAppointment() async {
    try {
      // Update appointment status
      await _appointmentService.updateStatus(widget.appointment.id, 'declined');

      // Format appointment time
      final dateTime = widget.appointment.date.toDate();
      final formattedDate = "${_getDayName(dateTime.weekday)}, ${_getMonthName(dateTime.month)} ${dateTime.day}";
      final appointmentTimeStr = "$formattedDate at ${widget.appointment.time}";
      final bookedAt = widget.appointment.createdAt?.toDate().toLocal();
      final bookedOn = bookedAt == null
          ? 'Not recorded'
          : '${_formatTimelineDate(bookedAt)} at ${_formatClock(bookedAt)}';

      // Send notification
      await _notificationService.sendNotification(
        receiverId: widget.appointment.userId,
        title: 'Appointment Declined',
        message: 'Dr. ${doctor?.name ?? "Your doctor"} has declined your appointment for ${animalData?['name'] ?? widget.appointment.animalName}.\nAppointment On: $appointmentTimeStr\nBooked On: $bookedOn',
        appointmentId: widget.appointment.id,
        type: 'appointment_declined',
      );

      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment declined successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error declining appointment: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: primaryTeal,
          title: const Text("Request Details"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Request Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 20),
            _sectionLabel("Owner Information"),
            _buildUserCard(),
            const SizedBox(height: 20),
            _sectionLabel("Animal Details"),
            _buildAnimalCard(),
            const SizedBox(height: 20),
            _sectionLabel("Appointment Information"),
            _buildAppointmentDetails(),
            const SizedBox(height: 20),
            _sectionLabel("Payment Information"),
            _buildPaymentScreenshotSection(),
            const SizedBox(height: 30),
            _buildActionButtons(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildStatusHeader() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: const Text("Requested", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildUserCard() {
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text("User data not available"),
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryTeal.withOpacity(0.2),
            backgroundImage: NetworkImage(user!.imageUrl!),
            child: null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(user!.role, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(userId: widget.appointment.userId),
                ),
              );
            },
            child: Text("View Profile", style: TextStyle(color: darkTeal, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCard() {
    if (animalData == null) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text("Animal data not available"),
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: lightGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryTeal.withOpacity(0.2),
            backgroundImage: animalData!['imageUrls'] != null && (animalData!['imageUrls'] as List).isNotEmpty
                ? NetworkImage(animalData!['imageUrls'][0])
                : null,
            child: (animalData!['imageUrls'] == null || (animalData!['imageUrls'] as List).isEmpty) ? Icon(Icons.pets, color: darkTeal) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${animalData!['name'] ?? 'Unknown'} (${animalData!['type'] ?? 'Animal'})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${animalData!['breed'] ?? 'Unknown Breed'} • ${animalData!['age'] ?? 'N/A'} Years", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetails() {
    final appointmentDate = widget.appointment.date.toDate().toLocal();
    final bookedAt = widget.appointment.createdAt?.toDate().toLocal();
    final appointmentOn =
        '${_formatTimelineDate(appointmentDate)}  •  ${widget.appointment.time.trim().isEmpty ? 'Time not provided' : widget.appointment.time.trim()}';
    final bookedOn = bookedAt == null
        ? 'Not recorded'
        : '${_formatTimelineDate(bookedAt)}  •  ${_formatClock(bookedAt)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _detailRow(
            Icons.calendar_today_outlined,
            'Appointment On',
            appointmentOn,
          ),
          const Divider(height: 30),
          _detailRow(
            Icons.schedule_send_outlined,
            'Booked On',
            bookedOn,
          ),
          const Divider(height: 30),
          _detailRow(Icons.description_outlined, "Reason for Visit", widget.appointment.problem),
          const Divider(height: 30),
          _detailRow(Icons.error_outline, "Additional Notes", "Please provide more details if needed"),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  String _formatTimelineDate(DateTime date) {
    return '${_getDayName(date.weekday)}, ${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _formatClock(DateTime date) {
    final hour24 = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final isPm = hour24 >= 12;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute ${isPm ? 'PM' : 'AM'}';
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 22),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentScreenshotSection() {
    // Validate URL
    final screenshotUrl = widget.appointment.paymentScreenshotUrl;
    final bool hasValidUrl = screenshotUrl != null && 
                              screenshotUrl.isNotEmpty && 
                              (screenshotUrl.startsWith('http://') || screenshotUrl.startsWith('https://'));
    
    print('[Doctor-Payment] Screenshot URL: $screenshotUrl');
    print('[Doctor-Payment] Is Valid: $hasValidUrl');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.grey, size: 22),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Amount', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${widget.appointment.paymentAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.call_to_action, color: Colors.grey, size: 22),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Consultation Type', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      widget.appointment.consultationType == 'online' ? 'Online Consultation' : 'Home Visit',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasValidUrl) ...[
            const Divider(height: 30),
            const Text(
              'Payment Screenshot',
              style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showFullScreenImage(widget.appointment.paymentScreenshotUrl!),
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryTeal.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.appointment.paymentScreenshotUrl!,
                        fit: BoxFit.cover,
                        headers: const {
                          'Cache-Control': 'no-cache',
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            print('[Doctor-Screenshot] Image loaded');
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: primaryTeal,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          final url = widget.appointment.paymentScreenshotUrl ?? 'null';
                          print('[Doctor-Screenshot] \u274c ERROR: $error');
                          print('[Doctor-Screenshot] URL: $url');
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 50, color: Colors.red[400]),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Failed to load screenshot',
                                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'URL: ${url.length > 35 ? url.substring(0, 35) + '...' : url}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 9),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '\u2022 Check storage permissions\n\u2022 Verify file exists\n\u2022 Check CORS policy',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 9),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'Tap to view',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
            ),
          ] else
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          screenshotUrl != null && screenshotUrl.isNotEmpty 
                            ? 'Invalid screenshot URL' 
                            : 'No payment screenshot provided',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (screenshotUrl != null && screenshotUrl.isNotEmpty && !hasValidUrl) ...[
                    const SizedBox(height: 8),
                    Text(
                      'URL must start with http:// or https://',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  headers: const {
                    'Cache-Control': 'no-cache',
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('[Doctor-FullScreen] Error: $error');
                    print('[Doctor-FullScreen] URL: $imageUrl');
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 60, color: Colors.white),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Check connection or try again',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: _approveAppointment,
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text("Accept Appointment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: darkTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton.icon(
            onPressed: _declineAppointment,
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            label: const Text("Decline Request", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
      ],
    );
  }
}