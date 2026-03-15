import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/model/payment_model.dart';
import 'package:flutter_application_1/model/doctor_profile_model.dart';
import 'package:flutter_application_1/services/Appointment%20Service/appointment_services.dart';
import 'package:flutter_application_1/services/payment_service/stripe_payment_service.dart';
import 'package:flutter_application_1/services/notification%20service/notification_service.dart';

class BookAppointmentWithPaymentPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String doctorImage;

  const BookAppointmentWithPaymentPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.doctorImage,
  });

  @override
  State<BookAppointmentWithPaymentPage> createState() =>
      _BookAppointmentWithPaymentPageState();
}

class _BookAppointmentWithPaymentPageState
    extends State<BookAppointmentWithPaymentPage> {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
