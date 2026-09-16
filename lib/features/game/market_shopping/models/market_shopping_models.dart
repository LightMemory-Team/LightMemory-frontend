/// 一樣食材（後端只給 code 跟中文名，圖片由前端自己對應）
class MarketFood {
  final String foodCode;
  final String foodName;

  MarketFood({required this.foodCode, required this.foodName});

  factory MarketFood.fromJson(Map<String, dynamic> json) {
    return MarketFood(
      foodCode: json['food_code'],
      foodName: json['food_name'],
    );
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
  final int sessionId;
  final ShoppingQuestion firstQuestion;

  GameSession({required this.sessionId, required this.firstQuestion});

  factory GameSession.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return GameSession(
      sessionId: _toInt(data['session_id']),
      firstQuestion: ShoppingQuestion.fromJson(data),
    );
  }
}

/// 送出選菜答案的回應
class ItemAnswerResult {
  final bool isCorrect;
  final bool isCompleted;
  final int? budget;
  final int? spentAmount; // easy/medium 才有
  final List<PurchasedItem>? purchasedItems; // hard 才有
  final List<int>? changeOptions;
  final ShoppingQuestion? nextQuestion; // 選菜錯滿3次跳題時才會有

  ItemAnswerResult({
    required this.isCorrect,
    this.isCompleted = false,
    this.budget,
    this.spentAmount,
    this.purchasedItems,
    this.changeOptions,
    this.nextQuestion,
  });

  factory ItemAnswerResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return ItemAnswerResult(
      isCorrect: data['is_correct'],
      isCompleted: data['is_completed'] ?? false,
      budget: _toIntOrNull(data['budget']),
      spentAmount: _toIntOrNull(data['spent_amount']),
      purchasedItems: data['purchased_items'] != null
          ? (data['purchased_items'] as List).map((e) => PurchasedItem.fromJson(e)).toList()
          : null,
      changeOptions: data['change_options'] != null
          ? (data['change_options'] as List).map((e) => _toInt(e)).toList()
          : null,
      nextQuestion: data['next_question'] != null
          ? ShoppingQuestion.fromJson(data['next_question'])
          : null,
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

/// 送出找零答案的回應
class ChangeAnswerResult {
  final bool isCorrect;
  final bool retry; // true = 還可以重試，留在原畫面
  final bool isCompleted;
  final int? accuracy;
  final ShoppingQuestion? nextQuestion;

  ChangeAnswerResult({
    required this.isCorrect,
    required this.retry,
    required this.isCompleted,
    this.accuracy,
    this.nextQuestion,
  });

  factory ChangeAnswerResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return ChangeAnswerResult(
      isCorrect: data['is_correct'] ?? false,
      retry: data['retry'] ?? false,
      isCompleted: data['is_completed'] ?? false,
      accuracy: _toIntOrNull(data['accuracy']),
      nextQuestion: data['next_question'] != null
          ? ShoppingQuestion.fromJson(data['next_question'])
          : null,
    );
  }
}

/// 共用小工具：把後端傳來的數字（不管是 int 或 double）安全轉成 int
int _toInt(dynamic value) => (value as num).toInt();

/// 同上，但允許 null
int? _toIntOrNull(dynamic value) => value != null ? (value as num).toInt() : null;