import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../theme/app_theme.dart';
import 'game_menu_button.dart';

/// 遊戲進行中的共用頂部列：左「選單」按鈕＋中間標題＋右通知鈴鐺
///
/// 市場買菜、料理準備、整理菜籃、冰箱清點共用。
/// 來去菜市場是橫向遊戲，頂部空間比較小，只單獨使用 [GameMenuButton]。
class GameInProgressTopBar extends StatelessWidget {
  final String title;

  /// 點「選單」要做的事，通常是打開 GamePause
  final VoidCallback onMenuTap;

  /// 點鈴鐺要做的事；傳 null 就不顯示鈴鐺
  final VoidCallback? onNotificationTap;

  const GameInProgressTopBar({
    super.key,
    required this.title,
    required this.onMenuTap,
    this.onNotificationTap,
  });

  // 左右兩側留一樣寬的位置，標題才會真正置中
  static const double _sideSlotWidth = 96;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: _sideSlotWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GameMenuButton(onTap: onMenuTap),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          SizedBox(
            width: _sideSlotWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: onNotificationTap == null
                  ? null
                  : _NotificationBell(onTap: onNotificationTap!),
            ),
          ),
        ],
      ),
    );
  }
}

/// 鈴鐺：自己監聽未讀數量，有未讀就顯示紅點（跟遊戲首頁的鈴鐺一致）
class _NotificationBell extends StatelessWidget {
  final VoidCallback onTap;

  const _NotificationBell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ValueListenableBuilder<int>(
        valueListenable: AppSettings.unreadNotificationCount,
        builder: (context, count, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: AppTheme.primaryColor,
                size: 28,
              ),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
