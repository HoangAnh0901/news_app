import '../services/api_service.dart';
import '../models/news_model.dart';

class NewsRepository {
  final ApiService apiService;

  NewsRepository({required this.apiService});

  Future<GNewsResponse> getTopHeadlines({
    String country = 'us',
    String category = 'general',
    int max = 20,
  }) async {
    return await apiService.getTopHeadlines(
      country: country,
      category: category,
      max: max,
    );
  }

  Future<GNewsResponse> getVietnamNews({int max = 20}) async {
    return await apiService.getVietnamNews(max: max);
  }

  Future<GNewsResponse> searchNews(String query) async {
    return await apiService.searchNews(query);
  }

  Future<GNewsResponse> getNewsByCategory(String category) async {
    return await getTopHeadlines(category: category);
  }

  Future<GNewsResponse> getNewsByCountry(String country) async {
    return await getTopHeadlines(country: country);
  }
}