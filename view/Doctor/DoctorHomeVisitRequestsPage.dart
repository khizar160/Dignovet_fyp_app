import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/model/home_visit_appointment_model.dart';
import 'package:flutter_application_1/services/home_visit_service.dart';
import 'package:flutter_application_1/services/notification%20service/notification_service.dart';
import 'package:flutter_application_1/view/Doctor/home_visit_completion_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorHomeVisitRequestsPage extends StatefulWidget {
  const DoctorHomeVisitRequestsPage({super.key});

  @override
  State<DoctorHomeVisitRequestsPage> createState() =>
      _DoctorHomeVisitRequestsPageState();
}

class _DoctorHomeVisitRequestsPageState
    extends State<DoctorHomeVisitRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryDark = const Color(0xFF00796B);
  final Color primaryLight = const Color(0xFF80CBC4);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryDark,
        title: const Text('Home Visit Requests'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.schedule)),
            Tab(text: 'Accepted', icon: Icon(Icons.check_circle)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending Requests
          _buildPendingTab(doctorId),
          // Accepted Requests
          _buildAcceptedTab(doctorId),
          // History
          _buildHistoryTab(doctorId),
        ],
      ),
    );
  }

  Widget _buildPendingTab(String doctorId) {
    return StreamBuilder<List<HomeVisitAppointmentModel>>(
      stream: HomeVisitService.getDoctorHomeVisitRequests(doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No pending home visit requests'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(requests[index]);
          },
        );
      },
    );
  }

  Widget _buildAcceptedTab(String doctorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('home_visit_appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('status', whereIn: ['accepted', 'on_the_way']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs
                .map((doc) => HomeVisitAppointmentModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ))
                .toList() ??
            [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No accepted requests'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildAcceptedRequestCard(requests[index]);
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(String doctorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('home_visit_appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('status',
              whereIn: ['completed', 'rejected', 'cancelled']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs
                .map((doc) => HomeVisitAppointmentModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ))
                .toList() ??
            [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No history'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildHistoryCard(requests[index]);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(HomeVisitAppointmentModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.withOpacity(0.2), Colors.orange.withOpacity(0.1)],
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
                      '🐾 ${request.animalName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requested ${_formatTime(request.requestDate)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('📍 Location', request.address),
                const SizedBox(height: 12),
                _detailRow('🏅 Landmark', request.landmark ?? 'Not provided'),
                const SizedBox(height: 12),
                _detailRow('⏰ Preferred Time', request.preferredTime),
                const SizedBox(height: 12),
                _buildPhoneContactRow(request.userPhone),
                const SizedBox(height: 12),
                _detailRow('🐕 Problem', request.problem),
                if (request.userNotes != null) ...[
                  const SizedBox(height: 12),
                  _detailRow('📝 Notes', request.userNotes!),
                ],
                const SizedBox(height: 12),
                _detailRow('💰 Fee', 'Rs. ${request.homeVisitFee}'),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectRequest(request.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAcceptDialog(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedRequestCard(HomeVisitAppointmentModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1)],
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
                      '🐾 ${request.animalName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📍 ${request.address.substring(0, 30)}...',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                    request.doctorStatus?.toUpperCase() ?? 'ACCEPTED',
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

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('⏰ Time', request.preferredTime),
                const SizedBox(height: 12),
                _buildPhoneContactRow(request.userPhone),
                const SizedBox(height: 12),
                if (request.doctorEstimatedArrival != null)
                  _detailRow('🚗 ETA', request.doctorEstimatedArrival!),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchMap(request.latitude, request.longitude),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.map),
                    label: const Text('View Map'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCompletionDialog(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HomeVisitAppointmentModel request) {
    final statusColor = request.status == 'completed'
        ? Colors.green
        : request.status == 'rejected'
            ? Colors.red
            : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🐾 ${request.animalName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                request.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            request.status == 'completed'
                ? Icons.check_circle
                : Icons.cancel,
            color: statusColor,
          ),
        ],
      ),
    );
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
        _showSnackBar('Cannot make calls on this device', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error making call: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAcceptDialog(HomeVisitAppointmentModel request) {
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Animal: ${request.animalName}'),
            const SizedBox(height: 8),
            Text('Problem: ${request.problem}'),
            const SizedBox(height: 12),
            const Text('When will you arrive?'),
            const SizedBox(height: 8),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                hintText: 'e.g., Will arrive in 30 minutes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _acceptRequest(request, timeController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(
    HomeVisitAppointmentModel request,
    String estimatedArrival,
  ) async {
    if (estimatedArrival.isEmpty) {
      _showError('Please enter estimated arrival time');
      return;
    }

    try {
      await HomeVisitService.acceptHomeVisitRequest(
        request.id,
        request.doctorId,
        estimatedArrival,
      );

      // Send notification to user
      await NotificationService().sendNotification(
        receiverId: request.userId,
        appointmentId: request.id,
        title: 'Home Visit Accepted! ✅',
        message: 'Your home visit has been accepted. $estimatedArrival',
        type: 'home_visit_accepted',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Request accepted and notified')),
        );
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _submitReject(requestId, reasonController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReject(String requestId, String reason) async {
    if (reason.isEmpty) {
      _showError('Please provide a reason');
      return;
    }

    try {
      await HomeVisitService.rejectHomeVisitRequest(requestId, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Request rejected')),
        );
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _showCompletionDialog(HomeVisitAppointmentModel request) async {
    showHomeVisitCompletionDialog(
      context,
      request,
      () {
        // Refresh the UI
        setState(() {});
      },
    );
  }

  void _launchMap(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
