class ImageUtils {
  static const Map<String, String> categoryPlaceholders = {
    'general': 'https://images.unsplash.com/photo-1586339949216-35c2747cc36d?w=400&h=200&fit=crop',
    'technology': 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400&h=200&fit=crop',
    'sports': 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=400&h=200&fit=crop',
    'business': 'https://images.unsplash.com/photo-1664575198263-269a022d6f14?w=400&h=200&fit=crop',
    'entertainment': 'https://images.unsplash.com/photo-1489599809505-fb40ebc14d59?w=400&h=200&fit=crop',
    'health': 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400&h=200&fit=crop',
    'science': 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=400&h=200&fit=crop',
    'world': 'https://images.unsplash.com/photo-1487088678257-3a541e6e3922?w=400&h=200&fit=crop',
  };

  static String getPlaceholderImage(String category) {
    return categoryPlaceholders[category.toLowerCase()] ?? categoryPlaceholders['general']!;
  }

  static bool isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final hasImageExtension = imageExtensions.any((ext) => 
        url.toLowerCase().contains(ext));
    
    final imageDomains = [
      'images.unsplash.com',
      'media.npr.org',
      'static01.nyt.com',
      'abcnews.go.com',
      'cdn.cnn.com',
      'reuters.com',
      'bloximages.newyork1.vip.townnews.com',
    ];
    
    final hasImageDomain = imageDomains.any((domain) => 
        url.toLowerCase().contains(domain));
    
    return hasImageExtension || hasImageDomain;
  }
}