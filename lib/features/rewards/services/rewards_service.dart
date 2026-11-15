import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/auth_headers.dart';
import '../models/rewards_models.dart';
import 'mock_redeem_points.dart';

/// 點數與成就資料服務（依〈點數與成就系統規格〉）
///
/// - getSummary()：GET /api/rewards/summary/
/// - getAchievements()：GET /api/rewards/achievements/
///
/// 回傳格式統一是 {"success": true, "data": {...}, "error": null}。
class RewardsService {
  // ============================================================
  // 假資料開關
  //
  // true ：使用下方的假資料（後端還沒做好時用來做畫面）
  // false：呼叫真實後端
  // TODO：後端 rewards API 做好、對接時改成 false
  // ============================================================

  static const bool useMockRewards = false;

  static const Duration _timeout = Duration(seconds: 15);

  Uri _uri(String path) => Uri.parse('${ApiConstants.serverUrl}$path');

  /// 成功回傳 data 那一層；失敗丟出 ApiException
  Future<Map<String, dynamic>> _get(String path) async {
    final response = await http
        .get(_uri(path), headers: await authHeaders())
        .timeout(_timeout);

    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      json = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json?['data'];
      if (data is Map<String, dynamic>) return data;
      return json ?? {};
    }

    debugPrint('❌ 點數成就 API 失敗（${response.statusCode}）：${utf8.decode(response.bodyBytes)}');
    throw json != null
        ? parseApiError(json, response.statusCode)
        : ApiException(
            statusCode: response.statusCode,
            message: '發生錯誤（${response.statusCode}）',
          );
  }

  // ============================================================
  // API
  // ============================================================

  /// 點數與成就總覽（首頁點數、成就牆上方的已解鎖數）
  /// total_points 會扣掉商城假兌換花掉的點數（見 MockRedeemPoints）
  Future<RewardsSummary> getSummary() async {
    final RewardsSummary summary;
    if (useMockRewards) {
      await Future.delayed(const Duration(milliseconds: 300));
      summary = RewardsSummary.fromJson(_mockSummary);
    } else {
      summary = RewardsSummary.fromJson(await _get('/api/rewards/summary/'));
    }
    return RewardsSummary(
      totalPoints: MockRedeemPoints.apply(summary.totalPoints),
      todayPoints: summary.todayPoints,
      dailyCap: summary.dailyCap,
      dailyRemaining: summary.dailyRemaining,
      achievementsUnlocked: summary.achievementsUnlocked,
      achievementsTotal: summary.achievementsTotal,
    );
  }

  /// 成就牆：依三類分組（探索、訓練、里程碑）
  Future<List<AchievementCategory>> getAchievements() async {
    final Map<String, dynamic> data;
    if (useMockRewards) {
      await Future.delayed(const Duration(milliseconds: 400));
      data = _mockAchievements;
    } else {
      data = await _get('/api/rewards/achievements/');
    }

    final categories = data['categories'];
    if (categories is! List) return [];
    return categories
        .whereType<Map<String, dynamic>>()
        .map(AchievementCategory.fromJson)
        .toList();
  }

  // ============================================================
  // 假資料（第一版 25 個成就：探索 10、訓練 3、里程碑 12）
  // 已解鎖 3 個，其他有不同進度，方便測各種畫面
  // ============================================================

  static const Map<String, dynamic> _mockSummary = {
    'total_points': 120,
    'today_points': 35,
    'daily_cap': 100,
    'daily_remaining': 65,
    'achievements_unlocked': 3,
    'achievements_total': 25,
  };

  static Map<String, dynamic> _a(
    String code,
    String title,
    String description,
    int points, {
    String? unlockedAt,
    int current = 0,
    int target = 1,
  }) {
    final bool unlocked = unlockedAt != null;
    return {
      'code': code,
      'title': title,
      'description': description,
      'points': points,
      'unlocked': unlocked,
      'unlocked_at': unlockedAt,
      'progress': {'current': unlocked ? target : current, 'target': target},
    };
  }

  static final Map<String, dynamic> _mockAchievements = {
    'categories': [
      {
        'category': 'exploration',
        'label': '探索類',
        'achievements': [
          _a('first_market_route', '初次上市場', '第一次完成「來去菜市場」', 10),
          _a('first_memory_recall', '記憶初體驗', '第一次完成「料理準備」', 10),
          _a('first_market_sort', '整理初登場', '第一次完成「整理菜籃」', 10,
              unlockedAt: '2026-11-08T15:30:00+08:00'),
          _a('first_fridge_check', '冰箱小管家', '第一次完成「冰箱清點」', 10),
          _a('first_market_shopping', '第一次買菜', '第一次完成「市場買菜」', 10),
          _a('first_diary', '說說我的故事', '完成第一篇聲影日記', 10,
              unlockedAt: '2026-11-09T10:20:00+08:00'),
          _a('first_all_tasks', '今日目標達成', '第一次把今日任務全部完成', 10),
          _a('first_weekly_report', '回頭看看', '第一次打開上週回顧', 10),
          _a('first_dashboard', '認識自己', '第一次查看儀表板', 10,
              unlockedAt: '2026-11-05T09:00:00+08:00'),
          _a('first_share', '樂於分享', '第一次分享日記到動態牆', 10),
        ],
      },
      {
        'category': 'training',
        'label': '訓練類',
        'achievements': [
          _a('week_all_games', '五感全開', '同一週內 5 款遊戲都玩過', 20,
              current: 3, target: 5),
          _a('day_three_games', '多元練習', '同一天玩 3 款不同的遊戲', 20,
              current: 2, target: 3),
          _a('all_tasks_7', '每日小目標', '累積 7 天把今日任務全部完成', 20,
              current: 2, target: 7),
        ],
      },
      {
        'category': 'milestone',
        'label': '里程碑類',
        'achievements': [
          _a('play30_market_route', '市場尋寶家', '「來去菜市場」累積 30 場', 30,
              current: 4, target: 30),
          _a('play30_memory_recall', '記憶高手', '「料理準備」累積 30 場', 30,
              current: 2, target: 30),
          _a('play30_market_sort', '收納專家', '「整理菜籃」累積 30 場', 30,
              current: 12, target: 30),
          _a('play30_fridge_check', '冰箱總管', '「冰箱清點」累積 30 場', 30,
              current: 6, target: 30),
          _a('play30_market_shopping', '算盤達人', '「市場買菜」累積 30 場', 30,
              current: 3, target: 30),
          _a('diary_10', '日記滿十篇', '聲影日記累積 10 篇', 30,
              current: 1, target: 10),
          _a('games_100', '菜市場常客', '遊戲總共累積 100 場', 30,
              current: 27, target: 100),
          _a('radar_all_unlocked', '六項全能', '雷達圖六個維度全部解鎖', 30,
              current: 4, target: 6),
          _a('all_tasks_30', '持之以恆', '累積 30 天把今日任務全部完成', 30,
              current: 2, target: 30),
          _a('active_30', '一路相伴', '累積使用 30 天', 30,
              current: 9, target: 30),
          _a('active_90', '三個月的陪伴', '累積使用 90 天', 30,
              current: 9, target: 90),
          _a('points_1000', '點數小富翁', '點數累積 1,000 點', 30,
              current: 120, target: 1000),
        ],
      },
    ],
  };
}