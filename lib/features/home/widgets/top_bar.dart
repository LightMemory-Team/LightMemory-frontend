import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int unreadCount;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onNotificationTap;

  const TopBar({
    super.key,
    this.title = '憶智防線',
    this.unreadCount = 0,
    this.onSettingsTap,
    this.onNotificationTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    const themeGreen = Color(0xFF4A6B53); // 主題深綠色

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.settings, color: themeGreen, size: 26),
        onPressed: onSettingsTap ?? () {},
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: themeGreen,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  color: themeGreen,
                  size: 28,
                ),
                onPressed: onNotificationTap ?? () {},
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
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
