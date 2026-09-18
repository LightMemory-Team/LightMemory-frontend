import 'package:flutter/material.dart';
import '../../features/game/market_sort/models/market_sort_item.dart';

/// 商品圖案的取得方式：有正式插畫素材就用圖片，還沒有就先用 emoji 頂著
///
/// 呼叫端（畫面元件）永遠只呼叫這個函式，不自己判斷 emoji 或圖片，
/// 之後真的有素材了，只要在 MarketSortItem 的 imageAsset 欄位填上路徑、
/// 把檔案放進 assets/images/market_sort/ 資料夾，畫面就會自動切換成真圖，
/// 不用改任何 widget 程式碼。
Widget buildItemVisual(MarketSortItem item, {double size = 80}) {
  if (item.imageAsset != null) {
    return Image.asset(item.imageAsset!, width: size, height: size);
  }
  return Text(item.emoji, style: TextStyle(fontSize: size));
}