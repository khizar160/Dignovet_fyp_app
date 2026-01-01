// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/model/appointment_model.dart';
// import 'package:flutter_application_1/services/Appointment%20Service/appointment_services.dart';
// import 'package:flutter_application_1/services/notification%20service/notification_service.dart';
// import 'package:flutter_application_1/view/User/AppointmentRequest.dart';

// class BookAppointmentPage extends StatefulWidget {
//   final String doctorId; // Selected doctor ID
//   final String doctorName;
//   final String doctorImage;

//   const BookAppointmentPage({
//     super.key,
//     required this.doctorId,
//     required this.doctorName,
//     required this.doctorImage,
//   });

//   @override
//   State<BookAppointmentPage> createState() => _BookAppointmentPageState();
// }

// class _BookAppointmentPageState extends State<BookAppointmentPage> {
//   final Color primaryTeal = const Color(0xFF80CBC4);
//   final Color darkTeal = const Color(0xFF00796B);

//   DateTime selectedDate = DateTime.now();
//   String selectedSlot = "";
//   bool isLoading = false;
//   bool isPending = false;

//   final TextEditingController problemController = TextEditingController();

//   // Animal Details - list of animals
//   List<Map<String, dynamic>> animals = [];
//   Map<String, dynamic>? selectedAnimal;
//   bool isAnimalLoading = true;

//   final List<String> timeSlots = [
//     "09:00 AM",
//     "11:00 AM",
//     "02:00 PM",
//     "04:00 PM",
//     "06:00 PM"
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _fetchAnimals();
//   }

//   Future<void> _fetchAnimals() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         setState(() {
//           isAnimalLoading = false;
//         });
//         return;
//       }
//       final snapshot = await FirebaseFirestore.instance
//           .collection('animals')
//           .where('userId', isEqualTo: user.uid)
//           .get();

//       if (snapshot.docs.isNotEmpty) {
//         final sortedDocs = snapshot.docs..sort((a, b) {
//           final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
//           final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
//           return bTime.compareTo(aTime);
//         });

//         final animalList = sortedDocs.map((doc) => doc.data()).toList();
//         setState(() {
//           animals = animalList;
//           selectedAnimal = animalList.first;
//           isAnimalLoading = false;
//         });
//       } else {
//         setState(() {
//           animals = [];
//           selectedAnimal = null;
//           isAnimalLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         animals = [];
//         selectedAnimal = null;
//         isAnimalLoading = false;
//       });
//     }
//   }

//   //----------------- BOOK APPOINTMENT FUNCTION -----------------
//   Future<void> bookAppointment() async {
//     if (selectedAnimal == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please select an animal")),
//       );
//       return;
//     }
//     if (selectedSlot.isEmpty || problemController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please select slot & write problem")),
//       );
//       return;
//     }

//     setState(() => isLoading = true);

//     final userId = FirebaseAuth.instance.currentUser!.uid;

//     final dateTimestamp = Timestamp.fromDate(selectedDate);

//     final appointment = AppointmentModel(
//       id: '', // Firestore will generate
//       userId: userId,
//       doctorId: widget.doctorId,
//       animalName: selectedAnimal!['name'] ?? 'Unknown',
//       date: dateTimestamp,
//       time: selectedSlot,
//       problem: problemController.text,
//       status: 'pending',
//     );

//     try {
//       final appointmentId =
//           await AppointmentService().createAppointment(appointment);

//       await NotificationService().sendNotification(
//         receiverId: widget.doctorId,
//         title: 'New Appointment Request',
//         message:
//             'You have a new appointment request from a user for ${selectedAnimal!['name']}.',
//         appointmentId: appointmentId,
//         type: 'appointment_request',
//       );

//       setState(() {
//         isLoading = false;
//         isPending = true;
//       });

//       // Success popup
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const AlertDialog(
//           content: Text("Your request has been sent to the doctor"),
//         ),
//       );

//       Future.delayed(const Duration(seconds: 2), () {
//         Navigator.pop(context);
//       });
//     } catch (e) {
//       setState(() => isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")),
//       );
//     }
//   }

//   //----------------- BUILD UI -----------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: primaryTeal,
//         elevation: 0,
//         title: const Text(
//           "Book Appointment",
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _sectionHeader("Doctor"),
//             _doctorCard(),
//             const SizedBox(height: 20),
//             _sectionHeader("Animal Details"),
//             _animalCard(),
//             const SizedBox(height: 25),
//             _sectionHeader("Select Date"),
//             CalendarDatePicker(
//               initialDate: selectedDate,
//               firstDate: DateTime.now(),
//               lastDate: DateTime.now().add(const Duration(days: 30)),
//               onDateChanged: (date) => setState(() => selectedDate = date),
//             ),
//             const SizedBox(height: 15),
//             _sectionHeader("Available Slots"),
//             Wrap(
//               spacing: 10,
//               runSpacing: 10,
//               children: timeSlots.map((slot) {
//                 return ChoiceChip(
//                   label: Text(slot),
//                   selected: selectedSlot == slot,
//                   selectedColor: darkTeal,
//                   labelStyle: TextStyle(
//                     color: selectedSlot == slot ? Colors.white : Colors.black,
//                   ),
//                   onSelected: (_) => setState(() => selectedSlot = slot),
//                 );
//               }).toList(),
//             ),
//             const SizedBox(height: 25),
//             _sectionHeader("Problem Description"),
//             TextField(
//               controller: problemController,
//               maxLines: 4,
//               decoration: InputDecoration(
//                 hintText: "Briefly describe the issue",
//                 filled: true,
//                 fillColor: Colors.grey[100],
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 30),
//             SizedBox(
//               width: double.infinity,
//               height: 60,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: isPending ? Colors.grey : darkTeal,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                 ),
//                 onPressed: isPending || isLoading ? null : bookAppointment,
//                 child: isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : Text(
//                         isPending ? "Pending" : "Book Appointment Now",
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   //----------------- WIDGETS -----------------
//   Widget _sectionHeader(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _animalCard() {
//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: primaryTeal.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: primaryTeal),
//       ),
//       child: isAnimalLoading
//           ? const Center(child: CircularProgressIndicator())
//           : animals.isEmpty
//               ? Column(
//                   children: [
//                     const Text(
//                         "No animal registered. Please register an animal first."),
//                     const SizedBox(height: 10),
//                     ElevatedButton(
//                       onPressed: () {
//                         Navigator.pushNamed(context, '/registerAnimal');
//                       },
//                       child: const Text("Register Animal"),
//                     ),
//                   ],
//                 )
//               : Column(
//                   children: [
//                     DropdownButtonFormField<Map<String, dynamic>>(
//                       value: selectedAnimal,
//                       decoration: InputDecoration(
//                         labelText: 'Select Animal',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       items: animals.map((animal) {
//                         return DropdownMenuItem<Map<String, dynamic>>(
//                           value: animal,
//                           child: Text(animal['name'] ?? 'Unknown'),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           selectedAnimal = value;
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 15),
//                     if (selectedAnimal != null)
//                       Row(
//                         children: [
//                           CircleAvatar(
//                             radius: 30,
//                             backgroundImage: (selectedAnimal!['imageUrls']
//                                         as List<dynamic>?)
//                                     ?.isNotEmpty ==
//                                 true
//                                 ? NetworkImage(selectedAnimal!['imageUrls'][0])
//                                 : const NetworkImage(
//                                     'https://images.unsplash.com/photo-1552053831-71594a27632d'),
//                           ),
//                           const SizedBox(width: 15),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 selectedAnimal!['name'] ?? 'Unknown',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: darkTeal,
//                                 ),
//                               ),
//                               Text(selectedAnimal!['breed'] ?? ''),
//                               Text(
//                                 "Age: ${selectedAnimal!['age']?.toString() ?? ''}",
//                                 style: const TextStyle(fontSize: 12),
//                               ),
//                             ],
//                           )
//                         ],
//                       ),
//                   ],
//                 ),
//     );
//   }

//   Widget _doctorCard() {
//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: primaryTeal.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: primaryTeal),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 30,
//             backgroundImage: NetworkImage(widget.doctorImage),
//           ),
//           const SizedBox(width: 15),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 widget.doctorName,
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: darkTeal,
//                 ),
//               ),
//               const Text(
//                 "Veterinarian",
//                 style: TextStyle(fontSize: 14, color: Colors.black54),
//               ),
//             ],
//           )
//         ],
//       ),
//     );
//   }
// }
//
// //
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/model/appointment_model.dart';
// import 'package:flutter_application_1/model/app_user.dart';
// import 'package:flutter_application_1/services/Appointment%20Service/appointment_services.dart';
// import 'package:flutter_application_1/services/notification%20service/notification_service.dart';
// import 'package:intl/intl.dart';

// class BookAppointmentPage extends StatefulWidget {
//   final AppUser doctor;

//   const BookAppointmentPage({
//     super.key,
//     required this.doctor,
//   });

//   @override
//   State<BookAppointmentPage> createState() => _BookAppointmentPageState();
// }

// class _BookAppointmentPageState extends State<BookAppointmentPage> {
//   final Color primaryTeal = const Color(0xFF80CBC4);
//   final Color darkTeal = const Color(0xFF00796B);
//   final Color lightTeal = const Color(0xFFB2DFDB);

//   late DateTime selectedDate;
//   String selectedSlot = "";
//   bool isLoading = false;
//   bool isPending = false;

//   final TextEditingController problemController = TextEditingController();

//   List<Map<String, dynamic>> animals = [];
//   Map<String, dynamic>? selectedAnimal;
//   bool isAnimalLoading = true;

//   List<String> timeSlots = [];
//   List<String> availableDays = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadDoctorAvailability();
//     _fetchUserAnimals();
//   }

//   void _loadDoctorAvailability() {
//     availableDays = widget.doctor.availableDays ?? [];
    
//     // Find the first available date
//     selectedDate = _findFirstAvailableDate();
    
//     setState(() {
//       timeSlots = _getSlotsForDay(selectedDate);
//     });
//   }

//   DateTime _findFirstAvailableDate() {
//     DateTime checkDate = DateTime.now();
//     final maxDate = DateTime.now().add(const Duration(days: 30));
    
//     if (_isDayAvailable(checkDate)) {
//       return checkDate;
//     }
    
//     while (checkDate.isBefore(maxDate)) {
//       checkDate = checkDate.add(const Duration(days: 1));
//       if (_isDayAvailable(checkDate)) {
//         return checkDate;
//       }
//     }
    
//     return DateTime.now();
//   }

//   List<String> _getSlotsForDay(DateTime date) {
//     final weekday = _getWeekdayName(date.weekday);
    
//     if (!availableDays.contains(weekday)) {
//       return [];
//     }
    
//     return widget.doctor.availableSlots ?? [];
//   }

//   String _getWeekdayName(int weekday) {
//     switch (weekday) {
//       case DateTime.monday:
//         return "Mon";
//       case DateTime.tuesday:
//         return "Tue";
//       case DateTime.wednesday:
//         return "Wed";
//       case DateTime.thursday:
//         return "Thu";
//       case DateTime.friday:
//         return "Fri";
//       case DateTime.saturday:
//         return "Sat";
//       case DateTime.sunday:
//         return "Sun";
//       default:
//         return "";
//     }
//   }

//   bool _isDayAvailable(DateTime date) {
//     final weekday = _getWeekdayName(date.weekday);
//     return availableDays.contains(weekday);
//   }

//   Future<void> _fetchUserAnimals() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         setState(() => isAnimalLoading = false);
//         return;
//       }

//       final snapshot = await FirebaseFirestore.instance
//           .collection('animals')
//           .where('userId', isEqualTo: user.uid)
//           .get();

//       if (snapshot.docs.isNotEmpty) {
//         final animalList = snapshot.docs
//             .map((doc) => doc.data())
//             .toList()
//             .cast<Map<String, dynamic>>();
//         setState(() {
//           animals = animalList;
//           selectedAnimal = animalList.first;
//           isAnimalLoading = false;
//         });
//       } else {
//         setState(() {
//           animals = [];
//           selectedAnimal = null;
//           isAnimalLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         animals = [];
//         selectedAnimal = null;
//         isAnimalLoading = false;
//       });
//     }
//   }

//   Future<void> bookAppointment() async {
//     if (selectedAnimal == null) {
//       _showErrorDialog("Please select an animal");
//       return;
//     }

//     if (selectedSlot.isEmpty) {
//       _showErrorDialog("Please select a time slot");
//       return;
//     }

//     if (problemController.text.trim().isEmpty) {
//       _showErrorDialog("Please describe the problem");
//       return;
//     }

//     setState(() => isLoading = true);

//     final userId = FirebaseAuth.instance.currentUser!.uid;
//     final dateTimestamp = Timestamp.fromDate(selectedDate);

//     final appointment = AppointmentModel(
//       id: '',
//       userId: userId,
//       doctorId: widget.doctor.id,
//       animalName: selectedAnimal!['name'] ?? 'Unknown',
//       date: dateTimestamp,
//       time: selectedSlot,
//       problem: problemController.text.trim(),
//       status: 'pending',
//     );

//     try {
//       final appointmentId = await AppointmentService().createAppointment(appointment);

//       await NotificationService().sendNotification(
//         receiverId: widget.doctor.id,
//         title: 'New Appointment Request',
//         message: 'You have a new appointment request from a user for ${selectedAnimal!['name']}.',
//         appointmentId: appointmentId,
//         type: 'appointment_request',
//       );

//       setState(() {
//         isLoading = false;
//         isPending = true;
//       });

//       await Future.delayed(const Duration(milliseconds: 500));
      
//       if (mounted) {
//         _showSuccessDialog();
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//       _showErrorDialog("Failed to book appointment: $e");
//     }
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Row(
//           children: [
//             Icon(Icons.error_outline, color: Colors.red[700], size: 28),
//             const SizedBox(width: 10),
//             const Text("Error", style: TextStyle(fontWeight: FontWeight.bold)),
//           ],
//         ),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("OK"),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Row(
//           children: [
//             Icon(Icons.check_circle_outline, color: Colors.green[700], size: 28),
//             const SizedBox(width: 10),
//             const Text("Success", style: TextStyle(fontWeight: FontWeight.bold)),
//           ],
//         ),
//         content: const Text("Your appointment request has been sent to the doctor. You will be notified once approved."),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.pop(context);
//             },
//             child: const Text("OK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: lightTeal,
//       appBar: AppBar(
//         backgroundColor: darkTeal,
//         elevation: 0,
//         title: const Text(
//           "Book Appointment",
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _doctorCard(),
//             const SizedBox(height: 20),
//             _sectionHeader("Select Your Pet"),
//             _animalCard(),
//             const SizedBox(height: 25),
//             _sectionHeader("Select Date"),
//             const SizedBox(height: 10),
//             _buildCalendar(),
//             const SizedBox(height: 25),
//             _sectionHeader("Available Time Slots"),
//             const SizedBox(height: 10),
//             _buildTimeSlots(),
//             const SizedBox(height: 25),
//             _sectionHeader("Problem Description"),
//             const SizedBox(height: 10),
//             TextField(
//               controller: problemController,
//               maxLines: 4,
//               decoration: InputDecoration(
//                 hintText: "Describe your pet's symptoms or concerns...",
//                 filled: true,
//                 fillColor: Colors.white,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                   borderSide: BorderSide.none,
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                   borderSide: BorderSide(color: primaryTeal, width: 1),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15),
//                   borderSide: BorderSide(color: darkTeal, width: 2),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 30),
//             SizedBox(
//               width: double.infinity,
//               height: 60,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: isPending ? Colors.grey : darkTeal,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   elevation: 3,
//                 ),
//                 onPressed: isPending || isLoading ? null : bookAppointment,
//                 child: isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             isPending ? Icons.schedule : Icons.check_circle_outline,
//                             color: Colors.white,
//                             size: 24,
//                           ),
//                           const SizedBox(width: 10),
//                           Text(
//                             isPending ? "Request Pending" : "Confirm Booking",
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _sectionHeader(String title) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 18,
//         fontWeight: FontWeight.bold,
//         color: darkTeal,
//       ),
//     );
//   }

//   Widget _doctorCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 15,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: primaryTeal, width: 3),
//             ),
//             child: CircleAvatar(
//               radius: 40,
//               backgroundColor: lightTeal.withOpacity(0.3),
//               backgroundImage: widget.doctor.imageUrl.isNotEmpty
//                   ? NetworkImage(widget.doctor.imageUrl)
//                   : null,
//               child: widget.doctor.imageUrl.isEmpty
//                   ? Icon(Icons.person, color: darkTeal, size: 40)
//                   : null,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.doctor.name,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   widget.doctor.specialization ?? 'Veterinarian',
//                   style: TextStyle(
//                     fontSize: 15,
//                     color: Colors.grey[700],
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
//                     const SizedBox(width: 4),
//                     Text(
//                       '${widget.doctor.experience ?? 0} Years Experience',
//                       style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
//                     const SizedBox(width: 4),
//                     Expanded(
//                       child: Text(
//                         widget.doctor.clinicName ?? 'Clinic',
//                         style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _animalCard() {
//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: isAnimalLoading
//           ? const Center(child: CircularProgressIndicator())
//           : animals.isEmpty
//               ? Column(
//                   children: [
//                     Icon(Icons.pets, size: 50, color: Colors.grey[400]),
//                     const SizedBox(height: 10),
//                     const Text(
//                       "No pets registered",
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                     ),
//                     const SizedBox(height: 5),
//                     const Text(
//                       "Please register your pet first to book an appointment",
//                       textAlign: TextAlign.center,
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                     const SizedBox(height: 15),
//                     ElevatedButton.icon(
//                       onPressed: () {
//                         Navigator.pushNamed(context, '/registerAnimal');
//                       },
//                       icon: const Icon(Icons.add),
//                       label: const Text("Register Pet"),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: darkTeal,
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ],
//                 )
//               : Column(
//                   children: [
//                     DropdownButtonFormField<Map<String, dynamic>>(
//                       value: selectedAnimal,
//                       decoration: InputDecoration(
//                         labelText: 'Select Pet',
//                         prefixIcon: Icon(Icons.pets, color: darkTeal),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: primaryTeal),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: darkTeal, width: 2),
//                         ),
//                       ),
//                       items: animals.map((animal) {
//                         return DropdownMenuItem<Map<String, dynamic>>(
//                           value: animal,
//                           child: Text(animal['name'] ?? 'Unknown'),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           selectedAnimal = value;
//                         });
//                       },
//                     ),
//                     if (selectedAnimal != null) ...[
//                       const SizedBox(height: 15),
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: lightTeal.withOpacity(0.3),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           children: [
//                             CircleAvatar(
//                               radius: 30,
//                               backgroundImage: (selectedAnimal!['imageUrls'] as List<dynamic>?)?.isNotEmpty == true
//                                   ? NetworkImage(selectedAnimal!['imageUrls'][0])
//                                   : const NetworkImage('https://images.unsplash.com/photo-1552053831-71594a27632d'),
//                             ),
//                             const SizedBox(width: 15),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     selectedAnimal!['name'] ?? 'Unknown',
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.bold,
//                                       color: darkTeal,
//                                     ),
//                                   ),
//                                   Text(
//                                     '${selectedAnimal!['breed'] ?? 'Unknown'} • ${selectedAnimal!['age']?.toString() ?? '0'} years',
//                                     style: const TextStyle(fontSize: 14, color: Colors.grey),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//     );
//   }

//   Widget _buildCalendar() {
//     if (availableDays.isEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: Colors.red[200]!),
//         ),
//         child: Row(
//           children: [
//             Icon(Icons.error_outline, color: Colors.red[700]),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 "Doctor has no available days set. Please contact support.",
//                 style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.w500),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: CalendarDatePicker(
//         initialDate: selectedDate,
//         firstDate: DateTime.now(),
//         lastDate: DateTime.now().add(const Duration(days: 30)),
//         selectableDayPredicate: (DateTime date) {
//           return _isDayAvailable(date);
//         },
//         onDateChanged: (date) {
//           final slots = _getSlotsForDay(date);
//           if (slots.isEmpty) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: const Text("Doctor is not available on this day"),
//                 backgroundColor: Colors.red[700],
//                 behavior: SnackBarBehavior.floating,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               ),
//             );
//             return;
//           }
//           setState(() {
//             selectedDate = date;
//             selectedSlot = "";
//             timeSlots = slots;
//           });
//         },
//       ),
//     );
//   }

//   Widget _buildTimeSlots() {
//     if (timeSlots.isEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(15),
//           border: Border.all(color: Colors.orange[200]!),
//         ),
//         child: Row(
//           children: [
//             Icon(Icons.info_outline, color: Colors.orange[700]),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 "Doctor is not available on ${DateFormat('EEEE, MMM dd').format(selectedDate)}. Please select another date.",
//                 style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.w500),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Wrap(
//         spacing: 10,
//         runSpacing: 10,
//         children: timeSlots.map((slot) {
//           final isSelected = selectedSlot == slot;
//           return InkWell(
//             onTap: () => setState(() => selectedSlot = slot),
//             borderRadius: BorderRadius.circular(12),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//               decoration: BoxDecoration(
//                 color: isSelected ? darkTeal : Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: isSelected ? darkTeal : primaryTeal,
//                   width: 2,
//                 ),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.access_time,
//                     size: 18,
//                     color: isSelected ? Colors.white : darkTeal,
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     slot,
//                     style: TextStyle(
//                       color: isSelected ? Colors.white : darkTeal,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 15,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/model/app_user.dart';
import 'package:flutter_application_1/services/Appointment%20Service/appointment_services.dart';
import 'package:flutter_application_1/services/notification%20service/notification_service.dart';
import 'package:intl/intl.dart';
import '../../provider/language_provider.dart';

class BookAppointmentPage extends StatefulWidget {
  final AppUser doctor;

  const BookAppointmentPage({
    super.key,
    required this.doctor,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  // Your color scheme
  final Color primaryDark = const Color(0xFF00796B);
  final Color primaryMedium = const Color(0xFF4DB6AC);
  final Color primaryLight = const Color(0xFF80CBC4);
  final Color darkText = const Color(0xFF2C3E50);

  late DateTime selectedDate;
  String selectedSlot = "";
  bool isLoading = false;
  bool isPending = false;

  final TextEditingController problemController = TextEditingController();

  List<Map<String, dynamic>> animals = [];
  Map<String, dynamic>? selectedAnimal;
  bool isAnimalLoading = true;

  List<String> timeSlots = [];
  List<String> availableDays = [];

  @override
  void initState() {
    super.initState();
    _loadDoctorAvailability();
    _fetchUserAnimals();
  }

  void _loadDoctorAvailability() {
    availableDays = widget.doctor.availableDays ?? [];
    selectedDate = _findFirstAvailableDate();
    setState(() {
      timeSlots = _getSlotsForDay(selectedDate);
    });
  }

  DateTime _findFirstAvailableDate() {
    DateTime checkDate = DateTime.now();
    final maxDate = DateTime.now().add(const Duration(days: 30));
    
    if (_isDayAvailable(checkDate)) {
      return checkDate;
    }
    
    while (checkDate.isBefore(maxDate)) {
      checkDate = checkDate.add(const Duration(days: 1));
      if (_isDayAvailable(checkDate)) {
        return checkDate;
      }
    }
    
    return DateTime.now();
  }

  List<String> _getSlotsForDay(DateTime date) {
    final weekday = _getWeekdayName(date.weekday);
    
    if (!availableDays.contains(weekday)) {
      return [];
    }
    
    return widget.doctor.availableSlots ?? [];
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "Mon";
      case DateTime.tuesday:
        return "Tue";
      case DateTime.wednesday:
        return "Wed";
      case DateTime.thursday:
        return "Thu";
      case DateTime.friday:
        return "Fri";
      case DateTime.saturday:
        return "Sat";
      case DateTime.sunday:
        return "Sun";
      default:
        return "";
    }
  }

  bool _isDayAvailable(DateTime date) {
    final weekday = _getWeekdayName(date.weekday);
    return availableDays.contains(weekday);
  }

  Future<void> _fetchUserAnimals() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => isAnimalLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final animalList = snapshot.docs
            .map((doc) => doc.data())
            .toList()
            .cast<Map<String, dynamic>>();
        setState(() {
          animals = animalList;
          selectedAnimal = animalList.first;
          isAnimalLoading = false;
        });
      } else {
        setState(() {
          animals = [];
          selectedAnimal = null;
          isAnimalLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        animals = [];
        selectedAnimal = null;
        isAnimalLoading = false;
      });
    }
  }

  Future<void> bookAppointment(LanguageProvider languageProvider) async {
    if (selectedAnimal == null) {
      _showErrorDialog(languageProvider.translate('please_select_animal'), languageProvider);
      return;
    }

    if (selectedSlot.isEmpty) {
      _showErrorDialog(languageProvider.t('Please select a time slot', 'براہ کرم وقت کا سلاٹ منتخب کریں'), languageProvider);
      return;
    }

    if (problemController.text.trim().isEmpty) {
      _showErrorDialog(languageProvider.t('Please describe the problem', 'براہ کرم مسئلہ بیان کریں'), languageProvider);
      return;
    }

    setState(() => isLoading = true);

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final dateTimestamp = Timestamp.fromDate(selectedDate);

    final appointment = AppointmentModel(
      id: '',
      userId: userId,
      doctorId: widget.doctor.id,
      animalName: selectedAnimal!['name'] ?? languageProvider.translate('unknown'),
      date: dateTimestamp,
      time: selectedSlot,
      problem: problemController.text.trim(),
      status: 'pending',
    );

    try {
      final appointmentId = await AppointmentService().createAppointment(appointment);

      await NotificationService().sendNotification(
        receiverId: widget.doctor.id,
        title: languageProvider.t('New Appointment Request', 'نئی ملاقات کی درخواست'),
        message: languageProvider.t('You have a new appointment request from a user for ${selectedAnimal!['name']}.', 'آپ کو ${selectedAnimal!['name']} کے لیے صارف سے نئی ملاقات کی درخواست ملی ہے۔'),
        appointmentId: appointmentId,
        type: 'appointment_request',
      );

      setState(() {
        isLoading = false;
        isPending = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        _showSuccessDialog(languageProvider);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog(languageProvider.t('Failed to book appointment', 'ملاقات بک کرنے میں ناکامی') + ": $e", languageProvider);
    }
  }

  void _showErrorDialog(String message, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 28),
            const SizedBox(width: 10),
            Text(languageProvider.translate('error'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: primaryDark),
            child: Text(languageProvider.translate('ok'), style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(LanguageProvider languageProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green[700], size: 28),
            const SizedBox(width: 10),
            Text(languageProvider.translate('success'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(languageProvider.translate('request_sent_success')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: primaryDark),
            child: Text(languageProvider.translate('ok'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryDark,
              primaryMedium,
              primaryLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(languageProvider),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _doctorCard(languageProvider),
                        const SizedBox(height: 24),
                        _sectionHeader(languageProvider.t('Select Your Pet', 'اپنا پالتو جانور منتخب کریں')),
                        const SizedBox(height: 12),
                        _animalCard(languageProvider),
                        const SizedBox(height: 24),
                        _sectionHeader(languageProvider.translate('select_date')),
                        const SizedBox(height: 12),
                        _buildCalendar(languageProvider),
                        const SizedBox(height: 24),
                        _sectionHeader(languageProvider.translate('available_slots')),
                        const SizedBox(height: 12),
                        _buildTimeSlots(languageProvider),
                        const SizedBox(height: 24),
                        _sectionHeader(languageProvider.translate('problem_description')),
                        const SizedBox(height: 12),
                        _buildProblemField(languageProvider),
                        const SizedBox(height: 30),
                        _buildBookButton(languageProvider),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                languageProvider.translate('book_appointment'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: darkText,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _doctorCard(LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryDark.withOpacity(0.1),
            primaryMedium.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryDark.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  primaryMedium.withOpacity(0.3),
                  primaryLight.withOpacity(0.2)
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryDark.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.transparent,
              backgroundImage: widget.doctor.imageUrl.isNotEmpty
                  ? NetworkImage(widget.doctor.imageUrl)
                  : null,
              child: widget.doctor.imageUrl.isEmpty
                  ? Icon(Icons.person, color: primaryDark, size: 40)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.doctor.specialization ?? languageProvider.translate('veterinarian'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.work_outline, size: 14, color: primaryDark),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.doctor.experience ?? 0} ${languageProvider.t('Years Exp.', 'سال تجربہ')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.doctor.clinicName ?? languageProvider.t('Clinic', 'کلینک'),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _animalCard(LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryLight.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isAnimalLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryDark),
              ),
            )
          : animals.isEmpty
              ? Column(
                  children: [
                    Icon(Icons.pets, size: 50, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    Text(
                      languageProvider.t('No pets registered', 'کوئی پالتو جانور رجسٹرڈ نہیں'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      languageProvider.translate('no_animal_registered'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [primaryDark, primaryMedium],
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/registerAnimal');
                        },
                        icon: const Icon(Icons.add),
                        label: Text(languageProvider.translate('register_animal_btn')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedAnimal,
                      decoration: InputDecoration(
                        labelText: 'Select Pet',
                        labelStyle: TextStyle(color: primaryDark),
                        prefixIcon: Icon(Icons.pets, color: primaryDark),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryDark, width: 2),
                        ),
                      ),
                      items: animals.map((animal) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: animal,
                          child: Text(animal['name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAnimal = value;
                        });
                      },
                    ),
                    if (selectedAnimal != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryDark.withOpacity(0.05),
                              primaryLight.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryMedium,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundImage: (selectedAnimal!['imageUrls'] as List<dynamic>?)?.isNotEmpty == true
                                    ? NetworkImage(selectedAnimal!['imageUrls'][0])
                                    : const NetworkImage('https://images.unsplash.com/photo-1552053831-71594a27632d'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedAnimal!['name'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: darkText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${selectedAnimal!['breed'] ?? 'Unknown'} • ${selectedAnimal!['age']?.toString() ?? '0'} years',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _buildCalendar(LanguageProvider languageProvider) {
    if (availableDays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                languageProvider.t("Doctor has no available days set. Please contact support.", "ڈاکٹر کے پاس کوئی دستیاب دن مقرر نہیں ہیں۔ براہ کرم سپورٹ سے رابطہ کریں۔"),
                style: TextStyle(
                  color: Colors.red[900],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryLight.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CalendarDatePicker(
        initialDate: selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)),
        selectableDayPredicate: (DateTime date) {
          return _isDayAvailable(date);
        },
        onDateChanged: (date) {
          final slots = _getSlotsForDay(date);
          if (slots.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(languageProvider.t("Doctor is not available on this day", "ڈاکٹر اس دن دستیاب نہیں ہے")),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            return;
          }
          setState(() {
            selectedDate = date;
            selectedSlot = "";
            timeSlots = slots;
          });
        },
      ),
    );
  }

  Widget _buildTimeSlots(LanguageProvider languageProvider) {
    if (timeSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                languageProvider.t("Doctor is not available on ${DateFormat('EEEE, MMM dd').format(selectedDate)}. Please select another date.", "ڈاکٹر ${DateFormat('EEEE, MMM dd').format(selectedDate)} کو دستیاب نہیں ہے۔ براہ کرم کوئی اور تاریخ منتخب کریں۔"),
                style: TextStyle(
                  color: Colors.orange[900],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryLight.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: timeSlots.map((slot) {
          final isSelected = selectedSlot == slot;
          return InkWell(
            onTap: () => setState(() => selectedSlot = slot),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [primaryDark, primaryMedium])
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.transparent : primaryDark.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryDark.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: isSelected ? Colors.white : primaryDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    slot,
                    style: TextStyle(
                      color: isSelected ? Colors.white : primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProblemField(LanguageProvider languageProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryLight.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: problemController,
        maxLines: 4,
        style: TextStyle(color: darkText, fontSize: 14),
        decoration: InputDecoration(
          hintText: languageProvider.translate('briefly_describe_issue'),
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryDark, width: 2),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildBookButton(LanguageProvider languageProvider) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isPending || isLoading
            ? null
            : LinearGradient(
                colors: [primaryDark, primaryMedium],
              ),
        color: isPending || isLoading ? Colors.grey : null,
        boxShadow: isPending || isLoading
            ? []
            : [
                BoxShadow(
                  color: primaryDark.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: isPending || isLoading ? null : () => bookAppointment(languageProvider),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPending ? Icons.schedule : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isPending ? languageProvider.t('Request Pending', 'درخواست زیر التواء') : languageProvider.t('Confirm Booking', 'بکنگ کی تصدیق کریں'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}