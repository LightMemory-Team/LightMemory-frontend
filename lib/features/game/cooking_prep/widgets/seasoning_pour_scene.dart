import 'package:flutter/material.dart';

/// 調味階段的「展示畫面」（單獨展示物品用，每輪答完展示新物品時，只要
/// 當時 current_stage 是 intermediate 就會用到，不是只有開局才會出現）：
/// 鍋子裡是清水（借用現有鍋子圖疊一層淡藍色模擬清水），調味料罐緊貼鍋緣、
/// 微微傾斜，像準備要倒進鍋子的構圖（不再浮空在畫面上方一大截）。
///
/// [maxHeight] 是呼叫端量出來、這個場景實際可以用的高度上限（見
/// cooking_prep_game_page.dart 的 _buildPreviewPhase）。只靠螢幕寬度算
/// 尺寸在橫向螢幕上會算出太高的場景，超出實際可用高度就溢出，所以這裡
/// 一定要再依 maxHeight 夾一次，確保不會超過真正可用的空間。
class SeasoningPourScene extends StatelessWidget {
  final String potImagePath;
  final String seasoningImagePath;
  final double maxHeight;

  const SeasoningPourScene({
    super.key,
    required this.potImagePath,
    required this.seasoningImagePath,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    var potSize = (screenWidth * 0.3).clamp(150.0, 230.0);
    // 整體場景縮短了（調味料現在緊貼鍋緣，不用再留一大截空間給它浮空），
    // sceneHeight = potSize * 1.15，反推能符合 maxHeight 的 potSize 上限。
    final maxPotSizeForHeight = maxHeight / 1.15;
    if (potSize > maxPotSizeForHeight) {
      potSize = maxPotSizeForHeight.clamp(80.0, potSize);
    }
    final containerSize = potSize * 0.45;

    return SizedBox(
      width: potSize * 1.3,
      height: potSize * 1.15,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 柔和偏灰黑、往下偏移的陰影，讓鍋子有立體感，跟切菜階段的砧板
          // 陰影風格一致。borderRadius 讓陰影貼合鍋子的圓弧外形，不是
          // 沿著圖片矩形邊界的硬陰影色塊。
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(potSize * 0.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.lightBlue.withValues(alpha: 0.25),
                BlendMode.srcATop,
              ),
              child: Image.asset(
                potImagePath,
                width: potSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.soup_kitchen_outlined,
                  size: potSize * 0.6,
                  color: Colors.black26,
                ),
              ),
            ),
          ),
          // 緊貼鍋子正上方、貼著鍋緣的位置（bottom 用鍋子本身高度的估計值，
          // 讓調味料罐的底部剛好落在鍋緣附近，不再浮空在畫面上方一大截），
          // 微微傾斜營造「準備要倒進鍋子」的自然構圖。
          Positioned(
            bottom: potSize * 0.62,
            right: potSize * 0.08,
            child: Transform.rotate(
              angle: 0.45,
              child: Image.asset(
                seasoningImagePath,
                width: containerSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported_outlined,
                  size: containerSize * 0.6,
                  color: Colors.black26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
