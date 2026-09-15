import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/game_rule.dart';
import '../models/market_sort_item.dart';
import '../models/market_sort_item_pool.dart';
import '../models/market_sort_stage_plan.dart';
import '../models/trial_result.dart';
import '../services/market_sort_answer_judge.dart';

enum QuestionPhase { locked, interactive, resolved }

class MarketSortGameController extends ChangeNotifier {
  MarketSortGameController({Random? random}) : _random = random ?? Random() {
    _pickItemForCurrentQuestion();
  }

  final Random _random;

  final List<GameRule> _flattenedRules = marketSort28QuestionPlan
      .expand((stage) => stage.rules)
      .toList();

  final List<int> _questionStageIndex = marketSort28QuestionPlan
      .asMap()
      .entries
      .expand(
        (entry) => List.filled(entry.value.questionCount, entry.key),
      )
      .toList();

  late final List<int> _stageBoundaryIndices = _computeStageBoundaryIndices();

  List<int> _computeStageBoundaryIndices() {
    final boundaries = <int>[];
    int cumulative = 0;
    for (final stage in marketSort28QuestionPlan) {
      cumulative += stage.questionCount;
      if (cumulative < totalQuestionCount) {
        boundaries.add(cumulative);
      }
    }
    return boundaries;
  }

  int _currentIndex = 0;

  int get displayQuestionNumber => _currentIndex + 1;
  int get totalQuestionCount => _flattenedRules.length;
  GameRule get currentRule => _flattenedRules[_currentIndex];
  GameRule? get previousRule =>
      _currentIndex == 0 ? null : _flattenedRules[_currentIndex - 1];
  bool get isRepeatTrial =>
      previousRule != null && currentRule == previousRule;
  int get currentStageIndex => _questionStageIndex[_currentIndex];
  String get currentStageName =>
      marketSort28QuestionPlan[currentStageIndex].stageName;
  bool get isStageBoundary => _stageBoundaryIndices.contains(_currentIndex);
  bool get isLastQuestion => _currentIndex == totalQuestionCount - 1;

  // ── 出題：依當題規則從對應子題庫抽商品 ──

  late MarketSortItem _currentItem;
  MarketSortItem get currentItem => _currentItem;

  void _pickItemForCurrentQuestion() {
    final availableItems = marketSortItemPool
        .where((item) => !item.isExcludedFor(currentRule))
        .toList();
    _currentItem = availableItems[_random.nextInt(availableItems.length)];
  }

  // ── 單題狀態機與計時 ──

  QuestionPhase _phase = QuestionPhase.locked;
  QuestionPhase get phase => _phase;

  final Stopwatch _stopwatch = Stopwatch();
  int? _lastReactionTimeMs;
  int? get lastReactionTimeMs => _lastReactionTimeMs;

  Timer? _lockedTimer;

  Duration get _lockedDuration {
    if (isRepeatTrial) {
      return const Duration(milliseconds: 300);
    }
    return isStageBoundary
        ? const Duration(seconds: 2)
        : const Duration(seconds: 1);
  }

  void startQuestion({
    VoidCallback? onEnterLocked,
    VoidCallback? onEnterInteractive,
  }) {
    _phase = QuestionPhase.locked;
    _lastReactionTimeMs = null;
    _stopwatch.reset();
    notifyListeners();
    onEnterLocked?.call();

    _lockedTimer?.cancel();
    _lockedTimer = Timer(_lockedDuration, () {
      _phase = QuestionPhase.interactive;
      _stopwatch.start();
      notifyListeners();
      onEnterInteractive?.call();
    });
  }

  // ── 單題判定紀錄的累積 ──

  final List<TrialResult> _results = [];
  List<TrialResult> get results => List.unmodifiable(_results);

  /// 使用者完成拖曳、放進某個籃子時呼叫
  /// [selectedBucketValue] 是長者拖進去的那個籃子代表的屬性值
  /// （例如拖進「水果籃」，這個值就是 ItemCategory.fruit）
  void resolveQuestion(Object selectedBucketValue) {
    if (_phase != QuestionPhase.interactive) return;
    _stopwatch.stop();
    _lastReactionTimeMs = _stopwatch.elapsedMilliseconds;
    _phase = QuestionPhase.resolved;

    final judgement = judgeAnswer(
      item: _currentItem,
      currentRule: currentRule,
      selectedBucketValue: selectedBucketValue,
      trialType: isRepeatTrial ? TrialType.repeat : TrialType.switchType,
      previousRule: previousRule,
    );

    _results.add(
      TrialResult(
        questionIndex: displayQuestionNumber,
        isCorrect: judgement.isCorrect,
        reactionTimeMs: _lastReactionTimeMs!,
        trialType: isRepeatTrial ? TrialType.repeat : TrialType.switchType,
        errorType: judgement.errorType,
      ),
    );

    notifyListeners();
  }

  void moveToNextQuestion() {
    if (isLastQuestion) return;
    _currentIndex++;
    _pickItemForCurrentQuestion();
    startQuestion();
  }

  void reset() {
    _currentIndex = 0;
    _results.clear();
    _lockedTimer?.cancel();
    _pickItemForCurrentQuestion();
  }

  @override
  void dispose() {
    _lockedTimer?.cancel();
    super.dispose();
  }
}