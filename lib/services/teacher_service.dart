import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itm_connect/models/teacher.dart';

class TeacherService {
    // Stream all teachers from Firestore
    Stream<List<Teacher>> streamAllTeachers() {
      return teachersCollection.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Get teacherInitial: prefer Firestore field, fallback to doc.id
          String teacherInitial = (data['teacherInitial'] ?? doc.id ?? '').toString().trim();
          
          return Teacher(
            id: doc.id,
            name: data['name'] ?? '',
            email: data['email'] ?? '',
            role: data['role'] ?? '',
            imageUrl: data['imageUrl'] ?? '',
            teacherInitial: teacherInitial,
          );
        }).toList();
      });
    }

    // Delete a teacher by initial
    Future<void> deleteTeacher(String teacherInitial) async {
      await teachersCollection.doc(teacherInitial).delete();
    }

    // Get all teachers (Future version)
    Future<List<Teacher>> getAllTeachers() async {
      final snapshot = await teachersCollection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get teacherInitial: prefer Firestore field, fallback to doc.id
        String teacherInitial = (data['teacherInitial'] ?? doc.id ?? '').toString().trim();
        
        return Teacher(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          teacherInitial: teacherInitial,
        );
      }).toList();
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
