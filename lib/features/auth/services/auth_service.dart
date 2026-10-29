import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/auth_headers.dart';
import '../../../core/services/token_storage.dart';

class AuthService {
  static const String _registerUrl = '${ApiConstants.serverUrl}/api/users/register/';
  static const String _loginUrl = '${ApiConstants.serverUrl}/api/users/login/';
  static const String _meUrl = '${ApiConstants.serverUrl}/api/users/me/';

  static const Duration _timeout = Duration(seconds: 15);

  // ============================================================
  // 共用：把失敗的回應轉成 ApiException
  //
  // 依小惠的〈首頁改版 API 規格書〉，錯誤格式是：
  // {"error": {"code": "...", "message": "...", "fields": {"欄位": ["訊息"]}}}
  // fields 放進 ApiException.details，畫面可以把訊息顯示在對應欄位下方。
  // 也相容 Django 預設格式 {"username": ["..."]}（後端還沒改好之前）。
  // ============================================================

  static ApiException _toApiException(http.Response response, String fallback) {
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      json = null;
    }

    if (json != null) {
      final error = json['error'];

      // 規格書的統一錯誤格式
      if (error is Map<String, dynamic>) {
        return ApiException(
          statusCode: response.statusCode,
          code: error['code'] as String?,
          message: (error['message'] as String?) ?? fallback,
          details: error['fields'],
        );
      }

      // Django 預設格式：{"欄位": ["訊息"]}
      if (response.statusCode == 400) {
        final fields = <String, dynamic>{};
        json.forEach((key, value) {
          if (value is List) fields[key] = value;
        });
        if (fields.isNotEmpty) {
          final bool usernameTaken = fields.containsKey('username');
          return ApiException(
            statusCode: 400,
            code: usernameTaken ? 'USERNAME_TAKEN' : 'VALIDATION_ERROR',
            message: usernameTaken ? '這個帳號已經有人使用，請換一個帳號' : fallback,
            details: fields,
          );
        }
      }
    }

    return ApiException(statusCode: response.statusCode, message: fallback);
  }

  // ============================================================
  // 註冊：只送必填欄位（選填的地區、緊急聯絡人之後用 updateMe 送）
  // ============================================================

  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String nickname,
    required String birthDate,
    required String gender,
  }) async {
    final response = await http
        .post(
          Uri.parse(_registerUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'password': password,
            'nickname': nickname,
            'birth_date': birthDate,
            'gender': gender,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    // 原始回應只印在終端機，畫面上顯示看得懂的中文
    debugPrint('註冊 - 狀態碼: ${response.statusCode}');
    debugPrint('註冊 - 回應內容: ${utf8.decode(response.bodyBytes)}');

    final error = _toApiException(response, '註冊失敗，請確認資料後再試一次');
    if (error.code == 'USERNAME_TAKEN') {
      throw ApiException(
        statusCode: error.statusCode,
        code: error.code,
        message: '這個帳號已經有人使用，請換一個帳號',
        details: error.details,
      );
    }
    throw error;
  }

  // ============================================================
  // 修改自己的資料（PATCH /api/users/me/）
  // 只送有要改的欄位，沒送的不會被改掉。需要登入。
  // ============================================================

  static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> fields) async {
    final response = await http
        .patch(
          Uri.parse(_meUrl),
          headers: await authHeaders(),
          body: jsonEncode(fields),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        // 相容有沒有包 {"data": ...} 兩種回傳
        final data = decoded['data'];
        return data is Map<String, dynamic> ? data : decoded;
      }
      return {};
    }

    debugPrint('修改資料 - 狀態碼: ${response.statusCode}');
    debugPrint('修改資料 - 回應內容: ${utf8.decode(response.bodyBytes)}');
    throw _toApiException(response, '資料儲存失敗，請稍後再試一次');
  }

  // ============================================================
  // 登入（沒有改）
  // ============================================================

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(_loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // 裡面會有 access、refresh
    }
    debugPrint('登入 - 狀態碼: ${response.statusCode}');
    debugPrint('登入 - 回應內容: ${response.body}');
    if (response.statusCode == 401) {
      throw Exception('帳號或密碼錯誤，請再確認一次');
    }
    throw Exception('登入失敗，請稍後再試一次');
  }

  /// 登入並把 access token 存起來。
  /// 登入頁、註冊成功後都呼叫這一支，存 token 的寫法只有這一份。
  static Future<void> loginAndSaveToken({
    required String username,
    required String password,
  }) async {
    final result = await login(username: username, password: password);
    final accessToken = result['access'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('登入失敗，請稍後再試一次');
    }
    await TokenStorage.saveAccessToken(accessToken);
  }
}