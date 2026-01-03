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
  // 🎨 Color Scheme - Matching UserDashboard
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
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  colors: [primaryDark, primaryMedium],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : primaryLight.withOpacity(0.3),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg['text'],
          style: TextStyle(
            color: isUser ? Colors.white : darkText,
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w400,
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
      backgroundColor: Colors.grey.shade50,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryDark, primaryMedium, primaryLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            color: primaryDark,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "DignoVet Chat ",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "Chat Assistant",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text("Clear Chat"),
                              content: const Text(
                                "Are you sure you want to delete all chat history?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          );

                          if (confirm ?? false) {
                            _clearChat();
                          }
                        },
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Chat Container
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: chatStream,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: primaryDark,
                                ),
                              );
                            }

                            final docs = snapshot.data!.docs;

                            if (docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: primaryLight.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.chat_bubble_outline,
                                        size: 60,
                                        color: primaryMedium,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      "Start a Conversation",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Ask me about animal diseases, care, and health",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              itemCount: docs.length,
                              itemBuilder: (context, index) => _buildMessage(
                                docs[index].data() as Map<String, dynamic>,
                              ),
                            );
                          },
                        ),
                      ),

                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "DignoVet AI is typing...",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  hintText:
                                      "Ask about animal diseases, vaccines, care...",
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: primaryDark,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryDark, primaryMedium],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryDark.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.transparent,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _isLoading ? null : _sendMessage,
                                ),
                              ),
                            ),
                          ],
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
}
