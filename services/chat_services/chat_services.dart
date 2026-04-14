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

  String _lastMessageLabel(ChatMessage message) {
    if (message.type == MessageType.image) return 'Image';
    if (message.type == MessageType.video) return 'Video';
    if (message.type == MessageType.prescription) return 'Prescription';
    return (message.text ?? '').isEmpty ? 'Message' : (message.text ?? 'Message');
  }

  Future<void> sendMessage(ChatMessage message) async {
    final chatId = _chatId(message.senderId, message.receiverId);

    await _firestore.collection('chats').doc(chatId).set({
      'participants': [message.senderId, message.receiverId],
      'lastMessage': _lastMessageLabel(message),
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

  Future<void> deleteMessage({
    required String senderId,
    required String receiverId,
    required String messageId,
  }) async {
    final chatId = _chatId(senderId, receiverId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    await chatRef.collection('messages').doc(messageId).delete();

    final latest = await chatRef
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (latest.docs.isEmpty) {
      await chatRef.set({
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    final latestMsg = ChatMessage.fromMap(latest.docs.first.data(), latest.docs.first.id);
    await chatRef.set({
      'lastMessage': _lastMessageLabel(latestMsg),
      'lastMessageTime': latestMsg.timestamp,
    }, SetOptions(merge: true));
  }

  Future<void> clearChat({
    required String userA,
    required String userB,
  }) async {
    final chatId = _chatId(userA, userB);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messagesRef = chatRef.collection('messages');

    while (true) {
      final snapshot = await messagesRef.limit(400).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < 400) break;
    }

    await chatRef.set({
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'clearedAt': FieldValue.serverTimestamp(),
      'clearedBy': userA,
    }, SetOptions(merge: true));
  }
}
