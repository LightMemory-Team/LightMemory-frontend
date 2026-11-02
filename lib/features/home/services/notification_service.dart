import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/auth_headers.dart';
import '../models/notification_model.dart';

/// 通知服務（後端網址是 /api/social/notifications/，不是 /api/notifications/）
///
/// 回傳格式統一成 {success, data, error}；找不到通知時 404、error.code 是 NOTIFICATION_NOT_FOUND。
/// - getNotifications()：GET   /api/social/notifications/  通知列表（data.notifications）
/// - markAllRead()：     PATCH /api/social/notifications/             全部標記已讀（只標自己的未讀；後端不看 body）
/// - markRead(id)：      PATCH /api/social/notifications/{id}/read/   單筆標記已讀
class NotificationService {
  static const Duration _timeout = Duration(seconds: 15);

  Uri get _uri =>
      Uri.parse('${ApiConstants.serverUrl}/api/social/notifications/');

  /// 成功回傳解析後的 JSON（Map 或 List），失敗丟出 ApiException
  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    debugPrint(
      '❌ 通知 API 失敗（${response.statusCode}）：${utf8.decode(response.bodyBytes)}',
    );
    throw decoded is Map<String, dynamic>
        ? parseApiError(decoded, response.statusCode)
        : ApiException(
            statusCode: response.statusCode,
            message: '發生錯誤（${response.statusCode}）',
          );
  }

  Future<List<AppNotification>> getNotifications() async {
    final response = await http
        .get(_uri, headers: await authHeaders())
        .timeout(_timeout);
    final decoded = _handleResponse(response);

    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    final list = data is Map<String, dynamic> ? data['notifications'] : null;
    if (list is! List) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  Future<void> markAllRead() async {
    final response = await http
        .patch(
          _uri,
          headers: await authHeaders(),
          body: jsonEncode({'is_read': true}),
        )
        .timeout(_timeout);
    _handleResponse(response);
  }

  Future<void> markRead(int id) async {
    final uri = Uri.parse('${ApiConstants.serverUrl}/api/social/notifications/$id/read/');
    final response = await http.patch(uri, headers: await authHeaders()).timeout(_timeout);
    _handleResponse(response);
  }
}
