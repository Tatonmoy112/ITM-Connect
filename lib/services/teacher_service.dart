import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itm_connect/models/teacher.dart';

class TeacherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'teachers';

  // Create or update a teacher
  Future<void> setTeacher(Teacher teacher) async {
    try {
      await _firestore.collection(_collection).doc(teacher.id).set(
            teacher.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      rethrow;
    }
  }

  // Get single teacher by ID
  Future<Teacher?> getTeacher(String teacherId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(teacherId).get();
      if (doc.exists) {
        return Teacher.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get all teachers (one-time fetch)
  Future<List<Teacher>> getAllTeachers() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs
          .map((doc) => Teacher.fromMap(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Stream all teachers (real-time updates)
  Stream<List<Teacher>> streamAllTeachers() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Teacher.fromMap(doc.data()))
          .toList();
    });
  }

  // Stream single teacher (real-time)
  Stream<Teacher?> streamTeacher(String teacherId) {
    return _firestore
        .collection(_collection)
        .doc(teacherId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return Teacher.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Update specific fields of a teacher
  Future<void> updateTeacher(String teacherId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(teacherId).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a teacher
  Future<void> deleteTeacher(String teacherId) async {
    try {
      await _firestore.collection(_collection).doc(teacherId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Search teachers by name
  Future<List<Teacher>> searchTeachersByName(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();
      return snapshot.docs
          .map((doc) => Teacher.fromMap(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Check if teacher exists
  Future<bool> teacherExists(String teacherId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(teacherId).get();
      return doc.exists;
    } catch (e) {
      rethrow;
    }
  }

  // Get teacher count
  Future<int> getTeacherCount() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      rethrow;
    }
  }
}
