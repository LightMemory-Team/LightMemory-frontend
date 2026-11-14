import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/auth_headers.dart';
import '../../../../core/network/api_response.dart';
import '../models/trial_result.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../rewards/models/rewards_models.dart';

class MarketSortSubmitResult {
  /// 每個人第一場是「熟悉場」，不計分
  final bool isPretest;

  /// 熟悉場或資料不夠算的場次是 null，一律有值才顯示
  final int? currentScore;
  final int? highestScore;
  final List<int> recentScores; // 不含 null 的場次，前幾次可能是空的
  final String? encouragementTier; // "great" / "good" / "keep_trying"

  /// 點數與成就：交卷回應的 data.rewards（熟悉場也會給點數）
  final RewardsResult rewards;

  MarketSortSubmitResult({
    this.isPretest = false,
    required this.currentScore,
    required this.highestScore,
    required this.recentScores,
    required this.encouragementTier,
    this.rewards = RewardsResult.empty,
  });

  factory MarketSortSubmitResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return MarketSortSubmitResult(
      isPretest: data['is_pretest'] as bool? ?? false,
      currentScore: data['current_score'] as int?,
      highestScore: data['highest_score'] as int?,
      recentScores: List<int>.from(data['recent_scores'] as List? ?? []),
      encouragementTier: data['encouragement_tier'] as String?,
      rewards: RewardsResult.fromData(data),
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