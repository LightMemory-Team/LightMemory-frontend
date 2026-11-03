import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../models/home_models.dart';

/// 首頁「大腦訓練遊戲」卡片（依首頁改版設計：兩張並排的方形卡片）
///
/// ┌──────────────┐
/// │ 🧺   本週還沒玩 │  ← 左上圖示；本週沒玩過右上角顯示橘色標籤
/// │              │
/// │ 整理菜籃      │  ← 左下遊戲名稱
/// └──────────────┘
class GameCard extends StatefulWidget {
  final HomeGame game;

  /// 點卡片：由首頁決定開哪個遊戲
  final VoidCallback onTap;

  const GameCard({super.key, required this.game, required this.onTap});

  /// 依遊戲代碼給圖示（代碼見小惠規格書）
  static IconData iconFor(String gameId) {
    switch (gameId) {
      case 'market_sort':
        return Icons.shopping_basket_outlined; // 整理菜籃
      case 'fridge_check':
        return Icons.kitchen_outlined; // 冰箱清點
      case 'market_shopping':
        return Icons.shopping_cart_outlined; // 市場買菜
      case 'market_route':
        return Icons.place_outlined; // 來去菜市場
      case 'memory_recall':
        return Icons.soup_kitchen_outlined; // 料理準備
      default:
        return Icons.sports_esports_outlined;
    }
  }

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
            : (_isPressed ? const Color(0xFFC3D8C5) : const Color(0xFFE3EDE5));
        final iconColor = isHighContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E6342));
        final textColor = isHighContrast
            ? (isDark ? Colors.white : Colors.black)
            : (isDark ? const Color(0xFFB8E6D0) : const Color(0xFF1E1E1E));

        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: double.infinity,
            height: 130,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              // 高對比模式加外框，讓卡片邊界更明顯
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
                // 左上圖示＋右上「本週還沒玩」
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(GameCard.iconFor(widget.game.id), color: iconColor, size: 32),
                    const Spacer(),
                    if (!widget.game.playedThisWeek)
                      _NotPlayedBadge(isDark: isDark, isHighContrast: isHighContrast),
                  ],
                ),
                const Spacer(),
                // 左下遊戲名稱
                Text(
                  widget.game.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppSettings.scaleFont(18),
                    fontWeight: isHighContrast ? FontWeight.w900 : FontWeight.bold,
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

/// 右上角的「本週還沒玩」橘色小標籤
class _NotPlayedBadge extends StatelessWidget {
  final bool isDark;
  final bool isHighContrast;

  const _NotPlayedBadge({required this.isDark, required this.isHighContrast});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF3A2C1A) : const Color(0xFFFDEBD3);
    final fg = isDark
        ? const Color(0xFFF5C68A)
        : (isHighContrast ? Colors.black : const Color(0xFF8A4B0F));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: isHighContrast ? Border.all(color: fg, width: 1.2) : null,
      ),
      child: Text(
        '本週還沒玩',
        style: TextStyle(
          fontSize: AppSettings.scaleFont(12),
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}