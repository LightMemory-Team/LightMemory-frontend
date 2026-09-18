import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

// 暫時測試用的深綠色，跟pause_modal.dart同一個數值，
// 之後拿到組員正確色碼時，這兩個檔案要一起換掉
const _testPrimaryColor = Color(0xFF2E5940);

enum ScoreLevel { excellent, good, tryAgain }

extension ScoreLevelDisplay on ScoreLevel {
  IconData get icon {
    switch (this) {
      case ScoreLevel.excellent:
        return Icons.star;
      case ScoreLevel.good:
        return Icons.check;
      case ScoreLevel.tryAgain:
        return Icons.flag;
    }
  }

  Color get color {
    switch (this) {
      case ScoreLevel.excellent:
      case ScoreLevel.good:
        return _testPrimaryColor;
      case ScoreLevel.tryAgain:
        return const Color(0xFFE8825A);
    }
  }

  String get label {
    switch (this) {
      case ScoreLevel.excellent:
        return '非常棒！';
      case ScoreLevel.good:
        return '很好！';
      case ScoreLevel.tryAgain:
        return '沒關係再加油！';
    }
  }
}

class ResultScoreCard extends StatelessWidget {
  final ScoreLevel level;
  final int currentScore;
  final int bestScore;
  final String currentLabel;
  final String bestLabel;
  final String unit;

  const ResultScoreCard({
    super.key,
    required this.level,
    required this.currentScore,
    required this.bestScore,
    this.currentLabel = '本次分數',
    this.bestLabel = '最高分數',
    this.unit = '分',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: level.color, width: 2),
            ),
            child: Icon(level.icon, color: level.color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            '本次表現等級',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            level.label,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: level.color,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ScoreColumn(label: currentLabel, score: currentScore, unit: unit),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _ScoreColumn(label: bestLabel, score: bestScore, unit: unit),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  final String label;
  final int score;
  final String unit;

  const _ScoreColumn({required this.label, required this.score, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$score',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(' $unit', style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ],
        ),
      ],
    );
  }
}