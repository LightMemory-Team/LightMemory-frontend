import 'package:flutter/material.dart';
import '../features/home/models/home_data.dart';
import '../features/home/widgets/top_bar.dart';
import '../features/home/widgets/greeting_section.dart';
import '../features/home/widgets/daily_suggestion_card.dart';
import '../features/home/widgets/game_card.dart';
import '../features/home/widgets/dynamic_wall_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeData = mockHomeData;
    final suggestion = DailySuggestion(
      text: '完成一場菜市場遊戲',
      actionRoute: 'game_market_sort',
    );
    final game = Game(id: 'market_sort', title: '菜市場');

    final safeTextScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TopBar(unreadCount: homeData.unreadNotificationCount),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 組員 A 的問候區
            GreetingSection(
              userName: homeData.userName,
              dailyTip: homeData.dailyTip,
            ),
            const SizedBox(height: 16),

            // 組員 B 的每日建議卡片
            DailySuggestionCard(suggestion: suggestion),
            const SizedBox(height: 24),

            // 大腦訓練遊戲標題區
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '大腦訓練遊戲',
                  textScaler: safeTextScaler,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                Text(
                  '查看全部',
                  textScaler: safeTextScaler,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2E6342),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 組員 B 的遊戲卡片
            GameCard(game: game),
            const SizedBox(height: 24),

            // 組員 A 的動態牆區塊（內部已自帶「動態牆 / 更多動態」標題）
            DynamicWallSection(posts: homeData.wallPosts, onSeeMoreTap: () {}),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
