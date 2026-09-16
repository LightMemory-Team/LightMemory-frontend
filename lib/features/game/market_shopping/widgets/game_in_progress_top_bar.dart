import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class GameInProgressTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onPauseTap;
  final VoidCallback onNotificationTap;
  final bool hasUnreadNotification;

  const GameInProgressTopBar({
    super.key,
    required this.title,
    required this.onPauseTap,
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
            onTap: onPauseTap,
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
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