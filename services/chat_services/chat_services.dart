// import 'dart:developer';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_1/model/chat_model.dart';

// class ChatService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // --- Send a message ---
//   Future<void> sendMessage(ChatMessage message) async {
//     final chatId = message.senderId.compareTo(message.receiverId) < 0
//         ? '${message.senderId}_${message.receiverId}'
//         : '${message.receiverId}_${message.senderId}';

//     try {
//       // Create or update the chat document
//       await _firestore.collection('chats').doc(chatId).set({
//         'participants': [message.senderId, message.receiverId],
//         'lastMessage': message.text,
//         'lastMessageTime': message.timestamp,
//       }, SetOptions(merge: true));

//       await _firestore
//           .collection('chats')
//           .doc(chatId)
//           .collection('messages')
//           .add(message.toMap());

//       log('[Services] Message sent successfully');
//       log('[Services] ChatId: $chatId');
//       log(
//         '[Services] Sender: ${message.senderId}, Receiver: ${message.receiverId}',
//       );
//       log('[Services] Text: ${message.text}');
//       log('[Services] Timestamp: ${message.timestamp}');
//     } catch (e) {
//       log('[Services] Error sending message: $e');
//     }
//   }

//   Stream<List<String>> getChatUsers(String myId) {
//     return FirebaseFirestore.instance
//         .collection('chats')
//         .where('participants', arrayContains: myId)
//         .snapshots()
//         .map((snapshot) {
//           final userIds = <String>{};

//           for (var doc in snapshot.docs) {
//             final participants = List<String>.from(doc.data()['participants']);
//             participants.remove(myId);
//             userIds.addAll(participants);
//           }

//           return userIds.toList();
//         });
//   }

//   // --- Get chat messages between two users ---
//   Stream<List<ChatMessage>> getMessages(String userId, String doctorId) {
//     final chatId = userId.compareTo(doctorId) < 0
//         ? '${userId}_$doctorId'
//         : '${doctorId}_$userId';

//     log('[Services] Listening to chat messages for ChatId: $chatId');

//     return _firestore
//         .collection('chats')
//         .doc(chatId)
//         .collection('messages')
//         .orderBy('timestamp')
//         .snapshots()
//         .map((snapshot) {
//           final messages = snapshot.docs
//               .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
//               .toList();

//           log(
//             '[Services] Retrieved ${messages.length} messages for ChatId: $chatId',
//           );
//           for (var msg in messages) {
//             log(
//               '[Services] Message: ${msg.text}, Sender: ${msg.senderId}, Receiver: ${msg.receiverId}, Time: ${msg.timestamp}',
//             );
//           }
//           return messages;
//         });
//   }
// }



// ------Updated with camera images and saved images code-----------------------
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _chatId(String a, String b) =>
      a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';

  Future<void> sendMessage(ChatMessage message) async {
    final chatId = _chatId(message.senderId, message.receiverId);

    await _firestore.collection('chats').doc(chatId).set({
      'participants': [message.senderId, message.receiverId],
      'lastMessage': message.text ?? '📷 Image',
      'lastMessageTime': message.timestamp,
    }, SetOptions(merge: true));

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());

    log('Message sent → $chatId');
  }
 Stream<List<String>> getChatUsers(String myId) {
  return FirebaseFirestore.instance
      .collection('chats')
      .where('participants', arrayContains: myId)
      .snapshots()
      .map((snapshot) {
        final userIds = <String>{};

        for (var doc in snapshot.docs) {
          final participants = List<String>.from(doc.data()['participants']);
          participants.removeWhere((id) => id == myId); // removes all occurrences
          userIds.addAll(participants);
        }

        return userIds.toList();
      });
}

  Stream<List<ChatMessage>> getMessages(String a, String b) {
    final chatId = _chatId(a, b);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => ChatMessage.fromMap(d.data(), d.id))
            .toList());
  }
}
