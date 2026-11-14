// 儀表板「小提醒」：解析 data.alerts、卡片顯示與「去玩一次」

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:light_memory/app_settings.dart';
import 'package:light_memory/features/dashboard/models/dashboard_models.dart';
import 'package:light_memory/features/dashboard/widgets/dashboard_alert_card.dart';
import 'package:light_memory/features/dashboard/widgets/dashboard_palette.dart';

const _message =
    '11/12 玩「市場買菜」的表現比平常低一些，可能當天比較累，建議多注意一下，休息後再玩一次看看。';

Map<String, dynamic> _alertJson({String message = _message}) => {
  'game_id': 'market_shopping',
  'game_title': '市場買菜',
  'dimension': 'math',
  'dimension_label': '數學',
  'played_at': '2026-11-12T15:30:00+08:00',
  'display_score': 18,
  'message': message,
};

void main() {
  group('DashboardOverview.fromApi 的 alerts', () {
    test('讀出每一筆提醒', () {
      final overview = DashboardOverview.fromApi(data: {
        'dimensions': [],
        'alerts': [_alertJson()],
      });

      expect(overview.alerts, hasLength(1));
      final alert = overview.alerts.single;
      expect(alert.gameId, 'market_shopping');
      expect(alert.gameTitle, '市場買菜');
      expect(alert.dimensionLabel, '數學');
      expect(alert.displayScore, 18);
      expect(alert.playedAt, isNotNull);
      expect(alert.message, _message);
    });

    test('後端還沒有 alerts 欄位（舊版）時是空的', () {
      final overview = DashboardOverview.fromApi(data: {'dimensions': []});
      expect(overview.alerts, isEmpty);
    });

    test('沒有文案的提醒不顯示', () {
      final overview = DashboardOverview.fromApi(data: {
        'dimensions': [],
        'alerts': [_alertJson(message: '  ')],
      });
      expect(overview.alerts, isEmpty);
    });
  });

  for (final dark in [false, true]) {
    testWidgets('小提醒卡片顯示文案，點「去玩一次」帶出遊戲代碼（深色：$dark）',
        (tester) async {
      AppSettings.isDarkMode.value = dark;
      addTearDown(() => AppSettings.isDarkMode.value = false);
      String? played;
      final alerts = DashboardAlert.listFrom([_alertJson()]);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DashboardAlertCard(
                alerts: alerts,
                palette: DashboardPalette.current(),
                onPlay: (id) => played = id,
              ),
            ],
          ),
        ),
      ));

      expect(find.text('小提醒'), findsOneWidget);
      expect(find.text(_message), findsOneWidget);
      // 不出現讓長輩緊張的字眼
      expect(find.textContaining('異常'), findsNothing);
      expect(find.textContaining('退步'), findsNothing);

      await tester.tap(find.text('去玩一次「市場買菜」'));
      expect(played, 'market_shopping');
    });
  }
}
