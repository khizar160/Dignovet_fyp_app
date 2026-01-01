// import 'package:cloud_firestore/cloud_firestore.dart';

// class ChatMessage {
//   final String id;
//   final String senderId;
//   final String receiverId;
//   final String text;
//   final DateTime timestamp;

//   ChatMessage({
//     required this.id,
//     required this.senderId,
//     required this.receiverId,
//     required this.text,
//     required this.timestamp,
//   });

//   factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
//     return ChatMessage(
//       id: id,
//       senderId: map['senderId'],
//       receiverId: map['receiverId'],
//       text: map['text'],
//       timestamp: (map['timestamp'] as Timestamp).toDate(),
//     );
//   }

//   Map<String, dynamic> toMap() => {
//         'senderId': senderId,
//         'receiverId': receiverId,
//         'text': text,
//         'timestamp': timestamp,
//       };
// }


// ------Updated with camera images and saved images code-----------------------
import 'package:cloud_firestore/cloud_firestore.dart';
enum MessageType { text, image, video }

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String? text;
  final String? mediaUrl;
  final MessageType type;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.text,
    this.mediaUrl,
    this.type = MessageType.text,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      text: map['text'],
      mediaUrl: map['mediaUrl'],
      type: MessageType.values[map['type'] ?? 0],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'mediaUrl': mediaUrl,
        'type': type.index,
        'timestamp': timestamp,
      };
}
