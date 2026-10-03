import 'package:flutter/material.dart';

import '../services/fridge_inventory_service.dart';
import 'fridge_game_page.dart';

class FridgeResultPage extends StatefulWidget {
  final double finalScore;

  // ⭐ 測試模式
  //
  // true：
  // 不需要後端歷史成績，直接使用測試資料。
  //
  // false：
  // 正式遊戲使用後端 API。
  final bool isTestMode;

  const FridgeResultPage({
    super.key,
    required this.finalScore,
    this.isTestMode = false,
  });

  @override
  State<FridgeResultPage> createState() => _FridgeResultPageState();
}

class _FridgeResultPageState extends State<FridgeResultPage> {
  // ============================================================
  // 顏色
  // ============================================================

  static const Color darkGreen = Color(0xFF355E3B);
  static const Color deepGreen = Color(0xFF29442F);

  static const Color lightGreen = Color(0xFFE5EEE7);
  static const Color paleGreen = Color(0xFFF5F8F5);

  static const Color borderGreen = Color(0xFFC8D5CA);
  static const Color textGreen = Color(0xFF52715A);

  // 低分評語使用的橘色
  static const Color warningOrange = Color(0xFFD8951B);

  // ============================================================
  // 歷史成績
  // ============================================================

  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();

    _loadHistory();
  }

  // ============================================================
  // 載入歷史成績
  // ============================================================

  void _loadHistory() {
    // ⭐ 測試模式不需要後端
    if (widget.isTestMode) {
      _historyFuture = Future.value(_buildTestHistory());
      return;
    }

    // 正式遊戲 → 使用後端 API
    _historyFuture = FridgeInventoryService.getHistory();
  }

  // ============================================================
  // ⭐ 測試用歷史資料
  //
  // 固定模擬前四次：
  // 35 → 60 → 70 → 85
  //
  // 本次分數會由遊戲傳進來。
  // ============================================================

  List<Map<String, dynamic>> _buildTestHistory() {
    return [
      {'score': 35, 'created_at': '2026-09-20T10:00:00'},
      {'score': 60, 'created_at': '2026-09-21T10:00:00'},
      {'score': 70, 'created_at': '2026-09-22T10:00:00'},
      {'score': 85, 'created_at': '2026-09-23T10:00:00'},
      {'score': widget.finalScore, 'created_at': '2026-09-24T10:00:00'},
    ];
  }

  // ============================================================
  // 分數格式
  // ============================================================

  String _formatScore(num score) {
    final double value = score.toDouble();

    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  // ============================================================
  // 評語
  // ============================================================

  String _getScoreMessage(double score) {
    if (score >= 90) {
      return '非常棒！';
    }

    if (score >= 60) {
      return '很好！';
    }

    return '沒關係，再加油！';
  }

  // ============================================================
  // 評語圖示
  //
  // 90↑  → 星星
  // 60~89 → 打勾
  // 0~59 → 旗子
  // ============================================================

  IconData _getScoreIcon(double score) {
    if (score >= 90) {
      return Icons.star_outline_rounded;
    }

    if (score >= 60) {
      return Icons.check_rounded;
    }

    return Icons.flag_outlined;
  }

  // ============================================================
  // 評語圖示顏色
  // ============================================================

  Color _getScoreIconColor(double score) {
    if (score < 60) {
      return warningOrange;
    }

    return darkGreen;
  }

  // ============================================================
  // 取得歷史分數
  // ============================================================

  double _getItemScore(Map<String, dynamic> item) {
    final dynamic rawScore =
        item['final_score'] ?? item['score'] ?? item['current_score'];

    if (rawScore is num) {
      return rawScore.toDouble();
    }

    return double.tryParse(rawScore?.toString() ?? '') ?? 0.0;
  }

  // ============================================================
  // 取得日期
  // ============================================================

  DateTime? _getItemDate(Map<String, dynamic> item) {
    final dynamic rawDate =
        item['created_at'] ?? item['completed_at'] ?? item['date'];

    if (rawDate == null) {
      return null;
    }

    return DateTime.tryParse(rawDate.toString());
  }

  // ============================================================
  // 整理歷史資料
  //
  // 最新五次。
  //
  // 圖表一定會把「本次成績」放在最後。
  // ============================================================

  List<double> _prepareChartScores(List<Map<String, dynamic>> history) {
    final List<Map<String, dynamic>> sortedHistory =
        List<Map<String, dynamic>>.from(history);

    // 有日期就按照舊 → 新排序
    sortedHistory.sort((a, b) {
      final DateTime? dateA = _getItemDate(a);

      final DateTime? dateB = _getItemDate(b);

      if (dateA == null && dateB == null) {
        return 0;
      }

      if (dateA == null) {
        return -1;
      }

      if (dateB == null) {
        return 1;
      }

      return dateA.compareTo(dateB);
    });

    // 取最新五筆
    List<Map<String, dynamic>> latest = sortedHistory.length > 5
        ? sortedHistory.sublist(sortedHistory.length - 5)
        : sortedHistory;

    List<double> scores = latest.map(_getItemScore).toList();

    // ==========================================================
    // 確保本次成績存在
    // ==========================================================

    if (scores.isEmpty) {
      scores = [widget.finalScore];
    } else {
      final double lastScore = scores.last;

      if ((lastScore - widget.finalScore).abs() > 0.001) {
        scores.add(widget.finalScore);
      } else {
        scores[scores.length - 1] = widget.finalScore;
      }
    }

    // 最後只留五筆
    if (scores.length > 5) {
      scores = scores.sublist(scores.length - 5);
    }

    return scores;
  }

  // ============================================================
  // 取得最高分
  // ============================================================

  double _getHighestScore(List<Map<String, dynamic>> history) {
    double highestScore = widget.finalScore;

    for (final item in history) {
      final double score = _getItemScore(item);

      if (score > highestScore) {
        highestScore = score;
      }
    }

    return highestScore;
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double currentScore = widget.finalScore;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F1),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================================================
              // 1. 遊戲名稱
              // ==================================================
              const Text(
                '冰箱清點',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: deepGreen,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                '成績結算',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: textGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // 2. 評語
              // ==================================================
              _buildCommentSection(currentScore),

              const SizedBox(height: 14),

              // ==================================================
              // 3 + 4. 分數
              // ==================================================
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  double highestScore = currentScore;

                  if (snapshot.hasData) {
                    highestScore = _getHighestScore(snapshot.data!);
                  }

                  return _buildScoreCards(currentScore, highestScore);
                },
              ),

              const SizedBox(height: 16),

              // ==================================================
              // 5. 歷史成績
              // ==================================================
              _buildHistorySection(),

              const SizedBox(height: 18),

              // ==================================================
              // 6. 再玩一次
              // ==================================================
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FridgeGamePage(),
                      ),
                    );
                  },
                  child: const Text(
                    '再玩一次',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // 7. 退出
              // ==================================================
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: darkGreen,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: borderGreen, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '退出',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 評語區
  // ============================================================

  Widget _buildCommentSection(double score) {
    final Color iconColor = _getScoreIconColor(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGreen, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ======================================================
          // 評語圖示
          // ======================================================
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: score < 60 ? const Color(0xFFFFF7E8) : lightGreen,
              border: Border.all(color: iconColor, width: 1.3),
            ),
            child: Icon(_getScoreIcon(score), size: 30, color: iconColor),
          ),

          const SizedBox(height: 8),

          Text(
            _getScoreMessage(score),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 本次分數 / 最高分數
  // ============================================================

  Widget _buildScoreCards(double currentScore, double highestScore) {
    return Container(
      width: double.infinity,
      height: 94,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGreen, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildScoreItem(title: '本次分數', score: currentScore),
          ),

          Container(width: 1, height: 48, color: borderGreen),

          Expanded(
            child: _buildScoreItem(title: '最高分數', score: highestScore),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem({required String title, required double score}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: textGreen,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          _formatScore(score),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 歷史成績
  // ============================================================

  Widget _buildHistorySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGreen, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              '歷史成績',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: deepGreen,
              ),
            ),
          ),

          const SizedBox(height: 2),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              '最近五次遊戲成績',
              style: TextStyle(fontSize: 11, color: Color(0xFF7A8C7E)),
            ),
          ),

          const SizedBox(height: 10),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              // ==================================================
              // 載入中
              // ==================================================

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(color: darkGreen),
                  ),
                );
              }

              // ==================================================
              // 後端錯誤
              // ==================================================

              if (snapshot.hasError) {
                return _buildHistoryError();
              }

              final List<Map<String, dynamic>> history = snapshot.data ?? [];

              final List<double> scores = _prepareChartScores(history);

              if (scores.isEmpty) {
                return _buildEmptyHistory();
              }

              return _buildScoreChart(scores);
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 歷史成績錯誤
  // ============================================================

  Widget _buildHistoryError() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          decoration: BoxDecoration(
            color: paleGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              Icon(Icons.cloud_off_outlined, size: 30, color: textGreen),

              SizedBox(height: 7),

              Text(
                '目前無法取得歷史成績',
                style: TextStyle(
                  fontSize: 13,
                  color: textGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 3),

              Text(
                '本次遊戲成績仍然正常顯示',
                style: TextStyle(fontSize: 11, color: Color(0xFF7A8C7E)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        OutlinedButton(
          onPressed: () {
            setState(() {
              _loadHistory();
            });
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: darkGreen,
            side: const BorderSide(color: borderGreen),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: const Text('重新載入'),
        ),
      ],
    );
  }

  // ============================================================
  // 沒有歷史資料
  // ============================================================

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: paleGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 32, color: textGreen),

            SizedBox(height: 7),

            Text(
              '目前還沒有歷史成績',
              style: TextStyle(
                fontSize: 13,
                color: textGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 折線圖
  // ============================================================

  Widget _buildScoreChart(List<double> scores) {
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: CustomPaint(painter: _ScoreChartPainter(scores)),
    );
  }
}

// ==================================================================
// 折線圖 Painter
// ==================================================================

class _ScoreChartPainter extends CustomPainter {
  final List<double> scores;

  _ScoreChartPainter(this.scores);

  static const Color darkGreen = Color(0xFF355E3B);

  static const Color paleGreen = Color(0xFFF5F8F5);

  static const Color gridGreen = Color(0xFFDCE5DD);

  static const Color textGreen = Color(0xFF7A8C7E);

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) {
      return;
    }

    const double leftPadding = 30;
    const double rightPadding = 8;
    const double topPadding = 25;
    const double bottomPadding = 35;

    final double chartWidth = size.width - leftPadding - rightPadding;

    final double chartHeight = size.height - topPadding - bottomPadding;

    // ============================================================
    // 背景
    // ============================================================

    final Paint backgroundPaint = Paint()..color = paleGreen;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      backgroundPaint,
    );

    // ============================================================
    // 最大值
    // ============================================================

    const double maxScore = 100;

    // ============================================================
    // 水平參考線
    // ============================================================

    final Paint gridPaint = Paint()
      ..color = gridGreen
      ..strokeWidth = 1;

    const List<double> gridValues = [100, 75, 50, 25, 0];

    for (final double value in gridValues) {
      final double normalized = value / maxScore;

      final double y = topPadding + chartHeight * (1 - normalized);

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    // ============================================================
    // Y 軸文字
    // ============================================================

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final double value in gridValues) {
      final double normalized = value / maxScore;

      final double y = topPadding + chartHeight * (1 - normalized);

      textPainter.text = TextSpan(
        text: value.toInt().toString(),
        style: const TextStyle(fontSize: 9, color: textGreen),
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 5, y - textPainter.height / 2),
      );
    }

    // ============================================================
    // 計算資料點
    // ============================================================

    final List<Offset> points = [];

    for (int i = 0; i < scores.length; i++) {
      final double x;

      if (scores.length == 1) {
        x = leftPadding + chartWidth / 2;
      } else {
        x = leftPadding + chartWidth * (i / (scores.length - 1));
      }

      final double normalized = (scores[i] / maxScore).clamp(0.0, 1.0);

      final double y = topPadding + chartHeight * (1 - normalized);

      points.add(Offset(x, y));
    }

    // ============================================================
    // 面積
    // ============================================================

    if (points.length >= 2) {
      final Path areaPath = Path();

      areaPath.moveTo(points.first.dx, topPadding + chartHeight);

      areaPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        areaPath.lineTo(points[i].dx, points[i].dy);
      }

      areaPath.lineTo(points.last.dx, topPadding + chartHeight);

      areaPath.close();

      final Paint areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [darkGreen.withOpacity(0.14), darkGreen.withOpacity(0.01)],
        ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));

      canvas.drawPath(areaPath, areaPaint);
    }

    // ============================================================
    // 折線
    // ============================================================

    if (points.length >= 2) {
      final Paint linePaint = Paint()
        ..color = darkGreen
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final Path linePath = Path();

      linePath.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(linePath, linePaint);
    }

    // ============================================================
    // 資料點 + 分數
    // ============================================================

    final Paint pointPaint = Paint()..color = darkGreen;

    final Paint whitePaint = Paint()..color = Colors.white;

    for (int i = 0; i < points.length; i++) {
      // 白色外圈
      canvas.drawCircle(points[i], 5.5, whitePaint);

      // 綠色資料點
      canvas.drawCircle(points[i], 3.5, pointPaint);

      // 分數文字
      textPainter.text = TextSpan(
        text: _formatChartScore(scores[i]),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: darkGreen,
        ),
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          points[i].dx - textPainter.width / 2,
          points[i].dy - textPainter.height - 6,
        ),
      );
    }

    // ============================================================
    // X 軸文字
    // ============================================================

    for (int i = 0; i < points.length; i++) {
      String label;

      if (i == points.length - 1) {
        label = '本次';
      } else {
        final int previousCount = points.length - 1 - i;

        label = '前${previousCount}次';
      }

      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(fontSize: 9, color: textGreen),
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          points[i].dx - textPainter.width / 2,
          size.height - bottomPadding + 8,
        ),
      );
    }
  }

  // ============================================================
  // 圖表分數格式
  // ============================================================

  String _formatChartScore(double score) {
    if (score == score.roundToDouble()) {
      return score.toInt().toString();
    }

    return score.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant _ScoreChartPainter oldDelegate) {
    if (oldDelegate.scores.length != scores.length) {
      return true;
    }

    for (int i = 0; i < scores.length; i++) {
      if (oldDelegate.scores[i] != scores[i]) {
        return true;
      }
    }

    return false;
  }
}
