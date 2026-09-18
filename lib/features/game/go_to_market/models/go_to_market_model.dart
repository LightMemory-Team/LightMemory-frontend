class MarketRoundData {
  final int questionNumber;
  final String stage;
  final String targetItem;
  final String targetPosition;
  final dynamic distractorItems;
  final int exposureTimeMs;

  MarketRoundData({
    required this.questionNumber,
    required this.stage,
    required this.targetItem,
    required this.targetPosition,
    required this.distractorItems,
    required this.exposureTimeMs,
  });

  factory MarketRoundData.fromJson(dynamic json) {
    return MarketRoundData(
      questionNumber: json['question_number'] ?? 1,
      stage: json['stage'] ?? 'basic',
      targetItem: json['target_item'] ?? '魚',
      targetPosition: json['target_position'] ?? 'center',
      distractorItems: json['distractor_items'] ?? [],
      exposureTimeMs: json['exposure_time_ms'] ?? 2000,
    );
  }
}

class MarketAnswerResponse {
  final bool isCorrect;
  final String action;
  final String currentStage;
  final int correctStreak;
  final int wrongAttempts;
  final int scoreEarned;
  final int fastCorrectStreak;

  MarketAnswerResponse({
    required this.isCorrect,
    required this.action,
    required this.currentStage,
    required this.correctStreak,
    required this.wrongAttempts,
    required this.scoreEarned,
    this.fastCorrectStreak = 0,
  });

  factory MarketAnswerResponse.fromJson(dynamic json) {
    return MarketAnswerResponse(
      isCorrect: json['is_correct'] ?? false,
      action: json['action'] ?? 'next_question',
      currentStage: json['current_stage'] ?? 'basic',
      correctStreak: json['correct_streak'] ?? 0,
      wrongAttempts: json['wrong_attempts'] ?? 0,
      scoreEarned: json['score_earned'] ?? 0,
      fastCorrectStreak: json['fast_correct_streak'] ?? 0,
    );
  }
}

class MarketFinishResult {
  final int totalQuestions;
  final int answeredCount;
  final int correctCount;
  final int timeoutCount;
  final double accuracy;
  final int avgResponseTimeMs;
  final String finalStage;
  final int totalScore;

  MarketFinishResult({
    required this.totalQuestions,
    required this.answeredCount,
    required this.correctCount,
    required this.timeoutCount,
    required this.accuracy,
    required this.avgResponseTimeMs,
    required this.finalStage,
    required this.totalScore,
  });

  factory MarketFinishResult.fromJson(dynamic json) {
    return MarketFinishResult(
      totalQuestions: json['total_questions'] ?? 20,
      answeredCount: json['answered_count'] ?? 0,
      correctCount: json['correct_count'] ?? 0,
      timeoutCount: json['timeout_count'] ?? 0,
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] as num).toDouble()
          : 0.0,
      avgResponseTimeMs: json['avg_response_time_ms'] ?? 0,
      finalStage: json['final_stage'] ?? 'basic',
      totalScore: json['total_score'] ?? 0,
    );
  }
}
