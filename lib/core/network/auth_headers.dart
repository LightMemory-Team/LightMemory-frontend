import '../services/token_storage.dart';

/// 手機裡沒有登入 token（沒登入，或 token 被清掉）時丟出的例外。
/// 這種情況不送請求到後端，直接請使用者重新登入。
class NotLoggedInException implements Exception {
  final String message;

  const NotLoggedInException([this.message = '尚未登入，請重新登入']);

  @override
  String toString() => message;
}

/// 所有需要登入的 API 共用的 Headers，新功能請一律用這個，不要自己讀 token。
///
/// - 統一從 TokenStorage 讀登入時存的 token（key 是 access_token）
/// - 沒有 token 時丟出 [NotLoggedInException]
/// - [json] 預設會帶 `Content-Type: application/json`；
///   上傳檔案（MultipartRequest）這類不是送 JSON 的請求請傳 `json: false`
Future<Map<String, String>> authHeaders({bool json = true}) async {
  final token = await TokenStorage.getAccessToken();
  if (token == null || token.isEmpty) {
    throw const NotLoggedInException();
  }
  return {
    if (json) 'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };
}
