import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/model/home_visit_appointment_model.dart';
import 'package:flutter_application_1/services/home_visit_service.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:flutter_application_1/view/home_visit_chat_screen.dart';

class DoctorHomeVisitTrackingPage extends StatefulWidget {
  const DoctorHomeVisitTrackingPage({super.key});

  @override
  State<DoctorHomeVisitTrackingPage> createState() =>
      _DoctorHomeVisitTrackingPageState();
}

class _DoctorHomeVisitTrackingPageState
    extends State<DoctorHomeVisitTrackingPage> {
  final Color primaryDark = const Color(0xFF00796B);
  bool _sharingLocation = false;
  late Stream<Position> _positionStream;

  @override
  void initState() {
    super.initState();
    _initializeLocationStream();
  }

  void _initializeLocationStream() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryDark,
        title: const Text('🏥 My Home Visits'),
        elevation: 0,
      ),
      body: StreamBuilder<List<HomeVisitAppointmentModel>>(
        stream: HomeVisitService.getDoctorActiveVisits(doctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeVisits = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeVisits.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: 100,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No active home visits',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check pending requests in home visit dashboard',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Text(
                      '🚗 Active Visits (${activeVisits.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...activeVisits
                        .map((visit) => _buildActiveVisitCard(context, visit)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveVisitCard(
    BuildContext context,
    HomeVisitAppointmentModel visit,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.2),
                  Colors.green.withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🐾 ${visit.animalName} - ${visit.problem}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${visit.id.substring(0, 8)}...',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    visit.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('📍 Location', visit.address),
                const SizedBox(height: 8),
                _detailRow('⏰ Time', visit.preferredTime),
                const SizedBox(height: 8),
                _buildPhoneContactRow(visit.userPhone),
                const SizedBox(height: 12),
                
                // Location Sharing Status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Location Sharing',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          StreamBuilder<Position>(
                            stream: _positionStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  '✅ Sharing location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                  ),
                                );
                              }
                              return Text(
                                '⏳ Waiting for location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            _toggleLocationSharing(context, visit),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _sharingLocation
                              ? Colors.red
                              : Colors.green,
                        ),
                        child: Text(
                          _sharingLocation ? 'Stop' : 'Start',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  HomeVisitChatScreen(appointment: visit),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryDark,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showCompleteDialog(context, visit),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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

  void _toggleLocationSharing(
    BuildContext context,
    HomeVisitAppointmentModel visit,
  ) async {
    if (_sharingLocation) {
      // Stop sharing
      setState(() => _sharingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📍 Location sharing stopped')),
      );
    } else {
      // Start sharing
      setState(() => _sharingLocation = true);
      
      // Start streaming location
      _positionStream.listen((position) async {
        try {
          await HomeVisitService.updateDoctorLocation(
            visit.id,
            position.latitude,
            position.longitude,
            'on_the_way',
          );
        } catch (e) {
          print('Error updating location: $e');
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Location sharing started')),
      );
    }
  }

  void _showCompleteDialog(
    BuildContext context,
    HomeVisitAppointmentModel visit,
  ) {
    final notesController = TextEditingController();
    String selectedPayment = 'cash';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Home Visit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Animal: ${visit.animalName}'),
              const SizedBox(height: 12),
              const Text('Medical Notes (Required)'),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  hintText: 'Enter medical notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text('Payment Method'),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) => Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('💵 Cash'),
                      value: 'cash',
                      groupValue: selectedPayment,
                      onChanged: (value) {
                        setState(() => selectedPayment = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('💳 Online'),
                      value: 'online',
                      groupValue: selectedPayment,
                      onChanged: (value) {
                        setState(() => selectedPayment = value!);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (notesController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter medical notes'),
                  ),
                );
                return;
              }

              _completeVisit(visit, notesController.text, selectedPayment);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _completeVisit(
    HomeVisitAppointmentModel visit,
    String notes,
    String payment,
  ) async {
    try {
      await HomeVisitService.completeHomeVisit(
        visit.id,
        notes,
        payment,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Home visit completed')),
        );
        setState(() => _sharingLocation = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildPhoneContactRow(String phoneNumber) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 100,
          child: Text(
            '📱 Phone',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _makePhoneCall(phoneNumber),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF80CBC4).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00796B), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    phoneNumber,
                    style: const TextStyle(
                      color: Color(0xFF00796B),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.call, size: 16, color: Color(0xFF00796B)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot make calls on this device'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error making call: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
