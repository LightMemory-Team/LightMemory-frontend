import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:light_memory/core/network/api_response.dart';
import 'package:light_memory/core/network/auth_headers.dart';
import 'package:light_memory/features/home/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用 MockClient 攔截請求，不需要真的連後端
Future<T> _withMock<T>(
  Future<http.Response> Function(http.Request request) handler,
  Future<T> Function() body,
) {
  return http.runWithClient(body, () => MockClient(handler));
}

http.Response _json(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'test-token'});
  });

  group('getNotifications', () {
    test('呼叫 /api/social/notifications/ 並帶登入 token', () async {
      late http.Request captured;
      await _withMock(
        (request) async {
          captured = request;
          return _json({'success': true, 'data': {'notifications': []}, 'error': null});
        },
        () => NotificationService().getNotifications(),
      );

      expect(captured.method, 'GET');
      expect(captured.url.path, '/api/social/notifications/');
      expect(captured.headers['Authorization'], 'Bearer test-token');
    });

    test('從 data.notifications 讀出通知', () async {
      final list = await _withMock(
        (_) async => _json({
          'success': true,
          'data': {
            'notifications': [
              {'id': 2, 'message': 'A', 'notification_type': 'comment', 'target_url': '/api/social/posts/9/', 'is_read': false},
              {'id': 1, 'message': 'B', 'notification_type': 'memory_recall', 'target_url': '', 'is_read': true},
            ],
          },
          'error': null,
        }),
        () => NotificationService().getNotifications(),
      );

      expect(list.length, 2);
      expect(list[0].id, 2);
      expect(list[0].message, 'A');
      expect(list[0].isRead, isFalse);
      expect(list[1].isRead, isTrue);
    });

    test('回傳格式不是預期的結構時回空陣列，不丟例外', () async {
      final list = await _withMock(
        (_) async => _json({'success': true, 'data': null, 'error': null}),
        () => NotificationService().getNotifications(),
      );
      expect(list, isEmpty);
    });

    test('後端回 404 NOTIFICATION_NOT_FOUND 時丟出帶 code 的 ApiException', () async {
      await expectLater(
        _withMock(
          (_) async => _json({
            'success': false,
            'data': null,
            'error': {'code': 'NOTIFICATION_NOT_FOUND', 'message': '找不到這則通知'},
          }, 404),
          () => NotificationService().getNotifications(),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.code, 'code', 'NOTIFICATION_NOT_FOUND')
              .having((e) => e.message, 'message', '找不到這則通知'),
        ),
      );
    });

    test('回傳不是 JSON（例如 502）時丟出 ApiException，帶狀態碼', () async {
      await expectLater(
        _withMock(
          (_) async => http.Response('<html>Bad Gateway</html>', 502),
          () => NotificationService().getNotifications(),
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 502)),
      );
    });

    test('沒有登入 token 時不送請求，丟出 NotLoggedInException', () async {
      SharedPreferences.setMockInitialValues({});
      var called = false;
      await expectLater(
        _withMock(
          (_) async {
            called = true;
            return _json({});
          },
          () => NotificationService().getNotifications(),
        ),
        throwsA(isA<NotLoggedInException>()),
      );
      expect(called, isFalse);
    });
  });

  group('markAllRead', () {
    test('PATCH /api/social/notifications/，body 是 {"is_read": true}', () async {
      late http.Request captured;
      await _withMock(
        (request) async {
          captured = request;
          return _json({'success': true, 'data': {}, 'error': null});
        },
        () => NotificationService().markAllRead(),
      );

      expect(captured.method, 'PATCH');
      expect(captured.url.path, '/api/social/notifications/');
      expect(jsonDecode(captured.body), {'is_read': true});
      expect(captured.headers['Authorization'], 'Bearer test-token');
    });

    test('失敗時丟出 ApiException', () async {
      await expectLater(
        _withMock(
          (_) async => _json({'detail': '沒有權限'}, 403),
          () => NotificationService().markAllRead(),
        ),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', '沒有權限')),
      );
    });
  });

  group('markRead', () {
    test('PATCH /api/social/notifications/<id>/read/', () async {
      late http.Request captured;
      await _withMock(
        (request) async {
          captured = request;
          return _json({'success': true, 'data': {}, 'error': null});
        },
        () => NotificationService().markRead(12),
      );

      expect(captured.method, 'PATCH');
      expect(captured.url.path, '/api/social/notifications/12/read/');
      expect(captured.headers['Authorization'], 'Bearer test-token');
    });

    test('找不到通知（404 NOTIFICATION_NOT_FOUND）時丟出帶 code 的 ApiException', () async {
      await expectLater(
        _withMock(
          (_) async => _json({
            'success': false,
            'data': null,
            'error': {'code': 'NOTIFICATION_NOT_FOUND', 'message': '找不到這則通知'},
          }, 404),
          () => NotificationService().markRead(999),
        ),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NOTIFICATION_NOT_FOUND')),
      );
    });
  });
}
