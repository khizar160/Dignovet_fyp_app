import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String userId;
  final String doctorId;
  final String animalName;
  final Timestamp date;
  final String time;
  final String problem;
  final String status;
  final String consultationType; // 'online' or 'home_visit'
  final double paymentAmount;
  final String? paymentIntentId; // Stripe Payment Intent ID
  final String? paymentScreenshotUrl;
  final String? paymentStatus; // 'pending', 'paid', 'refunded'
  final Timestamp? paymentDate;
  final String? refundId; // Stripe Refund ID if refunded
  final String? paymentMethod; // 'JazzCash' or 'EasyPaisa'
  final String? declineReason;
  final String? declineReasonText;
  final String? doctorDeclineMessage;
  final String? declineCategoryText;
  final bool? refundRequired;
  final Timestamp? declinedAt;
  final Timestamp? createdAt;
  
  // Chat & Consultation System
  final String chatStatus; // 'disabled', 'read-only' (user), 'enabled' (both can send)
  final Timestamp? consultationStartTime; // When doctor approves - user gets read-only access
  final Timestamp? consultationEndTime; // Appointment time + slotDuration
  final int slotDuration; // Duration in minutes (15, 30, 60, etc.)
  final bool appointmentReminder15minSent; // Tracks if 15-min reminder sent
  final bool appointmentEndedNotificationSent; // Tracks if appointment ended notification sent
  final String? autoConfirmationMessageId; // ID of auto-generated approval message
  final bool doctorStartedConversation; // True when doctor sends first message
  final bool userRated; // True if user rated doctor & app
  final bool doctorRated; // True if doctor rated interaction (if applicable)

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.animalName,
    required this.date,
    required this.time,
    required this.problem,
    required this.status,
    this.consultationType = 'online',
    this.paymentAmount = 0.0,
    this.paymentIntentId,
    this.paymentScreenshotUrl,
    this.paymentStatus = 'pending',
    this.paymentDate,
    this.refundId,
    this.paymentMethod,
    this.declineReason,
    this.declineReasonText,
    this.doctorDeclineMessage,
    this.declineCategoryText,
    this.refundRequired,
    this.declinedAt,
    this.createdAt,
    this.chatStatus = 'disabled',
    this.consultationStartTime,
    this.consultationEndTime,
    this.slotDuration = 30, // Default to 30 minutes if not specified
    this.appointmentReminder15minSent = false,
    this.appointmentEndedNotificationSent = false,
    this.autoConfirmationMessageId,
    this.doctorStartedConversation = false,
    this.userRated = false,
    this.doctorRated = false,
  });

  /// Convert model to map for Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'doctorId': doctorId,
        'animalName': animalName,
        'date': date,
        'time': time,
        'problem': problem,
        'status': status,
        'consultationType': consultationType,
        'paymentAmount': paymentAmount,
        'paymentIntentId': paymentIntentId,
        'paymentScreenshotUrl': paymentScreenshotUrl,
        'paymentStatus': paymentStatus,
        'paymentDate': paymentDate,
        'refundId': refundId,
        'paymentMethod': paymentMethod,
        'declineReason': declineReason,
        'declineReasonText': declineReasonText,
        'doctorDeclineMessage': doctorDeclineMessage,
        'declineCategoryText': declineCategoryText,
        'refundRequired': refundRequired,
        'declinedAt': declinedAt,
        'createdAt': createdAt ?? Timestamp.now(),
        'chatStatus': chatStatus,
        'consultationStartTime': consultationStartTime,
        'consultationEndTime': consultationEndTime,
        'slotDuration': slotDuration,
        'appointmentReminder15minSent': appointmentReminder15minSent,
        'appointmentEndedNotificationSent': appointmentEndedNotificationSent,
        'autoConfirmationMessageId': autoConfirmationMessageId,
        'doctorStartedConversation': doctorStartedConversation,
        'userRated': userRated,
        'doctorRated': doctorRated,
      };

  /// Convert Firestore document to model
  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AppointmentModel(
      id: id,
      userId: map['userId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      animalName: map['animalName'] ?? '',
      date: map['date'] ?? Timestamp.now(),
      time: map['time'] ?? '',
      problem: map['problem'] ?? '',
      status: map['status'] ?? 'pending',
      consultationType: map['consultationType'] ?? 'online',
      paymentAmount: (map['paymentAmount'] ?? 0.0).toDouble(),
      paymentIntentId: map['paymentIntentId'],
      paymentScreenshotUrl: map['paymentScreenshotUrl'],
      paymentStatus: map['paymentStatus'] ?? 'pending',
      paymentDate: map['paymentDate'],
      refundId: map['refundId'],
      paymentMethod: map['paymentMethod'],
      declineReason: map['declineReason'],
      declineReasonText: map['declineReasonText'],
      doctorDeclineMessage: map['doctorDeclineMessage'],
      declineCategoryText: map['declineCategoryText'],
      refundRequired: map['refundRequired'],
      declinedAt: map['declinedAt'],
      createdAt: map['createdAt'],
      chatStatus: map['chatStatus'] ?? 'disabled',
      consultationStartTime: map['consultationStartTime'],
      consultationEndTime: map['consultationEndTime'],
      slotDuration: map['slotDuration'] ?? 30,
      appointmentReminder15minSent: map['appointmentReminder15minSent'] ?? false,
      appointmentEndedNotificationSent: map['appointmentEndedNotificationSent'] ?? false,
      autoConfirmationMessageId: map['autoConfirmationMessageId'],
      doctorStartedConversation: map['doctorStartedConversation'] ?? false,
      userRated: map['userRated'] ?? false,
      doctorRated: map['doctorRated'] ?? false,
    );
  }

  /// Create a copy of this appointment with some fields replaced
  AppointmentModel copyWith({
    String? id,
    String? userId,
    String? doctorId,
    String? animalName,
    Timestamp? date,
    String? time,
    String? problem,
    String? status,
    String? consultationType,
    double? paymentAmount,
    String? paymentIntentId,
    String? paymentScreenshotUrl,
    String? paymentStatus,
    Timestamp? paymentDate,
    String? refundId,
    String? paymentMethod,
    String? declineReason,
    String? declineReasonText,
    String? doctorDeclineMessage,
    String? declineCategoryText,
    bool? refundRequired,
    Timestamp? declinedAt,
    Timestamp? createdAt,
    String? chatStatus,
    Timestamp? consultationStartTime,
    Timestamp? consultationEndTime,
    int? slotDuration,
    bool? appointmentReminder15minSent,
    bool? appointmentEndedNotificationSent,
    String? autoConfirmationMessageId,
    bool? doctorStartedConversation,
    bool? userRated,
    bool? doctorRated,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      doctorId: doctorId ?? this.doctorId,
      animalName: animalName ?? this.animalName,
      date: date ?? this.date,
      time: time ?? this.time,
      problem: problem ?? this.problem,
      status: status ?? this.status,
      consultationType: consultationType ?? this.consultationType,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      paymentScreenshotUrl: paymentScreenshotUrl ?? this.paymentScreenshotUrl,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDate: paymentDate ?? this.paymentDate,
      refundId: refundId ?? this.refundId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      declineReason: declineReason ?? this.declineReason,
      declineReasonText: declineReasonText ?? this.declineReasonText,
      doctorDeclineMessage: doctorDeclineMessage ?? this.doctorDeclineMessage,
      declineCategoryText: declineCategoryText ?? this.declineCategoryText,
      refundRequired: refundRequired ?? this.refundRequired,
      declinedAt: declinedAt ?? this.declinedAt,
      createdAt: createdAt ?? this.createdAt,
      chatStatus: chatStatus ?? this.chatStatus,
      consultationStartTime: consultationStartTime ?? this.consultationStartTime,
      consultationEndTime: consultationEndTime ?? this.consultationEndTime,
      slotDuration: slotDuration ?? this.slotDuration,
      appointmentReminder15minSent: appointmentReminder15minSent ?? this.appointmentReminder15minSent,
      appointmentEndedNotificationSent: appointmentEndedNotificationSent ?? this.appointmentEndedNotificationSent,
      autoConfirmationMessageId: autoConfirmationMessageId ?? this.autoConfirmationMessageId,
      doctorStartedConversation: doctorStartedConversation ?? this.doctorStartedConversation,
      userRated: userRated ?? this.userRated,
      doctorRated: doctorRated ?? this.doctorRated,
    );
  }
}
