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
  if (error is ApiException) return error.message;

  const prefix = 'Exception: ';
  final text = error.toString();
  if (error is Exception && text.startsWith(prefix)) {
    final message = text.substring(prefix.length).trim();
    if (message.isNotEmpty) return message;
  }
  return fallback;
}
