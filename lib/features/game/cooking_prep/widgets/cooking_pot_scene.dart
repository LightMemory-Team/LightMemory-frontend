import 'package:flutter/material.dart';

/// 烹飪階段的「展示畫面」（單獨展示物品用，每輪答完展示新物品時，只要
/// 當時 current_stage 是 advanced 就會用到，不是只有開局才會出現）：
/// 只顯示這一輪要記住的食材一個大圖示，畫面乾淨、聚焦在單一食材上，不再
/// 放鍋子或周圍的裝飾食材堆（之前那版鍋子＋裝飾食材堆的做法看起來雜亂，
/// 而且其實從來沒有真的顯示過「這一輪的食材」本身，已經拿掉）。
///
/// [maxHeight] 是呼叫端量出來、這個場景實際可以用的高度上限（見
/// cooking_prep_game_page.dart 的 _buildPreviewPhase）。只靠螢幕寬度算
/// 尺寸在橫向螢幕上會算出太高的場景，超出實際可用高度就溢出，所以這裡
/// 一定要再依 maxHeight 夾一次，確保不會超過真正可用的空間。
class CookingPotScene extends StatelessWidget {
  final String itemImagePath;
  final double maxHeight;

  const CookingPotScene({
    super.key,
    required this.itemImagePath,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    var itemSize = (screenWidth * 0.4).clamp(200.0, 320.0);
    if (itemSize > maxHeight) {
      itemSize = maxHeight.clamp(80.0, itemSize);
    }

    return Image.asset(
      itemImagePath,
      width: itemSize,
      height: itemSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.image_not_supported_outlined,
        size: itemSize * 0.6,
        color: Colors.black26,
      ),
    );
  }
}
