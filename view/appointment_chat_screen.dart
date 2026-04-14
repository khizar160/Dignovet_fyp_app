import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/model/appointment_model.dart';
import 'package:flutter_application_1/model/chat_model.dart';
import 'package:flutter_application_1/services/consultation_service.dart';
import 'package:flutter_application_1/services/chat_permission_checker.dart';
import 'package:flutter_application_1/services/chat_services/chat_services.dart';
import 'package:flutter_application_1/utils/time_parser.dart';
import 'package:flutter_application_1/utils/appointment_time_parser.dart';
import 'package:flutter_application_1/helpers/appointment_status_helper.dart';
import 'package:image_picker/image_picker.dart';

class AppointmentChatScreen extends StatefulWidget {
  final AppointmentModel appointment;
  final String otherUserName;
  final String otherUserImage;
  final bool isDoctor;

  const AppointmentChatScreen({
    super.key,
    required this.appointment,
    required this.otherUserName,
    required this.otherUserImage,
    required this.isDoctor,
  });

  @override
  State<AppointmentChatScreen> createState() => _AppointmentChatScreenState();
}

class _AppointmentChatScreenState extends State<AppointmentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final ChatPermissionChecker _permissionChecker = ChatPermissionChecker();
  final ConsultationService _consultationService = ConsultationService();
  final ChatService _chatService = ChatService();

  late String _chatId;
  late bool _userCanSend;
  bool _isLoadingPermissions = true;
  Map<String, bool> _permissions = {'canRead': false, 'canSend': false};
  bool _appointmentDetailsMessageSent = false;
  bool _isStartingConsultation = false;  // Loading state for start button

  @override
  void initState() {
    super.initState();
    _chatId = _generateChatId(
      widget.appointment.userId,
      widget.appointment.doctorId,
    );
    print('[AppointmentChat] 🚀 Initializing chat - isDoctor: ${widget.isDoctor}, appointmentId: ${widget.appointment.id}');
    _loadPermissions();
    _listenToAppointmentStatus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPermissions() async {
    try {
      final currentUserId = _auth.currentUser!.uid;
      
      // Check current appointment status first
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(widget.appointment.id)
          .get();
      
      final appointmentData = appointmentDoc.data() as Map<String, dynamic>?;
      final status = appointmentData?['status'] ?? 'pending';

      print('[AppointmentChat] 📊 Current appointment status: $status');

      // For doctors, if appointment is approved, they can immediately read/send
      if (widget.isDoctor && status == 'approved') {
        print('[AppointmentChat] ✅ Doctor appointment approved - granting full permissions');
        if (mounted) {
          setState(() {
            _permissions = {'canRead': true, 'canSend': true, 'canDelete': true};
            _userCanSend = true;
            _isLoadingPermissions = false;
          });
        }
        return;
      }

      // Otherwise, check permissions normally
      final permissions = await _permissionChecker.getChatPermissions(
        appointmentId: widget.appointment.id,
        currentUserId: currentUserId,
        otherUserId: widget.isDoctor
            ? widget.appointment.userId
            : widget.appointment.doctorId,
      );

      print('[AppointmentChat] 🔓 Permissions loaded - canSend: ${permissions['canSend']}, canRead: ${permissions['canRead']}, isDoctor: ${widget.isDoctor}');

      if (mounted) {
        setState(() {
          _permissions = permissions;
          _userCanSend = permissions['canSend'] ?? false;
          _isLoadingPermissions = false;
        });
      }
    } catch (e) {
      print('[AppointmentChat] ❌ Error loading permissions: $e');
      if (mounted) {
        setState(() => _isLoadingPermissions = false);
      }
    }
  }

  void _listenToAppointmentStatus() {
    _firestore
        .collection('appointments')
        .doc(widget.appointment.id)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final status = data['status'] as String?;

      print('[AppointmentChat] 📍 Appointment status changed to: $status');

      // When appointment is approved, reload permissions and send details
      if (status == 'approved') {
        print('[AppointmentChat] 🔄 Reloading permissions due to approval');
        _loadPermissions(); // Reload permissions
        
        // If this is the doctor, send appointment details message once
        if (widget.isDoctor && !_appointmentDetailsMessageSent) {
          print('[AppointmentChat] 📤 Doctor sending appointment details');
          _sendAppointmentDetailsMessage();
          _appointmentDetailsMessageSent = true;
        }
      }
    });
  }

  Future<void> _sendAppointmentDetailsMessage() async {
    try {
      // Show appointment details as an automatic message
      final detailsText = _buildAppointmentDetailsText();

      final message = ChatMessage(
        id: '',
        senderId: _auth.currentUser!.uid,
        receiverId: widget.appointment.userId == _auth.currentUser!.uid
            ? widget.appointment.doctorId
            : widget.appointment.userId,
        text: detailsText,
        appointmentId: widget.appointment.id,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      await _chatService.sendMessage(message);
      print('[AppointmentChat] ✅ Appointment details sent successfully');
    } catch (e) {
      print('[AppointmentChat] ❌ Error sending appointment details: $e');
      if (mounted) {
        _showSnackBar('Error: Could not send appointment details', isError: true);
      }
    }
  }

  String _buildAppointmentDetailsText() {
    return '''📋 **APPOINTMENT DETAILS** 📋

🐾 Pet: ${widget.appointment.animalName}
🔍 Issue: ${widget.appointment.problem}
📅 Date: ${_formatDate(widget.appointment.date.toDate())}
⏰ Time: ${widget.appointment.time}
💬 Type: ${widget.appointment.consultationType}

Your consultation is ready to begin. Please wait for further instructions.''';
  }

  Future<void> _onDoctorStartedConversation() async {
    try {
      // When doctor sends first message, enable user to send
      await _consultationService.enableUserSendMessages(
        appointmentId: widget.appointment.id,
        userId: widget.appointment.userId,
        doctorId: widget.appointment.doctorId,
      );

      // Reload permissions
      _loadPermissions();
    } catch (e) {
      print('[AppointmentChat] Error enabling user to send: $e');
    }
  }

  Future<void> _startConsultationButtonPressed() async {
    if (!widget.isDoctor) {
      _showSnackBar('Only doctors can start a consultation', isError: true);
      return;
    }

    // Prevent multiple clicks
    if (_isStartingConsultation) {
      print('[AppointmentChat] ⚠️ Already starting consultation, ignoring duplicate click');
      return;
    }

    try {
      setState(() => _isStartingConsultation = true);
      
      // Get patient's name from Firestore
      final patientDoc = await _firestore
          .collection('users')
          .doc(widget.appointment.userId)
          .get();
      
      final patientName = patientDoc.data()?['name'] ?? 'Patient';

      // Format appointment time
      final appointmentDateTime = widget.appointment.date.toDate();
      final timeString = '${appointmentDateTime.day}/${appointmentDateTime.month}/${appointmentDateTime.year} at ${widget.appointment.time}';

      // Check if current time is before appointment time
      final now = DateTime.now();
      final appointmentTime = _parseAppointmentTime();

      if (appointmentTime == null || now.isBefore(appointmentTime)) {
        // Time hasn't arrived yet
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.red[50],
            title: const Text('⏰ Too Early', style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            )),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'باخبر رہیں! 📍',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اس patient کی appointment اس وقت شروع نہیں ہو رہی۔',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red[900],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⏱️ مقررہ وقت:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeString,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00796B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'خود بخود شروع ہو جائے گی اس وقت پر۔\nتھوڑا انتظار کریں۔',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.4,
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
                child: const Text('ٹھیک ہے', style: TextStyle(color: Color(0xFF00796B))),
              ),
            ],
          ),
        );
        return;
      }

      // Time has arrived - show confirmation dialog
      // Get doctor's name from Firestore
      final doctorDoc = await _firestore
          .collection('users')
          .doc(widget.appointment.doctorId)
          .get();
      
      final doctorName = doctorDoc.data()?['name'] ?? 'Doctor';

      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('🟢 Appointment Time Reached', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'یہ appointment کا مقررہ وقت ہے:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeString,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF00796B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'یہ consultation اب شروع ہو سکتی ہے۔\n'
                        'براہ کرم "اب شروع کریں" کلک کریں۔',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00796B),
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
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
              child: const Text('منسوخ', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performStartConsultation(doctorName, patientName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('اب شروع کریں', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      print('[AppointmentChat] ❌ Error preparing consultation: $e');
      if (!mounted) return;
      _showSnackBar('خرابی: تفصیلات لوڈ نہیں ہو سکیں: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isStartingConsultation = false);
      }
    }
  }

  /// Parse appointment time safely using TimeParser
  DateTime? _parseAppointmentTime() {
    try {
      final appointmentDate = widget.appointment.date.toDate();
      final timeRange = parseAppointmentTimeRange(
        widget.appointment.time,
        appointmentDate: appointmentDate,
      );
      return timeRange['start'];
    } catch (e) {
      print('[AppointmentChat] ⚠️ Error parsing appointment time: $e');
      return null;
    }
  }

  /// Parse appointment END time from time range (e.g., "06:00-07:00" → 07:00)
  DateTime? _parseAppointmentEndTime() {
    try {
      final appointmentDate = widget.appointment.date.toDate();
      final timeRange = parseAppointmentTimeRange(
        widget.appointment.time,
        appointmentDate: appointmentDate,
      );
      return timeRange['end'];
    } catch (e) {
      print('[AppointmentChat] ⚠️ Error parsing appointment end time: $e');
      return null;
    }
  }

  /// Check if appointment has ended
  bool _hasAppointmentEnded() {
    try {
      final endTime = _parseAppointmentEndTime();
      if (endTime == null) return false; // No end time, allow messaging
      
      final now = DateTime.now();
      return now.isAfter(endTime);
    } catch (e) {
      print('[AppointmentChat] ⚠️ Error checking appointment end: $e');
      return false;
    }
  }

  /// Check if appointment time has been reached
  Future<bool> _isAppointmentTimeReached() async {
    try {
      final appointmentTime = _parseAppointmentTime();
      final endTime = _parseAppointmentEndTime();
      
      if (appointmentTime == null) return false;
      
      final now = DateTime.now();
      
      // Check if time has passed and appointment hasn't ended yet
      final hasStarted = now.isAfter(appointmentTime) || now.isAtSameMomentAs(appointmentTime);
      final hasEnded = endTime != null && now.isAfter(endTime);
      
      return hasStarted && !hasEnded;
    } catch (e) {
      print('[AppointmentChat] ⚠️ Error checking appointment time: $e');
      return false;
    }
  }

  Future<void> _performStartConsultation(String doctorName, String patientName) async {
    try {
      print('[AppointmentChat] 🟢 Doctor starting consultation for appointment: ${widget.appointment.id}');

      final consultationService = ConsultationService();
      
      final success = await consultationService.startConsultation(
        appointmentId: widget.appointment.id,
        doctorId: widget.appointment.doctorId,
        userId: widget.appointment.userId,
        doctorName: doctorName,
        animalName: widget.appointment.animalName ?? 'Pet',
        appointment: widget.appointment,
      );

      if (!success) {
        print('[AppointmentChat] ❌ Consultation start failed - may already be running');
        if (!mounted) return;
        
        // Show error dialog with better message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.amber[50],
            title: const Text('⚠️ مسئلہ', style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            )),
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
                child: const Text('ٹھیک ہے', style: TextStyle(color: Color(0xFF00796B))),
              ),
            ],
          ),
        );
        return;
      }

      print('[AppointmentChat] ✅ Consultation started successfully');

      if (!mounted) return;
      
      // Reload permissions
      _loadPermissions();
      
      _showSnackBar('🟢 Consultation is now live! Connected with $patientName');
    } catch (e) {
      print('[AppointmentChat] ❌ Failed to start consultation: $e');
      if (!mounted) return;
      _showSnackBar('Failed to start consultation: $e', isError: true);
    }
  }

  void _sendMessage() async {
    // Check if appointment has ended
    if (_hasAppointmentEnded()) {
      print('[AppointmentChat] ❌ Appointment has ended - cannot send messages');
      _showSnackBar('Appointment has ended. No new messages allowed.', isError: true);
      return;
    }

    // For doctors, always allow sending once appointment is approved
    if (widget.isDoctor && !_permissions['canRead']!) {
      print('[AppointmentChat] ⚠️ Doctor: Cannot send - appointment not approved yet');
      return;
    }

    // For users, check sending permission
    if (!widget.isDoctor && !_userCanSend) {
      print('[AppointmentChat] ⚠️ User: Cannot send - chat not enabled');
      return;
    }

    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      final currentUserId = _auth.currentUser!.uid;

      print('[AppointmentChat] 📨 Sending message - isDoctor: ${widget.isDoctor}, text: ${messageText.substring(0, 30)}...');

      // Create message
      final message = ChatMessage(
        id: '',
        senderId: currentUserId,
        receiverId: widget.appointment.userId == currentUserId
            ? widget.appointment.doctorId
            : widget.appointment.userId,
        text: messageText,
        appointmentId: widget.appointment.id,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      // Send via service
      await _chatService.sendMessage(message);
      print('[AppointmentChat] ✅ Message sent successfully');

      // If doctor sends any message, enable user to send if not already
      if (widget.isDoctor && !_userCanSend) {
        print('[AppointmentChat] 🔓 Doctor sent message - enabling user to send');
        _onDoctorStartedConversation();
      }

      _scrollToBottom();
    } catch (e) {
      print('[AppointmentChat] ❌ Error sending message: $e');
      _showSnackBar('Failed to send message: $e', isError: true);
      _messageController.text = messageText; // Restore text
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      _showSnackBar('Image upload coming soon!');
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
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

  Future<void> _makePhoneCall() async {
    try {
      // Fetch user's phone number from Firestore
      final userDoc = await _firestore.collection('users').doc(widget.appointment.userId).get();
      final userData = userDoc.data();
      String? phoneNumber = userData?['phone'] ?? userData?['phoneNumber'];
      
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
      _showSnackBar('Error making call: $e', isError: true);
    }
  }

  Future<void> _startVideoCall() async {
    try {
      _showSnackBar('📹 Starting video call setup...');
      
      // Show video call options dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('📹 Start Video Call'),
          content: const Text('Choose how you want to start the video call:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _openWhatsAppVideoCall();
              },
              icon: const Icon(Icons.video_call),
              label: const Text('WhatsApp Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Error starting video call: $e', isError: true);
    }
  }

  Future<void> _openWhatsAppVideoCall() async {
    try {
      // Fetch user's phone number from Firestore
      final userDoc = await _firestore.collection('users').doc(widget.appointment.userId).get();
      final userData = userDoc.data();
      String? phoneNumber = userData?['phone'] ?? userData?['phoneNumber'];
      
      if (phoneNumber == null || phoneNumber.isEmpty) {
        _showSnackBar('Phone number not available', isError: true);
        return;
      }

      // Clean phone number (remove spaces, dashes, etc.)
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Try WhatsApp with intent
      final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone?text=Hi, I want to start a video call');
      
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        _showSnackBar('📱 Opening WhatsApp for video call');
      } else {
        _showSnackBar('WhatsApp is not installed', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error opening WhatsApp: $e', isError: true);
    }
  }

  String _generateChatId(String userId, String doctorId) {
    return userId.compareTo(doctorId) < 0
        ? '${userId}_$doctorId'
        : '${doctorId}_$userId';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('appointments').doc(widget.appointment.id).snapshots(),
        builder: (context, snapshot) {
          // Get real-time appointment status
          String normalizedStatus = 'pending';
          if (snapshot.hasData && snapshot.data != null) {
            final appointmentData = snapshot.data!.data() as Map<String, dynamic>?;
            if (appointmentData != null) {
              normalizedStatus = AppointmentStatusHelper.normalizeStatus(
                appointmentData['status'],
              );
            }
          }

          final appointmentEnded = _hasAppointmentEnded();
          final canSendMessage = !appointmentEnded && (
              widget.isDoctor 
                  ? (_permissions['canRead'] ?? false)
                  : _userCanSend
          );

          // Determine if user can chat based on real-time status
          final userCanChatBasedOnStatus = _canUserChatBasedOnStatus(normalizedStatus, widget.isDoctor);
          final shouldShowLockedBanner = !userCanChatBasedOnStatus && normalizedStatus == 'pending';

          print('[AppointmentChat] 🎨 Building UI - status: $normalizedStatus, canSendMessage: $canSendMessage, userCanChat: $userCanChatBasedOnStatus, isDoctor: ${widget.isDoctor}');

          return Column(
            children: [
              // Status banner - show actual status
              _buildStatusBanner(normalizedStatus, shouldShowLockedBanner),
              
              // Messages list
              Expanded(
                child: _isLoadingPermissions
                    ? const Center(child: CircularProgressIndicator())
                    : userCanChatBasedOnStatus
                        ? _buildMessagesList()
                        : _buildLockedView(normalizedStatus),
              ),
              
              // Input area - show if can send based on real-time status
              if (userCanChatBasedOnStatus && !appointmentEnded)
                _buildInputArea(),
            ],
          );
        },
      ),
    );
  }

  /// Determine if user can chat based on real-time appointment status
  bool _canUserChatBasedOnStatus(String normalizedStatus, bool isDoctor) {
    if (isDoctor) {
      // 🔥 DOCTOR CAN ALWAYS CHAT - IN ALL CASES
      return true;
    } else {
      // User can chat ONLY if: approved
      return normalizedStatus == 'approved';
    }
  }

  /// Build status banner showing the actual appointment status
  Widget _buildStatusBanner(String normalizedStatus, bool showAsLocked) {
    if (!showAsLocked && normalizedStatus != 'approved' && normalizedStatus != 'active') {
      // Show status for non-pending appointments
      Color bannerColor;
      String statusMessage;
      IconData statusIcon;

      switch (normalizedStatus) {
        case 'completed':
          bannerColor = Colors.blue;
          statusMessage = '✅ Appointment Completed';
          statusIcon = Icons.check_circle_outline;
          break;
        case 'declined':
          bannerColor = Colors.red;
          statusMessage = '❌ Appointment Declined';
          statusIcon = Icons.cancel_rounded;
          break;
        default:
          bannerColor = Colors.orange;
          statusMessage = '⏳ Your appointment is pending approval';
          statusIcon = Icons.lock_outline;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: bannerColor.withOpacity(0.1),
        child: Row(
          children: [
            Icon(statusIcon, color: bannerColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                statusMessage,
                style: TextStyle(
                  color: bannerColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (showAsLocked) {
      // Show locked banner for pending approval
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.orange.withOpacity(0.1),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.isDoctor
                    ? '⏳ Appointment awaiting approval'
                    : '⏳ Your appointment is pending approval',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Build locked view with appropriate message based on status
  Widget _buildLockedView(String normalizedStatus) {
    String message;
    if (normalizedStatus == 'pending') {
      message = widget.isDoctor
          ? 'Appointment awaiting approval. Chat will unlock once approved.'
          : 'Appointment pending approval. Chat will unlock once approved.';
    } else if (normalizedStatus == 'declined') {
      message = 'This appointment has been declined.';
    } else if (normalizedStatus == 'completed') {
      message = widget.isDoctor
          ? 'Appointment is completed. You can still send messages.'
          : 'Appointment is completed. You have read-only access.';
    } else {
      message = 'Waiting for appointment approval...';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            normalizedStatus == 'pending'
                ? Icons.lock_outline
                : normalizedStatus == 'declined'
                    ? Icons.cancel_rounded
                    : Icons.check_circle_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF00796B),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.otherUserName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.isDoctor
                ? 'Patient'
                : 'Dr. ${widget.appointment.doctorId}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        // Show Start Consultation button ONLY when appointment time has arrived AND status is 'approved'
        if (widget.isDoctor)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('appointments').doc(widget.appointment.id).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final appointmentData = snapshot.data!.data() as Map<String, dynamic>?;
                  final status = appointmentData?['status'] as String? ?? 'pending';
                  
                  // Only show button if status is 'approved' (not started yet)
                  if (status != 'approved') {
                    return const SizedBox.shrink();
                  }

                  // Check if time has reached
                  return FutureBuilder<bool>(
                    future: _isAppointmentTimeReached(),
                    builder: (context, timeSnapshot) {
                      final isTimeReached = timeSnapshot.data ?? false;
                      final isLoading = _isStartingConsultation;
                      
                      if (isLoading) {
                        return ElevatedButton.icon(
                          onPressed: null,
                          icon: const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          label: const Text('Starting...', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        );
                      }
                      
                      if (!isTimeReached) {
                        final appointmentTime = _parseAppointmentTime();
                        final timeText = appointmentTime != null
                            ? '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}'
                            : '--:--';
                        
                        return Tooltip(
                          message: 'Consultation starts at $timeText',
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.schedule, size: 14),
                            label: Text('Starts $timeText', style: const TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        );
                      }
                      
                      return ElevatedButton.icon(
                        onPressed: _startConsultationButtonPressed,
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('Start', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.white),
          tooltip: 'Make Call',
          onPressed: _makePhoneCall,
        ),
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.white),
          tooltip: 'Video Call',
          onPressed: _startVideoCall,
        ),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: _showAppointmentDetails,
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Error loading messages'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final message = ChatMessage.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            final isMe = message.senderId == _auth.currentUser!.uid;

            return _buildMessageBubble(message, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFF00796B)
                : Colors.grey[200],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text ?? '',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    // Doctor can ALWAYS send (no restrictions)
    // User can send only if explicitly enabled
    final canSendMessage = widget.isDoctor 
        ? true  // 🔥 Doctor ALWAYS can send
        : _userCanSend;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show status banner if NOT ready to send
          if (!canSendMessage && !widget.isDoctor)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, color: Colors.orange, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isDoctor
                          ? '⏳ Waiting for appointment approval'
                          : '⏳ Waiting for doctor to approve appointment',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: canSendMessage ? Colors.grey[300]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: canSendMessage,
                          decoration: InputDecoration(
                            hintText: canSendMessage
                                ? (widget.isDoctor
                                    ? 'Chat with Pet Owner...'
                                    : 'Reply to doctor...')
                                : (widget.isDoctor
                                    ? 'Waiting for approval...'
                                    : 'Waiting for doctor...'),
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      if (canSendMessage)
                        IconButton(
                          icon: const Icon(Icons.image, color: Color(0xFF00796B)),
                          onPressed: _sendImage,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: canSendMessage ? const Color(0xFF00796B) : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: canSendMessage ? _sendMessage : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _showAppointmentDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('📋 Appointment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailTile('Pet:', widget.appointment.animalName),
            _detailTile('Issue:', widget.appointment.problem),
            _detailTile('Date:', _formatDate(widget.appointment.date.toDate())),
            _detailTile('Time:', widget.appointment.time),
            _detailTile('Type:', widget.appointment.consultationType),
            _detailTile('Status:', widget.appointment.status.toUpperCase()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
