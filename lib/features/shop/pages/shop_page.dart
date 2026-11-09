import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../core/network/error_message.dart';
import '../models/shop_models.dart';
import '../services/shop_service.dart';
import '../widgets/shop_item_card.dart';
import 'shop_brand_page.dart';

/// 點數商城頁：首頁右下角「逛商城」進來
///
/// - 上方：我的點數（深綠色卡片，照比賽版）
/// - 中間：品牌按鈕（星巴克、全聯、農會），三個一排、不用左右滑
/// - 下方：熱門兌換，直向卡片列表（長輩只要上下滑）
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final ShopService _service = ShopService();

  int _points = 0;
  List<ShopBrand> _brands = [];
  List<ShopItem> _hotItems = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  /// 點數、品牌、熱門兌換同時讀取
  Future<void> _loadAll() async {
    setState(() {
      _isLoading = _brands.isEmpty;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.getPoints(),
        _service.getBrands(),
        _service.getHotItems(),
      ]);
      if (!mounted) return;
      setState(() {
        _points = results[0] as int;
        _brands = results[1] as List<ShopBrand>;
        _hotItems = results[2] as List<ShopItem>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 讀取點數商城失敗: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = friendlyErrorMessage(e, fallback: '目前無法載入點數商城');
      });
    }
  }

  void _openBrand(ShopBrand brand) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShopBrandPage(brand: brand, currentPoints: _points),
      ),
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
                Icon(Icons.storefront_outlined, color: colors.green),
                const SizedBox(width: 6),
                Text(
                  '點數商城',
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 56, color: colors.subtitle),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(18),
                  color: colors.subtitle,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAll,
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
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: colors.green,
      onRefresh: _loadAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildPointsCard(colors),
          const SizedBox(height: 18),

          // 品牌按鈕：三個一排
          Row(
            children: [
              for (int i = 0; i < _brands.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: _buildBrandButton(_brands[i], colors)),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // 熱門兌換
          Text(
            '熱門兌換',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(20),
              fontWeight: FontWeight.bold,
              color: colors.title,
            ),
          ),
          const SizedBox(height: 12),
          if (_hotItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                '目前還沒有熱門商品',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(16),
                  color: colors.subtitle,
                ),
              ),
            )
          else
            ..._hotItems.map(
              (item) => ShopItemCard(item: item, currentPoints: _points),
            ),
        ],
      ),
    );
  }

  /// 我的點數：深綠色卡片（照比賽版）
  Widget _buildPointsCard(ShopColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF25382E) : const Color(0xFF2E6342),
        borderRadius: BorderRadius.circular(22),
        border: colors.isHighContrast ? Border.all(color: Colors.black, width: 2) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '我的點數',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(16),
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_points 點',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(32),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.monetization_on, size: 52, color: Color(0xFFF5C542)),
        ],
      ),
    );
  }

  /// 品牌按鈕：圓形圖示＋品牌名稱
  Widget _buildBrandButton(ShopBrand brand, ShopColors colors) {
    return Material(
      color: colors.cardBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openBrand(brand),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: colors.isHighContrast
                ? Border.all(color: colors.title, width: 2)
                : Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(brand.icon, size: 28, color: colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                brand.name,
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(16),
                  fontWeight: FontWeight.bold,
                  color: colors.title,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}