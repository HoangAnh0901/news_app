// widgets/news_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/news_model.dart';
import '../utils/image_utils.dart';
import '../screens/article_detail_screen.dart';

class NewsCard extends StatelessWidget {
  final NewsArticle article;
  final double elevation;

  const NewsCard({
    Key? key,
    required this.article,
    this.elevation = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final sourceColor = isDark ? Colors.cyanAccent : Colors.blue;
    final placeholderBg = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final placeholderIconColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
    final placeholderTextColor = isDark ? Colors.grey[500]! : Colors.grey[500]!;

    final hasValidImage = ImageUtils.isValidImageUrl(article.image);

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: InkWell(
        onTap: () => _openDetailScreen(context),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === HÌNH ẢNH ===
            Container(
              height: 200,
              width: double.infinity,
              child: hasValidImage
                  ? _buildArticleImage()
                  : _buildImagePlaceholder(placeholderBg, placeholderIconColor, placeholderTextColor),
            ),

            // === NỘI DUNG ===
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nguồn + Thời gian
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          article.source.name,
                          style: TextStyle(
                            color: sourceColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy - HH:mm').format(article.publishedAt),
                        style: TextStyle(color: subtitleColor, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tiêu đề
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: textColor,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Mô tả
                  if (_hasValidDescription(article.description))
                    Text(
                      _cleanDescription(article.description),
                      style: TextStyle(
                        fontSize: 14,
                        color: subtitleColor,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),

                  // === NÚT ĐỌC + BOOKMARK ===
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openDetailScreen(context),
                          icon: const Icon(Icons.article_outlined, size: 16),
                          label: const Text('Đọc chi tiết'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // === ICON BOOKMARK (REALTIME) ===
                      StreamBuilder<DocumentSnapshot?>(
                        stream: _bookmarkStream(),
                        builder: (context, snapshot) {
                          final doc = snapshot.data;
                          final isBookmarked = doc != null && doc.exists;
                          final isLoading = snapshot.connectionState == ConnectionState.waiting;

                          return IconButton(
                            onPressed: isLoading ? null : () => _toggleBookmark(context),
                            icon: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(
                                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                    color: isBookmarked
                                        ? Colors.amber
                                        : (isDark ? Colors.white70 : Colors.grey),
                                    size: 28,
                                  ),
                            tooltip: isBookmarked ? 'Bỏ lưu' : 'Lưu bài',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === HÌNH ẢNH ===
  Widget _buildArticleImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: CachedNetworkImage(
        imageUrl: article.image,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildImagePlaceholder(
          Colors.grey[300]!,
          Colors.grey[400]!,
          Colors.grey[500]!,
        ),
        errorWidget: (context, url, error) => _buildImagePlaceholder(
          Colors.grey[300]!,
          Colors.grey[400]!,
          Colors.grey[500]!,
        ),
        fadeInDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildImagePlaceholder(Color bgColor, Color iconColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article, size: 50, color: iconColor),
            const SizedBox(height: 8),
            Text(
              article.source.name,
              style: TextStyle(color: textColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // === KIỂM TRA MÔ TẢ ===
  bool _hasValidDescription(String? description) {
    return description != null &&
        description.isNotEmpty &&
        description != 'No Description' &&
        description.length > 20;
  }

  String _cleanDescription(String? description) {
    if (description == null) return '';
    return description
        .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // === MỞ CHI TIẾT TRONG APP ===
  void _openDetailScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ArticleDetailScreen(article: article),
      ),
    );
  }

  // === MÃ HÓA URL THÀNH ID HỢP LỆ ===
  String _encodeUrl(String url) {
    return url
        .replaceAll(RegExp(r'[.#\[\]$/]'), '_')  // Thay ký tự cấm
        .replaceAll(RegExp(r'//+'), '/');        // Gộp //
  }

  // === REALTIME BOOKMARK STREAM ===
  Stream<DocumentSnapshot?> _bookmarkStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .doc(_encodeUrl(article.url))  // ĐÃ SỬA
        .snapshots();
  }

  // === LƯU / BỎ LƯU ===
  Future<void> _toggleBookmark(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để lưu bài!')),
      );
      return;
    }

    final encodedId = _encodeUrl(article.url);  // ĐÃ SỬA
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bookmarks')
        .doc(encodedId);  // ĐÃ SỬA

    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bỏ lưu bài'), backgroundColor: Colors.red),
      );
    } else {
      await ref.set({
        'title': article.title,
        'description': article.description,
        'content': article.content,
        'url': article.url,  // Lưu URL gốc
        'image': article.image,
        'source': article.source.name,
        'sourceId': article.source.id,
        'publishedAt': Timestamp.fromDate(article.publishedAt),
        'savedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu bài!'), backgroundColor: Colors.green),
      );
    }
  }
}