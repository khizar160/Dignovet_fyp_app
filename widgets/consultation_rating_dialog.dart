import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/model/app_user.dart';
import 'package:flutter_application_1/services/consultation_service.dart';

class ConsultationRatingDialog extends StatefulWidget {
  final AppointmentModel appointment;
  final AppUser user;
  final VoidCallback? onRatingSubmitted;
  final VoidCallback? onRebookPressed;
  final VoidCallback? onHomePressed;

  const ConsultationRatingDialog({
    required this.appointment,
    required this.user,
    this.onRatingSubmitted,
    this.onRebookPressed,
    this.onHomePressed,
    super.key,
  });

  @override
  State<ConsultationRatingDialog> createState() => _ConsultationRatingDialogState();
}

class _ConsultationRatingDialogState extends State<ConsultationRatingDialog> {
  final ConsultationService _consultationService = ConsultationService();
  
  int doctorRating = 0;
  int appRating = 0;
  String? doctorFeedback;
  String? appFeedback;
  bool isSubmitting = false;
  bool isCompleted = false;

  final doctorFeedbackController = TextEditingController();
  final appFeedbackController = TextEditingController();

  @override
  void dispose() {
    doctorFeedbackController.dispose();
    appFeedbackController.dispose();
    super.dispose();
  }

  Future<void> submitRating() async {
    if (doctorRating == 0 || appRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate both the doctor and app')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final success = await _consultationService.submitCompleteRating(
        appointmentId: widget.appointment.id,
        appointment: widget.appointment,
        user: widget.user,
        doctorRating: doctorRating,
        appRating: appRating,
        doctorFeedback: doctorFeedbackController.text.isEmpty 
            ? null 
            : doctorFeedbackController.text,
        appFeedback: appFeedbackController.text.isEmpty 
            ? null 
            : appFeedbackController.text,
      );

      if (mounted) {
        setState(() => isSubmitting = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Thank you for your feedback!'),
              backgroundColor: Color(0xFF00796B),
            ),
          );
          
          setState(() => isCompleted = true);
          widget.onRatingSubmitted?.call();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit rating')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget buildStarRating(
    int currentRating,
    Function(int) onRatingChanged,
    String label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => onRatingChanged(index + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index < currentRating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFF9A825),
                  size: 32,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00796B),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✅ Consultation Complete',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Help us improve by sharing your feedback',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (!isCompleted) ...[
                // Doctor Rating
                buildStarRating(
                  doctorRating,
                  (rating) => setState(() => doctorRating = rating),
                  '⭐ Rate Dr. (Skill, Manner, Time)',
                ),
                const SizedBox(height: 16),

                // Doctor Feedback
                TextField(
                  controller: doctorFeedbackController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Optional: Comments about the doctor...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 20),

                // App Rating
                buildStarRating(
                  appRating,
                  (rating) => setState(() => appRating = rating),
                  '⭐ Rate DiagnoVet App (Ease, Features)',
                ),
                const SizedBox(height: 16),

                // App Feedback
                TextField(
                  controller: appFeedbackController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Optional: App feedback & suggestions...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 24),

                // Info Message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '💬 After submitting: Chat becomes read-only for you. Doctor can still read all messages and provide additional guidance.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF00796B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF00796B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : submitRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00796B),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Rating',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Success State with Next Steps
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Rating Submitted Successfully!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thank you for your feedback. What would you like to do next?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Rebook Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onRebookPressed,
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Book Another Appointment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Home Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onHomePressed ?? () => Navigator.pop(context),
                          icon: const Icon(Icons.home),
                          label: const Text('Go Back Home'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00796B),
                            side: const BorderSide(color: Color(0xFF00796B), width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

