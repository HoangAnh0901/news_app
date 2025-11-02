// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/news_provider.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/bookmark_screen.dart';
import 'screens/profile/avatar_picker_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NewsProvider()),
      ],
      child: // main.dart (chỉ cần đoạn MaterialApp)
MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.light().copyWith(
    primaryColor: const Color(0xFF1E3A8A),
    scaffoldBackgroundColor: Colors.white,
  ),
  darkTheme: ThemeData.dark().copyWith(
    primaryColor: const Color(0xFF1E3A8A),
    scaffoldBackgroundColor: const Color(0xFF121212),
  ),
  themeMode: ThemeMode.system, // Sẽ bị override bởi Firestore
  initialRoute: '/',
  routes: {
    '/': (context) => const AuthWrapper(),
    '/home': (context) => const HomeScreen(),
    '/login': (context) => LoginScreen(),
    '/profile': (context) => ProfileScreen(),
    '/bookmarks': (context) => BookmarksScreen(),
    '/avatar_picker': (context) => AvatarPickerScreen(),
  },
)
    );
  }
}

// === KIỂM TRA ĐĂNG NHẬP ===
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
          );
        }

        if (snapshot.hasData) {
          // TẢI TIN TỨC KHI ĐĂNG NHẬP
          Future.microtask(() {
            final newsProv = Provider.of<NewsProvider>(context, listen: false);
            newsProv.refresh();
          });
          return const HomeScreen();
        }

        return LoginScreen();
      },
    );
  }
}