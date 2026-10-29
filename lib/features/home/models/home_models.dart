// ============================================================
// 首頁改版的資料格式（依小惠〈首頁改版 API 規格書〉）
//
// - HomeUser：GET /api/home/user/        招呼語的暱稱、鼓勵語、未讀通知數
// - HomeGame：GET /api/home/games/       大腦訓練遊戲卡片
// - DailyTasks／DailyTask：GET /api/home/daily-tasks/  今日任務
// ============================================================

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

/// 首頁招呼語
class HomeUser {
  /// 暱稱，例如「玉蘭」（後端欄位名稱還是 user_name，內容改成暱稱）
  final String userName;

  /// 鼓勵語，例如「今天也要保持大腦活力呦」
  final String dailyTip;

  /// 未讀通知數，0 就不顯示鈴鐺紅點
  final int unreadNotificationCount;

  const HomeUser({
    required this.userName,
    required this.dailyTip,
    required this.unreadNotificationCount,
  });

  factory HomeUser.fromJson(Map<String, dynamic> json) {
    return HomeUser(
      userName: json['user_name']?.toString() ?? '',
      // 鼓勵語的欄位名稱規格書沒寫清楚，兩種常見寫法都讀讀看
      dailyTip: (json['daily_tip'] ?? json['greeting_subtitle'] ?? '').toString(),
      unreadNotificationCount: _toInt(json['unread_notification_count']),
    );
  }
}

/// 首頁的大腦訓練遊戲卡片
class HomeGame {
  /// 遊戲代碼：market_route、memory_recall、market_sort、fridge_check、market_shopping
  final String id;

  /// 遊戲名稱，例如「整理菜籃」
  final String name;

  /// 本週（週一到今天）有沒有玩過；false 時卡片顯示「本週還沒玩」
  final bool playedThisWeek;

  const HomeGame({
    required this.id,
    required this.name,
    required this.playedThisWeek,
  });

  factory HomeGame.fromJson(Map<String, dynamic> json) {
    return HomeGame(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      playedThisWeek: json['played_this_week'] == true,
    );
  }
}

/// 今日任務的其中一項
class DailyTask {
  final int id;

  /// game（遊戲）／diary（聲影日記）／weekly_report（上週回顧），決定點下去跳到哪一頁
  final String type;

  /// 直接顯示在畫面上，例如「玩「整理菜籃」」
  final String title;

  /// 只有遊戲任務有值，點下去直接開這個遊戲
  final String? gameId;

  /// 這個任務練的維度；上週回顧是 null
  final String? dimension;

  /// 是否完成，完成就打勾
  final bool done;

  const DailyTask({
    required this.id,
    required this.type,
    required this.title,
    required this.gameId,
    required this.dimension,
    required this.done,
  });

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: _toInt(json['id']),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      gameId: json['game_id']?.toString(),
      dimension: json['dimension']?.toString(),
      done: json['done'] == true,
    );
  }
}

/// 今日任務整體（標題「完成 1 / 5」、進度條、任務清單）
class DailyTasks {
  final String date;
  final int completedCount;
  final int totalCount;

  /// 本週已玩過幾個遊戲維度（0～5），前端可選擇要不要顯示
  final int playedDimensions;
  final int weeklyGoal;

  final List<DailyTask> tasks;

  const DailyTasks({
    required this.date,
    required this.completedCount,
    required this.totalCount,
    required this.playedDimensions,
    required this.weeklyGoal,
    required this.tasks,
  });

  /// 進度條長度（0.0～1.0）
  double get progress => totalCount <= 0 ? 0 : (completedCount / totalCount).clamp(0.0, 1.0);

  factory DailyTasks.fromJson(Map<String, dynamic> json) {
    final weekly = json['weekly_progress'];
    final rawTasks = json['tasks'];

    return DailyTasks(
      date: json['date']?.toString() ?? '',
      completedCount: _toInt(json['completed_count']),
      totalCount: _toInt(json['total_count']),
      playedDimensions: weekly is Map ? _toInt(weekly['played_dimensions']) : 0,
      weeklyGoal: weekly is Map ? _toInt(weekly['goal'], fallback: 5) : 5,
      tasks: rawTasks is List
          ? rawTasks.whereType<Map<String, dynamic>>().map(DailyTask.fromJson).toList()
          : [],
    );
  }
}