import 'package:flutter/material.dart';
import 'register_page.dart';
import 'welcome_page.dart';
import '../services/auth_service.dart';
import '../../../core/services/token_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入帳號與密碼')),
      );
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      final result = await AuthService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      // 之前這裡完全沒有存token，這是補上的部分
      final accessToken = result['access'] as String?;
      if (accessToken != null) {
        await TokenStorage.saveAccessToken(accessToken);
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WelcomePage(userName: _usernameController.text.trim()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset(
                'assets/images/logo.png',
                width: 90,
                height: 90,
              ),
              const SizedBox(height: 12),
              const Text(
                '憶智防線',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D6B4A),
                ),
              ),
              const SizedBox(height: 32),

              // 帳號欄位
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('帳號', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  hintText: '請輸入您的帳號',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 密碼欄位
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('密碼', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  hintText: '請輸入您的密碼',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 登入按鈕
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B8A6B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _isLoggingIn ? null : _handleLogin,
                  child: _isLoggingIn
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          '登入',
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // 註冊連結
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                    children: [
                      TextSpan(text: '還沒有帳號？'),
                      TextSpan(
                        text: '立即註冊',
                        style: TextStyle(
                          color: Color(0xFF5B8A6B),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}