import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

// 暫時測試用的深綠色，跟pause_modal.dart、result_score_card.dart同一個數值，
// 之後拿到組員正確色碼時，這三個檔案要一起換掉
const _testPrimaryColor = Color(0xFF2E5940);

class ResultHistoryChart extends StatelessWidget {
  final List<int> pastScores; // 對應API的recent_scores[]，最多4筆，由舊到新排序
  final int currentScore; // 對應API的current_score

  const ResultHistoryChart({
    super.key,
    required this.pastScores,
    required this.currentScore,
  });

  List<String> get _xLabels {
    final count = pastScores.length;
    final labels = List.generate(count, (i) => '前${count - i}次');
    return [...labels, '本次'];
  }

  List<int> get _allScores => [...pastScores, currentScore];

  @override
  Widget build(BuildContext context) {
    final scores = _allScores;
    final labels = _xLabels;
    final lastIndex = scores.length - 1;

    final lineBarData = LineChartBarData(
      spots: [
        for (int i = 0; i < scores.length; i++)
          FlSpot(i.toDouble(), scores[i].toDouble()),
      ],
      isCurved: true,
      color: AppTheme.primaryColor,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) {
          final isLast = index == lastIndex;
          return FlDotCirclePainter(
            radius: isLast ? 6 : 4,
            color: AppTheme.primaryColor,
            strokeWidth: isLast ? 2.5 : 0,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.primaryColor.withValues(alpha: 0.0),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '歷史成績',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _testPrimaryColor,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: lastIndex.toDouble(),
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 50,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1, // 關鍵：明確指定間隔為1，避免自動間隔算出小數導致標籤重複
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        final isLast = index == lastIndex;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: isLast ? 14 : 13,
                              color: isLast
                                  ? _testPrimaryColor
                                  : Colors.grey.shade700,
                              fontWeight:
                                  isLast ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [lineBarData],
                showingTooltipIndicators: [
                  for (int i = 0; i < scores.length; i++)
                    ShowingTooltipIndicators([
                      LineBarSpot(lineBarData, 0, lineBarData.spots[i]),
                    ]),
                ],
                lineTouchData: LineTouchData(
                  enabled: false,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) {
                      final isLast = touchedSpot.x.toInt() == lastIndex;
                      return isLast
                          ? _testPrimaryColor
                          : Colors.grey.shade200;
                    },
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tooltipMargin: 10,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isLast = spot.x.toInt() == lastIndex;
                        return LineTooltipItem(
                          isLast ? '本次 ${spot.y.toInt()}' : '${spot.y.toInt()}',
                          TextStyle(
                            color: isLast ? Colors.white : Colors.grey.shade800,
                            fontSize: isLast ? 14 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}