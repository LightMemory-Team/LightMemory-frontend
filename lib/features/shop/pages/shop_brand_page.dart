import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../core/network/error_message.dart';
import '../models/shop_models.dart';
import '../services/shop_service.dart';
import '../widgets/shop_item_card.dart';

/// 品牌頁：點數商城點「星巴克／全聯／農會」進來，列出這個品牌的商品（直向卡片）
class ShopBrandPage extends StatefulWidget {
  final ShopBrand brand;

  /// 目前的點數（從商城頁帶過來，不用再讀一次）
  final int currentPoints;

  const ShopBrandPage({
    super.key,
    required this.brand,
    required this.currentPoints,
  });

  @override
  State<ShopBrandPage> createState() => _ShopBrandPageState();
}

class _ShopBrandPageState extends State<ShopBrandPage> {
  final ShopService _service = ShopService();

  List<ShopItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _service.getItemsByBrand(widget.brand.id);
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 讀取品牌商品失敗: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = friendlyErrorMessage(e, fallback: '目前無法載入商品');
      });
    }
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
            // 左上角用文字「返回」（跟註冊頁、忘記密碼一樣）
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
                Icon(widget.brand.icon, color: colors.green),
                const SizedBox(width: 6),
                Text(
                  widget.brand.name,
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

    if (_errorMessage != null) {
      return _buildMessage(
        colors: colors,
        icon: Icons.cloud_off_outlined,
        text: _errorMessage!,
        buttonText: '再試一次',
        onPressed: _loadItems,
      );
    }

    if (_items.isEmpty) {
      return _buildMessage(
        colors: colors,
        icon: Icons.inventory_2_outlined,
        text: '這個品牌目前還沒有商品',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // 目前點數
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Text(
                '我的點數',
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(16),
                  color: colors.subtitle,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.monetization_on, size: 22, color: Color(0xFFE5A823)),
              const SizedBox(width: 2),
              Text(
                '${widget.currentPoints} 點',
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(18),
                  fontWeight: FontWeight.bold,
                  color: colors.green,
                ),
              ),
            ],
          ),
        ),
        ..._items.map(
          (item) => ShopItemCard(
            item: item,
            currentPoints: widget.currentPoints,
            showBrand: false,
          ),
        ),
      ],
    );
  }

  Widget _buildMessage({
    required ShopColors colors,
    required IconData icon,
    required String text,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: colors.subtitle),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSettings.scaleFont(18),
                color: colors.subtitle,
              ),
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(fontSize: AppSettings.scaleFont(16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}