import '../models/shop_models.dart';
import '../../rewards/services/rewards_service.dart';

/// 點數商城資料服務
///
/// 後端 API 還沒定，目前全部用假資料（useMockShop = true）。
/// 之後後端好了，把各方法改成呼叫 API（記得用 authHeaders()），畫面不用改。
class ShopService {
  // ============================================================
  // 假資料開關
  // TODO：後端點數、商城 API 做好後改成 false，並接上真實 API
  // ============================================================

  static const bool useMockShop = true;

  /// 目前的點數：跟首頁、成就牆同一個來源（GET /api/rewards/summary/ 的 total_points）
  /// 假資料開關在 RewardsService.useMockRewards
  Future<int> getPoints() async {
    final summary = await RewardsService().getSummary();
    return summary.totalPoints;
  }

  /// 合作品牌（星巴克、全聯、農會）
  Future<List<ShopBrand>> getBrands() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockBrands.map(ShopBrand.fromJson).toList();
  }

  /// 熱門兌換：各品牌最多人換的商品
  Future<List<ShopItem>> getHotItems() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockItems
        .where((item) => _mockHotItemIds.contains(item['id']))
        .map(ShopItem.fromJson)
        .toList();
  }

  /// 某個品牌的全部商品
  Future<List<ShopItem>> getItemsByBrand(String brandId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockItems
        .where((item) => item['brand_id'] == brandId)
        .map(ShopItem.fromJson)
        .toList();
  }

  // ============================================================
  // 假資料（點數 120：有些商品換得起、有些點數不足，方便測兩種畫面）
  // ============================================================

  static const List<Map<String, dynamic>> _mockBrands = [
    {'id': 'starbucks', 'name': '星巴克'},
    {'id': 'pxmart', 'name': '全聯'},
    {'id': 'farmers', 'name': '農會'},
  ];

  static const List<int> _mockHotItemIds = [2, 5, 7];

  static const List<Map<String, dynamic>> _mockItems = [
    // 星巴克
    {
      'id': 1,
      'brand_id': 'starbucks',
      'brand_name': '星巴克',
      'name': '中杯美式咖啡券',
      'description': '可兌換中杯美式咖啡一杯（冰、熱皆可）',
      'points': 100,
    },
    {
      'id': 2,
      'brand_id': 'starbucks',
      'brand_name': '星巴克',
      'name': '中杯拿鐵券',
      'description': '可兌換中杯拿鐵一杯（冰、熱皆可）',
      'points': 150,
    },
    {
      'id': 3,
      'brand_id': 'starbucks',
      'brand_name': '星巴克',
      'name': '焦糖瑪奇朵券',
      'description': '可兌換中杯焦糖瑪奇朵一杯',
      'points': 180,
    },
    // 全聯
    {
      'id': 4,
      'brand_id': 'pxmart',
      'brand_name': '全聯',
      'name': '50 元購物金',
      'description': '全台全聯門市結帳時可折抵 50 元',
      'points': 60,
    },
    {
      'id': 5,
      'brand_id': 'pxmart',
      'brand_name': '全聯',
      'name': '100 元購物金',
      'description': '全台全聯門市結帳時可折抵 100 元',
      'points': 110,
    },
    {
      'id': 6,
      'brand_id': 'pxmart',
      'brand_name': '全聯',
      'name': '衛生紙一串',
      'description': '抽取式衛生紙 12 包一串',
      'points': 150,
    },
    // 農會
    {
      'id': 7,
      'brand_id': 'farmers',
      'brand_name': '農會',
      'name': '台南 16 號越光米',
      'description': '米粒飽滿晶瑩、香甜 Q 彈，食味值更勝日本米',
      'points': 120,
    },
    {
      'id': 8,
      'brand_id': 'farmers',
      'brand_name': '農會',
      'name': '有機地瓜 1 公斤',
      'description': '在地小農種植，香甜鬆軟',
      'points': 80,
    },
    {
      'id': 9,
      'brand_id': 'farmers',
      'brand_name': '農會',
      'name': '在地龍眼蜂蜜',
      'description': '純天然龍眼蜜 700 公克',
      'points': 200,
    },
  ];
}