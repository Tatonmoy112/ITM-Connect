import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news.dart';

class NewsService {
  final CollectionReference newsCollection =
      FirebaseFirestore.instance.collection('news');

  // Add or Update News
  Future<void> addNews(News news) async {
    final docRef = newsCollection.doc(news.id.isEmpty ? null : news.id);
    final String newsId = docRef.id;
    
    await docRef.set({
      'id': newsId,
      'title': news.title,
      'body': news.body,
      'date': news.date,
      'imageUrl': news.imageUrl,
      'facebookUrl': news.facebookUrl,
      'timestamp': FieldValue.serverTimestamp(), // For sorting
    });
  }

  // Delete News
  Future<void> deleteNews(String id) async {
    await newsCollection.doc(id).delete();
  }

  // Stream All News
  Stream<List<News>> streamAllNews() {
    return newsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return News.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
