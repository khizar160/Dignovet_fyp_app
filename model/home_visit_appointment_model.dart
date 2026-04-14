import 'package:cloud_firestore/cloud_firestore.dart';

class HomeVisitAppointmentModel {
  final String id;
  final String userId;
  final String doctorId;
  final String animalName;
  
  // Appointment Details
  final Timestamp requestDate;
  final String preferredTime; // e.g., "3:00 PM - 5:00 PM"
  final String problem;
  
  // Location Details
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark; // Optional landmark
  
  // Contact Details
  final String userPhone;
  final String? userNotes;
  
  // Status Flow
  final String status; // 'pending', 'accepted', 'rejected', 'on_the_way', 'completed', 'cancelled'
  final String? doctorAcceptanceTime;
  final String? doctorRejectionReason;
  
  // Doctor Details (saved when accepted)
  final String? doctorEstimatedArrival; // "Will arrive in 30 minutes"
  
  // Chat & Consultation
  final bool chatEnabled; // Enabled only after doctor accepts
  final Timestamp? chatEnabledAt;
  
  // Live Location Tracking
  final bool liveLocationEnabled;
  final double? doctorCurrentLatitude;
  final double? doctorCurrentLongitude;
  final String? doctorCurrentAddress; // Current address of doctor
  final String? doctorLocationUpdatedAt; // Timestamp of last location update
  final String? doctorStatus; // 'accepted', 'on_the_way', 'arrived', 'in_progress'
  final String? liveLocationEnabledAt; // Timestamp when live location was enabled
  
  // Visit Completion
  final Timestamp? visitCompletedAt;
  final String? visitNotes;
  
  // Payment
  final double homeVisitFee;
  final String paymentStatus; // 'pending', 'paid', 'completed'
  final String? paymentMethod; // 'cash', 'online'
  
  // Timestamps
  final Timestamp createdAt;
  final Timestamp updatedAt;

  HomeVisitAppointmentModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.animalName,
    required this.requestDate,
    required this.preferredTime,
    required this.problem,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
    required this.userPhone,
    this.userNotes,
    required this.status,
    this.doctorAcceptanceTime,
    this.doctorRejectionReason,
    this.doctorEstimatedArrival,
    this.chatEnabled = false,
    this.chatEnabledAt,
    this.liveLocationEnabled = false,
    this.doctorCurrentLatitude,
    this.doctorCurrentLongitude,
    this.doctorCurrentAddress,
    this.doctorLocationUpdatedAt,
    this.doctorStatus,
    this.liveLocationEnabledAt,
    this.visitCompletedAt,
    this.visitNotes,
    required this.homeVisitFee,
    this.paymentStatus = 'pending',
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to Firestore map
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'doctorId': doctorId,
    'animalName': animalName,
    'requestDate': requestDate,
    'preferredTime': preferredTime,
    'problem': problem,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'landmark': landmark,
    'userPhone': userPhone,
    'userNotes': userNotes,
    'status': status,
    'doctorAcceptanceTime': doctorAcceptanceTime,
    'doctorRejectionReason': doctorRejectionReason,
    'doctorEstimatedArrival': doctorEstimatedArrival,
    'chatEnabled': chatEnabled,
    'chatEnabledAt': chatEnabledAt,
    'liveLocationEnabled': liveLocationEnabled,
    'doctorCurrentLatitude': doctorCurrentLatitude,
    'doctorCurrentLongitude': doctorCurrentLongitude,
    'doctorCurrentAddress': doctorCurrentAddress,
    'doctorLocationUpdatedAt': doctorLocationUpdatedAt,
    'doctorStatus': doctorStatus,
    'liveLocationEnabledAt': liveLocationEnabledAt,
    'visitCompletedAt': visitCompletedAt,
    'visitNotes': visitNotes,
    'homeVisitFee': homeVisitFee,
    'paymentStatus': paymentStatus,
    'paymentMethod': paymentMethod,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  /// Create from Firestore map
  factory HomeVisitAppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    return HomeVisitAppointmentModel(
      id: id,
      userId: map['userId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      animalName: map['animalName'] ?? '',
      requestDate: map['requestDate'] ?? Timestamp.now(),
      preferredTime: map['preferredTime'] ?? '',
      problem: map['problem'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] ?? '',
      landmark: map['landmark'],
      userPhone: map['userPhone'] ?? '',
      userNotes: map['userNotes'],
      status: map['status'] ?? 'pending',
      doctorAcceptanceTime: map['doctorAcceptanceTime'],
      doctorRejectionReason: map['doctorRejectionReason'],
      doctorEstimatedArrival: map['doctorEstimatedArrival'],
      chatEnabled: map['chatEnabled'] ?? false,
      chatEnabledAt: map['chatEnabledAt'],
      liveLocationEnabled: map['liveLocationEnabled'] ?? false,
      doctorCurrentLatitude: (map['doctorCurrentLatitude'] as num?)?.toDouble(),
      doctorCurrentLongitude: (map['doctorCurrentLongitude'] as num?)?.toDouble(),
      doctorCurrentAddress: map['doctorCurrentAddress'],
      doctorLocationUpdatedAt: map['doctorLocationUpdatedAt'],
      doctorStatus: map['doctorStatus'],
      liveLocationEnabledAt: map['liveLocationEnabledAt'],
      visitCompletedAt: map['visitCompletedAt'],
      visitNotes: map['visitNotes'],
      homeVisitFee: (map['homeVisitFee'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map['paymentStatus'] ?? 'pending',
      paymentMethod: map['paymentMethod'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      updatedAt: map['updatedAt'] ?? Timestamp.now(),
    );
  }
}
