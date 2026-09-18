import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/assets/item_visual_resolver.dart';
import '../models/market_sort_item.dart';

class ProductCard extends StatefulWidget {
  final MarketSortItem item;
  final bool isIdle;
  final bool compact; // true時整體縮小，用於教學彈窗這類空間有限的地方

  const ProductCard({
    super.key,
    required this.item,
    this.isIdle = false,
    this.compact = false,
  });

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
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isIdle && !oldWidget.isIdle) {
      _controller.repeat(reverse: true);
    } else if (!widget.isIdle && oldWidget.isIdle) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circleSize = widget.compact ? 100.0 : 140.0;
    final visualSize = widget.compact ? 50.0 : 70.0;
    final nameFontSize = widget.compact ? 18.0 : 28.0;
    final idleFontSize = widget.compact ? 14.0 : 20.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
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
            width: circleSize,
            height: circleSize,
            decoration: const BoxDecoration(
              color: AppTheme.cardColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: buildItemVisual(widget.item, size: visualSize),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.isIdle)
          Icon(
            Icons.arrow_downward,
            color: AppTheme.primaryColor,
            size: widget.compact ? 20 : 28,
          ),
        const SizedBox(height: 6),
        Text(
          widget.isIdle ? '請把商品拖到正確的籃子裡！' : widget.item.name,
          style: TextStyle(
            fontSize: widget.isIdle ? idleFontSize : nameFontSize,
            fontWeight: FontWeight.bold,
            color: widget.isIdle ? AppTheme.primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }
}