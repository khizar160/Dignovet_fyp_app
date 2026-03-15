import 'dart:io';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/model/app_user.dart';
import 'package:flutter_application_1/model/payment_model.dart';
import 'package:flutter_application_1/services/Appointment%20Service/appointment_services.dart';
import 'package:flutter_application_1/services/payment_service/stripe_payment_service.dart';
import 'package:flutter_application_1/services/notification%20service/notification_service.dart';
import 'package:intl/intl.dart';
import '../../provider/language_provider.dart';
import '../../config/payment_config.dart';
import '../../widgets/payment_method_selector.dart';

// FIRST VERSION - Simple BookAppointmentPage (Commented Out)
// This version uses doctorId, doctorName, doctorImage parameters
/*
class BookAppointmentPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String doctorImage;

  const BookAppointmentPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.doctorImage,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final Color primaryTeal = const Color(0xFF80CBC4);
  final Color darkTeal = const Color(0xFF00796B);

  // Controllers and State Variables
  DateTime selectedDate = DateTime.now();
  String selectedSlot = "";
  String consultationType = "online"; // 'online' or 'home_visit'
  bool isLoading = false;
  bool isPending = false;

  final TextEditingController problemController = TextEditingController();
  final StripePaymentService _paymentService = StripePaymentService();
  final AppointmentService _appointmentService = AppointmentService();
  final NotificationService _notificationService = NotificationService();

  // Animal Details
  List<Map<String, dynamic>> animals = [];
  Map<String, dynamic>? selectedAnimal;
  bool isAnimalLoading = true;

  // Doctor Details  
  Doctor? doctor;
  double consultationFee = 0.0;

  // Payment Screenshot
  File? paymentScreenshot;
  final ImagePicker _picker = ImagePicker();
  
  // Selected Payment Method
  String? _selectedPaymentMethod; // 'JazzCash' or 'EasyPaisa'

  final List<String> timeSlots = [
    "09:00 AM",
    "10:00 AM",
    "11:00 AM",
    "02:00 PM",
    "03:00 PM",
    "04:00 PM",
    "05:00 PM",
    "06:00 PM"
  ];

  @override
  void initState() {
    super.initState();
    _fetchAnimals();
    _fetchDoctorDetails();
  }

  Future<void> _fetchDoctorDetails() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.doctorId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          doctor = Doctor.fromMap(docSnapshot.data()!, docSnapshot.id);
          consultationFee = consultationType == 'online'
              ? doctor!.onlineConsultationFee
              : doctor!.homeVisitFee;
        });
      }
    } catch (e) {
      print('Error fetching doctor details: $e');
    }
  }

  Future<void> _fetchAnimals() async {
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
        final sortedDocs = snapshot.docs
          ..sort((a, b) {
            final aTime =
                (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime =
                (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });

        final animalList = sortedDocs.map((doc) => doc.data()).toList();
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

  Future<void> _pickPaymentScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          paymentScreenshot = File(image.path);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment screenshot selected successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _bookAppointmentWithPayment() async {
    // Validation
    if (selectedAnimal == null) {
      _showError("Please select an animal");
      return;
    }
    if (selectedSlot.isEmpty || problemController.text.isEmpty) {
      _showError("Please select slot & write problem");
      return;
    }
    if (_selectedPaymentMethod == null) {
      _showError("Please select payment method (JazzCash or EasyPaisa)");
      return;
    }
    if (paymentScreenshot == null) {
      _showError("Please upload payment screenshot");
      return;
    }

    setState(() => isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final dateTimestamp = Timestamp.fromDate(selectedDate);

      // Step 1: Create Payment Intent
      final paymentIntent = await _paymentService.createPaymentIntent(
        amount: consultationFee,
        currency: 'USD',
      );

      if (paymentIntent == null) {
        throw Exception('Failed to create payment intent');
      }

      // Step 2: Upload Payment Screenshot
      final screenshotUrl = await _paymentService.uploadPaymentScreenshot(
        imageFile: paymentScreenshot!,
        userId: userId,
        appointmentId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (screenshotUrl == null) {
        throw Exception('Failed to upload payment screenshot');
      }

      // Step 3: Create Appointment
      final appointment = AppointmentModel(
        id: '',
        userId: userId,
        doctorId: widget.doctorId,
        animalName: selectedAnimal!['name'] ?? 'Unknown',
        date: dateTimestamp,
        time: selectedSlot,
        problem: problemController.text.trim(),
        status: 'pending',
        consultationType: consultationType,
        paymentAmount: consultationFee,
        paymentIntentId: paymentIntent['id'],
        paymentScreenshotUrl: screenshotUrl,
        paymentStatus: 'paid',
        paymentDate: Timestamp.now(),
        paymentMethod: _selectedPaymentMethod, // JazzCash or EasyPaisa
      );

      final appointmentId = await _appointmentService.createAppointment(appointment);

      // Step 4: Create Payment Record
      final payment = PaymentModel(
        id: '',
        userId: userId,
        doctorId: widget.doctorId,
        appointmentId: appointmentId,
        amount: consultationFee,
        paymentIntentId: paymentIntent['id'],
        paymentScreenshotUrl: screenshotUrl,
        status: 'completed',
        createdAt: Timestamp.now(),
        completedAt: Timestamp.now(),
        consultationType: consultationType,
      );

      await _paymentService.savePayment(payment);

      // Step 5: Send Notification to Doctor
      await _notificationService.sendNotification(
        receiverId: widget.doctorId,
        title: 'New Paid Appointment Request',
        message:
            'You have a new appointment request from a user for ${selectedAnimal!['name']}. Payment of \$${consultationFee.toStringAsFixed(2)} received.',
        appointmentId: appointmentId,
        type: 'appointment_request',
      );

      setState(() {
        isLoading = false;
        isPending = true;
      });

      // Success Dialog
      _showSuccessDialog();
    } catch (e) {
      setState(() => isLoading = false);
      _showError("Error: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "Payment submitted! Your appointment request has been sent to the doctor. You will be notified once approved.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryTeal,
        elevation: 0,
        title: const Text(
          "Book Appointment with Payment",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("Doctor"),
            _doctorCard(),
            const SizedBox(height: 20),
            _sectionHeader("Animal Details"),
            _animalCard(),
            const SizedBox(height: 25),
            _sectionHeader("Consultation Type"),
            _consultationTypeSelector(),
            const SizedBox(height: 25),
            _sectionHeader("Select Date"),
            _dateSelector(),
            const SizedBox(height: 15),
            _sectionHeader("Available Slots"),
            _timeSlotSelector(),
            const SizedBox(height: 25),
            _sectionHeader("Problem Description"),
            _problemTextField(),
            const SizedBox(height: 25),
            _sectionHeader("Payment"),
            _paymentSection(),
            const SizedBox(height: 30),
            _bookButton(),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00796B),
        ),
      ),
    );
  }

  Widget _doctorCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryTeal, width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: NetworkImage(widget.doctorImage),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctorName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkTeal,
                  ),
                ),
                const Text(
                  "Veterinarian",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                if (doctor != null)
                  Text(
                    "${doctor!.specialization ?? 'Specialist'}",
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _animalCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryTeal, width: 2),
      ),
      child: isAnimalLoading
          ? const Center(child: CircularProgressIndicator())
          : animals.isEmpty
              ? Column(
                  children: [
                    const Text(
                      "No animal registered. Please register an animal first.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/registerAnimal');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkTeal,
                      ),
                      child: const Text("Register Animal"),
                    ),
                  ],
                )
              : Column(
                  children: [
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedAnimal,
                      decoration: InputDecoration(
                        labelText: 'Select Animal',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
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
                    const SizedBox(height: 15),
                    if (selectedAnimal != null)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage:
                                (selectedAnimal!['imageUrls'] as List<dynamic>?)
                                            ?.isNotEmpty ==
                                        true
                                    ? NetworkImage(selectedAnimal!['imageUrls'][0])
                                    : const NetworkImage(
                                        'https://via.placeholder.com/150'),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedAnimal!['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: darkTeal,
                                  ),
                                ),
                                Text(selectedAnimal!['breed'] ?? 'Mixed'),
                                Text(
                                  "Age: ${selectedAnimal!['age']?.toString() ?? 'N/A'}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                  ],
                ),
    );
  }

  Widget _consultationTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryTeal, width: 2),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Online Consultation'),
                Text(
                  '\$${doctor?.onlineConsultationFee.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkTeal,
                  ),
                ),
              ],
            ),
            value: 'online',
            groupValue: consultationType,
            activeColor: darkTeal,
            onChanged: (value) {
              setState(() {
                consultationType = value!;
                consultationFee = doctor?.onlineConsultationFee ?? 0.0;
              });
            },
          ),
          RadioListTile<String>(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Home Visit'),
                Text(
                  '\$${doctor?.homeVisitFee.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkTeal,
                  ),
                ),
              ],
            ),
            value: 'home_visit',
            groupValue: consultationType,
            activeColor: darkTeal,
            onChanged: (value) {
              setState(() {
                consultationType = value!;
                consultationFee = doctor?.homeVisitFee ?? 0.0;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _dateSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryTeal),
      ),
      child: CalendarDatePicker(
        initialDate: selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)),
        onDateChanged: (date) => setState(() => selectedDate = date),
      ),
    );
  }

  Widget _timeSlotSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: timeSlots.map((slot) {
        final isSelected = selectedSlot == slot;
        return ChoiceChip(
          label: Text(slot),
          selected: isSelected,
          selectedColor: darkTeal,
          backgroundColor: Colors.grey[200],
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (_) => setState(() => selectedSlot = slot),
        );
      }).toList(),
    );
  }

  Widget _problemTextField() {
    return TextField(
      controller: problemController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: "Briefly describe the issue/problem",
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primaryTeal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primaryTeal),
        ),
      ),
    );
  }

  Widget _paymentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal.withOpacity(0.2), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: darkTeal, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkTeal,
                ),
              ),
              Text(
                '\$${consultationFee.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 15),
          const Text(
            'Upload Payment Screenshot',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please send payment to the doctor and upload the screenshot as proof.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 15),
          if (paymentScreenshot != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(
                  paymentScreenshot!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickPaymentScreenshot,
              icon: const Icon(Icons.upload_file),
              label: Text(paymentScreenshot == null
                  ? 'Select Screenshot'
                  : 'Change Screenshot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: paymentScreenshot == null ? darkTeal : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPending ? Colors.grey : darkTeal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        onPressed: isPending || isLoading ? null : _bookAppointmentWithPayment,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                isPending ? "Request Pending" : "Book Appointment Now",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    problemController.dispose();
    super.dispose();
  }
}
*/
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


// ============================================================================
// SECOND VERSION - Full Featured BookAppointmentPage 
// Uses AppUser doctor parameter with Google Maps, Language Support & Payment
// ============================================================================

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

  DateTime selectedDate = DateTime.now();
  String selectedSlot = "";
  String consultationType = "online"; // 'online' or 'home_visit'
  bool isLoading = false;
  bool isPending = false;

  final TextEditingController problemController = TextEditingController();
  final StripePaymentService _paymentService = StripePaymentService();

  List<Map<String, dynamic>> animals = [];
  Map<String, dynamic>? selectedAnimal;
  bool isAnimalLoading = true;

  List<String> timeSlots = [];
  List<String> availableDays = [];
  
  // Payment-related
  double consultationFee = 0.0;
  File? paymentScreenshot;
  final ImagePicker _picker = ImagePicker();
  String? _selectedPaymentMethod; // 'JazzCash' or 'EasyPaisa'
  
  // Google Maps variables
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    try {
      _loadDoctorAvailability();
      _fetchUserAnimals();
      _initializeMap();
      _loadDoctorFees();
    } catch (e) {
      print('Error in initState: $e');
      // Set safe defaults
      availableDays = [];
      selectedDate = DateTime.now();
      timeSlots = [];
      consultationFee = 0.0;
    }
  }
  
  void _loadDoctorFees() {
    try {
      consultationFee = consultationType == 'online'
          ? (widget.doctor.onlineConsultationFee ?? 0.0)
          : (widget.doctor.homeVisitFee ?? 0.0);
    } catch (e) {
      print('Error loading doctor fees: $e');
      consultationFee = 0.0;
    }
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    problemController.dispose();
    super.dispose();
  }

  void _loadDoctorAvailability() {
    try {
      availableDays = widget.doctor.availableDays ?? [];
      selectedDate = _findFirstAvailableDate();
      timeSlots = _getSlotsForDay(selectedDate);
    } catch (e) {
      print('Error loading doctor availability: $e');
      availableDays = [];
      selectedDate = DateTime.now();
      timeSlots = [];
    }
  }

  DateTime _findFirstAvailableDate() {
    try {
      DateTime checkDate = DateTime.now();
      final maxDate = DateTime.now().add(const Duration(days: 30));
      
      // If no available days, return today
      if (availableDays.isEmpty) {
        return DateTime.now();
      }
      
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
    } catch (e) {
      print('Error finding first available date: $e');
      return DateTime.now();
    }
  }

  List<String> _getSlotsForDay(DateTime date) {
    try {
      final weekday = _getWeekdayName(date.weekday);
      
      if (!availableDays.contains(weekday)) {
        return [];
      }
      
      return widget.doctor.availableSlots ?? [];
    } catch (e) {
      print('Error getting slots for day: $e');
      return [];
    }
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
    try {
      if (availableDays.isEmpty) {
        return false;
      }
      final weekday = _getWeekdayName(date.weekday);
      return availableDays.contains(weekday);
    } catch (e) {
      print('Error checking day availability: $e');
      return false;
    }
  }
  
  /// ------------------ INITIALIZE GOOGLE MAP ------------------
  void _initializeMap() {
    try {
      final lat = widget.doctor.latitude;
      final lng = widget.doctor.longitude;
      
      if (lat != null && lng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('clinic_location'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: widget.doctor.clinicName ?? 'Clinic',
              snippet: widget.doctor.clinicAddress ?? 'Address',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    } catch (e) {
      print('Error initializing map: $e');
    }
  }
  
  /// ------------------ OPEN IN GOOGLE MAPS ------------------
  Future<void> _openInGoogleMaps() async {
    if (widget.doctor.latitude == null || widget.doctor.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    final lat = widget.doctor.latitude;
    final lng = widget.doctor.longitude;
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

  Future<void> _fetchUserAnimals() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() => isAnimalLoading = false);
        }
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (!mounted) return;

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
      print('Error fetching user animals: $e');
      if (mounted) {
        setState(() {
          animals = [];
          selectedAnimal = null;
          isAnimalLoading = false;
        });
      }
    }
  }

  Future<void> _pickPaymentScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          paymentScreenshot = File(image.path);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment screenshot selected successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
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

    if (paymentScreenshot == null) {
      _showErrorDialog(languageProvider.t('Please upload payment screenshot', 'براہ کرم ادائیگی کا اسکرین شاٹ اپ لوڈ کریں'), languageProvider);
      return;
    }

    // Verify file still exists
    if (paymentScreenshot != null && !await paymentScreenshot!.exists()) {
      setState(() => paymentScreenshot = null);
      _showErrorDialog(
        languageProvider.t('Selected file no longer exists. Please select the screenshot again.', 
        'منتخب کردہ فائل موجود نہیں ہے۔ براہ کرم دوبارہ اسکرین شاٹ منتخب کریں۔'), 
        languageProvider
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception(languageProvider.t('User not authenticated. Please login again.', 'صارف تصدیق شدہ نہیں ہے۔ براہ کرم دوبارہ لاگ ان کریں۔'));
      }
      final userId = currentUser.uid;
      final dateTimestamp = Timestamp.fromDate(selectedDate);

      // Store safe references
      final animalData = selectedAnimal!;
      final screenshotFile = paymentScreenshot!;
      final animalName = animalData['name'] ?? languageProvider.translate('unknown');
      
      print('📋 Starting appointment booking...');
      print('   User ID: $userId');
      print('   Doctor ID: ${widget.doctor.id}');
      print('   Animal: $animalName');
      print('   Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}');
      print('   Time: $selectedSlot');
      print('   Fee: Rs $consultationFee');

      // Step 1: Upload Payment Screenshot to Supabase Storage
      // Screenshot will be stored in:
      // 1. Supabase Storage -> "Payment" bucket (actual file)
      // 2. Firestore -> "appointments" collection (URL in appointment document)
      // 3. Firestore -> "payments" collection (URL in payment document)
      // This allows admins to access screenshot from either appointments or payments
      print('\n📤 Step 1: Uploading payment screenshot to Supabase...');
      final screenshotUrl = await _paymentService.uploadPaymentScreenshot(
        imageFile: screenshotFile,
        userId: userId,
        appointmentId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (screenshotUrl == null || screenshotUrl.isEmpty) {
        throw Exception(languageProvider.t(
          'Failed to upload payment screenshot. Please check your internet connection and try again.',
          'ادائیگی کے اسکرین شاٹ کو اپ لوڈ کرنے میں ناکامی۔ براہ کرم اپنا انٹرنیٹ کنکشن چیک کریں اور دوبارہ کوشش کریں۔'
        ));
      }

      print('✅ Screenshot uploaded: $screenshotUrl');

      // Step 2: Create Appointment with Payment Details
      // Screenshot URL is stored in appointment document for admin access
      print('\n📝 Step 2: Creating appointment with screenshot URL...');
      final appointment = AppointmentModel(
        id: '',
        userId: userId,
        doctorId: widget.doctor.id,
        animalName: animalName,
        date: dateTimestamp,
        time: selectedSlot,
        problem: problemController.text.trim(),
        status: 'pending',
        consultationType: consultationType,
        paymentAmount: consultationFee,
        paymentIntentId: 'jazzcash_${DateTime.now().millisecondsSinceEpoch}', // Manual payment reference
        paymentScreenshotUrl: screenshotUrl, // ✅ Screenshot URL stored here
        paymentStatus: 'pending_verification', // Admin will verify payment screenshot
        paymentDate: Timestamp.now(),
      );

      final appointmentId = await AppointmentService().createAppointment(appointment);
      print('✅ Appointment created with screenshot: $appointmentId');

      // Step 3: Create Payment Record
      // Screenshot URL is also stored in payment document for complete record
      print('\n💳 Step 3: Creating payment record with screenshot URL...');
      final payment = PaymentModel(
        id: '',
        userId: userId,
        doctorId: widget.doctor.id,
        appointmentId: appointmentId,
        amount: consultationFee,
        paymentIntentId: 'jazzcash_${DateTime.now().millisecondsSinceEpoch}', // Manual payment reference
        paymentScreenshotUrl: screenshotUrl, // ✅ Screenshot URL stored here too
        status: 'pending_verification', // Admin will verify payment
        createdAt: Timestamp.now(),
        completedAt: null,
        consultationType: consultationType,
      );

      await _paymentService.savePayment(payment);
      print('✅ Payment record saved with screenshot URL');

      // Step 4: Send Notification to Doctor
      print('\n🔔 Step 4: Sending notification to doctor...');
      await NotificationService().sendNotification(
        receiverId: widget.doctor.id,
        title: languageProvider.t('New Appointment Request', 'نئی ملاقات کی درخواست'),
        message: languageProvider.t('You have a new appointment request from a user for $animalName. Payment of Rs ${consultationFee.toStringAsFixed(0)} via JazzCash (pending verification).', 'آپ کو $animalName کے لیے Rs ${consultationFee.toStringAsFixed(0)} کی ادائیگی کے ساتھ نئی ملاقات کی درخواست ملی ہے (تصدیق زیر التواء)۔'),
        appointmentId: appointmentId,
        type: 'appointment_request',
      );
      print('✅ Notification sent');

      setState(() {
        isLoading = false;
        isPending = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      
      print('✅ Appointment booking completed successfully!');
      
      if (mounted) {
        _showSuccessDialog(languageProvider);
      }
    } on StorageException catch (e) {
      setState(() => isLoading = false);
      print('❌ Supabase Storage Error: $e');
      _showErrorDialog(
        languageProvider.t(
          'Storage error: ${e.message}. Please make sure the Payment bucket exists in Supabase Storage and is publicly accessible.',
          'اسٹوریج خرابی: ${e.message}۔ براہ کرم یقینی بنائیں کہ Supabase Storage میں Payment bucket موجود ہے اور عوامی رسائی فعال ہے۔'
        ), 
        languageProvider
      );
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ Appointment booking error: $e');
      String errorMessage = e.toString();
      
      // Remove "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      _showErrorDialog(
        "${languageProvider.t('Failed to book appointment', 'ملاقات بک کرنے میں ناکامی')}: $errorMessage", 
        languageProvider
      );
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
    try {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      
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
                        
                        // Clinic Location with Google Maps
                        if (widget.doctor.latitude != null && widget.doctor.longitude != null) ...[
                          _sectionHeader(languageProvider.t('Clinic Location', 'کلینک کا مقام')),
                          const SizedBox(height: 12),
                          _buildClinicLocationCard(languageProvider),
                          const SizedBox(height: 24),
                        ],
                        
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
                        const SizedBox(height: 24),
                        
                        // Consultation Type Selector
                        _sectionHeader(languageProvider.t('Consultation Type', 'مشاورت کی قسم')),
                        const SizedBox(height: 12),
                        _buildConsultationTypeSelector(languageProvider),
                        const SizedBox(height: 24),
                        
                        // Payment Screenshot Section
                        _sectionHeader(languageProvider.t('Payment Proof', 'ادائیگی کا ثبوت')),
                        const SizedBox(height: 12),
                        _buildPaymentSection(languageProvider),
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
    } catch (e, stackTrace) {
      print('Error in BookAppointmentPage build: $e');
      print('Stack trace: $stackTrace');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Appointment Booking'),
          backgroundColor: primaryDark,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error loading appointment page',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
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
                      initialValue: selectedAnimal,
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

  Widget _buildConsultationTypeSelector(LanguageProvider languageProvider) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Online Consultation Option
          InkWell(
            onTap: () {
              setState(() {
                consultationType = 'online';
                _loadDoctorFees();
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: consultationType == 'online' ? primaryDark : Colors.grey[300]!,
                  width: consultationType == 'online' ? 2 : 1,
                ),
                color: consultationType == 'online' ? primaryLight.withOpacity(0.1) : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(
                    consultationType == 'online' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: consultationType == 'online' ? primaryDark : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.t('Online Consultation', 'آن لائن مشاورت'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: consultationType == 'online' ? primaryDark : darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          languageProvider.t('Video/Phone consultation with doctor', 'ڈاکٹر کے ساتھ ویڈیو/فون مشاورت'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rs ${widget.doctor.onlineConsultationFee?.toStringAsFixed(0) ?? '0'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: consultationType == 'online' ? primaryDark : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Home Visit Option
          InkWell(
            onTap: () {
              setState(() {
                consultationType = 'home_visit';
                _loadDoctorFees();
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: consultationType == 'home_visit' ? primaryDark : Colors.grey[300]!,
                  width: consultationType == 'home_visit' ? 2 : 1,
                ),
                color: consultationType == 'home_visit' ? primaryLight.withOpacity(0.1) : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(
                    consultationType == 'home_visit' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: consultationType == 'home_visit' ? primaryDark : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.t('Home Visit', 'گھر کا دورہ'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: consultationType == 'home_visit' ? primaryDark : darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          languageProvider.t('Doctor will visit your home', 'ڈاکٹر آپ کے گھر آئیں گے'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rs ${widget.doctor.homeVisitFee?.toStringAsFixed(0) ?? '0'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: consultationType == 'home_visit' ? primaryDark : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(LanguageProvider languageProvider) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Amount Display with Commission Breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryDark.withOpacity(0.1), primaryLight.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageProvider.t('Total Amount', 'کل رقم'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    Text(
                      'Rs ${consultationFee.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languageProvider.t('Doctor receives', 'ڈاکٹر کو ملے گی'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            'Rs ${PaymentConfig.calculateDoctorPayout(consultationFee).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languageProvider.t('App service fee', 'ایپ سروس فیس'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            'Rs ${PaymentConfig.calculateCommission(consultationFee).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Professional Payment Method Selector
          PaymentMethodSelector(
            selectedMethod: _selectedPaymentMethod,
            onMethodSelected: (String method) {
              setState(() {
                _selectedPaymentMethod = method;
              });
            },
            showAccountDetails: true,
          ),
          const SizedBox(height: 16),
          
          // Warning if payment method not selected
          if (_selectedPaymentMethod == null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[300]!, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please select a payment method (JazzCash or EasyPaisa) above first',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Upload Screenshot Button
          if (paymentScreenshot == null && _selectedPaymentMethod != null)
            InkWell(
              onTap: _pickPaymentScreenshot,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [primaryDark.withOpacity(0.9), primaryMedium.withOpacity(0.9)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryDark.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload_file, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      languageProvider.t('Upload Payment Screenshot', 'ادائیگی کا اسکرین شاٹ اپ لوڈ کریں'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (paymentScreenshot != null)
            // Screenshot Preview
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      paymentScreenshot!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 22),
                          const SizedBox(width: 8),
                          Text(
                            languageProvider.t('Payment proof uploaded', 'ادائیگی کا ثبوت اپ لوڈ ہو گیا'),
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _pickPaymentScreenshot,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(languageProvider.t('Change', 'تبدیل کریں')),
                        style: TextButton.styleFrom(foregroundColor: primaryDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          
          // Refund Policy
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user, color: Colors.blue[700], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.t('Money Back Guarantee', 'رقم واپسی کی ضمانت'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        languageProvider.t(
                          'If doctor declines your appointment, you will receive full refund within ${PaymentConfig.REFUND_PROCESSING_DAYS} business days.',
                          'اگر ڈاکٹر آپ کی ملاقات مسترد کر دیتے ہیں تو آپ کو ${PaymentConfig.REFUND_PROCESSING_DAYS} کاروباری دنوں میں مکمل رقم واپس مل جائے گی۔',
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[800],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method for payment instruction steps
  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: primaryDark,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[800],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ------------------ CLINIC LOCATION MAP CARD ------------------
  Widget _buildClinicLocationCard(LanguageProvider languageProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryLight.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Map Container with Overlay
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                SizedBox(
                  height: 280,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        widget.doctor.latitude ?? 0.0,
                        widget.doctor.longitude ?? 0.0,
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
                // Floating Clinic Name Badge
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.doctor.clinicName ?? 'Clinic',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                languageProvider.t('Tap for directions', 'راستے کے لیے ٹیپ کریں'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 14, color: primaryDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Location Details Section
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clinic Name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryDark.withOpacity(0.1),
                            primaryLight.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.local_hospital, color: primaryDark, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.t('Clinic Name', 'کلینک کا نام'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.doctor.clinicName ?? 'Clinic',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryDark.withOpacity(0.1),
                            primaryLight.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.place, color: primaryDark, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.t('Address', 'پتہ'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.doctor.clinicAddress ?? 'Address',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [primaryDark, primaryMedium],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryDark.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _openInGoogleMaps,
                          icon: const Icon(Icons.directions, size: 20),
                          label: Text(
                            languageProvider.t('Get Directions', 'راستہ دیکھیں'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final lat = widget.doctor.latitude;
                          final lng = widget.doctor.longitude;
                          if (_mapController != null && lat != null && lng != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(lat, lng),
                                  zoom: 17,
                                  tilt: 45,
                                ),
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.zoom_in_map, color: primaryDark, size: 20),
                        label: Text(
                          languageProvider.t('View Map', 'نقشہ دیکھیں'),
                          style: TextStyle(
                            color: primaryDark,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryDark, width: 1.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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