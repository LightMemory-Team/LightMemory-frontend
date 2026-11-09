import 'package:flutter_test/flutter_test.dart';
import 'package:light_memory/core/network/api_response.dart';
import 'package:light_memory/core/network/error_message.dart';

ApiException _tooMany({int? retryAfter}) => ApiException(
      statusCode: 429,
      code: 'TOO_MANY_REQUESTS',
      message: '操作太頻繁了，請稍後再試',
      retryAfterSeconds: retryAfter,
    );

void main() {
  group('friendlyErrorMessage 429', () {
    test('沒有 Retry-After：用後端的訊息', () {
      expect(friendlyErrorMessage(_tooMany()), '操作太頻繁了，請稍後再試');
    });

    test('1 分鐘內：顯示秒數', () {
      expect(friendlyErrorMessage(_tooMany(retryAfter: 30)), '操作太頻繁了，請約 30 秒後再試');
      expect(friendlyErrorMessage(_tooMany(retryAfter: 60)), '操作太頻繁了，請約 60 秒後再試');
    });

    test('超過 1 分鐘：無條件進位成分鐘', () {
      expect(friendlyErrorMessage(_tooMany(retryAfter: 61)), '操作太頻繁了，請約 2 分鐘後再試');
      expect(friendlyErrorMessage(_tooMany(retryAfter: 1800)), '操作太頻繁了，請約 30 分鐘後再試');
    });

    test('1 小時以上：顯示小時', () {
      expect(friendlyErrorMessage(_tooMany(retryAfter: 3600)), '操作太頻繁了，請約 1 小時後再試');
    });

    test('只有 HTTP 429、沒有 error.code 也算次數限制', () {
      final e = ApiException(statusCode: 429, message: 'x', retryAfterSeconds: 120);
      expect(friendlyErrorMessage(e), '操作太頻繁了，請約 2 分鐘後再試');
    });

    test('其他 ApiException 維持顯示後端訊息', () {
      final e = ApiException(statusCode: 404, code: 'ACCOUNT_NOT_FOUND', message: '找不到帳號');
      expect(friendlyErrorMessage(e), '找不到帳號');
    });
  });
}
