import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/services/token_storage.dart';

class AuthService {
  static const String _registerUrl = '${ApiConstants.serverUrl}/api/users/register/';
  static const String _loginUrl = '${ApiConstants.serverUrl}/api/users/login/';  
  
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String birthDate,
    required String gender,
    String? phone,
    String? address,
    String? firstName,
    String? lastName,
    String? region,
  }) async {
    final response = await http.post(
      Uri.parse(_registerUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'birth_date': birthDate,
        'gender': gender,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (region != null) 'region': region,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    // 原始回應只印在終端機，畫面上顯示看得懂的中文
    debugPrint('註冊 - 狀態碼: ${response.statusCode}');
    debugPrint('註冊 - 回應內容: ${response.body}');
    // Django 帳號重複時回 400，內容像 {"username": ["A user with that username already exists."]}
    if (response.statusCode == 400 && response.body.contains('username')) {
      throw Exception('這個帳號已經有人使用，請換一個帳號');
    }
    throw Exception('註冊失敗，請確認資料後再試一次');
  }

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