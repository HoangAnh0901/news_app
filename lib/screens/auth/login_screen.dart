// screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    final errorMsg = await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text);
    setState(() => _isLoading = false);

    if (errorMsg == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      setState(() => _error = errorMsg);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email hợp lệ để khôi phục')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    final result = await AuthService.resetPassword(email);
    setState(() => _isLoading = false);

    if (result == null) {
      setState(() => _successMessage = 'Đã gửi link khôi phục đến $email');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kiểm tra email để đặt lại mật khẩu!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _error = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // CỐ ĐỊNH MÀU TRẮNG – KHÔNG DÙNG Theme.of(context)
    return Scaffold(
      backgroundColor: Colors.white, // CỐ ĐỊNH MÀU NỀN
      appBar: AppBar(
        title: Text('Đăng nhập', style: GoogleFonts.ptSans(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 80, color: const Color(0xFF1E3A8A)),
              const SizedBox(height: 24),
              Text(
                'Chào mừng đến với QuickNews!',
                style: GoogleFonts.ptSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF1E3A8A)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                  ),
                ),
                validator: (v) => v!.contains('@') ? null : 'Email không hợp lệ',
              ),
              const SizedBox(height: 16),

              // MẬT KHẨU
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF1E3A8A)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (v) => v!.length >= 6 ? null : 'Mật khẩu ít nhất 6 ký tự',
              ),
              const SizedBox(height: 12),

              // THÀNH CÔNG / LỖI
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_successMessage!, style: TextStyle(color: Colors.green.shade700))),
                    ],
                  ),
                ),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700))),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // NÚT ĐĂNG NHẬP
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: Text(
                  'Quên mật khẩu?',
                  style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),
                child: Text(
                  'Chưa có tài khoản? Đăng ký ngay',
                  style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}