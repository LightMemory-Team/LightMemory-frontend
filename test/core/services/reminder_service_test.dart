// 每日提醒：設定存取、排程時間、權限沒給時不打開

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:light_memory/core/services/reminder_service.dart';

/// 假的排程器：記下排了什麼時間、取消了幾次
class FakeReminderScheduler implements ReminderScheduler {
  bool granted;
  int initCount = 0;
  int cancelCount = 0;
  final List<TimeOfDay> scheduled = [];

  FakeReminderScheduler({this.granted = true});

  @override
  Future<void> init() async => initCount++;

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<void> scheduleDaily(TimeOfDay time) async => scheduled.add(time);

  @override
  Future<void> cancel() async => cancelCount++;
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

  group('formatTime（給長輩看的時間）', () {
    test('上午、中午、下午、晚上、凌晨', () {
      expect(
        ReminderService.formatTime(const TimeOfDay(hour: 20, minute: 0)),
        '晚上 8:00',
      );
      expect(
        ReminderService.formatTime(const TimeOfDay(hour: 9, minute: 5)),
        '上午 9:05',
      );
      expect(
        ReminderService.formatTime(const TimeOfDay(hour: 12, minute: 30)),
        '中午 12:30',
      );
      expect(
        ReminderService.formatTime(const TimeOfDay(hour: 15, minute: 0)),
        '下午 3:00',
      );
      expect(
        ReminderService.formatTime(const TimeOfDay(hour: 0, minute: 10)),
        '凌晨 12:10',
      );
    });
  });

  group('nextInstanceOf（下一次提醒）', () {
    setUpAll(tz_data.initializeTimeZones);

    test('今天時間還沒到：今天', () {
      final taipei = tz.getLocation('Asia/Taipei');
      final now = tz.TZDateTime(taipei, 2026, 11, 14, 19, 0);
      final next = ReminderService.nextInstanceOf(
        const TimeOfDay(hour: 20, minute: 0),
        now,
      );
      expect(next, tz.TZDateTime(taipei, 2026, 11, 14, 20, 0));
    });

    test('今天已經過了（或剛好是現在）：明天', () {
      final taipei = tz.getLocation('Asia/Taipei');
      final now = tz.TZDateTime(taipei, 2026, 11, 14, 20, 0);
      final next = ReminderService.nextInstanceOf(
        const TimeOfDay(hour: 20, minute: 0),
        now,
      );
      expect(next, tz.TZDateTime(taipei, 2026, 11, 15, 20, 0));
    });
  });

  test('預設關閉、晚上 8:00', () async {
    final settings = await ReminderService.load();
    expect(settings.enabled, isFalse);
    expect(settings.time, const TimeOfDay(hour: 20, minute: 0));
  });

  test('打開：有權限就排程並存起來', () async {
    final ok = await ReminderService.enable(
      const TimeOfDay(hour: 9, minute: 30),
    );

    expect(ok, isTrue);
    expect(fake.scheduled, [const TimeOfDay(hour: 9, minute: 30)]);
    final settings = await ReminderService.load();
    expect(settings.enabled, isTrue);
    expect(settings.time, const TimeOfDay(hour: 9, minute: 30));
  });

  test('打開：沒給權限就不打開、不排程', () async {
    fake.granted = false;

    final ok = await ReminderService.enable(
      const TimeOfDay(hour: 9, minute: 30),
    );

    expect(ok, isFalse);
    expect(fake.scheduled, isEmpty);
    expect((await ReminderService.load()).enabled, isFalse);
  });

  test('關閉：取消排程，時間保留', () async {
    await ReminderService.enable(const TimeOfDay(hour: 7, minute: 0));

    await ReminderService.disable();

    expect(fake.cancelCount, 1);
    final settings = await ReminderService.load();
    expect(settings.enabled, isFalse);
    expect(settings.time, const TimeOfDay(hour: 7, minute: 0));
  });

  test('改時間：已打開時用新時間重新排程；關閉時只存時間', () async {
    await ReminderService.updateTime(const TimeOfDay(hour: 10, minute: 0));
    expect(fake.scheduled, isEmpty);

    await ReminderService.enable(const TimeOfDay(hour: 10, minute: 0));
    await ReminderService.updateTime(const TimeOfDay(hour: 21, minute: 15));

    expect(fake.scheduled.last, const TimeOfDay(hour: 21, minute: 15));
    expect(
      (await ReminderService.load()).time,
      const TimeOfDay(hour: 21, minute: 15),
    );
  });

  test('App 啟動：之前打開過就重新排程，沒打開過只初始化', () async {
    await ReminderService.init();
    expect(fake.initCount, 1);
    expect(fake.scheduled, isEmpty);

    SharedPreferences.setMockInitialValues({
      'reminder_enabled': true,
      'reminder_hour': 8,
      'reminder_minute': 45,
    });
    await ReminderService.init();
    expect(fake.scheduled, [const TimeOfDay(hour: 8, minute: 45)]);
  });

  test('網頁版不支援：不能打開，啟動時什麼都不做', () async {
    ReminderService.isSupportedOverride = false;

    expect(
      await ReminderService.enable(const TimeOfDay(hour: 8, minute: 0)),
      isFalse,
    );
    await ReminderService.init();
    expect(fake.initCount, 0);
  });
}
