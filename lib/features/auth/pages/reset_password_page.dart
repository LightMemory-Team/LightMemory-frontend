import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/error_message.dart';

/// 忘記密碼第 2 頁：設定新密碼（依小惠〈首頁改版 API 規格書〉）
///
/// - 帳號由第 1 頁帶過來，不用再輸入一次
/// - 新密碼、確認密碼都填了才能按「送出」
/// - 成功後跳出「密碼已更新」，按「回到登入頁」回登入頁（回傳 true 給第 1 頁）
class ResetPasswordPage extends StatefulWidget {
  /// 第 1 頁確認過的帳號
  final String username;

  const ResetPasswordPage({super.key, required this.username});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  static const Color _green = Color(0xFF5B8A6B);
  static const Color _bg = Color(0xFFF6F8F3);

  /// 欄位錯誤的顏色：不用紅色，避免長輩緊張
  static const Color _errorColor = Color(0xFFB45309);

  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  /// 欄位錯誤：new_password、new_password_confirm
  final Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    // 輸入時重畫（讓「送出」即時變成可按），並清掉那一格的錯誤
    _newPasswordController.addListener(() {
      setState(() => _fieldErrors.remove('new_password'));
    });
    _confirmController.addListener(() {
      setState(() => _fieldErrors.remove('new_password_confirm'));
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _newPasswordController.text.isNotEmpty && _confirmController.text.isNotEmpty;

  Future<void> _handleSubmit() async {
    if (!_canSubmit || _isSubmitting) return;
    FocusScope.of(context).unfocus();

    final newPassword = _newPasswordController.text;
    final confirm = _confirmController.text;

    // 前端先檢查兩次密碼一不一樣，不用等後端
    if (newPassword != confirm) {
      setState(() => _fieldErrors['new_password_confirm'] = '兩次輸入的新密碼不一樣');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _fieldErrors.clear();
    });

    try {
      await AuthService.resetPassword(
        username: widget.username,
        newPassword: newPassword,
        newPasswordConfirm: confirm,
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showSuccessDialog();
    } catch (e) {
      debugPrint('[ResetPasswordPage] 設定新密碼失敗: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _handleError(e);
    }
  }

  /// 後端的欄位錯誤顯示在欄位下方；其他錯誤跳出提示
  void _handleError(Object e) {
    if (e is ApiException) {
      final Map<String, String> errors = {};
      final details = e.details;
      if (details is Map) {
        details.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            errors[key.toString()] = value.first.toString();
          } else if (value != null) {
            errors[key.toString()] = value.toString();
          }
        });
      }
      if (e.code == 'PASSWORD_MISMATCH' && errors.isEmpty) {
        errors['new_password_confirm'] = e.message;
      }
      if (errors.isNotEmpty) {
        setState(() => _fieldErrors.addAll(errors));
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(friendlyErrorMessage(e, fallback: '密碼更新失敗，請稍後再試一次'))),
    );
  }

  /// 成功：「密碼已更新」，按「回到登入頁」回去
  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '密碼已更新',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '請用新的密碼重新登入',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text(
              '回到登入頁',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    // 回傳 true 給第 1 頁，第 1 頁再一起回到登入頁
    Navigator.of(context).pop(true);
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
        // 左上角用文字「返回」（跟註冊頁一樣），回到第 1 頁
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

              // 新密碼
              _label('新密碼'),
              const SizedBox(height: 8),
              _passwordField(
                controller: _newPasswordController,
                hint: '請輸入新的密碼',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                errorText: _fieldErrors['new_password'],
              ),
              const SizedBox(height: 20),

              // 確認密碼
              _label('確認密碼'),
              const SizedBox(height: 8),
              _passwordField(
                controller: _confirmController,
                hint: '請再輸入一次新的密碼',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                errorText: _fieldErrors['new_password_confirm'],
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

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: obscure ? '顯示密碼' : '隱藏密碼',
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.black45,
          ),
          onPressed: onToggle,
        ),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        errorText: errorText,
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
    );
  }
}