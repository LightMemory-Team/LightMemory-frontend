import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../models/cognitive_domain_model.dart';

class DomainCard extends StatefulWidget {
  final CognitiveDomain domain;
  final VoidCallback onTap;

  const DomainCard({super.key, required this.domain, required this.onTap});

  @override
  State<DomainCard> createState() => _DomainCardState();
}

class _DomainCardState extends State<DomainCard> {
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

        // 配色跟首頁的遊戲卡片（game_card.dart）一致
        final cardColor = isDark
            ? (_isPressed ? const Color(0xFF32503F) : const Color(0xFF25382E))
            : (_isPressed
                  ? const Color(0xFFC3D8C5) // 按下去的深色
                  : const Color(0xFFDCE8DC)); // 原本的淺色
        final iconColor = isHighContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? const Color(0xFF4CAF50) : const Color(0xFF4A7C5C));
        final textColor = isHighContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? const Color(0xFFB8E6D0) : const Color(0xFF3D6B4A));

        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              // 高對比模式加外框，讓卡片邊界更明顯
              border: isHighContrast
                  ? Border.all(
                      color: isDark ? Colors.white : Colors.black,
                      width: 2,
                    )
                  : null,
            ),
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.domain.icon, color: iconColor, size: 36),
                    const SizedBox(height: 10),
                    // 字放大時卡片高度不變，用 FittedBox 縮回卡片寬度內，避免溢出
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.domain.title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: AppSettings.scaleFont(18),
                          fontWeight: isHighContrast
                              ? FontWeight.w900
                              : FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.domain.isRecommended)
                  Positioned(
                    top: -12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A623),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '今日推薦',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppSettings.scaleFont(11),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
