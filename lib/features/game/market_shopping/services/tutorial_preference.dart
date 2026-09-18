import 'package:shared_preferences/shared_preferences.dart';

class TutorialPreference {
  static const String _key = 'market_shopping_tutorial_seen';

  /// 檢查使用者是否已經看過教學
  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  /// 標記使用者已經看過教學
  static Future<void> markTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}