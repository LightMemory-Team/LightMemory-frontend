import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/error_message.dart';
import 'reset_password_page.dart';

/// 忘記密碼第 1 頁：輸入帳號（依小惠〈首頁改版 API 規格書〉）
///
/// - 有輸入帳號才能按「送出」
/// - 帳號存在 → 帶著帳號跳到第 2 頁（不用再輸入一次）
/// - 第 2 頁改好密碼回傳 true → 這頁也關掉，一起回到登入頁
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const Color _green = Color(0xFF5B8A6B);
  static const Color _bg = Color(0xFFF6F8F3);

  /// 欄位錯誤的顏色：不用紅色，避免長輩緊張
  static const Color _errorColor = Color(0xFFB45309);

  final _usernameController = TextEditingController();

  bool _isSubmitting = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    // 輸入時重畫（讓「送出」即時變成可按），並清掉錯誤訊息
    _usernameController.addListener(() {
      setState(() => _usernameError = null);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _usernameController.text.trim().isNotEmpty;

  Future<void> _handleSubmit() async {
    if (!_canSubmit || _isSubmitting) return;
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();

    setState(() {
      _isSubmitting = true;
      _usernameError = null;
    });

    try {
      await AuthService.checkPasswordResetAccount(username);
    } catch (e) {
      debugPrint('[ForgotPasswordPage] 確認帳號失敗: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // 找不到帳號、或後端說帳號欄位有問題：顯示在帳號下方
      if (e is ApiException &&
          (e.code == 'ACCOUNT_NOT_FOUND' || e.statusCode == 404 || e.code == 'VALIDATION_ERROR')) {
        setState(() => _usernameError = e.message);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(e, fallback: '確認帳號失敗，請稍後再試一次'))),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // 帳號存在：帶著帳號跳到第 2 頁
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => ResetPasswordPage(username: username)),
    );

    // 第 2 頁改好密碼：這頁也關掉，回到登入頁
    if (updated == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        // 左上角用文字「返回」（跟註冊頁一樣），回到登入頁
        leadingWidth: 88,
        leading: TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: _green),
          child: const Text(
            '返回',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Image.asset('assets/images/logo.png', width: 90, height: 90),
              const SizedBox(height: 12),
              const Text(
                '憶智防線',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D6B4A),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '忘記密碼',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // 帳號
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '帳號',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleSubmit(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  hintText: '請輸入您的帳號',
                  filled: true,
                  fillColor: Colors.white,
                  errorText: _usernameError,
                  errorStyle: const TextStyle(color: _errorColor, fontSize: 14),
                  errorMaxLines: 2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _errorColor, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _errorColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 送出
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: const Color(0xFFC9D6CC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: (!_canSubmit || _isSubmitting) ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          '送出',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}