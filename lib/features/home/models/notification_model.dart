// 通知資料結構（對齊後端 GET /api/social/notifications/）
//
// 回傳格式 {success, data: {notifications: [...]}, error}，
// 每筆：id、message、notification_type、target_url（另外有 is_read、created_at 就一併讀）
class AppNotification {
  final int id;

  /// 通知內容，直接顯示在畫面上
  final String message;

  /// 通知類型（後端代碼，之後要依類型換圖示再用）
  final String type;

  /// 點通知要前往的位置（後端給的路徑，可能是空的）
  final String targetUrl;

  final bool isRead;

  /// 通知建立時間（ISO 8601 時間字串），沒有或解析不了就是 null
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.targetUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return AppNotification(
      id: rawId is num ? rawId.toInt() : int.tryParse('${rawId ?? ''}') ?? 0,
      message: (json['message'] ?? '').toString(),
      type: (json['notification_type'] ?? '').toString(),
      targetUrl: (json['target_url'] ?? '').toString(),
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(
        (json['created_at'] ?? '').toString(),
      )?.toLocal(),
    );
  }

  /// 點下去要不要跳到動態牆貼文：目前後端只會產生 comment（親友留言），
  /// target_url 是 /posts/{貼文 id}/；其他類型（like、family_reply、
  /// diary_reminder、game_reminder）後端還沒產生，路徑格式也還沒定，先不跳轉
  bool get opensPost => type == 'comment';

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    message: message,
    type: type,
    targetUrl: targetUrl,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}
