/// 記憶配對玩法（cooking_prep 的美術主題底層邏輯）的資料結構，對應後端
/// 6 支 API 的實際回應。這裡的類別名稱沿用「memory_recall」，是因為這款
/// 玩法本身在後端就叫 memory_recall（路由是 /api/games/memory-recall/），
/// cooking_prep 只是它的美術包裝，不是另一款獨立遊戲。
///
/// === ver3（1-back 連續配對，物品序列 A,B,C,D,...）改版說明 ===
/// - config/ 不再有 memorize_time_ms／delay_ms，已經整個拿掉這兩個欄位
/// - round/ 不再有 target_item，正確答案交給 round/answer/ 的 is_correct
///   判斷（見 cooking_prep_game_page.dart 類別註解的完整推導）
/// - start/ 的回應**已經用測試帳號實測確認**含有 [MemoryRecallSession.seedItem]
///   （JSON key 是 seed_item），而且這個欄位是必要的：round/ 回傳的
///   option_items 陣列順序是隨機的（不代表誰先出現），開局第1輪要展示
///   的兩個物品裡，「真正先出現、也是第1輪正解」的那一個，只能靠
///   seed_item 判斷，不能假設是 option_items[0]——這裡之前拿掉這個欄位、
///   改成直接照 option_items 陣列順序展示是錯的，導致第1輪大約一半機率
///   誤判（2026-10 實測 4 次：seed_item 在 option_items[0] 的位置隨機出現
///   在兩個位置，且 is_correct 完全跟著 seed_item 走，不跟著陣列位置）。
class MemoryRecallConfig {
  final bool isPretest;
  final String currentStage;
  final int pretestTotalRounds;
  final int baseTimeLimitSeconds;
  final int promoteStreak;
  final int promoteBonusSeconds;

  MemoryRecallConfig({
    required this.isPretest,
    required this.currentStage,
    required this.pretestTotalRounds,
    required this.baseTimeLimitSeconds,
    required this.promoteStreak,
    required this.promoteBonusSeconds,
  });

  factory MemoryRecallConfig.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MemoryRecallConfig(
      isPretest: data['is_pretest'] as bool,
      currentStage: data['current_stage'] as String,
      pretestTotalRounds: _toInt(data['pretest_total_rounds']),
      baseTimeLimitSeconds: _toInt(data['base_time_limit_seconds']),
      promoteStreak: _toInt(data['promote_streak']),
      promoteBonusSeconds: _toInt(data['promote_bonus_seconds']),
    );
  }
}

/// POST /start/ 的回應。[seedItem] 是整場遊戲第1輪真正「先出現」的物品
/// （見類別註解），只在開局這一次呼叫 start/ 才拿得到，換階段時後端沒有
/// 提供等同的欄位（見 cooking_prep_game_page.dart 的
/// _startNewStageOpening 的說明跟已知風險）。
class MemoryRecallSession {
  final String sessionId;
  final bool isPretest;
  final String currentStage;
  final DateTime? expiresAt;
  final String? seedItem;

  MemoryRecallSession({
    required this.sessionId,
    required this.isPretest,
    required this.currentStage,
    this.expiresAt,
    this.seedItem,
  });

  factory MemoryRecallSession.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MemoryRecallSession(
      sessionId: data['session_id'].toString(),
      isPretest: data['is_pretest'] as bool,
      currentStage: data['current_stage'] as String,
      expiresAt: _toDateTimeOrNull(data['expires_at']),
      seedItem: data['seed_item'] as String?,
    );
  }
}

/// GET /round/ 的回應：這一輪要二選一比對的 2 張卡片。
/// ver2 拿掉了 target_item／memorize_time_ms／delay_ms，兩張卡片同時顯示，
/// 答對答錯由後端在 round/answer/ 的 is_correct 判斷，前端不用自己判斷
/// 「哪一張是對的」。
class MemoryRecallRound {
  final int roundNumber;
  final String stage;
  final List<String> optionItems;
  // 2026-10 實測確認（Python 直打 API 連續跑 100+ 輪、外加後端團隊對照
  // log 確認）：這個欄位是「這一輪自己」要新引入、讓玩家記住的物品，
  // 保證不會出現在這一輪自己的 optionItems 裡；真正會用到它（判斷這一輪
  // 選項卡的正解）要等到「下一輪」。cooking_prep_game_page.dart 的
  // _fetchNextRoundAndPreview 直接拿它驅動單物品展示，見該檔案類別註解
  // ver6 的完整說明。
  final String? newItem;

  MemoryRecallRound({
    required this.roundNumber,
    required this.stage,
    required this.optionItems,
    this.newItem,
  });

  factory MemoryRecallRound.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MemoryRecallRound(
      roundNumber: _toInt(data['round_number']),
      stage: data['stage'] as String,
      optionItems: List<String>.from(data['option_items'] as List),
      newItem: data['new_item'] as String?,
    );
  }
}

/// POST /round/answer/ 的回應
class MemoryRecallAnswerResult {
  final bool isCorrect;
  final String action; // next_question / promoted / finished / time_up
  final String currentStage;
  final int correctStreak;
  final int bonusSecondsGranted;
  final DateTime? expiresAt;
  final int scoreEarned;

  MemoryRecallAnswerResult({
    required this.isCorrect,
    required this.action,
    required this.currentStage,
    required this.correctStreak,
    required this.bonusSecondsGranted,
    this.expiresAt,
    required this.scoreEarned,
  });

  factory MemoryRecallAnswerResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MemoryRecallAnswerResult(
      isCorrect: data['is_correct'] as bool,
      action: data['action'] as String,
      currentStage: data['current_stage'] as String,
      correctStreak: _toInt(data['correct_streak']),
      bonusSecondsGranted: _toInt(data['bonus_seconds_granted']),
      expiresAt: _toDateTimeOrNull(data['expires_at']),
      scoreEarned: _toInt(data['score_earned']),
    );
  }
}

/// POST /finish/ 跟 GET /result/{session_id}/ 共用的結算結果
/// （/result/ 的內容包在 session_result 底下，用 [MemoryRecallResult.fromResultJson] 解析）
class MemoryRecallResult {
  final int totalRounds;
  final int totalCorrect;
  final int totalWrong;
  final double accuracy;
  final int avgResponseTimeMs;
  final String finalStage;
  final int totalBonusSeconds;
  final int? totalScore; // 前測是 null

  MemoryRecallResult({
    required this.totalRounds,
    required this.totalCorrect,
    required this.totalWrong,
    required this.accuracy,
    required this.avgResponseTimeMs,
    required this.finalStage,
    required this.totalBonusSeconds,
    this.totalScore,
  });

  factory MemoryRecallResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MemoryRecallResult._fromData(data);
  }

  factory MemoryRecallResult.fromResultJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final sessionResult = data['session_result'] as Map<String, dynamic>;
    return MemoryRecallResult._fromData(sessionResult);
  }

  factory MemoryRecallResult._fromData(Map<String, dynamic> data) {
    return MemoryRecallResult(
      totalRounds: _toInt(data['total_rounds']),
      totalCorrect: _toInt(data['total_correct']),
      totalWrong: _toInt(data['total_wrong']),
      accuracy: (data['accuracy'] as num).toDouble(),
      avgResponseTimeMs: _toInt(data['avg_response_time_ms']),
      finalStage: data['final_stage'] as String,
      totalBonusSeconds: _toInt(data['total_bonus_seconds']),
      totalScore: _toIntOrNull(data['total_score']),
    );
  }
}

int _toInt(dynamic value) => (value as num).toInt();

int? _toIntOrNull(dynamic value) =>
    value != null ? (value as num).toInt() : null;

DateTime? _toDateTimeOrNull(dynamic value) =>
    value != null ? DateTime.parse(value as String) : null;
