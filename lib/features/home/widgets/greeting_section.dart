import 'package:flutter/material.dart';
import '../../../app_settings.dart';

class GreetingSection extends StatelessWidget {
  final String userName;
  final String dailyTip;

  const GreetingSection({
    super.key,
    required this.userName,
    required this.dailyTip,
  });

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
            : (isHighContrast
                  ? const Color(0xFF333333)
                  : const Color(0xFF595959));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '早安，$userName！',
              style: TextStyle(
                fontSize: AppSettings.scaleFont(24),
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dailyTip,
              style: TextStyle(
                fontSize: AppSettings.scaleFont(15),
                color: subtitleColor,
              ),
            ),
          ],
        );
      },
    );
  }
}
