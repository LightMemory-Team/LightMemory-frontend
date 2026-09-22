import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../screens/notification_screen.dart';
import '../../../screens/settings_screen.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const TopBar({super.key, this.title = '憶智防線'});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.isDarkMode,
        AppSettings.fontSizeLevel,
        AppSettings.unreadNotificationCount, // 監聽未讀數
      ]),
      builder: (context, _) {
        final isDark = AppSettings.isDarkMode.value;
        final unreadCount = AppSettings.unreadNotificationCount.value;

        final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final iconColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
        final themeGreen = isDark
            ? const Color(0xFF4CAF50)
            : const Color(0xFF2E6342);

        return AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          // 左上角設定按鈕
          leading: IconButton(
            icon: Icon(Icons.settings_outlined, color: iconColor, size: 26),
            tooltip: '系統設定',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          // 中間標題
          title: Text(
            title,
            style: TextStyle(
              color: themeGreen,
              fontSize: AppSettings.scaleFont(22),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          // 右上角鈴鐺
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: iconColor,
                      size: 28,
                    ),
                    tooltip: '最新通知',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  // 未讀紅點提示：只有 unreadCount > 0 時才會顯示
                  if (unreadCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 10,
                          minHeight: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
