import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../theme/app_theme.dart';

class GameBottomActions extends StatelessWidget {
  final VoidCallback onDailyTaskTap;
  final VoidCallback onAchievementTap;

  const GameBottomActions({
    super.key,
    required this.onDailyTaskTap,
    required this.onAchievementTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final isDark = AppSettings.isDarkMode.value;
        final isHighContrast = AppSettings.isHighContrast.value;
        final fontSize = AppSettings.scaleFont(15);

        // 「我的成就」是外框按鈕：深色模式底色改深灰，框線和字改亮綠
        final outlineBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final outlineColor = isHighContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? const Color(0xFF4CAF50) : AppTheme.primaryColor);

        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onDailyTaskTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(30),
                    border: isHighContrast
                        ? Border.all(
                            color: isDark ? Colors.white : Colors.black,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '每日任務',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onAchievementTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: outlineBg,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: outlineColor,
                      width: isHighContrast ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: outlineColor, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '我的成就',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: outlineColor,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
