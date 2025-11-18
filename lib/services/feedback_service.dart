import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itm_connect/models/feedback.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'feedback';

  Future<void> submitFeedback(Feedback feedback) async {
    try {
      await _firestore.collection(_collection).doc(feedback.id).set(feedback.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Feedback>> getAllFeedback() async {
    try {
      final snap = await _firestore.collection(_collection).orderBy('date', descending: true).get();
      return snap.docs.map((d) => Feedback.fromMap(d.id, d.data())).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Feedback>> streamAllFeedback() {
    return _firestore.collection(_collection).orderBy('date', descending: true).snapshots().map((snap) {
      return snap.docs.map((d) => Feedback.fromMap(d.id, d.data())).toList();
    });
  }
}
