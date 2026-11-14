import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:light_memory/core/network/api_response.dart';
import 'package:light_memory/core/services/token_storage.dart';
import 'package:light_memory/features/auth/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// 後端 G3 的 429 body 與忘記密碼相同。
Future<void> _registerWith(http.Response Function() respond) => _withMock(
      (request) async => respond(),
      () => AuthService.register(
        username: '0912345678',
        password: 'Passw0rd!',
        nickname: '玉蘭',
        birthDate: '1955-01-01',
        gender: 'female',
      ),
    );

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
  // 後端 G3：登入只算「失敗」的次數，同一帳號 1 小時 10 次。
  // 被鎖住時，即使密碼正確也回 429。
  group('登入 429（G3）', () {
    test('帶 Retry-After：丟 ApiException 並記錄等待秒數', () async {
      await expectLater(
        _withMock(
          (request) async => _tooMany(retryAfter: '1800'),
          () => AuthService.login(username: '0912345678', password: 'pw'),
        ),
        throwsA(_tooManyException(retryAfter: 1800)),
      );
    });

    test('沒有 Retry-After：retryAfterSeconds 是 null', () async {
      await expectLater(
        _withMock(
          (request) async => _tooMany(),
          () => AuthService.login(username: '0912345678', password: 'pw'),
        ),
        throwsA(_tooManyException(retryAfter: null)),
      );
    });

    test('loginAndSaveToken 也把 429 往上丟，且不存 token', () async {
      SharedPreferences.setMockInitialValues({});
      await expectLater(
        _withMock(
          (request) async => _tooMany(retryAfter: '60'),
          () => AuthService.loginAndSaveToken(
            username: '0912345678',
            password: 'pw',
          ),
        ),
        throwsA(_tooManyException(retryAfter: 60)),
      );
      expect(await TokenStorage.getAccessToken(), isNull);
    });

    test('401 帳密錯誤：訊息不變，不是 ApiException', () async {
      await expectLater(
        _withMock(
          (request) async => http.Response('{"detail":"x"}', 401),
          () => AuthService.login(username: '0912345678', password: 'bad'),
        ),
        throwsA(
          isA<Exception>()
              .having((e) => e is ApiException, 'is ApiException', isFalse)
              .having((e) => e.toString(), 'toString', contains('帳號或密碼錯誤')),
        ),
      );
    });

    test('其他失敗（例如 500）：仍是一般登入失敗訊息', () async {
      await expectLater(
        _withMock(
          (request) async => http.Response('oops', 500),
          () => AuthService.login(username: '0912345678', password: 'pw'),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('登入失敗'),
          ),
        ),
      );
    });

    test('200：回傳 access／refresh，並存下 access token', () async {
      SharedPreferences.setMockInitialValues({});
      await _withMock(
        (request) async => http.Response(
          jsonEncode({'access': 'A', 'refresh': 'R'}),
          200,
        ),
        () => AuthService.loginAndSaveToken(
          username: '0912345678',
          password: 'pw',
        ),
      );
      expect(await TokenStorage.getAccessToken(), 'A');
    });
  });

  // 後端 G3：註冊同一來源 1 小時 30 次，成功失敗都算。
  group('註冊 429（G3）', () {
    test('帶 Retry-After：丟 ApiException 並記錄等待秒數', () async {
      await expectLater(
        _registerWith(() => _tooMany(retryAfter: '600')),
        throwsA(_tooManyException(retryAfter: 600)),
      );
    });

    test('帳號已被註冊（USERNAME_TAKEN）不受影響', () async {
      await expectLater(
        _registerWith(
          () => http.Response(
            jsonEncode({
              'success': false,
              'error': {'code': 'USERNAME_TAKEN', 'message': 'x'},
            }),
            400,
          ),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'USERNAME_TAKEN')
              .having((e) => e.isTooManyRequests, 'isTooManyRequests', isFalse),
        ),
      );
    });
  });
}
