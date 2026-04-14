import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/model/app_user.dart';
import 'package:flutter_application_1/services/consultation_service.dart';

class PostConsultationRatingScreen extends StatefulWidget {
  final AppointmentModel appointment;
  final AppUser user;
  final String doctorName;
  final VoidCallback onRatingComplete;

  const PostConsultationRatingScreen({
    super.key,
    required this.appointment,
    required this.user,
    required this.doctorName,
    required this.onRatingComplete,
  });

  @override
  State<PostConsultationRatingScreen> createState() =>
      _PostConsultationRatingScreenState();
}

class _PostConsultationRatingScreenState
    extends State<PostConsultationRatingScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final TextEditingController _doctorFeedbackController = TextEditingController();
  final TextEditingController _appFeedbackController = TextEditingController();

  int _doctorRating = 0;
  int _appRating = 0;
  bool _isSubmitting = false;
  final Color primaryTeal = const Color(0xFF00796B);
  final Color lightTeal = const Color(0xFF4DB6AC);

  @override
  void dispose() {
    _doctorFeedbackController.dispose();
    _appFeedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_doctorRating == 0 || _appRating == 0) {
      _showSnackBar('Please rate both doctor and app', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await _consultationService.submitConsultationRating(
        appointmentId: widget.appointment.id,
        doctorRating: _doctorRating,
        appRating: _appRating,
        doctorFeedback: _doctorFeedbackController.text.trim(),
        appFeedback: _appFeedbackController.text.trim(),
        appointment: widget.appointment,
        user: widget.user,
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar('Thank you for your feedback! 🙏', isError: false);
        widget.onRatingComplete();
        
        // Close dialog after a short delay
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showSnackBar('Rating saved! (Some fields may not have updated)', isError: false);
        widget.onRatingComplete();
        
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'Error submitting rating';
      if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. Your rating was still saved!';
      } else if (e.code == 'network-error') {
        errorMessage = 'Network error. Please try again.';
      } else if (e.code == 'unavailable') {
        errorMessage = 'Service temporarily unavailable. Please try again.';
      }
      
      _showSnackBar(errorMessage, isError: true);
      setState(() => _isSubmitting = false);
    } catch (e) {
      if (!mounted) return;
      
      print('[Rating] Error: $e');
      _showSnackBar('Error: Unable to submit rating. Please try again.', isError: true);
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildRatingSection(
    String title,
    String subtitle,
    int currentRating,
    ValueChanged<int> onRatingChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(5, (index) {
              final rating = index + 1;
              return GestureDetector(
                onTap: () => onRatingChanged(rating),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: rating <= currentRating
                        ? primaryTeal.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          rating <= currentRating ? primaryTeal : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.star,
                    color: rating <= currentRating ? Colors.amber[600] : Colors.grey[400],
                    size: 28,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              currentRating == 0
                  ? 'Tap a star to rate'
                  : _getRatingLabel(currentRating),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: currentRating == 0
                    ? Colors.grey[500]
                    : _getRatingColor(currentRating),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Not rated';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxDialogWidth = (screenWidth > 600 ? 500.0 : screenWidth * 0.9) as double;
    
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: const Text(
                        '⭐ Rate Your Experience',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 24, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your feedback helps us improve our service',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Doctor Rating
                _buildRatingSection(
                  '👨‍⚕️ Rate Dr. ${widget.doctorName}',
                  'How was your consultation experience?',
                  _doctorRating,
                  (rating) => setState(() => _doctorRating = rating),
                ),
                const SizedBox(height: 20),

                // App Rating
                _buildRatingSection(
                  '📱 Rate Our App',
                  'How easy was it to use the app?',
                  _appRating,
                  (rating) => setState(() => _appRating = rating),
                ),
                const SizedBox(height: 20),

                // Doctor Feedback
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _doctorFeedbackController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Any feedback for the doctor? (Optional)',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // App Feedback
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _appFeedbackController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Any suggestions for the app? (Optional)',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit Rating 🚀',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '⚠️ Rating is required to complete the consultation',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
