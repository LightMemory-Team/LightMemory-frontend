import 'package:flutter/material.dart';
import '../models/shop_models.dart';
import 'shop_item_card.dart';

/// 圓形品牌 logo（商城品牌按鈕、品牌頁標題共用）
///
/// - 底色固定白色（深色模式也一樣），logo 才看得清楚
/// - 星巴克本身是圓形，整張放進去留白邊；全聯、農會裁成圓形（見 ShopBrand.logoFit）
/// - 圖片讀不到時顯示品牌圖示
class ShopBrandLogo extends StatelessWidget {
  final ShopBrand brand;

  /// 直徑
  final double size;

  final ShopColors colors;

  const ShopBrandLogo({
    super.key,
    required this.brand,
    required this.colors,
    this.size = 84,
  });

  @override
  Widget build(BuildContext context) {
    final String? logo = brand.logoAsset;
    final Widget fallbackIcon = Container(
      color: colors.iconBg,
      child: Icon(brand.icon, size: size * 0.48, color: colors.green),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: colors.isHighContrast
            ? Border.all(color: colors.title, width: 2)
            : Border.all(color: colors.border, width: size >= 60 ? 1.5 : 1),
      ),
      child: ClipOval(
        child: logo == null
            ? fallbackIcon
            : Padding(
                // 星巴克整張放進去，留一點白邊；其他裁成圓形不留邊
                padding: EdgeInsets.all(
                  brand.logoFit == BoxFit.contain ? size * 0.107 : 0,
                ),
                child: Transform.scale(
                  scale: brand.logoScale,
                  child: Image.asset(
                    logo,
                    fit: brand.logoFit,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => fallbackIcon,
                  ),
                ),
              ),
      ),
    );
  }
}
