// 會員統計，對應後端 GET /api/users/me/stats/ 的 data

/// 會員頁「連續天數火苗」用的統計資料。
///
/// [streakDays] 是後端算好的「連續有玩遊戲或寫日記的天數」：今天還沒活動、
/// 但昨天有的話，延續昨天的天數。前端只顯示，不自己算
class UserStats {
  final int streakDays;
  final int activeDayCount;
  final int sessionCount;
  final int diaryCount;
  final String joinedAt; // YYYY-MM-DD

  const UserStats({
    required this.streakDays,
    required this.activeDayCount,
    required this.sessionCount,
    required this.diaryCount,
    required this.joinedAt,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    int toInt(Object? v) => v is num ? v.toInt() : 0;
    return UserStats(
      streakDays: toInt(json['streak_days']),
      activeDayCount: toInt(json['active_day_count']),
      sessionCount: toInt(json['session_count']),
      diaryCount: toInt(json['diary_count']),
      joinedAt: json['joined_at'] as String? ?? '',
    );
  }
}
