import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../dashboard/models/dashboard_models.dart';
import '../../dashboard/widgets/robot_avatar.dart';

/// 首頁招呼區（依首頁改版設計）
///
/// 10 月 27 日　星期二
/// 早安，玉蘭！                    🌱 120 點
/// 🤖 今天也要保持大腦活力呦
class GreetingSection extends StatelessWidget {
  /// 暱稱（來自 GET /api/home/user/ 的 user_name）
  final String userName;

  /// 鼓勵語（機器人旁邊那句話）
  final String dailyTip;

  /// 點數：點數系統下一個 issue 才做，這次先放假資料
  final int points;

  const GreetingSection({
    super.key,
    required this.userName,
    required this.dailyTip,
    this.points = 120,
  });

  static const List<String> _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  /// 依時間換招呼語：05:00～10:59 早安、11:00～17:59 午安、其他 晚安
  String _greetingWord(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 11) return '早安';
    if (hour >= 11 && hour < 18) return '午安';
    return '晚安';
  }

  /// 10 月 27 日　星期二
  String _dateText(DateTime now) {
    return '${now.month} 月 ${now.day} 日　星期${_weekdays[now.weekday - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.isDarkMode,
        AppSettings.fontSizeLevel,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final isDark = AppSettings.isDarkMode.value;
        final isHighContrast = AppSettings.isHighContrast.value;

        final titleColor = isDark
            ? Colors.white
            : (isHighContrast ? Colors.black : const Color(0xFF1E1E1E));
        final subtitleColor = isDark
            ? const Color(0xFFCCCCCC)
            : (isHighContrast ? const Color(0xFF333333) : const Color(0xFF595959));
        final tipColor = isDark
            ? const Color(0xFF4CAF50)
            : (isHighContrast ? Colors.black : const Color(0xFF2E6342));
        final robotBg = isDark ? const Color(0xFF25382E) : const Color(0xFFDCEBF2);

        final now = DateTime.now();
        final name = userName.trim();
        final greeting = name.isEmpty
            ? '${_greetingWord(now)}！'
            : '${_greetingWord(now)}，$name！';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期
            Text(
              _dateText(now),
              style: TextStyle(
                fontSize: AppSettings.scaleFont(14),
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 4),

            // 招呼語＋點數
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    greeting,
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(26),
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _PointsBadge(points: points, isDark: isDark, isHighContrast: isHighContrast),
              ],
            ),
            const SizedBox(height: 12),

            // 機器人＋鼓勵語
            if (dailyTip.trim().isNotEmpty)
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: robotBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const RobotAvatar(mood: DashboardMood.good, size: 40),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dailyTip,
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(17),
                        fontWeight: FontWeight.bold,
                        color: tipColor,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

/// 右上角的點數小標籤「🌱 120 點」
class _PointsBadge extends StatelessWidget {
  final int points;
  final bool isDark;
  final bool isHighContrast;

  const _PointsBadge({
    required this.points,
    required this.isDark,
    required this.isHighContrast,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF3A2C1A) : const Color(0xFFFDEBD3);
    final fg = isDark
        ? const Color(0xFFF5C68A)
        : (isHighContrast ? Colors.black : const Color(0xFF8A4B0F));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: isHighContrast ? Border.all(color: fg, width: 1.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_outlined, size: 18, color: fg),
          const SizedBox(width: 4),
          Text(
            '$points 點',
            style: TextStyle(
              fontSize: AppSettings.scaleFont(15),
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}