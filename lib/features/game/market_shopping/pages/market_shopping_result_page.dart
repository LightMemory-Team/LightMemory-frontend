import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../models/market_shopping_models.dart';
import '../services/market_shopping_service.dart';
import '../../market_sort/widgets/result_score_card.dart';
import '../../market_sort/widgets/result_history_chart.dart';
import 'market_shopping_game_page.dart';
import '../../../rewards/models/rewards_models.dart';
import '../../../rewards/widgets/rewards_earned_card.dart';
import '../../../rewards/widgets/achievement_unlock.dart';

class MarketShoppingResultPage extends StatefulWidget {
  final int score;
  final int accuracy; // 首次答對率（重試後才答對的題目不計入）

  /// 點數與成就：第 10 題結束時找零回應的 rewards（沒有就是 0 點，不顯示）
  final RewardsResult rewards;

  const MarketShoppingResultPage({
    super.key,
    required this.score,
    required this.accuracy,
    this.rewards = RewardsResult.empty,
  });

  @override
  State<MarketShoppingResultPage> createState() =>
      _MarketShoppingResultPageState();
}

class _MarketShoppingResultPageState extends State<MarketShoppingResultPage> {
  bool _isLoadingHistory = true;
  String? _historyError;
  List<HistoryRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final result = await MarketShoppingService.getHistory();
      if (!mounted) return;
      setState(() {
        _records = result.records;
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = '無法載入歷史成績';
        _isLoadingHistory = false;
      });
    }
  }

  ScoreLevel get _scoreLevel {
    if (widget.score >= 90) return ScoreLevel.excellent;
    if (widget.score >= 60) return ScoreLevel.good;
    return ScoreLevel.tryAgain;
  }

  // 最高分數取全部歷史紀錄的最大值，records是空的（或還沒讀到）就先顯示本次成績
  int get _bestScore {
    if (_records.isEmpty) return widget.score;
    return _records.map((r) => r.score).reduce((a, b) => a > b ? a : b);
  }

  // 依時間排序後取最近5筆，最新一筆當作圖表上的「本次」
  List<HistoryRecord> get _recentRecords {
    final sorted = [..._records]
      ..sort((a, b) => a.playedAt.compareTo(b.playedAt));
    return sorted.length > 5 ? sorted.sublist(sorted.length - 5) : sorted;
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
                currentScore: widget.score,
                bestScore: _bestScore,
              ),
              const SizedBox(height: 10),
              Text(
                '首次答對率 ${widget.accuracy}%（重試後才答對的題目不計入這項）',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // 點數與成就：本場獲得點數（五款遊戲維持淺色）
              // 明細播完後，有新成就就跳出解鎖視窗；0 點時卡片自動隱藏
              RewardsEarnedCard(
                rewards: widget.rewards,
                forceLight: true,
                onFinished: () => showNewAchievements(
                  context,
                  widget.rewards.newAchievements,
                  forceLight: true,
                ),
              ),
              if (widget.rewards.hasSomethingToShow) const SizedBox(height: 16),

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
                            builder: (context) => const MarketShoppingGamePage(),
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
              _buildHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_isLoadingHistory) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_historyError != null) {
      return _buildHistoryMessage(_historyError!);
    }

    final recent = _recentRecords;
    if (recent.length < 2) {
      // 沒有足夠的過去紀錄可以畫折線圖（第一次玩，或後端還沒有資料）
      return _buildHistoryMessage(recent.isEmpty ? '尚無歷史成績' : null);
    }

    final pastScores =
        recent.sublist(0, recent.length - 1).map((r) => r.score).toList();
    final currentScoreForChart = recent.last.score;

    return ResultHistoryChart(
      pastScores: pastScores,
      currentScore: currentScoreForChart,
    );
  }

  Widget _buildHistoryMessage(String? message) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      ),
    );
  }
}