// 大腦訓練遊戲卡片：顯示對應的認知維度，字體放大時不溢版

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:light_memory/app_settings.dart';
import 'package:light_memory/features/home/models/home_models.dart';
import 'package:light_memory/features/home/widgets/game_card.dart';

const _game = HomeGame(
  id: 'memory_recall',
  name: '料理準備',
  playedThisWeek: false,
  dimension: 'working_memory',
  dimensionLabel: '工作記憶',
);

/// 跟首頁一樣兩張並排，手機寬度 360
Widget _wrap(HomeGame game) => MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: GameCard(game: game, onTap: () {})),
              const SizedBox(width: 14),
              Expanded(child: GameCard(game: game, onTap: () {})),
            ],
          ),
        ),
      ),
    );

void main() {
  setUp(() => AppSettings.fontSizeLevel.value = 2);
  tearDown(() => AppSettings.fontSizeLevel.value = 2);

  void useSmallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('卡片顯示遊戲名稱與維度標籤', (tester) async {
    useSmallPhone(tester);
    await tester.pumpWidget(_wrap(_game));

    expect(find.text('料理準備'), findsNWidgets(2));
    expect(find.text('工作記憶'), findsNWidgets(2));
    expect(find.text('本週還沒玩'), findsNWidgets(2));
  });

  testWidgets('沒有維度時不顯示標籤', (tester) async {
    useSmallPhone(tester);
    await tester.pumpWidget(_wrap(const HomeGame(
      id: 'market_sort',
      name: '整理菜籃',
      playedThisWeek: true,
    )));

    expect(find.byIcon(Icons.psychology_outlined), findsNothing);
  });

  for (final level in [1, 2, 3, 4, 5]) {
    testWidgets('字體等級 $level：卡片不溢版', (tester) async {
      useSmallPhone(tester);
      AppSettings.fontSizeLevel.value = level;
      await tester.pumpWidget(_wrap(_game));
      // RenderFlex overflow 會在這裡變成例外
      expect(tester.takeException(), isNull);
    });
  }

  test('字體放大時卡片跟著加高', () {
    AppSettings.fontSizeLevel.value = 2;
    expect(GameCard.cardHeight, 130);
    AppSettings.fontSizeLevel.value = 5;
    expect(GameCard.cardHeight, greaterThan(130));
  });
}
