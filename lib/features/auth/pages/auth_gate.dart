import 'package:flutter/material.dart';
import '../../../core/services/token_storage.dart';
import 'identity_select_page.dart';
import '../../../screens/main_screen.dart';

/// App 啟動時的登入狀態檢查：
/// 有 access token 就直接進主畫面，沒有（或還沒檢查完）就先顯示 loading，
/// 檢查完發現沒 token 就導去身分選擇頁，讓使用者走登入／註冊流程。
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    final token = await TokenStorage.getAccessToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const IdentitySelectPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 檢查 token 只需要幾毫秒，這裡只是避免畫面閃一下空白
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}