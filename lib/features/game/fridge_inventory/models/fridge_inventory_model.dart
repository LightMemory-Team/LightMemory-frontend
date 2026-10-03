class FridgeItem {
  final String position;
  final String? foodCode;
  final String? foodName;

  FridgeItem({required this.position, this.foodCode, this.foodName});

  factory FridgeItem.fromJson(Map<String, dynamic> json) {
    return FridgeItem(
      position: json['position']?.toString() ?? '',
      foodCode: json['food_code']?.toString(),
      foodName: json['food_name']?.toString(),
    );
  }
}

class SourceFood {
  final String foodCode;
  final String foodName;

  SourceFood({required this.foodCode, required this.foodName});

  factory SourceFood.fromJson(Map<String, dynamic> json) {
    return SourceFood(
      foodCode: json['food_code']?.toString() ?? '',
      foodName: json['food_name']?.toString() ?? '',
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
    final dynamic rawBoard = json['board'];

    final List<dynamic> boardList = rawBoard is List ? rawBoard : <dynamic>[];

    final List<FridgeItem> parsedBoard = boardList
        .whereType<Map>()
        .map(
          (item) => FridgeItem.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();

    return FridgeQuestion(
      questionId: int.tryParse(json['question_id']?.toString() ?? '') ?? 0,
      questionType: json['question_type']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
      board: parsedBoard,
      sourceFood: json['source_food'] is Map
          ? SourceFood.fromJson(
              (json['source_food'] as Map).map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
          : null,
    );
  }
}

class FridgeGameSession {
  // 後端的 session_id 是 UUID 字串（例如 7d6635ab-eef8-458b-...），
  // 必須用 String 保存，不能轉成 int，否則會變成 0，
  // 送答案時打到 /sessions/0/answers/ 導致 404 SESSION_NOT_FOUND
  final String sessionId;
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
    // 後端正常應該是 session_id
    // 如果後端某些情況回傳 id，也一起支援
    final dynamic rawSessionId = json['session_id'] ?? json['id'];

    final String parsedSessionId = rawSessionId?.toString() ?? '';

    final dynamic rawQuestion = json['question'];

    final FridgeQuestion parsedQuestion = rawQuestion is Map
        ? FridgeQuestion.fromJson(
            rawQuestion.map((key, value) => MapEntry(key.toString(), value)),
          )
        : FridgeQuestion(
            questionId: 0,
            questionType: '',
            prompt: '',
            board: [],
          );

    return FridgeGameSession(
      sessionId: parsedSessionId,
      totalQuestions:
          int.tryParse(json['total_questions']?.toString() ?? '') ?? 10,
      currentQuestion:
          int.tryParse(json['current_question']?.toString() ?? '') ?? 1,
      difficulty: json['difficulty']?.toString() ?? 'easy',
      question: parsedQuestion,
    );
  }
}
