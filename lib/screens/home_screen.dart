import 'package:flutter/material.dart';
// 引入組員 B 寫好的元件與資料結構
import '../features/home/widgets/daily_suggestion_card.dart';
import '../features/home/widgets/game_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 建立 B 區塊需要的假資料（供畫面排版顯示）
    final suggestion = DailySuggestion(
      text: '完成一場菜市場遊戲',
      actionRoute: 'game_market_sort',
    );
    final game = Game(id: 'market_sort', title: '菜市場');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.black87),
          onPressed: () {},
        ),
        title: const Text(
          '憶智防線',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 【隊友 A 負責】問候區（早安，玉蘭！）
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('【A 負責】問候區預留位置'),
            ),

            // 【已組裝 B 的元件】每日建議卡片
            DailySuggestionCard(suggestion: suggestion),
            const SizedBox(height: 20),

            // 【已組裝 B 的元件】大腦訓練遊戲區標題
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '大腦訓練遊戲',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '查看全部',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 【已組裝 B 的元件】菜市場遊戲卡片
            GameCard(game: game),
            const SizedBox(height: 20),

            // 【隊友 A 負責】動態牆
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('【A 負責】動態牆預留位置'),
            ),
          ],
        ),
      ),
    );
  }
}
