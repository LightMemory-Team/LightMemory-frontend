import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/auth_headers.dart';
import '../../../../core/network/api_response.dart';
import '../models/trial_result.dart';
import '../../../../core/constants/api_constants.dart';

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
  static const String _submitUrl = '${ApiConstants.serverUrl}/api/games/market-sort/submit/';

  static Future<MarketSortSubmitResult> submit({
    required String sessionId,
    required bool isComplete,
    required List<TrialResult> questions,
  }) async {
    final response = await http.post(
      Uri.parse(_submitUrl),
      headers: await authHeaders(),
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

    return parseEnvelope(response, MarketSortSubmitResult.fromJson);
  }
}