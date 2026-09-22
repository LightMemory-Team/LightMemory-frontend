import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../app_settings.dart';

class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String text;
  final bool isTyping;
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
      ]),
      builder: (context, _) {
        final isDark = AppSettings.isDarkMode.value;
        final colorScheme = AppTheme.colorScheme;

        // 淺綠底容器（使用者頭像底色）的深色版本，跟其他頁面用的暫定色一致
        final userContainerColor = isDark
            ? const Color(0xFF25382E)
            : colorScheme.secondaryContainer;
        final userOnContainerColor = isDark
            ? const Color(0xFFB8E6D0)
            : colorScheme.onSecondaryContainer;
        final aiBubbleBg = isDark
            ? const Color(0xFF2A2A2A)
            : colorScheme.surfaceContainerHighest;
        final aiBubbleText = isDark ? Colors.white : colorScheme.onSurface;
        final typingDotColor = isDark ? Colors.white54 : Colors.black54;

        final avatar = CircleAvatar(
          radius: AppTheme.sizeAvatar / 2,
          backgroundColor: isUser ? userContainerColor : AppTheme.primaryColor,
          child: Icon(
            isUser ? Icons.person : Icons.smart_toy,
            color: isUser ? userOnContainerColor : Colors.white,
            size: 20,
          ),
        );

        final bubble = Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? AppTheme.primaryColor : aiBubbleBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusBubble),
          ),
          child: isTyping
              ? _TypingDots(color: typingDotColor)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: AppSettings.scaleFont(AppTheme.fontBody),
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: isUser ? Colors.white : aiBubbleText,
                        ),
                      ),
                    ),
                    if (onPlayTap != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onPlayTap,
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.white.withValues(
                            alpha: 0.25,
                          ),
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
            ? [Flexible(child: bubble), const SizedBox(width: 10), avatar]
            : [avatar, const SizedBox(width: 10), Flexible(child: bubble)];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ),
        );
      },
    );
  }
}

/// AI 思考中的三顆跳動點動畫
class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

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
                    decoration: BoxDecoration(
                      color: widget.color,
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