import 'package:flutter/material.dart';
import '../features/game/market_sort/widgets/market_sort_top_bar.dart';
import '../features/game/market_sort/widgets/game_progress_header.dart';

class WidgetGalleryScreen extends StatelessWidget {
  const WidgetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('元件展示（開發用，非正式畫面）')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. MarketSortTopBar'),
            const SizedBox(height: 8),
            MarketSortTopBar(
              onBackTap: () {},
              onNotificationTap: () {},
              hasUnreadNotification: true,
            ),
            const Divider(height: 32),

            const Text('2. GameProgressHeader'),
            const SizedBox(height: 8),
            const GameProgressHeader(
              currentQuestionNumber: 3,
              totalQuestionCount: 28,
            ),
            const Divider(height: 32),
          ],
        ),
      ),
    );
  }
}