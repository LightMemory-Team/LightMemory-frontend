import 'package:flutter/material.dart';
import '../features/game/models/game_mock_data.dart';
import '../features/game/widgets/game_top_bar.dart';
import '../features/game/widgets/training_progress_card.dart';
import '../features/game/widgets/domain_card.dart';
import '../features/game/widgets/game_bottom_actions.dart';
import '../theme/app_theme.dart';

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
              onHomeTap: () {
                // TODO: 導回首頁
              },
              onNotificationTap: () {
                // TODO: 導向通知頁
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

                  // 反推每張卡片的寬高，讓 2欄x3列 剛好填滿目前可用的空間
                  final itemWidth =
                      (constraints.maxWidth - crossAxisSpacing * (crossAxisCount - 1)) /
                          crossAxisCount;
                  final itemHeight =
                      (constraints.maxHeight - mainAxisSpacing * (rowCount - 1)) /
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
                          // TODO: 導向該領域的遊戲選單頁，帶入 domain.id
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
                onDailyTaskTap: () {
                  // TODO: 導向每日任務頁
                },
                onAchievementTap: () {
                  // TODO: 導向我的成就頁
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}