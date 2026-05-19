import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itm_connect/models/notice.dart';

class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notices';

  Future<void> setNotice(Notice notice) async {
    try {
      await _firestore.collection(_collection).doc(notice.id).set(notice.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteNotice(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<Notice?> getNotice(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return Notice.fromMap(doc.id, doc.data());
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Notice>> streamAllNotices() {
    return _firestore.collection(_collection).orderBy('date', descending: true).snapshots().map((snap) {
      return snap.docs.map((d) => Notice.fromMap(d.id, d.data())).toList();
    });
  }
}
