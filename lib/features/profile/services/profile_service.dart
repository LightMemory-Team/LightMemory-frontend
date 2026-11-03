import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/network/auth_headers.dart';
import '../models/user_profile.dart';

/// 後端驗證沒過（400），[fields] 是各欄位的錯誤訊息，例如
/// `{'birth_date': ['生日不能是未來的日期']}`
class ProfileValidationException implements Exception {
  final String message;
  final Map<String, List<String>> fields;

  const ProfileValidationException(this.message, this.fields);

  @override
  String toString() => message;
}

/// 會員資料的讀取與修改（/api/users/me/）。
///
/// 沒登入或 token 無效（401）時丟出 [NotLoggedInException]，畫面收到後導回登入。
class ProfileService {
  static const String _meUrl = '${ApiConstants.serverUrl}/api/users/me/';
  static const Duration _timeout = Duration(seconds: 15);

  Future<UserProfile> getMe() async {
    final response = await http
        .get(Uri.parse(_meUrl), headers: await authHeaders())
        .timeout(_timeout);
    return UserProfile.fromJson(_parse(response));
  }

  /// 只送有改的欄位；清空的欄位傳 null
  Future<UserProfile> updateMe(Map<String, dynamic> changes) async {
    final response = await http
        .patch(
          Uri.parse(_meUrl),
          headers: await authHeaders(),
          body: jsonEncode(changes),
        )
        .timeout(_timeout);
    return UserProfile.fromJson(_parse(response));
  }

  /// 成功時後端直接回會員資料（沒有 success／data 外層），失敗時才是
  /// `{success: false, error: {...}}`，兩種都接
  Map<String, dynamic> _parse(http.Response response) {
    if (response.statusCode == 401) {
      throw const NotLoggedInException();
    }

    Map<String, dynamic> json;
    try {
      json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('伺服器回應格式錯誤（${response.statusCode}）');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = json['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? '資料暫時無法更新';
      final fields = (error?['fields'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((e) => e.toString()).toList(),
        ),
      );
      if (response.statusCode == 400) {
        throw ProfileValidationException(message, fields);
      }
      throw Exception(message);
    }

    final data = json['data'];
    return data is Map<String, dynamic> ? data : json;
  }
}
