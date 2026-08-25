// 1. 定義通知的四大情境類型
enum NotificationType {
  like, // 誰按讚了你的日記
  comment, // 誰留言了你的日記
  memoryRecall, // 動態日記回顧（如一年前的今天）
  systemReminder, // 每日發布貼心提醒
}

// 2. 通知資料結構（對齊後端 API 規格）
class AppNotification {
  final int id;
  final NotificationType type;
  final String title;
  final String message;
  final String postedAt;
  final bool isRead;
  final int? relatedDiaryId; // 關聯日記 ID

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.postedAt,
    this.isRead = false,
    this.relatedDiaryId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['notification_id'] ?? json['id'] ?? 0,
      type: _parseType(json['type'] as String?),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      postedAt: json['posted_at'] ?? '剛剛',
      isRead: json['is_read'] ?? false,
      relatedDiaryId: json['related_diary_id'],
    );
  }

  static NotificationType _parseType(String? typeStr) {
    switch (typeStr) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'memory_recall':
      case 'memory-recall':
        return NotificationType.memoryRecall;
      case 'system_reminder':
      case 'system-reminder':
      default:
        return NotificationType.systemReminder;
    }
  }
}

// 3. 測試用假資料
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
