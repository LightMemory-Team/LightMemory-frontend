import 'package:flutter/material.dart';
import '../models/cooking_prep_asset_map.dart';

/// 切菜／調味／烹飪三階段共用的「選項畫面」版式：
/// 頂部橫幅「請問上一個是什麼」＋下方一塊淺粉色圓角容器，
/// 容器內用一條分隔線切成左右兩個可點擊的區塊，各放一張物品圖示。
/// 三階段呼叫時只有 [items]（對應的兩個物品字串）不同，版式完全共用。
class MemoryRecallOptionCards extends StatelessWidget {
  final List<String> items; // 固定 2 個
  final String? selectedItem;
  final bool hasAnswered;
  final bool? isCorrect; // 目前選中的那個作答結果，還沒作答時是 null
  final void Function(String item) onTap;

  const MemoryRecallOptionCards({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.hasAnswered,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBanner(),
        const SizedBox(height: 16),
        Expanded(child: _buildCardsContainer()),
      ],
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEAE1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        '請問上一個是什麼',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5B5B4F),
        ),
      ),
    );
  }

  Widget _buildCardsContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6EC),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(child: _buildCard(items[0])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(width: 2, color: const Color(0xFFE3C6D1)),
          ),
          Expanded(child: _buildCard(items[1])),
        ],
      ),
    );
  }

  Widget _buildCard(String item) {
    final isSelected = selectedItem == item;
    // hasAnswered 在點下去的當下就會是 true（送出 round/answer/ 前），
    // 但 isCorrect 要等後端回應才會有值，中間有一段 isCorrect 還是 null
    // 的空窗期。原本只看 hasAnswered && isSelected 就決定要不要畫徽章，
    // 會讓這段空窗期被 isCorrect==true ? ... : ... 的 else 分支當成「答錯」
    // 處理，畫面上會先閃一下叉叉，等真正結果回來才更正——如果實際答對，
    // 使用者就會看到「先顯示答錯、接著又播放答對動畫」這種前後矛盾的畫面。
    // 加上 isCorrect != null 這個條件，讓徽章真正等結果確定了才顯示。
    final showBadge = hasAnswered && isSelected && isCorrect != null;

    Color tint = Colors.transparent;
    Widget? badge;
    if (showBadge) {
      if (isCorrect == true) {
        tint = const Color(0xFFD9F2DF);
        badge = const Icon(
          Icons.check_circle,
          color: Color(0xFF4CAF50),
          size: 30,
        );
      } else {
        tint = const Color(0xFFFFE9D6);
        badge = const Icon(Icons.cancel, color: Color(0xFFFF9800), size: 30);
      }
    }

    return GestureDetector(
      key: ValueKey(item),
      onTap: hasAnswered ? null : () => onTap(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Center(
              child: Image.asset(
                imagePathForMemoryRecallItem(item),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported_outlined,
                  size: 56,
                  color: Colors.black26,
                ),
              ),
            ),
            if (badge != null) Positioned(top: 0, right: 0, child: badge),
          ],
        ),
      ),
    );
  }
}
