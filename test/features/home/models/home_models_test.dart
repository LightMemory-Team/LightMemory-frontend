import 'package:flutter_test/flutter_test.dart';
import 'package:light_memory/features/home/models/home_models.dart';

void main() {
  group('HomeGame.fromJson', () {
    test('名稱優先讀 name（短名稱）', () {
      final g = HomeGame.fromJson({'id': 'market_sort', 'name': '整理菜籃', 'title': '整理菜籃大挑戰'});
      expect(g.name, '整理菜籃');
    });

    test('沒有 name 時退回 title', () {
      final g = HomeGame.fromJson({'id': 'market_sort', 'title': '整理菜籃'});
      expect(g.name, '整理菜籃');
    });

    test('沒有 played_this_week 時視為本週還沒玩', () {
      expect(HomeGame.fromJson({'id': 'a', 'name': 'x'}).playedThisWeek, isFalse);
      expect(HomeGame.fromJson({'id': 'a', 'name': 'x', 'played_this_week': true}).playedThisWeek, isTrue);
    });

    test('讀認知維度 dimension／dimension_label', () {
      final g = HomeGame.fromJson({
        'id': 'market_route',
        'name': '來去菜市場',
        'dimension': 'attention',
        'dimension_label': '注意力',
      });
      expect(g.dimension, 'attention');
      expect(g.dimensionLabel, '注意力');
    });

    test('後端沒給維度（舊版後端）或空字串時是 null', () {
      expect(HomeGame.fromJson({'id': 'a', 'name': 'x'}).dimensionLabel, isNull);
      expect(
        HomeGame.fromJson({'id': 'a', 'name': 'x', 'dimension_label': ''}).dimensionLabel,
        isNull,
      );
    });
  });

  group('HomeUser.fromJson', () {
    test('讀暱稱、鼓勵語、未讀通知數', () {
      final u = HomeUser.fromJson({
        'user_name': '玉蘭',
        'daily_tip': '今天也要保持大腦活力喔。',
        'unread_notification_count': 3,
      });
      expect(u.userName, '玉蘭');
      expect(u.dailyTip, '今天也要保持大腦活力喔。');
      expect(u.unreadNotificationCount, 3);
    });

    test('缺少欄位時：空暱稱、空鼓勵語、未讀 0', () {
      final u = HomeUser.fromJson({});
      expect(u.userName, '');
      expect(u.dailyTip, '');
      expect(u.unreadNotificationCount, 0);
    });
  });

  group('DailyTasks.fromJson', () {
    test('讀任務清單與完成進度', () {
      final t = DailyTasks.fromJson({
        'date': '2026-11-02',
        'completed_count': 1,
        'total_count': 4,
        'weekly_progress': {'played_dimensions': 2, 'goal': 5},
        'tasks': [
          {'id': 31, 'type': 'game', 'title': '玩「整理菜籃」', 'game_id': 'market_sort', 'dimension': 'executive_function', 'done': true},
          {'id': 35, 'type': 'weekly_report', 'title': '看看上週回顧', 'game_id': null, 'dimension': null, 'done': false},
        ],
      });

      expect(t.tasks.length, 2);
      expect(t.tasks[0].gameId, 'market_sort');
      expect(t.tasks[0].done, isTrue);
      expect(t.tasks[1].gameId, isNull);
      expect(t.playedDimensions, 2);
      expect(t.weeklyGoal, 5);
      expect(t.progress, 0.25);
    });

    test('總數為 0 時進度是 0，不會除以零', () {
      expect(DailyTasks.fromJson({'completed_count': 0, 'total_count': 0}).progress, 0);
    });
  });
}
