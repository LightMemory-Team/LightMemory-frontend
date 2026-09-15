import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// 整理菜籃遊戲進行頁專用的頂部列：返回箭頭＋標題＋通知鈴鐺
///
/// 跟遊戲首頁用的 GameTopBar 不是同一個元件——那個是房子圖示＋鈴鐺，
/// 沒有返回箭頭跟標題文字，畫面需求不一樣，不能共用。
class MarketSortTopBar extends StatelessWidget {
  final VoidCallback onBackTap;
  final VoidCallback onNotificationTap;
  final bool hasUnreadNotification;

  const MarketSortTopBar({
    super.key,
    required this.onBackTap,
    required this.onNotificationTap,
    this.hasUnreadNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBackTap,
            child: const Icon(
              Icons.arrow_back,
              color: AppTheme.primaryColor,
              size: 26,
            ),
          ),
          const Expanded(
            child: Text(
              '整理菜籃',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
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
                  size: 26,
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