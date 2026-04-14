import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/home_visit_appointment_model.dart';
import 'package:flutter_application_1/model/app_user.dart';
import 'package:flutter_application_1/services/home_visit_service.dart';
import 'package:flutter_application_1/services/notification%20service/notification_service.dart';
import 'package:flutter_application_1/services/location_service.dart';

class BookHomeVisitPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String doctorImage;
  final double homeVisitFee;

  const BookHomeVisitPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.doctorImage,
    required this.homeVisitFee,
  });

  @override
  State<BookHomeVisitPage> createState() => _BookHomeVisitPageState();
}

class _BookHomeVisitPageState extends State<BookHomeVisitPage> {
  final Color primaryDark = const Color(0xFF00796B);
  final Color primaryLight = const Color(0xFF80CBC4);

  // Form Controllers
  final TextEditingController addressController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController animalNameController = TextEditingController();
  final TextEditingController problemController = TextEditingController();

  // State Variables
  bool isLoading = false;
  Position? userPosition;
  String selectedTimeSlot = '3:00 PM - 5:00 PM';
  List<Map<String, dynamic>> animals = [];
  Map<String, dynamic>? selectedAnimal;
  bool isLoadingAnimals = true;

  final List<String> timeSlots = [
    '9:00 AM - 11:00 AM',
    '11:00 AM - 1:00 PM',
    '1:00 PM - 3:00 PM',
    '3:00 PM - 5:00 PM',
    '5:00 PM - 7:00 PM',
    '7:00 PM - 9:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAnimals();
    _getLocation();
    phoneController.text = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
  }

  /// Fetch user's animals
  Future<void> _fetchAnimals() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('animals')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final animalList = snapshot.docs.map((doc) => doc.data()).toList();
      setState(() {
        animals = animalList;
        selectedAnimal = animalList.isNotEmpty ? animalList.first : null;
        isLoadingAnimals = false;
      });
    } catch (e) {
      print('Error fetching animals: $e');
      setState(() => isLoadingAnimals = false);
    }
  }

  /// Get user's location
  Future<void> _getLocation() async {
    try {
      final position = await LocationService.getUserLocation();
      setState(() => userPosition = position);
      
      // Fill address field with lat/lng
      addressController.text = 'Lat: ${position.latitude}, Lng: ${position.longitude}';
    } catch (e) {
      print('Location error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enable location: $e')),
        );
      }
    }
  }

  /// Book home visit
  Future<void> _bookHomeVisit() async {
    // Validation
    if (selectedAnimal == null) {
      _showError('Please select an animal');
      return;
    }
    if (addressController.text.isEmpty) {
      _showError('Please enter address');
      return;
    }
    if (phoneController.text.isEmpty) {
      _showError('Please enter phone number');
      return;
    }
    if (problemController.text.isEmpty) {
      _showError('Please describe the problem');
      return;
    }
    if (userPosition == null) {
      _showError('Location required for home visit');
      return;
    }

    setState(() => isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final appointmentId = DateTime.now().millisecondsSinceEpoch.toString();

      final homeVisitRequest = HomeVisitAppointmentModel(
        id: appointmentId,
        userId: userId,
        doctorId: widget.doctorId,
        animalName: selectedAnimal!['name'] ?? 'Unknown Animal',
        requestDate: Timestamp.now(),
        preferredTime: selectedTimeSlot,
        problem: problemController.text,
        latitude: userPosition!.latitude,
        longitude: userPosition!.longitude,
        address: addressController.text,
        landmark: landmarkController.text.isNotEmpty ? landmarkController.text : null,
        userPhone: phoneController.text,
        userNotes: notesController.text.isNotEmpty ? notesController.text : null,
        status: 'pending',
        chatEnabled: false, // Chat will be enabled only after doctor accepts
        homeVisitFee: widget.homeVisitFee,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // Create request in Firestore
      await HomeVisitService.createHomeVisitRequest(homeVisitRequest);

      // Send notification to doctor
      await NotificationService().sendNotification(
        receiverId: widget.doctorId,
        appointmentId: appointmentId,
        title: 'New Home Visit Request! 🏥',
        message:
            'You have a home visit request for ${selectedAnimal!['name']}. Location: ${addressController.text}',
        type: 'home_visit_request',
      );

      setState(() => isLoading = false);

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Home visit request sent! Waiting for doctor acceptance...'),
            backgroundColor: Color(0xFF00796B),
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Error: $e');
      print('Booking error: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryDark,
        title: const Text('Book Home Visit'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Card
            _buildDoctorCard(),
            const SizedBox(height: 24),

            // Animal Selection
            _sectionHeader('Select Animal'),
            _buildAnimalSelector(),
            const SizedBox(height: 24),

            // Address Field
            _sectionHeader('Home Address'),
            _buildTextField(
              controller: addressController,
              label: 'Full Address',
              icon: Icons.location_on,
              hint: 'Enter your home address',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: landmarkController,
              label: 'Landmark (Optional)',
              icon: Icons.flag,
              hint: 'e.g., Near park, Blue house',
            ),
            const SizedBox(height: 24),

            // Time Slot Selection
            _sectionHeader('Preferred Time'),
            _buildTimeSlotSelector(),
            const SizedBox(height: 24),

            // Contact Details
            _sectionHeader('Contact Details'),
            _buildTextField(
              controller: phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              hint: '+92...',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Problem Description
            _sectionHeader('Problem/Notes'),
            _buildTextArea(
              controller: problemController,
              label: 'Describe the problem',
              hint: 'Describe your pet\'s symptoms or health issue',
            ),
            const SizedBox(height: 12),
            _buildTextArea(
              controller: notesController,
              label: 'Additional Notes (Optional)',
              hint: 'Any special instructions or notes for the doctor',
            ),
            const SizedBox(height: 24),

            // Fee Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryDark.withOpacity(0.1), primaryLight.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Home Visit Fee',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Rs. ${widget.homeVisitFee.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Book Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : _bookHomeVisit,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Send Home Visit Request',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Info Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryDark.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your request will be sent to the doctor. You\'ll receive a notification once they accept or reject your request.',
                      style: TextStyle(
                        color: primaryDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryLight, width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(widget.doctorImage),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctorName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Home Visit Specialist',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryDark.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '📍 Home Service Available',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalSelector() {
    if (isLoadingAnimals) {
      return const Center(child: CircularProgressIndicator());
    }

    if (animals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text('No animals registered'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/registerAnimal'),
              icon: const Icon(Icons.add),
              label: const Text('Register Animal'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryDark),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<Map<String, dynamic>>(
      value: selectedAnimal,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: animals.map((animal) {
        return DropdownMenuItem(
          value: animal,
          child: Text(animal['name'] ?? 'Unknown'),
        );
      }).toList(),
      onChanged: (value) => setState(() => selectedAnimal = value),
    );
  }

  Widget _buildTimeSlotSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: timeSlots.map((slot) {
        return FilterChip(
          label: Text(slot),
          selected: selectedTimeSlot == slot,
          selectedColor: primaryDark,
          labelStyle: TextStyle(
            color: selectedTimeSlot == slot ? Colors.white : Colors.black,
          ),
          onSelected: (selected) {
            setState(() => selectedTimeSlot = slot);
          },
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryDark),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: primaryDark,
        ),
      ),
    );
  }

  @override
  void dispose() {
    addressController.dispose();
    landmarkController.dispose();
    phoneController.dispose();
    notesController.dispose();
    animalNameController.dispose();
    problemController.dispose();
    super.dispose();
  }
}
