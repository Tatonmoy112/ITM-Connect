import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itm_connect/models/routine.dart';

class RoutineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'routines';

  // Create or overwrite routine document
  Future<void> setRoutine(Routine routine) async {
    try {
      await _firestore.collection(_collection).doc(routine.id).set(
            routine.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      rethrow;
    }
  }

  // Get a single routine document
  Future<Routine?> getRoutine(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return Routine.fromMap(doc.id, doc.data());
    } catch (e) {
      rethrow;
    }
  }

  // Stream a single routine doc (real-time)
  Stream<Routine?> streamRoutine(String id) {
    return _firestore.collection(_collection).doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Routine.fromMap(doc.id, doc.data());
    });
  }

  // Delete routine document
  Future<void> deleteRoutine(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Add a class to the routine (append)
  Future<void> addClass(String routineId, RoutineClass newClass) async {
    final docRef = _firestore.collection(_collection).doc(routineId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      List existing = [];
      Map<String, dynamic> base = {};
      if (snapshot.exists) {
        base = snapshot.data() as Map<String, dynamic>;
        existing = (base['classes'] as List<dynamic>?) ?? [];
      }
      existing.add(newClass.toMap());
      final updated = {...base, 'classes': existing};
      tx.set(docRef, updated, SetOptions(merge: true));
    });
  }

  // Update a class by index
  Future<void> updateClass(String routineId, int index, RoutineClass updatedClass) async {
    final docRef = _firestore.collection(_collection).doc(routineId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists) throw Exception('Routine does not exist');
      final base = snapshot.data() as Map<String, dynamic>;
      final existing = List<Map<String, dynamic>>.from((base['classes'] as List<dynamic>? ) ?? []);
      if (index < 0 || index >= existing.length) throw Exception('Invalid index');
      existing[index] = updatedClass.toMap();
      final updated = {...base, 'classes': existing};
      tx.set(docRef, updated, SetOptions(merge: true));
    });
  }

  // Delete class by index
  Future<void> deleteClass(String routineId, int index) async {
    final docRef = _firestore.collection(_collection).doc(routineId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists) return;
      final base = snapshot.data() as Map<String, dynamic>;
      final existing = List<Map<String, dynamic>>.from((base['classes'] as List<dynamic>?) ?? []);
      if (index < 0 || index >= existing.length) return;
      existing.removeAt(index);
      final updated = {...base, 'classes': existing};
      tx.set(docRef, updated, SetOptions(merge: true));
    });
  }

  // Stream all routines (real-time)
  Stream<List<Routine>> streamAllRoutines() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Routine.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}
