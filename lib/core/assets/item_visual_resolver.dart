import 'package:flutter/material.dart';
import '../../features/game/market_sort/models/market_sort_item.dart';

/// 商品圖案的取得方式：有圖片素材就用圖片，沒有就用 emoji
///
/// 呼叫端（畫面元件）永遠只呼叫這個函式，不自己判斷 emoji 或圖片。
/// 圖片放在 assets/images/game/market_sort/，路徑填在 MarketSortItem 的
/// imageAsset 欄位；路徑打錯或檔案漏放時會自動退回 emoji，
/// 不會讓長者看到紅色錯誤框。
Widget buildItemVisual(MarketSortItem item, {double size = 80}) {
  final emoji = Text(item.emoji, style: TextStyle(fontSize: size));
  if (item.imageAsset == null) return emoji;

  return Image.asset(
    item.imageAsset!,
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => emoji,
  );
}