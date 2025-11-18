import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itm_connect/models/teacher.dart';

class TeacherService {
    // Stream all teachers from Firestore
    Stream<List<Teacher>> streamAllTeachers() {
      return teachersCollection.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Teacher(
            id: doc.id,
            name: data['name'] ?? '',
            email: data['email'] ?? '',
            role: data['role'] ?? '',
            imageUrl: data['imageUrl'] ?? '',
          );
        }).toList();
      });
    }

    // Delete a teacher by initial
    Future<void> deleteTeacher(String teacherInitial) async {
      await teachersCollection.doc(teacherInitial).delete();
    }
  final CollectionReference teachersCollection =
      FirebaseFirestore.instance.collection('teachers');

  Future<void> addOrUpdateTeacher({
    required String teacherInitial,
    required String name,
    required String email,
    required String role,
    required String imageUrl,
  }) async {
    await teachersCollection.doc(teacherInitial).set({
      'teacherInitial': teacherInitial,
      'name': name,
      'email': email,
      'role': role,
      'imageUrl': imageUrl,
    });
  }
}
