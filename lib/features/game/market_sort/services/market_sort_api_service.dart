import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/services/token_storage.dart';
import '../models/trial_result.dart';

class MarketSortSubmitResult {
  final int currentScore;
  final int highestScore;
  final List<int> recentScores;
  final String encouragementTier; // "great" / "good" / "keep_trying"

  MarketSortSubmitResult({
    required this.currentScore,
    required this.highestScore,
    required this.recentScores,
    required this.encouragementTier,
  });

  factory MarketSortSubmitResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MarketSortSubmitResult(
      currentScore: data['current_score'] as int,
      highestScore: data['highest_score'] as int,
      recentScores: List<int>.from(data['recent_scores'] as List),
      encouragementTier: data['encouragement_tier'] as String,
    );
  }
}

class MarketSortApiService {
  // TODO: 暫時寫死，跟auth_service.dart同樣的做法，待後端提供正式網址後改用ApiConstants
  static const String _submitUrl =
      'https://stopped-residential-proposal-clients.trycloudflare.com/api/games/market-sort/submit/';

  static Future<MarketSortSubmitResult> submit({
    required String sessionId,
    required bool isComplete,
    required List<TrialResult> questions,
  }) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) {
      throw Exception('尚未登入，找不到token');
    }

    final response = await http.post(
      Uri.parse(_submitUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'session_id': sessionId,
        'is_complete': isComplete,
        'questions': questions
            .map((q) => {
                  'question_index': q.questionIndex,
                  'is_correct': q.isCorrect,
                  'reaction_time_ms': q.reactionTimeMs,
                  'trial_type':
                      q.trialType == TrialType.repeat ? 'repeat' : 'switch',
                  'error_type': q.errorType == null
                      ? null
                      : (q.errorType == ErrorType.persistent
                          ? 'persistent'
                          : 'random'),
                })
            .toList(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return MarketSortSubmitResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('送出成績失敗（${response.statusCode}）：${response.body}');
    }
  }
}