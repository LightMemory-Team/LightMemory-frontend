import 'package:flutter/material.dart';

class AppSettings {
  // 字體大小等級：1=85%, 2=100%(標準), 3=115%, 4=130%, 5=145%
  static final ValueNotifier<int> fontSizeLevel = ValueNotifier<int>(2);
  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isHighContrast = ValueNotifier<bool>(false);

  // 未讀通知數量（預設為 3，全部已讀後變為 0）
  static final ValueNotifier<int> unreadNotificationCount = ValueNotifier<int>(
    3,
  );

  // 取得全 App 字體縮放倍率
  static double get fontScaleFactor {
    switch (fontSizeLevel.value) {
      case 1:
        return 0.85;
      case 2:
        return 1.0;
      case 3:
        return 1.15;
      case 4:
        return 1.30;
      case 5:
        return 1.45;
      default:
        return 1.0;
    }
  }

  // 輔助函式：直接計算縮放後的字體大小
  static double scaleFont(double baseSize) {
    return baseSize * fontScaleFactor;
  }

  // 取得中文標籤
  static String get fontSizeLabel {
    switch (fontSizeLevel.value) {
      case 1:
        return '小（85%）';
      case 2:
        return '標準（100%）';
      case 3:
        return '大（115%）';
      case 4:
        return '特大（130%）';
      case 5:
        return '超大（145%）';
      default:
        return '標準（100%）';
    }
  }
}
