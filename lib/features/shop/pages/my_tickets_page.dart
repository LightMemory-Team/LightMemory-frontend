import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../core/network/error_message.dart';
import '../models/shop_models.dart';
import '../services/shop_service.dart';
import '../widgets/shop_item_card.dart';
import 'ticket_qr_page.dart';

/// 我的票券（卡夾包）：點數商城「我的票券」按鈕進來
///
/// - 直向票券卡片，一張一列，新兌換的在前
/// - 點一張票券 → 票券 QR code 頁（螢幕自動調到最亮）
/// - 目前是假資料，見 ShopService.getMyTickets()
class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  final ShopService _service = ShopService();

  List<MyTicket> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = _tickets.isEmpty;
      _errorMessage = null;
    });
    try {
      final tickets = await _service.getMyTickets();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 讀取我的票券失敗: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = friendlyErrorMessage(e, fallback: '目前無法載入票券');
      });
    }
  }

  void _openTicket(MyTicket ticket) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => TicketQrPage(ticket: ticket)),
    );
  }

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
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.confirmation_number_outlined, color: colors.green),
                const SizedBox(width: 6),
                Text(
                  '我的票券',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(20),
                    fontWeight: FontWeight.bold,
                    color: colors.green,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(child: _buildBody(colors)),
        );
      },
    );
  }

  Widget _buildBody(ShopColors colors) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.green));
    }

    if (_errorMessage != null || _tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _errorMessage != null
                    ? Icons.cloud_off_outlined
                    : Icons.confirmation_number_outlined,
                size: 56,
                color: colors.subtitle,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? '還沒有兌換的票券\n去點數商城看看吧',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(18),
                  color: colors.subtitle,
                  height: 1.5,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    '再試一次',
                    style: TextStyle(fontSize: AppSettings.scaleFont(16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: colors.green,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            '點一下票券，出示 QR code 給店員掃描',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(16),
              color: colors.subtitle,
            ),
          ),
          const SizedBox(height: 12),
          ..._tickets.map((ticket) => _buildTicketCard(ticket, colors)),
        ],
      ),
    );
  }

  /// 票券卡片：品牌圖示、票券名稱、品牌、兌換日期、右側箭頭
  Widget _buildTicketCard(MyTicket ticket, ShopColors colors) {
    final item = ticket.item;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openTicket(ticket),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: colors.isHighContrast
                  ? Border.all(color: colors.title, width: 2)
                  : Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, size: 30, color: colors.green),
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
                      const SizedBox(height: 2),
                      Text(
                        item.brandName,
                        style: TextStyle(
                          fontSize: AppSettings.scaleFont(14),
                          fontWeight: FontWeight.w600,
                          color: colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ticket.redeemedDateText} 兌換',
                        style: TextStyle(
                          fontSize: AppSettings.scaleFont(14),
                          color: colors.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.qr_code_2, size: 30, color: colors.green),
                Icon(Icons.chevron_right, size: 28, color: colors.subtitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
