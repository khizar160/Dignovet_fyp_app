// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/model/appointment_model.dart';
// import 'package:flutter_application_1/services/Appointment%20Service/appointment_services.dart';
// import 'package:flutter_application_1/services/notification%20service/notification_service.dart';
// import 'package:flutter_application_1/view/User/ChatScreen.dart';

// class BookAppointmentPage extends StatefulWidget {
//   final String doctorId;
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
//   bool isBooked = false;
//   String appointmentId = '';

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
//         print('User not logged in');
//         setState(() {
//           isAnimalLoading = false;
//         });
//         return;
//       }
//       final userId = user.uid;
//       print('Fetching animals for userId: $userId');
//       final snapshot = await FirebaseFirestore.instance
//           .collection('animals')
//           .where('userId', isEqualTo: userId)
//           .get();

//       print('Snapshot docs length: ${snapshot.docs.length}');
//       if (snapshot.docs.isNotEmpty) {
//         // Sort by createdAt descending
//         final sortedDocs = snapshot.docs..sort((a, b) {
//           final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
//           final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
//           return bTime.compareTo(aTime);
//         });
//         final animalList = sortedDocs.map((doc) => doc.data()).toList();
//         setState(() {
//           animals = animalList;
//           selectedAnimal = animalList.first; // Select the latest by default
//           isAnimalLoading = false;
//         });
//       } else {
//         print('No animals found for user');
//         setState(() {
//           animals = [];
//           selectedAnimal = null;
//           isAnimalLoading = false;
//         });
//       }
//     } catch (e) {
//       print('Error fetching animals: $e');
//       setState(() {
//         animals = [];
//         selectedAnimal = null;
//         isAnimalLoading = false;
//       });
//     }
//   }

//   /// ----------------- BOOK APPOINTMENT FUNCTION -----------------
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

//     // Format date as Timestamp
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
//       final id =
//           await AppointmentService().createAppointment(appointment);
//       appointmentId = id;

//       // Send notification to doctor
//       await NotificationService().sendNotification(
//         receiverId: widget.doctorId,
//         title: 'New Appointment Request',
//         message:
//             'You have a new appointment request from a user for ${selectedAnimal!['name']}.',
//         appointmentId: id,
//         type: 'appointment_request',
//       );
//       print('Notification sent to doctor ${widget.doctorId} for appointment $id');

//       setState(() {
//         isLoading = false;
//         isBooked = true;
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

//   /// ----------------- BUILD UI -----------------
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
//             _buildActionButton(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButton() {
//     if (!isBooked) {
//       return SizedBox(
//         width: double.infinity,
//         height: 60,
//         child: ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: darkTeal,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//           ),
//           onPressed: bookAppointment,
//           child: isLoading
//               ? const CircularProgressIndicator(color: Colors.white)
//               : const Text(
//                   "Book Appointment Now",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//         ),
//       );
//     } else {
//       return StreamBuilder<DocumentSnapshot>(
//         stream: FirebaseFirestore.instance.collection('appointments').doc(appointmentId).snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const CircularProgressIndicator();
//           }
//           final data = snapshot.data!.data() as Map<String, dynamic>;
//           final status = data['status'] ?? 'pending';
//           if (status == 'approved') {
//             return SizedBox(
//               width: double.infinity,
//               height: 60,
//               child: ElevatedButton.icon(
//                 onPressed: () async {
//                   // Get doctor info
//                   final doctorDoc = await FirebaseFirestore.instance.collection('users').doc(widget.doctorId).get();
//                   if (doctorDoc.exists) {
//                     final doctor = doctorDoc.data()!;
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => ChatScreen(
//                           receiverId: widget.doctorId,
//                           receiverName: doctor['name'] ?? 'Doctor',
//                           receiverImage: doctor['imageUrl'] ?? '',
//                           isOnline: true,
//                         ),
//                       ),
//                     );
//                   }
//                 },
//                 icon: const Icon(Icons.chat, color: Colors.white),
//                 label: const Text("Chat with Doctor"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: darkTeal,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                 ),
//               ),
//             );
//           } else if (status == 'declined') {
//             return Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade100,
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: const Text(
//                 'Appointment Declined by Doctor',
//                 style: TextStyle(color: Colors.red, fontSize: 16),
//                 textAlign: TextAlign.center,
//               ),
//             );
//           } else {
//             return SizedBox(
//               width: double.infinity,
//               height: 60,
//               child: ElevatedButton(
//                 onPressed: null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.grey,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                 ),
//                 child: const Text(
//                   "Pending Approval",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             );
//           }
//         },
//       );
//     }
//   }

//   /// ----------------- WIDGETS -----------------
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
//                     const Text("No animal registered. Please register an animal first."),
//                     const SizedBox(height: 10),
//                     ElevatedButton(
//                       onPressed: () {
//                         // Navigate to register animal page
//                         Navigator.pushNamed(context, '/registerAnimal');
//                       },
//                       child: const Text("Register Animal"),
//                     ),
//                   ],
//                 )
//               : Column(
//                   children: [
//                     // Animal Selection Dropdown
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
//                     // Selected Animal Details
//                     if (selectedAnimal != null)
//                       Row(
//                         children: [
//                           CircleAvatar(
//                             radius: 30,
//                             backgroundImage: (selectedAnimal!['imageUrls'] as List<dynamic>?)?.isNotEmpty == true
//                                 ? NetworkImage(selectedAnimal!['imageUrls'][0])
//                                 : const NetworkImage('https://images.unsplash.com/photo-1552053831-71594a27632d?q=80&w=1000'),
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





import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/doctor_model.dart';
import '../../model/appointment_model.dart';
import '../../services/Appointment Service/appointment_services.dart';
import '../../services/notification service/notification_service.dart';
import '../../provider/language_provider.dart';
import '../User/ChatScreen.dart';

class BookAppointmentPage extends StatefulWidget {
  final DoctorProfile doctorProfile;

  const BookAppointmentPage({super.key, required this.doctorProfile});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final Color primaryTeal = const Color(0xFF80CBC4);
  final Color darkTeal = const Color(0xFF00796B);

  DateTime selectedDate = DateTime.now();
  String selectedSlot = "";
  bool isLoading = false;
  bool isBooked = false;
  String appointmentId = '';

  final TextEditingController problemController = TextEditingController();

  List<Map<String, dynamic>> animals = [];
  Map<String, dynamic>? selectedAnimal;
  bool isAnimalLoading = true;

  List<String> availableSlotsForSelectedDay = [];

  @override
  void initState() {
    super.initState();
    _fetchAnimals();
  }

  /// ------------------ FETCH USER ANIMALS ------------------
  Future<void> _fetchAnimals() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final snapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where('userId', isEqualTo: user.uid)
          .get();

      final animalList = snapshot.docs.map((e) => e.data()).toList();
      setState(() {
        animals = animalList;
        selectedAnimal = animalList.isNotEmpty ? animalList.first : null;
        isAnimalLoading = false;
      });
    } catch (e) {
      setState(() {
        animals = [];
        selectedAnimal = null;
        isAnimalLoading = false;
      });
    }
  }

  /// ------------------ GET AVAILABLE SLOTS FOR DATE ------------------
  void _updateSlotsForSelectedDate(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final weekdayName = _weekdayIntToString(weekday);

    setState(() {
      selectedDate = date;
      availableSlotsForSelectedDay =
          widget.doctorProfile.availableDays.contains(weekdayName)
              ? widget.doctorProfile.availableSlots
              : [];
      selectedSlot = ""; // reset slot on date change
    });
  }

  String _weekdayIntToString(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  /// ------------------ BOOK APPOINTMENT ------------------
  Future<void> bookAppointment() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    if (selectedAnimal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(languageProvider.translate('please_select_animal'))));
      return;
    }
    if (selectedSlot.isEmpty || problemController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(languageProvider.translate('please_select_slot_problem'))));
      return;
    }

    setState(() => isLoading = true);

    final userId = FirebaseAuth.instance.currentUser!.uid;

    final appointment = AppointmentModel(
      id: '',
      userId: userId,
      doctorId: widget.doctorProfile.id,
      animalName: selectedAnimal!['name'] ?? 'Unknown',
      date: Timestamp.fromDate(selectedDate),
      time: selectedSlot,
      problem: problemController.text,
      status: 'pending',
    );

    try {
      final id = await AppointmentService().createAppointment(appointment);
      appointmentId = id;

      // Send notification to doctor
      await NotificationService().sendNotification(
        receiverId: widget.doctorProfile.id,
        title: 'New Appointment Request',
        message:
            'You have a new appointment request for ${selectedAnimal!['name']}.',
        appointmentId: id,
        type: 'appointment_request',
      );

      setState(() {
        isLoading = false;
        isBooked = true;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Text(languageProvider.translate('request_sent_success')),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  /// ------------------ BUILD UI ------------------
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryTeal,
        title: Text(languageProvider.translate('book_appointment')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(languageProvider.translate('doctor'), languageProvider),
            _doctorCard(languageProvider),
            const SizedBox(height: 20),
            _sectionHeader(languageProvider.translate('animal_details'), languageProvider),
            _animalCard(languageProvider),
            const SizedBox(height: 20),
            _sectionHeader(languageProvider.translate('select_date'), languageProvider),
            _calendarWidget(),
            const SizedBox(height: 20),
            _sectionHeader(languageProvider.translate('available_slots'), languageProvider),
            _slotsWidget(languageProvider),
            const SizedBox(height: 20),
            _sectionHeader(languageProvider.translate('problem_description'), languageProvider),
            TextField(
              controller: problemController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: languageProvider.translate('briefly_describe_issue'),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildActionButton(languageProvider),
          ],
        ),
      ),
    );
  }

  /// ------------------ UI COMPONENTS ------------------
  Widget _sectionHeader(String title, LanguageProvider languageProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _doctorCard(LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryTeal),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(widget.doctorProfile.imageUrl),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.doctorProfile.id, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.doctorProfile.specialization),
              Text(widget.doctorProfile.clinicName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _animalCard(LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryTeal),
      ),
      child: isAnimalLoading
          ? const Center(child: CircularProgressIndicator())
          : animals.isEmpty
              ? Text(languageProvider.t('No animals registered.', 'کوئی جانور رجسٹرڈ نہیں۔'))
              : DropdownButtonFormField<Map<String, dynamic>>(
                  value: selectedAnimal,
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('select_animal'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: animals.map((animal) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: animal,
                      child: Text(animal['name'] ?? languageProvider.translate('unknown')),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAnimal = value;
                    });
                  },
                ),
    );
  }

  Widget _calendarWidget() {
    return CalendarDatePicker(
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      selectableDayPredicate: (date) {
        final weekday = _weekdayIntToString(date.weekday);
        return widget.doctorProfile.availableDays.contains(weekday);
      },
      onDateChanged: _updateSlotsForSelectedDate,
    );
  }

  Widget _slotsWidget(LanguageProvider languageProvider) {
    if (availableSlotsForSelectedDay.isEmpty) {
      return Text(languageProvider.t('No slots available for this day', 'اس دن کے لیے کوئی وقت دستیاب نہیں'));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: availableSlotsForSelectedDay.map((slot) {
        return ChoiceChip(
          label: Text(slot),
          selected: selectedSlot == slot,
          selectedColor: darkTeal,
          labelStyle: TextStyle(
            color: selectedSlot == slot ? Colors.white : Colors.black,
          ),
          onSelected: (_) => setState(() => selectedSlot = slot),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(LanguageProvider languageProvider) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkTeal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: bookAppointment,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                languageProvider.translate('book_appointment_now'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
