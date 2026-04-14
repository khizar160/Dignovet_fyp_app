// import 'dart:io';
// import 'dart:developer'; // <-- for logging
// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/model/chat_model.dart';
// import 'package:flutter_application_1/provider/chat_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:image_picker/image_picker.dart';

// class ChatScreen extends StatefulWidget {
//   final String receiverId;
//   final String receiverName;
//   final String receiverImage;
//   final bool isOnline;

//   const ChatScreen({
//     super.key,
//     required this.receiverId,
//     required this.receiverName,
//     required this.receiverImage,
//     required this.isOnline,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final ImagePicker _picker = ImagePicker();

//   String get _myId => FirebaseAuth.instance.currentUser!.uid;

//   // ---------------- Send text message ----------------
//   void _sendMessage(String text) async {
//     if (text.trim().isEmpty) return;

//     final msg = ChatMessage(
//       id: '',
//       senderId: _myId,
//       receiverId: widget.receiverId,
//       text: text,
//       type: MessageType.text,
//       timestamp: DateTime.now(),
//     );

//     log('[ChatScreen] Sending text message: ${msg.text}');

//     try {
//       await context.read<ChatProvider>().sendText(msg);
//       log('[ChatScreen] Text message sent successfully');
//     } catch (e) {
//       log('[ChatScreen] Error sending text message: $e');
//     }

//     _messageController.clear();
//     _scrollToBottom();
//   }

//   // ---------------- Send media (image/video) ----------------
//   void _sendMedia(MessageType type) async {
//     try {
//       final XFile? file = await (_picker.pickImage(
//           source: type == MessageType.image ? ImageSource.gallery : ImageSource.camera,
//           maxWidth: 1080,
//           maxHeight: 1080));

//       if (file == null) {
//         log('[ChatScreen] No file selected for media');
//         return;
//       }

//       final mediaFile = File(file.path);
//       log('[ChatScreen] Selected file: ${mediaFile.path}');

//       await context.read<ChatProvider>().sendMedia(_myId, widget.receiverId, mediaFile, type);
//       log('[ChatScreen] Media uploaded and message sent successfully');

//       _scrollToBottom();
//     } catch (e) {
//       log('[ChatScreen] Error sending media: $e');
//     }
//   }

//   // ---------------- Scroll to bottom ----------------
//   void _scrollToBottom() {
//     Future.delayed(const Duration(milliseconds: 200), () {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//         log('[ChatScreen] Scrolled to bottom');
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     log('[ChatScreen] Building chat screen for receiver: ${widget.receiverName}');
//     return Scaffold(
//       backgroundColor: const Color(0xFFEFF5F4),
//       appBar: _buildAppBar(),
//       body: Column(
//         children: [
//           Expanded(child: _buildMessages()),
//           _buildInput(),
//         ],
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       elevation: 1,
//       backgroundColor: Colors.teal,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back),
//         onPressed: () => Navigator.pop(context),
//       ),
//       title: Row(
//         children: [
//           CircleAvatar(
//             radius: 20,
//             backgroundImage: widget.receiverImage.isNotEmpty
//                 ? NetworkImage(widget.receiverImage)
//                 : null,
//             backgroundColor: Colors.white,
//             child: widget.receiverImage.isEmpty
//                 ? const Icon(Icons.person, color: Colors.teal)
//                 : null,
//           ),
//           const SizedBox(width: 12),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(widget.receiverName,
//                   style: const TextStyle(
//                       fontSize: 16, fontWeight: FontWeight.bold)),
//               Text(
//                 widget.isOnline ? 'Online' : 'Offline',
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: widget.isOnline ? Colors.greenAccent : Colors.white70,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // ---------------- Build message list ----------------
//   Widget _buildMessages() {
//     return StreamBuilder<List<ChatMessage>>(
//       stream: context.read<ChatProvider>().getMessages(_myId, widget.receiverId),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
//         final messages = snapshot.data!;
//         log('[ChatScreen] Loaded ${messages.length} messages');
//         return ListView.builder(
//           controller: _scrollController,
//           padding: const EdgeInsets.all(14),
//           itemCount: messages.length,
//           itemBuilder: (_, i) => _buildBubble(messages[i]),
//         );
//       },
//     );
//   }

//   // ---------------- Build chat bubble ----------------
//   Widget _buildBubble(ChatMessage msg) {
//     final isMe = msg.senderId == _myId;
//     final bgColor = isMe ? Colors.teal : Colors.white;
//     final align = isMe ? Alignment.centerRight : Alignment.centerLeft;

//     return Align(
//       alignment: align,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 6),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//         constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
//         decoration: BoxDecoration(
//           color: bgColor,
//           borderRadius: BorderRadius.circular(18),
//           boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
//         ),
//         child: msg.type == MessageType.text
//             ? _textBubble(msg, isMe)
//             : _mediaBubble(msg, isMe),
//       ),
//     );
//   }

//   Widget _textBubble(ChatMessage msg, bool isMe) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(msg.text??'', style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
//         const SizedBox(height: 4),
//         Text(
//           _formatTime(msg.timestamp),
//           style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black45),
//         ),
//       ],
//     );
//   }

//   Widget _mediaBubble(ChatMessage msg, bool isMe) {
//     if (msg.type == MessageType.image) {
//       return Column(
//         children: [
//           Image.network(msg.mediaUrl ?? '', errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
//           const SizedBox(height: 4),
//           Text(_formatTime(msg.timestamp), style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black45)),
//         ],
//       );
//     } else {
//       return Container(); // fallback for unsupported media
//     }
//   }

//   Widget _buildInput() {
//     return SafeArea(
//       child: Container(
//         padding: const EdgeInsets.all(10),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
//         ),
//         child: Row(
//           children: [
//             IconButton(
//               icon: const Icon(Icons.image, color: Colors.teal),
//               onPressed: () => _sendMedia(MessageType.image),
//             ),
//             IconButton(
//               icon: const Icon(Icons.videocam, color: Colors.teal),
//               onPressed: () => _sendMedia(MessageType.video),
//             ),
//             Expanded(
//               child: TextField(
//                 controller: _messageController,
//                 minLines: 1,
//                 maxLines: 4,
//                 decoration: InputDecoration(
//                   hintText: 'Type a message...',
//                   filled: true,
//                   fillColor: Colors.grey.shade100,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(30),
//                     borderSide: BorderSide.none,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 5),
//             CircleAvatar(
//               radius: 24,
//               backgroundColor: Colors.teal,
//               child: IconButton(
//                 icon: const Icon(Icons.send, color: Colors.white),
//                 onPressed: () => _sendMessage(_messageController.text),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatTime(DateTime t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
// }

import 'dart:io';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/model/chat_model.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/model/app_user.dart';
import 'package:flutter_application_1/provider/chat_provider.dart';
import 'package:flutter_application_1/services/file_download_service.dart';
import 'package:flutter_application_1/services/consultation_service.dart';
import 'package:flutter_application_1/services/chat_permission_checker.dart';
import 'package:flutter_application_1/utils/time_parser.dart';
import 'package:flutter_application_1/utils/appointment_time_parser.dart';
import 'package:flutter_application_1/view/User/post_consultation_rating_screen.dart';
import 'package:flutter_application_1/helpers/appointment_status_helper.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverImage;
  final bool isOnline;
  final String? appointmentId;
  final String? animalName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverImage,
    required this.isOnline,
    this.appointmentId,
    this.animalName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- DignoVet Theme Colors ---
  final Color primaryTeal = const Color(0xFF00796B);
  final Color mediumTeal = const Color(0xFF4DB6AC);
  final Color lightTeal = const Color(0xFF80CBC4);

  String get _myId => FirebaseAuth.instance.currentUser!.uid;
  bool _isDoctor = false;
  bool _isSendingPrescription = false;
  Map<String, dynamic>? _doctorData;

  // --- Consultation System State ---
  AppointmentModel? _appointment;
  ChatPermissionChecker? _permissionChecker;
  bool _canSendMessages = true;
  bool _canReadMessages = true;
  String? _restrictionMessage;
  bool _showRatingModal = false;
  bool _ratingCompleted = false;
  Timer? _appointmentCheckTimer;
  Timer? _restrictionUpdateTimer;
  bool _notificationShown5Min = false;
  bool _isStartingConsultation = false; // Loading state for start button

  static const String _menuClearChat = 'clear_chat';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
    _loadAppointmentData();
    // Removed duplicate _listenToChatPermissionChanges() - now handled in _listenToAppointmentStatusChanges()
    _listenToAppointmentStatusChanges();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _appointmentCheckTimer?.cancel();
    _restrictionUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAppointmentData() async {
    if (widget.appointmentId == null || widget.appointmentId!.isEmpty) {
      return;
    }

    try {
      final doc = await _firestore
          .collection('appointments')
          .doc(widget.appointmentId)
          .get();
      if (!doc.exists || !mounted) return;

      final apt = AppointmentModel.fromMap(
        doc.data() ?? {},
        widget.appointmentId!,
      );
      setState(() {
        _appointment = apt;
      });

      _loadPermissions();
      _startAppointmentEndCheck();
      _startAppointmentCountdownTimer();
    } catch (e) {
      log('[ChatScreen] Failed to load appointment: $e');
    }
  }

  Future<void> _loadPermissions() async {
    if (_appointment == null) return;

    try {
      // Get live status using helper
      final liveStatus = AppointmentStatusHelper.getLiveAppointmentStatus(
        _appointment!,
      );

      // Determine if user can send messages based on live status
      bool canSendMessages = false;
      bool canReadMessages = true;

      if (_isDoctor) {
        // Doctor can always send (unless declined/cancelled)
        canSendMessages = AppointmentStatusHelper.canDoctorChat(
          _appointment!.status,
        );
      } else {
        // User can send only during active appointment window
        canSendMessages = AppointmentStatusHelper.canUserSendMessage(
          _appointment!,
        );

        // User cannot read if declined
        if (liveStatus == 'declined' || liveStatus == 'cancelled') {
          canReadMessages = false;
        }
      }

      if (!mounted) return;

      setState(() {
        _canSendMessages = canSendMessages;
        _canReadMessages = canReadMessages;
        _restrictionMessage = AppointmentStatusHelper.getChatRestrictionMessage(
          _appointment!,
          isDoctor: _isDoctor,
        );
      });
    } catch (e) {
      log('[ChatScreen] Failed to load permissions: $e');
    }
  }

  bool _canSendBasedOnStatus() {
    if (_isDoctor) return true; // 🔥 Doctor can ALWAYS send

    if (_appointment == null) return false;
    final status = _appointment!.status.toLowerCase().trim();

    // User: _canSendMessages is set by _loadPermissions() and countdown timer
    // which call the async _isAppointmentTimeReached()
    // 🔧 FIXED: Allow both 'approved' (before start) and 'active' (during consultation)
    return (status == 'approved' || status == 'active') && _canSendMessages;
  }

  Duration? _getTimeUntilAppointment() {
    if (_appointment == null) return null;

    try {
      final appointmentDate = _appointment!.date.toDate();
      final timeText = _appointment!.time;

      final timeRange = parseAppointmentTimeRange(
        timeText,
        appointmentDate: appointmentDate,
      );

      final startTime = timeRange['start'] as DateTime?;
      if (startTime == null) return null;

      final now = DateTime.now();
      final remaining = startTime.difference(now);

      // If time has passed, return null
      if (remaining.isNegative) return null;

      return remaining;
    } catch (e) {
      log('[ChatScreen] Error calculating time until appointment: $e');
      return null;
    }
  }

  bool _canReadBasedOnStatus() {
    if (_appointment == null) return true;
    final status = _appointment!.status.toLowerCase().trim();

    // Cannot read if declined
    if (status == 'declined') return false;

    return true; // Can read for all other statuses
  }

  String? _getRestrictionMessage(bool isDoctor) {
    if (_appointment == null) return null;

    final status = _appointment!.status.toLowerCase().trim();

    // For DOCTOR: Show info only (no restrictions)
    if (isDoctor) {
      if (status == 'approved') {
        // Show countdown info for doctor too
        final timeUntil = _getTimeUntilAppointment();
        if (timeUntil != null && timeUntil.inSeconds > 0) {
          final hours = timeUntil.inHours;
          final minutes = timeUntil.inMinutes.remainder(60);
          final seconds = timeUntil.inSeconds.remainder(60);

          String timeStr = '';
          if (hours > 0) {
            timeStr = '$hours hour${hours > 1 ? 's' : ''} ${minutes}m';
          } else if (minutes > 0) {
            timeStr = '$minutes min${minutes > 1 ? 's' : ''} ${seconds}s';
          } else {
            timeStr = '${seconds}s';
          }

          return '⏰ Appointment starts in $timeStr';
        }
      }
      return null; // No message for other statuses
    }

    // For USER: Show restrictions and info
    // User-specific messages based on status
    if (status == 'pending') {
      return 'Chat will be available after doctor approval';
    } else if (status == 'completed') {
      return '✅ Appointment completed. You can view messages only';
    } else if (status == 'declined') {
      return '❌ This appointment has been declined';
    } else if (status == 'approved') {
      // 🔥 For approved appointments, show time until consultation
      final timeUntil = _getTimeUntilAppointment();
      if (timeUntil != null && timeUntil.inSeconds > 0) {
        final hours = timeUntil.inHours;
        final minutes = timeUntil.inMinutes.remainder(60);
        final seconds = timeUntil.inSeconds.remainder(60);

        String timeStr = '';
        if (hours > 0) {
          timeStr = '$hours hour${hours > 1 ? 's' : ''} ${minutes}m';
        } else if (minutes > 0) {
          timeStr = '$minutes min${minutes > 1 ? 's' : ''} ${seconds}s';
        } else {
          timeStr = '${seconds}s';
        }

        return '⏰ Your appointment starts in $timeStr - Chat will be enabled then';
      }
    }

    // No message for approved status when time has reached
    return null;
  }

  void _startAppointmentCountdownTimer() {
    if (_appointment == null) return;

    _restrictionUpdateTimer?.cancel();
    _restrictionUpdateTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (!mounted || _appointment == null) return;

      final liveStatus = AppointmentStatusHelper.getLiveAppointmentStatus(
        _appointment!,
      );
      final oldCanSend = _canSendMessages;

      // Update can send based on current live status
      bool newCanSend = false;
      if (_isDoctor) {
        newCanSend = AppointmentStatusHelper.canDoctorChat(
          _appointment!.status,
        );
      } else {
        newCanSend = AppointmentStatusHelper.canUserSendMessage(_appointment!);
      }

      setState(() {
        _canSendMessages = newCanSend;
        _restrictionMessage = AppointmentStatusHelper.getChatRestrictionMessage(
          _appointment!,
          isDoctor: _isDoctor,
        );
      });

      // Show notification when user can start chatting
      if (!oldCanSend && newCanSend && !_isDoctor && liveStatus == 'active') {
        _showNotification(
          title: 'Consultation Started',
          body:
              'Your consultation is now active! You can start messaging the doctor.',
          icon: Icons.call_received_rounded,
        );
      }
    });
  }

  void _startAppointmentEndCheck() {
    if (_appointment == null || _ratingCompleted) return;

    _appointmentCheckTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      if (!mounted || _appointment == null) return;

      final endTime = _appointment!.consultationEndTime?.toDate();
      if (endTime == null) return;

      final now = DateTime.now();
      final secondsRemaining =
          AppointmentStatusHelper.getSecondsRemainingInAppointment(
            _appointment!,
          );
      final minutesRemaining = Duration(seconds: secondsRemaining).inMinutes;

      // 5 minute warning (only for user, not doctor)
      if (minutesRemaining == 5 && !_notificationShown5Min && !_isDoctor) {
        setState(() {
          _notificationShown5Min = true;
        });
        final slotDuration = _appointment?.slotDuration ?? 30;
        _showNotification(
          title: '⏰ Consultation Ending Soon',
          body:
              'Your $slotDuration-minute consultation will end in 5 minutes. Wrap up your discussion.',
          icon: Icons.timer_outlined,
        );
        log(
          '[ChatScreen] 🔔 5-minute warning shown to user (slot duration: $slotDuration min)',
        );
      }

      // Appointment ended - auto-complete and show rating (only for user, not doctor)
      if (now.isAfter(endTime) && !_showRatingModal && !_isDoctor) {
        // Auto-complete appointment in Firebase
        await AppointmentStatusHelper.completeAppointmentIfNeeded(
          _appointment!.id,
          _appointment!,
        );

        _appointmentCheckTimer?.cancel();
        _restrictionUpdateTimer?.cancel();
        _showRatingModalIfNeeded();
      }
    });

    // Start timer to update restriction message every second (for countdown display)
    _restrictionUpdateTimer?.cancel();
    _restrictionUpdateTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (!mounted || _appointment == null) return;
      setState(() {
        _restrictionMessage = AppointmentStatusHelper.getChatRestrictionMessage(
          _appointment!,
          isDoctor: _isDoctor,
        );
      });
    });
  }

  Future<void> _showRatingModalIfNeeded() async {
    if (_appointment == null || _ratingCompleted || !mounted) return;

    try {
      log(
        '[ChatScreen] Checking rating status for appointment: ${_appointment!.id}',
      );

      final doc = await _firestore
          .collection('appointments')
          .doc(_appointment!.id)
          .get();

      if (!doc.exists || !mounted) {
        log('[ChatScreen] Appointment doc does not exist or widget unmounted');
        return;
      }

      final userRated = doc.get('userRated') as bool? ?? false;
      if (!userRated && !_ratingCompleted) {
        log('[ChatScreen] Showing rating modal immediately');
        if (mounted) {
          setState(() {
            _showRatingModal = true;
          });
          // Show immediately without delay
          Future.microtask(() => _showRatingDialog());
        }
      }
    } catch (e) {
      log('[ChatScreen] Failed to check rating status: $e');
    }
  }

  void _showRatingDialog() {
    if (!mounted || _appointment == null) return;

    // Load current user for rating submission
    _firestore
        .collection('users')
        .doc(_myId)
        .get()
        .then((userDoc) {
          if (!mounted || !userDoc.exists) {
            log('[ChatScreen] User doc not found or widget unmounted');
            return;
          }

          final userData = AppUser.fromMap(userDoc.data() ?? {}, _myId);

          if (!mounted) return;

          log('[ChatScreen] Displaying rating dialog');
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => PostConsultationRatingScreen(
              appointment: _appointment!,
              user: userData,
              doctorName: widget.receiverName,
              onRatingComplete: () {
                log('[ChatScreen] Rating completed');
                if (mounted) {
                  setState(() {
                    _ratingCompleted = true;
                  });
                }
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          );
        })
        .catchError((e) {
          log('[ChatScreen] Failed to load user for rating: $e');
          if (mounted) {
            _showSnackBar('Unable to submit rating. Please try again.');
          }
        });
  }

  void _listenToChatPermissionChanges() {
    if (widget.appointmentId == null || widget.appointmentId!.isEmpty) return;

    _firestore
        .collection('appointments')
        .doc(widget.appointmentId)
        .snapshots()
        .listen((doc) async {
          if (!mounted) return;

          if (doc.exists) {
            final newAppointment = AppointmentModel.fromMap(
              doc.data() ?? {},
              widget.appointmentId!,
            );
            final oldCanSend = _canSendMessages;

            // Use helper to determine if user can send
            bool newCanSend = false;
            if (_isDoctor) {
              newCanSend = AppointmentStatusHelper.canDoctorChat(
                newAppointment.status,
              );
            } else {
              newCanSend = AppointmentStatusHelper.canUserSendMessage(
                newAppointment,
              );
            }

            if (!mounted) return;

            setState(() {
              _appointment = newAppointment;
              _canSendMessages = newCanSend;
              _restrictionMessage =
                  AppointmentStatusHelper.getChatRestrictionMessage(
                    newAppointment,
                    isDoctor: _isDoctor,
                  );
            });

            // Show notification when appointment time arrives for user
            if (!oldCanSend && newCanSend && !_isDoctor) {
              final liveStatus =
                  AppointmentStatusHelper.getLiveAppointmentStatus(
                    newAppointment,
                  );
              if (liveStatus == 'active') {
                _showNotification(
                  title: 'Consultation Starting',
                  body:
                      'Your consultation is now active! You can start messaging the doctor.',
                  icon: Icons.call_received_rounded,
                );
              }
            }
          }
        });
  }

  void _listenToAppointmentStatusChanges() {
    if (widget.appointmentId == null || widget.appointmentId!.isEmpty) return;

    _firestore.collection('appointments').doc(widget.appointmentId).snapshots().listen((
      doc,
    ) async {
      if (!mounted) return;

      if (doc.exists) {
        final newAppointment = AppointmentModel.fromMap(
          doc.data() ?? {},
          widget.appointmentId!,
        );
        final oldStatus = _appointment?.status;
        final newStatus = newAppointment.status.toLowerCase();

        // Get live statuses
        final oldLiveStatus = _appointment != null
            ? AppointmentStatusHelper.getLiveAppointmentStatus(_appointment!)
            : null;
        final newLiveStatus = AppointmentStatusHelper.getLiveAppointmentStatus(
          newAppointment,
        );

        // CRITICAL: Update permissions whenever appointment data changes
        bool newCanSend = false;
        if (_isDoctor) {
          newCanSend = AppointmentStatusHelper.canDoctorChat(
            newAppointment.status,
          );
        } else {
          newCanSend = AppointmentStatusHelper.canUserSendMessage(
            newAppointment,
          );
        }

        // Notification when appointment is approved
        if (newStatus == 'approved' && oldStatus != 'approved') {
          _showNotification(
            title: '✅ Appointment Approved!',
            body:
                'Your appointment has been approved. Chat will be enabled when the appointment time starts.',
            icon: Icons.thumb_up_outlined,
          );
          if (!_isDoctor) {
            _sendConsultationNotification(
              userId: _myId,
              title: 'Appointment Approved',
              body:
                  'Your appointment has been approved by Dr. ${widget.receiverName}',
              type: 'approved',
            );
          }
          log(
            '[ChatScreen] ✅ Appointment approved - user chat disabled until appointment starts (canSend: $newCanSend)',
          );
        }

        // Notification when appointment becomes ACTIVE (time window starts)
        if (newLiveStatus == 'active' && oldLiveStatus != 'active') {
          _showNotification(
            title: '🟢 Consultation Now Active',
            body:
                'Your appointment is now live! You can start messaging the doctor.',
            icon: Icons.phone_in_talk_outlined,
          );
          if (!_isDoctor) {
            _sendConsultationNotification(
              userId: _myId,
              title: 'Consultation Started',
              body:
                  'Your consultation is now active. You can start chatting with the doctor.',
              type: 'started',
            );
          }
          log(
            '[ChatScreen] 🟢 Consultation active - user chat enabled (canSend: $newCanSend)',
          );
        }

        // Notification 5 minutes before end
        final endTime = newAppointment.consultationEndTime?.toDate();
        if (endTime != null) {
          final now = DateTime.now();
          final minutesBefore = endTime.difference(now).inMinutes;

          if (minutesBefore == 5 && !_notificationShown5Min) {
            setState(() {
              _notificationShown5Min = true;
            });
            final slotDuration = newAppointment.slotDuration;
            _showNotification(
              title: '⏰ Consultation Ending Soon',
              body:
                  'Your $slotDuration-minute consultation will end in 5 minutes.',
              icon: Icons.timer_outlined,
            );
            _sendConsultationNotification(
              userId: _myId,
              title: 'Consultation Ending Soon',
              body: 'Your consultation will end in 5 minutes',
              type: 'ending_soon',
            );
            log('[ChatScreen] ⏰ Ending soon notification sent');
          }
        }

        // Appointment ended - auto-complete and show rating for users
        if (newLiveStatus == 'completed' &&
            oldLiveStatus != 'completed' &&
            !_showRatingModal &&
            !_ratingCompleted &&
            !_isDoctor) {
          log(
            '[ChatScreen] Consultation ended - auto-completing and triggering rating (canSend: $newCanSend)',
          );

          // Auto-complete in Firestore
          await AppointmentStatusHelper.completeAppointmentIfNeeded(
            newAppointment.id,
            newAppointment,
          );

          _showRatingModalIfNeeded();
        }

        if (!mounted) return;

        setState(() {
          _appointment = newAppointment;
          _canSendMessages = newCanSend;
          _canReadMessages = true; // User can always read (unless declined)
          if (newLiveStatus == 'declined') {
            _canReadMessages = false;
          }
          _restrictionMessage =
              AppointmentStatusHelper.getChatRestrictionMessage(
                newAppointment,
                isDoctor: _isDoctor,
              );
        });
      }
    });
  }

  void _showNotification({
    required String title,
    required String body,
    required IconData icon,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: primaryTeal,
        duration: const Duration(seconds: 15), // Increased from 6 to 15 seconds
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
      ),
    );

    log('[ChatScreen] 🔔 Notification: $title - $body');
  }

  Future<void> _sendConsultationNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type, // 'approved', 'started', 'ending_soon', 'ended'
        'appointmentId': _appointment?.id,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      log(
        '[ChatScreen] 📬 Notification saved to Firebase: $type for user $userId',
      );
    } catch (e) {
      log('[ChatScreen] Failed to save notification: $e');
    }
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final doc = await _firestore.collection('users').doc(_myId).get();
      if (!doc.exists) return;

      final data = doc.data() ?? {};
      final role = (data['role'] ?? '').toString().toLowerCase();

      if (!mounted) return;
      setState(() {
        _doctorData = data;
        _isDoctor = role == 'doctor';
      });
    } catch (e) {
      log('Failed to load current user profile: $e');
    }
  }

  // ---------------- Logic (Unchanged) ----------------
  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final msg = ChatMessage(
      id: '',
      senderId: _myId,
      receiverId: widget.receiverId,
      text: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );
    try {
      await context.read<ChatProvider>().sendText(msg);
    } catch (e) {
      log('Error: $e');
    }
    _messageController.clear();
    _scrollToBottom();
  }

  void _sendMedia(MessageType type) async {
    try {
      final XFile? file = await (_picker.pickImage(
        source: type == MessageType.image
            ? ImageSource.gallery
            : ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
      ));
      if (file == null) return;
      final mediaFile = File(file.path);
      await context.read<ChatProvider>().sendMedia(
        _myId,
        widget.receiverId,
        mediaFile,
        type,
      );
      _scrollToBottom();
    } catch (e) {
      log('Error: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showPrescriptionComposer() async {
    if (!_isDoctor) {
      _showSnackBar('Only doctors can send prescriptions.');
      return;
    }

    final doctorName = (_doctorData?['name'] ?? 'Doctor').toString();
    final specialization = (_doctorData?['specialization'] ?? '').toString();
    final clinicName =
        (_doctorData?['clinicName'] ??
                _doctorData?['clinic'] ??
                'DignoVet Clinic')
            .toString();
    final clinicAddress = (_doctorData?['clinicAddress'] ?? '').toString();
    final clinicPhone = (_doctorData?['phone'] ?? '').toString();

    final petOwnerController = TextEditingController(text: widget.receiverName);
    final animalNameController = TextEditingController(
      text: widget.animalName ?? '',
    );
    final complaintController = TextEditingController();
    final diagnosisController = TextEditingController();
    final medicinesController = TextEditingController();
    final testsController = TextEditingController();
    final adviceController = TextEditingController();
    final followUpController = TextEditingController();
    final notesController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_services_rounded, color: primaryTeal),
                      const SizedBox(width: 8),
                      const Text(
                        'Create Prescription',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$clinicName • $doctorName',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildPrescriptionField(
                    controller: petOwnerController,
                    label: 'Pet Owner Name',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Pet owner name is required'
                        : null,
                  ),
                  _buildPrescriptionField(
                    controller: animalNameController,
                    label: 'Pet Name',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Pet name is required'
                        : null,
                  ),
                  _buildPrescriptionField(
                    controller: complaintController,
                    label: 'Chief Complaint',
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Chief complaint is required'
                        : null,
                  ),
                  _buildPrescriptionField(
                    controller: diagnosisController,
                    label: 'Diagnosis',
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Diagnosis is required'
                        : null,
                  ),
                  _buildPrescriptionField(
                    controller: medicinesController,
                    label: 'Medicines / Dosage',
                    hint: 'Example: Tab XYZ 1-0-1 for 5 days',
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Medicines are required'
                        : null,
                  ),
                  _buildPrescriptionField(
                    controller: testsController,
                    label: 'Recommended Tests',
                    maxLines: 2,
                  ),
                  _buildPrescriptionField(
                    controller: adviceController,
                    label: 'Advice / Care Instructions',
                    maxLines: 2,
                  ),
                  _buildPrescriptionField(
                    controller: followUpController,
                    label: 'Follow-up (Days or Date)',
                    hint: 'e.g., 7 days or 26-03-2026',
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return null;
                      final dayRegex = RegExp(
                        r'^\d+\s*(day|days)?$',
                        caseSensitive: false,
                      );
                      final dateRegex = RegExp(
                        r'^\d{1,2}[-/]\d{1,2}[-/]\d{2,4}$',
                      );
                      if (dayRegex.hasMatch(value) ||
                          dateRegex.hasMatch(value)) {
                        return null;
                      }
                      return 'Use days (e.g., 7) or date (DD-MM-YYYY)';
                    },
                  ),
                  _buildPrescriptionField(
                    controller: notesController,
                    label: 'Additional Notes',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSendingPrescription
                          ? null
                          : () async {
                              if (!(formKey.currentState?.validate() ?? false))
                                return;
                              Navigator.pop(ctx);
                              await _generateAndSendPrescription(
                                doctorName: doctorName,
                                specialization: specialization,
                                clinicName: clinicName,
                                clinicAddress: clinicAddress,
                                clinicPhone: clinicPhone,
                                petOwnerName: petOwnerController.text.trim(),
                                petName: animalNameController.text.trim(),
                                complaint: complaintController.text.trim(),
                                diagnosis: diagnosisController.text.trim(),
                                medicines: medicinesController.text.trim(),
                                tests: testsController.text.trim(),
                                advice: adviceController.text.trim(),
                                followUpDate: followUpController.text.trim(),
                                notes: notesController.text.trim(),
                              );
                            },
                      icon: _isSendingPrescription
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(
                        _isSendingPrescription
                            ? 'Generating...'
                            : 'Generate PDF and Send in Chat',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF8F9FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _generateAndSendPrescription({
    required String doctorName,
    required String specialization,
    required String clinicName,
    required String clinicAddress,
    required String clinicPhone,
    required String petOwnerName,
    required String petName,
    required String complaint,
    required String diagnosis,
    required String medicines,
    required String tests,
    required String advice,
    required String followUpDate,
    required String notes,
  }) async {
    setState(() {
      _isSendingPrescription = true;
    });

    try {
      final doc = pw.Document();
      final now = DateTime.now();
      final signatureUrl =
          (_doctorData?['signatureUrl'] ??
                  _doctorData?['digitalSignatureUrl'] ??
                  _doctorData?['imageUrl'] ??
                  '')
              .toString();
      final stampUrl =
          (_doctorData?['stampUrl'] ?? _doctorData?['clinicStampUrl'] ?? '')
              .toString();

      final signatureImage = await _networkImageToMemory(signatureUrl);
      final stampImage = await _networkImageToMemory(stampUrl);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal700,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    clinicName,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Doctor: $doctorName ${specialization.isNotEmpty ? '($specialization)' : ''}',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11,
                    ),
                  ),
                  if (clinicAddress.isNotEmpty)
                    pw.Text(
                      clinicAddress,
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                  if (clinicPhone.isNotEmpty)
                    pw.Text(
                      'Phone: $clinicPhone',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Prescription',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Date: ${now.day}-${now.month}-${now.year}'),
            pw.Text('Pet Owner: $petOwnerName'),
            pw.Text('Pet Name: $petName'),
            pw.SizedBox(height: 12),
            _pdfSection('Chief Complaint', complaint),
            _pdfSection('Diagnosis', diagnosis),
            _pdfSection('Medicines / Dosage', medicines),
            _pdfSection('Recommended Tests', tests.isEmpty ? 'N/A' : tests),
            _pdfSection(
              'Advice / Care Instructions',
              advice.isEmpty ? 'N/A' : advice,
            ),
            _pdfSection('Follow-up', _normalizeFollowUp(followUpDate)),
            _pdfSection('Additional Notes', notes.isEmpty ? 'N/A' : notes),
            pw.SizedBox(height: 14),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Doctor Signature',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        height: 80,
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: signatureImage != null
                            ? pw.Image(signatureImage, fit: pw.BoxFit.contain)
                            : pw.Align(
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  'Dr. $doctorName',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Clinic Stamp',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        height: 80,
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: stampImage != null
                            ? pw.Image(stampImage, fit: pw.BoxFit.contain)
                            : pw.Center(
                                child: pw.Text(
                                  clinicName,
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Issued via DignoVet App',
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Dr. $doctorName',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'prescription_${petOwnerName.replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}.pdf';
      final pdfFile = File('${tempDir.path}/$fileName');
      await pdfFile.writeAsBytes(await doc.save(), flush: true);

      final summary = 'Prescription shared for $petName by Dr. $doctorName';
      final prescriptionId = _firestore.collection('prescriptions').doc().id;

      final uploadedPdfUrl = await context
          .read<ChatProvider>()
          .sendPrescription(
            _myId,
            widget.receiverId,
            pdfFile,
            summary: summary,
            appointmentId: widget.appointmentId,
            animalName: petName,
            documentName: fileName,
            prescriptionId: prescriptionId,
            doctorName: doctorName,
            patientName: petOwnerName,
            medicines: medicines,
            prescriptionDate: DateTime.now(),
          );

      try {
        await _firestore.collection('prescriptions').doc(prescriptionId).set({
          'id': prescriptionId,
          'doctorId': _myId,
          'doctorName': doctorName,
          'clinicName': clinicName,
          'patientId': widget.receiverId,
          'patientName': petOwnerName,
          'animalName': petName,
          'appointmentId': widget.appointmentId,
          'summary': summary,
          'followUp': _normalizeFollowUp(followUpDate),
          'pdfUrl': uploadedPdfUrl,
          'pdfFileName': fileName,
          'downloadCount': 0,
          'status': 'sent',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (widget.appointmentId != null && widget.appointmentId!.isNotEmpty) {
          await _firestore
              .collection('appointments')
              .doc(widget.appointmentId)
              .set({
                'hasPrescription': true,
                'lastPrescriptionAt': FieldValue.serverTimestamp(),
                'lastPrescriptionId': prescriptionId,
                'lastPrescriptionBy': _myId,
              }, SetOptions(merge: true));

          await _appendAppointmentTimelineEvent(
            appointmentId: widget.appointmentId!,
            eventType: 'prescription_sent',
            prescriptionId: prescriptionId,
            summary: summary,
            actorId: _myId,
            actorRole: 'doctor',
            pdfUrl: null,
          );
        }
      } catch (metaError) {
        log('Prescription metadata save failed: $metaError');
      }

      _showSnackBar('Prescription PDF generated and sent successfully.');
      _scrollToBottom();
    } catch (e) {
      log('Prescription send failed: $e');
      _showSnackBar('Unable to send prescription right now. Please try again.');
      if (kDebugMode) {
        _showSnackBar('Debug: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingPrescription = false;
        });
      }
    }
  }

  Future<pw.MemoryImage?> _networkImageToMemory(String url) async {
    if (url.trim().isEmpty) return null;
    try {
      final uri = Uri.parse(url);
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) {
        client.close(force: true);
        return null;
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      client.close(force: true);
      if (bytes.isEmpty) return null;
      return pw.MemoryImage(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  pw.Widget _pdfSection(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 3),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  String _normalizeFollowUp(String input) {
    final value = input.trim();
    if (value.isEmpty) return 'N/A';

    final onlyNumber = RegExp(r'^\d+$');
    if (onlyNumber.hasMatch(value)) {
      return '$value days';
    }

    final numberWithDays = RegExp(r'^\d+\s*(day|days)$', caseSensitive: false);
    if (numberWithDays.hasMatch(value)) {
      return value;
    }

    return value;
  }

  String _formatPrescriptionDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd-$mm-$yyyy';
  }

  Future<void> _openAttachment(String? url, {ChatMessage? message}) async {
    if (url == null || url.isEmpty) {
      _showSnackBar('Attachment URL is not available.');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnackBar('Invalid attachment URL.');
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _showSnackBar('Could not open document.');
      return;
    }

    if (message != null &&
        message.type == MessageType.prescription &&
        !_isDoctor) {
      await _downloadPrescriptionFromChat(
        prescriptionId: message.prescriptionId,
        pdfUrl: url,
        appointmentId: message.appointmentId,
        documentName: message.documentName,
      );
    }
  }

  Future<void> _previewPrescriptionInline({
    String? prescriptionId,
    required String pdfUrl,
    String? appointmentId,
  }) async {
    try {
      final bytes = await http.get(Uri.parse(pdfUrl)).then((response) {
        if (response.statusCode != 200) {
          throw Exception('Failed to fetch PDF');
        }
        return response.bodyBytes;
      });

      if (!mounted) return;

      // Show inline preview dialog
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              AppBar(
                title: const Text('Prescription Preview'),
                backgroundColor: primaryTeal,
                automaticallyImplyLeading: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: PdfPreview(
                  build: (_) => bytes,
                  pdfFileName: 'prescription.pdf',
                  allowPrinting: true,
                  allowSharing: true,
                ),
              ),
            ],
          ),
        ),
      );

      log('[ChatScreen] ✅ Prescription preview displayed');
    } catch (e) {
      log('[ChatScreen] ❌ Prescription preview failed: $e');
      if (!mounted) return;
      _showSnackBar('Could not preview prescription. Please try again.');
    }
  }

  Future<void> _downloadPrescriptionFromChat({
    String? prescriptionId,
    required String pdfUrl,
    String? appointmentId,
    String? documentName,
  }) async {
    try {
      if (pdfUrl.trim().isEmpty) {
        _showSnackBar('Invalid prescription URL.');
        return;
      }

      final baseName = (documentName ?? '').trim().isNotEmpty
          ? documentName!.trim()
          : 'prescription_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedPath = await FileDownloadService.downloadPdf(
        url: pdfUrl,
        fileName: baseName,
      );

      if (savedPath == null) {
        _showSnackBar('Unable to download prescription file.');
        return;
      }

      if (!mounted) return;
      _showSnackBar('✅ Prescription saved: $savedPath');
      log(
        '[ChatScreen] ✅ Prescription downloaded successfully: $baseName to $savedPath',
      );
    } catch (e) {
      log('[ChatScreen] ❌ Error downloading prescription: $e');
      if (!mounted) return;
      _showSnackBar('Unable to download prescription right now.');
    }
  }

  Future<void> _showImagePreview(String imageUrl) async {
    if (imageUrl.trim().isEmpty) {
      _showSnackBar('Image URL is not available.');
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white70,
                      size: 60,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseAppointmentTime() {
    try {
      if (_appointment == null) return null;
      final appointmentDate = _appointment!.date.toDate();
      final timeRange = parseAppointmentTimeRange(
        _appointment!.time,
        appointmentDate: appointmentDate,
      );
      return timeRange['start'];
    } catch (e) {
      log('[ChatScreen] ⚠️ Error parsing appointment time: $e');
      return null;
    }
  }

  DateTime? _parseAppointmentEndTime() {
    try {
      if (_appointment == null) return null;
      final appointmentDate = _appointment!.date.toDate();
      final timeRange = parseAppointmentTimeRange(
        _appointment!.time,
        appointmentDate: appointmentDate,
      );
      return timeRange['end'];
    } catch (e) {
      log('[ChatScreen] ⚠️ Error parsing appointment end time: $e');
      return null;
    }
  }

  Future<bool> _isAppointmentTimeReached() async {
    try {
      final appointmentTime = _parseAppointmentTime();
      final endTime = _parseAppointmentEndTime();

      if (appointmentTime == null) {
        log('[ChatScreen] ⚠️ Could not parse appointment time');
        return false;
      }

      final now = DateTime.now();

      // Check if time has passed and appointment hasn't ended yet
      final hasStarted =
          now.isAfter(appointmentTime) || now.isAtSameMomentAs(appointmentTime);
      final hasEnded = endTime != null && now.isAfter(endTime);

      log(
        '[ChatScreen] ⏰ Time check - now: ${now.toIso8601String()}, scheduled: ${appointmentTime.toIso8601String()}, hasStarted: $hasStarted, hasEnded: $hasEnded',
      );

      return hasStarted && !hasEnded;
    } catch (e) {
      log('[ChatScreen] ⚠️ Error checking appointment time: $e');
      return false;
    }
  }

  Future<void> _startConsultation() async {
    if (_appointment == null) return;

    // Prevent multiple clicks
    if (_isStartingConsultation) {
      log(
        '[ChatScreen] ⚠️ Already starting consultation, ignoring duplicate click',
      );
      return;
    }

    // Check if time has reached BEFORE calling API
    final isTimeReached = await _isAppointmentTimeReached();
    if (!isTimeReached) {
      log('[ChatScreen] ❌ Cannot start - appointment time not reached yet');
      final appointmentTime = _parseAppointmentTime();
      if (appointmentTime != null) {
        final formatter =
            appointmentTime.hour.toString().padLeft(2, '0') +
            ':' +
            appointmentTime.minute.toString().padLeft(2, '0');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏳ Consultation available at $formatter'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      setState(() => _isStartingConsultation = true);

      log(
        '[ChatScreen] 🟢 Doctor starting consultation for appointment: ${_appointment!.id}',
      );

      // Use consolidated consultation service
      final consultationService = ConsultationService();

      final success = await consultationService.startConsultation(
        appointmentId: _appointment!.id,
        doctorId: _appointment!.doctorId,
        userId: _appointment!.userId,
        doctorName: widget.receiverName,
        animalName: _appointment!.animalName,
        appointment: _appointment!,
      );

      if (!success) {
        log(
          '[ChatScreen] ❌ Consultation start failed - may already be running',
        );
        if (!mounted) {
          setState(() => _isStartingConsultation = false);
          return;
        }

        // Show error dialog with better message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.amber[50],
            title: const Text(
              '⚠️ مسئلہ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[300]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consultation پہلے سے شروع ہو چکی ہے۔',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'براہ کرم دوبارہ Start نہ کریں۔\n\n' +
                            'آپ اور patient دونوں اب chat کر سکتے ہیں۔',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'ٹھیک ہے',
                  style: TextStyle(color: Color(0xFF00796B)),
                ),
              ),
            ],
          ),
        );
        return;
      }

      log('[ChatScreen] ✅ Consultation started successfully');

      if (!mounted) return;

      // Show success notification
      _showNotification(
        title: '🟢 Consultation Live!',
        body: 'Consultation is now active. Both users can chat.',
        icon: Icons.phone_in_talk_outlined,
      );

      setState(() {
        _canSendMessages = true;
      });
    } catch (e) {
      log('[ChatScreen] ❌ Failed to start consultation: $e');
      if (!mounted) return;
      _showSnackBar('Failed to start consultation. Please try again.');
    }
  }

  Future<void> _confirmAndDeleteMessage(ChatMessage message) async {
    if (message.id.isEmpty || message.senderId != _myId) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This will remove the message for both users.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await context.read<ChatProvider>().deleteMessage(
        senderId: _myId,
        receiverId: widget.receiverId,
        messageId: message.id,
      );
      _showSnackBar('Message deleted.');
    } catch (e) {
      log('Message delete failed: $e');
      _showSnackBar('Unable to delete message right now.');
    }
  }

  Future<void> _confirmAndClearChat() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear this chat?'),
        content: const Text('All messages will be removed for both sides.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear Chat'),
          ),
        ],
      ),
    );

    if (shouldClear != true) return;

    try {
      await context.read<ChatProvider>().clearChat(
        userA: _myId,
        userB: widget.receiverId,
      );
      _showSnackBar('Chat cleared successfully.');
    } catch (e) {
      log('Clear chat failed: $e');
      _showSnackBar('Unable to clear chat right now.');
    }
  }

  Future<void> _handleMenuSelection(String value) async {
    if (value == _menuClearChat) {
      await _confirmAndClearChat();
    }
  }

  Future<void> _appendAppointmentTimelineEvent({
    required String appointmentId,
    required String eventType,
    required String prescriptionId,
    required String summary,
    required String actorId,
    required String actorRole,
    required String? pdfUrl,
  }) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .collection('prescriptionTimeline')
          .add({
            'eventType': eventType,
            'prescriptionId': prescriptionId,
            'summary': summary,
            'actorId': actorId,
            'actorRole': actorRole,
            'pdfUrl': pdfUrl,
            'eventAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      log('Failed to append appointment timeline event: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isLoading = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : const Color(0xFF00796B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Helper method to get time remaining text
  String _getTimeRemainingText() {
    if (_appointment == null) return '';

    final secondsRemaining =
        AppointmentStatusHelper.getSecondsRemainingInAppointment(_appointment!);
    if (secondsRemaining <= 0) {
      return '';
    }

    final minutesLeft = Duration(seconds: secondsRemaining).inMinutes;
    final secondsLeft = secondsRemaining % 60;

    if (minutesLeft == 0) {
      return 'Less than a minute remaining';
    } else if (minutesLeft < 5) {
      return '${minutesLeft}m ${secondsLeft}s remaining';
    } else {
      return '${minutesLeft}m remaining';
    }
  }

  // Helper method to check if a prescription exists for this appointment
  Future<bool> _checkPrescriptionExists() async {
    if (_appointment == null) return false;

    try {
      final querySnapshot = await _firestore
          .collection('prescriptions')
          .where('appointmentId', isEqualTo: _appointment!.id)
          .where('archived', isEqualTo: false)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      log('[ChatScreen] Error checking prescription existence: $e');
      return false;
    }
  }

  // ---------------- UI Building ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryTeal, // Background according to your theme
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Permission Banner (if consultation appointment with restrictions)
          if (_appointment != null && _restrictionMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.amber.shade100,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _restrictionMessage!,
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // White Container for Messages
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
                child: _buildMessages(),
              ),
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  // ── Phone & Video Calling ──────────────────────────────────────────────────

  Future<void> _makePhoneCall() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.receiverId)
          .get();

      String? phoneNumber =
          userDoc.data()?['phone'] ?? userDoc.data()?['phoneNumber'];

      if (phoneNumber == null || phoneNumber.isEmpty) {
        _showSnackBar('Phone number not available', isError: true);
        return;
      }

      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        _showSnackBar('📞 Initiating call to $phoneNumber');
      } else {
        _showSnackBar('Cannot make calls on this device', isError: true);
      }
    } catch (e) {
      log('[ChatScreen] Error making call: $e');
      _showSnackBar('Error making call: $e', isError: true);
    }
  }

  Future<void> _startVideoCall() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('📹 Start Video Call'),
        content: const Text('Open WhatsApp to start a video call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            onPressed: () {
              Navigator.pop(ctx);
              _openWhatsAppVideoCall();
            },
            child: const Text(
              'Open WhatsApp',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsAppVideoCall() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.receiverId)
          .get();

      String? phoneNumber =
          userDoc.data()?['phone'] ?? userDoc.data()?['phoneNumber'];

      if (phoneNumber == null || phoneNumber.isEmpty) {
        _showSnackBar('Phone number not available', isError: true);
        return;
      }

      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final whatsappUrl = Uri.parse(
          'https://wa.me/$cleanPhone?text=Hi, I want to start a video call');

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        _showSnackBar('📱 Opening WhatsApp for video call');
      } else {
        _showSnackBar('WhatsApp is not installed', isError: true);
      }
    } catch (e) {
      log('[ChatScreen] Error opening WhatsApp: $e');
      _showSnackBar('Error opening WhatsApp: $e', isError: true);
    }
  }

  // ── Location Sharing ───────────────────────────────────────────────────────

  Future<void> _shareCurrentLocation() async {
    try {
      // Check if user can share (only during appointment)
      if (!_isDoctor) {
        final canShare = await _isAppointmentTimeReached();
        if (!canShare) {
          _showSnackBar('📍 Location sharing available during appointment', isError: true);
          return;
        }
      }

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission required', isError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
            'Location permission denied. Enable in settings.', isError: true);
        return;
      }

      _showSnackBar('📍 Getting your location...', isLoading: true);

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Check time again before showing map
      if (!_isDoctor) {
        final canShare = await _isAppointmentTimeReached();
        if (!canShare) {
          _showSnackBar('📍 Location sharing available during appointment', isError: true);
          return;
        }
      }

      // Show map picker with current location
      await _showLocationPicker(position.latitude, position.longitude);
    } catch (e) {
      log('[ChatScreen] Error sharing location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSnackBar('Error getting location: $e', isError: true);
      }
    }
  }

  Future<void> _startLiveLocation() async {
    try {
      // Check if user can share (only during appointment)
      if (!_isDoctor) {
        final canShare = await _isAppointmentTimeReached();
        if (!canShare) {
          _showSnackBar('🎯 Live location sharing available during appointment', isError: true);
          return;
        }
      }

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission required', isError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
            'Location permission denied. Enable in settings.', isError: true);
        return;
      }

      _showSnackBar('🎯 Getting your location...', isLoading: true);

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Check time again before showing map
      if (!_isDoctor) {
        final canShare = await _isAppointmentTimeReached();
        if (!canShare) {
          _showSnackBar('🎯 Live location sharing available during appointment', isError: true);
          return;
        }
      }

      // Show map picker for live location
      await _showLiveLocationPicker(position.latitude, position.longitude);
    } catch (e) {
      log('[ChatScreen] Error starting live location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSnackBar('Error getting location: $e', isError: true);
      }
    }
  }

  Future<void> _showLocationPicker(double initialLat, double initialLng) async {
    if (!mounted) return;

    // Check if user can share
    final canShare = _isDoctor || await _isAppointmentTimeReached();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        double selectedLat = initialLat;
        double selectedLng = initialLng;
        late GoogleMapController mapController;

        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            insetPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: primaryTeal,
                title: const Text('📍 Select Current Location',
                    style: TextStyle(color: Colors.white)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              body: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(selectedLat, selectedLng),
                      zoom: 18,
                    ),
                    onMapCreated: (controller) async {
                      mapController = controller;
                    },
                    onCameraMove: (CameraPosition position) {
                      selectedLat = position.target.latitude;
                      selectedLng = position.target.longitude;
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected_location'),
                        position: LatLng(selectedLat, selectedLng),
                        infoWindow: InfoWindow(
                          title: 'Sharing from here',
                          snippet: '${selectedLat.toStringAsFixed(6)}, ${selectedLng.toStringAsFixed(6)}',
                        ),
                      ),
                    },
                  ),
                  // Center pin indicator
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Icon(
                        Icons.location_on,
                        color: primaryTeal,
                        size: 50,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                    ),
                  ),
                  // Bottom action buttons
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Lat: ${selectedLat.toStringAsFixed(6)}\nLng: ${selectedLng.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontFamily: 'Courier',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (!canShare)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info,
                                        color: Colors.orange[700], size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Available during appointment',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange[900],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(Icons.close),
                                label: const Text('Cancel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: canShare
                                    ? () async {
                                        Navigator.pop(ctx);
                                        final locationMessage =
                                            '📍 My Location\nhttps://maps.google.com/?q=$selectedLat,$selectedLng';
                                        final msg = ChatMessage(
                                          id: '',
                                          senderId: _myId,
                                          receiverId: widget.receiverId,
                                          text: locationMessage,
                                          type: MessageType.text,
                                          timestamp: DateTime.now(),
                                        );
                                        try {
                                          await context
                                              .read<ChatProvider>()
                                              .sendText(msg);
                                          _showSnackBar('✅ Location shared');
                                        } catch (e) {
                                          _showSnackBar('Error: $e',
                                              isError: true);
                                        }
                                      }
                                    : null,
                                icon: const Icon(Icons.check),
                                label: const Text('Share Location'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      canShare ? primaryTeal : Colors.grey[300],
                                  foregroundColor: canShare
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLiveLocationPicker(double initialLat, double initialLng) async {
    if (!mounted) return;

    // Check if user can share
    final canShare = _isDoctor || await _isAppointmentTimeReached();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        double selectedLat = initialLat;
        double selectedLng = initialLng;
        late GoogleMapController mapController;
        int selectedDuration = 60;

        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            insetPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: primaryTeal,
                title: const Text('🎯 Share Live Location',
                    style: TextStyle(color: Colors.white)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              body: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(selectedLat, selectedLng),
                      zoom: 18,
                    ),
                    onMapCreated: (controller) async {
                      mapController = controller;
                    },
                    onCameraMove: (CameraPosition position) {
                      selectedLat = position.target.latitude;
                      selectedLng = position.target.longitude;
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected_location'),
                        position: LatLng(selectedLat, selectedLng),
                        infoWindow: InfoWindow(
                          title: 'Sharing live from here',
                          snippet: '${selectedLat.toStringAsFixed(6)}, ${selectedLng.toStringAsFixed(6)}',
                        ),
                      ),
                    },
                  ),
                  // Center pin indicator
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Icon(
                        Icons.location_on,
                        color: primaryTeal,
                        size: 50,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                    ),
                  ),
                  // Bottom action panel
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Lat: ${selectedLat.toStringAsFixed(6)}\nLng: ${selectedLng.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontFamily: 'Courier',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Share live for:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildDurationButton('15 min', 15, selectedDuration,
                                  () {
                                setState(() {
                                  selectedDuration = 15;
                                });
                              }),
                              _buildDurationButton('30 min', 30, selectedDuration,
                                  () {
                                setState(() {
                                  selectedDuration = 30;
                                });
                              }),
                              _buildDurationButton('1 hour', 60, selectedDuration,
                                  () {
                                setState(() {
                                  selectedDuration = 60;
                                });
                              }),
                              _buildDurationButton('8 hours', 480,
                                  selectedDuration, () {
                                setState(() {
                                  selectedDuration = 480;
                                });
                              }),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (!canShare)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info,
                                        color: Colors.orange[700], size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Available during appointment',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange[900],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(Icons.close),
                                label: const Text('Cancel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: canShare
                                    ? () async {
                                        Navigator.pop(ctx);
                                        final durationStr =
                                            _formatDuration(selectedDuration);
                                        final liveLocationMessage =
                                            '🎯 Live Location ($durationStr)\nhttps://maps.google.com/?q=$selectedLat,$selectedLng';
                                        final msg = ChatMessage(
                                          id: '',
                                          senderId: _myId,
                                          receiverId: widget.receiverId,
                                          text: liveLocationMessage,
                                          type: MessageType.text,
                                          timestamp: DateTime.now(),
                                        );
                                        try {
                                          await context
                                              .read<ChatProvider>()
                                              .sendText(msg);
                                          _showSnackBar('✅ Live location shared');
                                        } catch (e) {
                                          _showSnackBar('Error: $e',
                                              isError: true);
                                        }
                                      }
                                    : null,
                                icon: const Icon(Icons.check),
                                label: const Text('Share Live'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      canShare ? primaryTeal : Colors.grey[300],
                                  foregroundColor: canShare
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDurationButton(String label, int duration, int selectedDuration,
      VoidCallback onTap) {
    final isActive = duration == selectedDuration;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryTeal : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? primaryTeal : Colors.grey[400]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else if (minutes == 60) {
      return '1 hour';
    } else {
      final hours = minutes / 60;
      return '${hours.toStringAsFixed(1)} hours';
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      toolbarHeight: 70,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
      titleSpacing: 4,
      title: Container(
        height: 70,
        constraints: const BoxConstraints(maxWidth: 200),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  backgroundImage: widget.receiverImage.isNotEmpty
                      ? NetworkImage(widget.receiverImage)
                      : null,
                  child: widget.receiverImage.isEmpty
                      ? Icon(Icons.person, color: primaryTeal, size: 20)
                      : null,
                ),
                if (widget.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryTeal, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            // Name and Status
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (_appointment != null)
                    StreamBuilder<int>(
                      stream: Stream.periodic(
                        const Duration(seconds: 1),
                        (_) => 0,
                      ),
                      builder: (context, snapshot) {
                        final startTime = _parseAppointmentTime();
                        final endTime = _parseAppointmentEndTime();
                        final timeRemaining = _getTimeRemainingText();
                        final now = DateTime.now();
                        
                        if (startTime != null && endTime != null) {
                          // Format appointment time: "2:30 - 3:00"
                          final startHour = startTime.hour.toString().padLeft(2, '0');
                          final startMin = startTime.minute.toString().padLeft(2, '0');
                          final endHour = endTime.hour.toString().padLeft(2, '0');
                          final endMin = endTime.minute.toString().padLeft(2, '0');
                          final appointmentTimeStr = '$startHour:$startMin - $endHour:$endMin';
                          
                          // Show remaining time if during appointment, else show appointment time
                          final statusText = timeRemaining.isEmpty
                              ? appointmentTimeStr
                              : '⏱️ $timeRemaining';
                          
                          final statusColor = timeRemaining.isNotEmpty
                              ? Colors.amber.shade200
                              : Colors.white.withOpacity(0.7);
                          
                          return Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              color: statusColor,
                              fontWeight: timeRemaining.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        } else {
                          // Fallback if times not available
                          return Text(
                            widget.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.7),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                      },
                    )
                  else
                    Text(
                      widget.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Doctor Start Consultation Button
        if (_isDoctor && _appointment != null)
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('appointments')
                .doc(_appointment!.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final appointmentData =
                  snapshot.data!.data() as Map<String, dynamic>?;
              final status = appointmentData?['status'] as String? ?? 'pending';

              if (status != 'approved') return const SizedBox.shrink();

              return FutureBuilder<bool>(
                future: _isAppointmentTimeReached(),
                builder: (context, timeSnapshot) {
                  final isTimeReached = timeSnapshot.data ?? false;
                  final isLoading = _isStartingConsultation;

                  if (isLoading) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    );
                  }

                  if (!isTimeReached) {
                    return const SizedBox.shrink();
                  }

                  return SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      icon: const Icon(Icons.play_circle_filled,
                          color: Colors.white, size: 20),
                      tooltip: 'Start Consultation',
                      onPressed: _startConsultation,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  );
                },
              );
            },
          ),
        // Call Button
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            icon: Icon(
              Icons.call,
              color: (_isDoctor || _canSendMessages)
                  ? Colors.white
                  : Colors.white54,
              size: 18,
            ),
            tooltip: 'Make Call',
            onPressed:
                (_isDoctor || _canSendMessages) ? _makePhoneCall : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
        // Video Call Button
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            icon: Icon(
              Icons.videocam,
              color: (_isDoctor || _canSendMessages)
                  ? Colors.white
                  : Colors.white54,
              size: 18,
            ),
            tooltip: 'Video Call',
            onPressed:
                (_isDoctor || _canSendMessages) ? _startVideoCall : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
        // Current Location Button
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            icon: Icon(
              Icons.location_on,
              color: (_isDoctor || _canSendMessages)
                  ? Colors.white
                  : Colors.white54,
              size: 18,
            ),
            tooltip: 'Share Location',
            onPressed:
                (_isDoctor || _canSendMessages)
                    ? _shareCurrentLocation
                    : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
        // Live Location Button
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            icon: Icon(
              Icons.location_searching,
              color: (_isDoctor || _canSendMessages)
                  ? Colors.white
                  : Colors.white54,
              size: 18,
            ),
            tooltip: 'Live Location',
            onPressed: (_isDoctor || _canSendMessages)
                ? _startLiveLocation
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
        // More Menu
        SizedBox(
          width: 40,
          height: 40,
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            onSelected: _handleMenuSelection,
            padding: EdgeInsets.zero,
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: _menuClearChat,
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Clear chat', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessages() {
    return StreamBuilder<List<ChatMessage>>(
      stream: context.read<ChatProvider>().getMessages(
        _myId,
        widget.receiverId,
      ),
      builder: (context, snapshot) {
        // Handle errors first
        if (snapshot.hasError) {
          final errorCode = snapshot.error.toString();
          if (errorCode.contains('PERMISSION_DENIED')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 80, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to Load Chat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'You do not have permission to access this conversation or the connection may have been lost.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator(color: primaryTeal));

        final messages = snapshot.data!;
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: messages.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (_, i) => _buildBubble(messages[i]),
        );
      },
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isMe = msg.senderId == _myId;
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: align,
      child: GestureDetector(
        onLongPress: isMe ? () => _confirmAndDeleteMessage(msg) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            // Gradient for 'Me', Solid white for 'Receiver'
            gradient: isMe
                ? LinearGradient(colors: [primaryTeal, mediumTeal])
                : null,
            color: isMe ? null : const Color(0xFFF1F1F1),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: msg.type == MessageType.text
              ? _textBubble(msg, isMe)
              : msg.type == MessageType.prescription
              ? _prescriptionBubble(msg, isMe)
              : _mediaBubble(msg, isMe),
        ),
      ),
    );
  }

  Widget _textBubble(ChatMessage msg, bool isMe) {
    // Check if this is a location message
    final isLocationMessage = msg.text?.contains('maps.google.com') ?? false;
    
    if (isLocationMessage) {
      return _buildLocationBubble(msg, isMe);
    }
    
    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          msg.text ?? '',
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(msg.timestamp),
          style: TextStyle(
            fontSize: 10,
            color: isMe ? Colors.white70 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationBubble(ChatMessage msg, bool isMe) {
    final lat = _extractLatitude(msg.text ?? '');
    final lng = _extractLongitude(msg.text ?? '');
    final isLiveLocation = msg.text?.contains('Live Location') ?? false;
    
    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (lat != null && lng != null) {
              _openLocationMap(lat, lng, msg.text ?? '');
            }
          },
          child: Container(
            width: 220,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMe ? Colors.white30 : Colors.black12,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Static map preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: lat != null && lng != null
                      ? Image.network(
                          'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=17&size=220x200&markers=color:red%7C$lat,$lng&key=AIzaSyBYRXva_nHpjbLjW8v9Z-kj3360pTNQUp8',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(
                                  Icons.location_on,
                                  color: primaryTeal,
                                  size: 50,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.location_on,
                            color: primaryTeal,
                            size: 50,
                          ),
                        ),
                ),
                // Overlay with tap hint
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                // Center button
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      Icons.map,
                      color: primaryTeal,
                      size: 32,
                    ),
                  ),
                ),
                // Top left label
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isLiveLocation ? '🎯 Live Location' : '📍 Location',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatTime(msg.timestamp),
          style: TextStyle(
            fontSize: 10,
            color: isMe ? Colors.white70 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Future<void> _openLocationMap(double lat, double lng, String locationText) async {
    late GoogleMapController mapController;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: primaryTeal,
            title: const Text('📍 Location View',
                style: TextStyle(color: Colors.white)),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_new, color: Colors.white),
                onPressed: () async {
                  final url = Uri.parse(
                      'https://maps.google.com/?q=$lat,$lng');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url,
                        mode: LaunchMode.externalApplication);
                  }
                },
                tooltip: 'Open in Google Maps',
              ),
            ],
          ),
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(lat, lng),
                  zoom: 18,
                ),
                onMapCreated: (controller) {
                  mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                markers: {
                  Marker(
                    markerId: const MarkerId('location'),
                    position: LatLng(lat, lng),
                    infoWindow: InfoWindow(
                      title: 'Shared Location',
                      snippet: '$lat, $lng',
                    ),
                  ),
                },
              ),
              // Info panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Lat: $lat\nLng: $lng',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontFamily: 'Courier',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse(
                              'https://maps.google.com/?q=$lat,$lng');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open in Google Maps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double? _extractLatitude(String text) {
    try {
      final regex = RegExp(r'q=([-\d.]+),');
      final match = regex.firstMatch(text);
      return match != null ? double.tryParse(match.group(1)!) : null;
    } catch (e) {
      return null;
    }
  }

  double? _extractLongitude(String text) {
    try {
      final regex = RegExp(r'q=[-\d.]+,([-\d.]+)');
      final match = regex.firstMatch(text);
      return match != null ? double.tryParse(match.group(1)!) : null;
    } catch (e) {
      return null;
    }
  }

  Widget _mediaBubble(ChatMessage msg, bool isMe) {
    if (msg.type == MessageType.video) {
      return Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openAttachment(msg.mediaUrl),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam_rounded,
                    color: isMe ? Colors.white : primaryTeal,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Open video',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(msg.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: isMe ? Colors.white70 : Colors.black45,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showImagePreview(msg.mediaUrl ?? ''),
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              msg.mediaUrl ?? '',
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 50),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(msg.timestamp),
          style: TextStyle(
            fontSize: 10,
            color: isMe ? Colors.white70 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _prescriptionBubble(ChatMessage msg, bool isMe) {
    final medicinesPreview = (msg.medicines ?? '')
        .split('\n')
        .take(2)
        .join('\n')
        .replaceAll(RegExp(r'\n+'), ' - ');

    final dateStr = msg.prescriptionDate != null
        ? _formatPrescriptionDate(msg.prescriptionDate!)
        : '';

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            gradient: isMe
                ? LinearGradient(
                    colors: [
                      primaryTeal.withOpacity(0.9),
                      mediumTeal.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.white, const Color(0xFFF5F5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Header with doctor info
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      color: isMe ? Colors.white : primaryTeal,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prescription Document',
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if (msg.doctorName != null &&
                              msg.doctorName!.isNotEmpty)
                            Text(
                              'Dr. ${msg.doctorName}',
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white70
                                    : Colors.grey.shade700,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Patient and animal info
                if ((msg.patientName ?? '').isNotEmpty ||
                    (msg.animalName ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if ((msg.patientName ?? '').isNotEmpty)
                          Text(
                            'Owner: ${msg.patientName}',
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 11,
                            ),
                          ),
                        if ((msg.animalName ?? '').isNotEmpty)
                          Text(
                            'Pet: ${msg.animalName}',
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),

                // Medicines preview
                if (medicinesPreview.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.white.withOpacity(0.15)
                          : primaryTeal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Medicines: ${medicinesPreview.length > 40 ? medicinesPreview.substring(0, 40) + '...' : medicinesPreview}',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Date and summary
                if (dateStr.isNotEmpty || (msg.text ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (dateStr.isNotEmpty)
                          Text(
                            'Date: $dateStr',
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          ),
                        if ((msg.text ?? '').isNotEmpty)
                          Text(
                            msg.text!,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                // Action buttons
                Wrap(
                  alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
                  runAlignment: isMe ? WrapAlignment.end : WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Preview button
                    InkWell(
                      onTap: msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty
                          ? () => _previewPrescriptionInline(
                              prescriptionId: msg.prescriptionId,
                              pdfUrl: msg.mediaUrl!,
                              appointmentId: msg.appointmentId,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.white.withOpacity(0.2)
                              : primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility,
                              color: isMe ? Colors.white : primaryTeal,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Preview',
                              style: TextStyle(
                                color: isMe ? Colors.white : primaryTeal,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Download button
                    InkWell(
                      onTap: msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty
                          ? () => _downloadPrescriptionFromChat(
                              prescriptionId: msg.prescriptionId,
                              pdfUrl: msg.mediaUrl!,
                              appointmentId: msg.appointmentId,
                              documentName: msg.documentName,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.white.withOpacity(0.2)
                              : mediumTeal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_rounded,
                              color: isMe ? Colors.white : mediumTeal,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Download',
                              style: TextStyle(
                                color: isMe ? Colors.white : mediumTeal,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(msg.timestamp),
          style: TextStyle(
            fontSize: 10,
            color: isMe ? Colors.white70 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildInput() {
    // 🔥 Doctor can ALWAYS send. User can send ONLY if status is 'approved'
    final canSend = _canSendBasedOnStatus();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Disabled message if user can't send
            if (!canSend && _appointment != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _restrictionMessage ??
                        'You are currently unable to send messages',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                // Media Options in a nice container
                Container(
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.image_rounded,
                          color: canSend ? primaryTeal : Colors.grey,
                          size: 22,
                        ),
                        onPressed: canSend
                            ? () => _sendMedia(MessageType.image)
                            : null,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.videocam_rounded,
                          color: canSend ? primaryTeal : Colors.grey,
                          size: 22,
                        ),
                        onPressed: canSend
                            ? () => _sendMedia(MessageType.video)
                            : null,
                      ),
                      if (_isDoctor)
                        IconButton(
                          icon: Icon(
                            Icons.receipt_long_rounded,
                            color: canSend ? primaryTeal : Colors.grey,
                            size: 22,
                          ),
                          tooltip: 'Send Prescription',
                          onPressed: (canSend && !_isSendingPrescription)
                              ? _showPrescriptionComposer
                              : null,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Text Input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: canSend,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: canSend
                          ? 'Type a message...'
                          : 'Messages disabled',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: canSend
                          ? Colors.grey.shade100
                          : Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Send Button
                GestureDetector(
                  onTap: canSend
                      ? () => _sendMessage(_messageController.text)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: canSend
                          ? LinearGradient(colors: [primaryTeal, mediumTeal])
                          : LinearGradient(
                              colors: [
                                Colors.grey.shade400,
                                Colors.grey.shade500,
                              ],
                            ),
                      shape: BoxShape.circle,
                      boxShadow: canSend
                          ? [
                              BoxShadow(
                                color: primaryTeal.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
