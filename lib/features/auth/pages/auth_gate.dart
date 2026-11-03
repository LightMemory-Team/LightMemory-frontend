import 'package:flutter/material.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/auth_headers.dart';
import '../../../core/services/token_storage.dart';
import '../services/auth_service.dart';
import 'identity_select_page.dart';
import 'welcome_page.dart';

/// App 啟動時的登入狀態檢查（啟動頁）
///
/// - 沒有 token：導去身分選擇頁，走登入／註冊流程
/// - 有 token：跟後端拿暱稱（GET /api/users/me/）→ 歡迎頁「歡迎回來，玉蘭！」
///   → 輕觸螢幕進首頁
/// - token 過期（後端回 401）：清掉 token，回身分選擇頁重新登入
/// - 其他錯誤（例如網路不穩）：不擋住使用者，歡迎頁照樣出現、只是不顯示名字
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
      _goToIdentitySelect();
      return;
    }

    String nickname = '';
    try {
      final me = await AuthService.getMe();
      nickname = (me['nickname'] ?? '').toString().trim();
    } catch (e) {
      debugPrint('[AuthGate] 取得暱稱失敗: $e');

      // token 過期或無效：清掉 token，請使用者重新登入
      final bool expired =
          e is NotLoggedInException || (e is ApiException && e.statusCode == 401);
      if (expired) {
        await TokenStorage.clear();
        if (!mounted) return;
        _goToIdentitySelect();
        return;
      }
      // 其他錯誤（網路不穩等）：不擋住，歡迎頁不顯示名字
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => WelcomePage(userName: nickname)),
    );
  }

  void _goToIdentitySelect() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const IdentitySelectPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 檢查 token、拿暱稱的時候先顯示轉圈圈
    return const Scaffold(
      backgroundColor: Color(0xFFF6F8F3),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF5B8A6B)),
      ),
    );
  }
}