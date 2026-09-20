class FridgeItem {
  final String position; // r1c1 ~ r3c3
  final String? foodCode;
  final String? foodName;

  FridgeItem({required this.position, this.foodCode, this.foodName});

  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    return FridgeItem(
      position: json['position'] ?? '',
      foodCode: json['food_code'],
      foodName: json['food_name'],
    );
  }
}

class SourceFood {
  final String foodCode;
  final String foodName;

  SourceFood({required this.foodCode, required this.foodName});

  factory SourceFood.fromJson(Map<String, dynamic> json) {
    return SourceFood(
      foodCode: json['food_code'] ?? '',
      foodName: json['food_name'] ?? '',
    );
  }
}

class FridgeQuestion {
  final int questionId;
  final String questionType;
  final String prompt;
  final List<FridgeItem> board;
  final SourceFood? sourceFood;

  FridgeQuestion({
    required this.questionId,
    required this.questionType,
    required this.prompt,
    required this.board,
    this.sourceFood,
  });

  factory FridgeQuestion.fromJson(Map<String, dynamic> json) {
    var boardList = json['board'] as List? ?? [];
    List<FridgeItem> parsedBoard = boardList
        .map((i) => FridgeItem.fromJson(i))
        .toList();

    return FridgeQuestion(
      questionId: json['question_id'] ?? 0,
      questionType: json['question_type'] ?? '',
      prompt: json['prompt'] ?? '',
      board: parsedBoard,
      sourceFood: json['source_food'] != null
          ? SourceFood.fromJson(json['source_food'])
          : null,
    );
  }
}

class FridgeGameSession {
  final int sessionId;
  final int totalQuestions;
  final int currentQuestion;
  final String difficulty;
  final FridgeQuestion question;

  FridgeGameSession({
    required this.sessionId,
    required this.totalQuestions,
    required this.currentQuestion,
    required this.difficulty,
    required this.question,
  });

  factory FridgeGameSession.fromJson(Map<String, dynamic> json) {
    return FridgeGameSession(
      sessionId: json['session_id'] ?? 0,
      totalQuestions: json['total_questions'] ?? 10,
      currentQuestion: json['current_question'] ?? 1,
      difficulty: json['difficulty'] ?? 'easy',
      question: FridgeQuestion.fromJson(json['question'] ?? {}),
    );
  }
}
