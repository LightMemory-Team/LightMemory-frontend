// 健康儀表板、週報表的資料格式，對應後端「儀表板與週報表 API 規格書」
// （GET /api/dashboard/、GET /api/dashboard/weekly-report/）。

import '../../rewards/models/rewards_models.dart';

/// 狀態卡片的機器人表情：good／keep／encourage
enum DashboardMood { good, keep, encourage }

/// 儀表板首頁上方的狀態卡片。
/// 後端只回傳趨勢代碼（encouragement.trend），文字由前端對照（規格書 4-2）
class DashboardStatus {
  final DashboardMood mood;
  final String title;
  final String message;

  const DashboardStatus({
    required this.mood,
    required this.title,
    required this.message,
  });

  /// [trend] 是後端的 up／steady／practice；六項還沒全部解鎖時
  /// encouragement 是 null，跟不認得的值一樣顯示「歡迎開始！」
  factory DashboardStatus.fromTrend(String? trend) {
    switch (trend) {
      case 'up':
        return const DashboardStatus(
          mood: DashboardMood.good,
          title: '進步了！',
          message: '最近越玩越好喔，繼續加油！',
        );
      case 'steady':
        return const DashboardStatus(
          mood: DashboardMood.keep,
          title: '請保持！',
          message: '最近狀態很不錯喔，繼續保持！',
        );
      case 'practice':
        return const DashboardStatus(
          mood: DashboardMood.encourage,
          title: '多練習！',
          message: '一起來動動腦，慢慢會越來越順手！',
        );
      default:
        return const DashboardStatus(
          mood: DashboardMood.keep,
          title: '歡迎開始！',
          message: '多玩幾次就能看到自己的變化喔！',
        );
    }
  }
}

/// 雷達圖上單項能力的狀態，每項各自判斷：
/// - 未解鎖：灰色＋「再玩 N 次」
/// - 已解鎖但統計期間（period_days）內沒玩：score 是 null，灰色＋「最近還沒玩」
/// - 其他：照 score 畫，名稱下方顯示分數
class DashboardDimension {
  final String dimension; // 能力代號，例如 working_memory
  final bool unlocked;
  final int validCount; // 累計有效場次（日記是篇數）
  final int sessionsToUnlock; // 還差幾次解鎖，已解鎖是 0
  final double? score; // 1～100，未解鎖或統計期間內沒玩是 null

  /// 自己的場次占基準的比例 n ÷ (n + 3)，小於 0.5 表示還在參考期
  /// （基準偏向其他使用者）
  final double personalWeight;

  const DashboardDimension({
    required this.dimension,
    required this.unlocked,
    required this.validCount,
    required this.sessionsToUnlock,
    required this.score,
    required this.personalWeight,
  });

  /// 已解鎖但基準還偏向其他使用者
  bool get isReferencePeriod => unlocked && personalWeight < 0.5;

  factory DashboardDimension.fromJson(Map<String, dynamic> json) {
    return DashboardDimension(
      dimension: json['dimension'] as String? ?? '',
      unlocked: json['unlocked'] as bool? ?? false,
      validCount: json['valid_count'] as int? ?? 0,
      sessionsToUnlock: json['sessions_to_unlock'] as int? ?? 0,
      score: (json['score'] as num?)?.toDouble(),
      // 舊版後端沒有這個欄位，當作已脫離參考期，不顯示提示
      personalWeight: (json['personal_weight'] as num?)?.toDouble() ?? 1,
    );
  }
}

/// 儀表板「小提醒」：近期某一場遊戲的表現比自己平常低很多（極端值）。
/// 由後端判斷（近 14 天、z ≤ -1.5，每款遊戲最多一筆），文案也由後端產生，
/// 前端直接顯示 [message]，不自己計算
class DashboardAlert {
  final String gameId;
  final String gameTitle;
  final String dimension;
  final String dimensionLabel;
  final DateTime? playedAt;
  final int? displayScore;
  final String message;

  const DashboardAlert({
    required this.gameId,
    required this.gameTitle,
    required this.dimension,
    required this.dimensionLabel,
    required this.playedAt,
    required this.displayScore,
    required this.message,
  });

  factory DashboardAlert.fromJson(Map<String, dynamic> json) {
    final score = json['display_score'];
    return DashboardAlert(
      gameId: json['game_id']?.toString() ?? '',
      gameTitle: json['game_title']?.toString() ?? '',
      dimension: json['dimension']?.toString() ?? '',
      dimensionLabel: json['dimension_label']?.toString() ?? '',
      playedAt: DateTime.tryParse(json['played_at']?.toString() ?? ''),
      displayScore: score is num ? score.round() : null,
      message: json['message']?.toString() ?? '',
    );
  }

  /// 後端沒給文案時不顯示（避免出現空白的提醒）
  static List<DashboardAlert> listFrom(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(DashboardAlert.fromJson)
        .where((alert) => alert.message.trim().isNotEmpty)
        .toList();
  }
}

/// 儀表板首頁：狀態卡片＋雷達圖
class DashboardOverview {
  /// 由 encouragement.trend 對照；六項還沒全部解鎖時顯示「歡迎開始！」
  final DashboardStatus status;

  /// 六項能力，key 是能力代號
  final Map<String, DashboardDimension> dimensions;

  /// 每項能力要累計幾場才解鎖
  final int requiredSessions;

  /// 點數與成就：開儀表板時解鎖的成就（data.rewards，只有第一次會有）
  final RewardsResult rewards;

  /// 小提醒：近期表現特別低的場次（data.alerts）；後端沒給或沒有時是空的
  final List<DashboardAlert> alerts;

  const DashboardOverview({
    required this.status,
    required this.dimensions,
    required this.requiredSessions,
    this.rewards = RewardsResult.empty,
    this.alerts = const [],
  });

  /// [data] 是後端回傳的 data
  factory DashboardOverview.fromApi({required Map<String, dynamic> data}) {
    final dimensions = (data['dimensions'] as List<dynamic>? ?? []).map(
      (e) => DashboardDimension.fromJson(e as Map<String, dynamic>),
    );
    final encouragement = data['encouragement'] as Map<String, dynamic>?;
    return DashboardOverview(
      status: DashboardStatus.fromTrend(encouragement?['trend'] as String?),
      dimensions: {for (final d in dimensions) d.dimension: d},
      requiredSessions: data['required_sessions'] as int? ?? 3,
      rewards: RewardsResult.fromData(data),
      alerts: DashboardAlert.listFrom(data['alerts']),
    );
  }
}

/// 本週跟上週比較的狀態詞：進步／持平／多練習（由後端判斷）
enum AbilityTrend { improved, steady, practice }

AbilityTrend? abilityTrendFromString(String? value) {
  switch (value) {
    case 'up':
      return AbilityTrend.improved;
    case 'steady':
      return AbilityTrend.steady;
    case 'practice':
      return AbilityTrend.practice;
    default:
      return null;
  }
}

/// 週報表「本週 vs 上週」的一行（整體或單項能力），分數都是 1～100
class WeeklyAbilityStat {
  /// 能力代號；整體是 'overall'
  final String id;

  /// 這週有沒有玩。語言（聲影日記）還沒有分數，有寫日記時 played 是
  /// true 但分數是 null，所以不能用 thisWeek 判斷
  final bool played;

  /// 累積滿 3 次才解鎖；未解鎖時本週、上週、最佳、趨勢都是 null。
  /// 整體沒有這個欄位，有任何一項解鎖就算解鎖
  final bool unlocked;
  final double? thisWeek; // 本週沒玩是 null
  final double? lastWeek; // 上週沒玩或第一週是 null
  final double? personalBest;
  final AbilityTrend? trend;

  const WeeklyAbilityStat({
    required this.id,
    required this.played,
    required this.unlocked,
    required this.thisWeek,
    required this.lastWeek,
    required this.personalBest,
    required this.trend,
  });

  bool get playedThisWeek => played;

  /// [id]、[unlocked] 給整體用（後端整體沒有 dimension、unlocked 欄位）
  factory WeeklyAbilityStat.fromJson(
    Map<String, dynamic> json, {
    String? id,
    bool? unlocked,
  }) {
    final thisWeek = (json['this_week'] as num?)?.toDouble();
    return WeeklyAbilityStat(
      id: id ?? json['dimension'] as String,
      // 整體沒有 played 欄位，有本週分數就算有玩
      played: json['played'] as bool? ?? thisWeek != null,
      unlocked: unlocked ?? json['unlocked'] as bool? ?? false,
      thisWeek: thisWeek,
      lastWeek: (json['last_week'] as num?)?.toDouble(),
      personalBest: (json['best'] as num?)?.toDouble(),
      trend: abilityTrendFromString(json['trend'] as String?),
    );
  }
}

/// 週報表裡的一篇聲影日記，點開彈窗要顯示的內容也在這裡
class WeeklyDiaryItem {
  final int diaryId;
  final DateTime date;
  final String title;
  final String photoUrl;
  final String postText;

  const WeeklyDiaryItem({
    required this.diaryId,
    required this.date,
    required this.title,
    required this.photoUrl,
    required this.postText,
  });

  factory WeeklyDiaryItem.fromJson(Map<String, dynamic> json) {
    return WeeklyDiaryItem(
      diaryId: json['diary_id'] as int,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String? ?? '',
      photoUrl: json['photo_url'] as String? ?? '',
      postText: json['post_text'] as String? ?? '',
    );
  }
}

/// 週報表「本週遊玩時間」裡單款遊戲的時長
class WeeklyGameTime {
  final String source; // 遊戲 id，例如 market_route
  final String label; // 例：「菜市場找路」
  final int seconds;

  const WeeklyGameTime({
    required this.source,
    required this.label,
    required this.seconds,
  });

  factory WeeklyGameTime.fromJson(Map<String, dynamic> json) {
    return WeeklyGameTime(
      source: json['source'] as String? ?? '',
      label: json['label'] as String? ?? '',
      seconds: json['seconds'] as int? ?? 0,
    );
  }
}

/// 週報表「本週遊玩時間」：總時長＋各遊戲時長
class WeeklyPlayTime {
  final int totalSeconds;
  final List<WeeklyGameTime> games;

  const WeeklyPlayTime({required this.totalSeconds, required this.games});

  factory WeeklyPlayTime.fromJson(Map<String, dynamic> json) {
    return WeeklyPlayTime(
      totalSeconds: json['total_seconds'] as int? ?? 0,
      games: (json['games'] as List<dynamic>? ?? [])
          .map((e) => WeeklyGameTime.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 週報表（上一個完整的週，週一到週日）
class WeeklyReport {
  final DateTime weekStart; // 週一
  final DateTime weekEnd; // 週日

  /// 後端沒有這個欄位，前端推算：整體沒有上週分數就當作第一週
  final bool isFirstWeek;

  /// ① 一句話總結
  final String summary;

  /// ② 三個大數字
  final int daysPlayed;
  final int sessionsPlayed;
  final int streakDays;

  /// ② 三個大數字下方的本週遊玩時間
  final WeeklyPlayTime playTime;

  /// ③ 本週打卡：週一到週日，有活動的那天是 true
  final List<bool> playedDays;

  /// ④ 本週 vs 上週
  final WeeklyAbilityStat overall;
  final List<WeeklyAbilityStat> abilities;

  /// ⑤ 聲影日記
  final List<WeeklyDiaryItem> diaries;
  final int diaryTalkSeconds;

  /// ⑥ 下週小目標
  final String nextWeekGoal;

  /// 頁尾免責聲明
  final String disclaimer;

  /// 點數與成就：看上週回顧的今日任務點數、解鎖的成就（data.rewards）
  final RewardsResult rewards;

  const WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.isFirstWeek,
    required this.summary,
    required this.daysPlayed,
    required this.sessionsPlayed,
    required this.streakDays,
    required this.playTime,
    required this.playedDays,
    required this.overall,
    required this.abilities,
    required this.diaries,
    required this.diaryTalkSeconds,
    required this.nextWeekGoal,
    required this.disclaimer,
    this.rewards = RewardsResult.empty,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    final weekStart = DateTime.parse(json['week_start'] as String);
    final highlights = json['highlights'] as Map<String, dynamic>? ?? {};
    final abilities = json['abilities'] as Map<String, dynamic>? ?? {};
    final diary = json['diary'] as Map<String, dynamic>? ?? {};
    final dimensionStats = (abilities['dimensions'] as List<dynamic>? ?? [])
        .map((e) => WeeklyAbilityStat.fromJson(e as Map<String, dynamic>))
        .toList();
    // 整體只用已解鎖的能力平均，全都沒解鎖時整體也是 null
    final overall = WeeklyAbilityStat.fromJson(
      abilities['overall'] as Map<String, dynamic>? ?? {},
      id: 'overall',
      unlocked: dimensionStats.any((d) => d.unlocked),
    );

    // 依日期對到週一～週日，後端少給或順序不同也不會錯位
    final activeDates = {
      for (final d
          in (json['daily_activity'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>())
        if (d['is_active'] == true) d['date'] as String,
    };
    String dateKey(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return WeeklyReport(
      weekStart: weekStart,
      weekEnd: DateTime.parse(json['week_end'] as String),
      isFirstWeek: overall.lastWeek == null,
      summary: json['summary'] as String? ?? '',
      daysPlayed: highlights['active_day_count'] as int? ?? 0,
      sessionsPlayed: highlights['session_count'] as int? ?? 0,
      streakDays: highlights['streak_days'] as int? ?? 0,
      playTime: WeeklyPlayTime.fromJson(
        json['play_time'] as Map<String, dynamic>? ?? {},
      ),
      playedDays: List.generate(
        7,
        (i) => activeDates.contains(
          dateKey(DateTime(weekStart.year, weekStart.month, weekStart.day + i)),
        ),
      ),
      overall: overall,
      abilities: dimensionStats,
      diaries: (diary['entries'] as List<dynamic>? ?? [])
          .map((e) => WeeklyDiaryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      diaryTalkSeconds: diary['talk_seconds'] as int? ?? 0,
      nextWeekGoal: json['next_week_goal'] as String? ?? '',
      disclaimer: json['disclaimer'] as String? ?? '這不是醫療診斷，僅供自我了解',
      rewards: RewardsResult.fromData(json),
    );
  }
}
