import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../../app_settings.dart';
import '../models/shop_models.dart';
import '../widgets/shop_item_card.dart';

/// 票券 QR code 頁：從「我的票券」點一張券進來
///
/// - 上方：票券圖片（目前商品沒有圖片，先用品牌圖示）、票券名稱、品牌
/// - 正中央：QR code，固定白底黑碼（深色模式也一樣，店員才掃得到）
/// - 進來時把螢幕調到最亮，離開時恢復原本亮度（網頁版不支援，自動略過）
class TicketQrPage extends StatefulWidget {
  final MyTicket ticket;

  const TicketQrPage({super.key, required this.ticket});

  @override
  State<TicketQrPage> createState() => _TicketQrPageState();
}

class _TicketQrPageState extends State<TicketQrPage> {
  @override
  void initState() {
    super.initState();
    _setMaxBrightness();
  }

  @override
  void dispose() {
    _resetBrightness();
    super.dispose();
  }

  /// 只調這個 App 的亮度，不改系統設定，所以不用另外要權限
  Future<void> _setMaxBrightness() async {
    if (kIsWeb) return;
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);
    } catch (e) {
      debugPrint('⚠️ 調整螢幕亮度失敗: $e');
    }
  }

  Future<void> _resetBrightness() async {
    if (kIsWeb) return;
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint('⚠️ 恢復螢幕亮度失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.ticket.item;

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

        return Scaffold(
          backgroundColor: colors.pageBg,
          appBar: AppBar(
            backgroundColor: colors.pageBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            leadingWidth: 88,
            leading: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: colors.green),
              child: Text(
                '返回',
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(17),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              '使用票券',
              style: TextStyle(
                fontSize: AppSettings.scaleFont(20),
                fontWeight: FontWeight.bold,
                color: colors.green,
              ),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // QR code 最大 240，畫面窄（或橫向手機）時跟著縮小
                final double qrSize =
                    (constraints.maxWidth - 96).clamp(160.0, 240.0);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        decoration: BoxDecoration(
                          color: colors.cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: colors.isHighContrast
                              ? Border.all(color: colors.title, width: 2)
                              : Border.all(color: colors.border),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 票券圖片（之後有商品圖片再換）
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: colors.iconBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(item.icon, size: 48, color: colors.green),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              item.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppSettings.scaleFont(24),
                                fontWeight: FontWeight.bold,
                                color: colors.title,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.brandName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppSettings.scaleFont(17),
                                fontWeight: FontWeight.w600,
                                color: colors.green,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // QR code：固定白底黑碼
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colors.isHighContrast
                                      ? Colors.black
                                      : const Color(0xFFE5E5E5),
                                  width: colors.isHighContrast ? 2 : 1,
                                ),
                              ),
                              child: QrImageView(
                                data: widget.ticket.qrData,
                                size: qrSize,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '請出示此畫面給店員掃描',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppSettings.scaleFont(18),
                                fontWeight: FontWeight.bold,
                                color: colors.title,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${widget.ticket.redeemedDateText} 兌換',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppSettings.scaleFont(15),
                                color: colors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
