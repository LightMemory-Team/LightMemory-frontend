import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../models/game_rule.dart';

class RuleBadge extends StatelessWidget {
  final GameRule rule;
  final bool compact; // true時整體縮小，用於教學彈窗這類空間有限的地方

  const RuleBadge({super.key, required this.rule, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final labelFontSize = compact ? 18.0 : 28.0;
    final iconSize = compact ? 18.0 : 28.0;

    return Container(
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
            style: TextStyle(fontSize: 13, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                color: AppTheme.primaryColor,
                size: iconSize,
              ),
              const SizedBox(width: 6),
              Text(
                rule.label,
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}