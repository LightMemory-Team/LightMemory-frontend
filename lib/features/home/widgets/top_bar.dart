import 'package:flutter/material.dart';
import '../../../screens/notification_screen.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final int unreadCount;

  const TopBar({super.key, this.unreadCount = 0});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    const themeGreen = Color(0xFF2E6342);
    final safeTextScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.3);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        '憶智防線',
        textScaler: safeTextScaler,
        style: const TextStyle(
          color: themeGreen,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1E1E1E),
                  size: 28,
                ),
                tooltip: '最新通知',
                onPressed: () {
                  // 點擊鈴鐺跳轉至最新通知頁面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
              ),
              // 未讀紅點提示
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
  }
}
