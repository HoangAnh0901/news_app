class ApiConfig {
  static const String gNewsApiKey = 'aa79159ff10287bed0346a13414d95d5'; // Thay bằng API key của bạn
  static const String gNewsBaseUrl = 'https://gnews.io/api/v4';
  
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}

class ApiEndpoints {
  static String topHeadlines({
    String country = 'us',
    String category = 'general',
    int max = 20,
  }) {
    return '${ApiConfig.gNewsBaseUrl}/top-headlines?category=$category&country=$country&max=$max&lang=en&apikey=${ApiConfig.gNewsApiKey}';
  }
  
  static String searchNews({
    required String query,
    int max = 20,
  }) {
    return '${ApiConfig.gNewsBaseUrl}/search?q=$query&max=$max&lang=en&apikey=${ApiConfig.gNewsApiKey}';
  }
  
  static String vietnamNews({int max = 20}) {
    return '${ApiConfig.gNewsBaseUrl}/search?q=Vietnam&max=$max&lang=en&apikey=${ApiConfig.gNewsApiKey}';
  }
}