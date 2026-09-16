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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        width: 780,
        padding: const EdgeInsets.fromLTRB(36, 32, 36, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左側：歷史成績折線圖
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '歷史成績',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D5A43),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: CustomPaint(
                      size: const Size(double.infinity, 220),
                      painter: MarketHistoryChartPainter(scores: history),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 1.5,
              height: 260,
              margin: const EdgeInsets.symmetric(horizontal: 28),
              color: const Color(0xFFE5ECE8),
            ),

            // 右側：評語 + 分數卡片 + 按鈕
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '來去菜市場',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D5A43),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor, width: 2.2),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 32),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    commentText,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9F6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4EDE7)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                '本次分數',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7E73),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentScore.toString(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D5A43),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: const Color(0xFFD6E2DA),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                '最高分數',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7E73),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                highestScore.toString(),
                                style: const TextStyle(
                                  fontSize: 32,
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
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF335C45),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xFFD1DDD5),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5A43),
                        ),
                      ),
                    ),
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
