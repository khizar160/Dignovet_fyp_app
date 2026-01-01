import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save a prediction to Firestore
  Future<void> savePrediction({
    required String userId,
    required String animalId,
    required Map<String, dynamic> animalData,
    required String symptoms,
    required String prediction,
    required double confidence,
    required Map<String, dynamic> probabilities,
  }) async {
    try {
      await _firestore.collection('predictions').add({
        'userId': userId,
        'animalId': animalId,
        'animalData': animalData,
        'symptoms': symptoms,
        'prediction': prediction,
        'confidence': confidence,
        'probabilities': probabilities,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save prediction: $e');
    }
  }

  /// Fetch predictions for a specific user
  Stream<List<Map<String, dynamic>>> getPredictionsForUser(String userId) {
    return _firestore
        .collection('predictions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }
}
