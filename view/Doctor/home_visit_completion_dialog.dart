import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/home_visit_appointment_model.dart';
import 'package:flutter_application_1/services/notification%20service/notification_service.dart';

class HomeVisitCompletionDialog extends StatefulWidget {
  final HomeVisitAppointmentModel request;
  final VoidCallback onComplete;

  const HomeVisitCompletionDialog({
    required this.request,
    required this.onComplete,
    super.key,
  });

  @override
  State<HomeVisitCompletionDialog> createState() =>
      _HomeVisitCompletionDialogState();
}

class _HomeVisitCompletionDialogState extends State<HomeVisitCompletionDialog> {
  late TextEditingController _notesController;
  String _paymentMethod = 'cash'; // 'cash' or 'online'
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF00796B),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ Complete Home Visit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🐾 ${widget.request.animalName}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visit Details Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Patient', '${widget.request.userId}'),
                        const SizedBox(height: 8),
                        _infoRow('Location', widget.request.address),
                        const SizedBox(height: 8),
                        _infoRow(
                          'Fee',
                          'Rs. ${widget.request.homeVisitFee}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Visit Notes
                  const Text(
                    'Visit Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter treatment notes, findings, recommendations...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Method Selection
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption('cash', '💵 Cash Payment'),
                  const SizedBox(height: 8),
                  _buildPaymentOption('online', '💳 Online Payment'),

                  const SizedBox(height: 24),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'After completion, patient will be notified and payment will be processed.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitCompletion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                    ),
                    icon: const Icon(Icons.check),
                    label: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Complete Visit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(value),
      ],
    );
  }

  Widget _buildPaymentOption(String value, String label) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _paymentMethod == value ? Colors.green : Colors.grey[300]!,
          width: _paymentMethod == value ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color:
            _paymentMethod == value ? Colors.green[50] : Colors.transparent,
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _paymentMethod,
        onChanged: (val) {
          setState(() {
            _paymentMethod = val ?? 'cash';
          });
        },
        title: Text(label),
        activeColor: Colors.green,
      ),
    );
  }

  Future<void> _submitCompletion() async {
    // Validate notes
    if (_notesController.text.isEmpty) {
      _showError('Please add visit notes');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Update appointment in Firestore
      await FirebaseFirestore.instance
          .collection('home_visit_appointments')
          .doc(widget.request.id)
          .update({
        'status': 'completed',
        'doctorStatus': 'completed',
        'visitCompletedAt': Timestamp.now(),
        'visitNotes': _notesController.text,
        'paymentMethod': _paymentMethod,
        'paymentStatus': _paymentMethod == 'online'
            ? 'pending'
            : 'pending', // Doctor marked it, now waiting for payment confirmation
        'updatedAt': Timestamp.now(),
      });

      // Send notification to user
      await NotificationService().sendNotification(
        receiverId: widget.request.userId,
        appointmentId: widget.request.id,
        title: 'Home Visit Completed! ✅',
        message:
            'Your home visit for ${widget.request.animalName} has been completed. Payment: Rs. ${widget.request.homeVisitFee}',
        type: 'home_visit_completed',
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Visit marked complete'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
}

// Helper function to show the completion dialog
void showHomeVisitCompletionDialog(
  BuildContext context,
  HomeVisitAppointmentModel request,
  VoidCallback onComplete,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => HomeVisitCompletionDialog(
      request: request,
      onComplete: onComplete,
    ),
  );
}
