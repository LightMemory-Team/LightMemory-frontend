import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/auth_headers.dart';
import '../models/home_models.dart';

/// 首頁資料服務（依小惠〈首頁改版 API 規格書〉）
///
/// - getUser()：GET /api/home/user/         招呼語
/// - getGames()：GET /api/home/games/       大腦訓練遊戲卡片
/// - getDailyTasks()：GET /api/home/daily-tasks/  今日任務
///
/// 三支可以同時呼叫，不用一支等一支。
class HomeService {
  // ============================================================
  // 假資料開關
  //
  // true ：使用下方的假資料（後端還沒做好時用來做畫面）
  // false：呼叫真實後端
  // TODO：小惠的首頁 API 做好、對接時改成 false
  // ============================================================

  static const bool useMockHome = true;

  static const Duration _timeout = Duration(seconds: 15);

  Uri _uri(String path) => Uri.parse('${ApiConstants.serverUrl}$path');

  /// 成功回傳 data 那一層（相容有沒有包 {"data": ...}），失敗丟出 ApiException
  Map<String, dynamic> _handleResponse(http.Response response) {
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

    debugPrint('❌ 首頁 API 失敗（${response.statusCode}）：${utf8.decode(response.bodyBytes)}');
    throw json != null
        ? parseApiError(json, response.statusCode)
        : ApiException(
            statusCode: response.statusCode,
            message: '發生錯誤（${response.statusCode}）',
          );
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await http
        .get(_uri(path), headers: await authHeaders())
        .timeout(_timeout);
    return _handleResponse(response);
  }

  // ============================================================
  // 三支 API
  // ============================================================

    /// 招呼語：暱稱、鼓勵語、未讀通知數
  ///
  /// 依 Notion 現有 API：暱稱在 /api/home/user/，鼓勵語在 /api/home/greet/（daily_tip），
  /// 兩支同時呼叫再合在一起。鼓勵語拿不到不擋畫面，只是不顯示機器人那一行。
  Future<HomeUser> getUser() async {
    if (useMockHome) {
      await Future.delayed(const Duration(milliseconds: 400));
      return HomeUser.fromJson(_mockUser);
    }

    final results = await Future.wait([
      _get('/api/home/user/'),
      _get('/api/home/greet/').catchError((e) {
        debugPrint('❌ 讀取鼓勵語失敗: $e');
        return <String, dynamic>{};
      }),
    ]);

    final user = results[0];
    final greet = results[1];

    return HomeUser.fromJson({
      ...user,
      if (greet['daily_tip'] != null) 'daily_tip': greet['daily_tip'],
    });
  }

  /// 大腦訓練遊戲卡片（還沒開發的遊戲 is_developed = false 不顯示）
  Future<List<HomeGame>> getGames() async {
    if (useMockHome) {
      await Future.delayed(const Duration(milliseconds: 400));
      return _mockGames.map(HomeGame.fromJson).toList();
    }
    final data = await _get('/api/home/games/');
    final games = data['games'];
    if (games is! List) return [];
    return games
        .whereType<Map<String, dynamic>>()
        .map(HomeGame.fromJson)
        .where((game) => game.isDeveloped)
        .toList();
  }

  /// 今日任務（從遊戲或日記回到首頁時要重新呼叫，任務才會打勾）
  Future<DailyTasks> getDailyTasks() async {
    if (useMockHome) {
      await Future.delayed(const Duration(milliseconds: 400));
      return DailyTasks.fromJson(_mockDailyTasks);
    }
    return DailyTasks.fromJson(await _get('/api/home/daily-tasks/'));
  }

  // ============================================================
  // 假資料（useMockHome = true 時才會用到）
  // ============================================================

  static const Map<String, dynamic> _mockUser = {
    'user_name': '玉蘭',
    'daily_tip': '今天也要保持大腦活力呦',
    'unread_notification_count': 3,
  };

  static const List<Map<String, dynamic>> _mockGames = [
    {'id': 'market_sort', 'name': '整理菜籃', 'played_this_week': false},
    {'id': 'fridge_check', 'name': '冰箱清點', 'played_this_week': true},
    {'id': 'market_shopping', 'name': '市場買菜', 'played_this_week': false},
    {'id': 'market_route', 'name': '來去菜市場', 'played_this_week': true},
    {'id': 'memory_recall', 'name': '料理準備', 'played_this_week': false},
  ];

  static const Map<String, dynamic> _mockDailyTasks = {
    'date': '2026-11-02',
    'completed_count': 1,
    'total_count': 5,
    'weekly_progress': {'played_dimensions': 1, 'goal': 5},
    'tasks': [
      {
        'id': 31,
        'type': 'game',
        'title': '玩「整理菜籃」',
        'game_id': 'market_sort',
        'dimension': 'executive_function',
        'done': true,
      },
      {
        'id': 32,
        'type': 'game',
        'title': '玩「冰箱清點」',
        'game_id': 'fridge_check',
        'dimension': 'visual_spatial',
        'done': false,
      },
      {
        'id': 33,
        'type': 'game',
        'title': '玩「市場買菜」',
        'game_id': 'market_shopping',
        'dimension': 'math',
        'done': false,
      },
      {
        'id': 34,
        'type': 'diary',
        'title': '寫一篇聲影日記',
        'game_id': null,
        'dimension': 'language',
        'done': false,
      },
      {
        'id': 35,
        'type': 'weekly_report',
        'title': '看看上週回顧',
        'game_id': null,
        'dimension': null,
        'done': false,
      },
    ],
  };
}