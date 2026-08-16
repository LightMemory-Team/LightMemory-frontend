import 'package:flutter/material.dart';
import '../widgets/daily_suggestion_card.dart';
import '../widgets/game_card.dart';

class HomePageTest extends StatelessWidget {
  const HomePageTest({super.key});

  @override
  Widget build(BuildContext context) {
    final suggestion = DailySuggestion(
      text: '完成一場菜市場遊戲',
      actionRoute: 'game_market_sort',
    );
    final game = Game(id: 'market_sort', title: '菜市場');

    return Scaffold(
      appBar: AppBar(title: const Text('首頁元件測試')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DailySuggestionCard(suggestion: suggestion),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '大腦訓練遊戲',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text('查看全部', style: TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 12),
            GameCard(game: game),
          ],
        ),
      ),
    );
  }
}