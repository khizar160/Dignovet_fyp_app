import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/model/app_user.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/services/chat_services/chat_services.dart';
import 'package:flutter_application_1/services/firebase_authentication/auth_api.dart';
import 'package:flutter_application_1/view/User/ChatScreen.dart';
import 'package:flutter_application_1/utils/appointment_time_parser.dart';
import 'package:flutter_application_1/helpers/appointment_status_helper.dart';

class DoctorChatListScreen extends StatefulWidget {
  const DoctorChatListScreen({super.key});

  @override
  State<DoctorChatListScreen> createState() => _DoctorChatListScreenState();
}

class _DoctorChatListScreenState extends State<DoctorChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Theme colors
  static const Color _primaryTeal = Color(0xFF00796B);
  static const Color _lightTeal = Color(0xFF4DB6AC);
  static const Color _scaffoldBg = Color(0xFFF5F7FA);
  static const Color _darkGrey = Color(0xFF2C3E50);

  // Gradients
  static final LinearGradient _headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_primaryTeal, _lightTeal.withOpacity(0.3), Colors.white],
    stops: const [0.0, 0.3, 0.5],
  );

  @override
  Widget build(BuildContext context) {
    final doctorId = AuthService.currentUser?.uid;

    debugPrint('[DoctorChat] 🟢 Building doctor chat list - doctorId: $doctorId');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: _headerGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildPatientList(doctorId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.search,
                      color: Colors.white, size: 24),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Consultations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your appointments & patients',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList(String? doctorId) {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          color: _scaffoldBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('appointments')
              .where('doctorId', isEqualTo: doctorId)
              .where('status', whereIn: ['pending', 'approved', 'in-progress', 'completed'])
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, appointmentSnapshot) {
            if (!appointmentSnapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: _primaryTeal),
              );
            }

            final appointments = appointmentSnapshot.data!.docs;

            if (appointments.isEmpty) {
              return _buildEmptyState();
            }

            // Group by user and keep the latest appointment
            final Map<String, AppointmentModel> latestByUser = {};
            for (var doc in appointments) {
              final appointment = AppointmentModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
              
              // Keep only the latest appointment per user
              if (!latestByUser.containsKey(appointment.userId) ||
                  appointment.date.toDate().isAfter(
                      latestByUser[appointment.userId]!.date.toDate())) {
                latestByUser[appointment.userId] = appointment;
              }
            }

            // Fetch all users once
            return FutureBuilder<Map<String, AppUser>>(
              future: _fetchAllUsers(latestByUser.keys.toList()),
              builder: (context, userCacheSnapshot) {
                if (!userCacheSnapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: _primaryTeal),
                  );
                }

                final userCache = userCacheSnapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async {
                    // Rebuild the stream
                    setState(() {});
                    return Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: latestByUser.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final userId = latestByUser.keys.elementAt(index);
                      final appointment = latestByUser[userId]!;
                      final user = userCache[userId];

                      if (user == null) return const SizedBox.shrink();

                      return _buildPatientCard(
                        context,
                        user,
                        appointment,
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, AppUser>> _fetchAllUsers(List<String> userIds) async {
    final userCache = <String, AppUser>{};
    
    try {
      for (final userId in userIds) {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          userCache[userId] = AppUser.fromMap(
            doc.data() as Map<String, dynamic>,
            userId,
          );
        }
      }
    } catch (e) {
      debugPrint('[DoctorChat] Error fetching users: $e');
    }
    
    return userCache;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryTeal.withOpacity(0.15),
                  _primaryTeal.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 80,
              color: _primaryTeal,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'No Appointments Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _darkGrey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pending or approved appointments will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(
    BuildContext context,
    AppUser user,
    AppointmentModel appointment,
  ) {
    final isInProgress = appointment.status.toLowerCase() == 'in-progress';
    final isCompleted = appointment.status.toLowerCase() == 'completed';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
            ? Colors.blue.withOpacity(0.3)
            : isInProgress 
              ? Colors.green.withOpacity(0.3)
              : _primaryTeal.withOpacity(0.1),
          width: (isCompleted || isInProgress) ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
              ? Colors.blue.withOpacity(0.15)
              : isInProgress
                ? Colors.green.withOpacity(0.15)
                : _primaryTeal.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openConsultation(context, user, appointment),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPatientHeader(user, appointment),
                if (isCompleted)
                  _buildCompletionBanner(appointment),
                if (isInProgress)
                  _buildConsultationCountdown(appointment),
                const SizedBox(height: 12),
                Divider(color: Colors.grey[200], height: 1),
                const SizedBox(height: 12),
                _buildAppointmentDetails(appointment),
                const SizedBox(height: 12),
                _buildConsultationButton(context, user, appointment),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeader(AppUser user, AppointmentModel appointment) {
    return Row(
      children: [
        _buildAvatar(user),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _darkGrey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(appointment.status),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: user.online ? Colors.green : Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.online ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.pets,
                    size: 14,
                    color: _primaryTeal,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      appointment.animalName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _primaryTeal,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationCountdown(AppointmentModel appointment) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: StreamBuilder<int>(
        stream: Stream.periodic(const Duration(seconds: 1), (_) => 0),
        builder: (context, snapshot) {
          final endTime = appointment.consultationEndTime?.toDate();
          if (endTime == null) return const SizedBox.shrink();

          final timeRemaining = endTime.difference(DateTime.now());
          if (timeRemaining.isNegative) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  const Text(
                    'Consultation Completed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            );
          }

          final minutesLeft = timeRemaining.inMinutes;
          final secondsLeft = timeRemaining.inSeconds % 60;

          final isUrgent = minutesLeft < 5;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isUrgent ? Colors.orange.withOpacity(0.15) : Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isUrgent ? Colors.orange : Colors.amber,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_bottom,
                  size: 16,
                  color: isUrgent ? Colors.orange : Colors.amber[700],
                ),
                const SizedBox(width: 8),
                Text(
                  '⏱️ ${minutesLeft}m ${secondsLeft}s remaining',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isUrgent ? Colors.orange : Colors.amber[900],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompletionBanner(AppointmentModel appointment) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 18, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              '✅ Appointment Completed',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(AppUser user) {
    return Stack(
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                _primaryTeal.withOpacity(0.2),
                _primaryTeal.withOpacity(0.1),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: user.imageUrl.isNotEmpty
                ? Image.network(
                    user.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.person_rounded,
                        size: 32,
                        color: _primaryTeal,
                      );
                    },
                  )
                : const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: _primaryTeal,
                  ),
          ),
        ),
        if (user.online)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = AppointmentStatusHelper.getStatusColor(status);
    final label = AppointmentStatusHelper.getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAppointmentDetails(AppointmentModel appointment) {
    final slotDuration = appointment.slotDuration ?? 30;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                Icons.calendar_today,
                '📅 ${_formatDate(appointment.date.toDate())}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                Icons.access_time,
                '⏰ ${appointment.time}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                Icons.schedule,
                '⏳ ${slotDuration}m slot',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                Icons.note_outlined,
                '📝 ${appointment.problem.length > 15 ? appointment.problem.substring(0, 15) + '...' : appointment.problem}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _primaryTeal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: _primaryTeal,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _primaryTeal,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationButton(
    BuildContext context,
    AppUser user,
    AppointmentModel appointment,
  ) {
    // Parse actual appointment time range using utility function
    final appointmentDate = appointment.date.toDate();
    final timeRange = parseAppointmentTimeRange(
      appointment.time,
      appointmentDate: appointmentDate,
    );
    final startTime = timeRange['start']!;
    final endTime = timeRange['end']!;

    final isInProgress = appointment.status.toLowerCase() == 'in-progress';

    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) => 0),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final timeUntilStart = startTime.difference(now);
        final timeUntilEnd = endTime.difference(now);
        
        // Can start if current time is at or after the slot start time
        final canStart = now.isAfter(startTime) || now.isAtSameMomentAs(startTime);
        // Has ended if current time is after the slot end time
        final hasEnded = now.isAfter(endTime);

        // Send notification once when appointment time arrives
        _notifyWhenAppointmentStarts(appointment, canStart, timeUntilStart);

        debugPrint(
          '[DoctorChat] ⏰ Appointment Start: ${startTime.toString()}, End: ${endTime.toString()}, Now: ${now.toString()}, Can start: $canStart, Time left: ${timeUntilEnd.inMinutes}m',
        );

        return Column(
          children: [
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: (canStart || isInProgress) && !hasEnded
                      ? [_primaryTeal, _primaryTeal.withOpacity(0.8)]
                      : [Colors.grey[400]!, Colors.grey[500]!],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: (canStart || isInProgress) && !hasEnded
                  ? [
                      BoxShadow(
                        color: _primaryTeal.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (canStart || isInProgress) && !hasEnded
                      ? () => _openConsultation(context, user, appointment)
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isInProgress ? Icons.phone_in_talk : Icons.chat_bubble_outline,
                        color: (canStart || isInProgress) && !hasEnded ? Colors.white : Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        hasEnded ? 'Consultation Ended' : (isInProgress ? 'Continue Consultation' : 'Start Consultation'),
                        style: TextStyle(
                          color: (canStart || isInProgress) && !hasEnded ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!canStart && !isInProgress && !hasEnded)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _buildCountdownText(timeUntilStart, appointment.time),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (canStart && !hasEnded && timeUntilEnd.inSeconds > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Remaining: ${getCountdownString(timeUntilEnd.inSeconds)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (hasEnded)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Time slot has ended',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Build countdown text showing time remaining until appointment
  String _buildCountdownText(Duration timeUntilStart, String timeSlot) {
    if (timeUntilStart.isNegative) {
      return '⏳ Appointment time has passed';
    }
    
    final minutes = timeUntilStart.inMinutes;
    final seconds = timeUntilStart.inSeconds % 60;
    
    // Extract start time from slot (e.g., "10:00-11:00" -> "10:00")
    final startTime = timeSlot.contains('-') ? timeSlot.split('-')[0] : timeSlot;
    
    if (minutes > 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '⏳ Starts in ${hours}h ${remainingMinutes}m (at $startTime)';
    } else if (minutes > 0) {
      return '⏳ Starts in ${minutes}m ${seconds}s (at $startTime)';
    } else {
      return '⏳ Starts in ${seconds}s (at $startTime)';
    }
  }

  /// Track and notify when appointment time arrives
  final Map<String, bool> _appointmentNotificationSent = {};

  void _notifyWhenAppointmentStarts(
    AppointmentModel appointment,
    bool canStart,
    Duration timeUntilStart,
  ) {
    // Only send notification once per appointment
    if (canStart && !(_appointmentNotificationSent[appointment.id] ?? false)) {
      _appointmentNotificationSent[appointment.id] = true;
      
      debugPrint('[DoctorChat] 🔔 Appointment time reached! Sending notification for ${appointment.id}');
      
      // Schedule snackbar after frame is rendered (not during build)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🟢 Appointment is ready to start!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  Future<void> _openConsultation(
    BuildContext context,
    AppUser user,
    AppointmentModel appointment,
  ) async {
    debugPrint(
        '[DoctorChat] 🔓 Opening generic chat with patient: ${user.name}, userId: ${user.id}');

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          receiverId: user.id,
          receiverName: user.name,
          receiverImage: user.imageUrl,
          isOnline: user.online,
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
}