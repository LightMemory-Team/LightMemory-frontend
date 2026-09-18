import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import 'market_history_chart_painter.dart';

class MarketResultDialog extends StatelessWidget {
  final int currentScore;
  final int highestScore;
  final List history;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const MarketResultDialog({
    super.key,
    required this.currentScore,
    required this.highestScore,
    required this.history,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final String commentText;
    final IconData statusIcon;
    final Color statusColor;

    if (currentScore >= 90) {
      commentText = '非常棒！';
      statusIcon = Icons.star_outline_rounded;
      statusColor = const Color(0xFF2D5A43);
    } else if (currentScore >= 60) {
      commentText = '很好！';
      statusIcon = Icons.check_rounded;
      statusColor = const Color(0xFF2D5A43);
    } else {
      commentText = '沒關係再加油！';
      statusIcon = Icons.outlined_flag_rounded;
      statusColor = const Color(0xFFD97736);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        width: 720,
        height: 290, // 固定高度適配橫向畫面，杜絕 Overflow
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左側：歷史成績折線圖
            Expanded(
              flex: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '歷史成績',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D5A43),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0, bottom: 2.0),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: MarketHistoryChartPainter(scores: history),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 中間分隔線
            Container(
              width: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              color: const Color(0xFFE5ECE8),
            ),

            // 右側：評語 + 分數卡片 + 橫向並排按鈕
            Expanded(
              flex: 10,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 頂部評語區
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '來去菜市場',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5A43),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor, width: 2.0),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        commentText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),

                  // 分數並排卡
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9F6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE4EDE7)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '本次分數',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7E73),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentScore.toString(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D5A43),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: const Color(0xFFD6E2DA),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '最高分數',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7E73),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                highestScore.toString(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D5A43),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 底部操作按鈕：橫向並排
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: Color(0xFFD1DDD5),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              AudioService.playClick();
                              Navigator.of(context).pop();
                              onExit();
                            },
                            child: const Text(
                              '退出',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D5A43),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF335C45),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              AudioService.playClick();
                              Navigator.of(context).pop();
                              onPlayAgain();
                            },
                            child: const Text(
                              '再玩一次',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
