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
  final String? about;
  final List<String>? availableDays;
  final List<String>? availableSlots;
  final bool? profileCompleted;

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
    this.about,
    this.availableDays,
    this.availableSlots,
    this.profileCompleted,
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
      about: map['about'],
      availableDays: map['availableDays'] != null 
          ? List<String>.from(map['availableDays']) 
          : null,
      availableSlots: map['availableSlots'] != null 
          ? List<String>.from(map['availableSlots']) 
          : null,
      profileCompleted: map['profileCompleted'],
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

