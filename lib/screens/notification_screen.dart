import 'package:flutter/material.dart';
import '../app_settings.dart';

class NotificationItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String message;
  final String time;

  const NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.message,
    required this.time,
  });
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  final List<NotificationItem> _notifications = const [
    NotificationItem(
      icon: Icons.access_time_filled_rounded,
      iconColor: Color(0xFF7E57C2), // 紫色時鐘
      iconBgColor: Color(0xFFEDE7F6),
      title: '貼心小提醒',
      message: '今天還沒有發布日記喔！抽空記錄一下今天的心情吧～',
      time: '10 分鐘前',
    ),
    NotificationItem(
      icon: Icons.chat_bubble_rounded,
      iconColor: Color(0xFF2E6342), // 綠色對話框
      iconBgColor: Color(0xFFE8F5E9),
      title: '日記新留言',
      message: '小明在你的「書法練習」日記留言：「寫得真好看！」',
      time: '1 小時前',
    ),
    NotificationItem(
      icon: Icons.favorite_rounded,
      iconColor: Color(0xFFE53935), // 紅色愛心
      iconBgColor: Color(0xFFFFEBEE),
      title: '收到按讚',
      message: '秀英 為你的日記「早晨散步」按了讚！',
      time: '3 小時前',
    ),
    NotificationItem(
      icon: Icons.auto_stories_rounded,
      iconColor: Color(0xFFEF6C00), // 橘色日記相簿
      iconBgColor: Color(0xFFFFF3E0),
      title: '動態日記回顧',
      message: '一年前的今天：你去了陽明山賞花，還記得那天的陽光嗎？',
      time: '今天 08:00',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
        AppSettings.unreadNotificationCount,
      ]),
      builder: (context, _) {
        final isDark = AppSettings.isDarkMode.value;
        final isHighContrast = AppSettings.isHighContrast.value;
        final unreadCount = AppSettings.unreadNotificationCount.value;

        // 深淺色模式色彩適配
        final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
        final cardBgColor = isDark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFF1F8F4);
        final cardBorderColor = isDark
            ? const Color(0xFF333333)
            : (isHighContrast
                  ? const Color(0xFF2E6342)
                  : const Color(0xFFC8E6C9));
        final themeGreen = isDark
            ? const Color(0xFF4CAF50)
            : const Color(0xFF2E6342);

        final titleColor = isDark
            ? Colors.white
            : (isHighContrast ? Colors.black : const Color(0xFF1E1E1E));
        final messageColor = isDark
            ? const Color(0xFFCCCCCC)
            : (isHighContrast
                  ? const Color(0xFF212121)
                  : const Color(0xFF424242));
        final timeColor = isDark
            ? const Color(0xFF9E9E9E)
            : (isHighContrast
                  ? const Color(0xFF424242)
                  : const Color(0xFF757575));

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: themeGreen),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '最新通知',
              style: TextStyle(
                color: themeGreen,
                fontWeight: FontWeight.bold,
                fontSize: AppSettings.scaleFont(20),
              ),
            ),
            // 右上方「全部已讀」按鈕
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: unreadCount > 0
                      ? () {
                          // 點擊後將未讀數歸零，紅點即刻消失
                          AppSettings.unreadNotificationCount.value = 0;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('已將所有通知標記為已讀'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : null,
                  child: Text(
                    '全部已讀',
                    style: TextStyle(
                      color: unreadCount > 0
                          ? themeGreen
                          : (isDark
                                ? const Color(0xFF666666)
                                : const Color(0xFFBDBDBD)),
                      fontSize: AppSettings.scaleFont(15),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = _notifications[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cardBorderColor,
                    width: isHighContrast ? 2.0 : 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? item.iconColor.withValues(alpha: 0.2)
                            : item.iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: AppSettings.scaleFont(16),
                                  fontWeight: isHighContrast
                                      ? FontWeight.w900
                                      : FontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                              Text(
                                item.time,
                                style: TextStyle(
                                  fontSize: AppSettings.scaleFont(12),
                                  color: timeColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.message,
                            style: TextStyle(
                              fontSize: AppSettings.scaleFont(13.5),
                              color: messageColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
