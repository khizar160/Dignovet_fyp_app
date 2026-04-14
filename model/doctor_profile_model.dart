class Doctor {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? specialization;
  final int? experience;
  final String? clinicAddress;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final bool isProfileComplete;
  final Map<String, dynamic>? availabilitySlots;
  final double onlineConsultationFee;
  final double homeVisitFee;
  final String? stripeAccountId; // Doctor's Stripe Connected Account ID

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.specialization,
    this.experience,
    this.clinicAddress,
    this.latitude,
    this.longitude,
    this.imageUrl,
    required this.isProfileComplete,
    this.availabilitySlots,
    this.onlineConsultationFee = 0.0,
    this.homeVisitFee = 0.0,
    this.stripeAccountId,
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
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      imageUrl: map['imageUrl'],
      isProfileComplete: map['isProfileComplete'] ?? false,
      availabilitySlots: map['availabilitySlots'],
      onlineConsultationFee: (map['onlineConsultationFee'] ?? 0.0).toDouble(),
      homeVisitFee: (map['homeVisitFee'] ?? 0.0).toDouble(),
      stripeAccountId: map['stripeAccountId'],
    );
  }
}
