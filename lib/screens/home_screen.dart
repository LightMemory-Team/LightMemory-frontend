import 'package:flutter/material.dart';
// 引入組員 B 寫好的元件與資料結構
import '../features/home/widgets/daily_suggestion_card.dart';
import '../features/home/widgets/game_card.dart';

import '../features/home/models/home_data.dart';
import '../features/home/widgets/top_bar.dart';
import '../features/home/widgets/greeting_section.dart';
import '../features/home/widgets/dynamic_wall_section.dart';

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
      appBar: HomeTopBar(
        unreadNotificationCount: mockHomeData.unreadNotificationCount,
        onSettingsTap: () {},
        onNotificationTap: () {},
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 【隊友 A 負責】問候區（早安，玉蘭！）
            GreetingSection(
              userName: mockHomeData.userName,
              dailyTip: mockHomeData.dailyTip,
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
            DynamicWallSection(
              posts: mockHomeData.wallPosts,
              onSeeMoreTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
