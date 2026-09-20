import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'features/auth/pages/identity_select_page.dart';
import 'core/constants/route_constants.dart';
import 'screens/market_sort_game_screen.dart';
// 1. 匯入我們的冰箱清點教學頁
import 'features/game/fridge_inventory/pages/fridge_tutorial_page.dart';

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
      // 2. 將首頁暫時改為我們的冰箱教學頁，方便在模擬器測試
      home: const FridgeTutorialPage(),
      routes: {
        AppRoutes.gameMarketSort: (context) => const MarketSortGameScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
