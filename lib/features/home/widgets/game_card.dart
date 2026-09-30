import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../../../screens/game_home_screen.dart';

class Game {
  final String id;
  final String title;

  Game({
    required this.id,
    required this.title,
  });
}

class GameCard extends StatefulWidget {
  final Game game;

  const GameCard({super.key, required this.game});

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GameHomeScreen()),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
            child: Row(
              children: [
                Icon(Icons.storefront, color: iconColor, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.game.title,
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
          ),
        );
      },
    );
  }
}