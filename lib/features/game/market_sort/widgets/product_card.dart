import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/assets/item_visual_resolver.dart';
import '../models/market_sort_item.dart';

class ProductCard extends StatefulWidget {
  final MarketSortItem item;
  final bool isIdle;

  const ProductCard({super.key, required this.item, this.isIdle = false});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _bounce = Tween<double>(begin: 0, end: 14).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isIdle) {
      _controller.repeat(reverse: true); // 來回播放，做出晃動效果
    }
  }

  // 當外面傳進來的isIdle值改變時（例如長者開始操作了），要跟著調整動畫狀態，
  // 不是只有initState第一次建立時判斷一次
  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isIdle && !oldWidget.isIdle) {
      _controller.repeat(reverse: true);
    } else if (!widget.isIdle && oldWidget.isIdle) {
      _controller.stop();
      _controller.value = 0; // 停止時歸零，避免卡在晃動途中的位置
    }
  }

  // StatefulWidget只要用了AnimationController，一定要在dispose()裡關掉它，
  // 不然這個畫面被切走之後，動畫還在背景空跑，會造成記憶體洩漏
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _bounce,
          builder: (context, child) {
            final offset = widget.isIdle ? _bounce.value : 0.0;
            return Transform.translate(
              offset: Offset(0, offset),
              child: child,
            );
          },
          child: Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(
              color: AppTheme.cardColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: buildItemVisual(widget.item, size: 70),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.isIdle)
          const Icon(
            Icons.arrow_downward,
            color: AppTheme.primaryColor,
            size: 28,
          ),
        const SizedBox(height: 8),
        Text(
          widget.isIdle ? '請把商品拖到正確的籃子裡！' : widget.item.name,
          style: TextStyle(
            fontSize: widget.isIdle ? 20 : 28,
            fontWeight: FontWeight.bold,
            color: widget.isIdle ? AppTheme.primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }
}