import 'package:flutter/material.dart';
import 'dashboard_palette.dart';

/// 週報表的一「頁」：左側旅程線＋內容。
///
/// - 最小高度 [minHeight]，內容預設靠上對齊；[centered] 為 true 時
///   垂直置中（收尾頁用）
/// - 左邊 [railWidth] 寬的窄欄畫細線和圓點，內容在窄欄右邊，不會被壓到
/// - [lit]：這一頁出現過了，圓點和上半段線亮起；[nextLit]：下一頁也
///   出現過了，下半段線（連到下一頁）才亮
/// - [bottomGap] 是跟下一頁之間的留白，算在這一頁裡，線才會連續
class StoryStep extends StatelessWidget {
  static const double railWidth = 24;

  /// 靠上對齊時，圓點中心離這一頁頂端的距離（對齊旁白的機器人頭像）
  static const double _topDotCenter = 24;
  static const double _dotSize = 14;

  final double minHeight;
  final bool lit;
  final bool nextLit;
  final bool isFirst;
  final bool isLast;
  final bool centered;
  final double bottomGap;
  final DashboardPalette palette;
  final Widget child;

  const StoryStep({
    super.key,
    required this.minHeight,
    required this.lit,
    required this.nextLit,
    required this.isFirst,
    required this.isLast,
    this.centered = false,
    required this.bottomGap,
    required this.palette,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 400);

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(left: railWidth + 4, bottom: bottomGap),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: centered
                ? Center(child: child)
                : Align(alignment: Alignment.topCenter, child: child),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: railWidth,
          child: ExcludeSemantics(
            child: Column(
              children: [
                // 上半段：頁頂到圓點（第一頁沒有上一段）。
                // 靠上對齊時是固定高度，圓點對齊旁白；置中時照比例放在中間
                if (centered)
                  Expanded(flex: 100, child: _upperLine(duration))
                else
                  SizedBox(
                    height: _topDotCenter - _dotSize / 2,
                    child: _upperLine(duration),
                  ),
                _Dot(lit: lit, palette: palette, duration: duration),
                // 下半段：圓點到下一頁（含留白）；最後一頁沒有
                Expanded(
                  flex: centered ? _lowerFlex() : 1,
                  child: isLast
                      ? const SizedBox.shrink()
                      : _Line(
                          lit: nextLit,
                          palette: palette,
                          duration: duration,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _upperLine(Duration duration) => isFirst
      ? const SizedBox.shrink()
      : _Line(lit: lit, palette: palette, duration: duration);

  /// 置中時，圓點要對齊內容區（扣掉底部留白）的正中間：
  /// 上半段＝內容高的一半，下半段＝內容高的一半＋留白。
  /// 這裡用 minHeight 估內容高；內容比 minHeight 高時圓點會稍微偏上，
  /// 對看的人沒有影響。
  int _lowerFlex() {
    if (isLast) return 100;
    final half = minHeight / 2;
    return ((half + bottomGap) / half * 100).round();
  }
}

class _Line extends StatelessWidget {
  final bool lit;
  final DashboardPalette palette;
  final Duration duration;

  const _Line({
    required this.lit,
    required this.palette,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOut,
        width: 2,
        color: lit ? palette.primary : palette.track,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool lit;
  final DashboardPalette palette;
  final Duration duration;

  const _Dot({
    required this.lit,
    required this.palette,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      width: StoryStep._dotSize,
      height: StoryStep._dotSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? palette.primary : palette.card,
        border: Border.all(
          color: lit ? palette.primary : palette.grid,
          width: 2,
        ),
      ),
    );
  }
}
