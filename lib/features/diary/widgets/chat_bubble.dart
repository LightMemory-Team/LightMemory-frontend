import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String text;
  /// AI 正在生成回應時顯示三顆跳動的點，不顯示 text
  final bool isTyping;
  /// 有值時氣泡旁會出現回放按鈕（通常是使用者已錄好音的那一輪），
  /// 按下時只呼叫這個 callback，實際播放邏輯交給外部處理
  final VoidCallback? onPlayTap;

  const ChatBubble({
    super.key,
    required this.isUser,
    required this.text,
    this.isTyping = false,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = AppTheme.colorScheme;

    final avatar = CircleAvatar(
      radius: AppTheme.sizeAvatar / 2,
      backgroundColor:
          isUser ? colorScheme.secondaryContainer : AppTheme.primaryColor,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: isUser ? colorScheme.onSecondaryContainer : Colors.white,
        size: 20,
      ),
    );

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? AppTheme.primaryColor : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusBubble),
      ),
      child: isTyping
          ? const _TypingDots()
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: AppTheme.fontBody,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: isUser ? Colors.white : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (onPlayTap != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onPlayTap,
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      child: Icon(
                        Icons.play_arrow,
                        size: 16,
                        color: isUser ? Colors.white : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );

    final rowChildren = isUser
        ? [
            Flexible(child: bubble),
            const SizedBox(width: 10),
            avatar,
          ]
        : [
            avatar,
            const SizedBox(width: 10),
            Flexible(child: bubble),
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rowChildren,
      ),
    );
  }
}

/// AI 思考中的三顆跳動點動畫
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              // 三顆點依序延遲跳動，模擬 futureQ typing-bubble 的節奏
              final delay = i * 0.15;
              final t = (_controller.value - delay) % 1.0;
              final scale = t < 0.3 ? 1.0 + (0.3 - t) : 1.0;
              return Opacity(
                opacity: 0.5,
                child: Transform.scale(
                  scale: scale.clamp(1.0, 1.3),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}