// screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import 'edit_name_dialog.dart';
import 'change_password_dialog.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Người dùng';
        final avatarUrl = data['avatarUrl'] ?? 'assets/avatars/avatar1.png';
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final favoriteCategory = data['favoriteCategory'] ?? 'Chưa có';
        final bool isDarkMode = data['darkMode'] ?? false;

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
          child: Scaffold(
            appBar: AppBar(
              title: Text('Hồ sơ', style: GoogleFonts.ptSans(fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // === AVATAR + TÊN ===
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/avatar_picker'),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _getImageProvider(avatarUrl),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: GoogleFonts.ptSans(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => _showEditNameDialog(context, name),
                        child: const Text('Sửa tên', style: TextStyle(color: Colors.blue)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),

                // === THÔNG TIN ===
                _buildInfoRow(Icons.email, 'Email', _user.email!),
                _buildInfoRow(Icons.calendar_today, 'Tham gia', DateFormat('dd/MM/yyyy').format(createdAt)),
                _buildBookmarkCount(), // Real-time
                _buildInfoRow(Icons.star, 'Chủ đề yêu thích', _formatCategory(favoriteCategory)),

                const SizedBox(height: 24),
                const Divider(),

                // === CÀI ĐẶT ===
                _buildSwitchTile(
                  icon: Icons.dark_mode,
                  title: 'Chế độ tối',
                  value: isDarkMode,
                  onChanged: (val) => _updateSetting('darkMode', val),
                ),

                _buildActionTile(Icons.lock, 'Đổi mật khẩu', () => _showChangePasswordDialog(context)),

                const SizedBox(height: 24),
                const Divider(),

                // === HÀNH ĐỘNG ===
                _buildActionTile(Icons.logout, 'Đăng xuất', _logout, color: Colors.orange),
                _buildActionTile(Icons.delete_forever, 'Xóa tài khoản', _deleteAccount, color: Colors.red),
              ],
            ),
          ),
        );
      },
    );
  }

  // === SỐ BÀI ĐÃ LƯU REAL-TIME ===
  Widget _buildBookmarkCount() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .collection('bookmarks')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return _buildInfoRow(Icons.bookmark, 'Bài đã lưu', '$count bài');
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: const Color(0xFF1E3A8A)),
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF1E3A8A),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF1E3A8A)),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('assets/')) return AssetImage(url);
    return NetworkImage(url);
  }

  String _formatCategory(String cat) {
    final map = {
      'general': 'Tổng hợp',
      'business': 'Kinh doanh',
      'technology': 'Công nghệ',
      'entertainment': 'Giải trí',
      'sports': 'Thể thao',
      'science': 'Khoa học',
      'health': 'Sức khỏe',
    };
    return map[cat] ?? cat;
  }

  void _updateSetting(String field, dynamic value) {
    FirebaseFirestore.instance.collection('users').doc(_user.uid).update({field: value});
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    showDialog(
      context: context,
      builder: (_) => EditNameDialog(currentName: currentName),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangePasswordDialog(),
    );
  }

  Future<void> _logout() async {
    final confirm = await _showConfirmDialog('Đăng xuất', 'Bạn có chắc muốn đăng xuất?');
    if (confirm) {
      await AuthService.logout();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await _showConfirmDialog(
      'Xóa tài khoản',
      'Hành động này không thể khôi phục. Toàn bộ dữ liệu sẽ bị xóa!',
      confirmText: 'Xóa vĩnh viễn',
    );
    if (confirm) {
      final batch = FirebaseFirestore.instance.batch();
      final bookmarks = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .collection('bookmarks')
          .get();
      for (var doc in bookmarks.docs) batch.delete(doc.reference);
      batch.delete(FirebaseFirestore.instance.collection('users').doc(_user.uid));
      await batch.commit();

      await _user.delete();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<bool> _showConfirmDialog(String title, String content, {String confirmText = 'Xác nhận'}) async {
    return await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }
}