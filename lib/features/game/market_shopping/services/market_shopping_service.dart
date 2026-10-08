import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market_shopping_models.dart';
import '../../../../core/network/auth_headers.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/constants/api_constants.dart';

class MarketShoppingService {
  static const String _baseUrl =
      '${ApiConstants.serverUrl}/api/games/market-shopping';

  static Future<GameSession> startGame() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sessions/'),
      headers: await authHeaders(),
    );

    return parseEnvelope(response, GameSession.fromJson);
  }

  static Future<ItemAnswerResult> submitItemAnswer({
    required String sessionId,
    required List<String> selectedFoodCodes,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sessions/$sessionId/item-answers/'),
      headers: await authHeaders(),
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
      headers: await authHeaders(),
      body: jsonEncode({'selected_amount': selectedAmount}),
    );

    return parseEnvelope(response, ChangeAnswerResult.fromJson);
  }

  static Future<HistoryResult> getHistory() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/history/'),
      headers: await authHeaders(),
    );

    return parseEnvelope(response, HistoryResult.fromJson);
  }
}
