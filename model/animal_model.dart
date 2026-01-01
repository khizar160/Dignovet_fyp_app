import 'package:cloud_firestore/cloud_firestore.dart';

class Animal {
  String? id;
  String name;
  String breed;
  int age;
  String gender;
  String userId;
  String suspectedDisease;
  String symptoms;
  DateTime createdAt;
  List<String> imageUrls;

  Animal({
    this.id,
    required this.imageUrls,
    required this.name,
    required this.breed,
    required this.age,
    required this.gender,
    required this.userId,
    required this.suspectedDisease,
    required this.symptoms,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'breed': breed,
      'age': age,

      'gender': gender,
      'userId': userId,
      'suspectedDisease': suspectedDisease,
      'symptoms': symptoms,
      'createdAt': createdAt,
      'imageUrls': imageUrls,
    };
  }

  factory Animal.fromMap(Map<String, dynamic> map, String id) {
    return Animal(
      id: id,
      name: map['name'] ?? '',
      breed: map['breed'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      userId: map['userId'] ?? '',
      suspectedDisease: map['suspectedDisease'] ?? '',
      symptoms: map['symptoms'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }
}
