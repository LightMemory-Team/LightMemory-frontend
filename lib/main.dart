import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'core/constants/route_constants.dart';
import 'screens/market_sort_game_screen.dart';
import 'screens/game_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '憶智防線',
      theme: AppTheme.lightTheme,
      home: const GameHomeScreen(), // 一開機直接顯示六個分類大廳
      routes: {
        AppRoutes.gameMarketSort: (context) => const MarketSortGameScreen(),
        // 🌟 刪除原本那行有問題的 AppRoutes.gameHome 即可！
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
