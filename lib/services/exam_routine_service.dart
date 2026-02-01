import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itm_connect/models/exam_routine.dart';

class ExamRoutineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'exam_routines';

  Future<void> setExamRoutine(ExamRoutine routine) async {
    try {
      await _firestore.collection(_collection).doc(routine.id).set(routine.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteExamRoutine(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAllExamRoutines() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<ExamRoutine>> streamAllExamRoutines() {
    // Ordering by date descending so the newest exam routines appear first
    return _firestore.collection(_collection).orderBy('date', descending: true).snapshots().map((snap) {
      return snap.docs.map((d) => ExamRoutine.fromMap(d.id, d.data())).toList();
    });
  }

  Future<void> bulkUploadExamRoutines(List<ExamRoutine> routines) async {
    final batch = _firestore.batch();
    for (var routine in routines) {
      final docRef = _firestore.collection(_collection).doc(routine.id);
      batch.set(docRef, routine.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> createRandomExamData() async {
    final random = Random();
    final batches = ['58', '59', '60', '61'];
    final courses = [
      {'code': 'CSE-101', 'name': 'Introduction to Computer Systems'},
      {'code': 'CSE-102', 'name': 'Discrete Mathematics'},
      {'code': 'CSE-201', 'name': 'Data Structures'},
      {'code': 'CSE-203', 'name': 'Algorithms'},
      {'code': 'CSE-305', 'name': 'Software Engineering'},
    ];
    final titles = ['Mid Term Spring 2026', 'Final Term Spring 2026'];
    final times = ['10:00 AM - 12:00 PM', '02:00 PM - 04:00 PM'];

    final List<ExamRoutine> randomRoutines = [];

    for (int i = 0; i < 5; i++) {
       final batch = batches[random.nextInt(batches.length)];
       final course = courses[random.nextInt(courses.length)];
       final title = titles[random.nextInt(titles.length)];
       final time = times[random.nextInt(times.length)];
       
       // Random date within next 30 days
       final date = DateTime.now().add(Duration(days: random.nextInt(30)));
       final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
       
       final id = "${dateStr}_${course['code']}_$batch";
       
       randomRoutines.add(ExamRoutine(
         id: id,
         examTitle: title,
         batch: batch,
         courseName: course['name']!,
         courseCode: course['code']!,
         date: dateStr,
         time: time,
         room: "Room ${random.nextInt(20) + 100}",
       ));
    }
    
    await bulkUploadExamRoutines(randomRoutines);
  }
}
