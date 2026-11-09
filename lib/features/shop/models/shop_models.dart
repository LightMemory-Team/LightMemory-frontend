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

  /// 品牌圖示（之後有品牌 logo 圖片再換）
  IconData get icon => brandIcon(id);

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

  const ShopItem({
    required this.id,
    required this.brandId,
    required this.brandName,
    required this.name,
    required this.description,
    required this.points,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: _toInt(json['id']),
      brandId: json['brand_id']?.toString() ?? '',
      brandName: json['brand_name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      points: _toInt(json['points']),
    );
  }

  /// 商品圖示：先用品牌圖示（之後有商品圖片再換）
  IconData get icon => ShopBrand.brandIcon(brandId);
}