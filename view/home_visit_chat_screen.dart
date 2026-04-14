import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_application_1/model/home_visit_appointment_model.dart';
import 'package:flutter_application_1/services/home_visit_chat_service.dart';
import 'package:flutter_application_1/services/home_visit_service.dart';
import 'package:flutter_application_1/services/location_service.dart';

class HomeVisitChatScreen extends StatefulWidget {
  final HomeVisitAppointmentModel appointment;

  const HomeVisitChatScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<HomeVisitChatScreen> createState() => _HomeVisitChatScreenState();
}

class _HomeVisitChatScreenState extends State<HomeVisitChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _locationFetching = false;
  String _userRole = 'user'; // 'doctor' or 'user'
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  void _getUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _userName = userDoc.data()?['name'] ?? user.displayName ?? 'User';
      });

      // Determine if user is doctor or patient
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      if (doctorDoc.exists) {
        setState(() => _userRole = 'doctor');
      } else {
        setState(() => _userRole = 'user');
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      await HomeVisitChatService.sendMessage(
        homeVisitId: widget.appointment.id,
        message: _messageController.text.trim(),
        senderName: _userName,
        senderRole: _userRole,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send message: $e');
    }

    setState(() => _isSending = false);
  }

  void _sendLocation() async {
    setState(() => _locationFetching = true);

    try {
      final position = await LocationService.getUserLocation();

      final address = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      await HomeVisitChatService.sendLocationMessage(
        homeVisitId: widget.appointment.id,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        senderName: _userName,
        senderRole: _userRole,
      );

      _scrollToBottom();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📍 Location shared!')),
      );
    } catch (e) {
      _showError('Failed to send location: $e');
    }

    setState(() => _locationFetching = false);
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    // Simple implementation - you can enhance with actual geocoding
    return '$lat, $lng';
  }

  void _stopLocationSharing() async {
    try {
      await HomeVisitService.disableLiveLocation(widget.appointment.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Location sharing stopped'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      _showError('Error stopping location: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _launchMap(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _makePhoneCallHomeVisit() async {
    try {
      // Fetch user's phone number from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.appointment.userId)
          .get();
      final userData = userDoc.data();
      String? phoneNumber = userData?['phone'] ?? userData?['phoneNumber'];
      
      if (phoneNumber == null || phoneNumber.isEmpty) {
        _showError('Phone number not available');
        return;
      }

      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📞 Initiating call to $phoneNumber'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError('Cannot make calls on this device');
      }
    } catch (e) {
      _showError('Error making call: $e');
    }
  }

  Future<void> _startVideoCallHomeVisit() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📹 Starting video call setup...'),
          backgroundColor: Colors.blue,
        ),
      );
      
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
                _openWhatsAppVideoCallHomeVisit();
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
      _showError('Error starting video call: $e');
    }
  }

  Future<void> _openWhatsAppVideoCallHomeVisit() async {
    try {
      // Fetch user's phone number from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.appointment.userId)
          .get();
      final userData = userDoc.data();
      String? phoneNumber = userData?['phone'] ?? userData?['phoneNumber'];
      
      if (phoneNumber == null || phoneNumber.isEmpty) {
        _showError('Phone number not available');
        return;
      }

      // Clean phone number (remove spaces, dashes, etc.)
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Try WhatsApp with intent
      final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone?text=Hi, I want to start a video call');
      
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 Opening WhatsApp for video call'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError('WhatsApp is not installed');
      }
    } catch (e) {
      _showError('Error opening WhatsApp: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00796B),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏥 ${widget.appointment.animalName}'),
            Text(
              'Status: ${widget.appointment.status}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          if (_userRole == 'user')
            StreamBuilder<Map<String, dynamic>>(
              stream: HomeVisitService.getDoctorLiveLocation(widget.appointment.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final data = snapshot.data!;
                      _launchMap(data['latitude'], data['longitude']);
                    },
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('View Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00796B),
                    ),
                  ),
                );
              },
            )
          else if (_userRole == 'doctor')
            StreamBuilder<Map<String, dynamic>>(
              stream: HomeVisitService.getDoctorLiveLocation(widget.appointment.id),
              builder: (context, snapshot) {
                final isSharing = snapshot.hasData && 
                    (snapshot.data?.isNotEmpty ?? false) &&
                    widget.appointment.liveLocationEnabled;

                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Tooltip(
                    message: isSharing ? 'Stop Location Sharing' : 'Location Not Shared',
                    child: ElevatedButton.icon(
                      onPressed: isSharing ? _stopLocationSharing : null,
                      icon: Icon(
                        isSharing ? Icons.location_on : Icons.location_off,
                        size: 18,
                      ),
                      label: Text(isSharing ? 'Stop' : 'Not Sharing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSharing ? Colors.red : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Live Location Widget (if doctor is on the way)
          if (_userRole == 'user' && widget.appointment.status == 'accepted')
            _buildDoctorLocationWidget(),

          // Status Info Card
          _buildStatusCard(),

          // Chat Messages
          Expanded(
            child: StreamBuilder<List<HomeVisitChatMessage>>(
              stream: HomeVisitChatService.getChatMessages(widget.appointment.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text('No messages yet'),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),

          // Message Input Area
          if (widget.appointment.chatEnabled)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  // Location Button
                  IconButton(
                    onPressed: _locationFetching ? null : _sendLocation,
                    icon: Icon(
                      _locationFetching ? Icons.hourglass_top : Icons.location_on,
                      color: const Color(0xFF00796B),
                    ),
                  ),

                  // Message Input
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send Button
                  CircleAvatar(
                    backgroundColor: const Color(0xFF00796B),
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _getChatDisabledMessage(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.white),
          tooltip: 'Make Call',
          onPressed: _makePhoneCallHomeVisit,
        ),
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.white),
          tooltip: 'Video Call',
          onPressed: _startVideoCallHomeVisit,
        ),
        ],
      ),
    );
  }

  Widget _buildDoctorLocationWidget() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: HomeVisitService.getDoctorLiveLocation(widget.appointment.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
          return const SizedBox.shrink();
        }

        final locationData = snapshot.data!;
        final doctorLat = locationData['latitude'] as double? ?? 0;
        final doctorLng = locationData['longitude'] as double? ?? 0;
        final address = locationData['address'] as String? ?? 'En route';
        final eta = locationData['eta'] as String? ?? 'Calculating...';

        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF80CBC4),
            borderRadius: BorderRadius.circular(12),
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
              const Text(
                '🚗 Doctor is on the way',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ETA',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eta,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _launchMap(doctorLat, doctorLng),
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('View Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00796B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '📍 $address',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.all(12),
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
              Text(
                '${widget.appointment.animalName} - ${widget.appointment.problem}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${widget.appointment.homeVisitFee} - ${widget.appointment.preferredTime}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.appointment.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.appointment.status.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(HomeVisitChatMessage message) {
    final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;

    if (message.messageType == 'status') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message.message,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    if (message.messageType == 'location') {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFF00796B)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: isMe ? Colors.white : Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.locationAddress ?? 'Location shared',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  final lat = double.tryParse(message.locationLatitude ?? '0') ?? 0;
                  final lng = double.tryParse(message.locationLongitude ?? '0') ?? 0;
                  _launchMap(lat, lng);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white.withOpacity(0.2) : Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'View on Map 🗺️',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.blue[700],
                      fontSize: 12,
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

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF00796B) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getChatDisabledMessage() {
    if (widget.appointment.status == 'completed') {
      return '✅ This home visit is completed. Chat is now closed.';
    } else if (widget.appointment.status == 'rejected' || 
               widget.appointment.status == 'cancelled') {
      return '❌ This home visit was ${widget.appointment.status}. Chat is not available.';
    } else {
      return '💬 Chat will be enabled when doctor accepts your request.';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'on_the_way':
        return Colors.blue;
      case 'completed':
        return Colors.teal;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
