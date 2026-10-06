import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../theme/app_theme.dart';

class GameTopBar extends StatelessWidget {
  final VoidCallback onHomeTap; // 點擊房子圖示要做的事（回首頁）
  final VoidCallback onNotificationTap; // 點擊鈴鐺要做的事（進通知頁）
  final bool hasUnreadNotification; // 是否顯示紅點

  const GameTopBar({
    super.key,
    required this.onHomeTap,
    required this.onNotificationTap,
    this.hasUnreadNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final isDark = AppSettings.isDarkMode.value;
        final isHighContrast = AppSettings.isHighContrast.value;

        // 深色模式的綠色沿用首頁頂部列（0xFF4CAF50）；高對比改成純黑／純白
        final iconColor = isHighContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? const Color(0xFF4CAF50) : AppTheme.primaryColor);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onHomeTap,
                child: Icon(Icons.home_outlined, color: iconColor, size: 28),
              ),
              GestureDetector(
                onTap: onNotificationTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: iconColor,
                      size: 28,
                    ),
                    if (hasUnreadNotification)
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
