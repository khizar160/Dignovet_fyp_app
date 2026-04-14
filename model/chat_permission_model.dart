import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages chat permissions based on appointment status
/// This model ensures proper access control for the consultation chat system
class ChatPermission {
  final String id;
  final String appointmentId;
  final String chatId; // Format: userId_doctorId or doctorId_userId
  final String userId;
  final String doctorId;
  
  // Permission flags
  final bool userCanRead; // User can read messages (true after doctor approves)
  final bool userCanSend; // User can send messages (true after doctor starts chat or appointment starts)
  final bool userCanDelete; // User can delete own messages
  final bool doctorCanRead; // Doctor can read messages (true after approval)
  final bool doctorCanSend; // Doctor can send messages (true always after approval)
  final bool doctorCanDelete; // Doctor can delete own messages
  final bool doctorCanEdit; // Doctor can edit messages (especially auto-generated)
  
  // Status tracking
  final Timestamp? permissionGrantedAt; // When user got read access (approval time)
  final Timestamp? firstMessageSentAt; // When conversation actually started
  final Timestamp createdAt;

  ChatPermission({
    required this.id,
    required this.appointmentId,
    required this.chatId,
    required this.userId,
    required this.doctorId,
    this.userCanRead = false,
    this.userCanSend = false,
    this.userCanDelete = true,
    this.doctorCanRead = false,
    this.doctorCanSend = false,
    this.doctorCanDelete = true,
    this.doctorCanEdit = true,
    this.permissionGrantedAt,
    this.firstMessageSentAt,
    required this.createdAt,
  });

  /// Convert model to map for Firestore
  Map<String, dynamic> toMap() => {
        'appointmentId': appointmentId,
        'chatId': chatId,
        'userId': userId,
        'doctorId': doctorId,
        'userCanRead': userCanRead,
        'userCanSend': userCanSend,
        'userCanDelete': userCanDelete,
        'doctorCanRead': doctorCanRead,
        'doctorCanSend': doctorCanSend,
        'doctorCanDelete': doctorCanDelete,
        'doctorCanEdit': doctorCanEdit,
        'permissionGrantedAt': permissionGrantedAt,
        'firstMessageSentAt': firstMessageSentAt,
        'createdAt': createdAt,
      };

  /// Convert Firestore document to model
  factory ChatPermission.fromMap(Map<String, dynamic> map, String id) {
    return ChatPermission(
      id: id,
      appointmentId: map['appointmentId'] ?? '',
      chatId: map['chatId'] ?? '',
      userId: map['userId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      userCanRead: map['userCanRead'] ?? false,
      userCanSend: map['userCanSend'] ?? false,
      userCanDelete: map['userCanDelete'] ?? true,
      doctorCanRead: map['doctorCanRead'] ?? false,
      doctorCanSend: map['doctorCanSend'] ?? false,
      doctorCanDelete: map['doctorCanDelete'] ?? true,
      doctorCanEdit: map['doctorCanEdit'] ?? true,
      permissionGrantedAt: map['permissionGrantedAt'],
      firstMessageSentAt: map['firstMessageSentAt'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  /// Create a copy of this permission with modified properties
  ChatPermission copyWith({
    bool? userCanRead,
    bool? userCanSend,
    bool? doctorCanRead,
    bool? doctorCanSend,
    Timestamp? permissionGrantedAt,
    Timestamp? firstMessageSentAt,
  }) {
    return ChatPermission(
      id: id,
      appointmentId: appointmentId,
      chatId: chatId,
      userId: userId,
      doctorId: doctorId,
      userCanRead: userCanRead ?? this.userCanRead,
      userCanSend: userCanSend ?? this.userCanSend,
      userCanDelete: userCanDelete,
      doctorCanRead: doctorCanRead ?? this.doctorCanRead,
      doctorCanSend: doctorCanSend ?? this.doctorCanSend,
      doctorCanDelete: doctorCanDelete,
      doctorCanEdit: doctorCanEdit,
      permissionGrantedAt: permissionGrantedAt ?? this.permissionGrantedAt,
      firstMessageSentAt: firstMessageSentAt ?? this.firstMessageSentAt,
      createdAt: createdAt,
    );
  }
}
