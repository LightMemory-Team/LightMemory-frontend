// 首頁招呼區：右上角點數標籤可以點（進點數商城）

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:light_memory/features/home/widgets/greeting_section.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('點數標籤顯示點數，點擊會呼叫 onPointsTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_wrap(GreetingSection(
      userName: '玉蘭',
      dailyTip: '',
      points: 230,
      onPointsTap: () => tapped++,
    )));

    expect(find.text('230 點'), findsOneWidget);
    // 有「›」提示可以點
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.text('230 點'));
    expect(tapped, 1);

    // 讀螢幕的人知道這是按鈕、會去哪裡
    expect(find.bySemanticsLabel('點數 230 點，前往點數商城'), findsOneWidget);
  });

  testWidgets('沒有 onPointsTap 時不顯示「›」，也不是按鈕', (tester) async {
    await tester.pumpWidget(_wrap(const GreetingSection(
      userName: '玉蘭',
      dailyTip: '',
      points: 230,
    )));

    expect(find.text('230 點'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.bySemanticsLabel('點數 230 點'), findsOneWidget);
  });
}
