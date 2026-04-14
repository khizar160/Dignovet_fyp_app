import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/appointment_model.dart';

/// Enhanced appointment notification widget with full details
/// Shows appointment info, timing, and action buttons
class AppointmentNotificationCard extends StatelessWidget {
  final AppointmentModel appointment;
  final String doctorName;
  final String notificationType; // 'approval', 'reminder_15min', 'started', 'ended'
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const AppointmentNotificationCard({
    required this.appointment,
    required this.doctorName,
    required this.notificationType,
    this.onTap,
    this.onDismiss,
    super.key,
  });

  String _getTitle() {
    switch (notificationType) {
      case 'approval':
        return '✅ Appointment Approved';
      case 'reminder_15min':
        return '⏰ Appointment in 15 Minutes';
      case 'started':
        return '🎯 Consultation Starting Now';
      case 'ended':
        return '✅ Consultation Complete';
      default:
        return '📋 Appointment Update';
    }
  }

  String _getMessage() {
    switch (notificationType) {
      case 'approval':
        return 'Dr. $doctorName has approved your appointment for ${appointment.animalName}';
      case 'reminder_15min':
        return 'Your appointment with Dr. $doctorName is starting in 15 minutes!';
      case 'started':
        return 'Consultation with Dr. $doctorName is now live!';
      case 'ended':
        return 'Your consultation has ended. Please rate your experience.';
      default:
        return 'Update for your appointment';
    }
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getAccentColor() {
    switch (notificationType) {
      case 'approval':
        return const Color(0xFF4CAF50);
      case 'reminder_15min':
        return const Color(0xFFFFC107);
      case 'started':
        return const Color(0xFF2196F3);
      case 'ended':
        return const Color(0xFF00796B);
      default:
        return const Color(0xFF00796B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor();
    final formattedDate = _formatDate(appointment.date);
    final formattedTime = _formatTime(appointment.time);

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: accentColor, width: 6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getHeaderIcon(),
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTitle(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getMessage(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDismiss != null)
                    GestureDetector(
                      onTap: onDismiss,
                      child: Icon(Icons.close, color: Colors.grey[400], size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Appointment details box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    // Row 1: Date & Time
                    _detailRow(
                      icon: Icons.calendar_today,
                      label: 'Date & Time',
                      value: '$formattedDate at $formattedTime',
                    ),
                    const SizedBox(height: 10),

                    // Row 2: Pet
                    _detailRow(
                      icon: Icons.pets,
                      label: 'Pet',
                      value: appointment.animalName,
                    ),
                    const SizedBox(height: 10),

                    // Row 3: Consultation Type
                    _detailRow(
                      icon: appointment.consultationType == 'online'
                          ? Icons.video_call
                          : Icons.home,
                      label: 'Type',
                      value: appointment.consultationType == 'online'
                          ? 'Online Consultation'
                          : 'Home Visit',
                    ),
                    const SizedBox(height: 10),

                    // Row 4: Amount
                    _detailRow(
                      icon: Icons.payments,
                      label: 'Fee',
                      value: '${appointment.paymentAmount} PKR',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Problem description (if exists)
              if (appointment.problem.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Problem/Concern',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        appointment.problem,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

              // Action button
              if (onTap != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _getButtonText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getHeaderIcon() {
    switch (notificationType) {
      case 'approval':
        return Icons.check_circle;
      case 'reminder_15min':
        return Icons.access_time;
      case 'started':
        return Icons.play_circle;
      case 'ended':
        return Icons.done_all;
      default:
        return Icons.notifications;
    }
  }

  String _getButtonText() {
    switch (notificationType) {
      case 'approval':
        return 'View Chat';
      case 'reminder_15min':
        return 'Open Appointment';
      case 'started':
        return 'Start Chat';
      case 'ended':
        return 'Rate Experience';
      default:
        return 'View Details';
    }
  }
}

/// Formatted Doctor Available Slots Display
class DoctorAvailableSlotsWidget extends StatelessWidget {
  final List<String> availableSlots; // Format: "HH:MM"
  final Function(String) onSlotSelected;
  final bool isLoading;

  const DoctorAvailableSlotsWidget({
    required this.availableSlots,
    required this.onSlotSelected,
    this.isLoading = false,
    super.key,
  });

  String _formatSlot(String timeString) {
    try {
      // Handle time range format: "10:00-11:00" → extract start time "10:00"
      final timeStart = timeString.contains('-')
          ? timeString.split('-')[0]
          : timeString;
      
      final parts = timeStart.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          height: 100,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      );
    }

    if (availableSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No Available Slots',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check back later for available times',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: availableSlots.length,
      itemBuilder: (context, index) {
        final slot = availableSlots[index];
        final formattedSlot = _formatSlot(slot);

        return GestureDetector(
          onTap: () => onSlotSelected(slot),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00796B),
                width: 2,
              ),
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                formattedSlot,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00796B),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Enhanced Appointment Selection with formatted slots
class AppointmentDateTimeSelector extends StatefulWidget {
  final Function(DateTime date, String time) onSelected;

  const AppointmentDateTimeSelector({
    required this.onSelected,
    super.key,
  });

  @override
  State<AppointmentDateTimeSelector> createState() => _AppointmentDateTimeSelectorState();
}

class _AppointmentDateTimeSelectorState extends State<AppointmentDateTimeSelector> {
  DateTime? selectedDate;
  String? selectedTime;

  // Sample available slots (in 30-minute intervals)
  final List<String> availableSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
  ];

  String _formatTimeSlot(String timeString) {
    try {
      // Handle time range format: "10:00-11:00" → extract start time "10:00"
      final timeStart = timeString.contains('-')
          ? timeString.split('-')[0]
          : timeString;
      
      final parts = timeStart.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selector
            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[100],
                foregroundColor: const Color(0xFF00796B),
              ),
              child: Text(
                selectedDate != null
                    ? '📅 ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                    : '📅 Pick a date',
              ),
            ),
            const SizedBox(height: 24),

            // Time Selector
            const Text(
              'Select Time (Doctor\'s Available Slots)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: availableSlots.length,
              itemBuilder: (context, index) {
                final slot = availableSlots[index];
                final isSelected = selectedTime == slot;
                final formattedSlot = _formatTimeSlot(slot);

                return GestureDetector(
                  onTap: () => setState(() => selectedTime = slot),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00796B),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? const Color(0xFF00796B).withOpacity(0.1)
                          : Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        formattedSlot,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF00796B)
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Confirmation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedDate != null && selectedTime != null
                    ? () {
                        widget.onSelected(selectedDate!, selectedTime!);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm Appointment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
