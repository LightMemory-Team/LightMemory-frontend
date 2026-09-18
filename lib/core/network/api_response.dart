import 'dart:convert';
import 'package:http/http.dart' as http;

/// 對應後端三款遊戲統一後的錯誤格式：
/// {"success": false, "data": null, "error": {"code": "...", "message": "..."}}
///
/// 之後要依 code 分流處理（例如 SESSION_NOT_FOUND 時導回首頁）可以直接讀 [code]，
/// 不用再從字串裡自己解析。[details] 對應 market_sort INVALID_QUESTION_DATA
/// 這種一次列出多筆驗證錯誤的情況，一般錯誤不會有這個欄位。
class ApiException implements Exception {
  final int statusCode;
  final String? code;
  final String message;
  final dynamic details;

  ApiException({
    required this.statusCode,
    this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => message;
}

Map<String, dynamic>? _tryDecode(String body) {
  try {
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

/// 把後端回傳的失敗 body 轉成 [ApiException]，相容幾種不同格式：
/// - 三款遊戲統一後的 `error: {code, message}`（含 details 的驗證錯誤）
/// - market_route 改版前的 `error` 純字串（保留相容，理論上之後不會再出現）
/// - 未登入等狀況的 Django REST Framework 預設格式（例如 `{"detail": "..."}`）
ApiException parseApiError(Map<String, dynamic> json, int statusCode) {
  final error = json['error'];

  if (error is Map<String, dynamic>) {
    final code = error['code'] as String?;
    final message = error['message'] as String?;
    final details = error['details'];
    return ApiException(
      statusCode: statusCode,
      code: code,
      message: message ?? (details != null ? '資料驗證失敗，請確認送出的內容是否正確' : '發生未知錯誤'),
      details: details,
    );
  }

  if (error is String) {
    return ApiException(statusCode: statusCode, message: error);
  }

  final detail = json['detail'];
  if (detail is String) {
    return ApiException(statusCode: statusCode, message: detail);
  }

  return ApiException(statusCode: statusCode, message: '發生錯誤（$statusCode）');
}

/// 解析 `{success, data, error}` 格式的回應：成功時把整包 json 交給 [fromJson]
/// （沿用 market_shopping／market_sort 現有 model 自己從 json['data'] 取值的寫法），
/// 失敗時丟出解析好的 [ApiException]。
T parseEnvelope<T>(
  http.Response response,
  T Function(Map<String, dynamic> json) fromJson,
) {
  final json = _tryDecode(response.body);
  if (json != null && json['success'] == true) {
    return fromJson(json);
  }
  throw json != null
      ? parseApiError(json, response.statusCode)
      : ApiException(
          statusCode: response.statusCode,
          message: '發生錯誤（${response.statusCode}）',
        );
}

/// 跟 [parseEnvelope] 一樣，但只把 `data` 那一層交給呼叫端
/// （對應 go_to_market model 現有的 fromJson(data) 寫法）。
T parseData<T>(
  http.Response response,
  T Function(dynamic data) fromData,
) {
  return parseEnvelope(response, (json) => fromData(json['data']));
}
