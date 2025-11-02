// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  // === ĐĂNG KÝ ===
  static Future<String?> register(String email, String password, String name) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'name': name,
          'email': email,
          'avatarUrl': 'assets/avatars/avatar1.png', // ← MẶC ĐỊNH AVATAR
          'darkMode': false, // ← MẶC ĐỊNH
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'Lỗi không xác định: $e';
    }
  }

  // === ĐĂNG NHẬP ===
  static Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'Lỗi kết nối';
    }
  }

  // === LỖI CHUNG ===
  static String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Tài khoản không tồn tại. Vui lòng đăng ký!';
      case 'wrong-password':
        return 'Mật khẩu không đúng. Vui lòng thử lại.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (ít nhất 6 ký tự).';
      case 'email-already-in-use':
        return 'Email đã được sử dụng.';
      default:
        return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }
  }

  // === QUÊN MẬT KHẨU ===
  static Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này.';
        case 'invalid-email':
          return 'Email không hợp lệ.';
        default:
          return 'Lỗi gửi email. Vui lòng thử lại.';
      }
    } catch (e) {
      return 'Lỗi kết nối. Vui lòng kiểm tra mạng.';
    }
  }

  // === ĐĂNG XUẤT ===
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // === LẤY THÔNG TIN USER (TÊN + AVATAR) ===
  static Future<Map<String, String>> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      return {
        'name': data['name'] ?? 'Người dùng',
        'avatarUrl': data['avatarUrl'] ?? 'assets/avatars/avatar1.png',
      };
    } catch (e) {
      print('Lỗi lấy thông tin user: $e');
      return {
        'name': 'Người dùng',
        'avatarUrl': 'assets/avatars/avatar1.png',
      };
    }
  }

  // === CẬP NHẬT AVATAR ===
  static Future<void> updateAvatar(String uid, String avatarUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'avatarUrl': avatarUrl,
      });
    } catch (e) {
      print('Lỗi cập nhật avatar: $e');
      rethrow;
    }
  }

  // === LẤY TÊN USER (Giữ lại cho tương thích cũ) ===
  static Future<String> getUserName(String uid) async {
    final profile = await getUserProfile(uid);
    return profile['name']!;
  }
}