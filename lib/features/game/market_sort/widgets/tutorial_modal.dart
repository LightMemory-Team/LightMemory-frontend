import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../models/game_rule.dart';
import '../models/market_sort_item_pool.dart';
import 'product_card.dart';
import 'basket_row.dart';
import 'rule_badge.dart';

class TutorialModal extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onStartGame;

  const TutorialModal({super.key, required this.onClose, this.onStartGame});

  @override
  State<TutorialModal> createState() => _TutorialModalState();
}

class _TutorialModalState extends State<TutorialModal>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _moveController;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation;

  static const List<String> _titles = ['怎麼玩', '遊戲共分四階段'];
  static const _basketOffset = Offset(44, 56); // 商品從原位到籃子的位移量

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // 位置動畫：分四段，每段各佔總時長的25%（0.5秒）
    _offsetAnimation = TweenSequence<Offset>([
      // 1. 原位 → 籃子（可見）
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: _basketOffset)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      // 2. 停在籃子位置（這段同時間淡出，見下面opacity）
      TweenSequenceItem(
        tween: ConstantTween(_basketOffset),
        weight: 25,
      ),
      // 3. 籃子 → 原位（這段全程透明，見下面opacity）
      TweenSequenceItem(
        tween: Tween(begin: _basketOffset, end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      // 4. 停在原位（這段同時間淡入）
      TweenSequenceItem(
        tween: ConstantTween(Offset.zero),
        weight: 25,
      ),
    ]).animate(_moveController);

    // 透明度動畫：跟上面四段一一對應
    _opacityAnimation = TweenSequence<double>([
      // 1. 移動中，維持可見
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
      // 2. 淡出：可見→透明
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
      // 3. 回程中，維持透明（看不見）
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 25),
      // 4. 淡入：透明→可見
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
    ]).animate(_moveController);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          width: 320,
          height: 600,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _currentPage > 0
                      ? GestureDetector(
                          onTap: _goToPreviousPage,
                          child: const Icon(
                            Icons.arrow_back,
                            size: 24,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : const SizedBox(width: 24),
                  Text(
                    _titles[_currentPage],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: const Icon(Icons.close, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    _buildPage1(),
                    _buildPage2(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) {
                  final isActive = index == _currentPage;
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primaryColor
                          : AppTheme.primaryColor.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              _currentPage == 0
                  ? OutlinedButton(
                      onPressed: _goToNextPage,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                      child: const Text(
                        '下一頁 →',
                        style: TextStyle(color: AppTheme.primaryColor, fontSize: 16),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: widget.onStartGame ?? widget.onClose,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text(
                        '開始遊戲 →',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '每件商品都有自己的屬性，畫面上方會提示現在要看哪個屬性分類。\n'
          '長按中間商品圖示，拖到符合提示的籃子裡就完成一題',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, height: 1.5),
        ),
        const SizedBox(height: 12),
        const Center(child: RuleBadge(rule: GameRule.species, compact: true)),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _moveController,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.translate(
                offset: _offsetAnimation.value,
                child: child,
              ),
            );
          },
          child: ProductCard(item: marketSortItemPool[10], compact: true),
        ),
        const SizedBox(height: 6),
        BasketRow(
          compact: true,
          options: const [
            BasketOption(
              label: '蔬菜',
              emoji: '🥬',
              color: Color(0xFF5B9E87),
              value: 'vegetable',
            ),
            BasketOption(
              label: '水果',
              emoji: '🍎',
              color: Color(0xFFE8825A),
              value: 'fruit',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPage2() {
    final stages = [
      (icon: Icons.access_time, label: '生熟', desc: '分生食、熟食'),
      (icon: Icons.shopping_basket_outlined, label: '種類', desc: '分蔬菜、水果、肉蛋'),
      (icon: Icons.palette_outlined, label: '顏色', desc: '分紅、綠、黃'),
      (icon: Icons.shuffle, label: '隨機', desc: '規則會不斷切換，每題都會先提示'),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ...stages.map(
          (stage) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(stage.icon, color: AppTheme.primaryColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                      children: [
                        TextSpan(
                          text: stage.label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: '——${stage.desc}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Text(
          '答錯了也沒關係，直接換下一題就好',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }
}