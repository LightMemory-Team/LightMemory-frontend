import 'package:flutter/material.dart';
import '../models/market_shopping_models.dart';
import '../widgets/game_in_progress_top_bar.dart';
import '../../widgets/game_pause.dart';
import '../widgets/market_shopping_tutorial_dialog.dart';
import '../services/sound_player.dart';
import '../../../../screens/notification_screen.dart';
import '../../../../screens/game_home_screen.dart';

class MarketShoppingPlayPage extends StatefulWidget {
  final ShoppingQuestion question;
  final Future<ItemAnswerResult> Function(List<MarketFood> selectedFoods) onSubmitAnswer;
  final VoidCallback onProceedToCheckout;
  final VoidCallback onRestart;

  const MarketShoppingPlayPage({
    super.key,
    required this.question,
    required this.onSubmitAnswer,
    required this.onProceedToCheckout,
    required this.onRestart,
  });

  @override
  State<MarketShoppingPlayPage> createState() => _MarketShoppingPlayPageState();
}

class _MarketShoppingPlayPageState extends State<MarketShoppingPlayPage> {
  final Set<String> _selectedCodes = {};
  bool _isSubmitting = false;
  bool _hasAnswered = false;
  ItemAnswerResult? _result;

  List<MarketFood> get _selectedFoods =>
      widget.question.selectionOptions.where((f) => _selectedCodes.contains(f.foodCode)).toList();

  bool _isInShoppingList(MarketFood food) =>
      widget.question.shoppingList.any((f) => f.foodCode == food.foodCode);

  void _toggleSelect(MarketFood food) {
    if (_hasAnswered || _isSubmitting) return;

    SoundPlayer.playClick();
    setState(() {
      if (_selectedCodes.contains(food.foodCode)) {
        _selectedCodes.remove(food.foodCode);
      } else {
        _selectedCodes.add(food.foodCode);
      }
    });
  }

  Future<void> _handleConfirm() async {
    setState(() => _isSubmitting = true);

    try {
      final result = await widget.onSubmitAnswer(_selectedFoods);

      setState(() {
        _result = result;
        _hasAnswered = true;
        _isSubmitting = false;
      });

      if (result.isCorrect) {
        SoundPlayer.playCorrect();
      } else {
        SoundPlayer.playWrong();
      }

      if (result.isCompleted || result.nextQuestion != null) return;

      if (result.isCorrect) {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) widget.onProceedToCheckout();
      } else {
        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted) {
          setState(() {
            _hasAnswered = false;
            _result = null;
            _selectedCodes.clear();
          });
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
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
                    const Text(
                      '請選出購物清單上的品項',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3D6B4A)),
                    ),
                    const SizedBox(height: 16),
                    _buildBasketPreview(),
                    const SizedBox(height: 24),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemCount: widget.question.selectionOptions.length,
                        itemBuilder: (context, index) {
                          final food = widget.question.selectionOptions[index];
                          final isSelected = _selectedCodes.contains(food.foodCode);
                          return _buildOptionCard(food, isSelected);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B8A6B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: (_selectedCodes.isEmpty || _hasAnswered || _isSubmitting) ? null : _handleConfirm,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _hasAnswered ? '請稍候...' : '確認選好了',
                                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildBasketPreview() {
    return Container(
      height: 64,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8DC)),
      ),
      child: _selectedFoods.isEmpty
          ? const Center(child: Text('菜籃是空的，點選下方品項', style: TextStyle(color: Colors.black38)))
          : ListView(
              scrollDirection: Axis.horizontal,
              children: _selectedFoods.map((food) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Chip(label: Text(food.foodName), backgroundColor: const Color(0xFFDCE8DC)),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildOptionCard(MarketFood food, bool isSelected) {
    // 依狀態決定卡片底色：預設木盒色，選中/答對/答錯各是一整片單色
    Color backgroundColor;
    Widget? badge;

    if (!_hasAnswered) {
      backgroundColor = isSelected ? const Color(0xFF3D6B4A) : const Color(0xFFB07D4F);
    } else {
      final shouldHaveBeenSelected = _isInShoppingList(food);

      if (shouldHaveBeenSelected) {
        backgroundColor = const Color(0xFF4CAF50);
        badge = const Icon(Icons.check_circle, color: Colors.white, size: 22);
      } else if (isSelected) {
        backgroundColor = const Color(0xFFFF9800);
        badge = const Icon(Icons.cancel, color: Colors.white, size: 22);
      } else {
        backgroundColor = const Color(0xFFE0DAD0);
      }
    }

    return GestureDetector(
      onTap: () => _toggleSelect(food),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                food.imagePath,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported_outlined, size: 32, color: Colors.black26),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  food.foodName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 4),
                  badge,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}