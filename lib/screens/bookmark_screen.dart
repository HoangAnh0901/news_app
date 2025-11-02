// screens/bookmark_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Source;
import 'package:intl/intl.dart';
import '../models/news_model.dart';
import '../screens/article_detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  // === MÃ HÓA URL ĐỂ LÀM ID ===
  String _encodeUrl(String url) {
    return url
        .replaceAll(RegExp(r'[.#\[\]$/]'), '_')
        .replaceAll(RegExp(r'//+'), '/')
        .replaceAll(RegExp(r'^https?:\/\/'), '');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bài đã lưu'),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
        ),
       
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, userSnapshot) {
        final bool isDarkMode = userSnapshot.data?.get('darkMode') ?? false;

        return Theme(
          data: isDarkMode
              ? ThemeData.dark().copyWith(
                  primaryColor: const Color(0xFF1E3A8A),
                  scaffoldBackgroundColor: const Color(0xFF121212),
                  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E3A8A)),
                )
              : ThemeData.light().copyWith(
                  primaryColor: const Color(0xFF1E3A8A),
                  scaffoldBackgroundColor: Colors.white,
                  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E3A8A)),
                ),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Bài đã lưu'),
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('bookmarks')
                  .orderBy('savedAt', descending: true)
                  .snapshots(),
              builder: (context, bookmarkSnapshot) {
                if (bookmarkSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)));
                }
                if (!bookmarkSnapshot.hasData || bookmarkSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có bài nào được lưu',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final docs = bookmarkSnapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final article = NewsArticle(
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
                    final encodedId = _encodeUrl(article.url);
                    return _buildBookmarkItem(context, article, encodedId, user.uid);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookmarkItem(BuildContext context, NewsArticle article, String encodedId, String uid) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: article.image.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  article.image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.article, color: Colors.grey),
              ),
        title: Text(
          article.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${article.source.name} • ${DateFormat('dd/MM HH:mm').format(article.publishedAt)}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            final confirmed = await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Xóa bài đã lưu?'),
                content: const Text('Bài viết sẽ bị xóa khỏi danh sách.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('bookmarks')
                  .doc(encodedId)
                  .delete();
            }
          },
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
        ),
      ),
    );
  }
}