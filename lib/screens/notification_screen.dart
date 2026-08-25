import 'package:flutter/material.dart';

// ==========================================
// 1. 資料模型區 (Notification Models)
// ==========================================
enum NotificationType { like, comment, memoryRecall, systemReminder }

class AppNotification {
  final int id;
  final NotificationType type;
  final String title;
  final String message;
  final String postedAt;
  final bool isRead;
  final int? relatedDiaryId;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.postedAt,
    this.isRead = false,
    this.relatedDiaryId,
  });
}

// 測試用通知資料
final List<AppNotification> mockNotifications = [
  AppNotification(
    id: 1,
    type: NotificationType.systemReminder,
    title: '貼心小提醒',
    message: '今天還沒有發布日記喔！抽空記錄一下今天的心情吧～',
    postedAt: '10 分鐘前',
    isRead: false,
  ),
  AppNotification(
    id: 2,
    type: NotificationType.comment,
    title: '日記新留言',
    message: '小明在你的「書法練習」日記留言：「寫得真好看！」',
    postedAt: '1 小時前',
    isRead: false,
    relatedDiaryId: 101,
  ),
  AppNotification(
    id: 3,
    type: NotificationType.like,
    title: '收到按讚',
    message: '秀英 為你的日記「早晨散步」按了讚！',
    postedAt: '3 小時前',
    isRead: false,
    relatedDiaryId: 102,
  ),
  AppNotification(
    id: 4,
    type: NotificationType.memoryRecall,
    title: '動態日記回顧',
    message: '一年前的今天：你去了陽明山賞花，還記得那天的陽光嗎？',
    postedAt: '今天 08:00',
    isRead: true,
    relatedDiaryId: 201,
  ),
];

// ==========================================
// 2. 介面畫面區 (Notification Screen UI)
// ==========================================
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const themeGreen = Color(0xFF2E6342);
    final safeTextScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.3);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: themeGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '最新通知',
          textScaler: safeTextScaler,
          style: const TextStyle(
            color: themeGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: mockNotifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = mockNotifications[index];
          return _buildNotificationCard(context, item, safeTextScaler);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification item,
    TextScaler textScaler,
  ) {
    IconData icon = Icons.notifications_rounded;
    Color iconBgColor = const Color(0xFFEDE7F6);
    Color iconColor = const Color(0xFF673AB7);

    switch (item.type) {
      case NotificationType.like:
        icon = Icons.favorite_rounded;
        iconBgColor = const Color(0xFFFFEBEE);
        iconColor = const Color(0xFFE53935);
        break;
      case NotificationType.comment:
        icon = Icons.chat_bubble_rounded;
        iconBgColor = const Color(0xFFE8F5E9);
        iconColor = const Color(0xFF2E7D32);
        break;
      case NotificationType.memoryRecall:
        icon = Icons.history_edu_rounded;
        iconBgColor = const Color(0xFFFFF3E0);
        iconColor = const Color(0xFFEF6C00);
        break;
      case NotificationType.systemReminder:
        icon = Icons.alarm_rounded;
        iconBgColor = const Color(0xFFEDE7F6);
        iconColor = const Color(0xFF673AB7);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : const Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead
              ? const Color(0xFFE8ECE9)
              : const Color(0xFFB7D5C2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
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
                      textScaler: textScaler,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    Text(
                      item.postedAt,
                      textScaler: textScaler,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF595959),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.message,
                  textScaler: textScaler,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF2B2B2B),
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
