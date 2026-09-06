import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // TODO: 暫時寫死，待後端開會確認後改用 ApiConstants
  static const String _registerUrl = 'https://higher-applying-father-soul.trycloudflare.com/api/users/register/';
  static const String _loginUrl = 'https://higher-applying-father-soul.trycloudflare.com/api/users/login/';

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
    } else {
      print('註冊 - 狀態碼: ${response.statusCode}');
      print('註冊 - 回應內容: ${response.body}');
      throw Exception('註冊失敗（${response.statusCode}）：${response.body}');
    }
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
    } else {
      print('登入 - 狀態碼: ${response.statusCode}');
      print('登入 - 回應內容: ${response.body}');
      throw Exception('登入失敗（${response.statusCode}）：${response.body}');
    }
  }
}