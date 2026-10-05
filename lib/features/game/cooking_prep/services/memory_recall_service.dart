import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/services/token_storage.dart';
import '../../../../core/network/api_response.dart';
import '../models/memory_recall_model.dart';
import '../../../../core/constants/api_constants.dart';

/// 記憶配對（memory_recall）的 6 支 API，已對照實測後端（不是只照文件）寫的。
/// 錯誤格式跟三款菜市場遊戲統一後的 {success, data, error:{code, message}} 一致，
/// 用共用的 parseEnvelope 解析；FORBIDDEN／ROUND_MISMATCH／GAME_TIME_UP 這三個
/// 是這份規格新增的錯誤碼，跟其他遊戲共用的 SESSION_NOT_FOUND 一樣，都會被
/// parseApiError 轉成帶 code 的 ApiException，呼叫端要分流處理可以讀 e.code。
class MemoryRecallService {
  static const String _baseUrl = '${ApiConstants.serverUrl}/api/games/memory-recall';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) {
      throw Exception('尚未登入，找不到token');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 1. GET /config/
  static Future<MemoryRecallConfig> fetchConfig() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/config/'),
      headers: headers,
    );
    return parseEnvelope(response, MemoryRecallConfig.fromJson);
  }

  /// 2. POST /start/
  /// [isPretest] 不帶的話交給後端自己判斷是不是這個使用者第一次玩；
  /// 呼叫端如果已經知道答案（例如本地已經記過「玩過了」）可以明確帶入覆蓋。
  static Future<MemoryRecallSession> startGame({bool? isPretest}) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/start/'),
      headers: headers,
      body: jsonEncode({
        if (isPretest != null) 'is_pretest': isPretest,
      }),
    );
    return parseEnvelope(response, MemoryRecallSession.fromJson);
  }

  /// 3. GET /round/
  static Future<MemoryRecallRound> fetchRound({required String sessionId}) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/round/?session_id=$sessionId'),
      headers: headers,
    );
    return parseEnvelope(response, MemoryRecallRound.fromJson);
  }

  /// 4. POST /round/answer/
  static Future<MemoryRecallAnswerResult> submitAnswer({
    required String sessionId,
    required int roundNumber,
    required String selectedItem,
    required int responseTimeMs,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/round/answer/'),
      headers: headers,
      body: jsonEncode({
        'session_id': sessionId,
        'round_number': roundNumber,
        'selected_item': selectedItem,
        'response_time_ms': responseTimeMs,
      }),
    );
    return parseEnvelope(response, MemoryRecallAnswerResult.fromJson);
  }

  /// 5. POST /finish/
  /// 正式賽時間到（time_up）或玩家中途離開時呼叫；前測第4輪答完後也要呼叫一次。
  static Future<MemoryRecallResult> finishGame({required String sessionId}) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/finish/'),
      headers: headers,
      body: jsonEncode({'session_id': sessionId}),
    );
    return parseEnvelope(response, MemoryRecallResult.fromJson);
  }

  /// 6. GET /result/{session_id}/
  static Future<MemoryRecallResult> fetchResult({required String sessionId}) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/result/$sessionId/'),
      headers: headers,
    );
    return parseEnvelope(response, MemoryRecallResult.fromResultJson);
  }
}
