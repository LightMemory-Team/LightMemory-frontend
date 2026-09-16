import 'dart:async';
import 'package:flutter/material.dart';
import '../models/market_shopping_models.dart';
import '../widgets/game_in_progress_top_bar.dart';
import '../widgets/game_pause.dart';
import '../widgets/market_shopping_tutorial_dialog.dart';
import '../services/sound_player.dart';
import '../../../../screens/notification_screen.dart';
import '../../../../screens/game_home_screen.dart';

class MarketShoppingMemorizePage extends StatefulWidget {
  final ShoppingQuestion question;
  final VoidCallback onTimeUp;
  final VoidCallback onRestart;

  const MarketShoppingMemorizePage({
    super.key,
    required this.question,
    required this.onTimeUp,
    required this.onRestart,
  });

  @override
  State<MarketShoppingMemorizePage> createState() => _MarketShoppingMemorizePageState();
}

class _MarketShoppingMemorizePageState extends State<MarketShoppingMemorizePage>
    with SingleTickerProviderStateMixin {
  static const int _totalSeconds = 10;
  late final AnimationController _controller;
  bool _hasProceeded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _totalSeconds),
    )..forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _proceed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _proceed() {
    if (_hasProceeded) return;
    _hasProceeded = true;
    widget.onTimeUp();
  }

  void _showPauseMenu() {
    _controller.stop();
    GamePause.show(
      context,
      onResume: () => _controller.forward(),
      onTutorial: () => MarketShoppingTutorialDialog.show(context),
      onRestart: () {
        widget.onRestart();
      },
      onExit: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const GameHomeScreen()),
          (route) => false,
        );
      },
    );
  }

  void _goToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      body: SafeArea(
        child: Column(
          children: [
            GameInProgressTopBar(
              title: '市場買菜',
              onPauseTap: _showPauseMenu,
              onNotificationTap: _goToNotifications,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      '第 ${widget.question.currentQuestion} / ${widget.question.totalQuestions} 題',
                      style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '請記住購物清單',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3D6B4A)),
                    ),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: 1 - _controller.value,
                            minHeight: 12,
                            backgroundColor: const Color(0xFFE0E0E0),
                            color: const Color(0xFF5B8A6B),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemCount: widget.question.shoppingList.length,
                        itemBuilder: (context, index) {
                          final food = widget.question.shoppingList[index];
                          return _buildItemCard(food);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF5B8A6B), width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () {
                          SoundPlayer.playClick();
                          _proceed();
                        },
                        child: const Text(
                          '我記住了！',
                          style: TextStyle(fontSize: 18, color: Color(0xFF5B8A6B), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(MarketFood food) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD2A679), Color(0xFFB07D4F), Color(0xFF8B5E34)],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: const Color(0xFF6B4423), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Image.asset(
              food.imagePath,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.black26),
            ),
          ),
          const SizedBox(height: 8),
          Text(food.foodName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}