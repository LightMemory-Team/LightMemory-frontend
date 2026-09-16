import 'package:flutter/material.dart';
import 'market_shopping_game_page.dart';

class MarketShoppingResultPage extends StatelessWidget {
  final int accuracy;
  final List<int> historyScores;

  const MarketShoppingResultPage({
    super.key,
    required this.accuracy,
    this.historyScores = const [],
  });

  @override
  Widget build(BuildContext context) {
    final allScores = [...historyScores, accuracy];
    final displayScores = allScores.length > 5
        ? allScores.sublist(allScores.length - 5)
        : allScores;

    final highestScore = allScores.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8F3),
        elevation: 0,
        title: const Text('市場買菜', style: TextStyle(color: Colors.black87)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildResultCard(context, highestScore),
                const SizedBox(height: 20),
                _buildHistoryCard(displayScores),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(List<int> scores) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('歷史成績', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: Size.infinite,
              painter: _SimpleLineChartPainter(scores: scores),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(scores.length, (index) {
              final labelIndex = scores.length - 1 - index;
              final label = labelIndex == 0 ? '本次' : '前$labelIndex次';
              return Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45));
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, int highestScore) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8DC)),
      ),
      child: Column(
        children: [
          const Text('市場買菜', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFDCE8DC)),
            child: const Icon(Icons.star_outline, color: Color(0xFF5B8A6B), size: 32),
          ),
          const SizedBox(height: 8),
          const Text('非常棒！', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreColumn('本次正確率', accuracy),
              Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
              _buildScoreColumn('最高正確率', highestScore),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B8A6B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MarketShoppingGamePage(),
                  ),
                );
              },
              child: const Text('再玩一次', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDDDDDD)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('退出', style: TextStyle(fontSize: 16, color: Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 4),
        Text('$value%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3D6B4A))),
      ],
    );
  }
}

class _SimpleLineChartPainter extends CustomPainter {
  final List<int> scores;

  _SimpleLineChartPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final maxScore = 100;
    final stepX = scores.length > 1 ? size.width / (scores.length - 1) : 0.0;

    final linePaint = Paint()
      ..color = const Color(0xFF5B8A6B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = const Color(0xFF5B8A6B);

    final points = <Offset>[];
    for (int i = 0; i < scores.length; i++) {
      final x = stepX * i;
      final y = size.height - (scores[i] / maxScore) * size.height;
      points.add(Offset(x, y));
    }

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 5, dotPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${scores[i]}',
          style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(points[i].dx - textPainter.width / 2, points[i].dy - 20));
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleLineChartPainter oldDelegate) => oldDelegate.scores != scores;
}