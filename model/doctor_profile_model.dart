class Doctor {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? specialization;
  final int? experience;
  final String? clinicAddress;
  final String? imageUrl;
  final bool isProfileComplete;
  final Map<String, dynamic>? availabilitySlots;

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.specialization,
    this.experience,
    this.clinicAddress,
    this.imageUrl,
    required this.isProfileComplete,
    this.availabilitySlots,
  });

  factory Doctor.fromMap(Map<String, dynamic> map, String id) {
    return Doctor(
      id: id,
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      specialization: map['specialization'],
      experience: map['experience'],
      clinicAddress: map['clinicAddress'],
      imageUrl: map['imageUrl'],
      isProfileComplete: map['isProfileComplete'] ?? false,
      availabilitySlots: map['availabilitySlots'],
    );
  }
}
