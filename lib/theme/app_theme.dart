import 'package:flutter/material.dart';

class AppTheme {
  // 主題深綠色（對照比賽版 futureQ 的 --primary: #36684c）
  // 原本的 0xFF5B9E87 配白字對比度約 3:1，低於無障礙標準 4.5:1；
  // 改深後約 6:1，長輩較容易辨識按鈕與卡片上的白字
  static const Color primaryColor = Color(0xFF36684C);
  // 淺色底色
  static const Color backgroundColor = Color(0xFFF7F9F8);
  // 卡片白色背景
  static const Color cardColor = Colors.white;

  // 由主色自動生成一整套 Material 3 色彩角色（次要色、表面色、邊框色…）
  // fromSeed 預設會把主色調整成它自己算出來的色調，
  // 所以額外指定 primary，確保 Material 元件用的主色跟 primaryColor 完全一致
  static final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
    primary: primaryColor,
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