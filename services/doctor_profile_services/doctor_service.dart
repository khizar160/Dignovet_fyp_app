import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/model/doctor_model.dart';


class DoctorService {
  final _db = FirebaseFirestore.instance;

  Future<DoctorProfile?> getDoctor(String uid) async {
    final doc = await _db.collection("doctors").doc(uid).get();
    if (!doc.exists) return null;
    return DoctorProfile.fromMap(doc.data()!, doc.id);
  }

  Future<void> saveDoctorProfile(String uid, DoctorProfile doctor) async {
    await _db.collection("doctors").doc(uid).set(doctor.toMap());
  }
}
