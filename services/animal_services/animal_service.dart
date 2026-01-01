import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/animal_model.dart';

class AnimalService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> registerAnimal(Animal animal) async {
    await _firestore.collection('animals').add(animal.toMap());
  }
}
