// screens/profile/avatar_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvatarPickerScreen extends StatefulWidget {
  @override
  _AvatarPickerScreenState createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  String? _currentAvatarUrl;
  late User _user;

  // 10 avatar có sẵn trong assets
  final List<String> _predefinedAvatars = List.generate(
    10,
    (i) => 'assets/avatars/avatar${i + 1}.png',
  );

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _loadCurrentAvatar();
  }

  // LẤY AVATAR HIỆN TẠI TỪ FIRESTORE
  Future<void> _loadCurrentAvatar() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .get();
    final data = doc.data();
    if (mounted) {
      setState(() {
        _currentAvatarUrl = data?['avatarUrl'] ?? 'assets/avatars/avatar1.png';
      });
    }
  }

  // CHỌN AVATAR → CẬP NHẬT FIRESTORE
  Future<void> _selectAvatar(String assetPath) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .update({'avatarUrl': assetPath});

    if (mounted) {
      setState(() {
        _currentAvatarUrl = assetPath;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã chọn avatar!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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
                    titleLarge: TextStyle(color: Colors.white),
                  ),
                )
              : ThemeData.light().copyWith(
                  primaryColor: const Color(0xFF1E3A8A),
                  scaffoldBackgroundColor: Colors.white,
                  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E3A8A)),
                  cardColor: Colors.white,
                  textTheme: const TextTheme(
                    bodyMedium: TextStyle(color: Colors.black87),
                    titleLarge: TextStyle(color: Colors.black87),
                  ),
                ),
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Chọn Avatar',
                style: GoogleFonts.ptSans(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // AVATAR HIỆN TẠI
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage: _getImageProvider(_currentAvatarUrl),
                        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // TIÊU ĐỀ
                  Text(
                    'Chọn avatar có sẵn',
                    style: GoogleFonts.ptSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GRID 10 AVATAR
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: _predefinedAvatars.length,
                      itemBuilder: (ctx, i) {
                        final avatarPath = _predefinedAvatars[i];
                        final isSelected = _currentAvatarUrl == avatarPath;

                        return GestureDetector(
                          onTap: () => _selectAvatar(avatarPath),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
                                width: isSelected ? 4 : 0,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF1E3A8A).withOpacity(isDarkMode ? 0.4 : 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                avatarPath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                  child: const Icon(Icons.person, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // XỬ LÝ ẢNH
  ImageProvider _getImageProvider(String? url) {
    if (url == null || !url.startsWith('assets/')) {
      return const AssetImage('assets/avatars/avatar1.png');
    }
    return AssetImage(url);
  }
}