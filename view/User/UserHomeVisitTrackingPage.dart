import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/model/home_visit_appointment_model.dart';
import 'package:flutter_application_1/services/home_visit_service.dart';
import 'package:flutter_application_1/view/home_visit_chat_screen.dart';

class UserHomeVisitTrackingPage extends StatefulWidget {
  const UserHomeVisitTrackingPage({super.key});

  @override
  State<UserHomeVisitTrackingPage> createState() =>
      _UserHomeVisitTrackingPageState();
}

class _UserHomeVisitTrackingPageState extends State<UserHomeVisitTrackingPage> {
  final Color primaryDark = const Color(0xFF00796B);
  final Color primaryLight = const Color(0xFF80CBC4);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryDark,
        title: const Text('🏥 My Home Visits'),
        elevation: 0,
      ),
      body: StreamBuilder<List<HomeVisitAppointmentModel>>(
        stream: HomeVisitService.getUserHomeVisitRequests(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final visits = snapshot.data ?? [];

          if (visits.isEmpty) {
            return Center(
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
                    'No home visits yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book your first pet home visit',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Separate by status
          final pending = visits.where((v) => v.status == 'pending').toList();
          final active = visits
              .where((v) =>
                  v.status == 'accepted' || v.status == 'on_the_way')
              .toList();
          final completed = visits
              .where((v) =>
                  v.status == 'completed' ||
                  v.status == 'rejected' ||
                  v.status == 'cancelled')
              .toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Visits
                  if (active.isNotEmpty) ...[
                    Text(
                      '🔴 Active Visits (${active.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...active.map((visit) => _buildActiveVisitCard(context, visit)),
                    const SizedBox(height: 24),
                  ],

                  // Pending Requests
                  if (pending.isNotEmpty) ...[
                    Text(
                      '⏳ Pending (${pending.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...pending.map((visit) => _buildPendingVisitCard(context, visit)),
                    const SizedBox(height: 24),
                  ],

                  // Completed/History
                  if (completed.isNotEmpty) ...[
                    Text(
                      '✅ History (${completed.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...completed
                        .map((visit) => _buildHistoryVisitCard(context, visit)),
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
    final statusColor = visit.status == 'on_the_way' ? Colors.blue : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: statusColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor.withOpacity(0.2), statusColor.withOpacity(0.1)],
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
                      '🐾 ${visit.animalName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dr. Visit for ${visit.problem}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    visit.status == 'on_the_way' ? '🚗 ON THE WAY' : '✅ ACCEPTED',
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
                _detailRow('⏰ Time', visit.preferredTime),
                const SizedBox(height: 8),
                _detailRow('📍 Location', visit.address),
                const SizedBox(height: 8),
                if (visit.doctorEstimatedArrival != null)
                  _detailRow('🚗 ETA', visit.doctorEstimatedArrival!),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
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
                    label: const Text('View Chat & Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryDark,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingVisitCard(
    BuildContext context,
    HomeVisitAppointmentModel visit,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🐾 ${visit.animalName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
          const SizedBox(height: 12),
          _detailRow('Problem', visit.problem),
          const SizedBox(height: 8),
          _detailRow('Time', visit.preferredTime),
          const SizedBox(height: 8),
          _detailRow('Fee', '₹${visit.homeVisitFee}'),
          const SizedBox(height: 12),
          Text(
            '⏳ Waiting for doctor to accept your request...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryVisitCard(
    BuildContext context,
    HomeVisitAppointmentModel visit,
  ) {
    final isCompleted = visit.status == 'completed';
    final statusColor = isCompleted ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: statusColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🐾 ${visit.animalName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                visit.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('Problem', visit.problem),
          const SizedBox(height: 8),
          _detailRow('Date', visit.preferredTime),
          if (visit.status == 'completed') ...[
            const SizedBox(height: 8),
            if (visit.visitNotes != null)
              _detailRow('Doctor Notes', visit.visitNotes!),
            const SizedBox(height: 8),
            _detailRow('Payment', visit.paymentMethod ?? 'Not specified'),
          ] else if (visit.status == 'rejected')
            ...[
              const SizedBox(height: 8),
              if (visit.doctorRejectionReason != null)
                _detailRow('Reason', visit.doctorRejectionReason!),
            ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
