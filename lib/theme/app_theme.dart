import 'package:flutter/material.dart';

class AppTheme {
  // 主題草綠色（對照設計圖）
  static const Color primaryColor = Color(0xFF5B9E87);
  // 淺色底色
  static const Color backgroundColor = Color(0xFFF7F9F8);
  // 卡片白色背景
  static const Color cardColor = Colors.white;

  // 由主色自動生成一整套 Material 3 色彩角色（次要色、表面色、邊框色…）
  static final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
  );

  // ── 版面結構常數（參考 futureQ 聲影日記的圓角/尺寸經驗值）──
  static const double radiusCard = 16;       // 照片卡片、波形圖
  static const double radiusPill = 999;      // 藥丸型按鈕、chip
  static const double radiusBubble = 18;     // 對話氣泡
  static const double sizeMicButton = 84;    // 錄音大圓鈕
  static const double sizeAvatar = 36;       // 聊天室頭像

  // ── 字級常數 ──
  static const double fontTitle = 22;
  static const double fontBody = 14;
  static const double fontTimer = 28;
  static const double fontCaption = 12;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}