import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../theme/app_theme.dart';

class TrainingProgressCard extends StatelessWidget {
  final int completedCount; // 已完成幾個訓練，例如 1
  final int totalCount; // 今日總共要完成幾個，例如 3

  const TrainingProgressCard({
    super.key,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalCount == 0 ? 0 : completedCount / totalCount;
    final int percentage = (progress * 100).round();

    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final isDark = AppSettings.isDarkMode.value;
        final isHighContrast = AppSettings.isHighContrast.value;

        final cardColor = isDark
            ? const Color(0xFF25382E)
            : const Color(0xFFDCE8DC);
        final titleColor = isHighContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? const Color(0xFFB8E6D0) : const Color(0xFF3D6B4A));
        final percentColor = isHighContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? const Color(0xFF4CAF50) : const Color(0xFF4A7C5C));
        // 深色卡片上主色太暗看不清楚，進度條改用較亮的綠
        final barColor = isDark
            ? const Color(0xFF4CAF50)
            : AppTheme.primaryColor;
        final trackColor = isDark ? const Color(0xFF121212) : Colors.white;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: isHighContrast
                ? Border.all(
                    color: isDark ? Colors.white : Colors.black,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 字放大時這行可能太長，用 Expanded 讓它自動換行，不會擠出畫面
                  Expanded(
                    child: Text(
                      '今日已完成：$completedCount/$totalCount 個訓練',
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(16),
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(16),
                      fontWeight: FontWeight.bold,
                      color: percentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: trackColor,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
