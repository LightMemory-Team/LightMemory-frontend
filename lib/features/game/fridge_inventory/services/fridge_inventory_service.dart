import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/fridge_inventory_model.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/token_storage.dart';

class FridgeInventoryService {
  // 後端 API
  static const String baseUrl = '${ApiConstants.serverUrl}/api/games/fridge-check';

  // ============================================================
  // 取得登入 Token
  // ============================================================

  static Future<String?> getToken() async {
    // 統一從 TokenStorage 讀登入時存的 token（key 是 access_token）
    return TokenStorage.getAccessToken();
  }

  // ============================================================
  // 共用 Headers
  // ============================================================

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // 將 Map 轉成 Map<String, dynamic>
  // ============================================================

  static Map<String, dynamic> _toStringDynamicMap(dynamic value) {
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    return <String, dynamic>{};
  }

  // ============================================================
  // 取得後端真正的資料內容
  // ============================================================

  static Map<String, dynamic> _extractMap(dynamic decoded) {
    if (decoded is! Map) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> root = _toStringDynamicMap(decoded);

    final dynamic data = root['data'];

    if (data is Map) {
      return _toStringDynamicMap(data);
    }

    final dynamic result = root['result'];

    if (result is Map) {
      return _toStringDynamicMap(result);
    }

    return root;
  }

  // ============================================================
  // 建立遊戲 Session
  // ============================================================

  static Future<FridgeGameSession> startSession() async {
    final url = Uri.parse('$baseUrl/sessions/');

    final headers = await _getHeaders();

    final response = await http
        .post(url, headers: headers)
        .timeout(const Duration(seconds: 10));

    // ----------------------------------------------------------
    // 建立 Session 失敗
    // ----------------------------------------------------------

    if (response.statusCode != 200 && response.statusCode != 201) {
      print('❌ 建立 Session 失敗');
      print('❌ URL: $url');
      print('❌ Status Code: ${response.statusCode}');
      print('❌ Response Body: ${response.body}');

      throw Exception(
        '無法建立遊戲 Session '
        '(${response.statusCode})',
      );
    }

    // ----------------------------------------------------------
    // 解析後端回傳資料
    // ----------------------------------------------------------

    final dynamic decoded = jsonDecode(response.body);

    final Map<String, dynamic> dataMap = _extractMap(decoded);

    // ----------------------------------------------------------
    // 顯示 Session 資訊
    // ----------------------------------------------------------

    print('📥 Session 原始回傳: ${response.body}');
    print('📥 Session dataMap: $dataMap');
    print('📥 Session ID: ${dataMap['session_id']}');

    // ----------------------------------------------------------
    // 確認資料是否有效
    // ----------------------------------------------------------

    if (dataMap.isEmpty) {
      throw Exception('後端沒有回傳有效的遊戲 Session 資料');
    }

    // ----------------------------------------------------------
    // 建立 FridgeGameSession
    // ----------------------------------------------------------

    final FridgeGameSession session = FridgeGameSession.fromJson(dataMap);

    print('✅ Flutter 取得 Session ID: ${session.sessionId}');

    return session;
  }

  // ============================================================
  // 提交遊戲答案
  // ============================================================

  static Future<Map<String, dynamic>> submitAnswer({
    // 後端的 session_id 是 UUID 字串（例如 7d6635ab-eef8-...），
    // 不可以用 int，否則會被轉成 0，導致 404 SESSION_NOT_FOUND
    required String sessionId,
    required int questionId,
    required int reactionTimeMs,
    String? foodCode,
    String? position,
  }) async {
    // ----------------------------------------------------------
    // API URL
    // ----------------------------------------------------------

    final url = Uri.parse('$baseUrl/sessions/$sessionId/answers/');

    final headers = await _getHeaders();

    // ----------------------------------------------------------
    // 建立答案內容
    //
    // Easy：
    // {
    //   "food_code": "egg"
    // }
    //
    // Medium：
    // {
    //   "position": "r2c2"
    // }
    //
    // Hard：
    // {
    //   "food_code": "tomato",
    //   "position": "r2c2"
    // }
    // ----------------------------------------------------------

    final Map<String, dynamic> answerMap = {};

    if (foodCode != null && foodCode.isNotEmpty) {
      answerMap['food_code'] = foodCode;
    }

    if (position != null && position.isNotEmpty) {
      answerMap['position'] = position;
    }

    // ----------------------------------------------------------
    // 後端 API 要求的 Request Body
    //
    // 不傳 question_id
    // ----------------------------------------------------------

    final Map<String, dynamic> body = {
      'answer': answerMap,
      'reaction_time_ms': reactionTimeMs,
    };

    // ----------------------------------------------------------
    // 顯示送出前的資料
    // ----------------------------------------------------------

    print('📤 Session ID: $sessionId');
    print('📤 Question ID: $questionId');
    print('📤 送出答案 URL: $url');
    print('📤 Request Body: ${jsonEncode(body)}');

    // ----------------------------------------------------------
    // 送出答案
    // ----------------------------------------------------------

    final response = await http
        .post(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));

    // ----------------------------------------------------------
    // 顯示後端回應
    // ----------------------------------------------------------

    print('📥 Status Code: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    // ----------------------------------------------------------
    // 判斷是否成功
    // ----------------------------------------------------------

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        '後端判題失敗 '
        '(${response.statusCode})',
      );
    }

    // ----------------------------------------------------------
    // 解析後端結果
    // ----------------------------------------------------------

    final dynamic decoded = jsonDecode(response.body);

    return _extractMap(decoded);
  }

  // ============================================================
  // 取得歷史成績
  // ============================================================

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final url = Uri.parse('$baseUrl/history/');

    final headers = await _getHeaders();

    final response = await http
        .get(url, headers: headers)
        .timeout(const Duration(seconds: 10));

    // ----------------------------------------------------------
    // 歷史紀錄取得失敗
    // ----------------------------------------------------------

    if (response.statusCode != 200) {
      print('❌ 取得歷史紀錄失敗');
      print('❌ URL: $url');
      print('❌ Status Code: ${response.statusCode}');
      print('❌ Response Body: ${response.body}');

      throw Exception(
        '無法取得歷史紀錄 '
        '(${response.statusCode})',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    List<dynamic> historyList = [];

    // ----------------------------------------------------------
    // 情況 1：
    //
    // {
    //   "history": [...]
    // }
    // ----------------------------------------------------------

    if (decoded is Map) {
      final Map<String, dynamic> root = _toStringDynamicMap(decoded);

      if (root['history'] is List) {
        historyList = root['history'] as List;
      }
      // --------------------------------------------------------
      // 情況 2：
      //
      // {
      //   "data": {
      //     "history": [...]
      //   }
      // }
      // --------------------------------------------------------
      else if (root['data'] is Map) {
        final Map<String, dynamic> data = _toStringDynamicMap(root['data']);

        if (data['history'] is List) {
          historyList = data['history'] as List;
        }
      }
      // --------------------------------------------------------
      // 情況 3：
      //
      // {
      //   "result": {
      //     "history": [...]
      //   }
      // }
      // --------------------------------------------------------
      else if (root['result'] is Map) {
        final Map<String, dynamic> result = _toStringDynamicMap(root['result']);

        if (result['history'] is List) {
          historyList = result['history'] as List;
        }
      }
    }
    // ----------------------------------------------------------
    // 情況 4：
    //
    // [
    //   {...},
    //   {...}
    // ]
    // ----------------------------------------------------------
    else if (decoded is List) {
      historyList = decoded;
    }

    // ----------------------------------------------------------
    // 轉換成 List<Map<String, dynamic>>
    // ----------------------------------------------------------

    return historyList.whereType<Map>().map<Map<String, dynamic>>((item) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }).toList();
  }
}
