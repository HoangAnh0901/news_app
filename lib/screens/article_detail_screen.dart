// screens/article_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/news_model.dart';
import '../services/article_scraper.dart';
import '../utils/image_utils.dart';

class ArticleDetailScreen extends StatefulWidget {
  final NewsArticle article;
  const ArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  _ArticleDetailScreenState createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _isLoading = true;
  String _fullContent = '';
  String? _mainImage;
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);

    final result = await ArticleScraper.scrapeFullContent(widget.article.url);

    if (result.success) {
      setState(() {
        _fullContent = result.content;
        _mainImage = ArticleScraper.getMainImage(result.content) ?? widget.article.image;
        _isLoading = false;
      });
    } else {
      _autoOpenWeb(result.error ?? 'Không thể tải nội dung');
    }
  }

  void _autoOpenWeb(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      _launchURL(widget.article.url);
    });

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_user.uid).snapshots(),
      builder: (context, snapshot) {
        final bool isDarkMode = snapshot.data?.get('darkMode') ?? false;

        return Theme(
          data: isDarkMode
              ? ThemeData.dark().copyWith(
                  primaryColor: const Color(0xFF1E3A8A),
                  scaffoldBackgroundColor: const Color(0xFF121212),
                  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E3A8A)),
                  cardColor: const Color(0xFF1E1E1E),
                  textTheme: const TextTheme(
                    bodyMedium: TextStyle(color: Colors.white70),
                  ),
                )
              : ThemeData.light().copyWith(
                  primaryColor: const Color(0xFF1E3A8A),
                  scaffoldBackgroundColor: Colors.white,
                  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E3A8A)),
                  cardColor: Colors.white,
                  textTheme: const TextTheme(
                    bodyMedium: TextStyle(color: Colors.black87),
                  ),
                ),
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF1E3A8A),
              title: Text(
                'Bài báo',
                style: GoogleFonts.ptSans(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadContent,
                ),
              ],
            ),
            body: _isLoading
                ? _buildLoading(isDarkMode)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDarkMode),
                        const SizedBox(height: 16),
                        if (_mainImage != null && ImageUtils.isValidImageUrl(_mainImage!))
                          _buildImage(isDarkMode),
                        const SizedBox(height: 20),
                        if (_fullContent.isNotEmpty) _buildContent(isDarkMode),
                        const SizedBox(height: 20),
                        _buildActionButtons(isDarkMode),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.article.title,
          style: GoogleFonts.ptSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.source, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.article.source.name,
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              DateFormat('dd/MM HH:mm').format(widget.article.publishedAt),
              style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImage(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: _mainImage!,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: 250,
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 250,
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          child: Center(child: Icon(Icons.broken_image, size: 50, color: isDark ? Colors.white70 : Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Html(
      data: _fullContent,
      style: {
        "body": Style(
          fontSize: FontSize(16),
          lineHeight: LineHeight.number(1.6),
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        "p": Style(margin: Margins.symmetric(vertical: 12)),
        "h1,h2,h3": Style(fontSize: FontSize.larger, color: isDark ? Colors.white : Colors.black87),
        "img": Style(width: Width(100, Unit.percent), margin: Margins.symmetric(vertical: 12)),
        "a": Style(color: Colors.blue),
      },
      onLinkTap: (url, _, __) => _launchURL(url ?? ''),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Share.share('${widget.article.title}\n\n${widget.article.url}'),
            icon: const Icon(Icons.share, color: Colors.white),
            label: const Text('Chia sẻ', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _launchURL(widget.article.url),
            icon: const Icon(Icons.open_in_browser, color: Colors.white),
            label: const Text('Web gốc', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF1E3A8A)),
            const SizedBox(height: 16),
            Text(
              'Đang tải nội dung...',
              style: GoogleFonts.ptSans(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}