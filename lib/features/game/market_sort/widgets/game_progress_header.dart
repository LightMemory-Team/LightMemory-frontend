import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// 題數「3/28」＋進度長條，全場累計格式，不顯示百分比數字
class GameProgressHeader extends StatelessWidget {
  final int currentQuestionNumber; // 1起算
  final int totalQuestionCount;

  const GameProgressHeader({
    super.key,
    required this.currentQuestionNumber,
    required this.totalQuestionCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentQuestionNumber / totalQuestionCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$currentQuestionNumber/$totalQuestionCount',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
