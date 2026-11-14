import 'dart:async';
import 'package:http/http.dart' as http;
import 'api_response.dart';
import 'auth_headers.dart';

/// 把例外轉成長輩看得懂的中文提示，畫面上一律用這個，不要直接顯示 `$e`。
///
/// - 連不上後端（`ClientException`，例如「Failed to fetch」）、逾時：
///   統一顯示「連線失敗」，不把後端網址、英文錯誤露給使用者看
/// - 沒有 token（`NotLoggedInException`）、後端統一格式的錯誤（`ApiException`）：
///   顯示裡面的中文訊息
/// - 各 service 自己丟的 `Exception('中文訊息')`：去掉前面的「Exception: 」
/// - 其他沒預期到的錯誤：顯示 [fallback]
///
/// 原始錯誤請另外用 `debugPrint` 印在終端機，方便除錯。
String friendlyErrorMessage(
  Object error, {
  String fallback = '發生錯誤，請稍後再試一次',
}) {
  if (error is NotLoggedInException) return error.message;
  if (error is http.ClientException || error is TimeoutException) {
    return '連線失敗，請檢查網路後再試一次';
  }
  if (error is ApiException) {
    // 次數限制：有 Retry-After 就告訴長輩大約要等多久，沒有就用後端的訊息
    if (error.isTooManyRequests && error.retryAfterSeconds != null) {
      return '操作太頻繁了，請約 ${_waitText(error.retryAfterSeconds!)}後再試';
    }
    return error.message;
  }

  const prefix = 'Exception: ';
  final text = error.toString();
  if (error is Exception && text.startsWith(prefix)) {
    final message = text.substring(prefix.length).trim();
    if (message.isNotEmpty) return message;
  }
  return fallback;
}

/// 登入頁專用的錯誤提示。
///
/// 後端的登入次數限制（HTTP 429）被鎖住時，**即使密碼正確也不能登入**，
/// 要明確告訴使用者，避免長輩以為是密碼不對而一直重試。
/// 其他錯誤跟 [friendlyErrorMessage] 一樣。
String friendlyLoginErrorMessage(Object error) {
  if (error is ApiException && error.isTooManyRequests) {
    final seconds = error.retryAfterSeconds;
    final wait = seconds == null ? '稍後' : '約 ${_waitText(seconds)}後';
    return '登入次數太多了，請$wait再試。這段時間即使密碼正確也無法登入';
  }
  return friendlyErrorMessage(error, fallback: '登入失敗，請稍後再試一次');
}

/// 把秒數轉成「N 秒／N 分鐘／N 小時」，一律無條件進位，避免讓使用者提早重試又被擋。
String _waitText(int seconds) {
  if (seconds <= 60) return '${seconds <= 0 ? 1 : seconds} 秒';
  final minutes = (seconds / 60).ceil();
  if (minutes < 60) return '$minutes 分鐘';
  return '${(minutes / 60).ceil()} 小時';
}
