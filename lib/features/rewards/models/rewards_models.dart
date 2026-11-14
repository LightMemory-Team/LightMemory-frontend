// ============================================================
// 點數與成就的資料格式（依〈點數與成就系統規格〉）
//
// - RewardsSummary：GET /api/rewards/summary/       首頁點數、已解鎖數
// - AchievementCategory／Achievement：
//                    GET /api/rewards/achievements/  成就牆（依三類分組）
// - RewardsResult：遊戲結算、日記完成等回應的 data.rewards（獲得點數、新解鎖成就）
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

// ============================================================
// 結算回傳的獎勵（遊戲結算、日記完成、週報、儀表板、分享日記的 data.rewards）
//
// 規格書：rewards 區塊一律存在，沒有獲得點數時 points_earned 為 0，
// breakdown 與 new_achievements 為空陣列。
// ============================================================

/// 點數明細的一行，例如「完成一場遊戲 +10」
class RewardBreakdownItem {
  final String reason;
  final String label;
  final int points;

  const RewardBreakdownItem({
    required this.reason,
    required this.label,
    required this.points,
  });

  factory RewardBreakdownItem.fromJson(Map<String, dynamic> json) {
    return RewardBreakdownItem(
      reason: json['reason']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      points: _toInt(json['points']),
    );
  }
}

/// 這一次剛解鎖的成就（給解鎖視窗用）
class NewAchievement {
  final String code;
  final String category;
  final String title;
  final String description;
  final int points;

  const NewAchievement({
    required this.code,
    required this.category,
    required this.title,
    required this.description,
    required this.points,
  });

  factory NewAchievement.fromJson(Map<String, dynamic> json) {
    return NewAchievement(
      code: json['code']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      points: _toInt(json['points']),
    );
  }
}

/// 結算回傳的獎勵區塊
class RewardsResult {
  /// 這次實際入帳的點數
  final int pointsEarned;

  /// 點數明細（可逐行顯示）
  final List<RewardBreakdownItem> breakdown;

  /// 今天的點數是不是拿滿了（每日上限 100）
  final bool dailyCapReached;

  /// 目前總點數（結算後直接用這個更新畫面）
  final int totalPoints;

  /// 這次剛解鎖的成就（空的就不跳視窗）
  final List<NewAchievement> newAchievements;

  /// 發點失敗時後端給的訊息（rewards.error.message，REWARDS_FAILED）。
  /// 規格書：遊戲本身照常成功、當作 0 點，前端可以顯示這句，不要顯示錯誤畫面。
  final String? errorMessage;

  const RewardsResult({
    required this.pointsEarned,
    required this.breakdown,
    required this.dailyCapReached,
    required this.totalPoints,
    required this.newAchievements,
    this.errorMessage,
  });

  /// 沒有 rewards 時用（例如已結束的場次再次進入），當作 0 點
  static const RewardsResult empty = RewardsResult(
    pointsEarned: 0,
    breakdown: [],
    dailyCapReached: false,
    totalPoints: 0,
    newAchievements: [],
  );

  /// 有沒有東西可以顯示（規格書：0 點不顯示；拿滿了、發點失敗要顯示文案）
  bool get hasSomethingToShow =>
      pointsEarned > 0 || dailyCapReached || errorMessage != null;

  /// 從整個回應的 data 裡找 rewards；沒有就回傳 empty
  static RewardsResult fromData(dynamic data) {
    if (data is Map && data['rewards'] is Map<String, dynamic>) {
      return RewardsResult.fromJson(data['rewards'] as Map<String, dynamic>);
    }
    return RewardsResult.empty;
  }

  factory RewardsResult.fromJson(Map<String, dynamic> json) {
    final breakdown = json['breakdown'];
    final achievements = json['new_achievements'];
    final error = json['error'];
    String? errorMessage;
    if (error is Map) {
      final message = error['message']?.toString() ?? '';
      errorMessage = message.isNotEmpty ? message : '這次的點數暫時沒有算到';
    }
    return RewardsResult(
      pointsEarned: _toInt(json['points_earned']),
      breakdown: breakdown is List
          ? breakdown.whereType<Map<String, dynamic>>().map(RewardBreakdownItem.fromJson).toList()
          : [],
      dailyCapReached: json['daily_cap_reached'] == true,
      totalPoints: _toInt(json['total_points']),
      newAchievements: achievements is List
          ? achievements.whereType<Map<String, dynamic>>().map(NewAchievement.fromJson).toList()
          : [],
      errorMessage: errorMessage,
    );
  }
}