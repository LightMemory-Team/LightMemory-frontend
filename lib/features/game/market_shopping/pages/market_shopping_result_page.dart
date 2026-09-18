import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../models/market_shopping_models.dart';
import '../services/market_shopping_service.dart';
import '../../market_sort/widgets/result_score_card.dart';
import '../../market_sort/widgets/result_history_chart.dart';
import '../../../../screens/game_home_screen.dart';
import 'market_shopping_game_page.dart';

class MarketShoppingResultPage extends StatefulWidget {
  final int accuracy;

  const MarketShoppingResultPage({super.key, required this.accuracy});

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
    if (widget.accuracy >= 90) return ScoreLevel.excellent;
    if (widget.accuracy >= 60) return ScoreLevel.good;
    return ScoreLevel.tryAgain;
  }

  // 最高正確率取全部歷史紀錄的最大值，records是空的（或還沒讀到）就先顯示本次成績
  int get _bestAccuracy {
    if (_records.isEmpty) return widget.accuracy;
    return _records.map((r) => r.accuracy).reduce((a, b) => a > b ? a : b);
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
                currentScore: widget.accuracy,
                bestScore: _bestAccuracy,
                currentLabel: '本次正確率',
                bestLabel: '最高正確率',
                unit: '%',
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
        recent.sublist(0, recent.length - 1).map((r) => r.accuracy).toList();
    final currentScoreForChart = recent.last.accuracy;

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
