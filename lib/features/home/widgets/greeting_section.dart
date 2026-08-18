import 'package:flutter/material.dart';

class GreetingSection extends StatelessWidget {
  final String userName;
  final String dailyTip;

  const GreetingSection({
    super.key,
    required this.userName,
    required this.dailyTip,
  });

  @override
  Widget build(BuildContext context) {
    // 限制系統大字體最大放大倍率為 1.3 倍，避免過度放大跑版
    final safeTextScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '早安，$userName！',
          textScaler: safeTextScaler,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E), // 高對比近黑色
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dailyTip,
          textScaler: safeTextScaler,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A4A4A), // 高對比深灰色（符合 WCAG AA）
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
