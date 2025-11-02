// models/news_model.dart
class NewsArticle {
  final String title;
  final String description;
  final String content; // Nội dung ngắn từ API
  final String url;
  final String image;
  final DateTime publishedAt;
  final Source source;
  String? fullContent; // Nội dung đầy đủ (sau khi scrape)

  NewsArticle({
    required this.title,
    required this.description,
    required this.content,
    required this.url,
    required this.image,
    required this.publishedAt,
    required this.source,
    this.fullContent,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No Description',
      content: json['content'] ?? 'No Content',
      url: json['url'] ?? '',
      image: _getImageUrl(json),
      publishedAt: DateTime.parse(json['publishedAt'] ?? DateTime.now().toIso8601String()),
      source: Source.fromJson(json['source'] ?? {}),
      fullContent: null,
    );
  }

  static String _getImageUrl(Map<String, dynamic> json) {
    if (json['image'] != null && json['image'].toString().isNotEmpty) {
      return json['image'];
    }
    if (json['urlToImage'] != null && json['urlToImage'].toString().isNotEmpty) {
      return json['urlToImage'];
    }
    final content = json['content'] ?? '';
    final description = json['description'] ?? '';
    final imageUrl = _extractImageFromText(content + description);
    return imageUrl.isNotEmpty ? imageUrl : '';
  }

  static String _extractImageFromText(String text) {
    try {
      final regex = RegExp(r'(http(s?):)([/|.|\w|\s|-])*\.(?:jpg|jpeg|gif|png|webp)');
      final match = regex.firstMatch(text);
      return match?.group(0) ?? '';
    } catch (e) {
      print('Error extracting image: $e');
      return '';
    }
  }
}

class Source {
  final String id;
  final String name;
  final String url;

  Source({
    required this.id,
    required this.name,
    required this.url,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Source',
      url: json['url'] ?? '',
    );
  }
}

class GNewsResponse {
  final int totalArticles;
  final List<NewsArticle> articles;

  GNewsResponse({
    required this.totalArticles,
    required this.articles,
  });

  factory GNewsResponse.fromJson(Map<String, dynamic> json) {
    return GNewsResponse(
      totalArticles: json['totalArticles'] ?? 0,
      articles: (json['articles'] as List? ?? [])
          .map((e) => NewsArticle.fromJson(e))
          .toList(),
    );
  }
}