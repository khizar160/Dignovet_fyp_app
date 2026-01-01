
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_application_1/services/chat_bot_api_sservces/chatBot_servcies.dart';

// class DignoVetChatScreen extends StatefulWidget {
//   const DignoVetChatScreen({super.key});

//   @override
//   State<DignoVetChatScreen> createState() => _DignoVetChatScreenState();
// }

// class _DignoVetChatScreenState extends State<DignoVetChatScreen> {
//   final GroqService _groqService = GroqService();
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   bool _isLoading = false;

//   final uid = FirebaseAuth.instance.currentUser!.uid;

//   Future<void> _sendMessage() async {
//     final userMessage = _controller.text.trim();
//     if (userMessage.isEmpty) return;

//     setState(() { _isLoading = true; });
//     _controller.clear();

//     // Save user message
//     await FirebaseFirestore.instance.collection('users').doc(uid).collection('chats').add({
//       'role': 'user',
//       'text': userMessage,
//       'timestamp': FieldValue.serverTimestamp(),
//     });

//     _scrollToBottom();

//     try {
//       final botReply = await _groqService.sendMessage(userMessage);
//       await FirebaseFirestore.instance.collection('users').doc(uid).collection('chats').add({
//         'role': 'bot',
//         'text': botReply,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//       _scrollToBottom();
//     } catch (e) {
//       await FirebaseFirestore.instance.collection('users').doc(uid).collection('chats').add({
//         'role': 'bot',
//         'text': 'Error: $e',
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//       _scrollToBottom();
//     } finally {
//       setState(() { _isLoading = false; });
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

//   Future<void> _clearChat() async {
//     final snapshots = await FirebaseFirestore.instance.collection('users').doc(uid).collection('chats').get();
//     for (var doc in snapshots.docs) { await doc.reference.delete(); }
//   }

//   Widget _buildMessage(Map<String, dynamic> msg) {
//     final isUser = msg['role'] == 'user';
//     return Align(
//       alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
//         padding: const EdgeInsets.all(14),
//         constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
//         decoration: BoxDecoration(
//           color: isUser ? Colors.teal.shade700 : Colors.teal.shade100,
//           borderRadius: BorderRadius.only(
//             topLeft: const Radius.circular(16),
//             topRight: const Radius.circular(16),
//             bottomLeft: Radius.circular(isUser ? 16 : 0),
//             bottomRight: Radius.circular(isUser ? 0 : 16),
//           ),
//           boxShadow: [BoxShadow(color: Colors.black12, offset: const Offset(2,2), blurRadius:4)],
//         ),
//         child: Text(msg['text'], style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize:16)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final chatStream = FirebaseFirestore.instance.collection('users').doc(uid).collection('chats')
//       .orderBy('timestamp', descending: false)
//       .snapshots();

//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         title: const Text("DignoVet Chat"),
//         backgroundColor: Colors.teal,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.delete_forever),
//             tooltip: "Clear Chat",
//             onPressed: () async {
//               final confirm = await showDialog<bool>(
//                 context: context,
//                 builder: (_) => AlertDialog(
//                   title: const Text("Clear Chat?"),
//                   content: const Text("Are you sure you want to delete the chat history?"),
//                   actions: [
//                     TextButton(child: const Text("Cancel"), onPressed: ()=> Navigator.pop(context,false)),
//                     TextButton(child: const Text("Delete"), onPressed: ()=> Navigator.pop(context,true)),
//                   ],
//                 ),
//               );
//               if (confirm ?? false) _clearChat();
//             },
//           )
//         ],
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: StreamBuilder(
//                 stream: chatStream,
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
//                   final docs = snapshot.data!.docs;
//                   return ListView.builder(
//                     controller: _scrollController,
//                     itemCount: docs.length,
//                     itemBuilder: (context, index) => _buildMessage(docs[index].data()),
//                   );
//                 },
//               ),
//             ),
//             if (_isLoading) const Padding(
//               padding: EdgeInsets.all(8),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [SizedBox(width:24,height:24,child:CircularProgressIndicator(strokeWidth:2)),SizedBox(width:10),Text("AI is typing...",style:TextStyle(color:Colors.grey))],
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.all(8),
//               color: Colors.white,
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _controller,
//                       textCapitalization: TextCapitalization.sentences,
//                       decoration: InputDecoration(
//                         hintText: "Ask about FMD disease in animals...",
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                         filled: true,
//                         fillColor: Colors.grey.shade100,
//                       ),
//                       onSubmitted: (_) => _sendMessage(),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   CircleAvatar(
//                     backgroundColor: Colors.teal,
//                     child: IconButton(icon: const Icon(Icons.send,color: Colors.white), onPressed: _isLoading ? null : _sendMessage),
//                   )
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

//----Better ui code for chat screen----//
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/services/chat_bot_api_sservces/chatBot_servcies.dart';

class DignoVetChatScreen extends StatefulWidget {
  const DignoVetChatScreen({super.key});

  @override
  State<DignoVetChatScreen> createState() => _DignoVetChatScreenState();
}

class _DignoVetChatScreenState extends State<DignoVetChatScreen> {

  // 🎨 Color Scheme
  final Color primaryDark = const Color(0xFF00796B);
  final Color primaryMedium = const Color(0xFF4DB6AC);
  final Color primaryLight = const Color(0xFF80CBC4);
  final Color darkText = const Color(0xFF2C3E50);

  final GroqService _groqService = GroqService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() => _isLoading = true);
    _controller.clear();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chats')
        .add({
      'role': 'user',
      'text': userMessage,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _scrollToBottom();

    try {
      final botReply = await _groqService.sendMessage(userMessage);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('chats')
          .add({
        'role': 'bot',
        'text': botReply,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('chats')
          .add({
        'role': 'bot',
        'text': 'Error: $e',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
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

  Future<void> _clearChat() async {
    final snapshots = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chats')
        .get();

    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? primaryDark : primaryLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 2),
            )
          ],
        ),
        child: Text(
          msg['text'],
          style: TextStyle(
            color: isUser ? Colors.white : darkText,
            fontSize: 15.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chats')
        .orderBy('timestamp', descending: false)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: primaryDark,
        title: const Text(
          "DignoVet Chat Screen",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Clear Chat",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Clear Chat"),
                  content: const Text(
                      "Are you sure you want to delete all chat history?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );

              if (confirm ?? false) {
                _clearChat();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: chatStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: docs.length,
                    itemBuilder: (context, index) =>
                        _buildMessage(docs[index].data() as Map<String, dynamic>),
                  );
                },
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "DignoVet AI is typing...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText:
                            "Ask about animal diseases, vaccines, care...",
                        hintStyle:
                            TextStyle(color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: primaryDark,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

