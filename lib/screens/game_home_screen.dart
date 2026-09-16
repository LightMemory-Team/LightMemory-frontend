import 'package:flutter/material.dart';
import '../features/game/models/game_mock_data.dart';
import '../features/game/widgets/game_top_bar.dart';
import '../features/game/widgets/training_progress_card.dart';
import '../features/game/widgets/domain_card.dart';
import '../features/game/widgets/game_bottom_actions.dart';
import '../theme/app_theme.dart';
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
            GameTopBar(
              hasUnreadNotification: true,
              onHomeTap: () {},
              onNotificationTap: () {},
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
                      physics: const NeverScrollableScrollPhysics(),
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

                            final isAttention =
                                domain.id.toLowerCase().contains('attention') ||
                                domain.title.contains('注意');

                            if (isAttention) {
                              // 改跳轉到教學頁面
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const GoToMarketTutorialPage(),
                                ),
                              );
                            } else {
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
