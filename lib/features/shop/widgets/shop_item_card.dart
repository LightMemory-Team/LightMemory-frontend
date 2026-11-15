import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../core/network/error_message.dart';
import '../models/shop_models.dart';
import '../pages/my_tickets_page.dart';
import 'shop_brand_logo.dart';
import '../services/shop_service.dart';

/// 點數商城的商品卡片（直向排列，一張一列，長輩只要上下滑）
///
/// - 點數夠：綠色「兌換」按鈕
/// - 點數不夠：灰色「點數不足」，不能按
/// - 按「兌換」先跳確認視窗；目前後端還沒有兌換 API，確認後假扣點並把券加進「我的票券」
class ShopItemCard extends StatelessWidget {
  final ShopItem item;

  /// 目前的點數，用來判斷換不換得起
  final int currentPoints;

  /// 要不要顯示品牌名稱（品牌頁裡都是同一個品牌，可以不顯示）
  final bool showBrand;

  const ShopItemCard({
    super.key,
    required this.item,
    required this.currentPoints,
    this.showBrand = true,
  });

  bool get _canAfford => currentPoints >= item.points;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final colors = ShopColors.of(
          isDark: AppSettings.isDarkMode.value,
          isHighContrast: AppSettings.isHighContrast.value,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: colors.isHighContrast
                ? Border.all(color: colors.title, width: 2)
                : Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 商品圖片：有商品圖用商品圖，沒有就用圓形品牌 logo
                  item.imageAsset != null
                      ? ClipOval(
                          child: Image.asset(
                            item.imageAsset!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                ShopBrandLogo(
                                  brand: ShopBrand(id: item.brandId, name: item.brandName),
                                  colors: colors,
                                  size: 56,
                                ),
                          ),
                        )
                      : ShopBrandLogo(
                          brand: ShopBrand(id: item.brandId, name: item.brandName),
                          colors: colors,
                          size: 56,
                        ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(18),
                            fontWeight: FontWeight.bold,
                            color: colors.title,
                          ),
                        ),
                        if (showBrand) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.brandName,
                            style: TextStyle(
                              fontSize: AppSettings.scaleFont(14),
                              fontWeight: FontWeight.w600,
                              color: colors.green,
                            ),
                          ),
                        ],
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: AppSettings.scaleFont(14),
                              color: colors.subtitle,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 點數＋兌換按鈕
              Row(
                children: [
                  const Icon(Icons.monetization_on, size: 24, color: Color(0xFFE5A823)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${item.points} 點',
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(19),
                        fontWeight: FontWeight.bold,
                        color: colors.green,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _canAfford
                          ? () => showRedeemDialog(context, item, currentPoints)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: colors.disabledBg,
                        disabledForegroundColor: colors.disabledText,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _canAfford ? '兌換' : '點數不足',
                        style: TextStyle(
                          fontSize: AppSettings.scaleFont(16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 兌換確認視窗
///
/// 目前後端還沒有兌換 API：按「確定兌換」後假扣點（只在 App 裡扣，見 MockRedeemPoints）
/// 並把券加進「我的票券」，SnackBar 的「查看」可以直接打開我的票券。
/// 商城頁、品牌頁有監聽扣點，點數會自動更新。
/// TODO：後端兌換 API 做好後，改成呼叫 API、用回傳的 total_points 更新點數。
Future<void> showRedeemDialog(
  BuildContext context,
  ShopItem item,
  int currentPoints,
) async {
  final colors = ShopColors.of(
    isDark: AppSettings.isDarkMode.value,
    isHighContrast: AppSettings.isHighContrast.value,
  );

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: colors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        '兌換確認',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: AppSettings.scaleFont(20),
          fontWeight: FontWeight.bold,
          color: colors.title,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '確定要用 ${item.points} 點\n兌換「${item.name}」嗎？',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSettings.scaleFont(17),
              color: colors.title,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '兌換後剩下 ${currentPoints - item.points} 點',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSettings.scaleFont(16),
              fontWeight: FontWeight.bold,
              color: colors.green,
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            '取消',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(16),
              color: colors.subtitle,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(
            '確定兌換',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(16),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  try {
    await ShopService().redeemMock(item);
  } catch (e) {
    debugPrint('❌ 兌換失敗: $e');
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          friendlyErrorMessage(e, fallback: '兌換失敗，請稍後再試一次'),
          style: TextStyle(fontSize: AppSettings.scaleFont(16)),
        ),
      ),
    );
    return;
  }

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      content: Text(
        '兌換成功！扣除 ${item.points} 點，已放進「我的票券」',
        style: TextStyle(fontSize: AppSettings.scaleFont(16)),
      ),
      action: SnackBarAction(
        label: '查看',
        textColor: const Color(0xFFF5C542),
        onPressed: () => navigator.push(
          MaterialPageRoute(builder: (context) => const MyTicketsPage()),
        ),
      ),
    ),
  );
}

/// 商城共用顏色：跟著深色模式、高對比切換
class ShopColors {
  final bool isDark;
  final bool isHighContrast;
  final Color pageBg;
  final Color cardBg;
  final Color border;
  final Color iconBg;
  final Color title;
  final Color subtitle;
  final Color green;
  final Color disabledBg;
  final Color disabledText;

  const ShopColors._({
    required this.isDark,
    required this.isHighContrast,
    required this.pageBg,
    required this.cardBg,
    required this.border,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.green,
    required this.disabledBg,
    required this.disabledText,
  });

  factory ShopColors.of({required bool isDark, required bool isHighContrast}) {
    if (isDark) {
      return ShopColors._(
        isDark: true,
        isHighContrast: isHighContrast,
        pageBg: const Color(0xFF121212),
        cardBg: const Color(0xFF1E1E1E),
        border: const Color(0xFF333333),
        iconBg: const Color(0xFF25382E),
        title: Colors.white,
        subtitle: const Color(0xFFCCCCCC),
        green: const Color(0xFF4CAF50),
        disabledBg: const Color(0xFF333333),
        disabledText: const Color(0xFF999999),
      );
    }
    return ShopColors._(
      isDark: false,
      isHighContrast: isHighContrast,
      pageBg: const Color(0xFFF5F4EE),
      cardBg: Colors.white,
      border: const Color(0xFFE5E5E5),
      iconBg: const Color(0xFFE3EDE5),
      title: isHighContrast ? Colors.black : const Color(0xFF1E1E1E),
      subtitle: isHighContrast ? Colors.black : const Color(0xFF595959),
      green: const Color(0xFF2E6342),
      disabledBg: const Color(0xFFDDDDDD),
      disabledText: isHighContrast ? Colors.black : const Color(0xFF777777),
    );
  }
}