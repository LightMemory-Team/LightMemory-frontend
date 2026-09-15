import 'package:flutter/foundation.dart';
import '../models/game_rule.dart';
import '../models/market_sort_stage_plan.dart';

/// 整理菜籃遊戲的流程控制器
///
/// 這一版處理「題號、規則、所屬大階段」怎麼推進。
/// 計時、單題狀態機、出題（抽哪個商品）留到後面幾步再加上去。
class MarketSortGameController extends ChangeNotifier {
  final List<GameRule> _flattenedRules = marketSort28QuestionPlan
      .expand((stage) => stage.rules)
      .toList();

  // 每一題對應到第幾個大階段（0=生熟, 1=種類, 2=顏色, 3=隨機混合）
  // 用階段本身的題數結構算出來，不依賴規則是否相同，避免巧合誤判。
  final List<int> _questionStageIndex = marketSort28QuestionPlan
      .asMap()
      .entries
      .expand(
        (entry) => List.filled(entry.value.questionCount, entry.key),
      )
      .toList();

  // 三個大階段邊界各自是第幾題（0-based），依累計題數算出來：
  // 生熟5題結束→索引5是邊界；種類接著5題結束→索引10是邊界；
  // 顏色接著5題結束→索引15是邊界（進入隨機混合）。
  late final List<int> _stageBoundaryIndices = _computeStageBoundaryIndices();

  List<int> _computeStageBoundaryIndices() {
    final boundaries = <int>[];
    int cumulative = 0;
    for (final stage in marketSort28QuestionPlan) {
      cumulative += stage.questionCount;
      if (cumulative < totalQuestionCount) {
        boundaries.add(cumulative); // 這個階段結束、下一階段開始的那一題
      }
    }
    return boundaries;
  }

  int _currentIndex = 0; // 0-based，內部使用；對外顯示題號時要 +1

  int get displayQuestionNumber => _currentIndex + 1;

  int get totalQuestionCount => _flattenedRules.length;

  GameRule get currentRule => _flattenedRules[_currentIndex];

  GameRule? get previousRule =>
      _currentIndex == 0 ? null : _flattenedRules[_currentIndex - 1];

  /// 這一題跟上一題規則是否相同：true=repeat，false=switch
  /// 對應 trial_type，純粹比較規則本身，跟屬於哪個大階段無關
  bool get isRepeatTrial =>
      previousRule != null && currentRule == previousRule;

  int get currentStageIndex => _questionStageIndex[_currentIndex];

  String get currentStageName =>
      marketSort28QuestionPlan[currentStageIndex].stageName;

  /// 是否為三個大階段邊界之一（一→二、二→三、三→四這幾題的第一題）
  /// 直接查表，不再用「規則是否相同」去猜
  bool get isStageBoundary => _stageBoundaryIndices.contains(_currentIndex);

  bool get isLastQuestion => _currentIndex == totalQuestionCount - 1;

  void moveToNextQuestion() {
    if (isLastQuestion) return;
    _currentIndex++;
    notifyListeners();
  }

  void reset() {
    _currentIndex = 0;
    notifyListeners();
  }
}