import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class GameTopBar extends StatelessWidget {
  final VoidCallback onHomeTap;       // 點擊房子圖示要做的事（回首頁）
  final VoidCallback onNotificationTap; // 點擊鈴鐺要做的事（進通知頁）
  final bool hasUnreadNotification;    // 是否顯示紅點

  const GameTopBar({
    super.key,
    required this.onHomeTap,
    required this.onNotificationTap,
    this.hasUnreadNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onHomeTap,
            child: const Icon(
              Icons.home_outlined,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          GestureDetector(
            onTap: onNotificationTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.primaryColor,
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
  }
}