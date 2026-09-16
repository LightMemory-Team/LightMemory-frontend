import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/go_to_market_model.dart';

class GoToMarketService {
  // 後端提供的 Cloudflare 測試網址（已更新為最新網址）
  static const String baseUrl =
      'https://contractor-recreation-rational-appear.trycloudflare.com/api/games/market-route';

  /// 1. 取得遊戲設定
  static Future fetchConfig() async {
    try {
      debugPrint('🚀 [API] 正在請求 config...');
      final response = await http
          .get(Uri.parse(baseUrl + '/config/'))
          .timeout(const Duration(seconds: 4));
      debugPrint(
        '📥 [API] config 回傳 [' +
            response.statusCode.toString() +
            ']: ' +
            response.body,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return decoded['data'];
        }
      }
    } catch (e) {
      debugPrint('⚠️ [API] config 連線異常: ' + e.toString());
    }
    return null;
  }

  /// 2. 開始遊戲建立 Session
  static Future startGame() async {
    try {
      debugPrint('🚀 [API] 正在請求 start...');
      final response = await http
          .post(Uri.parse(baseUrl + '/start/'))
          .timeout(const Duration(seconds: 4));
      debugPrint(
        '📥 [API] start 回傳 [' +
            response.statusCode.toString() +
            ']: ' +
            response.body,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return decoded['data']['session_id'];
        }
      }
    } catch (e) {
      debugPrint('⚠️ [API] start 連線異常: ' + e.toString());
    }
    return null;
  }

  /// 3. 取得單題內容
  static Future fetchRound({required int sessionId}) async {
    try {
      debugPrint(
        '🚀 [API] 正在請求 round (session_id=' + sessionId.toString() + ')...',
      );
      final response = await http
          .get(
            Uri.parse(baseUrl + '/round/?session_id=' + sessionId.toString()),
          )
          .timeout(const Duration(seconds: 4));
      debugPrint(
        '📥 [API] round 回傳 [' +
            response.statusCode.toString() +
            ']: ' +
            response.body,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return MarketRoundData.fromJson(decoded['data']);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [API] round 連線異常: ' + e.toString());
    }
    return null;
  }

  /// 4. 送出作答
  static Future submitAnswer({
    required int sessionId,
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

      final response = await http
          .post(
            Uri.parse(baseUrl + '/round/answer/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(reqBody),
          )
          .timeout(const Duration(seconds: 4));
      debugPrint(
        '📥 [API] answer 回傳 [' +
            response.statusCode.toString() +
            ']: ' +
            response.body,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return MarketAnswerResponse.fromJson(decoded['data']);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [API] answer 連線異常: ' + e.toString());
    }
    return null;
  }

  /// 5. 結束遊戲結算
  static Future finishGame({required int sessionId}) async {
    try {
      debugPrint(
        '🚀 [API] 送出 finish (session_id=' + sessionId.toString() + ')...',
      );
      final response = await http
          .post(
            Uri.parse(baseUrl + '/finish/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'session_id': sessionId}),
          )
          .timeout(const Duration(seconds: 4));
      debugPrint(
        '📥 [API] finish 回傳 [' +
            response.statusCode.toString() +
            ']: ' +
            response.body,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          return MarketFinishResult.fromJson(decoded['data']);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [API] finish 連線異常: ' + e.toString());
    }
    return null;
  }
}
