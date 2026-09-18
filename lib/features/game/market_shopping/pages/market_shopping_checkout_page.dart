import 'package:flutter/material.dart';
import '../models/market_shopping_models.dart';
import '../widgets/game_in_progress_top_bar.dart';
import '../../widgets/game_pause.dart';
import '../widgets/market_shopping_tutorial_dialog.dart';
import '../services/sound_player.dart';
import '../../../../screens/notification_screen.dart';
import '../../../../screens/game_home_screen.dart';

class MarketShoppingCheckoutPage extends StatefulWidget {
  final ShoppingQuestion question;
  final ItemAnswerResult itemAnswerResult;
  final Future<ChangeAnswerResult> Function(int selectedAmount) onSubmitAnswer;
  final void Function(ShoppingQuestion nextQuestion) onProceedToNextQuestion;
  final VoidCallback onGameCompleted;
  final VoidCallback onRestart;

  const MarketShoppingCheckoutPage({
    super.key,
    required this.question,
    required this.itemAnswerResult,
    required this.onSubmitAnswer,
    required this.onProceedToNextQuestion,
    required this.onGameCompleted,
    required this.onRestart,
  });

  @override
  State<MarketShoppingCheckoutPage> createState() => _MarketShoppingCheckoutPageState();
}

class _MarketShoppingCheckoutPageState extends State<MarketShoppingCheckoutPage> {
  int? _chosenAmount;
  bool _isSubmitting = false;
  bool _hasAnswered = false;
  ChangeAnswerResult? _result;

  Future<void> _selectOption(int amount) async {
    if (_hasAnswered || _isSubmitting) return;

    SoundPlayer.playClick();
    setState(() {
      _chosenAmount = amount;
      _isSubmitting = true;
    });

    try {
      final result = await widget.onSubmitAnswer(amount);

      setState(() {
        _result = result;
        _hasAnswered = true;
        _isSubmitting = false;
      });

      if (result.isCorrect) {
        SoundPlayer.playCashiering();
      } else {
        SoundPlayer.playWrong();
      }

      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;

      if (result.isCompleted) {
        widget.onGameCompleted();
      } else if (result.retry) {
        setState(() {
          _hasAnswered = false;
          _result = null;
          _chosenAmount = null;
        });
      } else if (result.nextQuestion != null) {
        widget.onProceedToNextQuestion(result.nextQuestion!);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _hasAnswered = false;
        _chosenAmount = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('送出失敗：${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  void _showPauseMenu() {
    GamePause.show(
      context,
      onResume: () {},
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
    final result = widget.itemAnswerResult;
    final changeOptions = result.changeOptions ?? [];

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
                    Text(
                      '第 ${widget.question.currentQuestion} / ${widget.question.totalQuestions} 題',
                      style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(result),
                    const SizedBox(height: 24),
                    const Text('應該要找多少錢？', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ...changeOptions.map((option) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildOptionButton(option),
                        )),
                    if (_hasAnswered && _result?.retry == true)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          '再試一次看看！',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
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

  Widget _buildInfoCard(ItemAnswerResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8DC)),
      ),
      child: Column(
        children: [
          _buildInfoRow('你今天帶了', '${result.budget ?? 0} 元'),
          const Divider(height: 24),
          if (result.purchasedItems != null) ...[
            ...result.purchasedItems!.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildInfoRow(item.foodName, '${item.price} 元', small: true),
                )),
            const Divider(height: 16),
          ] else
            _buildInfoRow('花了', '${result.spentAmount ?? 0} 元'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool small = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: small ? 15 : 18, color: Colors.black87)),
        Text(
          value,
          style: TextStyle(fontSize: small ? 16 : 20, fontWeight: FontWeight.bold, color: const Color(0xFF3D6B4A)),
        ),
      ],
    );
  }

  Widget _buildOptionButton(int option) {
    Color backgroundColor = Colors.white;
    Color borderColor = const Color(0xFFE0E0E0);
    Widget? trailingIcon;

    if (_hasAnswered && _chosenAmount == option) {
      if (_result!.isCorrect) {
        backgroundColor = const Color(0xFFD9F2DF);
        borderColor = const Color(0xFF4CAF50);
        trailingIcon = const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28);
      } else {
        backgroundColor = const Color(0xFFFFE9D6);
        borderColor = const Color(0xFFFF9800);
        trailingIcon = const Icon(Icons.circle, color: Color(0xFFFF9800), size: 24);
      }
    }

    return GestureDetector(
      onTap: () => _selectOption(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$option 元', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (_isSubmitting && _chosenAmount == option)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF5B8A6B)))
            else if (trailingIcon != null)
              trailingIcon,
          ],
        ),
      ),
    );
  }
}