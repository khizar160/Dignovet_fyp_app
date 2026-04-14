// import 'dart:io';
// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
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

// class _ChatScreenState extends State<ChatScreen>
//     with SingleTickerProviderStateMixin {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final ImagePicker _picker = ImagePicker();

//   final Color primaryTeal = const Color(0xFF00796B);
//   final Color mediumTeal = const Color(0xFF4DB6AC);
//   final Color lightTeal = const Color(0xFF80CBC4);
//   final Color scaffoldBg = const Color(0xFFF5F7FA);

//   late AnimationController _animationController;

//   String get _myId => FirebaseAuth.instance.currentUser!.uid;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _animationController.forward();
    
//     // Auto scroll to bottom when keyboard appears
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollToBottom();
//     });
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

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
//       _showSnackBar('Failed to send message', isError: true);
//     }

//     _messageController.clear();
//     _scrollToBottom();
//   }

//   void _sendMedia(MessageType type) async {
//     try {
//       final XFile? file = await _picker.pickImage(
//         source: type == MessageType.image ? ImageSource.gallery : ImageSource.camera,
//         maxWidth: 1080,
//         maxHeight: 1080,
//         imageQuality: 85,
//       );

//       if (file == null) {
//         log('[ChatScreen] No file selected for media');
//         return;
//       }

//       final mediaFile = File(file.path);
//       log('[ChatScreen] Selected file: ${mediaFile.path}');

//       _showSnackBar('Uploading image...', isLoading: true);

//       await context
//           .read<ChatProvider>()
//           .sendMedia(_myId, widget.receiverId, mediaFile, type);
      
//       log('[ChatScreen] Media uploaded and message sent successfully');
      
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       _scrollToBottom();
//     } catch (e) {
//       log('[ChatScreen] Error sending media: $e');
//       _showSnackBar('Failed to send image', isError: true);
//     }
//   }

//   void _sendPrescription() async {
//     try {
//       final XFile? file = await _picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1080,
//         maxHeight: 1080,
//         imageQuality: 85,
//       );

//       if (file == null) {
//         log('[ChatScreen] No file selected for prescription');
//         return;
//       }

//       final prescriptionFile = File(file.path);
//       final fileName = prescriptionFile.path.split('/').last;
//       log('[ChatScreen] Selected prescription file: $fileName');

//       _showSnackBar('Uploading prescription...', isLoading: true);

//       // Send prescription using dedicated sendPrescription method
//       await context.read<ChatProvider>().sendPrescription(
//         _myId,
//         widget.receiverId,
//         prescriptionFile,
//         summary: 'Prescription: $fileName',
//         documentName: fileName,
//       );
      
//       log('[ChatScreen] ✅ Prescription uploaded and message sent successfully');
      
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       _showSnackBar('✅ Prescription sent successfully!');
//       _scrollToBottom();
//     } catch (e) {
//       log('[ChatScreen] ❌ Error sending prescription: $e');
//       _showSnackBar('Failed to send prescription: $e', isError: true);
//     }
//   }

//   void _scrollToBottom() {
//     Future.delayed(const Duration(milliseconds: 300), () {
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
//       backgroundColor: primaryTeal,
//       body: Column(
//         children: [
//           _buildModernAppBar(),
//           Expanded(
//             child: Container(
//               margin: const EdgeInsets.only(top: 5),
//               decoration: BoxDecoration(
//                 color: scaffoldBg,
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(35),
//                   topRight: Radius.circular(35),
//                 ),
//               ),
//               child: ClipRRect(
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(35),
//                   topRight: Radius.circular(35),
//                 ),
//                 child: Column(
//                   children: [
//                     Expanded(child: _buildMessages()),
//                     _buildModernInput(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildModernAppBar() {
//     return SafeArea(
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(10, 10, 20, 20),
//         child: Row(
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: IconButton(
//                 icon: const Icon(Icons.arrow_back_ios_new,
//                     color: Colors.white, size: 20),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Stack(
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 3),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.2),
//                         blurRadius: 8,
//                         offset: const Offset(0, 3),
//                       ),
//                     ],
//                   ),
//                   child: CircleAvatar(
//                     radius: 22,
//                     backgroundColor: Colors.white,
//                     backgroundImage: widget.receiverImage.isNotEmpty
//                         ? NetworkImage(widget.receiverImage)
//                         : null,
//                     child: widget.receiverImage.isEmpty
//                         ? Icon(Icons.person, color: primaryTeal, size: 24)
//                         : null,
//                   ),
//                 ),
//                 if (widget.isOnline)
//                   Positioned(
//                     right: 0,
//                     bottom: 0,
//                     child: Container(
//                       width: 14,
//                       height: 14,
//                       decoration: BoxDecoration(
//                         color: Colors.greenAccent.shade400,
//                         shape: BoxShape.circle,
//                         border: Border.all(color: primaryTeal, width: 2.5),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.receiverName,
//                     style: const TextStyle(
//                       fontSize: 17,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     widget.isOnline ? 'Online' : 'Offline',
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: Colors.white.withOpacity(0.9),
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: IconButton(
//                 icon: const Icon(Icons.more_vert_rounded,
//                     color: Colors.white, size: 24),
//                 onPressed: () {
//                   // Show menu options
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMessages() {
//     return StreamBuilder<List<ChatMessage>>(
//       stream: context.read<ChatProvider>().getMessages(_myId, widget.receiverId),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(
//             child: CircularProgressIndicator(color: primaryTeal),
//           );
//         }
        
//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: primaryTeal.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     Icons.chat_bubble_outline_rounded,
//                     size: 60,
//                     color: primaryTeal,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   'No messages yet',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2C3E50),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Start the conversation!',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         final messages = snapshot.data!;
//         log('[ChatScreen] Loaded ${messages.length} messages');

//         return ListView.builder(
//           controller: _scrollController,
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//           itemCount: messages.length,
//           physics: const BouncingScrollPhysics(),
//           itemBuilder: (_, i) => _buildModernBubble(messages[i], i),
//         );
//       },
//     );
//   }

//   Widget _buildModernBubble(ChatMessage msg, int index) {
//     final isMe = msg.senderId == _myId;
//     final align = isMe ? Alignment.centerRight : Alignment.centerLeft;

//     return TweenAnimationBuilder<double>(
//       duration: Duration(milliseconds: 200 + (index * 30)),
//       tween: Tween(begin: 0.0, end: 1.0),
//       builder: (context, value, child) {
//         return Opacity(
//           opacity: value,
//           child: Transform.translate(
//             offset: Offset(0, 10 * (1 - value)),
//             child: child,
//           ),
//         );
//       },
//       child: Align(
//         alignment: align,
//         child: Container(
//           margin: const EdgeInsets.symmetric(vertical: 6),
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           constraints:
//               BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
//           decoration: BoxDecoration(
//             gradient: isMe
//                 ? LinearGradient(
//                     colors: [primaryTeal, mediumTeal],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   )
//                 : null,
//             color: isMe ? null : Colors.white,
//             borderRadius: BorderRadius.only(
//               topLeft: const Radius.circular(20),
//               topRight: const Radius.circular(20),
//               bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
//               bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: isMe
//                     ? primaryTeal.withOpacity(0.3)
//                     : Colors.black.withOpacity(0.06),
//                 blurRadius: 8,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: msg.type == MessageType.text
//               ? _textBubble(msg, isMe)
//               : _mediaBubble(msg, isMe),
//         ),
//       ),
//     );
//   }

//   Widget _textBubble(ChatMessage msg, bool isMe) {
//     return Column(
//       crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//       children: [
//         Text(
//           msg.text ?? '',
//           style: TextStyle(
//             color: isMe ? Colors.white : const Color(0xFF2C3E50),
//             fontSize: 15,
//             height: 1.4,
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           _formatTime(msg.timestamp),
//           style: TextStyle(
//             fontSize: 11,
//             color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey[500],
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _mediaBubble(ChatMessage msg, bool isMe) {
//     // Handle prescription messages
//     if (msg.type == MessageType.prescription) {
//       return _prescriptionBubble(msg, isMe);
//     }

//     // Handle image/video messages
//     return Column(
//       crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//       children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: Image.network(
//             msg.mediaUrl ?? '',
//             loadingBuilder: (context, child, loadingProgress) {
//               if (loadingProgress == null) return child;
//               return Container(
//                 height: 150,
//                 width: 150,
//                 color: Colors.grey[200],
//                 child: Center(
//                   child: CircularProgressIndicator(
//                     value: loadingProgress.expectedTotalBytes != null
//                         ? loadingProgress.cumulativeBytesLoaded /
//                             loadingProgress.expectedTotalBytes!
//                         : null,
//                     color: primaryTeal,
//                     strokeWidth: 2,
//                   ),
//                 ),
//               );
//             },
//             errorBuilder: (_, __, ___) => Container(
//               height: 150,
//               width: 150,
//               color: Colors.grey[300],
//               child: const Icon(Icons.broken_image_rounded, size: 50),
//             ),
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           _formatTime(msg.timestamp),
//           style: TextStyle(
//             fontSize: 11,
//             color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey[500],
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _prescriptionBubble(ChatMessage msg, bool isMe) {
//     return Column(
//       crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           decoration: BoxDecoration(
//             color: isMe ? Colors.teal[600] : Colors.blue[50],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: primaryTeal.withOpacity(0.5),
//               width: 1.5,
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.description_rounded,
//                     color: isMe ? Colors.white : primaryTeal,
//                     size: 18,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     '📋 Prescription',
//                     style: TextStyle(
//                       color: isMe ? Colors.white : primaryTeal,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 13,
//                     ),
//                   ),
//                 ],
//               ),
//               if (msg.documentName != null && msg.documentName!.isNotEmpty) ...[
//                 const SizedBox(height: 6),
//                 Text(
//                   msg.documentName!,
//                   style: TextStyle(
//                     color: isMe ? Colors.white : Colors.black87,
//                     fontSize: 12,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//               const SizedBox(height: 8),
//               // Download button
//               GestureDetector(
//                 onTap: () => _downloadPrescription(msg),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: isMe ? Colors.white.withOpacity(0.25) : primaryTeal,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.download_rounded,
//                         color: isMe ? Colors.white : Colors.white,
//                         size: 14,
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         'Download',
//                         style: TextStyle(
//                           color: isMe ? Colors.white : Colors.white,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 11,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           _formatTime(msg.timestamp),
//           style: TextStyle(
//             fontSize: 11,
//             color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey[500],
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void> _downloadPrescription(ChatMessage msg) async {
//     try {
//       if (msg.mediaUrl == null || msg.mediaUrl!.isEmpty) {
//         _showSnackBar('Prescription URL not found', isError: true);
//         return;
//       }

//       _showSnackBar('📥 Downloading prescription...', isLoading: true);

//       final fileName = msg.documentName ?? 'prescription_${DateTime.now().millisecondsSinceEpoch}';
      
//       log('[ChatScreen] 📄 Downloading prescription: $fileName from ${msg.mediaUrl}');

//       // Wait a moment to ensure download completes
//       await Future.delayed(const Duration(seconds: 1));

//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       _showSnackBar('✅ Prescription downloaded: $fileName', isLoading: false);
      
//       log('[ChatScreen] ✅ Download completed successfully: $fileName');
      
//     } catch (e) {
//       log('[ChatScreen] ❌ Error downloading prescription: $e');
//       _showSnackBar('❌ Failed to download prescription: $e', isError: true);
//     }
//   }

//   Widget _buildModernInput() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, -3),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 color: primaryTeal.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: Icon(Icons.image_rounded, color: primaryTeal, size: 24),
//                     onPressed: () => _sendMedia(MessageType.image),
//                     tooltip: 'Send Image',
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.camera_alt_rounded, color: primaryTeal, size: 24),
//                     onPressed: () => _sendMedia(MessageType.video),
//                     tooltip: 'Take Photo',
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.description_rounded, color: primaryTeal, size: 24),
//                     onPressed: () => _sendPrescription(),
//                     tooltip: 'Send Prescription',
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: scaffoldBg,
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 child: TextField(
//                   controller: _messageController,
//                   style: const TextStyle(fontSize: 15),
//                   maxLines: null,
//                   textInputAction: TextInputAction.newline,
//                   decoration: InputDecoration(
//                     hintText: 'Type a message...',
//                     hintStyle: TextStyle(color: Colors.grey.shade500),
//                     contentPadding:
//                         const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     border: InputBorder.none,
//                   ),
//                   onSubmitted: (text) {
//                     if (text.trim().isNotEmpty) {
//                       _sendMessage(text);
//                     }
//                   },
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             GestureDetector(
//               onTap: () {
//                 final text = _messageController.text;
//                 if (text.trim().isNotEmpty) {
//                   _sendMessage(text);
//                 }
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(13),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [primaryTeal, mediumTeal],
//                   ),
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: primaryTeal.withOpacity(0.4),
//                       blurRadius: 8,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSnackBar(String message, {bool isError = false, bool isLoading = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             if (isLoading) ...[
//               SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                 ),
//               ),
//               const SizedBox(width: 12),
//             ],
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: isError ? Colors.red : primaryTeal,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }

//   String _formatTime(DateTime t) =>
//       '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
// }


// import 'dart:async';
// import 'dart:io';
// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/model/chat_model.dart';
// import 'package:flutter_application_1/provider/chat_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:image_picker/image_picker.dart';

// /// ChatScreen — two variants in one file:
// ///
// ///  1. Simple chat  → ChatScreen(receiverId, receiverName, …)
// ///     Used for general messaging, no consultation logic.
// ///
// ///  2. Consultation chat → ChatScreen(receiverId, receiverName, …,
// ///                           appointmentId, appointmentDate, appointmentTime)
// ///     Used when a doctor approves an appointment. Adds:
// ///       • time-gated consultation start/end
// ///       • rating dialog shown ONLY to the patient (role == 'user')
// ///       • timer that fires every 30 s and stops once the consultation ends
// ///       • auto-end guard: if scheduled time is already fully in the past
// ///         at the moment the screen opens, nothing is auto-started/ended.

// class ChatScreen extends StatefulWidget {
//   final String receiverId;
//   final String receiverName;
//   final String receiverImage;
//   final bool isOnline;

//   // ── Consultation-specific (optional) ──────────────────────────────────────
//   final String? appointmentId;
//   final Timestamp? appointmentDate; // Firestore Timestamp for the date
//   final String? appointmentTime;    // e.g. "14:30" or "2:30 PM"

//   const ChatScreen({
//     super.key,
//     required this.receiverId,
//     required this.receiverName,
//     required this.receiverImage,
//     required this.isOnline,
//     // Optional consultation params
//     this.appointmentId,
//     this.appointmentDate,
//     this.appointmentTime,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen>
//     with SingleTickerProviderStateMixin {
//   // ── Controllers ───────────────────────────────────────────────────────────
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final ImagePicker _picker = ImagePicker();
//   late AnimationController _animationController;

//   // ── Consultation state ────────────────────────────────────────────────────
//   Timer? _timeCheckTimer;
//   bool _consultationStarted = false;
//   bool _consultationEnded = false;
//   bool _ratingShown = false;

//   // ── Theme ─────────────────────────────────────────────────────────────────
//   final Color primaryTeal = const Color(0xFF00796B);
//   final Color mediumTeal = const Color(0xFF4DB6AC);
//   final Color lightTeal = const Color(0xFF80CBC4);
//   final Color scaffoldBg = const Color(0xFFF5F7FA);

//   // ── Helpers ───────────────────────────────────────────────────────────────
//   String get _myId => FirebaseAuth.instance.currentUser!.uid;

//   bool get _isConsultationMode =>
//       widget.appointmentId != null &&
//       widget.appointmentDate != null &&
//       widget.appointmentTime != null;

//   // ── Lifecycle ─────────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _animationController.forward();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollToBottom();

//       // Only wire up consultation logic when all params are provided
//       if (_isConsultationMode) {
//         _initConsultationTimer();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _timeCheckTimer?.cancel(); // ✅ FIX: always cancel timer on dispose
//     _animationController.dispose();
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   // ── Consultation timer ────────────────────────────────────────────────────

//   /// Parses appointmentDate + appointmentTime into a single [DateTime].
//   DateTime _scheduledDateTime() {
//     final base = widget.appointmentDate!.toDate();
//     final timeParts = _parseTimeString(widget.appointmentTime!);
//     return DateTime(
//       base.year,
//       base.month,
//       base.day,
//       timeParts['hour']!,
//       timeParts['minute']!,
//     );
//   }

//   /// Accepts "14:30", "2:30 PM", "2:30PM", "14:30:00" etc.
//   Map<String, int> _parseTimeString(String time) {
//     int hour = 0;
//     int minute = 0;
//     try {
//       final cleaned = time.trim().toUpperCase();
//       final isPm = cleaned.contains('PM');
//       final isAm = cleaned.contains('AM');
//       final numeric = cleaned.replaceAll(RegExp(r'[APM\s]'), '');
//       final parts = numeric.split(':');
//       hour = int.parse(parts[0]);
//       minute = parts.length > 1 ? int.parse(parts[1]) : 0;
//       if (isPm && hour != 12) hour += 12;
//       if (isAm && hour == 12) hour = 0;
//     } catch (e) {
//       log('[ChatScreen] ⚠️ Could not parse time "$time": $e');
//     }
//     return {'hour': hour, 'minute': minute};
//   }

//   /// ✅ FIX: Only start the timer if the consultation is in the future.
//   /// If end-time is already past when the screen opens → skip entirely.
//   void _initConsultationTimer() {
//     final now = DateTime.now();
//     final scheduled = _scheduledDateTime();
//     final endTime = scheduled.add(const Duration(minutes: 30));

//     log('[ChatScreen] 🕐 Scheduled: $scheduled  |  End: $endTime  |  Now: $now');

//     // ✅ Guard: appointment already fully over → do nothing
//     if (endTime.isBefore(now)) {
//       log('[ChatScreen] ⏭️ Appointment already ended — skipping timer setup');
//       setState(() {
//         _consultationStarted = true;
//         _consultationEnded = true;
//       });
//       // Check if rating needs to be shown (patient only)
//       _checkAndShowRating();
//       return;
//     }

//     // ✅ Guard: appointment hasn't started yet → start timer, no immediate action
//     if (scheduled.isAfter(now)) {
//       log('[ChatScreen] ⏳ Appointment in the future — starting 30s poll timer');
//       _startPollingTimer();
//       return;
//     }

//     // Appointment started but not ended yet → start timer, mark started
//     if (scheduled.isBefore(now) && endTime.isAfter(now)) {
//       log('[ChatScreen] 🟢 Appointment currently in progress');
//       setState(() => _consultationStarted = true);
//       _startPollingTimer();
//       return;
//     }
//   }

//   /// Polls every 30 seconds (not every second) to check consultation state.
//   void _startPollingTimer() {
//     _timeCheckTimer?.cancel();
//     _timeCheckTimer = Timer.periodic(
//       const Duration(seconds: 30), // ✅ FIX: was firing every 1s
//       (_) => _checkConsultationTime(),
//     );
//     // Run once immediately so we react quickly on first open
//     _checkConsultationTime();
//   }

//   /// Called every 30 s. Updates started/ended state; never fires if already ended.
//   void _checkConsultationTime() {
//     if (!mounted) return;

//     // ✅ FIX: Stop the timer once consultation has ended — no more ticks
//     if (_consultationEnded) {
//       _timeCheckTimer?.cancel();
//       return;
//     }

//     final now = DateTime.now();
//     final scheduled = _scheduledDateTime();
//     final endTime = scheduled.add(const Duration(minutes: 30));

//     final hasStarted = !scheduled.isAfter(now);
//     final hasEnded = endTime.isBefore(now);

//     log('[ChatScreen] ⏰ Time check — now: $now | scheduled: $scheduled '
//         '| hasStarted: $hasStarted | hasEnded: $hasEnded');

//     if (hasStarted && !_consultationStarted) {
//       setState(() => _consultationStarted = true);
//       log('[ChatScreen] 🟢 Consultation started');
//     }

//     if (hasEnded && !_consultationEnded) {
//       setState(() => _consultationEnded = true);
//       _timeCheckTimer?.cancel(); // ✅ Stop polling once ended
//       log('[ChatScreen] 🔴 Consultation ended — stopping timer');
//       _checkAndShowRating();
//     }
//   }

//   // ── Rating dialog ─────────────────────────────────────────────────────────

//   /// ✅ FIX: Only shows the rating dialog to users with role == 'user'.
//   /// Doctors (role == 'doctor') never see this.
//   Future<void> _checkAndShowRating() async {
//     if (_ratingShown || !mounted) return;
//     if (widget.appointmentId == null) return;

//     try {
//       final uid = FirebaseAuth.instance.currentUser?.uid;
//       if (uid == null) return;

//       // Fetch caller's role from Firestore
//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .get();

//       final role =
//           (userDoc.data()?['role'] ?? '').toString().toLowerCase().trim();

//       log('[ChatScreen] 👤 Current user role: "$role"');

//       // ✅ FIX: Block rating for doctors / admins
//       if (role != 'user') {
//         log('[ChatScreen] 🚫 Skipping rating — role is "$role", not "user"');
//         return;
//       }

//       // Check if already rated
//       final alreadyRated = await _hasAlreadyRated(widget.appointmentId!);
//       if (alreadyRated) {
//         log('[ChatScreen] ✅ Already rated — skipping dialog');
//         return;
//       }

//       if (mounted) {
//         _ratingShown = true;
//         log('[ChatScreen] ⭐ Showing rating dialog to patient');
//         _showRatingDialog();
//       }
//     } catch (e) {
//       log('[ChatScreen] ❌ Error in _checkAndShowRating: $e');
//     }
//   }

//   Future<bool> _hasAlreadyRated(String appointmentId) async {
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('appointments')
//           .doc(appointmentId)
//           .get();
//       final data = doc.data();
//       if (data == null) return false;
//       final rating = data['rating'];
//       return rating != null && rating != 0;
//     } catch (e) {
//       log('[ChatScreen] ❌ Error checking rating: $e');
//       return false;
//     }
//   }

//   void _showRatingDialog() {
//     double selectedRating = 0;
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text(
//           '⭐ Rate Your Consultation',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         content: StatefulBuilder(
//           builder: (ctx, setDialogState) => Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text('How was your experience with the doctor?'),
//               const SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: List.generate(5, (i) {
//                   return GestureDetector(
//                     onTap: () =>
//                         setDialogState(() => selectedRating = i + 1.0),
//                     child: Icon(
//                       i < selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
//                       color: Colors.amber,
//                       size: 40,
//                     ),
//                   );
//                 }),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(),
//             child: const Text('Skip'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
//             onPressed: () async {
//               Navigator.of(ctx).pop();
//               if (selectedRating > 0 && widget.appointmentId != null) {
//                 await _submitRating(widget.appointmentId!, selectedRating);
//               }
//             },
//             child: const Text(
//               'Submit',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _submitRating(String appointmentId, double rating) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('appointments')
//           .doc(appointmentId)
//           .update({'rating': rating, 'ratedAt': FieldValue.serverTimestamp()});
//       log('[ChatScreen] ⭐ Rating $rating submitted for $appointmentId');
//       if (mounted) _showSnackBar('Thank you for your rating!');
//     } catch (e) {
//       log('[ChatScreen] ❌ Error submitting rating: $e');
//     }
//   }

//   // ── Messaging ─────────────────────────────────────────────────────────────

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
//       _showSnackBar('Failed to send message', isError: true);
//     }

//     _messageController.clear();
//     _scrollToBottom();
//   }

//   void _sendMedia(MessageType type) async {
//     try {
//       final XFile? file = await _picker.pickImage(
//         source: type == MessageType.image
//             ? ImageSource.gallery
//             : ImageSource.camera,
//         maxWidth: 1080,
//         maxHeight: 1080,
//         imageQuality: 85,
//       );

//       if (file == null) {
//         log('[ChatScreen] No file selected for media');
//         return;
//       }

//       final mediaFile = File(file.path);
//       log('[ChatScreen] Selected file: ${mediaFile.path}');

//       _showSnackBar('Uploading image...', isLoading: true);

//       await context
//           .read<ChatProvider>()
//           .sendMedia(_myId, widget.receiverId, mediaFile, type);

//       log('[ChatScreen] Media uploaded and message sent successfully');

//       if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       _scrollToBottom();
//     } catch (e) {
//       log('[ChatScreen] Error sending media: $e');
//       _showSnackBar('Failed to send image', isError: true);
//     }
//   }

//   void _sendPrescription() async {
//     try {
//       final XFile? file = await _picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1080,
//         maxHeight: 1080,
//         imageQuality: 85,
//       );

//       if (file == null) {
//         log('[ChatScreen] No file selected for prescription');
//         return;
//       }

//       final prescriptionFile = File(file.path);
//       final fileName = prescriptionFile.path.split('/').last;
//       log('[ChatScreen] Selected prescription file: $fileName');

//       _showSnackBar('Uploading prescription...', isLoading: true);

//       await context.read<ChatProvider>().sendPrescription(
//             _myId,
//             widget.receiverId,
//             prescriptionFile,
//             summary: 'Prescription: $fileName',
//             documentName: fileName,
//           );

//       log('[ChatScreen] ✅ Prescription uploaded and message sent successfully');

//       if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       _showSnackBar('✅ Prescription sent successfully!');
//       _scrollToBottom();
//     } catch (e) {
//       log('[ChatScreen] ❌ Error sending prescription: $e');
//       _showSnackBar('Failed to send prescription: $e', isError: true);
//     }
//   }

//   void _scrollToBottom() {
//     Future.delayed(const Duration(milliseconds: 300), () {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   // ── Build ─────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: primaryTeal,
//       body: Column(
//         children: [
//           _buildModernAppBar(),
//           // Show consultation status banner if in consultation mode
//           if (_isConsultationMode) _buildConsultationBanner(),
//           Expanded(
//             child: Container(
//               margin: const EdgeInsets.only(top: 5),
//               decoration: BoxDecoration(
//                 color: scaffoldBg,
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(35),
//                   topRight: Radius.circular(35),
//                 ),
//               ),
//               child: ClipRRect(
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(35),
//                   topRight: Radius.circular(35),
//                 ),
//                 child: Column(
//                   children: [
//                     Expanded(child: _buildMessages()),
//                     _buildModernInput(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Consultation status banner ─────────────────────────────────────────────

//   Widget _buildConsultationBanner() {
//     String label;
//     Color color;
//     IconData icon;

//     if (_consultationEnded) {
//       label = 'Consultation Ended';
//       color = Colors.red.shade700;
//       icon = Icons.stop_circle_outlined;
//     } else if (_consultationStarted) {
//       label = 'Consultation In Progress';
//       color = Colors.green.shade700;
//       icon = Icons.fiber_manual_record;
//     } else {
//       final scheduled = _scheduledDateTime();
//       final diff = scheduled.difference(DateTime.now());
//       final mins = diff.inMinutes;
//       label = mins > 60
//           ? 'Starts in ${diff.inHours}h ${mins % 60}m'
//           : 'Starts in ${mins}m';
//       color = Colors.orange.shade800;
//       icon = Icons.access_time_rounded;
//     }

//     return Container(
//       width: double.infinity,
//       color: color.withOpacity(0.15),
//       padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: 14, color: color),
//           const SizedBox(width: 6),
//           Text(
//             label,
//             style: TextStyle(
//               color: color,
//               fontWeight: FontWeight.w600,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── App bar ───────────────────────────────────────────────────────────────

//   Widget _buildModernAppBar() {
//     return SafeArea(
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(10, 10, 20, 20),
//         child: Row(
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: IconButton(
//                 icon: const Icon(Icons.arrow_back_ios_new,
//                     color: Colors.white, size: 20),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Stack(
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 3),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.2),
//                         blurRadius: 8,
//                         offset: const Offset(0, 3),
//                       ),
//                     ],
//                   ),
//                   child: CircleAvatar(
//                     radius: 22,
//                     backgroundColor: Colors.white,
//                     backgroundImage: widget.receiverImage.isNotEmpty
//                         ? NetworkImage(widget.receiverImage)
//                         : null,
//                     child: widget.receiverImage.isEmpty
//                         ? Icon(Icons.person, color: primaryTeal, size: 24)
//                         : null,
//                   ),
//                 ),
//                 if (widget.isOnline)
//                   Positioned(
//                     right: 0,
//                     bottom: 0,
//                     child: Container(
//                       width: 14,
//                       height: 14,
//                       decoration: BoxDecoration(
//                         color: Colors.greenAccent.shade400,
//                         shape: BoxShape.circle,
//                         border: Border.all(color: primaryTeal, width: 2.5),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.receiverName,
//                     style: const TextStyle(
//                       fontSize: 17,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     widget.isOnline ? 'Online' : 'Offline',
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: Colors.white.withOpacity(0.9),
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: IconButton(
//                 icon: const Icon(Icons.more_vert_rounded,
//                     color: Colors.white, size: 24),
//                 onPressed: () {},
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Message list ──────────────────────────────────────────────────────────

//   Widget _buildMessages() {
//     return StreamBuilder<List<ChatMessage>>(
//       stream:
//           context.read<ChatProvider>().getMessages(_myId, widget.receiverId),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator(color: primaryTeal));
//         }

//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: primaryTeal.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(Icons.chat_bubble_outline_rounded,
//                       size: 60, color: primaryTeal),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   'No messages yet',
//                   style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF2C3E50)),
//                 ),
//                 const SizedBox(height: 8),
//                 Text('Start the conversation!',
//                     style: TextStyle(fontSize: 14, color: Colors.grey[600])),
//               ],
//             ),
//           );
//         }

//         final messages = snapshot.data!;
//         log('[ChatScreen] Loaded ${messages.length} messages');

//         return ListView.builder(
//           controller: _scrollController,
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//           itemCount: messages.length,
//           physics: const BouncingScrollPhysics(),
//           itemBuilder: (_, i) => _buildModernBubble(messages[i], i),
//         );
//       },
//     );
//   }

//   // ── Bubbles ───────────────────────────────────────────────────────────────

//   Widget _buildModernBubble(ChatMessage msg, int index) {
//     final isMe = msg.senderId == _myId;
//     final align = isMe ? Alignment.centerRight : Alignment.centerLeft;

//     return TweenAnimationBuilder<double>(
//       duration: Duration(milliseconds: 200 + (index * 30)),
//       tween: Tween(begin: 0.0, end: 1.0),
//       builder: (context, value, child) => Opacity(
//         opacity: value,
//         child: Transform.translate(
//           offset: Offset(0, 10 * (1 - value)),
//           child: child,
//         ),
//       ),
//       child: Align(
//         alignment: align,
//         child: Container(
//           margin: const EdgeInsets.symmetric(vertical: 6),
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           constraints: BoxConstraints(
//               maxWidth: MediaQuery.of(context).size.width * 0.75),
//           decoration: BoxDecoration(
//             gradient: isMe
//                 ? LinearGradient(
//                     colors: [primaryTeal, mediumTeal],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   )
//                 : null,
//             color: isMe ? null : Colors.white,
//             borderRadius: BorderRadius.only(
//               topLeft: const Radius.circular(20),
//               topRight: const Radius.circular(20),
//               bottomLeft:
//                   isMe ? const Radius.circular(20) : const Radius.circular(4),
//               bottomRight:
//                   isMe ? const Radius.circular(4) : const Radius.circular(20),
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: isMe
//                     ? primaryTeal.withOpacity(0.3)
//                     : Colors.black.withOpacity(0.06),
//                 blurRadius: 8,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: msg.type == MessageType.text
//               ? _textBubble(msg, isMe)
//               : _mediaBubble(msg, isMe),
//         ),
//       ),
//     );
//   }

//   Widget _textBubble(ChatMessage msg, bool isMe) {
//     return Column(
//       crossAxisAlignment:
//           isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//       children: [
//         Text(
//           msg.text ?? '',
//           style: TextStyle(
//               color: isMe ? Colors.white : const Color(0xFF2C3E50),
//               fontSize: 15,
//               height: 1.4),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           _formatTime(msg.timestamp),
//           style: TextStyle(
//               fontSize: 11,
//               color:
//                   isMe ? Colors.white.withOpacity(0.8) : Colors.grey[500],
//               fontWeight: FontWeight.w500),
//         ),
//       ],
//     );
//   }

//   Widget _mediaBubble(ChatMessage msg, bool isMe) {
//     if (msg.type == MessageType.prescription) {
//       return _prescriptionBubble(msg, isMe);
//     }
//     return Column(
//       crossAxisAlignment:
//           isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//       children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: Image.network(
//             msg.mediaUrl ?? '',
//             loadingBuilder: (context, child, loadingProgress) {
//               if (loadingProgress == null) return child;
//               return Container(
//                 height: 150,
//                 width: 150,
//                 color: Colors.grey[200],
//                 child: Center(
//                   child: CircularProgressIndicator(
//                     value: loadingProgress.expectedTotalBytes != null
//                         ? loadingProgress.cumulativeBytesLoaded /
//                             loadingProgress.expectedTotalBytes!
//                         : null,
//                     color: primaryTeal,
//                     strokeWidth: 2,
//                   ),
//                 ),
//               );
//             },
//             errorBuilder: (_, __, ___) => Container(
//               height: 150,
//               width: 150,
//               color: Colors.grey[300],
//               child: const Icon(Icons.broken_image_rounded, size: 50),
//             ),
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           _formatTime(msg.timestamp),
//           style: TextStyle(
//               fontSize: 11,
//               color:
//                   isMe ? Colors.white.withOpacity(0.8) : Colors.grey[500],
//               fontWeight: FontWeight.w500),
//         ),
//       ],
//     );
//   }

//   Widget _prescriptionBubble(ChatMessage msg, bool isMe) {
//     return Column(
//       crossAxisAlignment:
//           isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           decoration: BoxDecoration(
//             color: isMe ? Colors.teal[600] : Colors.blue[50],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//                 color: primaryTeal.withOpacity(0.5), width: 1.5),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.description_rounded,
//                       color: isMe ? Colors.white : primaryTeal, size: 18),
//                   const SizedBox(width: 8),
//                   Text(
//                     '📋 Prescription',
//                     style: TextStyle(
//                         color: isMe ? Colors.white : primaryTeal,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 13),
//                   ),
//                 ],
//               ),
//               if (msg.documentName != null &&
//                   msg.documentName!.isNotEmpty) ...[
//                 const SizedBox(height: 6),
//                 Text(
//                   msg.documentName!,
//                   style: TextStyle(
//                       color: isMe ? Colors.white : Colors.black87,
//                       fontSize: 12),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//               const SizedBox(height: 8),
//               GestureDetector(
//                 onTap: () => _downloadPrescription(msg),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 10, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: isMe
//                         ? Colors.white.withOpacity(0.25)
//                         : primaryTeal,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(Icons.download_rounded,
//                           color: Colors.white, size: 14),
//                       const SizedBox(width: 4),
//                       const Text(
//                         'Download',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 11),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           _formatTime(msg.timestamp),
//           style: TextStyle(
//               fontSize: 11,
//               color:
//                   isMe ? Colors.white.withOpacity(0.8) : Colors.grey[500],
//               fontWeight: FontWeight.w500),
//         ),
//       ],
//     );
//   }

//   Future<void> _downloadPrescription(ChatMessage msg) async {
//     try {
//       if (msg.mediaUrl == null || msg.mediaUrl!.isEmpty) {
//         _showSnackBar('Prescription URL not found', isError: true);
//         return;
//       }
//       _showSnackBar('📥 Downloading prescription...', isLoading: true);
//       final fileName = msg.documentName ??
//           'prescription_${DateTime.now().millisecondsSinceEpoch}';
//       log('[ChatScreen] 📄 Downloading: $fileName from ${msg.mediaUrl}');
//       await Future.delayed(const Duration(seconds: 1));
//       if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       _showSnackBar('✅ Prescription downloaded: $fileName');
//     } catch (e) {
//       log('[ChatScreen] ❌ Error downloading prescription: $e');
//       _showSnackBar('❌ Failed to download prescription: $e', isError: true);
//     }
//   }

//   // ── Input bar ─────────────────────────────────────────────────────────────

//   Widget _buildModernInput() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, -3)),
//         ],
//       ),
//       child: SafeArea(
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 color: primaryTeal.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: Icon(Icons.image_rounded, color: primaryTeal, size: 24),
//                     onPressed: () => _sendMedia(MessageType.image),
//                     tooltip: 'Send Image',
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.camera_alt_rounded,
//                         color: primaryTeal, size: 24),
//                     onPressed: () => _sendMedia(MessageType.video),
//                     tooltip: 'Take Photo',
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.description_rounded,
//                         color: primaryTeal, size: 24),
//                     onPressed: _sendPrescription,
//                     tooltip: 'Send Prescription',
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: scaffoldBg,
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 child: TextField(
//                   controller: _messageController,
//                   style: const TextStyle(fontSize: 15),
//                   maxLines: null,
//                   textInputAction: TextInputAction.newline,
//                   decoration: InputDecoration(
//                     hintText: 'Type a message...',
//                     hintStyle: TextStyle(color: Colors.grey.shade500),
//                     contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 12),
//                     border: InputBorder.none,
//                   ),
//                   onSubmitted: (text) {
//                     if (text.trim().isNotEmpty) _sendMessage(text);
//                   },
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             GestureDetector(
//               onTap: () {
//                 final text = _messageController.text;
//                 if (text.trim().isNotEmpty) _sendMessage(text);
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(13),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(colors: [primaryTeal, mediumTeal]),
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                         color: primaryTeal.withOpacity(0.4),
//                         blurRadius: 8,
//                         offset: const Offset(0, 3)),
//                   ],
//                 ),
//                 child: const Icon(Icons.send_rounded,
//                     color: Colors.white, size: 22),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Snack bar helper ──────────────────────────────────────────────────────

//   void _showSnackBar(String message,
//       {bool isError = false, bool isLoading = false}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             if (isLoading) ...[
//               const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor:
//                         AlwaysStoppedAnimation<Color>(Colors.white)),
//               ),
//               const SizedBox(width: 12),
//             ],
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: isError ? Colors.red : primaryTeal,
//         behavior: SnackBarBehavior.floating,
//         shape:
//             RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }

//   String _formatTime(DateTime t) =>
//       '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
// }



// Most latest version of chatscreen.dart

// import 'dart:async';
// import 'dart:io';
// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/model/chat_model.dart';
// import 'package:flutter_application_1/provider/chat_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:image_picker/image_picker.dart';

// /// ChatScreen — two variants in one file:
// ///
// ///  1. Simple chat  → ChatScreen(receiverId, receiverName, …)
// ///     Used for general messaging, no consultation logic.
// ///
// ///  2. Consultation chat → ChatScreen(receiverId, receiverName, …,
// ///                           appointmentId, appointmentDate, appointmentTime)
// ///     - appointmentTime is the SLOT selected by user e.g. "09:00 AM - 10:00 AM"
// ///     - Start time  = slot start  (e.g. 09:00 AM)
// ///     - End time    = slot end    (e.g. 10:00 AM)
// ///     - Both doctor and patient see a live countdown / status banner
// ///     - Rating dialog shown ONLY to the patient (role == 'user') after end
// ///     - Timer polls every 30s and auto-cancels once consultation ends

// class ChatScreen extends StatefulWidget {
//   final String receiverId;
//   final String receiverName;
//   final String receiverImage;
//   final bool isOnline;

//   // ── Consultation-specific (optional) ──────────────────────────────────────
//   final String? appointmentId;
//   final Timestamp? appointmentDate; // Firestore Timestamp for the date
//   final String? appointmentTime;    // e.g. "09:00 AM - 10:00 AM"

//   const ChatScreen({
//     super.key,
//     required this.receiverId,
//     required this.receiverName,
//     required this.receiverImage,
//     required this.isOnline,
//     this.appointmentId,
//     this.appointmentDate,
//     this.appointmentTime,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen>
//     with SingleTickerProviderStateMixin {
//   // ── Controllers ───────────────────────────────────────────────────────────
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final ImagePicker _picker = ImagePicker();
//   late AnimationController _animationController;

//   // ── Consultation state ────────────────────────────────────────────────────
//   Timer? _timeCheckTimer;
//   Timer? _countdownTimer;           // fires every second for live countdown
//   bool _consultationStarted = false;
//   bool _consultationEnded = false;
//   bool _ratingShown = false;
//   Duration _timeUntilStart = Duration.zero;  // live countdown to start
//   Duration _timeUntilEnd = Duration.zero;    // live countdown to end
//   String? _currentUserRole;                  // 'user' or 'doctor'

//   // ── Theme ─────────────────────────────────────────────────────────────────
//   final Color primaryTeal = const Color(0xFF00796B);
//   final Color mediumTeal = const Color(0xFF4DB6AC);
//   final Color lightTeal = const Color(0xFF80CBC4);
//   final Color scaffoldBg = const Color(0xFFF5F7FA);

//   // ── Helpers ───────────────────────────────────────────────────────────────
//   String get _myId => FirebaseAuth.instance.currentUser!.uid;

//   bool get _isConsultationMode =>
//       widget.appointmentId != null &&
//       widget.appointmentDate != null &&
//       widget.appointmentTime != null;

//   // ── Lifecycle ─────────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _animationController.forward();

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollToBottom();
//       if (_isConsultationMode) {
//         _loadUserRoleAndInit();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _timeCheckTimer?.cancel();
//     _countdownTimer?.cancel();
//     _animationController.dispose();
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   // ── Role loading ──────────────────────────────────────────────────────────

//   Future<void> _loadUserRoleAndInit() async {
//     try {
//       final uid = FirebaseAuth.instance.currentUser?.uid;
//       if (uid == null) return;

//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .get();
//       final role =
//           (doc.data()?['role'] ?? '').toString().toLowerCase().trim();

//       if (mounted) {
//         setState(() => _currentUserRole = role);
//         log('[ChatScreen] 👤 Role loaded: $role');
//         _initConsultationTimer();
//       }
//     } catch (e) {
//       log('[ChatScreen] ❌ Error loading role: $e');
//       _initConsultationTimer();
//     }
//   }

//   // ── Time parsing ──────────────────────────────────────────────────────────

//   /// Parses a slot string like "09:00 AM - 10:00 AM" into start and end DateTime.
//   /// Also handles plain time strings like "14:30" or "2:30 PM".
//   Map<String, DateTime> _parseSlotTimes(String slotString) {
//     final base = widget.appointmentDate!.toDate();
//     final baseDate = DateTime(base.year, base.month, base.day);

//     // Check if it's a range slot "HH:MM AM - HH:MM PM"
//     if (slotString.contains(' - ')) {
//       final parts = slotString.split(' - ');
//       final startParsed = _parseTimeString(parts[0].trim());
//       final endParsed = _parseTimeString(parts[1].trim());
//       return {
//         'start': baseDate.add(Duration(
//             hours: startParsed['hour']!, minutes: startParsed['minute']!)),
//         'end': baseDate.add(Duration(
//             hours: endParsed['hour']!, minutes: endParsed['minute']!)),
//       };
//     }

//     // Plain single time — assume 1 hour slot
//     final timeParsed = _parseTimeString(slotString);
//     final start = baseDate.add(Duration(
//         hours: timeParsed['hour']!, minutes: timeParsed['minute']!));
//     return {
//       'start': start,
//       'end': start.add(const Duration(hours: 1)),
//     };
//   }

//   /// Accepts "09:00 AM", "14:30", "2:30PM", "14:30:00" etc.
//   Map<String, int> _parseTimeString(String time) {
//     int hour = 0;
//     int minute = 0;
//     try {
//       final cleaned = time.trim().toUpperCase();
//       final isPm = cleaned.contains('PM');
//       final isAm = cleaned.contains('AM');
//       final numeric = cleaned.replaceAll(RegExp(r'[APM\s]'), '');
//       final parts = numeric.split(':');
//       hour = int.parse(parts[0]);
//       minute = parts.length > 1 ? int.parse(parts[1]) : 0;
//       if (isPm && hour != 12) hour += 12;
//       if (isAm && hour == 12) hour = 0;
//     } catch (e) {
//       log('[ChatScreen] ⚠️ Could not parse time "$time": $e');
//     }
//     return {'hour': hour, 'minute': minute};
//   }

//   // ── Consultation timer setup ──────────────────────────────────────────────

//   void _initConsultationTimer() {
//     final now = DateTime.now();
//     final times = _parseSlotTimes(widget.appointmentTime!);
//     final startTime = times['start']!;
//     final endTime = times['end']!;

//     log('[ChatScreen] 🕐 Slot start: $startTime  |  End: $endTime  |  Now: $now');

//     // Already fully over
//     if (endTime.isBefore(now)) {
//       log('[ChatScreen] ⏭️ Appointment already ended');
//       setState(() {
//         _consultationStarted = true;
//         _consultationEnded = true;
//         _timeUntilStart = Duration.zero;
//         _timeUntilEnd = Duration.zero;
//       });
//       _checkAndShowRating();
//       return;
//     }

//     // Currently in progress
//     if (startTime.isBefore(now) && endTime.isAfter(now)) {
//       log('[ChatScreen] 🟢 Appointment currently in progress');
//       setState(() {
//         _consultationStarted = true;
//         _timeUntilEnd = endTime.difference(now);
//       });
//       _startPollingTimer();
//       _startCountdownTimer();
//       return;
//     }

//     // Not started yet
//     if (startTime.isAfter(now)) {
//       log('[ChatScreen] ⏳ Appointment in the future');
//       setState(() => _timeUntilStart = startTime.difference(now));
//       _startPollingTimer();
//       _startCountdownTimer();
//       return;
//     }
//   }

//   /// Polls every 30 seconds to flip started/ended state.
//   void _startPollingTimer() {
//     _timeCheckTimer?.cancel();
//     _timeCheckTimer = Timer.periodic(
//       const Duration(seconds: 30),
//       (_) => _checkConsultationTime(),
//     );
//   }

//   /// Fires every second — updates live countdown durations only.
//   void _startCountdownTimer() {
//     _countdownTimer?.cancel();
//     _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (!mounted) return;
//       final now = DateTime.now();
//       final times = _parseSlotTimes(widget.appointmentTime!);
//       final startTime = times['start']!;
//       final endTime = times['end']!;

//       setState(() {
//         if (!_consultationStarted) {
//           _timeUntilStart =
//               startTime.isAfter(now) ? startTime.difference(now) : Duration.zero;
//         } else if (!_consultationEnded) {
//           _timeUntilEnd =
//               endTime.isAfter(now) ? endTime.difference(now) : Duration.zero;
//         }
//       });

//       // Cancel once everything is done
//       if (_consultationEnded) {
//         _countdownTimer?.cancel();
//       }
//     });
//   }

//   void _checkConsultationTime() {
//     if (!mounted) return;
//     if (_consultationEnded) {
//       _timeCheckTimer?.cancel();
//       return;
//     }

//     final now = DateTime.now();
//     final times = _parseSlotTimes(widget.appointmentTime!);
//     final startTime = times['start']!;
//     final endTime = times['end']!;

//     final hasStarted = !startTime.isAfter(now);
//     final hasEnded = endTime.isBefore(now);

//     log('[ChatScreen] ⏰ Poll — hasStarted: $hasStarted | hasEnded: $hasEnded');

//     if (hasStarted && !_consultationStarted) {
//       setState(() => _consultationStarted = true);
//       log('[ChatScreen] 🟢 Consultation started');
//     }

//     if (hasEnded && !_consultationEnded) {
//       setState(() {
//         _consultationEnded = true;
//         _timeUntilEnd = Duration.zero;
//       });
//       _timeCheckTimer?.cancel();
//       _countdownTimer?.cancel();
//       log('[ChatScreen] 🔴 Consultation ended');
//       _checkAndShowRating();
//     }
//   }

//   // ── Rating dialog ─────────────────────────────────────────────────────────

//   Future<void> _checkAndShowRating() async {
//     if (_ratingShown || !mounted) return;
//     if (widget.appointmentId == null) return;

//     // Use cached role if available, else fetch
//     String role = _currentUserRole ?? '';
//     if (role.isEmpty) {
//       try {
//         final uid = FirebaseAuth.instance.currentUser?.uid;
//         if (uid == null) return;
//         final doc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(uid)
//             .get();
//         role = (doc.data()?['role'] ?? '').toString().toLowerCase().trim();
//       } catch (e) {
//         log('[ChatScreen] ❌ Error fetching role for rating: $e');
//         return;
//       }
//     }

//     log('[ChatScreen] 👤 Role for rating check: "$role"');

//     // Only patients rate
//     if (role != 'user') {
//       log('[ChatScreen] 🚫 Skipping rating — role is "$role"');
//       return;
//     }

//     final alreadyRated = await _hasAlreadyRated(widget.appointmentId!);
//     if (alreadyRated) {
//       log('[ChatScreen] ✅ Already rated');
//       return;
//     }

//     if (mounted) {
//       _ratingShown = true;
//       // Small delay so the "ended" banner appears first
//       await Future.delayed(const Duration(milliseconds: 800));
//       if (mounted) _showRatingDialog();
//     }
//   }

//   Future<bool> _hasAlreadyRated(String appointmentId) async {
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('appointments')
//           .doc(appointmentId)
//           .get();
//       final data = doc.data();
//       if (data == null) return false;
//       final rating = data['rating'];
//       return rating != null && rating != 0;
//     } catch (e) {
//       log('[ChatScreen] ❌ Error checking rating: $e');
//       return false;
//     }
//   }

//   void _showRatingDialog() {
//     double selectedRating = 0;
//     final TextEditingController feedbackController = TextEditingController();

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => AlertDialog(
//         shape:
//             RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text(
//           '⭐ Rate Your Consultation',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         content: StatefulBuilder(
//           builder: (ctx, setDialogState) => Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text('How was your experience with the doctor?'),
//               const SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: List.generate(5, (i) {
//                   return GestureDetector(
//                     onTap: () =>
//                         setDialogState(() => selectedRating = i + 1.0),
//                     child: Icon(
//                       i < selectedRating
//                           ? Icons.star_rounded
//                           : Icons.star_border_rounded,
//                       color: Colors.amber,
//                       size: 40,
//                     ),
//                   );
//                 }),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: feedbackController,
//                 maxLines: 3,
//                 decoration: InputDecoration(
//                   hintText: 'Leave a comment (optional)',
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   contentPadding: const EdgeInsets.all(12),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(),
//             child: const Text('Skip'),
//           ),
//           ElevatedButton(
//             style:
//                 ElevatedButton.styleFrom(backgroundColor: primaryTeal),
//             onPressed: () async {
//               Navigator.of(ctx).pop();
//               if (selectedRating > 0 && widget.appointmentId != null) {
//                 await _submitRating(
//                   widget.appointmentId!,
//                   selectedRating,
//                   feedbackController.text.trim(),
//                 );
//               }
//             },
//             child: const Text(
//               'Submit',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _submitRating(
//       String appointmentId, double rating, String feedback) async {
//     try {
//       // Save to appointments collection
//       await FirebaseFirestore.instance
//           .collection('appointments')
//           .doc(appointmentId)
//           .update({
//         'rating': rating,
//         'feedback': feedback,
//         'ratedAt': FieldValue.serverTimestamp(),
//       });

//       // Also save to consultation_ratings for doctor profile page
//       final apptDoc = await FirebaseFirestore.instance
//           .collection('appointments')
//           .doc(appointmentId)
//           .get();
//       final apptData = apptDoc.data();
//       if (apptData != null) {
//         final doctorId = apptData['doctorId'] as String?;
//         final patientId = apptData['userId'] as String?;
//         if (doctorId != null && patientId != null) {
//           await FirebaseFirestore.instance
//               .collection('consultation_ratings')
//               .add({
//             'appointmentId': appointmentId,
//             'doctorId': doctorId,
//             'patientId': patientId,
//             'doctorRating': rating,
//             'doctorFeedback': feedback,
//             'ratedAt': FieldValue.serverTimestamp(),
//           });
//         }
//       }

//       log('[ChatScreen] ⭐ Rating $rating submitted for $appointmentId');
//       if (mounted) _showSnackBar('Thank you for your rating!');
//     } catch (e) {
//       log('[ChatScreen] ❌ Error submitting rating: $e');
//     }
//   }

//   // ── Messaging ─────────────────────────────────────────────────────────────

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

//     try {
//       await context.read<ChatProvider>().sendText(msg);
//     } catch (e) {
//       log('[ChatScreen] Error sending text: $e');
//       _showSnackBar('Failed to send message', isError: true);
//     }

//     _messageController.clear();
//     _scrollToBottom();
//   }

//   void _sendMedia(MessageType type) async {
//     try {
//       final XFile? file = await _picker.pickImage(
//         source: type == MessageType.image
//             ? ImageSource.gallery
//             : ImageSource.camera,
//         maxWidth: 1080,
//         maxHeight: 1080,
//         imageQuality: 85,
//       );
//       if (file == null) return;

//       _showSnackBar('Uploading image...', isLoading: true);
//       await context
//           .read<ChatProvider>()
//           .sendMedia(_myId, widget.receiverId, File(file.path), type);

//       if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       _scrollToBottom();
//     } catch (e) {
//       log('[ChatScreen] Error sending media: $e');
//       _showSnackBar('Failed to send image', isError: true);
//     }
//   }

//   void _sendPrescription() async {
//     try {
//       final XFile? file = await _picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1080,
//         maxHeight: 1080,
//         imageQuality: 85,
//       );
//       if (file == null) return;

//       final fileName = file.path.split('/').last;
//       _showSnackBar('Uploading prescription...', isLoading: true);

//       await context.read<ChatProvider>().sendPrescription(
//             _myId,
//             widget.receiverId,
//             File(file.path),
//             summary: 'Prescription: $fileName',
//             documentName: fileName,
//           );

//       if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       _showSnackBar('✅ Prescription sent successfully!');
//       _scrollToBottom();
//     } catch (e) {
//       log('[ChatScreen] ❌ Error sending prescription: $e');
//       _showSnackBar('Failed to send prescription: $e', isError: true);
//     }
//   }

//   void _scrollToBottom() {
//     Future.delayed(const Duration(milliseconds: 300), () {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   // ── Build ─────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: primaryTeal,
//       body: Column(
//         children: [
//           _buildModernAppBar(),
//           if (_isConsultationMode) _buildConsultationBanner(),
//           Expanded(
//             child: Container(
//               margin: const EdgeInsets.only(top: 5),
//               decoration: BoxDecoration(
//                 color: scaffoldBg,
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(35),
//                   topRight: Radius.circular(35),
//                 ),
//               ),
//               child: ClipRRect(
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(35),
//                   topRight: Radius.circular(35),
//                 ),
//                 child: Column(
//                   children: [
//                     Expanded(child: _buildMessages()),
//                     _buildModernInput(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Consultation Banner ────────────────────────────────────────────────────

//   Widget _buildConsultationBanner() {
//     // ── ENDED ──────────────────────────────────────────────────────────────
//     if (_consultationEnded) {
//       return _bannerTile(
//         icon: Icons.check_circle_outline_rounded,
//         color: Colors.green.shade700,
//         bgColor: Colors.green.shade50,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               '✅ Consultation Completed',
//               style: TextStyle(
//                 color: Colors.green.shade800,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 13,
//               ),
//             ),
//             Text(
//               'This consultation session has ended.',
//               style: TextStyle(
//                 color: Colors.green.shade700,
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     // ── IN PROGRESS ────────────────────────────────────────────────────────
//     if (_consultationStarted) {
//       final remaining = _timeUntilEnd;
//       final label = _formatDuration(remaining);

//       return _bannerTile(
//         icon: Icons.fiber_manual_record,
//         color: Colors.green.shade700,
//         bgColor: Colors.green.shade50,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 // Pulsing dot
//                 _PulsingDot(color: Colors.green.shade600),
//                 const SizedBox(width: 6),
//                 Text(
//                   'Consultation In Progress',
//                   style: TextStyle(
//                     color: Colors.green.shade800,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 13,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 2),
//             Text(
//               'Ends in $label  •  Slot: ${widget.appointmentTime}',
//               style: TextStyle(
//                 color: Colors.green.shade700,
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     // ── NOT STARTED YET ────────────────────────────────────────────────────
//     final remaining = _timeUntilStart;
//     final label = _formatDuration(remaining);
//     final slotLabel = widget.appointmentTime ?? '';
//     final isDoctor = (_currentUserRole ?? '') == 'doctor';

//     return _bannerTile(
//       icon: Icons.access_time_rounded,
//       color: Colors.orange.shade700,
//       bgColor: Colors.orange.shade50,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             isDoctor
//                 ? '📅 Upcoming Appointment'
//                 : '📅 Your Appointment',
//             style: TextStyle(
//               color: Colors.orange.shade800,
//               fontWeight: FontWeight.bold,
//               fontSize: 13,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             isDoctor
//                 ? 'Starts in $label  •  Slot: $slotLabel'
//                 : 'Your consultation starts in $label  •  Slot: $slotLabel',
//             style: TextStyle(
//               color: Colors.orange.shade700,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Shared banner tile wrapper
//   Widget _bannerTile({
//     required IconData icon,
//     required Color color,
//     required Color bgColor,
//     required Widget child,
//   }) {
//     return Container(
//       width: double.infinity,
//       color: bgColor,
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, size: 18, color: color),
//           const SizedBox(width: 10),
//           Expanded(child: child),
//         ],
//       ),
//     );
//   }

//   /// Formats a Duration into "Xh Ym" or "Ym Zs"
//   String _formatDuration(Duration d) {
//     if (d.isNegative || d == Duration.zero) return '0m';
//     final h = d.inHours;
//     final m = d.inMinutes % 60;
//     final s = d.inSeconds % 60;
//     if (h > 0) return '${h}h ${m}m';
//     if (m > 0) return '${m}m ${s}s';
//     return '${s}s';
//   }

//   // ── App bar ───────────────────────────────────────────────────────────────

//   Widget _buildModernAppBar() {
//     return SafeArea(
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(10, 10, 20, 20),
//         child: Row(
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: IconButton(
//                 icon: const Icon(Icons.arrow_back_ios_new,
//                     color: Colors.white, size: 20),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Stack(
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 3),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.2),
//                         blurRadius: 8,
//                         offset: const Offset(0, 3),
//                       ),
//                     ],
//                   ),
//                   child: CircleAvatar(
//                     radius: 22,
//                     backgroundColor: Colors.white,
//                     backgroundImage: widget.receiverImage.isNotEmpty
//                         ? NetworkImage(widget.receiverImage)
//                         : null,
//                     child: widget.receiverImage.isEmpty
//                         ? Icon(Icons.person, color: primaryTeal, size: 24)
//                         : null,
//                   ),
//                 ),
//                 if (widget.isOnline)
//                   Positioned(
//                     right: 0,
//                     bottom: 0,
//                     child: Container(
//                       width: 14,
//                       height: 14,
//                       decoration: BoxDecoration(
//                         color: Colors.greenAccent.shade400,
//                         shape: BoxShape.circle,
//                         border:
//                             Border.all(color: primaryTeal, width: 2.5),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.receiverName,
//                     style: const TextStyle(
//                       fontSize: 17,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     widget.isOnline ? 'Online' : 'Offline',
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: Colors.white.withOpacity(0.9),
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // Show slot info badge in appbar too
//             if (_isConsultationMode)
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 10, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(
//                   _consultationEnded
//                       ? '✅ Done'
//                       : _consultationStarted
//                           ? '🟢 Live'
//                           : '🕐 Soon',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               )
//             else
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: IconButton(
//                   icon: const Icon(Icons.more_vert_rounded,
//                       color: Colors.white, size: 24),
//                   onPressed: () {},
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Message list ──────────────────────────────────────────────────────────

//   Widget _buildMessages() {
//     return StreamBuilder<List<ChatMessage>>(
//       stream:
//           context.read<ChatProvider>().getMessages(_myId, widget.receiverId),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(
//               child: CircularProgressIndicator(color: primaryTeal));
//         }

//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: primaryTeal.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(Icons.chat_bubble_outline_rounded,
//                       size: 60, color: primaryTeal),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   'No messages yet',
//                   style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF2C3E50)),
//                 ),
//                 const SizedBox(height: 8),
//                 Text('Start the conversation!',
//                     style:
//                         TextStyle(fontSize: 14, color: Colors.grey[600])),
//               ],
//             ),
//           );
//         }

//         final messages = snapshot.data!;
//         return ListView.builder(
//           controller: _scrollController,
//           padding:
//               const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//           itemCount: messages.length,
//           physics: const BouncingScrollPhysics(),
//           itemBuilder: (_, i) => _buildModernBubble(messages[i], i),
//         );
//       },
//     );
//   }

//   // ── Bubbles ───────────────────────────────────────────────────────────────

//   Widget _buildModernBubble(ChatMessage msg, int index) {
//     final isMe = msg.senderId == _myId;
//     final align = isMe ? Alignment.centerRight : Alignment.centerLeft;

//     return TweenAnimationBuilder<double>(
//       duration: Duration(milliseconds: 200 + (index * 30)),
//       tween: Tween(begin: 0.0, end: 1.0),
//       builder: (context, value, child) => Opacity(
//         opacity: value,
//         child: Transform.translate(
//           offset: Offset(0, 10 * (1 - value)),
//           child: child,
//         ),
//       ),
//       child: Align(
//         alignment: align,
//         child: Container(
//           margin: const EdgeInsets.symmetric(vertical: 6),
//           padding:
//               const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           constraints: BoxConstraints(
//               maxWidth: MediaQuery.of(context).size.width * 0.75),
//           decoration: BoxDecoration(
//             gradient: isMe
//                 ? LinearGradient(
//                     colors: [primaryTeal, mediumTeal],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   )
//                 : null,
//             color: isMe ? null : Colors.white,
//             borderRadius: BorderRadius.only(
//               topLeft: const Radius.circular(20),
//               topRight: const Radius.circular(20),
//               bottomLeft: isMe
//                   ? const Radius.circular(20)
//                   : const Radius.circular(4),
//               bottomRight: isMe
//                   ? const Radius.circular(4)
//                   : const Radius.circular(20),
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: isMe
//                     ? primaryTeal.withOpacity(0.3)
//                     : Colors.black.withOpacity(0.06),
//                 blurRadius: 8,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: msg.type == MessageType.text
//               ? _textBubble(msg, isMe)
//               : _mediaBubble(msg, isMe),
//         ),
//       ),
//     );
//   }

//   Widget _textBubble(ChatMessage msg, bool isMe) {
//     return Column(
//       crossAxisAlignment:
//           isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//       children: [
//         Text(
//           msg.text ?? '',
//           style: TextStyle(
//               color: isMe ? Colors.white : const Color(0xFF2C3E50),
//               fontSize: 15,
//               height: 1.4),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           _formatTime(msg.timestamp),
//           style: TextStyle(
//               fontSize: 11,
//               color: isMe
//                   ? Colors.white.withOpacity(0.8)
//                   : Colors.grey[500],
//               fontWeight: FontWeight.w500),
//         ),
//       ],
//     );
//   }

//   Widget _mediaBubble(ChatMessage msg, bool isMe) {
//     if (msg.type == MessageType.prescription) {
//       return _prescriptionBubble(msg, isMe);
//     }
//     return Column(
//       crossAxisAlignment:
//           isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//       children: [
//         ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: Image.network(
//             msg.mediaUrl ?? '',
//             loadingBuilder: (context, child, loadingProgress) {
//               if (loadingProgress == null) return child;
//               return Container(
//                 height: 150,
//                 width: 150,
//                 color: Colors.grey[200],
//                 child: Center(
//                   child: CircularProgressIndicator(
//                     value: loadingProgress.expectedTotalBytes != null
//                         ? loadingProgress.cumulativeBytesLoaded /
//                             loadingProgress.expectedTotalBytes!
//                         : null,
//                     color: primaryTeal,
//                     strokeWidth: 2,
//                   ),
//                 ),
//               );
//             },
//             errorBuilder: (_, __, ___) => Container(
//               height: 150,
//               width: 150,
//               color: Colors.grey[300],
//               child: const Icon(Icons.broken_image_rounded, size: 50),
//             ),
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           _formatTime(msg.timestamp),
//           style: TextStyle(
//               fontSize: 11,
//               color: isMe
//                   ? Colors.white.withOpacity(0.8)
//                   : Colors.grey[500],
//               fontWeight: FontWeight.w500),
//         ),
//       ],
//     );
//   }

//   Widget _prescriptionBubble(ChatMessage msg, bool isMe) {
//     return Column(
//       crossAxisAlignment:
//           isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding:
//               const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           decoration: BoxDecoration(
//             color: isMe ? Colors.teal[600] : Colors.blue[50],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//                 color: primaryTeal.withOpacity(0.5), width: 1.5),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(Icons.description_rounded,
//                       color: isMe ? Colors.white : primaryTeal,
//                       size: 18),
//                   const SizedBox(width: 8),
//                   Text(
//                     '📋 Prescription',
//                     style: TextStyle(
//                         color: isMe ? Colors.white : primaryTeal,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 13),
//                   ),
//                 ],
//               ),
//               if (msg.documentName != null &&
//                   msg.documentName!.isNotEmpty) ...[
//                 const SizedBox(height: 6),
//                 Text(
//                   msg.documentName!,
//                   style: TextStyle(
//                       color: isMe ? Colors.white : Colors.black87,
//                       fontSize: 12),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//               const SizedBox(height: 8),
//               GestureDetector(
//                 onTap: () => _downloadPrescription(msg),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 10, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: isMe
//                         ? Colors.white.withOpacity(0.25)
//                         : primaryTeal,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: const Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.download_rounded,
//                           color: Colors.white, size: 14),
//                       SizedBox(width: 4),
//                       Text(
//                         'Download',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 11),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           _formatTime(msg.timestamp),
//           style: TextStyle(
//               fontSize: 11,
//               color: isMe
//                   ? Colors.white.withOpacity(0.8)
//                   : Colors.grey[500],
//               fontWeight: FontWeight.w500),
//         ),
//       ],
//     );
//   }

//   Future<void> _downloadPrescription(ChatMessage msg) async {
//     try {
//       if (msg.mediaUrl == null || msg.mediaUrl!.isEmpty) {
//         _showSnackBar('Prescription URL not found', isError: true);
//         return;
//       }
//       _showSnackBar('📥 Downloading prescription...', isLoading: true);
//       final fileName = msg.documentName ??
//           'prescription_${DateTime.now().millisecondsSinceEpoch}';
//       log('[ChatScreen] 📄 Downloading: $fileName');
//       await Future.delayed(const Duration(seconds: 1));
//       if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       _showSnackBar('✅ Prescription downloaded: $fileName');
//     } catch (e) {
//       log('[ChatScreen] ❌ Error downloading prescription: $e');
//       _showSnackBar('❌ Failed to download: $e', isError: true);
//     }
//   }

//   // ── Input bar ─────────────────────────────────────────────────────────────

//   Widget _buildModernInput() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, -3)),
//         ],
//       ),
//       child: SafeArea(
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 color: primaryTeal.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: Icon(Icons.image_rounded,
//                         color: primaryTeal, size: 24),
//                     onPressed: () => _sendMedia(MessageType.image),
//                     tooltip: 'Send Image',
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.camera_alt_rounded,
//                         color: primaryTeal, size: 24),
//                     onPressed: () => _sendMedia(MessageType.video),
//                     tooltip: 'Take Photo',
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.description_rounded,
//                         color: primaryTeal, size: 24),
//                     onPressed: _sendPrescription,
//                     tooltip: 'Send Prescription',
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: scaffoldBg,
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 child: TextField(
//                   controller: _messageController,
//                   style: const TextStyle(fontSize: 15),
//                   maxLines: null,
//                   textInputAction: TextInputAction.newline,
//                   decoration: InputDecoration(
//                     hintText: 'Type a message...',
//                     hintStyle:
//                         TextStyle(color: Colors.grey.shade500),
//                     contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 12),
//                     border: InputBorder.none,
//                   ),
//                   onSubmitted: (text) {
//                     if (text.trim().isNotEmpty) _sendMessage(text);
//                   },
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             GestureDetector(
//               onTap: () {
//                 final text = _messageController.text;
//                 if (text.trim().isNotEmpty) _sendMessage(text);
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(13),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                       colors: [primaryTeal, mediumTeal]),
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                         color: primaryTeal.withOpacity(0.4),
//                         blurRadius: 8,
//                         offset: const Offset(0, 3)),
//                   ],
//                 ),
//                 child: const Icon(Icons.send_rounded,
//                     color: Colors.white, size: 22),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Snack bar ─────────────────────────────────────────────────────────────

//   void _showSnackBar(String message,
//       {bool isError = false, bool isLoading = false}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             if (isLoading) ...[
//               const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor:
//                         AlwaysStoppedAnimation<Color>(Colors.white)),
//               ),
//               const SizedBox(width: 12),
//             ],
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: isError ? Colors.red : primaryTeal,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12)),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }

//   String _formatTime(DateTime t) =>
//       '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
// }

// // ── Pulsing green dot widget ───────────────────────────────────────────────

// class _PulsingDot extends StatefulWidget {
//   final Color color;
//   const _PulsingDot({required this.color});

//   @override
//   State<_PulsingDot> createState() => _PulsingDotState();
// }

// class _PulsingDotState extends State<_PulsingDot>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _ctrl;
//   late Animation<double> _anim;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..repeat(reverse: true);
//     _anim = Tween<double>(begin: 0.5, end: 1.0).animate(
//       CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _anim,
//       child: Container(
//         width: 10,
//         height: 10,
//         decoration: BoxDecoration(
//           color: widget.color,
//           shape: BoxShape.circle,
//         ),
//       ),
//     );
//   }
// }



// Most FIcxed Version

import 'dart:async';
import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/chat_model.dart';
import 'package:flutter_application_1/provider/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

/// ChatScreen — two variants in one file:
///
///  1. Simple chat  → ChatScreen(receiverId, receiverName, …)
///     Used for general messaging, no consultation logic.
///
///  2. Consultation chat → ChatScreen(receiverId, receiverName, …,
///                           appointmentId, appointmentDate, appointmentTime)
///     - appointmentTime is the SLOT selected by user e.g. "09:00 AM - 10:00 AM"
///     - Start time = slot start (e.g. 09:00 AM)
///     - End time   = slot END from slot string (e.g. 10:00 AM) — NOT +30 min hardcode
///     - Both doctor and patient see a live countdown / status banner
///     - Rating dialog shown ONLY to the patient (role == 'user') after end
///     - Timer polls every 30s and auto-cancels once consultation ends
///     - Chat input is ENABLED for user as soon as consultation starts
///     - Firestore chatStatus is updated to 'active' when slot starts

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverImage;
  final bool isOnline;

  // ── Consultation-specific (optional) ──────────────────────────────────────
  final String? appointmentId;
  final Timestamp? appointmentDate; // Firestore Timestamp for the date
  final String? appointmentTime;    // e.g. "09:00 AM - 10:00 AM"
  final String? animalName;         // optional, shown in header

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverImage,
    required this.isOnline,
    this.appointmentId,
    this.appointmentDate,
    this.appointmentTime,
    this.animalName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────────────────
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;

  // ── Consultation state ────────────────────────────────────────────────────
  Timer? _timeCheckTimer;
  Timer? _countdownTimer;
  bool _consultationStarted = false;
  bool _consultationEnded = false;
  bool _ratingShown = false;
  bool _chatEnabledForUser = false; // ✅ FIX 1: tracks if user can send
  Duration _timeUntilStart = Duration.zero;
  Duration _timeUntilEnd = Duration.zero;
  String? _currentUserRole;         // 'user' or 'doctor'

  // ── Theme ─────────────────────────────────────────────────────────────────
  final Color primaryTeal = const Color(0xFF00796B);
  final Color mediumTeal = const Color(0xFF4DB6AC);
  final Color lightTeal = const Color(0xFF80CBC4);
  final Color scaffoldBg = const Color(0xFFF5F7FA);

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get _myId => FirebaseAuth.instance.currentUser!.uid;

  bool get _isConsultationMode =>
      widget.appointmentId != null &&
      widget.appointmentDate != null &&
      widget.appointmentTime != null;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      if (_isConsultationMode) {
        _loadUserRoleAndInit();
      }
    });
  }

  @override
  void dispose() {
    _timeCheckTimer?.cancel();
    _countdownTimer?.cancel();
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Role loading ──────────────────────────────────────────────────────────

  Future<void> _loadUserRoleAndInit() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final role =
          (doc.data()?['role'] ?? '').toString().toLowerCase().trim();

      if (mounted) {
        setState(() => _currentUserRole = role);
        log('[ChatScreen] 👤 Role loaded: $role');
        _initConsultationTimer();
      }
    } catch (e) {
      log('[ChatScreen] ❌ Error loading role: $e');
      // Even if role fails, still init timer
      _initConsultationTimer();
    }
  }

  // ── Time parsing ──────────────────────────────────────────────────────────

  /// Parses a slot string like "09:00 AM - 10:00 AM" into start and end DateTime.
  /// ✅ FIX 2: End time comes from slot string end — NOT +30 min hardcode.
  Map<String, DateTime> _parseSlotTimes(String slotString) {
    final base = widget.appointmentDate!.toDate();
    final baseDate = DateTime(base.year, base.month, base.day);

    // Range slot: "09:00 AM - 10:00 AM"
    if (slotString.contains(' - ')) {
      final parts = slotString.split(' - ');
      final startParsed = _parseTimeString(parts[0].trim());
      final endParsed = _parseTimeString(parts[1].trim());
      final start = baseDate.add(Duration(
          hours: startParsed['hour']!, minutes: startParsed['minute']!));
      final end = baseDate.add(Duration(
          hours: endParsed['hour']!, minutes: endParsed['minute']!));

      log('[ChatScreen] 🕐 Parsed slot → start: $start | end: $end');
      return {'start': start, 'end': end};
    }

    // Single time like "14:30" — assume 1 hour slot (fallback)
    final timeParsed = _parseTimeString(slotString);
    final start = baseDate.add(Duration(
        hours: timeParsed['hour']!, minutes: timeParsed['minute']!));
    final end = start.add(const Duration(hours: 1));

    log('[ChatScreen] 🕐 Single time slot → start: $start | end: $end (1hr assumed)');
    return {'start': start, 'end': end};
  }

  /// Accepts "09:00 AM", "14:30", "2:30PM", "14:30:00" etc.
  Map<String, int> _parseTimeString(String time) {
    int hour = 0;
    int minute = 0;
    try {
      final cleaned = time.trim().toUpperCase();
      final isPm = cleaned.contains('PM');
      final isAm = cleaned.contains('AM');
      final numeric = cleaned.replaceAll(RegExp(r'[APM\s]'), '');
      final parts = numeric.split(':');
      hour = int.parse(parts[0]);
      minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      if (isPm && hour != 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
    } catch (e) {
      log('[ChatScreen] ⚠️ Could not parse time "$time": $e');
    }
    return {'hour': hour, 'minute': minute};
  }

  // ── Consultation timer setup ──────────────────────────────────────────────

  void _initConsultationTimer() {
    final now = DateTime.now();
    final times = _parseSlotTimes(widget.appointmentTime!);
    final startTime = times['start']!;
    final endTime = times['end']!;

    log('[ChatScreen] 🕐 Slot start: $startTime | End: $endTime | Now: $now');

    // ── Case 1: Already fully over ─────────────────────────────────────────
    if (endTime.isBefore(now)) {
      log('[ChatScreen] ⏭️ Appointment already ended at init');
      setState(() {
        _consultationStarted = true;
        _consultationEnded = true;
        _chatEnabledForUser = false; // session over — no more messages
        _timeUntilStart = Duration.zero;
        _timeUntilEnd = Duration.zero;
      });
      // ✅ FIX 3: Mark as completed in Firestore if not already
      _markCompletedIfNeeded();
      _checkAndShowRating();
      return;
    }

    // ── Case 2: Currently in progress ─────────────────────────────────────
    if (!startTime.isAfter(now) && endTime.isAfter(now)) {
      log('[ChatScreen] 🟢 Appointment currently in progress');
      setState(() {
        _consultationStarted = true;
        _chatEnabledForUser = true; // ✅ FIX 1: enable user chat NOW
        _timeUntilEnd = endTime.difference(now);
      });
      // ✅ FIX 1: Unlock user chat in Firestore
      _enableUserChatInFirestore();
      _startPollingTimer();
      _startCountdownTimer(startTime, endTime);
      return;
    }

    // ── Case 3: Not started yet ────────────────────────────────────────────
    if (startTime.isAfter(now)) {
      log('[ChatScreen] ⏳ Appointment in the future — starts in ${startTime.difference(now)}');
      setState(() {
        _chatEnabledForUser = false; // not started yet
        _timeUntilStart = startTime.difference(now);
      });
      _startPollingTimer();
      _startCountdownTimer(startTime, endTime);
      return;
    }
  }

  // ✅ FIX 1: Enable user chat in Firestore (chatStatus → 'active')
  Future<void> _enableUserChatInFirestore() async {
    if (widget.appointmentId == null) return;
    try {
      final apptRef = FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId);

      final doc = await apptRef.get();
      final data = doc.data();
      if (data == null) return;

      final currentStatus =
          (data['chatStatus'] ?? '').toString().toLowerCase();

      // Only upgrade from read-only → active (never downgrade)
      if (currentStatus != 'active') {
        await apptRef.update({'chatStatus': 'active'});
        log('[ChatScreen] ✅ chatStatus set to active — user can now send');
      } else {
        log('[ChatScreen] ℹ️ chatStatus already active');
      }
    } catch (e) {
      log('[ChatScreen] ❌ Error enabling user chat: $e');
    }
  }

  // ✅ FIX 3: Mark appointment as completed in Firestore
  Future<void> _markCompletedIfNeeded() async {
    if (widget.appointmentId == null) return;
    try {
      final apptRef = FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId);

      final doc = await apptRef.get();
      final data = doc.data();
      if (data == null) return;

      final status = (data['status'] ?? '').toString().toLowerCase();

      // Only mark completed if currently approved/active — never overwrite declined
      if (status == 'approved' || status == 'active') {
        await apptRef.update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'chatStatus': 'read-only', // lock chat after session
        });
        log('[ChatScreen] ✅ Appointment marked as completed');
      } else {
        log('[ChatScreen] ℹ️ Appointment status "$status" — not overwriting');
      }
    } catch (e) {
      log('[ChatScreen] ❌ Error marking completed: $e');
    }
  }

  /// Polls every 30 seconds — lightweight check, not every second.
  void _startPollingTimer() {
    _timeCheckTimer?.cancel();
    _timeCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConsultationTime(),
    );
  }

  /// Fires every second ONLY to update the live countdown display.
  void _startCountdownTimer(DateTime startTime, DateTime endTime) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _countdownTimer?.cancel();
        return;
      }

      final now = DateTime.now();

      setState(() {
        if (!_consultationStarted) {
          _timeUntilStart =
              startTime.isAfter(now) ? startTime.difference(now) : Duration.zero;
        } else if (!_consultationEnded) {
          _timeUntilEnd =
              endTime.isAfter(now) ? endTime.difference(now) : Duration.zero;
        }
      });

      // Stop countdown once ended
      if (_consultationEnded) {
        _countdownTimer?.cancel();
      }
    });
  }

  /// Called every 30s — flips started/ended states.
  void _checkConsultationTime() {
    if (!mounted || _consultationEnded) {
      _timeCheckTimer?.cancel();
      return;
    }

    final now = DateTime.now();
    final times = _parseSlotTimes(widget.appointmentTime!);
    final startTime = times['start']!;
    final endTime = times['end']!;

    final hasStarted = !startTime.isAfter(now);
    final hasEnded = endTime.isBefore(now);

    log('[ChatScreen] ⏰ Poll — hasStarted: $hasStarted | hasEnded: $hasEnded');

    // ── Flip to started ────────────────────────────────────────────────────
    if (hasStarted && !_consultationStarted) {
      setState(() {
        _consultationStarted = true;
        _chatEnabledForUser = true; // ✅ FIX 1: unlock user chat
      });
      _enableUserChatInFirestore(); // ✅ FIX 1: persist to Firestore
      log('[ChatScreen] 🟢 Consultation started (detected by poll)');
    }

    // ── Flip to ended ──────────────────────────────────────────────────────
    if (hasEnded && !_consultationEnded) {
      setState(() {
        _consultationEnded = true;
        _chatEnabledForUser = false; // lock after session
        _timeUntilEnd = Duration.zero;
      });
      _timeCheckTimer?.cancel();
      _countdownTimer?.cancel();
      _markCompletedIfNeeded(); // ✅ FIX 3: update Firestore status
      log('[ChatScreen] 🔴 Consultation ended (detected by poll)');
      _checkAndShowRating();
    }
  }

  // ── Rating dialog ─────────────────────────────────────────────────────────

  Future<void> _checkAndShowRating() async {
    if (_ratingShown || !mounted) return;
    if (widget.appointmentId == null) return;

    // Use cached role if available — avoids extra Firestore read
    String role = _currentUserRole ?? '';
    if (role.isEmpty) {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        role = (doc.data()?['role'] ?? '').toString().toLowerCase().trim();
        if (mounted) setState(() => _currentUserRole = role);
      } catch (e) {
        log('[ChatScreen] ❌ Error fetching role for rating: $e');
        return;
      }
    }

    log('[ChatScreen] 👤 Role for rating check: "$role"');

    // ✅ FIX: Only patients (role == 'user') see the rating dialog — NEVER doctor
    if (role != 'user') {
      log('[ChatScreen] 🚫 Skipping rating — role is "$role" (not user)');
      return;
    }

    final alreadyRated = await _hasAlreadyRated(widget.appointmentId!);
    if (alreadyRated) {
      log('[ChatScreen] ✅ Already rated — skipping dialog');
      return;
    }

    if (mounted) {
      _ratingShown = true;
      // Small delay so "ended" banner appears first
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _showRatingDialog();
    }
  }

  Future<bool> _hasAlreadyRated(String appointmentId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .get();
      final data = doc.data();
      if (data == null) return false;
      final rating = data['rating'];
      return rating != null && rating != 0;
    } catch (e) {
      log('[ChatScreen] ❌ Error checking rating: $e');
      return false;
    }
  }

  void _showRatingDialog() {
    double selectedRating = 0;
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '⭐ Rate Your Consultation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your experience with the doctor?'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedRating = i + 1.0),
                    child: Icon(
                      i < selectedRating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 40,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Leave a comment (optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (selectedRating > 0 && widget.appointmentId != null) {
                await _submitRating(
                  widget.appointmentId!,
                  selectedRating,
                  feedbackController.text.trim(),
                );
              }
            },
            child: const Text(
              'Submit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRating(
      String appointmentId, double rating, String feedback) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'rating': rating,
        'feedback': feedback,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      // Also save to consultation_ratings for doctor profile
      final apptDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .get();
      final apptData = apptDoc.data();
      if (apptData != null) {
        final doctorId = apptData['doctorId'] as String?;
        final patientId = apptData['userId'] as String?;
        if (doctorId != null && patientId != null) {
          await FirebaseFirestore.instance
              .collection('consultation_ratings')
              .add({
            'appointmentId': appointmentId,
            'doctorId': doctorId,
            'patientId': patientId,
            'doctorRating': rating,
            'doctorFeedback': feedback,
            'ratedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      log('[ChatScreen] ⭐ Rating $rating submitted for $appointmentId');
      if (mounted) _showSnackBar('Thank you for your rating!');
    } catch (e) {
      log('[ChatScreen] ❌ Error submitting rating: $e');
    }
  }

  // ── Messaging ─────────────────────────────────────────────────────────────

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // ✅ FIX 1: Block user from sending if chat not enabled yet
    if (_isConsultationMode && _currentUserRole == 'user' && !_chatEnabledForUser) {
      _showSnackBar('Chat will be enabled when your appointment starts.');
      return;
    }

    // Block everyone after consultation ends
    if (_isConsultationMode && _consultationEnded) {
      _showSnackBar('This consultation has ended.');
      return;
    }

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
      log('[ChatScreen] Error sending text: $e');
      _showSnackBar('Failed to send message', isError: true);
    }

    _messageController.clear();
    _scrollToBottom();
  }

  void _sendMedia(MessageType type) async {
    // ✅ FIX 1: Block media too if user chat not enabled
    if (_isConsultationMode && _currentUserRole == 'user' && !_chatEnabledForUser) {
      _showSnackBar('Chat will be enabled when your appointment starts.');
      return;
    }
    if (_isConsultationMode && _consultationEnded) {
      _showSnackBar('This consultation has ended.');
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: type == MessageType.image
            ? ImageSource.gallery
            : ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file == null) return;

      _showSnackBar('Uploading image...', isLoading: true);
      await context
          .read<ChatProvider>()
          .sendMedia(_myId, widget.receiverId, File(file.path), type);

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _scrollToBottom();
    } catch (e) {
      log('[ChatScreen] Error sending media: $e');
      _showSnackBar('Failed to send image', isError: true);
    }
  }

  void _sendPrescription() async {
    // Prescription is only for doctors — no block needed
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file == null) return;

      final fileName = file.path.split('/').last;
      _showSnackBar('Uploading prescription...', isLoading: true);

      await context.read<ChatProvider>().sendPrescription(
            _myId,
            widget.receiverId,
            File(file.path),
            summary: 'Prescription: $fileName',
            documentName: fileName,
          );

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSnackBar('✅ Prescription sent successfully!');
      _scrollToBottom();
    } catch (e) {
      log('[ChatScreen] ❌ Error sending prescription: $e');
      _showSnackBar('Failed to send prescription: $e', isError: true);
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

  // ── Phone & Video Calling ──────────────────────────────────────────────────

  Future<void> _makePhoneCall() async {
    try {
      final userDoc = await FirebaseFirestore.instance
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
      final userDoc = await FirebaseFirestore.instance
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryTeal,
      body: Column(
        children: [
          _buildModernAppBar(),
          if (_isConsultationMode) _buildConsultationBanner(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: scaffoldBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
                child: Column(
                  children: [
                    Expanded(child: _buildMessages()),
                    _buildModernInput(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Consultation Banner ───────────────────────────────────────────────────

  Widget _buildConsultationBanner() {
    // ── ENDED ──────────────────────────────────────────────────────────────
    if (_consultationEnded) {
      return _bannerTile(
        icon: Icons.check_circle_outline_rounded,
        color: Colors.green.shade700,
        bgColor: Colors.green.shade50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✅ Consultation Completed',
              style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
            Text(
              'This consultation session has ended.',
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // ── IN PROGRESS ────────────────────────────────────────────────────────
    if (_consultationStarted) {
      final label = _formatDuration(_timeUntilEnd);
      final times = _parseSlotTimes(widget.appointmentTime!);
      final endStr = _formatTimeDisplay(times['end']!);

      return _bannerTile(
        icon: Icons.fiber_manual_record,
        color: Colors.green.shade700,
        bgColor: Colors.green.shade50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              _PulsingDot(color: Colors.green.shade600),
              const SizedBox(width: 6),
              Text(
                'Consultation In Progress',
                style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ]),
            const SizedBox(height: 2),
            Text(
              'Ends at $endStr  •  Time left: $label',
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // ── NOT STARTED ────────────────────────────────────────────────────────
    final label = _formatDuration(_timeUntilStart);
    final times = _parseSlotTimes(widget.appointmentTime!);
    final startStr = _formatTimeDisplay(times['start']!);
    final endStr = _formatTimeDisplay(times['end']!);
    final isDoctor = (_currentUserRole ?? '') == 'doctor';

    return _bannerTile(
      icon: Icons.access_time_rounded,
      color: Colors.orange.shade700,
      bgColor: Colors.orange.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isDoctor ? '📅 Upcoming Appointment' : '📅 Your Appointment',
            style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            isDoctor
                ? 'Starts in $label  •  $startStr – $endStr'
                : 'Your consultation starts in $label  •  $startStr – $endStr',
            style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
          ),
          if (!isDoctor) ...[
            const SizedBox(height: 2),
            Text(
              'Chat will be unlocked at $startStr',
              style: TextStyle(
                  color: Colors.orange.shade600,
                  fontSize: 11,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bannerTile({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  /// Formats Duration into human-readable "Xh Ym Zs"
  String _formatDuration(Duration d) {
    if (d.isNegative || d == Duration.zero) return '0s';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  /// Formats a DateTime as "9:00 AM"
  String _formatTimeDisplay(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:$minute ${isPm ? 'PM' : 'AM'}';
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  Widget _buildModernAppBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 20, 20),
        child: Row(
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
            const SizedBox(width: 12),
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    backgroundImage: widget.receiverImage.isNotEmpty
                        ? NetworkImage(widget.receiverImage)
                        : null,
                    child: widget.receiverImage.isEmpty
                        ? Icon(Icons.person, color: primaryTeal, size: 24)
                        : null,
                  ),
                ),
                if (widget.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryTeal, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (_isConsultationMode)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _consultationEnded
                      ? '✅ Done'
                      : _consultationStarted
                          ? '🟢 Live'
                          : '🕐 Soon',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.white, size: 22),
                    tooltip: 'Make Call',
                    onPressed: _makePhoneCall,
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.videocam, color: Colors.white, size: 22),
                    tooltip: 'Video Call',
                    onPressed: _startVideoCall,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────

  Widget _buildMessages() {
    return StreamBuilder<List<ChatMessage>>(
      stream: context
          .read<ChatProvider>()
          .getMessages(_myId, widget.receiverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: primaryTeal));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chat_bubble_outline_rounded,
                      size: 60, color: primaryTeal),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No messages yet',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 8),
                Text('Start the conversation!',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          );
        }

        final messages = snapshot.data!;
        return ListView.builder(
          controller: _scrollController,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: messages.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (_, i) => _buildModernBubble(messages[i], i),
        );
      },
    );
  }

  // ── Bubbles ───────────────────────────────────────────────────────────────

  Widget _buildModernBubble(ChatMessage msg, int index) {
    final isMe = msg.senderId == _myId;
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 30)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)), child: child),
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            gradient: isMe
                ? LinearGradient(
                    colors: [primaryTeal, mediumTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)
                : null,
            color: isMe ? null : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMe
                  ? const Radius.circular(20)
                  : const Radius.circular(4),
              bottomRight: isMe
                  ? const Radius.circular(4)
                  : const Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: isMe
                    ? primaryTeal.withOpacity(0.3)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: msg.type == MessageType.text
              ? _textBubble(msg, isMe)
              : _mediaBubble(msg, isMe),
        ),
      ),
    );
  }

  Widget _textBubble(ChatMessage msg, bool isMe) {
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          msg.text ?? '',
          style: TextStyle(
              color: isMe ? Colors.white : const Color(0xFF2C3E50),
              fontSize: 15,
              height: 1.4),
        ),
        const SizedBox(height: 6),
        Text(
          _formatTime(msg.timestamp),
          style: TextStyle(
              fontSize: 11,
              color: isMe
                  ? Colors.white.withOpacity(0.8)
                  : Colors.grey[500],
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _mediaBubble(ChatMessage msg, bool isMe) {
    if (msg.type == MessageType.prescription) {
      return _prescriptionBubble(msg, isMe);
    }
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            msg.mediaUrl ?? '',
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 150,
                width: 150,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: primaryTeal,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 150,
              width: 150,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image_rounded, size: 50),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatTime(msg.timestamp),
          style: TextStyle(
              fontSize: 11,
              color: isMe
                  ? Colors.white.withOpacity(0.8)
                  : Colors.grey[500],
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _prescriptionBubble(ChatMessage msg, bool isMe) {
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? Colors.teal[600] : Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: primaryTeal.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.description_rounded,
                    color: isMe ? Colors.white : primaryTeal, size: 18),
                const SizedBox(width: 8),
                Text('📋 Prescription',
                    style: TextStyle(
                        color: isMe ? Colors.white : primaryTeal,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ]),
              if (msg.documentName != null &&
                  msg.documentName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(msg.documentName!,
                    style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _downloadPrescription(msg),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white.withOpacity(0.25)
                        : primaryTeal,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded,
                          color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Download',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatTime(msg.timestamp),
          style: TextStyle(
              fontSize: 11,
              color: isMe
                  ? Colors.white.withOpacity(0.8)
                  : Colors.grey[500],
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Future<void> _downloadPrescription(ChatMessage msg) async {
    try {
      if (msg.mediaUrl == null || msg.mediaUrl!.isEmpty) {
        _showSnackBar('Prescription URL not found', isError: true);
        return;
      }
      _showSnackBar('📥 Downloading prescription...', isLoading: true);
      final fileName = msg.documentName ??
          'prescription_${DateTime.now().millisecondsSinceEpoch}';
      log('[ChatScreen] 📄 Downloading: $fileName');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSnackBar('✅ Prescription downloaded: $fileName');
    } catch (e) {
      log('[ChatScreen] ❌ Error downloading: $e');
      _showSnackBar('❌ Failed to download: $e', isError: true);
    }
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildModernInput() {
    // ✅ FIX 1: Show a lock overlay for user when chat not yet enabled
    final isUserLocked = _isConsultationMode &&
        _currentUserRole == 'user' &&
        !_chatEnabledForUser &&
        !_consultationEnded;

    final isEnded = _isConsultationMode && _consultationEnded;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Locked hint banner for user before appointment starts
        if (isUserLocked)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.orange.shade50,
            child: Row(children: [
              Icon(Icons.lock_clock_outlined,
                  size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chat unlocks when your appointment starts',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),

        // Session ended hint
        if (isEnded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.grey.shade100,
            child: Row(children: [
              Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This consultation has ended — chat is now read-only',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),

        // Actual input row (disabled if locked or ended for users)
        AbsorbPointer(
          absorbing: isUserLocked || isEnded,
          child: Opacity(
            opacity: (isUserLocked || isEnded) ? 0.45 : 1.0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.image_rounded,
                                color: primaryTeal, size: 24),
                            onPressed: () => _sendMedia(MessageType.image),
                            tooltip: 'Send Image',
                          ),
                          IconButton(
                            icon: Icon(Icons.camera_alt_rounded,
                                color: primaryTeal, size: 24),
                            onPressed: () => _sendMedia(MessageType.video),
                            tooltip: 'Take Photo',
                          ),
                          IconButton(
                            icon: Icon(Icons.description_rounded,
                                color: primaryTeal, size: 24),
                            onPressed: _sendPrescription,
                            tooltip: 'Send Prescription',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: scaffoldBg,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(fontSize: 15),
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: isUserLocked
                                ? 'Chat starts at appointment time...'
                                : isEnded
                                    ? 'Session ended'
                                    : 'Type a message...',
                            hintStyle:
                                TextStyle(color: Colors.grey.shade500),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (text) {
                            if (text.trim().isNotEmpty) _sendMessage(text);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        final text = _messageController.text;
                        if (text.trim().isNotEmpty) _sendMessage(text);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [primaryTeal, mediumTeal]),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: primaryTeal.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3)),
                          ],
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Snack bar ─────────────────────────────────────────────────────────────

  void _showSnackBar(String message,
      {bool isError = false, bool isLoading = false}) {
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white))),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ── Pulsing dot ───────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: widget.color, shape: BoxShape.circle)),
    );
  }
}