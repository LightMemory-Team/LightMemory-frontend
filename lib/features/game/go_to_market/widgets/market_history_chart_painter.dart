import 'package:flutter/material.dart';

class MarketHistoryChartPainter extends CustomPainter {
  final List scores;

  MarketHistoryChartPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPadding = 36.0;
    const double rightPadding = 24.0;
    const double bottomPadding = 32.0;
    const double topPadding = 24.0;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    // 1. 繪製 Y 軸刻度與參考虛線 (0, 50, 100)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final dashedPaint = Paint()
      ..color = const Color(0xFFE5ECE8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final yValues = [0, 50, 100];
    for (final val in yValues) {
      final y = topPadding + chartHeight * (1 - (val / 100));

      textPainter.text = TextSpan(
        text: val.toString(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF7A8D81),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
      );

      _drawDashedLine(
        canvas,
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        dashedPaint,
      );
    }

    if (scores.isEmpty) return;

    // 安全解析整數陣列
    final List intScores = scores
        .map((e) => int.tryParse(e.toString()) ?? 0)
        .toList();

    // 2. 計算 X 軸間距與各點座標 (固定 5 格槽位，左到右對齊)
    const int totalSlots = 5;
    final double xStep = chartWidth / (totalSlots - 1);

    final List bottomLabels = [];
    final int count = intScores.length;
    for (int i = 0; i < totalSlots; i++) {
      if (i < count) {
        if (i == count - 1) {
          bottomLabels.add('本次');
        } else {
          final diff = (count - 1) - i;
          bottomLabels.add('前$diff次');
        }
      } else {
        bottomLabels.add('-');
      }
    }

    final List points = [];
    for (int i = 0; i < intScores.length; i++) {
      final x = leftPadding + (i * xStep);
      final scoreVal = intScores[i].clamp(0, 100);
      final y = topPadding + chartHeight * (1 - (scoreVal / 100));
      points.add(Offset(x, y));
    }

    // 繪製 X 軸標籤文字
    for (int i = 0; i < totalSlots; i++) {
      final x = leftPadding + (i * xStep);
      textPainter.text = TextSpan(
        text: bottomLabels[i],
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: i < count ? const Color(0xFF7A8D81) : const Color(0xFFC7D3CB),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomPadding + 8),
      );
    }

    // 3. 繪製半透明漸層陰影
    if (points.isNotEmpty) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, size.height - bottomPadding);
      for (final pt in points) {
        fillPath.lineTo(pt.dx, pt.dy);
      }
      fillPath.lineTo(points.last.dx, size.height - bottomPadding);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF335C45).withOpacity(0.18),
            const Color(0xFF335C45).withOpacity(0.01),
          ],
        ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));
      canvas.drawPath(fillPath, fillPaint);
    }

    // 4. 繪製折線
    if (points.length > 1) {
      final linePaint = Paint()
        ..color = const Color(0xFF335C45)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    // 5. 繪製資料點與分數文字
    final pointBorderPaint = Paint()
      ..color = const Color(0xFF335C45)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final pointFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final scoreVal = intScores[i];
      final isCurrent = (i == points.length - 1);

      canvas.drawCircle(pt, isCurrent ? 7.0 : 5.5, pointFillPaint);
      canvas.drawCircle(pt, isCurrent ? 7.0 : 5.5, pointBorderPaint);

      textPainter.text = TextSpan(
        text: scoreVal.toString(),
        style: TextStyle(
          fontSize: isCurrent ? 15 : 13,
          fontWeight: isCurrent ? FontWeight.w900 : FontWeight.bold,
          color: const Color(0xFF1E2D24),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pt.dx - textPainter.width / 2, pt.dy - textPainter.height - 6),
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 4.0;
    double startX = p1.dx;
    while (startX < p2.dx) {
      canvas.drawLine(
        Offset(startX, p1.dy),
        Offset((startX + dashWidth).clamp(p1.dx, p2.dx), p1.dy),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant MarketHistoryChartPainter oldDelegate) {
    return true;
  }
}
