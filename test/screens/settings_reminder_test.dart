// 設定頁「提醒」區塊：打開每日提醒、沒給權限時關回去、網頁版停用

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:light_memory/core/services/reminder_service.dart';
import 'package:light_memory/screens/settings_screen.dart';

import '../core/services/reminder_service_test.dart' show FakeReminderScheduler;

Finder get _reminderSwitch => find.widgetWithText(SwitchListTile, '每日提醒');

bool _switchValue(WidgetTester tester) =>
    tester.widget<SwitchListTile>(_reminderSwitch).value;

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
  await tester.pumpAndSettle();
}

void main() {
  late FakeReminderScheduler fake;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fake = FakeReminderScheduler();
    ReminderService.scheduler = fake;
    ReminderService.isSupportedOverride = true;
  });

  tearDown(() => ReminderService.isSupportedOverride = null);

  testWidgets('預設關閉、顯示晚上 8:00；打開後排程並提示', (tester) async {
    await _pump(tester);

    expect(_switchValue(tester), isFalse);
    expect(find.text('晚上 8:00'), findsOneWidget);

    await tester.tap(_reminderSwitch);
    await tester.pumpAndSettle();

    expect(_switchValue(tester), isTrue);
    expect(fake.scheduled, [const TimeOfDay(hour: 20, minute: 0)]);
    expect(find.text('已設定每天 晚上 8:00 提醒'), findsOneWidget);
  });

  testWidgets('沒給通知權限：開關關回去並說明', (tester) async {
    fake.granted = false;
    await _pump(tester);

    await tester.tap(_reminderSwitch);
    await tester.pumpAndSettle();

    expect(_switchValue(tester), isFalse);
    expect(find.text('需要允許通知才能提醒您，請到手機的「設定」開啟通知'), findsOneWidget);
  });

  testWidgets('已打開時關閉：取消排程', (tester) async {
    SharedPreferences.setMockInitialValues({
      'reminder_enabled': true,
      'reminder_hour': 9,
      'reminder_minute': 0,
    });
    await _pump(tester);
    expect(_switchValue(tester), isTrue);
    expect(find.text('上午 9:00'), findsOneWidget);

    await tester.tap(_reminderSwitch);
    await tester.pumpAndSettle();

    expect(_switchValue(tester), isFalse);
    expect(fake.cancelCount, 1);
  });

  testWidgets('網頁版：開關停用並說明', (tester) async {
    ReminderService.isSupportedOverride = false;
    await _pump(tester);

    expect(find.text('網頁版不支援提醒，請在手機 App 設定'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(_reminderSwitch).onChanged, isNull);
  });
}
