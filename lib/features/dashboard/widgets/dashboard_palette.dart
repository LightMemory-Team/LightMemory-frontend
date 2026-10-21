import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../theme/app_theme.dart';
import '../models/dashboard_models.dart';

/// 儀表板模組共用的配色：依目前的深色模式、高對比設定算出顏色，
/// 深色配色沿用首頁、遊戲首頁的寫法（0xFF121212 底、0xFF1E1E1E 卡片、
/// 0xFF4CAF50 綠）。每次 build 時用 [DashboardPalette.current] 取一次。
class DashboardPalette {
  final bool isDark;
  final bool isHighContrast;

  const DashboardPalette({required this.isDark, required this.isHighContrast});

  factory DashboardPalette.current() => DashboardPalette(
    isDark: AppSettings.isDarkMode.value,
    isHighContrast: AppSettings.isHighContrast.value,
  );

  Color get background =>
      isDark ? const Color(0xFF121212) : AppTheme.backgroundColor;
  Color get card => isDark ? const Color(0xFF1E1E1E) : AppTheme.cardColor;
  Color get primary => isDark ? const Color(0xFF4CAF50) : AppTheme.primaryColor;

  Color get title => isHighContrast
      ? (isDark ? Colors.white : Colors.black)
      : (isDark ? Colors.white : const Color(0xFF1E1E1E));
  Color get body => isHighContrast
      ? (isDark ? Colors.white : Colors.black)
      : (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF595959));

  /// 淺綠底容器（跟 DomainCard、GameCard 同色）
  Color get soft => isDark ? const Color(0xFF25382E) : const Color(0xFFDCE8DC);
  Color get onSoft => isHighContrast
      ? (isDark ? Colors.white : Colors.black)
      : (isDark ? const Color(0xFFB8E6D0) : const Color(0xFF3D6B4A));

  /// 長條、雷達圖的底線／格線
  Color get track => isDark ? const Color(0xFF33413A) : const Color(0xFFE6EEE8);
  Color get grid => isDark ? const Color(0xFF4A5A51) : const Color(0xFFC9D6CD);

  /// 高對比模式時卡片加外框
  Border? get cardBorder => isHighContrast
      ? Border.all(color: isDark ? Colors.white : Colors.black, width: 2)
      : null;

  List<BoxShadow> get cardShadow => isDark
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];

  BoxDecoration cardDecoration({double radius = 20}) => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(radius),
    border: cardBorder,
    boxShadow: cardShadow,
  );

  /// 狀態詞的底色／字色。不使用紅色：「多練習」用柔和的暖黃色
  Color trendBackground(AbilityTrend trend) {
    switch (trend) {
      case AbilityTrend.improved:
        return isDark ? const Color(0xFF25382E) : const Color(0xFFDDEFE2);
      case AbilityTrend.steady:
        return isDark ? const Color(0xFF2C3330) : const Color(0xFFE9EDEA);
      case AbilityTrend.practice:
        return isDark ? const Color(0xFF3A3122) : const Color(0xFFFBEFD9);
    }
  }

  Color trendForeground(AbilityTrend trend) {
    if (isHighContrast) return isDark ? Colors.white : Colors.black;
    switch (trend) {
      case AbilityTrend.improved:
        return isDark ? const Color(0xFF8FD9A8) : const Color(0xFF2E6342);
      case AbilityTrend.steady:
        return isDark ? const Color(0xFFC3CEC7) : const Color(0xFF55665B);
      case AbilityTrend.practice:
        return isDark ? const Color(0xFFF2C77B) : const Color(0xFF8A5A12);
    }
  }
}

String abilityTrendLabel(AbilityTrend trend) {
  switch (trend) {
    case AbilityTrend.improved:
      return '進步';
    case AbilityTrend.steady:
      return '持平';
    case AbilityTrend.practice:
      return '多練習';
  }
}
