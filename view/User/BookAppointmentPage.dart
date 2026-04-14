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
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/doctor_model.dart';
import '../../model/app_user.dart';
import '../../model/appointment_model.dart';
import '../../services/Appointment Service/appointment_services.dart';
import '../../services/notification service/notification_service.dart';
import '../../provider/language_provider.dart';

class BookAppointmentPage extends StatefulWidget {
  final AppUser doctor;

  const BookAppointmentPage({super.key, required this.doctor});

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
  
  // Doctor rating variables
  double doctorRating = 0.0;
  int ratingCount = 0;

  List<String> availableSlotsForSelectedDay = [];
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Get doctor data as DoctorProfile for consistency
  DoctorProfile get doctorProfile => DoctorProfile(
    id: widget.doctor.id,
    specialization: widget.doctor.specialization ?? 'General',
    experience: widget.doctor.experience ?? 0,
    clinicName: widget.doctor.clinicName ?? 'Clinic',
    clinicAddress: widget.doctor.clinicAddress ?? 'Address',
    latitude: widget.doctor.latitude,
    longitude: widget.doctor.longitude,
    about: widget.doctor.about ?? '',
    availableDays: widget.doctor.availableDays ?? [],
    availableSlots: widget.doctor.availableSlots ?? [],
    imageUrl: widget.doctor.imageUrl,
  );

  @override
  void initState() {
    super.initState();
    _fetchAnimals();
    _initializeMap();
    _updateSlotsForSelectedDate(selectedDate); // Initialize slots for today
    _fetchDoctorRating();  // Fetch doctor's average rating
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

  /// ------------------ FETCH DOCTOR RATING ------------------
  Future<void> _fetchDoctorRating() async {
    try {
      // Query all ratings where doctorId matches
      final snapshot = await FirebaseFirestore.instance
          .collection('consultation_ratings')
          .where('doctorId', isEqualTo: widget.doctor.id)
          .get();

      if (snapshot.docs.isNotEmpty) {
        double totalRating = 0;
        int count = 0;
        
        for (var doc in snapshot.docs) {
          final rating = doc['ratingValue'] as num?;
          if (rating != null) {
            totalRating += rating.toDouble();
            count++;
          }
        }
        
        if (count > 0) {
          setState(() {
            doctorRating = totalRating / count;
            ratingCount = count;
          });
          print('[BookAppointmentPage] Doctor ${widget.doctor.id} rating: $doctorRating ($count ratings)');
        }
      }
    } catch (e) {
      print('Error fetching doctor rating: $e');
    }
  }

  /// ------------------ INITIALIZE MAP ------------------
  void _initializeMap() {
    final doctor = doctorProfile;
    if (doctor.latitude != null && doctor.longitude != null) {
      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('clinic_location'),
            position: LatLng(
              doctor.latitude!,
              doctor.longitude!,
            ),
            infoWindow: InfoWindow(
              title: doctor.clinicName,
              snippet: doctor.clinicAddress,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      });
    }
  }

  /// ------------------ OPEN IN GOOGLE MAPS ------------------
  Future<void> _openInGoogleMaps() async {
    final doctor = doctorProfile;
    if (doctor.latitude == null || doctor.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    final lat = doctor.latitude;
    final lng = doctor.longitude;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  /// ------------------ GET AVAILABLE SLOTS FOR DATE ------------------
  void _updateSlotsForSelectedDate(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final weekdayName = _weekdayIntToString(weekday);
    final doctor = doctorProfile;

    setState(() {
      selectedDate = date;
      availableSlotsForSelectedDay =
          doctor.availableDays.contains(weekdayName)
              ? doctor.availableSlots
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

    final doctor = doctorProfile;
    final appointment = AppointmentModel(
      id: '',
      userId: userId,
      doctorId: doctor.id,
      animalName: selectedAnimal!['name'] ?? 'Unknown',
      date: Timestamp.fromDate(selectedDate),
      time: selectedSlot,
      problem: problemController.text,
      status: 'pending',
      paymentStatus: 'pending', // Required by Firestore rules
      paymentAmount: 0.0, // Default payment amount
      consultationType: 'online', // Default consultation type
      createdAt: Timestamp.now(), // Required by Firestore rules
      chatStatus: 'disabled', // Users can't chat until doctor approves
    );

    try {
      final id = await AppointmentService().createAppointment(appointment);
      appointmentId = id;

      // Send notification to doctor
      await NotificationService().sendNotification(
        receiverId: doctor.id,
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
            
            // Clinic Location Section with Google Maps
            if (doctorProfile.latitude != null && doctorProfile.longitude != null) ...[
              _sectionHeader(languageProvider.t('Clinic Location', 'کلینک کا مقام'), languageProvider),
              _clinicLocationCard(languageProvider),
              const SizedBox(height: 20),
            ],
            
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
    final doctor = doctorProfile;
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
            backgroundImage: doctor.imageUrl.isNotEmpty
                ? NetworkImage(doctor.imageUrl)
                : null,
            child: doctor.imageUrl.isEmpty
                ? Icon(Icons.person, size: 35, color: darkTeal)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.specialization,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_hospital, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doctor.clinicName,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doctor.clinicAddress,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Doctor rating display
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Show stars
                    ...List.generate(5, (index) {
                      final filledStars = doctorRating.toInt();
                      final isHalfStar = doctorRating - filledStars > 0.5 && index == filledStars;
                      
                      return Icon(
                        index < filledStars
                            ? Icons.star
                            : isHalfStar
                                ? Icons.star_half
                                : Icons.star_border,
                        color: Colors.amber,
                        size: 14,
                      );
                    }),
                    const SizedBox(width: 6),
                    // Rating number and count
                    Text(
                      doctorRating > 0
                          ? '${doctorRating.toStringAsFixed(1)} ($ratingCount)'
                          : 'No ratings',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
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

  Widget _clinicLocationCard(LanguageProvider languageProvider) {
    final doctor = doctorProfile;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryTeal.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Map Container with better styling
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                SizedBox(
                  height: 280,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        doctor.latitude!,
                        doctor.longitude!,
                      ),
                      zoom: 15,
                    ),
                    markers: _markers,
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    zoomControlsEnabled: true,
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    mapType: MapType.normal,
                    compassEnabled: true,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                  ),
                ),
                // Overlay badge showing clinic name
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doctor.clinicName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Location Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.location_city, color: darkTeal, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.t('Clinic Name', 'کلینک کا نام'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doctor.clinicName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.place, color: darkTeal, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.t('Address', 'پتہ'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doctor.clinicAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openInGoogleMaps,
                        icon: const Icon(Icons.directions, size: 20),
                        label: Text(
                          languageProvider.t('Get Directions', 'راستہ دیکھیں'),
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Show in map with full screen
                          if (_mapController != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(
                                    doctor.latitude!,
                                    doctor.longitude!,
                                  ),
                                  zoom: 17,
                                  tilt: 45,
                                ),
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.zoom_in, color: darkTeal, size: 20),
                        label: Text(
                          languageProvider.t('View Map', 'نقشہ دیکھیں'),
                          style: TextStyle(color: darkTeal, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: darkTeal, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
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
                  initialValue: selectedAnimal,
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
    final doctor = doctorProfile;
    return CalendarDatePicker(
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      selectableDayPredicate: (date) {
        final weekday = _weekdayIntToString(date.weekday);
        return doctor.availableDays.contains(weekday);
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
        return FutureBuilder<Map<String, dynamic>>(
          // Add key with date to force rebuild when date changes
          key: ValueKey('${slot}_${selectedDate.toString()}'),
          future: _getSlotStatus(slot),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Chip(label: Text('Loading...'));
            }

            final slotStatus = snapshot.data!;
            final isBooked = slotStatus['isBooked'] as bool;
            final isTimePassed = slotStatus['isTimePassed'] as bool;
            final canSelect = !isBooked && !isTimePassed;
            
            late String statusLabel;
            late Color statusColor;
            late IconData statusIcon;

            if (isTimePassed) {
              statusLabel = 'وقت ختم ہو چکا';
              statusColor = Colors.red;
              statusIcon = Icons.schedule;
            } else if (isBooked) {
              statusLabel = 'بک شدہ';
              statusColor = Colors.orange;
              statusIcon = Icons.block;
            } else {
              statusLabel = slot;
              statusColor = darkTeal;
              statusIcon = Icons.check;
            }

            return Tooltip(
              message: isTimePassed ? 'This slot time has passed' : 
                       isBooked ? 'This slot is already booked' : 
                       'Available slot',
              child: ChoiceChip(
                label: isBooked || isTimePassed
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14),
                          const SizedBox(width: 4),
                          Text(statusLabel, style: const TextStyle(fontSize: 11)),
                        ],
                      )
                    : Text(slot),
                selected: selectedSlot == slot && canSelect,
                selectedColor: canSelect ? darkTeal : Colors.grey.shade300,
                backgroundColor: isTimePassed
                    ? Colors.red.shade50
                    : isBooked
                        ? Colors.orange.shade50
                        : Colors.white,
                labelStyle: TextStyle(
                  color: canSelect && selectedSlot == slot
                      ? Colors.white
                      : isTimePassed
                          ? Colors.red
                          : isBooked
                              ? Colors.orange
                              : Colors.black,
                  fontWeight: selectedSlot == slot ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: canSelect ? (_) => setState(() => selectedSlot = slot) : null,
              ),
            );
          },
        );
      }).toList(),
    );
  }

  /// Check if a slot is booked or if time has passed
  Future<Map<String, dynamic>> _getSlotStatus(String slot) async {
    try {
      // Check if time has passed (only for today)
      final now = DateTime.now();
      final isToday = selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day == now.day;

      bool isTimePassed = false;
      if (isToday) {
        try {
          // Try parsing as range first (14:30-15:00)
          var timeString = slot;
          final slotParts = slot.split('-');
          
          if (slotParts.length == 2) {
            // Range format: "14:30-15:00"
            timeString = slotParts[0].trim();
          }
          
          // Parse time - can be "14:30" or "09:00 AM"
          var timeParts = timeString.split(':');
          if (timeParts.length == 2) {
            var hour = int.parse(timeParts[0]);
            final minuteStr = timeParts[1].replaceAll('AM', '').replaceAll('PM', '').trim();
            final minute = int.parse(minuteStr);
            
            // Convert to 24-hour format if AM/PM exists
            if (timeString.contains('PM') && hour != 12) {
              hour += 12;
            } else if (timeString.contains('AM') && hour == 12) {
              hour = 0;
            }
            
            final slotTime = DateTime(now.year, now.month, now.day, hour, minute);
            isTimePassed = now.isAfter(slotTime);
          }
        } catch (e) {
          print('[BookAppointmentPage] Error parsing time: $e');
        }
      }

      // Check if slot is already booked
      final doctor = doctorProfile;
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctor.id)
          .where('time', isEqualTo: slot)
          .where('date', isEqualTo: Timestamp.fromDate(DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
          )))
          .get();

      // Check if any non-declined appointments exist
      bool isBooked = false;
      for (var doc in snapshot.docs) {
        final status = doc['status'] as String? ?? '';
        if (status.toLowerCase() != 'declined' && status.toLowerCase() != 'cancelled') {
          isBooked = true;
          break;
        }
      }

      return {
        'isBooked': isBooked,
        'isTimePassed': isTimePassed,
      };
    } catch (e) {
      print('[BookAppointmentPage] Error in _getSlotStatus: $e');
      return {
        'isBooked': false,
        'isTimePassed': false,
      };
    }
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
