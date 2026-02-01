import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itm_connect/models/feedback_entry.dart';
import 'package:itm_connect/models/feedback.dart' as fb_model;

class FeedbackService {
  final CollectionReference _col = FirebaseFirestore.instance.collection('feedback');

  Stream<List<FeedbackEntry>> streamAllFeedbacks() {
    return _col.snapshots().map((snap) {
      return snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return FeedbackEntry.fromMap(d.id, data);
      }).toList();
    });
  }

  Future<void> deleteFeedback(String docId) async {
    await _col.doc(docId).delete();
  }

  Future<void> submitFeedback(dynamic entry) async {
    String docId;
    Map<String, dynamic> data;

    if (entry is FeedbackEntry) {
      docId = '${entry.date}_${entry.email}';
      data = {
        'date': entry.date,
        'time': entry.time,
        'email': entry.email,
        'name': entry.name,
        'feedbackType': entry.feedbackType,
        'message': entry.message,
      };
    } else if (entry is fb_model.Feedback) {
      docId = entry.id;
      data = entry.toMap();
    } else {
      throw ArgumentError('Unsupported feedback type');
    }

    await _col.doc(docId).set(data, SetOptions(merge: true));
  }
}
