// providers/news_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../repositories/news_repository.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;

class NewsProvider with ChangeNotifier {
  final NewsRepository _repository = NewsRepository(
    apiService: ApiService(client: http.Client()),
  );

  // Trạng thái
  List<NewsArticle> _articles = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedCategory = 'general';
  String _selectedCountry = 'us';
  String _currentSection = 'world';
  String _searchQuery = '';

  // DEBOUNCE
  Timer? _debounce;

  // Getters
  List<NewsArticle> get articles => _articles;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get selectedCountry => _selectedCountry;
  String get currentSection => _currentSection;
  String get searchQuery => _searchQuery;

  // === TÌM KIẾM (ĐÃ SỬA) ===
  Future<void> searchNews(String query) async {
    final trimmedQuery = query.trim();

    // Xóa tìm kiếm nếu rỗng
    if (trimmedQuery.isEmpty) {
      clearSearch();
      return;
    }

    // DEBOUNCE 500ms
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      _searchQuery = trimmedQuery;
      _setLoading(true);
      _clearError();

      try {
        // KIỂM TRA ĐỘ DÀI TỪ KHÓA
        if (_searchQuery.length < 2) {
          _setError('Từ khóa quá ngắn. Vui lòng nhập ít nhất 2 ký tự.');
          return;
        }

        final response = await _repository.searchNews(_searchQuery);
        if (response.articles.isEmpty) {
          _setError('Không tìm thấy tin tức cho "$_searchQuery"');
        } else {
          _articles = response.articles;
        }
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('400')) {
          _setError('Từ khóa không hợp lệ. Vui lòng thử lại.');
        } else if (msg.contains('401')) {
          _setError('Lỗi API Key. Vui lòng kiểm tra lại.');
        } else {
          _setError('Lỗi kết nối. Vui lòng kiểm tra mạng.');
        }
      } finally {
        _setLoading(false);
      }
    });
  }

  // === XÓA TÌM KIẾM ===
  void clearSearch() {
    _searchQuery = '';
    _debounce?.cancel();
    notifyListeners();
    _refresh(); // Quay lại danh sách mặc định
  }

  // === TẢI TIN THẾ GIỚI ===
  Future<void> loadWorldNews() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _repository.getTopHeadlines(
        country: _selectedCountry,
        category: _selectedCategory,
        max: 20,
      );
      _articles = response.articles;
    } catch (e) {
      _setError('Không thể tải tin thế giới: $e');
    } finally {
      _setLoading(false);
    }
  }

  // === TẢI TIN VIỆT NAM ===
  Future<void> loadVietnamNews() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _repository.getVietnamNews(max: 20);
      _articles = response.articles;
    } catch (e) {
      _setError('Không thể tải tin Việt Nam: $e');
    } finally {
      _setLoading(false);
    }
  }

  // === THAY ĐỔI DANH MỤC ===
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
    if (_currentSection == 'world') loadWorldNews();
  }

  // === THAY ĐỔI QUỐC GIA ===
  void setCountry(String country) {
    _selectedCountry = country;
    notifyListeners();
    if (_currentSection == 'world') loadWorldNews();
  }

  // === THAY ĐỔI TAB (THẾ GIỚI / VIỆT NAM) ===
  void setSection(String section) {
    _currentSection = section;
    notifyListeners();
    _refresh();
  }

  // === LÀM MỚI ===
  Future<void> _refresh() async {
    if (_currentSection == 'vietnam') {
      await loadVietnamNews();
    } else {
      await loadWorldNews();
    }
  }

  Future<void> refresh() async {
    await _refresh();
  }

  // === HELPER ===
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}