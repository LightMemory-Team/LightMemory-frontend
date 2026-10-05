/// 一樣食材（後端只給 code 跟中文名，圖片由前端自己對應）
class MarketFood {
  final String foodCode;
  final String foodName;

  MarketFood({required this.foodCode, required this.foodName});

  factory MarketFood.fromJson(Map<String, dynamic> json) {
    return MarketFood(foodCode: json['food_code'], foodName: json['food_name']);
  }

  /// 依照 food_code 對應到 assets 裡的圖片路徑
  String get imagePath => 'assets/images/game/market_shopping/$foodCode.png';
}

/// 困難模式購買明細（含價格）
class PurchasedItem {
  final String foodName;
  final int price;

  PurchasedItem({required this.foodName, required this.price});

  factory PurchasedItem.fromJson(Map<String, dynamic> json) {
    return PurchasedItem(
      foodName: json['food_name'],
      price: _toInt(json['price']),
    );
  }
}

/// 一題的題目資料（開始遊戲、或 next_question 都用這個格式）
class ShoppingQuestion {
  final String difficulty;
  final int currentQuestion;
  final int totalQuestions;
  final List<MarketFood> shoppingList;
  final List<MarketFood> selectionOptions;

  ShoppingQuestion({
    required this.difficulty,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.shoppingList,
    required this.selectionOptions,
  });

  factory ShoppingQuestion.fromJson(Map<String, dynamic> json) {
    return ShoppingQuestion(
      difficulty: json['difficulty'],
      currentQuestion: _toInt(json['current_question']),
      totalQuestions: _toInt(json['total_questions']),
      shoppingList: (json['shopping_list'] as List)
          .map((e) => MarketFood.fromJson(e))
          .toList(),
      selectionOptions: (json['selection_options'] as List)
          .map((e) => MarketFood.fromJson(e))
          .toList(),
    );
  }
}

/// 開始遊戲的回應（比 ShoppingQuestion 多一個 session_id）
class GameSession {
  // 後端的 session_id 是 UUID 字串（例如 48b8015b-c982-4311-...），
  // 必須用 String 保存，不能用 _toInt 轉數字，否則會出現
  // type 'String' is not a subtype of type 'num' 的錯誤
  final String sessionId;
  final ShoppingQuestion firstQuestion;

  GameSession({required this.sessionId, required this.firstQuestion});

  factory GameSession.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return GameSession(
      sessionId: data['session_id']?.toString() ?? '',
      firstQuestion: ShoppingQuestion.fromJson(data),
    );
  }
}

/// 送出選菜答案的回應。
/// 後端重寫計算方式後，答錯時（is_correct:false）回應形狀完全不一樣，
/// 不再有 budget/change_options 這些欄位，而是 retry/wrong_count/
/// remaining_attempts/error_type（實測過 mixed_item_error 這個值，答錯
/// 滿3次(remaining_attempts歸0)後才會改帶 next_question 自動跳題）。
class ItemAnswerResult {
  final bool isCorrect;
  final bool isCompleted;
  final int? budget;
  final int? spentAmount; // easy/medium 才有
  final List<PurchasedItem>? purchasedItems; // hard 才有
  final List<int>? changeOptions;
  final ShoppingQuestion? nextQuestion; // 選菜錯滿3次跳題時才會有

  /// 答錯時才有意義的欄位（is_correct:false 且還沒錯滿3次時）
  final bool retry;
  final int? wrongCount;
  final int? remainingAttempts;
  final String? errorType;

  ItemAnswerResult({
    required this.isCorrect,
    this.isCompleted = false,
    this.budget,
    this.spentAmount,
    this.purchasedItems,
    this.changeOptions,
    this.nextQuestion,
    this.retry = false,
    this.wrongCount,
    this.remainingAttempts,
    this.errorType,
  });

  factory ItemAnswerResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return ItemAnswerResult(
      isCorrect: data['is_correct'],
      isCompleted: data['is_completed'] ?? false,
      budget: _toIntOrNull(data['budget']),
      spentAmount: _toIntOrNull(data['spent_amount']),
      purchasedItems: data['purchased_items'] != null
          ? (data['purchased_items'] as List)
                .map((e) => PurchasedItem.fromJson(e))
                .toList()
          : null,
      changeOptions: data['change_options'] != null
          ? (data['change_options'] as List).map((e) => _toInt(e)).toList()
          : null,
      nextQuestion: data['next_question'] != null
          ? ShoppingQuestion.fromJson(data['next_question'])
          : null,
      retry: data['retry'] ?? false,
      wrongCount: _toIntOrNull(data['wrong_count']),
      remainingAttempts: _toIntOrNull(data['remaining_attempts']),
      errorType: data['error_type'],
    );
  }

  int get totalSpent {
    if (spentAmount != null) return spentAmount!;
    if (purchasedItems != null) {
      return purchasedItems!.fold(0, (sum, item) => sum + item.price);
    }
    return 0;
  }
}

/// 送出找零答案的回應。
/// 後端重寫計算方式後，答錯時的形狀跟 [ItemAnswerResult] 答錯時一樣
/// （retry/wrong_count/remaining_attempts/error_type，實測過
/// change_too_low 這個值）；完成整場遊戲時（is_completed:true）則多了
/// score/total_correct/first_try_correct_count 這些新欄位——這就是這次
/// 「計算方式重寫」的核心：accuracy 現在是「首次答對率」（first_try_correct_count
/// / total_questions），不是「最終有沒有答對」的正確率，即使10題全部最後都
/// 答對，只要有用到重試，accuracy 就不會是100，score 則是另外算的綜合分數
/// （實測過重試多次的情況：10題全對但只有6題是第一次就對，accuracy=60、
/// score=74，score 明顯比 accuracy 高，代表重試後答對還是有拿到部分分數，
/// 不是像 accuracy 那樣只認第一次）。
class ChangeAnswerResult {
  final bool isCorrect;
  final bool retry; // true = 還可以重試，留在原畫面
  final bool isCompleted;
  final int? accuracy; // 完成時才有值，語意是「首次答對率」，不是最終正確率
  final ShoppingQuestion? nextQuestion;

  /// 答錯時才有意義的欄位（跟 ItemAnswerResult 一樣的形狀）
  final int? wrongCount;
  final int? remainingAttempts;
  final String? errorType;

  /// 完成整場遊戲時（is_completed:true）才有值的新欄位
  final int? score;
  final int? totalCorrect;
  final int? firstTryCorrectCount;
  final int? consecutiveCorrect;
  final bool difficultyUpgraded;

  ChangeAnswerResult({
    required this.isCorrect,
    required this.retry,
    required this.isCompleted,
    this.accuracy,
    this.nextQuestion,
    this.wrongCount,
    this.remainingAttempts,
    this.errorType,
    this.score,
    this.totalCorrect,
    this.firstTryCorrectCount,
    this.consecutiveCorrect,
    this.difficultyUpgraded = false,
  });

  factory ChangeAnswerResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return ChangeAnswerResult(
      isCorrect: data['is_correct'] ?? false,
      retry: data['retry'] ?? false,
      isCompleted: data['is_completed'] ?? false,
      accuracy: _roundToIntOrNull(data['accuracy']),
      nextQuestion: data['next_question'] != null
          ? ShoppingQuestion.fromJson(data['next_question'])
          : null,
      wrongCount: _toIntOrNull(data['wrong_count']),
      remainingAttempts: _toIntOrNull(data['remaining_attempts']),
      errorType: data['error_type'],
      score: _toIntOrNull(data['score']),
      totalCorrect: _toIntOrNull(data['total_correct']),
      firstTryCorrectCount: _toIntOrNull(data['first_try_correct_count']),
      consecutiveCorrect: _toIntOrNull(data['consecutive_correct']),
      difficultyUpgraded: data['difficulty_upgraded'] ?? false,
    );
  }
}

/// 單筆歷史成績紀錄
class HistoryRecord {
  final int score;
  final int accuracy;
  final DateTime playedAt;

  HistoryRecord({
    required this.score,
    required this.accuracy,
    required this.playedAt,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      score: _toInt(json['score']),
      accuracy: _roundToInt(json['accuracy']),
      playedAt: DateTime.parse(json['played_at']),
    );
  }
}

/// 查詢歷史成績的回應（data 直接是陣列，不是 data.records）
class HistoryResult {
  final List<HistoryRecord> records;

  HistoryResult({required this.records});

  factory HistoryResult.fromJson(Map<String, dynamic> json) {
    return HistoryResult(
      records: (json['data'] as List)
          .map((e) => HistoryRecord.fromJson(e))
          .toList(),
    );
  }
}

/// 共用小工具：把後端傳來的數字（不管是 int 或 double）安全轉成 int
int _toInt(dynamic value) => (value as num).toInt();

/// 同上，但允許 null
int? _toIntOrNull(dynamic value) =>
    value != null ? (value as num).toInt() : null;

/// accuracy 這類百分比欄位後端現在給的是 double（例如 60.0、66.67），
/// 用四捨五入而不是直接 toInt() 截斷，避免數字被無聲地壓低
int _roundToInt(dynamic value) => (value as num).round();

int? _roundToIntOrNull(dynamic value) =>
    value != null ? (value as num).round() : null;
