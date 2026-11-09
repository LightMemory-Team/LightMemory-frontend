// ============================================================
// 點數與成就的資料格式（依〈點數與成就系統規格〉）
//
// - RewardsSummary：GET /api/rewards/summary/       首頁點數、已解鎖數
// - AchievementCategory／Achievement：
//                    GET /api/rewards/achievements/  成就牆（依三類分組）
// ============================================================

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

/// 點數與成就的總覽（首頁點數、成就牆上方的已解鎖數）
class RewardsSummary {
  /// 目前總點數
  final int totalPoints;

  /// 今天已得點數
  final int todayPoints;

  /// 每日上限（固定 100）
  final int dailyCap;

  /// 今天還能拿多少（最少 0）
  final int dailyRemaining;

  /// 已解鎖成就數、成就總數
  final int achievementsUnlocked;
  final int achievementsTotal;

  const RewardsSummary({
    required this.totalPoints,
    required this.todayPoints,
    required this.dailyCap,
    required this.dailyRemaining,
    required this.achievementsUnlocked,
    required this.achievementsTotal,
  });

  factory RewardsSummary.fromJson(Map<String, dynamic> json) {
    return RewardsSummary(
      totalPoints: _toInt(json['total_points']),
      todayPoints: _toInt(json['today_points']),
      dailyCap: _toInt(json['daily_cap'], fallback: 100),
      dailyRemaining: _toInt(json['daily_remaining']),
      achievementsUnlocked: _toInt(json['achievements_unlocked']),
      achievementsTotal: _toInt(json['achievements_total']),
    );
  }
}

/// 一個成就
class Achievement {
  /// 成就代碼，例如 first_diary
  final String code;

  /// 成就名稱，例如「說說我的故事」
  final String title;

  /// 解鎖條件說明，例如「完成第一篇聲影日記」
  final String description;

  /// 解鎖可得的點數（探索 10、訓練 20、里程碑 30）
  final int points;

  /// 是否已解鎖
  final bool unlocked;

  /// 解鎖時間（未解鎖是 null）
  final DateTime? unlockedAt;

  /// 進度：目前／目標，例如 12 / 30
  final int current;
  final int target;

  const Achievement({
    required this.code,
    required this.title,
    required this.description,
    required this.points,
    required this.unlocked,
    required this.unlockedAt,
    required this.current,
    required this.target,
  });

  /// 進度條長度（0.0～1.0）
  double get progressRatio =>
      target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'];
    final unlockedAtText = json['unlocked_at']?.toString();

    return Achievement(
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      points: _toInt(json['points']),
      unlocked: json['unlocked'] == true,
      unlockedAt: unlockedAtText == null ? null : DateTime.tryParse(unlockedAtText),
      current: progress is Map ? _toInt(progress['current']) : 0,
      target: progress is Map ? _toInt(progress['target'], fallback: 1) : 1,
    );
  }
}

/// 一個成就類別（探索類、訓練類、里程碑類）
class AchievementCategory {
  /// exploration／training／milestone
  final String category;

  /// 顯示名稱，例如「探索類」
  final String label;

  final List<Achievement> achievements;

  const AchievementCategory({
    required this.category,
    required this.label,
    required this.achievements,
  });

  int get unlockedCount => achievements.where((a) => a.unlocked).length;

  /// 畫面上的順序：已解鎖在前（最新解鎖的最上面），未解鎖在後（進度多的在前）
  List<Achievement> get sortedAchievements {
    final unlocked = achievements.where((a) => a.unlocked).toList()
      ..sort((a, b) {
        final aTime = a.unlockedAt ?? DateTime(2000);
        final bTime = b.unlockedAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
    final locked = achievements.where((a) => !a.unlocked).toList()
      ..sort((a, b) => b.progressRatio.compareTo(a.progressRatio));
    return [...unlocked, ...locked];
  }

  factory AchievementCategory.fromJson(Map<String, dynamic> json) {
    final raw = json['achievements'];
    return AchievementCategory(
      category: json['category']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      achievements: raw is List
          ? raw.whereType<Map<String, dynamic>>().map(Achievement.fromJson).toList()
          : [],
    );
  }
}