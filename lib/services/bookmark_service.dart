// services/bookmark_service.dart
import 'package:cloud_firestore/cloud_firestore.dart' hide Source;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/news_model.dart';

class BookmarkService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final User? _user = FirebaseAuth.instance.currentUser;

  static CollectionReference get _bookmarksRef {
    if (_user == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(_user!.uid).collection('bookmarks');
  }

  static Future<void> addBookmark(NewsArticle article) async {
    await _bookmarksRef.doc(article.url).set({
      'title': article.title,
      'description': article.description,
      'content': article.content,
      'url': article.url,
      'image': article.image,
      'source': article.source.name,
      'sourceId': article.source.id,
      'publishedAt': Timestamp.fromDate(article.publishedAt),
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeBookmark(String url) async {
    await _bookmarksRef.doc(url).delete();
  }

  static Future<bool> isBookmarked(String url) async {
    final doc = await _bookmarksRef.doc(url).get();
    return doc.exists;
  }

  static Stream<List<NewsArticle>> getAllBookmarks() {
    return _bookmarksRef.orderBy('savedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return NewsArticle(
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          content: data['content'] ?? '',
          url: data['url'] ?? '',
          image: data['image'] ?? '',
          publishedAt: (data['publishedAt'] as Timestamp).toDate(),
          source: Source(
            id: data['sourceId'] ?? '',
            name: data['source'] ?? 'Unknown',
            url: '',
          ),
        );
      }).toList();
    });
  }
}