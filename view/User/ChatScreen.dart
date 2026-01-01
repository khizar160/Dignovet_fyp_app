



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
import 'package:flutter/material.dart';
import 'package:flutter_application_1/model/chat_model.dart';
import 'package:flutter_application_1/provider/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverImage;
  final bool isOnline;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverImage,
    required this.isOnline,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // --- DignoVet Theme Colors ---
  final Color primaryTeal = const Color(0xFF00796B);
  final Color mediumTeal = const Color(0xFF4DB6AC);
  final Color lightTeal = const Color(0xFF80CBC4);

  String get _myId => FirebaseAuth.instance.currentUser!.uid;

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
          source: type == MessageType.image ? ImageSource.gallery : ImageSource.camera,
          maxWidth: 1080,
          maxHeight: 1080));
      if (file == null) return;
      final mediaFile = File(file.path);
      await context.read<ChatProvider>().sendMedia(_myId, widget.receiverId, mediaFile, type);
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

  // ---------------- UI Building ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryTeal, // Background according to your theme
      appBar: _buildAppBar(),
      body: Column(
        children: [
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                backgroundImage: widget.receiverImage.isNotEmpty
                    ? NetworkImage(widget.receiverImage)
                    : null,
                child: widget.receiverImage.isEmpty
                    ? Icon(Icons.person, color: primaryTeal)
                    : null,
              ),
              if (widget.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryTeal, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.receiverName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                widget.isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildMessages() {
    return StreamBuilder<List<ChatMessage>>(
      stream: context.read<ChatProvider>().getMessages(_myId, widget.receiverId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: primaryTeal));
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
            )
          ],
        ),
        child: msg.type == MessageType.text
            ? _textBubble(msg, isMe)
            : _mediaBubble(msg, isMe),
      ),
    );
  }

  Widget _textBubble(ChatMessage msg, bool isMe) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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

  Widget _mediaBubble(ChatMessage msg, bool isMe) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ClipRRect(
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
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(msg.timestamp),
          style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black45),
        ),
      ],
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        child: Row(
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
                    icon: Icon(Icons.image_rounded, color: primaryTeal, size: 22),
                    onPressed: () => _sendMedia(MessageType.image),
                  ),
                  IconButton(
                    icon: Icon(Icons.videocam_rounded, color: primaryTeal, size: 22),
                    onPressed: () => _sendMedia(MessageType.video),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Text Input
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send Button with DignoVet Gradient
            GestureDetector(
              onTap: () => _sendMessage(_messageController.text),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryTeal, mediumTeal]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}