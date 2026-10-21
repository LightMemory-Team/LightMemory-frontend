import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// 捲到畫面上才進場的區塊（週報表用）：淡入＋由下往上滑一小段，
/// 只播一次，捲回去不會重播。
///
/// [builder] 會拿到 `revealed`，區塊裡的數字跳動、長條長出來等動畫
/// 可以等 revealed 變 true 才開始，跟進場同步。
/// 系統開啟「減少動態」時直接顯示，不播動畫。
///
/// [onRevealed] 在區塊第一次出現在畫面上時呼叫一次（旅程線亮圓點用）。
/// 「減少動態」時一樣會跟著捲動呼叫，只是區塊本身不播動畫。
class RevealOnScroll extends StatefulWidget {
  final Widget Function(BuildContext context, bool revealed) builder;
  final VoidCallback? onRevealed;

  const RevealOnScroll({super.key, required this.builder, this.onRevealed});

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll> {
  final Key _detectorKey = UniqueKey();
  bool _revealed = false;

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_revealed || !mounted) return;
    // 區塊比畫面還高時 visibleFraction 永遠不會很大，所以也看實際露出的高度
    if (info.visibleFraction > 0.2 || info.visibleBounds.height > 140) {
      setState(() => _revealed = true);
      widget.onRevealed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final content = reduceMotion
        ? widget.builder(context, true)
        : widget
              .builder(context, _revealed)
              .animate(target: _revealed ? 1 : 0)
              .fadeIn(duration: 500.ms, curve: Curves.easeOut)
              .slideY(
                begin: 0.08,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              );
    return VisibilityDetector(
      key: _detectorKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: content,
    );
  }
}
