import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market_shopping_models.dart';
import '../../../../core/services/token_storage.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/constants/api_constants.dart';

class MarketShoppingService {
  static const String _baseUrl =
      '${ApiConstants.serverUrl}/api/games/market-shopping';

  /// 共用 Headers：統一從 TokenStorage 讀登入時存的 token（key 是 access_token），
  /// 後端開啟 JWT 驗證後，每支 API 都必須帶 Authorization，否則會回 401
  static Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getAccessToken();

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<GameSession> startGame() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sessions/'),
      headers: await _getHeaders(),
    );

    return parseEnvelope(response, GameSession.fromJson);
  }

  static Future<ItemAnswerResult> submitItemAnswer({
    required String sessionId,
    required List<String> selectedFoodCodes,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sessions/$sessionId/item-answers/'),
      headers: await _getHeaders(),
      body: jsonEncode({'selected_food_codes': selectedFoodCodes}),
    );

    return parseEnvelope(response, ItemAnswerResult.fromJson);
  }

  static Future<ChangeAnswerResult> submitChangeAnswer({
    required String sessionId,
    required int selectedAmount,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sessions/$sessionId/change-answers/'),
      headers: await _getHeaders(),
      body: jsonEncode({'selected_amount': selectedAmount}),
    );

    return parseEnvelope(response, ChangeAnswerResult.fromJson);
  }

  static Future<HistoryResult> getHistory() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) {
      throw Exception('尚未登入，找不到token');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/history/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return parseEnvelope(response, HistoryResult.fromJson);
  }
}
