import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../features/game/market_sort/services/market_sort_api_service.dart';
import '../features/game/market_sort/widgets/result_score_card.dart';
import '../features/game/market_sort/widgets/result_history_chart.dart';
import 'market_sort_game_screen.dart';
import 'game_home_screen.dart';

class MarketSortResultScreen extends StatelessWidget {
  final MarketSortSubmitResult result;

  const MarketSortResultScreen({super.key, required this.result});

  ScoreLevel get _scoreLevel {
    switch (result.encouragementTier) {
      case 'great':
        return ScoreLevel.excellent;
      case 'good':
        return ScoreLevel.good;
      default:
        return ScoreLevel.tryAgain;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                '成績結算',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              ResultScoreCard(
                level: _scoreLevel,
                currentScore: result.currentScore,
                bestScore: result.highestScore,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const GameHomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                      child: const Text(
                        '退出遊戲',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const MarketSortGameScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text(
                        '再玩一次',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (result.recentScores.isNotEmpty)
                ResultHistoryChart(
                  pastScores: result.recentScores,
                  currentScore: result.currentScore,
                ),
            ],
          ),
        ),
      ),
    );
  }
}