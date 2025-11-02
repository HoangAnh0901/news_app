// screens/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:lottie/lottie.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';
import '../services/auth_service.dart';
import '../screens/profile/avatar_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearchVisible = false;
  bool _isSearching = false;
  late AnimationController _animationController;
  late Animation<double> _searchWidthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchWidthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _searchController.addListener(() {
      setState(() {
        _isSearching = _searchController.text.isNotEmpty;
      });
    });

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
        _hideSearchBar();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSearchBar() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
    if (_isSearchVisible) {
      _animationController.forward().then((_) {
        _searchFocusNode.requestFocus();
      });
    } else {
      _animationController.reverse();
      _searchController.clear();
      Provider.of<NewsProvider>(context, listen: false).clearSearch();
    }
  }

  void _hideSearchBar() {
    if (_isSearchVisible) {
      _toggleSearchBar();
    }
  }

  // Chỉ cần thay đoạn StreamBuilder trong build() của HomeScreen

// Chỉ cần thay toàn bộ build() của HomeScreen

@override
Widget build(BuildContext context) {
  final user = AuthService.currentUser;
  if (user == null) return const SizedBox();

  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
    builder: (context, snapshot) {
      final bool isDarkMode = snapshot.data?.get('darkMode') ?? false;

      // ÁP DỤNG THEME TOÀN APP
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
        child: Consumer<NewsProvider>(
          builder: (context, newsProv, child) {
            return Scaffold(
              appBar: _buildAppBar(context, newsProv, isDarkMode),
              drawer: _buildDrawer(context, newsProv, snapshot),
              body: Column(
                children: [
                  _buildInfoBar(newsProv),
                  Expanded(child: _buildBody(context, newsProv)),
                ],
              ),
              bottomNavigationBar: _buildBottomNav(newsProv),
              floatingActionButton: FloatingActionButton(
                onPressed: () => newsProv.refresh().then((_) => _refreshController.refreshCompleted()),
                child: const Icon(Icons.refresh),
                backgroundColor: const Color(0xFF1E3A8A),
              ),
            );
          },
        ),
      );
    },
  );
}

  PreferredSizeWidget _buildAppBar(BuildContext context, NewsProvider prov, bool isDark) {
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: _isSearchVisible
          ? AnimatedBuilder(
              animation: _searchWidthAnimation,
              builder: (context, child) {
                return SizeTransition(
                  sizeFactor: _searchWidthAnimation,
                  axis: Axis.horizontal,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (query) {
                        if (query.isEmpty) {
                          prov.clearSearch();
                        } else {
                          prov.searchNews(query);
                        }
                      },
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm...',
                        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
                        suffixIcon: _isSearching
                            ? AnimatedRotation(
                                turns: 0.25,
                                duration: const Duration(milliseconds: 200),
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    prov.clearSearch();
                                    setState(() => _isSearching = false);
                                  },
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              },
            )
          : Text(
              prov.searchQuery.isNotEmpty ? 'Kết quả: "${prov.searchQuery}"' : 'QuickNews',
              style: GoogleFonts.ptSans(
                textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
      centerTitle: true,
      backgroundColor: const Color(0xFF1E3A8A),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: _toggleSearchBar,
        ),
      ],
    );
  }

  // === DRAWER: CÓ QUỐC KỲ + DANH MỤC ===
  Widget _buildDrawer(BuildContext context, NewsProvider prov, AsyncSnapshot<DocumentSnapshot> snapshot) {
    final categories = {
      'general': 'Tổng hợp',
      'world': 'Thế giới',
      'business': 'Kinh doanh',
      'technology': 'Công nghệ',
      'entertainment': 'Giải trí',
      'sports': 'Thể thao',
      'science': 'Khoa học',
      'health': 'Sức khỏe',
    };

    final countries = {
      'us': 'Mỹ',
      'gb': 'Anh',
      'ca': 'Canada',
      'au': 'Úc',
      'in': 'Ấn Độ',
      'jp': 'Nhật Bản',
      'fr': 'Pháp',
      'de': 'Đức',
    };

    final countryFlags = {
      'us': 'United States',
      'gb': 'United Kingdom',
      'ca': 'Canada',
      'au': 'Australia',
      'in': 'India',
      'jp': 'Japan',
      'fr': 'France',
      'de': 'Germany',
    };

    final data = snapshot.data?.data() as Map<String, dynamic>?;
    final name = data?['name'] ?? 'Người dùng';
    final avatarUrl = data?['avatarUrl'] ?? 'assets/avatars/avatar1.png';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QuickNews', style: GoogleFonts.ptSans(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/avatar_picker'),
                      child: CircleAvatar(radius: 22, backgroundImage: _getImageProvider(avatarUrl)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const Text('Nhấn để đổi avatar', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // HỒ SƠ
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF1E3A8A)),
            title: const Text('Hồ sơ'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),

          // BÀI ĐÃ LƯU
          ListTile(
            leading: const Icon(Icons.bookmark, color: Colors.amber),
            title: const Text('Bài đã lưu'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/bookmarks');
            },
          ),

          const Divider(height: 1),

          // DANH MỤC
          ExpansionTile(
            leading: const Icon(Icons.category, color: Color(0xFF1E3A8A)),
            title: const Text('LĨNH VỰC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            children: categories.entries.map((e) => ListTile(
              dense: true,
              title: Text(e.value, style: const TextStyle(fontSize: 14)),
              trailing: prov.selectedCategory == e.key ? const Icon(Icons.check, size: 18) : null,
              onTap: () {
                prov.setCategory(e.key);
                Navigator.pop(context);
              },
            )).toList(),
          ),

          // QUỐC GIA
          ExpansionTile(
            leading: const Icon(Icons.public, color: Color(0xFF1E3A8A)),
            title: const Text('QUỐC GIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            children: countries.entries.map((e) => ListTile(
              dense: true,
              leading: Text(countryFlags[e.key] ?? '', style: const TextStyle(fontSize: 20)),
              title: Text(e.value, style: const TextStyle(fontSize: 14)),
              trailing: prov.selectedCountry == e.key ? const Icon(Icons.check, size: 18) : null,
              onTap: () {
                prov.setCountry(e.key);
                Navigator.pop(context);
              },
            )).toList(),
          ),

          const Divider(),

          // ĐĂNG XUẤT
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await AuthService.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),

          const Spacer(),

          // FOOTER
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('GNews API • v1.0', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar(NewsProvider prov) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF60A5FA),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              prov.currentSection == 'vietnam'
                  ? 'Tin tức về Việt Nam'
                  : '${prov.selectedCategory} • Quốc tế',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          if (prov.currentSection == 'world')
            Text(prov.selectedCountry.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, NewsProvider prov) {
    if (prov.isLoading) return _buildLoading();
    if (prov.errorMessage.isNotEmpty) return _buildError(prov);
    if (prov.articles.isEmpty) return _buildEmpty(prov);

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: () => prov.refresh().then((_) => _refreshController.refreshCompleted()),
      header: const WaterDropHeader(waterDropColor: Color(0xFF1E3A8A)),
      child: ListView.builder(
        itemCount: prov.articles.length,
        itemBuilder: (ctx, i) => NewsCard(article: prov.articles[i]),
      ),
    );
  }

  Widget _buildLoading() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/lottie/loading.json', height: 100),
            const SizedBox(height: 16),
            Text('Đang tải...', style: GoogleFonts.ptSans()),
          ],
        ),
      );

  Widget _buildError(NewsProvider prov) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Không tìm thấy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(prov.errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: prov.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      );

  Widget _buildEmpty(NewsProvider prov) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.article, size: 64, color: Color(0xFF1E3A8A)),
            const Text('Không có tin tức'),
            ElevatedButton(onPressed: prov.refresh, child: const Text('Tải lại')),
          ],
        ),
      );

  Widget _buildBottomNav(NewsProvider prov) => BottomNavigationBar(
        currentIndex: prov.currentSection == 'vietnam' ? 1 : 0,
        onTap: (i) => prov.setSection(i == 0 ? 'world' : 'vietnam'),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Thế Giới'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Việt Nam'),
        ],
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
      );

  ImageProvider _getImageProvider(String url) {
    return url.startsWith('assets/') ? AssetImage(url) : NetworkImage(url);
  }
}