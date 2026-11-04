import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../features/game/market_sort/services/market_sort_api_service.dart';
import '../features/game/market_sort/widgets/result_score_card.dart';
import '../features/game/market_sort/widgets/result_history_chart.dart';
import 'market_sort_game_screen.dart';

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
              // 熟悉場或資料不夠算時沒有分數，有值才顯示
              if (result.currentScore case final currentScore?)
                ResultScoreCard(
                  level: _scoreLevel,
                  currentScore: currentScore,
                  bestScore: result.highestScore ?? currentScore,
                )
              else
                _NoScoreCard(isPretest: result.isPretest),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
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
              if (result.recentScores.isNotEmpty && result.currentScore != null)
                ResultHistoryChart(
                  pastScores: result.recentScores,
                  currentScore: result.currentScore!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 這場沒有分數時取代分數卡：第一場是熟悉場，其他是資料還不夠算
class _NoScoreCard extends StatelessWidget {
  final bool isPretest;

  const _NoScoreCard({required this.isPretest});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              border: Border.all(color: AppTheme.primaryColor, width: 2),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppTheme.primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isPretest ? '熟悉場' : '完成了！',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPretest ? '這場不計分，下一場開始算分數喔！' : '這場的分數還在準備中',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
