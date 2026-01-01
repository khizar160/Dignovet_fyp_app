import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all doctors
  Stream<List<AppUser>> getDoctors() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppUser.fromMap(doc.data(), doc.id)).toList());
  }

  // Get user by ID
  Future<AppUser?> getUserById(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if (doc.exists) return AppUser.fromMap(doc.data()!, doc.id);
    return null;
  }
}
