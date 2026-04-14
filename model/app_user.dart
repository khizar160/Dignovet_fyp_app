// class AppUser {
//   final String id;
//   final String name;
//   final String role;
//   final String imageUrl;
//   final bool online;

//   AppUser({
//     required this.id,
//     required this.name,
//     required this.role,
//     required this.imageUrl,
//     required this.online,
//   });

//   factory AppUser.fromMap(Map<String, dynamic> map, String id) {
//     return AppUser(
//       id: id,
//       name: map['name'] ?? '',
//       role: map['role'] ?? 'user',
//       imageUrl: map['imageUrl'] ?? '',
//       online: map['online'] ?? false,
//     );
//   }
// }



// Add this import at top
import 'package:cloud_firestore/cloud_firestore.dart';
class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String imageUrl;
  final bool online;
  final bool isBlocked;
  final DateTime? createdAt;
  
  // Doctor-specific fields (null for non-doctors)
  final String? specialization;
  final int? experience;
  final String? clinicName;
  final String? clinicAddress;
  final double? latitude;
  final double? longitude;
  final String? about;
  final List<String>? availableDays;
  final List<String>? availableSlots;
  final bool? profileCompleted;
  final double? onlineConsultationFee;
  final double? homeVisitFee;
  final double? averageRating;
  final int? totalReviews;
  final double? ratingSum;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.imageUrl,
    required this.online,
    required this.isBlocked,
    this.createdAt,
    // Doctor fields
    this.specialization,
    this.experience,
    this.clinicName,
    this.clinicAddress,
    this.latitude,
    this.longitude,
    this.about,
    this.availableDays,
    this.availableSlots,
    this.profileCompleted,
    this.onlineConsultationFee,
    this.homeVisitFee,
    this.averageRating,
    this.totalReviews,
    this.ratingSum,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'user',
      imageUrl: map['imageUrl'] ?? '',
      online: map['online'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
      // Doctor fields
      specialization: map['specialization'],
      experience: map['experience'],
      clinicName: map['clinicName'],
      clinicAddress: map['clinicAddress'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      about: map['about'],
      availableDays: map['availableDays'] != null 
          ? List<String>.from(map['availableDays']) 
          : null,
      availableSlots: map['availableSlots'] != null 
          ? List<String>.from(map['availableSlots']) 
          : null,
      profileCompleted: map['profileCompleted'],
      onlineConsultationFee: map['onlineConsultationFee']?.toDouble(),
      homeVisitFee: map['homeVisitFee']?.toDouble(),
      averageRating: map['averageRating']?.toDouble(),
      totalReviews: map['totalReviews'],
      ratingSum: map['ratingSum']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'imageUrl': imageUrl,
      'online': online,
      'isBlocked': isBlocked,
    };

    // Add doctor fields only if role is doctor
    if (role == 'doctor') {
      map.addAll({
        'specialization': specialization ?? '',
        'experience': experience ?? 0,
        'clinicName': clinicName ?? '',
        'clinicAddress': clinicAddress ?? '',
        'about': about ?? '',
        'availableDays': availableDays ?? [],
        'availableSlots': availableSlots ?? [],
        'profileCompleted': profileCompleted ?? false,
      });
      
      // Add latitude and longitude only if they're not null
      if (latitude != null) {
        map['latitude'] = latitude!;
      }
      if (longitude != null) {
        map['longitude'] = longitude!;
      }
      if (onlineConsultationFee != null) {
        map['onlineConsultationFee'] = onlineConsultationFee!;
      }
      if (homeVisitFee != null) {
        map['homeVisitFee'] = homeVisitFee!;
      }
      if (averageRating != null) {
        map['averageRating'] = averageRating!;
      }
      if (totalReviews != null) {
        map['totalReviews'] = totalReviews!;
      }
      if (ratingSum != null) {
        map['ratingSum'] = ratingSum!;
      }
    }

    return map;
  }

  // Check if doctor profile is complete
  bool isDoctorProfileComplete() {
    if (role != 'doctor') return true;
    
    return specialization != null &&
           specialization!.isNotEmpty &&
           experience != null &&
           experience! > 0 &&
           clinicName != null &&
           clinicName!.isNotEmpty &&
           clinicAddress != null &&
           clinicAddress!.isNotEmpty &&
           about != null &&
           about!.isNotEmpty &&
           availableDays != null &&
           availableDays!.isNotEmpty &&
           availableSlots != null &&
           availableSlots!.isNotEmpty;
  }
}

