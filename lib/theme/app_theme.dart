import 'package:flutter/material.dart';

class AppTheme {
  // 主題草綠色（對照設計圖）
  static const Color primaryColor = Color(0xFF5B9E87);
  // 淺色底色
  static const Color backgroundColor = Color(0xFFF7F9F8);
  // 卡片白色背景
  static const Color cardColor = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
