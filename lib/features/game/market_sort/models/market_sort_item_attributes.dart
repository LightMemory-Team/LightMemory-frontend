/// 商品本身的「種類」屬性值——每個商品一定有值，不會是 null
enum ItemCategory {
  vegetable, // 蔬菜
  fruit, // 水果
  meatEgg, // 肉蛋
}

extension ItemCategoryDisplay on ItemCategory {
  String get label {
    switch (this) {
      case ItemCategory.vegetable:
        return '蔬菜';
      case ItemCategory.fruit:
        return '水果';
      case ItemCategory.meatEgg:
        return '肉蛋';
    }
  }
}

/// 商品本身的「顏色」屬性值——部分商品這項是 null（該屬性有爭議，被排除）
enum ItemColor {
  red, // 紅
  green, // 綠
  yellow, // 黃
}

extension ItemColorDisplay on ItemColor {
  String get label {
    switch (this) {
      case ItemColor.red:
        return '紅';
      case ItemColor.green:
        return '綠';
      case ItemColor.yellow:
        return '黃';
    }
  }
}

/// 商品本身的「生熟」屬性值——部分商品這項是 null（該屬性有爭議，被排除）
enum ItemFreshness {
  raw, // 生食
  cooked, // 熟食
}

extension ItemFreshnessDisplay on ItemFreshness {
  String get label {
    switch (this) {
      case ItemFreshness.raw:
        return '生食';
      case ItemFreshness.cooked:
        return '熟食';
    }
  }
}