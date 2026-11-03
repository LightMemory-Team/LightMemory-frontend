import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:light_memory/features/home/services/home_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Future<T> _withMock<T>(
  Future<http.Response> Function(http.Request request) handler,
  Future<T> Function() body,
) {
  return http.runWithClient(body, () => MockClient(handler));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'test-token'});
  });

  group('getUser', () {
    test('暱稱、未讀數來自 /api/home/user/，鼓勵語來自 /api/home/greet/', () async {
      final paths = <String>[];
      final user = await _withMock(
        (request) async {
          paths.add(request.url.path);
          if (request.url.path == '/api/home/user/') {
            return _json({'user_name': '玉蘭', 'unread_notification_count': 3});
          }
          if (request.url.path == '/api/home/greet/') {
            return _json({'daily_tip': '今天也要保持大腦活力喔。'});
          }
          return http.Response('not found', 404);
        },
        () => HomeService().getUser(),
      );

      expect(paths, containsAll(['/api/home/user/', '/api/home/greet/']));
      expect(user.userName, '玉蘭');
      expect(user.unreadNotificationCount, 3);
      expect(user.dailyTip, '今天也要保持大腦活力喔。');
    });

    test('相容 {success, data} 包裝', () async {
      final user = await _withMock(
        (request) async {
          if (request.url.path == '/api/home/user/') {
            return _json({'success': true, 'data': {'user_name': '玉蘭', 'unread_notification_count': 1}});
          }
          return _json({'success': true, 'data': {'daily_tip': '加油'}});
        },
        () => HomeService().getUser(),
      );

      expect(user.userName, '玉蘭');
      expect(user.dailyTip, '加油');
    });

    test('greet 失敗時只少鼓勵語，名字和未讀數照常', () async {
      final user = await _withMock(
        (request) async {
          if (request.url.path == '/api/home/user/') {
            return _json({'user_name': '玉蘭', 'unread_notification_count': 2});
          }
          return http.Response('error', 500);
        },
        () => HomeService().getUser(),
      );

      expect(user.userName, '玉蘭');
      expect(user.unreadNotificationCount, 2);
      expect(user.dailyTip, '');
    });

    test('user 失敗時整體失敗（首頁要顯示錯誤畫面）', () async {
      await expectLater(
        _withMock(
          (request) async {
            if (request.url.path == '/api/home/greet/') return _json({'daily_tip': 'x'});
            return http.Response('error', 500);
          },
          () => HomeService().getUser(),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getGames', () {
    test('讀 games[]，名稱優先用 name', () async {
      final games = await _withMock(
        (_) async => _json({
          'games': [
            {'id': 'market_sort', 'title': '整理菜籃大挑戰', 'name': '整理菜籃', 'is_developed': true},
          ],
        }),
        () => HomeService().getGames(),
      );

      expect(games.length, 1);
      expect(games.first.id, 'market_sort');
      expect(games.first.name, '整理菜籃');
    });

    test('games 不是陣列時回空清單', () async {
      final games = await _withMock(
        (_) async => _json({'games': null}),
        () => HomeService().getGames(),
      );
      expect(games, isEmpty);
    });
  });

  test('getDailyTasks 讀 /api/home/daily-tasks/', () async {
    late String path;
    final tasks = await _withMock(
      (request) async {
        path = request.url.path;
        return _json({
          'date': '2026-11-02',
          'completed_count': 1,
          'total_count': 2,
          'weekly_progress': {'played_dimensions': 1, 'goal': 5},
          'tasks': [
            {'id': 34, 'type': 'diary', 'title': '寫一篇聲影日記', 'game_id': null, 'dimension': 'language', 'done': false},
          ],
        });
      },
      () => HomeService().getDailyTasks(),
    );

    expect(path, '/api/home/daily-tasks/');
    expect(tasks.tasks.single.type, 'diary');
    expect(tasks.completedCount, 1);
  });
}
