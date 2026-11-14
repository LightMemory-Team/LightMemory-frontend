import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../core/network/error_message.dart';
import '../../rewards/services/mock_redeem_points.dart';
import '../models/shop_models.dart';
import '../services/shop_service.dart';
import '../widgets/shop_item_card.dart';
import '../widgets/shop_item_grid_card.dart';
import 'my_tickets_page.dart';
import 'shop_brand_page.dart';

/// 點數商城頁：首頁右下角「逛商城」進來
///
/// - 上方：我的點數（深綠色卡片，照比賽版），卡片上有「我的票券」按鈕
/// - 中間：品牌按鈕（星巴克、全聯、農會），三個一排、不用左右滑
/// - 下方：熱門兌換，一排兩張的直向卡片、以圖片為主（長輩只要上下滑）
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
    // 兌換（假扣點）後重新讀點數，「點數不足」也會跟著更新
    MockRedeemPoints.spent.addListener(_reloadPoints);
  }

  @override
  void dispose() {
    MockRedeemPoints.spent.removeListener(_reloadPoints);
    super.dispose();
  }

  Future<void> _reloadPoints() async {
    try {
      final points = await _service.getPoints();
      if (!mounted) return;
      setState(() => _points = points);
    } catch (e) {
      debugPrint('❌ 重新讀取點數失敗: $e');
    }
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

  void _openMyTickets() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MyTicketsPage()),
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
            ..._buildHotItemRows(),
        ],
      ),
    );
  }

  /// 熱門兌換：一排兩張，同一排一樣高；最後一排只有一張時，右邊留空
  List<Widget> _buildHotItemRows() {
    const double gap = 12;
    return [
      for (int i = 0; i < _hotItems.length; i += 2)
        Padding(
          padding: const EdgeInsets.only(bottom: gap),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ShopItemGridCard(item: _hotItems[i], currentPoints: _points),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: i + 1 < _hotItems.length
                      ? ShopItemGridCard(item: _hotItems[i + 1], currentPoints: _points)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  /// 我的點數：深綠色卡片（照比賽版），下方「我的票券」按鈕
  Widget _buildPointsCard(ShopColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: colors.isDark ? const Color(0xFF25382E) : const Color(0xFF2E6342),
        borderRadius: BorderRadius.circular(22),
        border: colors.isHighContrast ? Border.all(color: Colors.black, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPointsRow(),
          const SizedBox(height: 14),
          // 我的票券：白色外框按鈕
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _openMyTickets,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.confirmation_number_outlined, size: 24),
              label: Text(
                '我的票券',
                style: TextStyle(
                  fontSize: AppSettings.scaleFont(17),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 點數卡片上半部：我的點數＋金幣
  Widget _buildPointsRow() {
    return Row(
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
    );
  }

  /// 品牌按鈕：圓形品牌 logo＋品牌名稱（沒有卡片底，整塊都可以點）
  Widget _buildBrandButton(ShopBrand brand, ShopColors colors) {
    final String? logo = brand.logoAsset;
    final Widget fallbackIcon = Container(
      color: colors.iconBg,
      child: Icon(brand.icon, size: 40, color: colors.green),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openBrand(brand),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              // logo 底色固定白色（深色模式也一樣），logo 才看得清楚
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: colors.isHighContrast
                      ? Border.all(color: colors.title, width: 2)
                      : Border.all(color: colors.border, width: 1.5),
                ),
                child: ClipOval(
                  child: logo == null
                      ? fallbackIcon
                      : Padding(
                          // 星巴克整張放進去，留一點白邊；其他裁成圓形不留邊
                          padding: EdgeInsets.all(
                            brand.logoFit == BoxFit.contain ? 9 : 0,
                          ),
                          child: Transform.scale(
                            scale: brand.logoScale,
                            child: Image.asset(
                              logo,
                              fit: brand.logoFit,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  fallbackIcon,
                            ),
                          ),
                        ),
                ),
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
