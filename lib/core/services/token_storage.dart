import 'package:shared_preferences/shared_preferences.dart';

/// 集中管理登入後的JWT token存取，之後任何需要帶Authorization的API呼叫
/// 都從這裡讀，不要各自散落在不同檔案裡各自存取SharedPreferences
class TokenStorage {
  static const _accessTokenKey = 'access_token';

  static Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
  }
}