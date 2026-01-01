// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/model/chat_model.dart';
// import 'package:flutter_application_1/services/chat_services/chat_services.dart';

// class ChatProvider with ChangeNotifier {
//   final ChatService _chatService = ChatService();

//   Future<void> sendMessage(ChatMessage message) async {
//     await _chatService.sendMessage(message);
//   }

//   Stream<List<ChatMessage>> getMessages(String userId, String doctorId) {
//     return _chatService.getMessages(userId, doctorId);
//   }
// }

//----------------Updated code wth images and camera code-----------------------
//----------------Updated ChatProvider with text, image, and video support-----------------------
import 'dart:io';
import 'package:flutter/material.dart';
import '../model/chat_model.dart';
import '../services/chat_services/chat_services.dart';
import '../services/Supabase storage services/supabase_chat_storage.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final SupabaseChatStorage _storage = SupabaseChatStorage();

  // Get chat messages between two users
  Stream<List<ChatMessage>> getMessages(String senderId, String receiverId) =>
      _chatService.getMessages(senderId, receiverId);

  // Send text message
  Future<void> sendText(ChatMessage msg) async {
    await _chatService.sendMessage(msg);
  }

  // Send media (image or video)
  Future<void> sendMedia(
      String senderId,
      String receiverId,
      File file,
      MessageType type,
      ) async {
    String mediaUrl;

    if (type == MessageType.image) {
      mediaUrl = await _storage.uploadImage(file, senderId);
    } else if (type == MessageType.video) {
      mediaUrl = await _storage.uploadVideo(file, senderId);
    } else {
      throw Exception('Unsupported media type');
    }

    final msg = ChatMessage(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      mediaUrl: mediaUrl,
      type: type,
      timestamp: DateTime.now(),
    );

    await _chatService.sendMessage(msg);
  }
}
