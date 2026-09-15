import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../models/game_rule.dart';

class RuleBadge extends StatelessWidget {
  final GameRule rule;

  const RuleBadge({super.key, required this.rule});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft, // 之後放進遊戲畫面時，外面通常會再包一層置中
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '目前分類：',
              style: TextStyle(fontSize: 18, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shopping_basket_outlined,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 6),
                Text(
                  rule.label,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}