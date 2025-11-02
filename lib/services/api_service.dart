// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/news_model.dart';

class ApiService {
  final http.Client client;

  ApiService({required this.client});

  // === TẢI TIN THẾ GIỚI ===
  Future<GNewsResponse> getTopHeadlines({
    String country = 'us',
    String category = 'general',
    int max = 20,
  }) async {
    try {
      final url = ApiEndpoints.topHeadlines(
        country: country,
        category: category,
        max: max,
      );

      final response = await client.get(Uri.parse(url)).timeout(
        Duration(milliseconds: ApiConfig.connectTimeout),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GNewsResponse.fromJson(jsonData);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load news: $e');
    }
  }

  // === TẢI TIN VIỆT NAM ===
  Future<GNewsResponse> getVietnamNews({int max = 20}) async {
    try {
      final url = ApiEndpoints.vietnamNews(max: max);
      final response = await client.get(Uri.parse(url)).timeout(
        Duration(milliseconds: ApiConfig.connectTimeout),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GNewsResponse.fromJson(jsonData);
      } else {
        throw Exception('Vietnam News Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load Vietnam news: $e');
    }
  }

  // === TÌM KIẾM (ĐÃ SỬA) ===
  Future<GNewsResponse> searchNews(String query, {int max = 20}) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = ApiEndpoints.searchNews(query: encodedQuery, max: max);

      final response = await client.get(Uri.parse(url)).timeout(
        Duration(milliseconds: ApiConfig.connectTimeout),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return GNewsResponse.fromJson(jsonData);
      } else if (response.statusCode == 400) {
        throw Exception('400: Từ khóa không hợp lệ hoặc quá ngắn');
      } else if (response.statusCode == 401) {
        throw Exception('401: API Key không hợp lệ');
      } else {
        throw Exception('Search Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search news: $e');
    }
  }
}