import 'package:flutter/material.dart';

/// 切菜階段的「展示畫面」（單獨展示物品用，開局展示 A、B 兩次、之後每輪
/// 答完展示新物品都會用到）：砧板置中、食材（原始整顆型態）放在砧板上、
/// 刀直立在砧板右側，靜態不動——版面跟 chopping_reward_scene.dart 的初始
/// （answer 觸發前）畫面刻意用同一組比例常數，只是這裡不接
/// AnimationController，純粹靜態展示。不加陰影（使用者明確要求拿掉）。
///
/// [maxHeight] 是呼叫端量出來、這個場景實際可以用的高度上限（見
/// cooking_prep_game_page.dart 的 _buildPreviewPhase）。只靠螢幕寬度算
/// 尺寸在橫向螢幕上會算出太高的場景，超出實際可用高度就溢出，所以這裡
/// 一定要再依 maxHeight 夾一次，確保不會超過真正可用的空間；基準尺寸
/// 已經比原本放大約 12%，這個 maxHeight 保護機制仍然會在橫向螢幕不夠高
/// 時自動縮小，不會被切邊。
class ChoppingDisplayScene extends StatelessWidget {
  final String foodImagePath;
  final String boardImagePath;
  final String knifeImagePath;
  final double maxHeight;

  const ChoppingDisplayScene({
    super.key,
    required this.foodImagePath,
    required this.boardImagePath,
    required this.knifeImagePath,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 基準尺寸比原本（0.45 / 170-300）放大約 12%。
    var boardWidth = (screenWidth * 0.50).clamp(190.0, 335.0);
    // sceneHeight = boardWidth * 0.66 * 1.35，反推能符合 maxHeight 的
    // boardWidth 上限，取比較小的那個。
    final maxBoardWidthForHeight = maxHeight / (0.66 * 1.35);
    if (boardWidth > maxBoardWidthForHeight) {
      boardWidth = maxBoardWidthForHeight.clamp(80.0, boardWidth);
    }
    final boardHeight = boardWidth * 0.66;
    final knifeWidth = boardWidth * 0.42;
    final foodSize = boardWidth * 0.38;
    final sceneWidth = boardWidth + knifeWidth * 0.6;
    final sceneHeight = boardHeight * 1.35;
    final knifeRestX = boardWidth * 0.70;

    return SizedBox(
      width: sceneWidth,
      height: sceneHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            // 不加陰影，純粹顯示砧板圖片。
            child: Image.asset(
              boardImagePath,
              width: boardWidth,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
          Positioned(
            left: boardWidth * 0.31,
            bottom: boardHeight * 0.42,
            child: Image.asset(
              foodImagePath,
              width: foodSize,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.image_not_supported_outlined,
                size: foodSize * 0.6,
                color: Colors.black26,
              ),
            ),
          ),
          Positioned(
            left: knifeRestX,
            bottom: boardHeight * 0.5,
            child: Image.asset(
              knifeImagePath,
              width: knifeWidth,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
