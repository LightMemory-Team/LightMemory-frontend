import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/services/audio_service.dart';
import '../features/game/market_sort/models/game_rule.dart';
import '../features/game/market_sort/models/market_sort_item.dart';
import '../features/game/market_sort/models/market_sort_item_attributes.dart';
import '../features/game/market_sort/controllers/market_sort_game_controller.dart';
import '../features/game/market_sort/widgets/market_sort_top_bar.dart';
import '../features/game/market_sort/widgets/game_progress_header.dart';
import '../features/game/market_sort/widgets/rule_badge.dart';
import '../features/game/market_sort/widgets/product_card.dart';
import '../features/game/market_sort/widgets/basket_row.dart';
import '../features/game/market_sort/widgets/countdown_digit.dart';
import '../features/game/market_sort/widgets/pause_modal.dart';
import '../features/game/market_sort/widgets/tutorial_modal.dart';

class MarketSortGameScreen extends StatefulWidget {
  const MarketSortGameScreen({super.key});

  @override
  State<MarketSortGameScreen> createState() => _MarketSortGameScreenState();
}

class _MarketSortGameScreenState extends State<MarketSortGameScreen> {
  late final MarketSortGameController _controller;

  int? _countdownNumber = 3;
  bool _showPause = false;
  bool _showTutorial = false;

  Object? _flashBucketValue;
  bool? _flashIsCorrect;

  bool _isIdle = false;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _controller = MarketSortGameController();
    _startCountdown();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startCountdown() async {
    for (final n in [3, 2, 1]) {
      if (!mounted) return;
      setState(() => _countdownNumber = n);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() => _countdownNumber = null);
    _startCurrentQuestion();
  }

  void _startCurrentQuestion() {
    _controller.startQuestion(
      onEnterLocked: _handleEnterLocked,
      onEnterInteractive: _handleEnterInteractive,
    );
  }

  void _handleEnterLocked() {
    _idleTimer?.cancel();
    if (_isIdle) setState(() => _isIdle = false);
    if (_controller.previousRule != null && !_controller.isRepeatTrial) {
      AudioService.play('change.mp3');
    }
  }

  void _handleEnterInteractive() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _isIdle = true);
    });
  }

  void _handleDragStarted() {
    _idleTimer?.cancel();
    if (_isIdle) setState(() => _isIdle = false);
  }

  void _handleDropped(MarketSortItem item, Object bucketValue) {
    if (_controller.phase != QuestionPhase.interactive) return;

    _idleTimer?.cancel();
    _controller.resolveQuestion(bucketValue);
    final isCorrect = _controller.results.last.isCorrect;

    AudioService.play(isCorrect ? 'correct.mp3' : 'no.mp3');

    setState(() {
      _flashBucketValue = bucketValue;
      _flashIsCorrect = isCorrect;
      _isIdle = false;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _flashBucketValue = null;
        _flashIsCorrect = null;
      });

      if (_controller.isLastQuestion) {
        // TODO(階段5)：導去結算頁，這裡先佔位直接返回上一頁
        Navigator.of(context).pop();
      } else {
        _controller.moveToNextQuestion();
        _startCurrentQuestion();
      }
    });
  }

  List<BasketOption?> _basketsForRule(GameRule rule) {
    switch (rule) {
      case GameRule.species:
        return [
          BasketOption(
            label: ItemCategory.vegetable.label,
            emoji: '🥬',
            color: const Color(0xFF5B9E87),
            value: ItemCategory.vegetable,
          ),
          BasketOption(
            label: ItemCategory.fruit.label,
            emoji: '🍎',
            color: const Color(0xFFE8825A),
            value: ItemCategory.fruit,
          ),
          BasketOption(
            label: ItemCategory.meatEgg.label,
            emoji: '🍗',
            color: const Color(0xFFC0694F),
            value: ItemCategory.meatEgg,
          ),
        ];
      case GameRule.color:
        return [
          BasketOption(
            label: '紅色',
            emoji: '🔴',
            color: Colors.red.shade400,
            value: ItemColor.red,
          ),
          BasketOption(
            label: '綠色',
            emoji: '🟢',
            color: const Color(0xFF5B9E87),
            value: ItemColor.green,
          ),
          BasketOption(
            label: '黃色',
            emoji: '🟡',
            color: Colors.amber.shade600,
            value: ItemColor.yellow,
          ),
        ];
      case GameRule.freshness:
        return [
          BasketOption(
            label: ItemFreshness.raw.label,
            emoji: '🥗',
            color: const Color(0xFF5B9E87),
            value: ItemFreshness.raw,
          ),
          null,
          BasketOption(
            label: ItemFreshness.cooked.label,
            emoji: '🍳',
            color: const Color(0xFFE8825A),
            value: ItemFreshness.cooked,
          ),
        ];
    }
  }

  void _openPause() {
    AudioService.stopAll();
    _idleTimer?.cancel();
    setState(() => _showPause = true);
  }

  void _resumeWithCountdown() {
    setState(() {
      _showPause = false;
      _showTutorial = false;
      _isIdle = false;
    });
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    if (_countdownNumber != null) {
      return CountdownDigit(number: _countdownNumber!);
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final item = _controller.currentItem;
                final isInteractive =
                    _controller.phase == QuestionPhase.interactive;

                return AbsorbPointer(
                  absorbing: !isInteractive,
                  child: Column(
                    children: [
                      MarketSortTopBar(
                        onBackTap: _openPause,
                        onNotificationTap: () {
                          // TODO: 串接通知頁
                        },
                      ),
                      GameProgressHeader(
                        currentQuestionNumber:
                            _controller.displayQuestionNumber,
                        totalQuestionCount: _controller.totalQuestionCount,
                      ),
                      const SizedBox(height: 24),
                      Center(child: RuleBadge(rule: _controller.currentRule)),
                      const SizedBox(height: 32),
                      Draggable<MarketSortItem>(
                        data: item,
                        dragAnchorStrategy: pointerDragAnchorStrategy,
                        onDragStarted: _handleDragStarted,
                        feedback: Material(
                          color: Colors.transparent,
                          child: ProductCard(item: item),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: ProductCard(item: item),
                        ),
                        child: ProductCard(
                          item: item,
                          isIdle: _isIdle,
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: BasketRow(
                          options: _basketsForRule(_controller.currentRule),
                          onAccept: _handleDropped,
                          highlightValue: _flashBucketValue,
                          highlightIsCorrect: _flashIsCorrect,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_showPause)
              PauseModal(
                onResume: _resumeWithCountdown,
                onTutorial: () => setState(() {
                  _showPause = false;
                  _showTutorial = true;
                }),
                onRestart: () {
                  AudioService.stopAll();
                  _controller.reset();
                  setState(() => _showPause = false);
                  _startCountdown();
                },
                onExit: () {
                  AudioService.stopAll();
                  // TODO(階段5)：呼叫API標記is_complete=false
                  Navigator.of(context).pop();
                },
              ),
            if (_showTutorial)
              TutorialModal(
                onClose: _resumeWithCountdown,
                onStartGame: _resumeWithCountdown,
              ),
          ],
        ),
      ),
    );
  }
}