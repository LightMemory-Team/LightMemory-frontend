import 'package:flutter/material.dart';
import '../../../core/services/token_storage.dart';
import '../../shop/services/shop_service.dart';
import '../pages/auth_gate.dart';

/// 設定頁與會員頁共用的登出流程，兩邊行為保持一致
class LogoutHelper {
  // 登出前先跟使用者確認，避免誤觸
  static Future<void> confirmAndLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('登出'),
          content: const Text('確定要登出目前的帳號嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                '登出',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    // 清掉 token 後交給 AuthGate，它找不到 token 就會導去登入頁
    await TokenStorage.clear();
    // demo 假資料（假扣點、兌換的票券）一起清掉，換帳號不會看到上一個人的
    ShopService.resetMock();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthGate()),
      (route) => false,
    );
  }
}
