import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_memory/features/game/fridge_inventory/pages/fridge_result_page.dart';
import 'package:light_memory/features/game/market_shopping/models/market_shopping_models.dart';
import 'package:light_memory/features/game/market_shopping/pages/market_shopping_checkout_page.dart';
import 'package:light_memory/features/game/market_shopping/pages/market_shopping_memorize_page.dart';
import 'package:light_memory/features/game/market_shopping/pages/market_shopping_play_page.dart';
import 'package:light_memory/features/game/market_shopping/pages/market_shopping_result_page.dart';
import 'package:light_memory/features/game/market_sort/services/market_sort_api_service.dart';
import 'package:light_memory/features/game/widgets/game_menu_button.dart';
import 'package:light_memory/screens/market_sort_game_screen.dart';
import 'package:light_memory/screens/market_sort_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 遊戲「退出」要回到堆疊最底層的首頁（MainScreen）。
///
/// 以前退出會 pushAndRemoveUntil(GameHomeScreen)（舊的六大領域遊戲首頁，已刪除），
/// 堆疊被清空後那頁的 home icon 只做 pop，回不去首頁。現在所有退出點都改成
/// popUntil(isFirst)。這裡用一個假首頁當堆疊最底層，驗證每個退出點都會退回它，
/// 而且遊戲頁已經被移出堆疊。
const _homeText = 'HOME-STUB';
const _midText = 'MID-STUB';

final _navKey = GlobalKey<NavigatorState>();

/// 堆疊：假首頁 → 中間頁（模擬教學頁等）→ 遊戲頁
Future<void> _pumpGameOnTopOfHome(WidgetTester tester, Widget game) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: _navKey,
      home: const Scaffold(body: Center(child: Text(_homeText))),
    ),
  );

  _navKey.currentState!.push(
    MaterialPageRoute(
      builder: (_) => const Scaffold(body: Center(child: Text(_midText))),
    ),
  );
  await tester.pumpAndSettle();
  _navKey.currentState!.push(MaterialPageRoute(builder: (_) => game));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void _expectBackAtHome(Type gamePage) {
  expect(find.text(_homeText), findsOneWidget);
  expect(find.text(_midText), findsNothing);
  expect(find.byType(gamePage), findsNothing);
  expect(_navKey.currentState!.canPop(), isFalse);
}

/// 點遊戲頂部「選單」→ 暫停選單「退出遊戲」
Future<void> _exitFromPauseMenu(WidgetTester tester) async {
  await tester.tap(find.byType(GameMenuButton));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.text('退出遊戲'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _tapExit(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

ShoppingQuestion _question() {
  final foods = [
    MarketFood(foodCode: 'apple', foodName: '蘋果'),
    MarketFood(foodCode: 'tomato', foodName: '番茄'),
    MarketFood(foodCode: 'egg', foodName: '雞蛋'),
  ];
  return ShoppingQuestion(
    difficulty: 'easy',
    currentQuestion: 1,
    totalQuestions: 10,
    shoppingList: foods.take(2).toList(),
    selectionOptions: foods,
  );
}

void main() {
  setUp(() {
    // 沒有 token：結果頁載入歷史成績會失敗，頁面要能照常顯示並退出
    SharedPreferences.setMockInitialValues({});
  });

  group('結果頁「退出」回首頁', () {
    testWidgets('整理菜籃結果頁', (tester) async {
      final result = MarketSortSubmitResult(
        currentScore: 80,
        highestScore: 90,
        recentScores: [60, 70, 80],
        encouragementTier: 'good',
      );
      await _pumpGameOnTopOfHome(tester, MarketSortResultScreen(result: result));

      await _tapExit(tester, '退出遊戲');

      _expectBackAtHome(MarketSortResultScreen);
    });

    testWidgets('市場買菜結果頁', (tester) async {
      await _pumpGameOnTopOfHome(
        tester,
        const MarketShoppingResultPage(score: 80, accuracy: 70),
      );

      await _tapExit(tester, '退出遊戲');

      _expectBackAtHome(MarketShoppingResultPage);
    });

    testWidgets('冰箱清點結果頁', (tester) async {
      await _pumpGameOnTopOfHome(
        tester,
        const FridgeResultPage(finalScore: 80),
      );

      await _tapExit(tester, '退出');

      _expectBackAtHome(FridgeResultPage);
    });
  });

  group('整理菜籃 暫停選單「退出遊戲」回首頁', () {
    testWidgets('進入題目後', (tester) async {
      await _pumpGameOnTopOfHome(tester, const MarketSortGameScreen());
      // 先跑完 3 秒倒數；題目剛出現時還在鎖定階段（不能點），再等到可以互動
      for (var i = 0; i < 12 && find.byType(GameMenuButton).evaluate().isEmpty; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pump(const Duration(seconds: 3));

      await _exitFromPauseMenu(tester);

      _expectBackAtHome(MarketSortGameScreen);
      // 退出後題目計時器不能再動到已經離開的頁面
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('市場買菜 暫停選單「退出遊戲」回首頁', () {
    testWidgets('記憶清單頁', (tester) async {
      await _pumpGameOnTopOfHome(
        tester,
        MarketShoppingMemorizePage(
          question: _question(),
          onTimeUp: () {},
          onRestart: () {},
        ),
      );

      await _exitFromPauseMenu(tester);

      _expectBackAtHome(MarketShoppingMemorizePage);
    });

    testWidgets('選菜頁', (tester) async {
      await _pumpGameOnTopOfHome(
        tester,
        MarketShoppingPlayPage(
          question: _question(),
          onSubmitAnswer: (_, __) async => ItemAnswerResult(isCorrect: true),
          onProceedToCheckout: () {},
          onRestart: () {},
        ),
      );

      await _exitFromPauseMenu(tester);

      _expectBackAtHome(MarketShoppingPlayPage);
    });

    testWidgets('結帳頁', (tester) async {
      await _pumpGameOnTopOfHome(
        tester,
        MarketShoppingCheckoutPage(
          question: _question(),
          itemAnswerResult: ItemAnswerResult(
            isCorrect: true,
            budget: 100,
            spentAmount: 60,
            changeOptions: [30, 40, 50],
          ),
          onSubmitAnswer: (_, __) async => throw UnimplementedError(),
          onProceedToNextQuestion: (_) {},
          onGameCompleted: () {},
          onRestart: () {},
        ),
      );

      await _exitFromPauseMenu(tester);

      _expectBackAtHome(MarketShoppingCheckoutPage);
    });
  });

  // 冰箱清點、料理準備、來去菜市場的遊戲頁一開場就會打後端 API，
  // 不好在 widget test 裡直接開起來，改用原始碼檢查。
  group('原始碼檢查：所有遊戲的退出點都直接回首頁', () {
    // 檔案 → 該檔案至少要有幾個 popUntil(isFirst) 退出點
    const exitPoints = {
      'lib/features/game/fridge_inventory/pages/fridge_game_page.dart': 1,
      'lib/features/game/fridge_inventory/pages/fridge_result_page.dart': 1,
      'lib/features/game/market_shopping/pages/market_shopping_play_page.dart': 1,
      'lib/features/game/market_shopping/pages/market_shopping_memorize_page.dart': 1,
      'lib/features/game/market_shopping/pages/market_shopping_checkout_page.dart': 1,
      'lib/features/game/market_shopping/pages/market_shopping_result_page.dart': 1,
      'lib/screens/market_sort_game_screen.dart': 1, // 暫停選單退出
      'lib/screens/market_sort_result_screen.dart': 1,
      'lib/features/game/go_to_market/pages/go_to_market_game_page.dart': 2, // 暫停退出＋結果彈窗退出
      'lib/features/game/cooking_prep/pages/cooking_prep_game_page.dart': 1,
    };

    test('每個退出點都使用 popUntil(isFirst)', () {
      exitPoints.forEach((path, minCount) {
        final count = 'popUntil((route) => route.isFirst)'
            .allMatches(File(path).readAsStringSync())
            .length;
        expect(count, greaterThanOrEqualTo(minCount), reason: path);
      });
    });

    test('舊的 GameHomeScreen 已刪除，沒有任何檔案再引用', () {
      expect(File('lib/screens/game_home_screen.dart').existsSync(), isFalse);

      final offenders = <String>[
        for (final f in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart')))
          if (f.readAsStringSync().contains('GameHomeScreen')) f.path,
      ];
      expect(offenders, isEmpty, reason: '這些檔案還在引用 GameHomeScreen：$offenders');
    });

    test('遊戲頁不再用 pushAndRemoveUntil 清空堆疊（只有登入過期可以回 AuthGate）', () {
      final offenders = <String>[];
      for (final path in exitPoints.keys) {
        for (final match in RegExp(r'pushAndRemoveUntil\(\s*MaterialPageRoute\(\s*builder: \(context\) => const (\w+)\(')
            .allMatches(File(path).readAsStringSync())) {
          if (match.group(1) != 'AuthGate') offenders.add('$path → ${match.group(1)}');
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
