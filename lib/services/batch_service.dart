import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/batch.dart';

class BatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'batches';

  // Get batch info by ID
  Future<BatchInfo?> getBatchInfo(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return BatchInfo.fromMap(doc.id, doc.data());
    } catch (e) {
      return null;
    }
  }

  // Set or update batch info
  Future<void> setBatchInfo(BatchInfo batchInfo) async {
    await _firestore.collection(_collection).doc(batchInfo.id).set(
          batchInfo.toMap(),
          SetOptions(merge: true),
        );
  }

  // Stream batch info
  Stream<BatchInfo?> streamBatchInfo(String id) {
    return _firestore.collection(_collection).doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BatchInfo.fromMap(doc.id, doc.data());
    });
  }

  // Get all batch IDs for suggestions
  Future<List<String>> getAllBatchIds() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print("Error fetching batch IDs: $e");
      return [];
    }
  }

  // Stream all batch IDs
  Stream<List<String>> streamAllBatchIds() {
    return _firestore.collection(_collection).snapshots().map((snap) {
      return snap.docs.map((doc) => doc.id).toList();
    });
  }
}
