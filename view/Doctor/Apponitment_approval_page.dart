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

  // DignoVet Theme Colors
  final Color primaryTeal = const Color(0xFF80CBC4);
  final Color darkTeal = const Color(0xFF00796B);
  final Color lightGrey = const Color(0xFFF5F5F5);

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

      // Send notification with doctor's name
      await _notificationService.sendNotification(
        receiverId: widget.appointment.userId,
        title: 'Appointment Approved!',
        message: 'Dr. ${doctor?.name ?? "Your doctor"} has approved your appointment for ${animalData?['name'] ?? widget.appointment.animalName} on $appointmentTimeStr.',
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

      // Send notification
      await _notificationService.sendNotification(
        receiverId: widget.appointment.userId,
        title: 'Appointment Declined',
        message: 'Dr. ${doctor?.name ?? "Your doctor"} has declined your appointment for ${animalData?['name'] ?? widget.appointment.animalName} scheduled on $appointmentTimeStr.',
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
            backgroundImage: user!.imageUrl != null ? NetworkImage(user!.imageUrl!) : null,
            child: user!.imageUrl == null ? Icon(Icons.person, color: darkTeal) : null,
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
    final dateTime = widget.appointment.date.toDate();
    final formattedDate = "${_getDayName(dateTime.weekday)}, ${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year}";

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
          _detailRow(Icons.calendar_today_outlined, "Date & Time", "$formattedDate\n${widget.appointment.time}"),
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