import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'features/auth/pages/identity_select_page.dart';
import 'core/constants/route_constants.dart';
import 'screens/market_sort_game_screen.dart';

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
      home: const IdentitySelectPage(),
      routes: {
        AppRoutes.gameMarketSort: (context) => const MarketSortGameScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}