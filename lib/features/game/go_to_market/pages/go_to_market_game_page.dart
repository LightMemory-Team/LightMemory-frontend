import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/go_to_market_model.dart';
import '../services/audio_service.dart';
import '../services/go_to_market_service.dart';
import '../widgets/market_result_dialog.dart';
import '../../widgets/game_pause.dart';
import 'go_to_market_tutorial_page.dart';

class GoToMarketGamePage extends StatefulWidget {
  const GoToMarketGamePage({super.key});

  @override
  State createState() => _GoToMarketGamePageState();
}

class _GoToMarketGamePageState extends State with WidgetsBindingObserver {
  final int totalQuestions = 20;
  int currentQuestionNumber = 1;
  int attemptNumber = 1;

  int? sessionId;
  String currentStage = 'basic';
  int correctStreak = 0;
  int wrongStreak = 0;
  int correctCount = 0;
  int totalScoreAccumulated = 0;

  int exposureTimeMs = 2000;
  bool isExposing = true;
  bool canAnswer = false;
  int _remainingSeconds = 20;
  Timer? _exposureTimer;
  Timer? _countdownTimer;

  DateTime? _questionStartTime;
  final List _reactionTimes = [];

  DateTime? _pausedStartTime;
  int _totalPausedMsThisRound = 0;
  bool _isPauseDialogOpen = false;

  String? feedbackState;
  String? lastUserClickedPosition;

  MarketRoundData? currentRound;

  String get levelTitle {
    switch (currentStage) {
      case 'intermediate':
        return '中等難度';
      case 'advanced':
        return '高階難度';
      case 'basic':
      default:
        return '簡單難度';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startNewGameSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _exposureTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedStartTime = DateTime.now();
      _pauseTimers();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedStartTime != null) {
        final pausedMs = DateTime.now()
            .difference(_pausedStartTime!)
            .inMilliseconds;
        _totalPausedMsThisRound += pausedMs;
        _pausedStartTime = null;
      }
      if (!_isPauseDialogOpen && mounted) {
        _showPauseDialog();
      }
    }
  }

  void _pauseTimers() {
    _exposureTimer?.cancel();
    _countdownTimer?.cancel();
  }

  void _resumeTimers() {
    if (isExposing) {
      _startExposure();
    } else if (canAnswer) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_remainingSeconds > 1) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          _handleAnswer(userPosition: null, isTimeout: true);
        }
      });
    }
  }

  void _showPauseDialog() {
    _isPauseDialogOpen = true;
    _pauseTimers();

    GamePause.show(
      context,
      onResume: () {
        AudioService.playClick();
        _isPauseDialogOpen = false;
        _resumeTimers();
      },
      onTutorial: () {
        AudioService.playClick();
        _isPauseDialogOpen = false;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const GoToMarketTutorialPage(),
          ),
        );
      },
      onRestart: () {
        AudioService.playClick();
        _isPauseDialogOpen = false;
        _resetGame();
      },
      onExit: () {
        AudioService.playClick();
        _isPauseDialogOpen = false;
        Navigator.of(context).pop();
      },
    );
  }

  void _resetGame() {
    setState(() {
      currentQuestionNumber = 1;
      attemptNumber = 1;
      correctCount = 0;
      correctStreak = 0;
      wrongStreak = 0;
      totalScoreAccumulated = 0;
      currentStage = 'basic';
      exposureTimeMs = 2000;
      _reactionTimes.clear();
      _startNewGameSession();
    });
  }

  Future _startNewGameSession() async {
    sessionId = await GoToMarketService.startGame();
    await _loadRound();
  }

  Future _loadRound() async {
    MarketRoundData? round;
    if (sessionId != null) {
      round = await GoToMarketService.fetchRound(sessionId: sessionId!);
    }
    round ??= _generateLocalRound(
      currentQuestionNumber,
      currentStage,
      exposureTimeMs,
    );

    if (!mounted) return;
    setState(() {
      currentRound = round;
      exposureTimeMs = round!.exposureTimeMs;
      attemptNumber = 1;
      feedbackState = null;
      lastUserClickedPosition = null;
      _totalPausedMsThisRound = 0;
    });

    _startExposure();
  }

  MarketRoundData _generateLocalRound(
    int qNum,
    String stage,
    int currentExpMs,
  ) {
    final quadrants = ['q1', 'q2', 'q3', 'q4'];
    final random = Random();

    if (stage == 'basic') {
      return MarketRoundData(
        questionNumber: qNum,
        stage: 'basic',
        targetItem: '魚',
        targetPosition: 'center',
        distractorItems: [],
        exposureTimeMs: currentExpMs.clamp(1500, 2000),
      );
    } else if (stage == 'intermediate') {
      final target = quadrants[random.nextInt(quadrants.length)];
      return MarketRoundData(
        questionNumber: qNum,
        stage: 'intermediate',
        targetItem: '魚',
        targetPosition: target,
        distractorItems: [],
        exposureTimeMs: currentExpMs.clamp(1000, 1500),
      );
    } else {
      final target = quadrants[random.nextInt(quadrants.length)];
      final remainingQuadrants = quadrants.where((q) => q != target).toList();
      final distractor =
          remainingQuadrants[random.nextInt(remainingQuadrants.length)];

      return MarketRoundData(
        questionNumber: qNum,
        stage: 'advanced',
        targetItem: '魚',
        targetPosition: target,
        distractorItems: [
          {'item': '魚骨頭', 'position': distractor},
        ],
        exposureTimeMs: currentExpMs.clamp(500, 1000),
      );
    }
  }

  void _startExposure() {
    _exposureTimer?.cancel();
    _countdownTimer?.cancel();

    setState(() {
      isExposing = true;
      canAnswer = false;
      feedbackState = null;
      _remainingSeconds = 20;
    });

    _exposureTimer = Timer(Duration(milliseconds: exposureTimeMs), () {
      if (!mounted) return;
      setState(() {
        isExposing = false;
        canAnswer = true;
        _questionStartTime = DateTime.now();
      });

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_remainingSeconds > 1) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          _handleAnswer(userPosition: null, isTimeout: true);
        }
      });
    });
  }

  Future _handleAnswer({
    required String? userPosition,
    bool isTimeout = false,
  }) async {
    if (!canAnswer) return;
    _countdownTimer?.cancel();

    final now = DateTime.now();
    final rawReactionMs = _questionStartTime != null
        ? now.difference(_questionStartTime!).inMilliseconds
        : 20000;
    final finalReactionMs = (rawReactionMs - _totalPausedMsThisRound).clamp(
      0,
      30000,
    );
    _reactionTimes.add(finalReactionMs);

    final isCorrect = (userPosition == currentRound?.targetPosition);

    setState(() {
      canAnswer = false;
      lastUserClickedPosition = userPosition;
    });

    MarketAnswerResponse? response;
    if (sessionId != null) {
      response = await GoToMarketService.submitAnswer(
        sessionId: sessionId!,
        questionNumber: currentQuestionNumber,
        attemptNumber: attemptNumber,
        answerPosition: userPosition,
        isTimeout: isTimeout,
        responseTimeMs: finalReactionMs,
        pausedDurationMs: _totalPausedMsThisRound,
      );
    }

    // 防禦性檢查：API 失敗或 API 與實際點擊不符時強制走本地邏輯
    if (response == null || isCorrect != response.isCorrect) {
      response = _generateLocalAnswerResponse(
        isCorrect,
        isTimeout,
        finalReactionMs,
      );
    }

    _applyAnswerResponse(response, isCorrect, isTimeout);
  }

  MarketAnswerResponse _generateLocalAnswerResponse(
    bool isCorrect,
    bool isTimeout,
    int reactionMs,
  ) {
    final bool isLastQuestion = (currentQuestionNumber >= totalQuestions);

    if (isCorrect) {
      final newCorrectStreak = correctStreak + 1;

      int baseScore = (attemptNumber == 1) ? 10 : (attemptNumber == 2 ? 6 : 3);
      double multiplier = (currentStage == 'advanced')
          ? 1.6
          : (currentStage == 'intermediate' ? 1.3 : 1.0);
      int speedBonus = (reactionMs <= (exposureTimeMs * 0.5)) ? 2 : 0;
      int scoreEarned = (baseScore * multiplier).round() + speedBonus;

      if (newCorrectStreak >= 5 && currentStage != 'advanced') {
        final nextStage = (currentStage == 'basic')
            ? 'intermediate'
            : 'advanced';
        return MarketAnswerResponse(
          isCorrect: true,
          action: isLastQuestion ? 'finished' : 'promoted',
          currentStage: nextStage,
          correctStreak: 0,
          wrongAttempts: 0,
          scoreEarned: scoreEarned,
        );
      }

      return MarketAnswerResponse(
        isCorrect: true,
        action: isLastQuestion ? 'finished' : 'next_question',
        currentStage: currentStage,
        correctStreak: newCorrectStreak,
        wrongAttempts: 0,
        scoreEarned: scoreEarned,
      );
    } else {
      final newWrongStreak = wrongStreak + 1;

      if (newWrongStreak >= 5 && currentStage != 'basic') {
        final prevStage = (currentStage == 'advanced')
            ? 'intermediate'
            : 'basic';
        return MarketAnswerResponse(
          isCorrect: false,
          action: isLastQuestion ? 'finished' : 'demoted',
          currentStage: prevStage,
          correctStreak: 0,
          wrongAttempts: attemptNumber,
          scoreEarned: 0,
        );
      }

      if (attemptNumber >= 3 || isLastQuestion || isTimeout) {
        return MarketAnswerResponse(
          isCorrect: false,
          action: isLastQuestion ? 'finished' : 'next_question',
          currentStage: currentStage,
          correctStreak: 0,
          wrongAttempts: attemptNumber,
          scoreEarned: 0,
        );
      }

      return MarketAnswerResponse(
        isCorrect: false,
        action: 'retry',
        currentStage: currentStage,
        correctStreak: 0,
        wrongAttempts: attemptNumber,
        scoreEarned: 0,
      );
    }
  }

  void _applyAnswerResponse(
    MarketAnswerResponse response,
    bool isCorrect,
    bool isTimeout,
  ) {
    setState(() {
      currentStage = response.currentStage;
      correctStreak = response.correctStreak;
      totalScoreAccumulated += response.scoreEarned;

      if (response.action == 'promoted' || response.action == 'demoted') {
        wrongStreak = 0;
        if (currentStage == 'basic') exposureTimeMs = 2000;
        if (currentStage == 'intermediate') exposureTimeMs = 1500;
        if (currentStage == 'advanced') exposureTimeMs = 1000;
      } else if (isCorrect) {
        wrongStreak = 0;
        int lowerBound = (currentStage == 'basic')
            ? 1500
            : (currentStage == 'intermediate' ? 1000 : 500);
        exposureTimeMs = max(lowerBound, exposureTimeMs - 100);
      } else {
        wrongStreak++;
        int upperBound = (currentStage == 'basic')
            ? 2000
            : (currentStage == 'intermediate' ? 1500 : 1000);
        exposureTimeMs = min(upperBound, exposureTimeMs + 150);
      }
    });

    if (isCorrect) {
      AudioService.playCorrect();
      correctCount++;
      setState(() {
        feedbackState = 'correct';
      });

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        if (currentQuestionNumber >= totalQuestions ||
            response.action == 'finished') {
          _showGameSummary();
        } else if (response.action == 'promoted') {
          _showLevelTransitionDialog(isPromoted: true);
        } else {
          _proceedToNextQuestion();
        }
      });
    } else {
      AudioService.playWrong();
      setState(() {
        feedbackState = 'wrong';
      });

      if (attemptNumber < 3 && !isTimeout && response.action == 'retry') {
        // 尚未滿 3 次，等待使用者按「重看一次」按鈕
      } else {
        // 滿 3 次答錯、超時或最後一題，跳下一題
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          if (currentQuestionNumber >= totalQuestions ||
              response.action == 'finished') {
            _showGameSummary();
          } else if (response.action == 'demoted') {
            _showLevelTransitionDialog(isPromoted: false);
          } else {
            _proceedToNextQuestion();
          }
        });
      }
    }
  }

  void _proceedToNextQuestion() {
    if (currentQuestionNumber < totalQuestions) {
      setState(() {
        currentQuestionNumber++;
      });
      _loadRound();
    } else {
      _showGameSummary();
    }
  }

  void _showLevelTransitionDialog({required bool isPromoted}) {
    if (isPromoted) {
      AudioService.playLevelUp();
    } else {
      AudioService.playClick();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF7F9F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPromoted ? Icons.stars_rounded : Icons.info_outline_rounded,
                color: isPromoted
                    ? const Color(0xFFE5A93C)
                    : const Color(0xFF4C7B5D),
                size: 80,
              ),
              const SizedBox(height: 12),
              Text(
                isPromoted ? '表現優異！難度升級！' : '節奏調整！進入更合適的難度',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5A43),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '目前階段為【' + levelTitle + '】\n閃現時間已調整為寬鬆模式，準備好迎接下一題！',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Color(0xFF4C5E53)),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5A43),
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                AudioService.playClick();
                Navigator.of(context).pop();
                _proceedToNextQuestion();
              },
              child: const Text(
                '進入下一題',
                style: TextStyle(
                  fontSize: 19,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future _showGameSummary() async {
    int finalScore = totalScoreAccumulated;

    if (sessionId != null) {
      final finishRes = await GoToMarketService.finishGame(
        sessionId: sessionId!,
      );
      if (finishRes != null) {
        finalScore = finishRes.totalScore;
      }
    }

    final List history = [];
    int highestScore = finalScore;

    try {
      final prefs = await SharedPreferences.getInstance();
      final List? savedList = prefs.getStringList('market_score_list');

      if (savedList != null && savedList.isNotEmpty) {
        for (final item in savedList) {
          final val = int.tryParse(item);
          if (val != null) history.add(val);
        }
      }

      history.add(finalScore);
      while (history.length > 5) {
        history.removeAt(0);
      }

      await prefs.setStringList(
        'market_score_list',
        history.map((e) => e.toString()).toList(),
      );

      final storedHighest = prefs.getInt('market_highest_score') ?? 0;
      highestScore = storedHighest > finalScore ? storedHighest : finalScore;
      await prefs.setInt('market_highest_score', highestScore);
    } catch (e) {
      debugPrint('❌ 本地紀錄儲存失敗: ' + e.toString());
      history.clear();
      history.add(finalScore);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return MarketResultDialog(
          currentScore: finalScore,
          highestScore: highestScore,
          history: List.from(history),
          onPlayAgain: _resetGame,
          onExit: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  Widget _buildFishImage() {
    return Image.asset(
      'assets/images/fish.png',
      width: 240,
      height: 82,
      fit: BoxFit.contain,
    );
  }

  Widget _buildFishBoneImage() {
    return Image.asset(
      'assets/images/fish_bone.png',
      width: 150,
      height: 85,
      fit: BoxFit.contain,
    );
  }

  Widget _buildCheckMark() {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF3F6851),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentRound == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9F6),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2D5A43)),
        ),
      );
    }

    final targetPos = currentRound!.targetPosition;
    final distractorList = currentRound!.distractorItems;
    final bool showObjects = isExposing || feedbackState != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      body: Stack(
        children: [
          if (feedbackState == 'correct')
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.95,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF3B7252).withOpacity(0.08),
                        const Color(0xFF2F6646).withOpacity(0.32),
                      ],
                      stops: const [0.65, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          if (feedbackState == 'wrong')
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.95,
                      colors: [
                        Colors.transparent,
                        const Color(0xFFF58A61).withOpacity(0.10),
                        const Color(0xFFEB6B42).withOpacity(0.35),
                      ],
                      stops: const [0.65, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 12.0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF2D5A43),
                          size: 34,
                        ),
                        onPressed: () {
                          AudioService.playClick();
                          _showPauseDialog();
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.help_outline_rounded,
                          color: Color(0xFF2D5A43),
                          size: 30,
                        ),
                        tooltip: '遊戲說明',
                        onPressed: () {
                          AudioService.playClick();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const GoToMarketTutorialPage(),
                            ),
                          );
                        },
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            '來去菜市場',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D5A43),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 80),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EFE9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          levelTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D5A43),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        currentQuestionNumber.toString() +
                            ' / ' +
                            totalQuestions.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5A43),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: currentQuestionNumber / totalQuestions,
                            backgroundColor: const Color(0xFFDDE5DF),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF2D5A43),
                            ),
                            minHeight: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 700,
                    height: 310,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 680,
                          height: 4.0,
                          color: const Color(0xFF6B8775),
                        ),
                        Container(
                          width: 4.0,
                          height: 300,
                          color: const Color(0xFF6B8775),
                        ),
                        if (showObjects) ...[
                          if (targetPos == 'center') _buildFishImage(),
                          if (targetPos == 'q1')
                            Positioned(
                              top: 15,
                              right: 40,
                              child: _buildFishImage(),
                            ),
                          if (targetPos == 'q2')
                            Positioned(
                              top: 15,
                              left: 40,
                              child: _buildFishImage(),
                            ),
                          if (targetPos == 'q3')
                            Positioned(
                              bottom: 12,
                              left: 40,
                              child: _buildFishImage(),
                            ),
                          if (targetPos == 'q4')
                            Positioned(
                              bottom: 12,
                              right: 40,
                              child: _buildFishImage(),
                            ),
                          for (final d in distractorList) ...[
                            if (d['position'] == 'q1')
                              Positioned(
                                top: 15,
                                right: 60,
                                child: _buildFishBoneImage(),
                              ),
                            if (d['position'] == 'q2')
                              Positioned(
                                top: 15,
                                left: 60,
                                child: _buildFishBoneImage(),
                              ),
                            if (d['position'] == 'q3')
                              Positioned(
                                bottom: 12,
                                left: 60,
                                child: _buildFishBoneImage(),
                              ),
                            if (d['position'] == 'q4')
                              Positioned(
                                bottom: 12,
                                right: 60,
                                child: _buildFishBoneImage(),
                              ),
                          ],
                        ],
                        if (feedbackState == 'correct') _buildCheckMark(),
                        if (canAnswer) ...[
                          GestureDetector(
                            onTap: () => _handleAnswer(userPosition: 'center'),
                            behavior: HitTestBehavior.opaque,
                            child: const SizedBox(width: 140, height: 140),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            child: GestureDetector(
                              onTap: () => _handleAnswer(userPosition: 'q2'),
                              behavior: HitTestBehavior.opaque,
                              child: const SizedBox(width: 340, height: 150),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _handleAnswer(userPosition: 'q1'),
                              behavior: HitTestBehavior.opaque,
                              child: const SizedBox(width: 340, height: 150),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: GestureDetector(
                              onTap: () => _handleAnswer(userPosition: 'q3'),
                              behavior: HitTestBehavior.opaque,
                              child: const SizedBox(width: 340, height: 150),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _handleAnswer(userPosition: 'q4'),
                              behavior: HitTestBehavior.opaque,
                              child: const SizedBox(width: 340, height: 150),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isExposing
                        ? '注意看！記住魚出現的位置！'
                        : (feedbackState == 'wrong'
                              ? '答錯囉！請看魚的正確位置'
                              : (feedbackState == 'correct'
                                    ? '太棒了！答對了！'
                                    : '請點擊剛剛魚出現的位置！')),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2D24),
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  if (feedbackState == 'wrong' && attemptNumber < 3)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC0D8CC),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 44,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        AudioService.playClick();
                        setState(() {
                          attemptNumber++;
                        });
                        _startExposure();
                      },
                      child: const Text(
                        '重看一次',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5A43),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 52),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
