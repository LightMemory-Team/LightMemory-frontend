import 'package:flutter/material.dart';
import '../features/game/market_sort/widgets/market_sort_top_bar.dart';
import '../features/game/market_sort/widgets/game_progress_header.dart';
import '../features/game/market_sort/widgets/rule_badge.dart';
import '../features/game/market_sort/models/game_rule.dart';
import '../features/game/market_sort/widgets/basket_row.dart';
import '../features/game/market_sort/widgets/product_card.dart';
import '../features/game/market_sort/models/market_sort_item_pool.dart';

class WidgetGalleryScreen extends StatelessWidget {
  const WidgetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('元件展示（開發用，非正式畫面）')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. MarketSortTopBar'),
            const SizedBox(height: 8),
            MarketSortTopBar(
              onBackTap: () {},
              onNotificationTap: () {},
              hasUnreadNotification: true,
            ),
            const Divider(height: 32),

            const Text('2. GameProgressHeader'),
            const SizedBox(height: 8),
            const GameProgressHeader(
              currentQuestionNumber: 3,
              totalQuestionCount: 28,
            ),
            const Divider(height: 32),

            const Text('3. RuleBadge'),
            const SizedBox(height: 8),
            const RuleBadge(rule: GameRule.species),
                        const Text('4. BasketRow（種類規則示例，三個籃子）'),
            const SizedBox(height: 8),
            const BasketRow(
              options: [
                BasketOption(
                  label: '蔬菜',
                  emoji: '🥬',
                  color: Color(0xFF5B9E87),
                  value: 'vegetable_placeholder', // 之後接上ItemCategory.vegetable
                ),
                BasketOption(
                  label: '水果',
                  emoji: '🍎',
                  color: Color(0xFFE8825A),
                  value: 'fruit_placeholder',
                ),
                BasketOption(
                  label: '肉蛋',
                  emoji: '🍗',
                  color: Color(0xFFA0653F),
                  value: 'meat_egg_placeholder',
                ),
              ],
            ),
            const Divider(height: 32),
            const Divider(height: 32),
                        const Text('5. ProductCard（平時狀態）'),
            const SizedBox(height: 8),
            ProductCard(item: marketSortItemPool.first),
            const Divider(height: 32),

            const Text('5b. ProductCard（逾時狀態）'),
            const SizedBox(height: 8),
            ProductCard(item: marketSortItemPool.first, isIdle: true),
            const Divider(height: 32),
          ],
        ),
      ),
    );
  }
}