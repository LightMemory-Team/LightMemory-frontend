import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/go_to_market_model.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/auth_headers.dart';

class GoToMarketService {
  static const String baseUrl =
      '${ApiConstants.serverUrl}/api/games/market-route';

  /// 這場遊戲是否有 API 回 401（token 過期或沒登入）。
  /// 每次 startGame 重設；遊戲頁用來提示重新登入，否則會默默改用本地模式、成績不進後端。
  static bool unauthorized = false;

  /// API 失敗時統一印出明顯的 log：呼叫端拿到 null 後會改用本地模式，成績不會寫入後端
  static void _logFailure(String api, Object e) {
    if (e is NotLoggedInException) {
      // 手機裡沒有 token：請求根本沒送出去，一樣要提示重新登入
      unauthorized = true;
      debugPrint(
        '🔴🔴🔴 [API] ' + api + ' 沒有登入 token，改用本地模式，這場成績不會寫入後端',
      );
    } else if (e is ApiException && e.statusCode == 401) {
      unauthorized = true;
      debugPrint(
        '🔴🔴🔴 [API] ' + api + ' 回 401：token 過期或沒登入，改用本地模式，這場成績不會寫入後端',
      );
    } else {
      debugPrint('🔴 [API] ' + api + ' 失敗，改用本地模式，這場成績不會寫入後端: ' + e.toString());
    }
  }

  /// 1. 取得遊戲設定
  static Future fetchConfig() async {
    try {
      debugPrint('🚀 [API] 正在請求 config...');
      final headers = await authHeaders();
      final response = await http
          .get(Uri.parse(baseUrl + '/config/'), headers: headers)
          .timeout(const Duration(seconds: 4));
      debugPrint(
        '📥 [API] config 回傳 [' +
            response.statusCode.toString() +
            ']: ' +
            response.body,
      );

      return parseData(response, (data) => data);
    } catch (e) {
      _logFailure('config', e);
    }
    return null;
  }

  /// 2. 開始遊戲建立 Session
  static Future startGame() async {
    try {
      unauthorized = false;
      debugPrint('🚀 [API] 正在請求 start...');
      final headers = await authHeaders();
      final response = await http
          .post(Uri.parse(baseUrl + '/start/'), headers: headers)
          .timeout(const Duration(seconds: 4));
      debugPrint(
        '📥 [API] start 回傳 [' +
            response.statusCode.toString() +
            ']: ' +
            response.body,
      );

      // 後端 session_id 是 UUID 字串（9/24 起），用 toString() 解析，跟料理準備一樣
      return parseData(response, (data) => data['session_id']?.toString());
    } catch (e) {
      _logFailure('start', e);
    }
    return null;
  }

  /// 3. 取得單題內容
  static Future fetchRound({required String sessionId}) async {
    try {
      debugPrint('🚀 [API] 正在請求 round (session_id=' + sessionId + ')...');
      final headers = await authHeaders();
      final response = await http
          .get(
            Uri.parse(baseUrl + '/round/?session_id=' + sessionId),
            headers: headers,
          )
          .timeout(const Duration(seconds: 4));
      debugPrint(
        '📥 [API] round 回傳 [' +
            response.statusCode.toString() +
            ']: ' +
            response.body,
      );

      return parseData(response, (data) => MarketRoundData.fromJson(data));
    } catch (e) {
      _logFailure('round', e);
    }
    return null;
  }

  /// 4. 送出作答
  static Future submitAnswer({
    required String sessionId,
    required int questionNumber,
    required int attemptNumber,
    required String? answerPosition,
    required bool isTimeout,
    required int responseTimeMs,
    required int pausedDurationMs,
  }) async {
    try {
      final reqBody = {
        'session_id': sessionId,
        'question_number': questionNumber,
        'attempt_number': attemptNumber,
        'answer_position': answerPosition,
        'is_timeout': isTimeout,
        'response_time_ms': responseTimeMs,
        'paused_duration_ms': pausedDurationMs,
      };
      debugPrint('🚀 [API] 送出作答 answer: ' + reqBody.toString());

      final headers = await authHeaders();
      final response = await http
          .post(
            Uri.parse(baseUrl + '/round/answer/'),
            headers: headers,
            body: jsonEncode(reqBody),
          )
          .timeout(const Duration(seconds: 4));
      debugPrint(
        '📥 [API] answer 回傳 [' +
            response.statusCode.toString() +
            ']: ' +
            response.body,
      );

      return parseData(response, (data) => MarketAnswerResponse.fromJson(data));
    } catch (e) {
      _logFailure('answer', e);
    }
    return null;
  }

  /// 5. 結束遊戲結算
  static Future finishGame({required String sessionId}) async {
    try {
      debugPrint('🚀 [API] 送出 finish (session_id=' + sessionId + ')...');
      final headers = await authHeaders();
      final response = await http
          .post(
            Uri.parse(baseUrl + '/finish/'),
            headers: headers,
            body: jsonEncode({'session_id': sessionId}),
          )
          .timeout(const Duration(seconds: 4));
      debugPrint(
        '📥 [API] finish 回傳 [' +
            response.statusCode.toString() +
            ']: ' +
            response.body,
      );

      return parseData(response, (data) => MarketFinishResult.fromJson(data));
    } catch (e) {
      _logFailure('finish', e);
    }
    return null;
  }
}
