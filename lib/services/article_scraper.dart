// services/article_scraper.dart
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class ArticleScraper {
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
    'Connection': 'keep-alive',
  };

  static Future<ScrapeResult> scrapeFullContent(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(Duration(seconds: 12));

      if (response.statusCode != 200) {
        return ScrapeResult(success: false, error: 'Mã lỗi: ${response.statusCode}');
      }

      final document = parser.parse(response.body);
      document.querySelectorAll('script, style, .ad, iframe, .advertisement')
          .forEach((e) => e.remove());

      String fullContent = '';

      final selectors = [
        'article',
        '.entry-content', '.post-content', '.article-body',
        '.story-body', '.content', '.RichTextArticleBody',
        '[data-module="ArticleContent"]', '.article__content'
      ];

      for (String sel in selectors) {
        final el = document.querySelector(sel);
        if (el != null) {
          fullContent = el.innerHtml;
          break;
        }
      }

      if (fullContent.isEmpty) {
        final main = document.querySelector('main') ?? document.body;
        if (main != null) {
          fullContent = main.querySelectorAll('p')
              .map((p) => '<p>${p.innerHtml}</p>')
              .join('<br><br>');
        }
      }

      fullContent = _cleanHtml(fullContent);

      final isValid = fullContent.isNotEmpty && fullContent.length > 150;
      return ScrapeResult(
        success: isValid,
        content: isValid ? fullContent : '',
        error: isValid ? null : 'Nội dung không đủ',
      );
    } on SocketException {
      return ScrapeResult(success: false, error: 'Không có mạng');
    } on http.ClientException catch (e) {
      return ScrapeResult(success: false, error: 'Lỗi tải: $e');
    } on TimeoutException {
      return ScrapeResult(success: false, error: 'Tải quá chậm');
    } catch (e) {
      return ScrapeResult(success: false, error: 'Lỗi: $e');
    }
  }

  static String _cleanHtml(String html) {
    final doc = parser.parse(html);
    doc.querySelectorAll('.related, .comments, nav, footer, .share, .social')
        .forEach((e) => e.remove());
    return doc.body?.innerHtml ?? html;
  }

  static String? getMainImage(String htmlContent) {
    final doc = parser.parse(htmlContent);
    return doc.querySelector('meta[property="og:image"]')?.attributes['content']
        ?? doc.querySelector('meta[name="twitter:image"]')?.attributes['content'];
  }
}

class ScrapeResult {
  final bool success;
  final String content;
  final String? error;

  ScrapeResult({required this.success, this.content = '', this.error});
}