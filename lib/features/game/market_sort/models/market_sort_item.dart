import 'game_rule.dart';
import 'market_sort_item_attributes.dart';

/// 單一商品的完整資料
///
/// 三個屬性裡，species 一定有值（每個商品都屬於某個種類），
/// color 跟 freshness 則可能是 null——null 代表這項屬性對這個商品有爭議
/// （例如吃法因人而異、顏色不單一），依設計文件原則直接把該商品從那個
/// 題型的子題庫排除，不會被拿去出那個屬性的題目。
class MarketSortItem {
  final String name; // 商品名稱，例如「蘋果」
  final String emoji; // 目前還沒有正式插畫素材，先用 emoji 顯示，例如 "🍎"
  final String? imageAsset; // 之後有正式插畫素材時填入路徑，目前先全部是 null
  final ItemCategory species; // 種類：一定有值
  final ItemColor? color; // 顏色：可能是 null
  final ItemFreshness? freshness; // 生熟：可能是 null

  const MarketSortItem({
    required this.name,
    required this.emoji,
    this.imageAsset, // 沒特別給值時預設 null，不強制每個商品都要填
    required this.species,
    required this.color,
    required this.freshness,
  });

  /// 依指定的規則，取得這個商品在該規則下的屬性值
  ///
  /// 回傳型別統一用 Object?（因為三種屬性各自是不同的 enum 型別），
  /// error_type 判定演算法會用「兩個商品在同一規則下的值是否相等」來比對，
  /// 呼叫端用 == 比較時要注意：只有同一個 enum 型別的值互相比較才有意義，
  /// 不同規則之間本來就不該拿來比。
  Object? valueFor(GameRule rule) {
    switch (rule) {
      case GameRule.species:
        return species;
      case GameRule.color:
        return color;
      case GameRule.freshness:
        return freshness;
    }
  }

  /// 這個商品在指定規則下，是不是「被排除」的（值為 null）
  /// species 一定有值，所以只有 color / freshness 可能回傳 true
  bool isExcludedFor(GameRule rule) => valueFor(rule) == null;
}