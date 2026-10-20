import 'package:flutter_test/flutter_test.dart';
import 'package:light_memory/features/game/market_sort/models/game_rule.dart';
import 'package:light_memory/features/game/market_sort/models/market_sort_item_pool.dart';

void main() {
  test('紅甜椒、黃甜椒不出種類題，但顏色題照常出', () {
    for (final name in ['紅甜椒', '黃甜椒']) {
      final item = marketSortItemPool.firstWhere((i) => i.name == name);
      expect(item.isExcludedFor(GameRule.species), isTrue, reason: name);
      expect(item.isExcludedFor(GameRule.color), isFalse, reason: name);
    }
  });

  test('種類題可用商品數為 26（28 項扣掉兩種甜椒）', () {
    expect(countAvailableItemsByRule()['種類'], 26);
  });
}
