import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_rule.dart';
import '../models/market_sort_stage_plan.dart';

/// 單題生命週期的三個狀態（對應設計文件第三節）
enum QuestionPhase { locked, interactive, resolved }

class MarketSortGameController extends ChangeNotifier {
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

  // ── 以下是這次新增的狀態機與計時部分 ──

  QuestionPhase _phase = QuestionPhase.locked;
  QuestionPhase get phase => _phase;

  final Stopwatch _stopwatch = Stopwatch();
  int? _lastReactionTimeMs;
  int? get lastReactionTimeMs => _lastReactionTimeMs;

  Timer? _lockedTimer;

  /// locked狀態要鎖多久：
  /// - repeat題：0.3秒極短緩衝
  /// - switch題、非階段邊界（第四階段題內切換）：1秒
  /// - switch題、階段邊界：2秒（見上方說明，3秒動畫由畫面層自行疊加）
  Duration get _lockedDuration {
    if (isRepeatTrial) {
      return const Duration(milliseconds: 300);
    }
    return isStageBoundary
        ? const Duration(seconds: 2)
        : const Duration(seconds: 1);
  }

  /// 開始這一題的生命週期：進入locked，計時結束後自動轉interactive並啟動碼表
  /// [onEnterLocked] 讓畫面層知道要不要播放規則切換音效（switch題才需要），
  /// controller本身不直接依賴AudioService，職責保持單純。
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

  /// 使用者完成拖曳判定時呼叫，記錄reaction_time_ms並轉入resolved
  /// 只有interactive狀態才允許判定，防呆擋掉locked狀態誤觸的情況
  /// （對應文件要求：規則提示還沒結束時要disable手勢偵測層）
  void resolveQuestion() {
    if (_phase != QuestionPhase.interactive) return;
    _stopwatch.stop();
    _lastReactionTimeMs = _stopwatch.elapsedMilliseconds;
    _phase = QuestionPhase.resolved;
    notifyListeners();
  }

  void moveToNextQuestion() {
    if (isLastQuestion) return;
    _currentIndex++;
    startQuestion();
  }

  void reset() {
    _currentIndex = 0;
    _lockedTimer?.cancel();
  }

  @override
  void dispose() {
    _lockedTimer?.cancel();
    super.dispose();
  }
}