import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market_shopping_models.dart';
import '../../../../core/services/token_storage.dart';
import '../../../../core/network/api_response.dart';

class MarketShoppingService {
  static const String _baseUrl =
      'https://stopped-residential-proposal-clients.trycloudflare.com/api/games/market-shopping';

  static Future<GameSession> startGame() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sessions/'),
      headers: {'Content-Type': 'application/json'},
    );

    return parseEnvelope(response, GameSession.fromJson);
  }

  static Future<ItemAnswerResult> submitItemAnswer({
    required int sessionId,
    required List<String> selectedFoodCodes,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sessions/$sessionId/item-answers/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'selected_food_codes': selectedFoodCodes}),
    );

    return parseEnvelope(response, ItemAnswerResult.fromJson);
  }

  static Future<ChangeAnswerResult> submitChangeAnswer({
    required int sessionId,
    required int selectedAmount,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sessions/$sessionId/change-answers/'),
      headers: {'Content-Type': 'application/json'},
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
