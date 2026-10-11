import 'package:flutter/material.dart';
import '../../../app_settings.dart';

class DailySuggestion {
  final String text;
  final String actionRoute;

  DailySuggestion({
    required this.text,
    required this.actionRoute,
  });
}

class DailySuggestionCard extends StatefulWidget {
  final DailySuggestion suggestion;

  const DailySuggestionCard({super.key, required this.suggestion});

  @override
  State<DailySuggestionCard> createState() => _DailySuggestionCardState();
}

class _DailySuggestionCardState extends State<DailySuggestionCard> {
  bool _isPressed = false;

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

        // 深色配色沿用聲影日記的淺綠底容器深色版（0xFF25382E / 0xFFB8E6D0）
        final cardColor = isDark
            ? (_isPressed ? const Color(0xFF32503F) : const Color(0xFF25382E))
            : (_isPressed ? const Color(0xFFC3D8C5) : const Color(0xFFDCE8DC));
        final iconBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final iconColor = isDark ? const Color(0xFF4CAF50) : Colors.green;
        final titleColor = isHighContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? const Color(0xFFB8E6D0) : const Color(0xFF2E7D4F));
        final bodyColor = isHighContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF1E1E1E));
        final chevronColor = isHighContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? Colors.white70 : Colors.black54);

        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            // TODO: 導頁
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(30),
              // 高對比模式加外框，讓卡片邊界更明顯
              border: isHighContrast
                  ? Border.all(
                      color: isDark ? Colors.white : Colors.black,
                      width: 2,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '每日建議',
                        style: TextStyle(
                          fontWeight: isHighContrast
                              ? FontWeight.w900
                              : FontWeight.bold,
                          fontSize: AppSettings.scaleFont(14),
                          color: titleColor,
                        ),
                      ),
                      Text(
                        widget.suggestion.text,
                        style: TextStyle(
                          fontSize: AppSettings.scaleFont(13),
                          fontWeight: isHighContrast
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: chevronColor),
              ],
            ),
          ),
        );
      },
    );
  }
}