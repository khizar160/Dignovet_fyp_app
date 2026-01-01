

class DoctorProfile {
  final String id;
  final String specialization;
  final int experience;
  final String clinicName;
  final String clinicAddress;
  final String about;
  final List<String> availableDays;
  final List<String> availableSlots;
  final String imageUrl; // ✅ doctor profile image

  DoctorProfile({
    required this.id,
    required this.specialization,
    required this.experience,
    required this.clinicName,
    required this.clinicAddress,
    required this.about,
    required this.availableDays,
    required this.availableSlots,
    required this.imageUrl,
  });

  factory DoctorProfile.fromMap(Map<String, dynamic> map, String id) {
    return DoctorProfile(
      id: id,
      specialization: map['specialization'] ?? '',
      experience: map['experience'] ?? 0,
      clinicName: map['clinicName'] ?? '',
      clinicAddress: map['clinicAddress'] ?? '',
      about: map['about'] ?? '',
      availableDays: List<String>.from(map['availableDays'] ?? []),
      availableSlots: List<String>.from(map['availableSlots'] ?? []),
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "specialization": specialization,
      "experience": experience,
      "clinicName": clinicName,
      "clinicAddress": clinicAddress,
      "about": about,
      "availableDays": availableDays,
      "availableSlots": availableSlots,
      "imageUrl": imageUrl,
    };
  }
}

