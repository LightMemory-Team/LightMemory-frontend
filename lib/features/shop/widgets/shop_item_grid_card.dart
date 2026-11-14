import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../models/shop_models.dart';
import 'shop_item_card.dart';

/// 熱門兌換用的直向商品卡片（一排兩張，以圖片為主）
///
/// - 上方：正方形商品圖片（商品還沒有圖片時用品牌 logo）
/// - 下方：商品名稱（最多兩行）、品牌、點數、兌換按鈕
/// - 兌換流程跟 [ShopItemCard] 一樣（showRedeemDialog）
///
/// 放在 IntrinsicHeight 的 Row 裡，同一排兩張卡片會一樣高，
/// 點數和按鈕固定貼在卡片底部，字級放大也不會溢版。
class ShopItemGridCard extends StatelessWidget {
  final ShopItem item;

  /// 目前的點數，用來判斷換不換得起
  final int currentPoints;

  const ShopItemGridCard({
    super.key,
    required this.item,
    required this.currentPoints,
  });

  bool get _canAfford => currentPoints >= item.points;

  @override
  Widget build(BuildContext context) {
    final colors = ShopColors.of(
      isDark: AppSettings.isDarkMode.value,
      isHighContrast: AppSettings.isHighContrast.value,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: colors.isHighContrast
            ? Border.all(color: colors.title, width: 2)
            : Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(aspectRatio: 1, child: _buildImage(colors)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(17),
                      fontWeight: FontWeight.bold,
                      color: colors.title,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.brandName,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(14),
                      fontWeight: FontWeight.w600,
                      color: colors.green,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, size: 22, color: Color(0xFFE5A823)),
                      const SizedBox(width: 4),
                      // 字級放大時「150 點」放不下就縮小，不斷成兩行
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${item.points} 點',
                            style: TextStyle(
                              fontSize: AppSettings.scaleFont(18),
                              fontWeight: FontWeight.bold,
                              color: colors.green,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _canAfford
                          ? () => showRedeemDialog(context, item, currentPoints)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: colors.disabledBg,
                        disabledForegroundColor: colors.disabledText,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _canAfford ? '兌換' : '點數不足',
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 商品圖片：白底（深色模式也一樣，圖片才看得清楚）
  ///
  /// 有商品圖就填滿；用品牌 logo 代替時，全聯是長方形旗幟直接填滿，
  /// 星巴克、農會整張放進去、四周留白
  Widget _buildImage(ShopColors colors) {
    final String? image = item.displayImage;
    final Widget fallback = Container(
      color: colors.iconBg,
      child: Icon(item.icon, size: 56, color: colors.green),
    );
    if (image == null) return fallback;

    final bool fill = item.imageAsset != null || item.brandId == 'pxmart';
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(fill ? 0 : 20),
      child: Image.asset(
        image,
        fit: fill ? BoxFit.cover : BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}
