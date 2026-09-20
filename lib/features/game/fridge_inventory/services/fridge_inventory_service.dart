import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_response.dart';
import '../models/fridge_inventory_model.dart';

class FridgeInventoryService {
  // 使用專案統一的雲端 API 網址
  static const String baseUrl =
      'https://stopped-residential-proposal-clients.trycloudflare.com/api/games/fridge-check';

  // 取得共用 Token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // 1. 建立遊戲 Session (開始遊戲並取得第 1 題)
  static Future<FridgeGameSession> startSession() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/sessions/');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    return parseEnvelope(response, FridgeGameSession.fromJson);
  }

  // 2. 提交答案
  static Future<Map<String, dynamic>> submitAnswer({
    required int sessionId,
    required int questionId,
    required int reactionTimeMs,
    String? foodCode,
    String? position,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/sessions/$sessionId/answers/');

    final Map<String, dynamic> body = {
      'question_id': questionId,
      'reaction_time_ms': reactionTimeMs,
    };

    if (foodCode != null) body['food_code'] = foodCode;
    if (position != null) body['position'] = position;

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    // 這裡我們直接用 dynamic 接收回傳的 Map 資料
    return parseEnvelope<Map<String, dynamic>>(
      response,
      (json) => json as Map<String, dynamic>,
    );
  }

  // 3. 取得歷史成績列表
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/history/');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    final resultData = parseEnvelope<Map<String, dynamic>>(
      response,
      (json) => json as Map<String, dynamic>,
    );
    final historyList = resultData['history'] as List? ?? [];
    return historyList.map((item) => item as Map<String, dynamic>).toList();
  }
}
