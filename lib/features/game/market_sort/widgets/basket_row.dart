import 'package:flutter/material.dart';

/// 單一個籃子要顯示的內容：文字標籤、底色、對應的規則值
/// （regRule值用Object是因為ItemCategory/ItemColor/ItemFreshness是不同型別，
/// 跟MarketSortItem.valueFor()回傳型別一致，方便呼叫端比對答案時直接用==）
class BasketOption {
  final String label; // 例如 "蔬菜"
  final String emoji; // 例如 "🥬"
  final Color color;
  final Object value; // 對應 ItemCategory.vegetable 這類值

  const BasketOption({
    required this.label,
    required this.emoji,
    required this.color,
    required this.value,
  });
}

/// 下方並排的籃子列，數量依規則而定（2或3個）
/// 目前先做「靜態顯示」版本，不含拖曳互動（DragTarget留到階段4再加）
class BasketRow extends StatelessWidget {
  final List<BasketOption> options;

  const BasketRow({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: options.map((option) => _BasketItem(option: option)).toList(),
    );
  }
}

class _BasketItem extends StatelessWidget {
  final BasketOption option;

  const _BasketItem({required this.option});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 籃子插畫先用emoji頂著，之後有正式插畫素材時換成Image.asset
        const Text('🧺', style: TextStyle(fontSize: 64)), // 48→64
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: option.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${option.label} ${option.emoji}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28, 
            ),
          ),
        ),
      ],
    );
  }
}