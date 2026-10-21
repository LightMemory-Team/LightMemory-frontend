import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 六大能力雷達圖（長者數值），自己用 CustomPainter 畫，
/// 動畫跟標籤位置才控制得到。
///
/// 動畫：
/// - 進場：長者數值的多邊形從中心長到實際位置，
///   頂點的圓點最後輕輕彈出，能力名稱跟著淡入
/// - 資料更新：從目前的形狀平滑變成新的形狀，不會先縮回中心
/// - 系統開啟「減少動態」時直接顯示完成的樣子
///
/// [values] 是 0～100，順序跟 [labels] 一樣（從正上方開始
/// 順時針）；沒玩過的能力傳 null，畫在 0 的位置。
/// [notes] 是名稱下方的小字（例如「近期未遊玩」），不需要的傳 null。
class AbilityRadarChart extends StatefulWidget {
  final List<String> labels;
  final List<String?>? notes;
  final List<double?> values;
  final Color userColor;
  final Color gridColor;
  final Color labelColor;
  final double labelFontSize;

  const AbilityRadarChart({
    super.key,
    required this.labels,
    this.notes,
    required this.values,
    required this.userColor,
    required this.gridColor,
    required this.labelColor,
    required this.labelFontSize,
  });

  @override
  State<AbilityRadarChart> createState() => _AbilityRadarChartState();
}

class _AbilityRadarChartState extends State<AbilityRadarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // 動畫起點／終點；進場時起點是全部 0（從中心長出來）
  late List<double> _fromValues;
  late List<double> _toValues;

  // true 代表正在播進場（名稱淡入、圓點彈出），
  // false 代表資料更新（只做形狀變化）
  bool _isEntrance = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fromValues = List.filled(widget.values.length, 0);
    _toValues = _normalize(widget.values);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.status == AnimationStatus.dismissed) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AbilityRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newValues = _normalize(widget.values);
    if (_listEquals(newValues, _toValues)) return;
    _fromValues = _currentValues();
    _toValues = newValues;
    _isEntrance = false;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<double> _normalize(List<double?> values) =>
      values.map((v) => ((v ?? 0) / 100).clamp(0.0, 1.0)).toList();

  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  double _shapeProgress() {
    final interval = _isEntrance
        ? const Interval(0, 1, curve: Curves.easeOutCubic)
        : const Interval(0, 1, curve: Curves.easeInOutCubic);
    return interval.transform(_controller.value);
  }

  List<double> _currentValues() {
    final t = _shapeProgress();
    return List.generate(
      _toValues.length,
      (i) => _fromValues[i] + (_toValues[i] - _fromValues[i]) * t,
    );
  }

  double _entrancePart(double begin, double end, Curve curve) {
    if (!_isEntrance) return 1;
    return Interval(begin, end, curve: curve).transform(_controller.value);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _RadarPainter(
              labels: widget.labels,
              notes: widget.notes,
              values: _currentValues(),
              labelOpacity: _entrancePart(0.1, 0.5, Curves.easeOut),
              dotScale: _entrancePart(0.6, 1, Curves.easeOutBack),
              userColor: widget.userColor,
              gridColor: widget.gridColor,
              labelColor: widget.labelColor,
              labelFontSize: widget.labelFontSize,
            ),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<String> labels;
  final List<String?>? notes;
  final List<double> values;
  final double labelOpacity;
  final double dotScale;
  final Color userColor;
  final Color gridColor;
  final Color labelColor;
  final double labelFontSize;

  _RadarPainter({
    required this.labels,
    required this.notes,
    required this.values,
    required this.labelOpacity,
    required this.dotScale,
    required this.userColor,
    required this.gridColor,
    required this.labelColor,
    required this.labelFontSize,
  });

  static const double _labelGap = 10;
  static const int _ringCount = 4;

  double _angle(int i) => -math.pi / 2 + i * 2 * math.pi / labels.length;

  Offset _point(Offset center, double radius, int i, double value) {
    final a = _angle(i);
    return center + Offset(math.cos(a), math.sin(a)) * radius * value;
  }

  List<TextPainter> _layoutLabels(double fontSize) {
    final color = labelColor.withValues(alpha: labelColor.a * labelOpacity);
    return [
      for (final (i, label) in labels.indexed)
        TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            children: [
              if (notes?[i] != null)
                TextSpan(
                  text: '\n${notes![i]}',
                  style: TextStyle(
                    fontSize: fontSize * 0.75,
                    fontWeight: FontWeight.normal,
                    color: color,
                  ),
                ),
            ],
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
  }

  /// 依名稱實際寬高算出圖本身能用多大的半徑：左右兩側的名稱要放得下、
  /// 上下的名稱也要放得下。字體設定很大時圖會被擠得太小，這時把名稱
  /// 字級往下調（最小 13），讓圖維持至少 1/4 寬的半徑。
  ({double radius, List<TextPainter> painters}) _fit(Size size) {
    var fontSize = labelFontSize;
    while (true) {
      final painters = _layoutLabels(fontSize);
      final maxWidth = painters.map((p) => p.width).reduce(math.max);
      final maxHeight = painters.map((p) => p.height).reduce(math.max);
      final byWidth =
          (size.width / 2 - _labelGap - maxWidth) / math.cos(math.pi / 6);
      final byHeight = size.height / 2 - _labelGap - maxHeight;
      final radius = math.min(byWidth, byHeight);
      if (radius >= size.width * 0.25 || fontSize <= 13) {
        return (radius: math.max(radius, 0), painters: painters);
      }
      fontSize -= 1;
    }
  }

  Path _polygon(Offset center, double radius, List<double> vals) {
    final path = Path();
    for (var i = 0; i < vals.length; i++) {
      final p = _point(center, radius, i, vals[i]);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (labels.isEmpty) return;
    final center = size.center(Offset.zero);
    final fit = _fit(size);
    final radius = fit.radius;

    // 格線：同心六邊形＋放射線
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var ring = 1; ring <= _ringCount; ring++) {
      canvas.drawPath(
        _polygon(center, radius, List.filled(labels.length, ring / _ringCount)),
        gridPaint,
      );
    }
    for (var i = 0; i < labels.length; i++) {
      canvas.drawLine(center, _point(center, radius, i, 1), gridPaint);
    }

    // 長者數值：深色線＋淡淡的填色＋頂點圓點
    final userPath = _polygon(center, radius, values);
    canvas.drawPath(
      userPath,
      Paint()..color = userColor.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      userPath,
      Paint()
        ..color = userColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    if (dotScale > 0) {
      final dotPaint = Paint()..color = userColor;
      for (var i = 0; i < values.length; i++) {
        canvas.drawCircle(
          _point(center, radius, i, values[i]),
          5 * dotScale,
          dotPaint,
        );
      }
    }

    // 能力名稱：放在頂點外側，依方向對齊
    for (var i = 0; i < labels.length; i++) {
      final painter = fit.painters[i];
      final anchor = _point(center, radius + _labelGap, i, 1);
      final dx = math.cos(_angle(i));
      final dy = math.sin(_angle(i));
      double left;
      if (dx > 0.1) {
        left = anchor.dx;
      } else if (dx < -0.1) {
        left = anchor.dx - painter.width;
      } else {
        left = anchor.dx - painter.width / 2;
      }
      double top;
      if (dx.abs() <= 0.1) {
        top = dy < 0 ? anchor.dy - painter.height : anchor.dy;
      } else {
        top = anchor.dy - painter.height / 2;
      }
      painter.paint(canvas, Offset(left, top));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => true;
}
