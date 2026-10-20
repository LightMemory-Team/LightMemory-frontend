import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';

/// 暫時的機器人圖：用程式畫的簡單機器人，依 [mood] 換表情。
/// 之後有正式圖片時，把這個元件換成 Image.asset 即可（呼叫端只傳 mood）。
/// - good：笑瞇眼＋舉手打招呼
/// - keep：圓眼＋微笑
/// - encourage：圓眼＋旁邊一顆小星星，替對方加油
class RobotAvatar extends StatelessWidget {
  final DashboardMood mood;
  final double size;

  const RobotAvatar({super.key, required this.mood, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _RobotPainter(mood)),
    );
  }
}

class _RobotPainter extends CustomPainter {
  final DashboardMood mood;

  _RobotPainter(this.mood);

  static const Color _shell = Color(0xFFF2F5F4);
  static const Color _visor = Color(0xFF1F2D2A);
  static const Color _glow = Color(0xFF5CE1E6);
  static const Color _accent = Color(0xFF8FE3C8);

  @override
  void paint(Canvas canvas, Size size) {
    // 用 100×100 的座標系畫，再整體縮放到實際大小
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s);

    final shell = Paint()..color = _shell;
    final accent = Paint()..color = _accent;

    // 天線
    canvas.drawLine(
      const Offset(50, 13),
      const Offset(50, 22),
      Paint()
        ..color = _shell
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(50, 11), 4, accent);

    // 耳朵
    canvas.drawRRect(
      RRect.fromLTRBR(16, 35, 23, 50, const Radius.circular(3)),
      accent,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(77, 35, 84, 50, const Radius.circular(3)),
      accent,
    );

    // 頭＋面罩
    canvas.drawRRect(
      RRect.fromLTRBR(21, 21, 79, 63, const Radius.circular(15)),
      shell,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(28, 29, 72, 55, const Radius.circular(11)),
      Paint()..color = _visor,
    );

    // 身體＋胸口燈
    canvas.drawRRect(
      RRect.fromLTRBR(33, 66, 67, 94, const Radius.circular(12)),
      shell,
    );
    canvas.drawCircle(const Offset(50, 78), 4.5, accent);

    // 手臂：good 舉右手打招呼，其他兩手自然垂放
    final armPaint = Paint()
      ..color = _shell
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(30, 72), const Offset(24, 88), armPaint);
    if (mood == DashboardMood.good) {
      canvas.drawLine(const Offset(70, 70), const Offset(82, 56), armPaint);
    } else {
      canvas.drawLine(const Offset(70, 72), const Offset(76, 88), armPaint);
    }

    _paintFace(canvas);
    if (mood == DashboardMood.encourage) _paintSparkle(canvas);

    canvas.restore();
  }

  void _paintFace(Canvas canvas) {
    final glowStroke = Paint()
      ..color = _glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    if (mood == DashboardMood.good) {
      // 笑瞇眼：向上彎的弧線
      for (final cx in [41.0, 59.0]) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, 42), width: 10, height: 9),
          math.pi,
          math.pi,
          false,
          glowStroke,
        );
      }
    } else {
      final eye = Paint()..color = _glow;
      canvas.drawCircle(const Offset(41, 40), 4.5, eye);
      canvas.drawCircle(const Offset(59, 40), 4.5, eye);
    }

    // 嘴巴：good 笑得比較開
    final mouthWidth = mood == DashboardMood.good ? 14.0 : 10.0;
    canvas.drawArc(
      Rect.fromCenter(
        center: const Offset(50, 46),
        width: mouthWidth,
        height: 8,
      ),
      0.15 * math.pi,
      0.7 * math.pi,
      false,
      glowStroke,
    );
  }

  void _paintSparkle(Canvas canvas) {
    final path = Path();
    const c = Offset(85, 22);
    const r = 7.0;
    const inner = 2.2;
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final radius = i.isEven ? r : inner;
      final p = c + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD66B));
  }

  @override
  bool shouldRepaint(covariant _RobotPainter oldDelegate) =>
      oldDelegate.mood != mood;
}
