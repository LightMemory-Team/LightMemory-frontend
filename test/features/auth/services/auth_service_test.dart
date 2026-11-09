import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:light_memory/core/network/api_response.dart';
import 'package:light_memory/features/auth/services/auth_service.dart';

// 後端 F4：忘記密碼兩支 API 加上次數限制，超過回 429 TOO_MANY_REQUESTS，
// 並帶 Retry-After（秒）標頭。

http.Response _tooMany({String? retryAfter}) => http.Response(
      jsonEncode({
        'success': false,
        'data': null,
        'error': {'code': 'TOO_MANY_REQUESTS', 'message': '操作太頻繁了，請稍後再試'},
      }),
      429,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        if (retryAfter != null) 'retry-after': retryAfter,
      },
    );

Future<T> _withMock<T>(
  Future<http.Response> Function(http.Request request) handler,
  Future<T> Function() body,
) {
  return http.runWithClient(body, () => MockClient(handler));
}

Matcher _tooManyException({int? retryAfter}) => isA<ApiException>()
    .having((e) => e.statusCode, 'statusCode', 429)
    .having((e) => e.code, 'code', 'TOO_MANY_REQUESTS')
    .having((e) => e.isTooManyRequests, 'isTooManyRequests', isTrue)
    .having((e) => e.retryAfterSeconds, 'retryAfterSeconds', retryAfter);

void main() {
  group('忘記密碼 429', () {
    test('確認帳號：帶 Retry-After 時記錄等待秒數', () async {
      await expectLater(
        _withMock(
          (request) async => _tooMany(retryAfter: '120'),
          () => AuthService.checkPasswordResetAccount('0912345678'),
        ),
        throwsA(_tooManyException(retryAfter: 120)),
      );
    });

    test('確認帳號：沒有 Retry-After 時 retryAfterSeconds 是 null', () async {
      await expectLater(
        _withMock(
          (request) async => _tooMany(),
          () => AuthService.checkPasswordResetAccount('0912345678'),
        ),
        throwsA(_tooManyException(retryAfter: null)),
      );
    });

    test('設定新密碼：同樣能取得 code 與 Retry-After', () async {
      await expectLater(
        _withMock(
          (request) async => _tooMany(retryAfter: '3600'),
          () => AuthService.resetPassword(
            username: '0912345678',
            newPassword: 'NewPassw0rd!',
            newPasswordConfirm: 'NewPassw0rd!',
          ),
        ),
        throwsA(_tooManyException(retryAfter: 3600)),
      );
    });

    test('Retry-After 不是整數（例如日期格式）時當作沒有', () async {
      await expectLater(
        _withMock(
          (request) async => _tooMany(retryAfter: 'Mon, 09 Nov 2026 10:00:00 GMT'),
          () => AuthService.checkPasswordResetAccount('0912345678'),
        ),
        throwsA(_tooManyException(retryAfter: null)),
      );
    });
  });

  group('忘記密碼 既有行為不變', () {
    test('帳號不存在仍是 404 ACCOUNT_NOT_FOUND', () async {
      await expectLater(
        _withMock(
          (request) async => http.Response(
            jsonEncode({
              'success': false,
              'error': {'code': 'ACCOUNT_NOT_FOUND', 'message': 'x'},
            }),
            404,
          ),
          () => AuthService.checkPasswordResetAccount('nobody'),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'ACCOUNT_NOT_FOUND')
              .having((e) => e.isTooManyRequests, 'isTooManyRequests', isFalse)
              .having((e) => e.retryAfterSeconds, 'retryAfterSeconds', isNull),
        ),
      );
    });

    test('200 視為成功', () async {
      await _withMock(
        (request) async => http.Response('{"success": true}', 200),
        () => AuthService.checkPasswordResetAccount('0912345678'),
      );
    });
  });
}
