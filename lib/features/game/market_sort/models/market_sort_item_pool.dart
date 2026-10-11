import 'market_sort_item.dart';
import 'market_sort_item_attributes.dart';

/// 整理菜籃遊戲的完整商品池（28項），依設計文件第二節的明細表整理
///
/// 商品圖片放在 assets/images/game/market_sort/（去背 PNG，512x512）。
/// emoji 保留作為備用：圖片載入失敗時，item_visual_resolver.dart 會退回顯示 emoji。
const List<MarketSortItem> marketSortItemPool = [
  // ── 蔬菜（10項）──
  MarketSortItem(
    name: '紅甜椒',
    emoji: '🫑',
    imageAsset: 'assets/images/game/market_sort/red_bell_pepper.png',
    species: ItemCategory.vegetable,
    color: ItemColor.red,
    freshness: null, // 生熟：吃法因人而異
  ),
  MarketSortItem(
    name: '黃甜椒',
    emoji: '🫑',
    imageAsset: 'assets/images/game/market_sort/yellow_bell_pepper.png',
    species: ItemCategory.vegetable,
    color: ItemColor.yellow,
    freshness: null, // 生熟：吃法因人而異
  ),
  MarketSortItem(
    name: '小黃瓜',
    emoji: '🥒',
    imageAsset: 'assets/images/game/market_sort/cucumber.png',
    species: ItemCategory.vegetable,
    color: ItemColor.green,
    freshness: null, // 生熟：生熟皆常見吃法
  ),
  MarketSortItem(
    name: '花椰菜',
    emoji: '🥦',
    imageAsset: 'assets/images/game/market_sort/broccoli.png',
    species: ItemCategory.vegetable,
    color: ItemColor.green,
    freshness: ItemFreshness.cooked,
  ),
  MarketSortItem(
    name: '菠菜',
    emoji: '🥬',
    imageAsset: 'assets/images/game/market_sort/spinach.png',
    species: ItemCategory.vegetable,
    color: ItemColor.green,
    freshness: ItemFreshness.cooked,
  ),
  MarketSortItem(
    name: '玉米',
    emoji: '🌽',
    imageAsset: 'assets/images/game/market_sort/corn.png',
    species: ItemCategory.vegetable,
    color: ItemColor.yellow,
    freshness: ItemFreshness.cooked,
  ),
  MarketSortItem(
    name: '南瓜',
    emoji: '🎃',
    imageAsset: 'assets/images/game/market_sort/pumpkin.png',
    species: ItemCategory.vegetable,
    color: ItemColor.yellow,
    freshness: ItemFreshness.cooked,
  ),
  MarketSortItem(
    name: '白蘿蔔',
    emoji: '🥕',
    imageAsset: 'assets/images/game/market_sort/white_radish.png',
    species: ItemCategory.vegetable,
    color: null, // 顏色偏白
    freshness: null, // 生熟：有醃漬生食吃法
  ),
  MarketSortItem(
    name: '豌豆',
    emoji: '🫛',
    imageAsset: 'assets/images/game/market_sort/pea.png',
    species: ItemCategory.vegetable,
    color: ItemColor.green,
    freshness: ItemFreshness.cooked,
  ),
  MarketSortItem(
    name: '地瓜葉',
    emoji: '🍃',
    imageAsset: 'assets/images/game/market_sort/sweet_potato_leaves.png',
    species: ItemCategory.vegetable,
    color: ItemColor.green,
    freshness: ItemFreshness.cooked,
  ),

  // ── 水果（11項）──
  MarketSortItem(
    name: '蘋果',
    emoji: '🍎',
    imageAsset: 'assets/images/game/market_sort/apple.png',
    species: ItemCategory.fruit,
    color: ItemColor.red,
    freshness: ItemFreshness.raw,
  ),
  MarketSortItem(
    name: '草莓',
    emoji: '🍓',
    imageAsset: 'assets/images/game/market_sort/strawberry.png',
    species: ItemCategory.fruit,
    color: ItemColor.red,
    freshness: ItemFreshness.raw,
  ),
  MarketSortItem(
    name: '奇異果',
    emoji: '🥝',
    imageAsset: 'assets/images/game/market_sort/kiwi.png',
    species: ItemCategory.fruit,
    color: ItemColor.green,
    freshness: ItemFreshness.raw,
  ),
  MarketSortItem(
    name: '芭樂',
    emoji: '🍈',
    imageAsset: 'assets/images/game/market_sort/guava.png',
    species: ItemCategory.fruit,
    color: ItemColor.green,
    freshness: ItemFreshness.raw,
  ),
  MarketSortItem(
    name: '香蕉',
    emoji: '🍌',
    imageAsset: 'assets/images/game/market_sort/banana.png',
    species: ItemCategory.fruit,
    color: ItemColor.yellow,
    freshness: ItemFreshness.raw,
  ),
  MarketSortItem(
    name: '檸檬',
    emoji: '🍋',
    imageAsset: 'assets/images/game/market_sort/lemon.png',
    species: ItemCategory.fruit,
    color: null, // 顏色綠黃不一
    freshness: null, // 一般不直接生吃當水果
  ),
  MarketSortItem(
    name: '鳳梨',
    emoji: '🍍',
    imageAsset: 'assets/images/game/market_sort/pineapple.png',
    species: ItemCategory.fruit,
    color: ItemColor.yellow,
    freshness: ItemFreshness.raw,
  ),
  MarketSortItem(
    name: '火龍果',
    emoji: '🐲',
    imageAsset: 'assets/images/game/market_sort/dragon_fruit.png',
    species: ItemCategory.fruit,
    color: null, // 顏色外皮果肉不一
    freshness: ItemFreshness.raw,
  ),
  MarketSortItem(
    name: '葡萄',
    emoji: '🍇',
    imageAsset: 'assets/images/game/market_sort/grape.png',
    species: ItemCategory.fruit,
    color: null, // 顏色依品種呈綠或紫
    freshness: ItemFreshness.raw,
  ),
  MarketSortItem(
    name: '木瓜',
    emoji: '🧡',
    imageAsset: 'assets/images/game/market_sort/papaya.png',
    species: ItemCategory.fruit,
    color: ItemColor.yellow,
    freshness: ItemFreshness.raw,
  ),
  MarketSortItem(
    name: '芒果',
    emoji: '🥭',
    imageAsset: 'assets/images/game/market_sort/mango.png',
    species: ItemCategory.fruit,
    color: ItemColor.yellow,
    freshness: ItemFreshness.raw,
  ),

  // ── 肉蛋（7項）──
  MarketSortItem(
    name: '豬肉',
    emoji: '🥩',
    imageAsset: 'assets/images/game/market_sort/pork.png',
    species: ItemCategory.meatEgg,
    color: ItemColor.red,
    freshness: ItemFreshness.cooked,
  ),
  MarketSortItem(
    name: '培根',
    emoji: '🥓',
    imageAsset: 'assets/images/game/market_sort/bacon.png',
    species: ItemCategory.meatEgg,
    color: ItemColor.red,
    freshness: ItemFreshness.cooked,
  ),
  MarketSortItem(
    name: '蝦子',
    emoji: '🦐',
    imageAsset: 'assets/images/game/market_sort/shrimp.png',
    species: ItemCategory.meatEgg,
    color: ItemColor.red,
    freshness: ItemFreshness.cooked,
  ),
  MarketSortItem(
    name: '牛肉',
    emoji: '🐄',
    imageAsset: 'assets/images/game/market_sort/beef.png',
    species: ItemCategory.meatEgg,
    color: ItemColor.red,
    freshness: ItemFreshness.cooked,
  ),
  MarketSortItem(
    name: '雞蛋',
    emoji: '🥚',
    imageAsset: 'assets/images/game/market_sort/egg.png',
    species: ItemCategory.meatEgg,
    color: null, // 顏色蛋殼偏白
    freshness: null, // 熟度吃法有爭議
  ),
  MarketSortItem(
    name: '蟹肉',
    emoji: '🦀',
    imageAsset: 'assets/images/game/market_sort/crab.png',
    species: ItemCategory.meatEgg,
    color: null, // 紅色是殼不是肉
    freshness: ItemFreshness.cooked,
  ),
  MarketSortItem(
    name: '火腿',
    emoji: '🍖',
    imageAsset: 'assets/images/game/market_sort/ham.png',
    species: ItemCategory.meatEgg,
    color: ItemColor.red,
    freshness: ItemFreshness.cooked,
  ),
];

/// 依規則統計題庫裡「有該屬性、可以拿來出題」的商品數量
///
/// 直接印出這個函式的結果，就能核對設計文件第二節的統計數字
/// （之前發現文件裡「顏色19／生熟22」跟明細表逐項核算對不上，
/// 用這個函式跑出來的數字才是真正依照目前商品池算出來的正確值）。
Map<String, int> countAvailableItemsByRule() {
  int speciesCount = marketSortItemPool.length; // species 一定有值，全部都算
  int colorCount = marketSortItemPool
      .where((item) => item.color != null)
      .length;
  int freshnessCount = marketSortItemPool
      .where((item) => item.freshness != null)
      .length;

  return {
    '種類': speciesCount,
    '顏色': colorCount,
    '生熟': freshnessCount,
  };
}