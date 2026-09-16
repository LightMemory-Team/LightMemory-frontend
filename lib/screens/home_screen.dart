import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../features/home/models/home_data.dart';
import '../features/home/widgets/top_bar.dart';
import '../features/home/widgets/greeting_section.dart';
import '../features/home/widgets/daily_suggestion_card.dart';
import '../features/home/widgets/game_card.dart';
import '../features/home/widgets/dynamic_wall_section.dart';
import 'game_home_screen.dart';

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

    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final isDark = AppSettings.isDarkMode.value;
        final isHighContrast = AppSettings.isHighContrast.value;

        final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
        final titleColor = isDark
            ? Colors.white
            : (isHighContrast ? Colors.black : const Color(0xFF1E1E1E));
        final themeGreen = isDark
            ? const Color(0xFF4CAF50)
            : const Color(0xFF2E6342);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: const TopBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 問候區
                GreetingSection(
                  userName: homeData.userName,
                  dailyTip: homeData.dailyTip,
                ),
                const SizedBox(height: 16),

                // 每日建議卡片
                DailySuggestionCard(suggestion: suggestion),
                const SizedBox(height: 24),

                // 大腦訓練遊戲標題區
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '大腦訓練遊戲',
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(18),
                        fontWeight: isHighContrast
                            ? FontWeight.w900
                            : FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GameHomeScreen(),
                          ),
                        );
                      },
                      child: Text(
                        '查看全部',
                        style: TextStyle(
                          fontSize: AppSettings.scaleFont(14),
                          color: themeGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 遊戲卡片
                GameCard(game: game),
                const SizedBox(height: 24),

                // 動態牆區塊
                DynamicWallSection(
                  posts: homeData.wallPosts,
                  onSeeMoreTap: () {},
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
