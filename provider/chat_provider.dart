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
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../model/chat_model.dart';
import '../services/chat_services/chat_services.dart';
import '../services/Supabase storage services/supabase_chat_storage.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final SupabaseChatStorage _storage = SupabaseChatStorage();
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  // Get chat messages between two users
  Stream<List<ChatMessage>> getMessages(String senderId, String receiverId) =>
      _chatService.getMessages(senderId, receiverId);

  Future<void> deleteMessage({
    required String senderId,
    required String receiverId,
    required String messageId,
  }) async {
    await _chatService.deleteMessage(
      senderId: senderId,
      receiverId: receiverId,
      messageId: messageId,
    );
  }

  Future<void> clearChat({
    required String userA,
    required String userB,
  }) async {
    await _chatService.clearChat(userA: userA, userB: userB);
  }

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

  Future<String> sendPrescription(
    String senderId,
    String receiverId,
    File pdfFile, {
    required String summary,
    String? appointmentId,
    String? animalName,
    String? documentName,
    String? prescriptionId,
    String? doctorName,
    String? patientName,
    String? medicines,
    DateTime? prescriptionDate,
  }) async {
    final documentUrl = await _uploadPrescriptionWithFallback(
      senderId: senderId,
      pdfFile: pdfFile,
    );

    final msg = ChatMessage(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      text: summary,
      mediaUrl: documentUrl,
      appointmentId: appointmentId,
      animalName: animalName,
      documentName: documentName,
      prescriptionId: prescriptionId,
      doctorName: doctorName,
      patientName: patientName,
      medicines: medicines,
      prescriptionDate: prescriptionDate,
      type: MessageType.prescription,
      timestamp: DateTime.now(),
    );

    await _chatService.sendMessage(msg);
    return documentUrl;
  }

  Future<String> _uploadPrescriptionWithFallback({
    required String senderId,
    required File pdfFile,
  }) async {
    try {
      return await _storage.uploadDocument(
        pdfFile,
        senderId,
        extension: 'pdf',
      );
    } catch (supabaseError) {
      log('Supabase prescription upload failed, using Firebase fallback: $supabaseError');

      final fileName =
          'prescription_${senderId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final ref = _firebaseStorage.ref().child('chat_documents/$fileName');
      await ref.putFile(pdfFile);
      return await ref.getDownloadURL();
    }
  }
}
