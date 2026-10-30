import 'package:flutter/material.dart';

import '../../../core/constants/route_constants.dart';
import '../../game/cooking_prep/pages/cooking_prep_game_page.dart';
import '../../game/fridge_inventory/pages/fridge_tutorial_page.dart';
import '../../game/go_to_market/pages/go_to_market_tutorial_page.dart';
import '../../game/go_to_market/services/audio_service.dart';
import '../../game/market_shopping/pages/market_shopping_game_page.dart';

/// 依遊戲代碼打開遊戲（首頁遊戲卡片、今日任務、全部遊戲頁共用）
///
/// 每款遊戲的入口跟原本「六大領域遊戲首頁」（game_home_screen.dart）一致：
/// - fridge_check     冰箱清點   → 教學頁
/// - market_shopping  市場買菜   → 遊戲頁
/// - market_sort      整理菜籃   → 遊戲（路由 gameMarketSort）
/// - market_route     來去菜市場 → 教學頁
/// - memory_recall    料理準備   → 遊戲頁
///
/// 回傳的 Future 會在使用者從遊戲回來時結束，首頁可以等它結束後重新整理今日任務。
Future<void> openGame(BuildContext context, String gameId) async {
  AudioService.playClick();

  switch (gameId) {
    case 'fridge_check':
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const FridgeTutorialPage()),
      );
      return;
    case 'market_shopping':
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const MarketShoppingGamePage()),
      );
      return;
    case 'market_sort':
      await Navigator.of(context).pushNamed(AppRoutes.gameMarketSort);
      return;
    case 'market_route':
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const GoToMarketTutorialPage()),
      );
      return;
    case 'memory_recall':
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const CookingPrepGamePage()),
      );
      return;
    default:
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('這個遊戲敬請期待！'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}