import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../models/market_sort_item.dart';

class BasketOption {
  final String label;
  final String emoji;
  final Color color;
  final Object value;

  const BasketOption({
    required this.label,
    required this.emoji,
    required this.color,
    required this.value,
  });
}

class BasketRow extends StatelessWidget {
  final List<BasketOption?> options;
  final bool compact;
  final void Function(MarketSortItem item, Object bucketValue)? onAccept;
  final Object? highlightValue;
  final bool? highlightIsCorrect;

  const BasketRow({
    super.key,
    required this.options,
    this.compact = false,
    this.onAccept,
    this.highlightValue,
    this.highlightIsCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: options.map((option) {
        if (option == null) {
          return SizedBox(width: compact ? 44 : 96);
        }
        final isHighlighted = highlightValue == option.value;
        return _BasketItem(
          option: option,
          compact: compact,
          onAccept: onAccept,
          isHighlighted: isHighlighted,
          highlightIsCorrect: isHighlighted ? highlightIsCorrect : null,
        );
      }).toList(),
    );
  }
}

class _BasketItem extends StatelessWidget {
  final BasketOption option;
  final bool compact;
  final void Function(MarketSortItem item, Object bucketValue)? onAccept;
  final bool isHighlighted;
  final bool? highlightIsCorrect;

  const _BasketItem({
    required this.option,
    required this.compact,
    this.onAccept,
    this.isHighlighted = false,
    this.highlightIsCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final basketSize = compact ? 44.0 : 64.0;
    final labelFontSize = compact ? 18.0 : 28.0;
    final labelPaddingH = compact ? 10.0 : 14.0;
    final labelPaddingV = compact ? 6.0 : 10.0;
    // compact（教學彈窗）維持零額外padding，避免固定高度容器溢出；
    // 一般遊戲頁才加padding跟最小點擊區域，增加拖放判定的容錯空間
    final outerPadding = compact ? 0.0 : 10.0;
    final minTapHeight = compact ? 0.0 : 120.0;
    final minTapWidth = compact ? 0.0 : 96.0;

    Color? flashColor;
    if (isHighlighted && highlightIsCorrect != null) {
      flashColor = highlightIsCorrect! ? Colors.green : Colors.deepOrange;
    }

    return DragTarget<MarketSortItem>(
      onAcceptWithDetails: (details) {
        onAccept?.call(details.data, option.value);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(outerPadding),
          constraints: BoxConstraints(
            minWidth: minTapWidth,
            minHeight: minTapHeight,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: flashColor?.withValues(alpha: 0.25) ??
                (candidateData.isNotEmpty
                    ? AppTheme.primaryColor.withValues(alpha: 0.12)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🧺', style: TextStyle(fontSize: basketSize)),
              SizedBox(height: compact ? 4 : 6),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: labelPaddingH,
                  vertical: labelPaddingV,
                ),
                decoration: BoxDecoration(
                  color: option.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${option.label} ${option.emoji}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: labelFontSize,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}