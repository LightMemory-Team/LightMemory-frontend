import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market_shopping_models.dart';

class MarketShoppingService {
  // TODO: 待後端部署固定網域後更新
  static const String _baseUrl =
      'https://jackets-revision-hey-mixing.trycloudflare.com/api/games/market-shopping';

  static Future<GameSession> startGame() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sessions/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return GameSession.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('開始遊戲失敗（${response.statusCode}）：${response.body}');
    }
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

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ItemAnswerResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('送出選菜答案失敗（${response.statusCode}）：${response.body}');
    }
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

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ChangeAnswerResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('送出找零答案失敗（${response.statusCode}）：${response.body}');
    }
  }
}