import '../core/constants/route_constants.dart';
import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../features/game/models/game_mock_data.dart';
import '../features/game/widgets/game_top_bar.dart';
import '../features/game/widgets/training_progress_card.dart';
import '../features/game/widgets/domain_card.dart';
import '../features/game/widgets/game_bottom_actions.dart';
import '../theme/app_theme.dart';
import '../features/game/market_shopping/pages/market_shopping_game_page.dart';
import 'notification_screen.dart';
// 改引用教學頁面
import '../features/game/go_to_market/pages/go_to_market_tutorial_page.dart';
import '../features/game/go_to_market/services/audio_service.dart';

class GameHomeScreen extends StatelessWidget {
  const GameHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ListenableBuilder(
              listenable: AppSettings.unreadNotificationCount,
              builder: (context, _) {
                return GameTopBar(
                  hasUnreadNotification:
                      AppSettings.unreadNotificationCount.value > 0,
                  onHomeTap: () => Navigator.pop(context),
                  onNotificationTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const TrainingProgressCard(
                completedCount: 1,
                totalCount: 3,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const crossAxisCount = 2;
                    const rowCount = 3;
                    const mainAxisSpacing = 16.0;
                    const crossAxisSpacing = 16.0;

                    final itemWidth =
                        (constraints.maxWidth -
                            crossAxisSpacing * (crossAxisCount - 1)) /
                        crossAxisCount;
                    final itemHeight =
                        (constraints.maxHeight -
                            mainAxisSpacing * (rowCount - 1)) /
                        rowCount;

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(), // 禁止捲動
                      itemCount: mockCognitiveDomains.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: mainAxisSpacing,
                        crossAxisSpacing: crossAxisSpacing,
                        childAspectRatio: itemWidth / itemHeight,
                      ),
                      itemBuilder: (context, index) {
                        final domain = mockCognitiveDomains[index];
                        return DomainCard(
                          domain: domain,
                          onTap: () {
                            AudioService.playClick();

                            if (domain.id == 'math') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MarketShoppingGamePage(),
                                ),
                              );
                            } else if (domain.id == 'executive_function') {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.gameMarketSort,
                              );
                            } else if (domain.id == 'attention') {
                              // 改跳轉到教學頁面
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const GoToMarketTutorialPage(),
                                ),
                              );
                            } else {
                              // TODO: 其他領域待各自組員接上，導向該領域的遊戲選單頁，帶入 domain.id
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${domain.title} 訓練敬請期待！'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: GameBottomActions(
                onDailyTaskTap: () {},
                onAchievementTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
