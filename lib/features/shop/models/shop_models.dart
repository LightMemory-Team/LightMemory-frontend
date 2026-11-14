import 'package:flutter/material.dart';

// ============================================================
// 點數商城的資料格式
//
// - ShopBrand：合作品牌（星巴克、全聯、農會）
// - ShopItem：可以兌換的商品或優惠券
//
// 後端 API 還沒定，欄位名稱先照這裡，之後依後端調整 fromJson 即可。
// ============================================================

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

/// 合作品牌
class ShopBrand {
  /// 品牌代碼：starbucks、pxmart、farmers
  final String id;

  /// 品牌名稱，例如「星巴克」
  final String name;

  const ShopBrand({required this.id, required this.name});

  factory ShopBrand.fromJson(Map<String, dynamic> json) {
    return ShopBrand(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  /// 品牌圖示（品牌 logo 讀不到時的備用）
  IconData get icon => brandIcon(id);

  /// 品牌 logo（assets/images/shop/），沒有對應圖片時是 null
  String? get logoAsset => logoAssetFor(id);

  static String? logoAssetFor(String brandId) {
    switch (brandId) {
      case 'starbucks':
        return 'assets/images/shop/starbucks.png';
      case 'pxmart':
        return 'assets/images/shop/pxmart.jpg';
      case 'farmers':
        return 'assets/images/shop/farmers.png';
      default:
        return null;
    }
  }

  /// logo 放進圓形的方式：
  /// 星巴克本身是圓形，整張放進去；全聯是長方形旗幟、農會是圓角方形，裁成圓形
  BoxFit get logoFit => id == 'starbucks' ? BoxFit.contain : BoxFit.cover;

  /// 農會 logo 是圓角方形，裁成圓形時四角會露白，稍微放大填滿
  double get logoScale => id == 'farmers' ? 1.12 : 1.0;

  static IconData brandIcon(String brandId) {
    switch (brandId) {
      case 'starbucks':
        return Icons.local_cafe_outlined; // 星巴克
      case 'pxmart':
        return Icons.shopping_cart_outlined; // 全聯
      case 'farmers':
        return Icons.grass_outlined; // 農會
      default:
        return Icons.redeem_outlined;
    }
  }
}

/// 可以兌換的商品或優惠券
class ShopItem {
  final int id;

  /// 屬於哪個品牌
  final String brandId;
  final String brandName;

  /// 商品名稱，例如「中杯拿鐵券」
  final String name;

  /// 一句話說明，例如「可兌換中杯熱拿鐵一杯」
  final String description;

  /// 需要多少點數
  final int points;

  /// 商品圖片（assets 路徑）；目前商品都還沒有圖片，是 null 時用品牌 logo
  final String? imageAsset;

  const ShopItem({
    required this.id,
    required this.brandId,
    required this.brandName,
    required this.name,
    required this.description,
    required this.points,
    this.imageAsset,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: _toInt(json['id']),
      brandId: json['brand_id']?.toString() ?? '',
      brandName: json['brand_name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      points: _toInt(json['points']),
      imageAsset: json['image_asset']?.toString(),
    );
  }

  /// 卡片要顯示的圖片：有商品圖用商品圖，沒有就用品牌 logo
  String? get displayImage => imageAsset ?? ShopBrand.logoAssetFor(brandId);

  /// 商品圖示：先用品牌圖示（之後有商品圖片再換）
  IconData get icon => ShopBrand.brandIcon(brandId);
}
/// 我的票券：兌換好的商品券（卡夾包）
///
/// 目前是假資料、僅示意：所有票券共用同一組 QR code 內容。
/// TODO：後端兌換 API 做好後，改成讀後端回傳的票券與各自的兌換碼。
class MyTicket {
  final int id;

  /// 換到的商品（名稱、品牌、說明、圖示都從這裡拿）
  final ShopItem item;

  /// 兌換時間
  final DateTime redeemedAt;

  /// QR code 內容（給店員掃描）
  final String qrData;

  const MyTicket({
    required this.id,
    required this.item,
    required this.redeemedAt,
    required this.qrData,
  });

  /// 例如「2026/11/14」
  String get redeemedDateText =>
      '${redeemedAt.year}/${redeemedAt.month.toString().padLeft(2, '0')}/${redeemedAt.day.toString().padLeft(2, '0')}';
}
