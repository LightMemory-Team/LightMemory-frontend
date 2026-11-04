import 'package:flutter/material.dart';
import 'package:light_memory/features/home/services/game_launcher.dart';

/// 測試用的首頁替身：每款遊戲一顆按鈕，點下去走 App 真正的入口 openGame()。
///
/// 舊的六大領域遊戲首頁（GameHomeScreen）已刪除，遊戲現在都是從首頁
/// （MainScreen → openGame）開啟，退出時 popUntil(isFirst) 退回最底層的首頁。
/// 遊玩流程測試把這個替身放在堆疊最底層，代表「首頁」。
/// 按鈕文字沿用原本的領域名稱，測試裡 find.text('執行功能') 等寫法不用改。
class TestHomeScreen extends StatelessWidget {
  const TestHomeScreen({super.key});

  static const entries = <String, String>{
    '視覺空間': 'fridge_check', // 冰箱清點
    '數學': 'market_shopping', // 市場買菜
    '執行功能': 'market_sort', // 整理菜籃
    '注意力': 'market_route', // 來去菜市場
    '工作記憶': 'memory_recall', // 料理準備
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final e in entries.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () => openGame(context, e.value),
                  child: Text(e.key),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
