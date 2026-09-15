import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'features/game/market_sort/widgets/result_score_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '憶智防線',
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: Colors.grey,
        body: const Center(
          child: ResultScoreCard(
            level: ScoreLevel.tryAgain, // 測完換成 good、tryAgain 各截一張
            currentScore: 78,
            bestScore: 85,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}