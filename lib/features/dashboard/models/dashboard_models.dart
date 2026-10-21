// 健康儀表板、週報表的資料格式，對應後端「儀表板與週報表 API 規格書」
// （GET /api/dashboard/、GET /api/dashboard/weekly-report/）。

/// 狀態卡片的機器人表情：good／keep／encourage
enum DashboardMood { good, keep, encourage }

DashboardMood dashboardMoodFromString(String? value) {
  switch (value) {
    case 'good':
      return DashboardMood.good;
    case 'encourage':
      return DashboardMood.encourage;
    default:
      return DashboardMood.keep;
  }
}

/// 把 {"working_memory": 72, ...} 轉成 Map，沒玩過的能力是 null
Map<String, double?> _scoreMapFromJson(dynamic json) {
  final map = json as Map<String, dynamic>? ?? {};
  return map.map((key, value) => MapEntry(key, (value as num?)?.toDouble()));
}

/// 儀表板首頁上方的狀態卡片
class DashboardStatus {
  final DashboardMood mood;
  final String title; // 例：「請保持!」
  final String message; // 例：「最近很狀態不錯喔 繼續保持!」

  const DashboardStatus({
    required this.mood,
    required this.title,
    required this.message,
  });

  factory DashboardStatus.fromJson(Map<String, dynamic> json) {
    return DashboardStatus(
      mood: dashboardMoodFromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

/// 未解鎖時，單款遊戲累計了幾場有分數的正式場次
class DashboardUnlockProgress {
  final String source; // 遊戲 id，例如 market_route
  final String label; // 例：「菜市場找路」
  final int sessionCount;

  const DashboardUnlockProgress({
    required this.source,
    required this.label,
    required this.sessionCount,
  });

  factory DashboardUnlockProgress.fromJson(Map<String, dynamic> json) {
    return DashboardUnlockProgress(
      source: json['source'] as String? ?? '',
      label: json['label'] as String? ?? '',
      sessionCount: json['session_count'] as int? ?? 0,
    );
  }
}

/// 儀表板首頁：狀態卡片＋雷達圖（已解鎖）或解鎖進度（未解鎖）
class DashboardOverview {
  /// 後端沒有提供，暫時用假資料（等跟後端討論後再決定）
  final DashboardStatus status;

  /// 同齡平均（0～100）。後端沒有提供，暫時用假資料
  final Map<String, double?> peerAverage;

  /// 六項能力近 7 天的 z 分數（-2～+2，0 = 跟平常一樣），
  /// key 是能力代號；近 7 天沒玩是 null。未解鎖時是空的
  final Map<String, double?> zScores;

  /// 未解鎖時每款遊戲的進度；已解鎖時是 null
  final List<DashboardUnlockProgress>? progress;

  /// 每款遊戲要累計幾場才解鎖
  final int requiredSessions;

  const DashboardOverview({
    required this.status,
    required this.peerAverage,
    required this.zScores,
    required this.progress,
    required this.requiredSessions,
  });

  bool get isUnlocked => progress == null;

  /// [data] 是後端回傳的 data；[mockStatus]／[mockPeerAverage] 是暫用的假資料
  factory DashboardOverview.fromApi({
    required bool success,
    required Map<String, dynamic> data,
    required Map<String, dynamic> mockStatus,
    required Map<String, dynamic> mockPeerAverage,
  }) {
    final status = DashboardStatus.fromJson(mockStatus);
    final peerAverage = _scoreMapFromJson(mockPeerAverage);

    if (!success) {
      return DashboardOverview(
        status: status,
        peerAverage: peerAverage,
        zScores: const {},
        progress: (data['progress'] as List<dynamic>? ?? [])
            .map(
              (e) =>
                  DashboardUnlockProgress.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        requiredSessions: data['required_sessions'] as int? ?? 3,
      );
    }

    final dimensions = data['dimensions'] as List<dynamic>? ?? [];
    return DashboardOverview(
      status: status,
      peerAverage: peerAverage,
      zScores: {
        for (final d in dimensions.cast<Map<String, dynamic>>())
          d['dimension'] as String: (d['z_score'] as num?)?.toDouble(),
      },
      progress: null,
      requiredSessions: 3,
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
  final double? thisWeek; // 本週沒玩是 null
  final double? lastWeek; // 上週沒玩或第一週是 null
  final double? personalBest;
  final AbilityTrend? trend;

  const WeeklyAbilityStat({
    required this.id,
    required this.played,
    required this.thisWeek,
    required this.lastWeek,
    required this.personalBest,
    required this.trend,
  });

  bool get playedThisWeek => played;

  /// [id] 給整體用（後端整體沒有 dimension 欄位）
  factory WeeklyAbilityStat.fromJson(Map<String, dynamic> json, {String? id}) {
    final thisWeek = (json['this_week'] as num?)?.toDouble();
    return WeeklyAbilityStat(
      id: id ?? json['dimension'] as String,
      // 整體沒有 played 欄位，有本週分數就算有玩
      played: json['played'] as bool? ?? thisWeek != null,
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
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    final weekStart = DateTime.parse(json['week_start'] as String);
    final highlights = json['highlights'] as Map<String, dynamic>? ?? {};
    final abilities = json['abilities'] as Map<String, dynamic>? ?? {};
    final diary = json['diary'] as Map<String, dynamic>? ?? {};
    final overall = WeeklyAbilityStat.fromJson(
      abilities['overall'] as Map<String, dynamic>? ?? {},
      id: 'overall',
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
      abilities: (abilities['dimensions'] as List<dynamic>? ?? [])
          .map((e) => WeeklyAbilityStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      diaries: (diary['entries'] as List<dynamic>? ?? [])
          .map((e) => WeeklyDiaryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      diaryTalkSeconds: diary['talk_seconds'] as int? ?? 0,
      nextWeekGoal: json['next_week_goal'] as String? ?? '',
      disclaimer: json['disclaimer'] as String? ?? '這不是醫療診斷，僅供自我了解',
    );
  }
}
