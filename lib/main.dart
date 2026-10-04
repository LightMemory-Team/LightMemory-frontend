import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'core/constants/route_constants.dart';
import 'screens/market_sort_game_screen.dart';
import 'screens/game_home_screen.dart';
import 'features/auth/pages/identity_select_page.dart';

void main() {
  // 保險起見在啟動時強制回正向：cooking_prep 頁面會鎖橫向，如果上次是用
  // hot restart（不會跑 dispose()）離開那個頁面，系統的橫向設定會殘留，
  // 導致其他直向頁面（例如六大分類）版面被壓縮到跑版、點擊區域跟著跑掉。
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
      //home: const GameHomeScreen(),
      routes: {
        AppRoutes.gameMarketSort: (context) => const MarketSortGameScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}