import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../../../theme/app_theme.dart';
import '../../../app_settings.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback onLikeTap;
  final VoidCallback onVoiceReplyTap;
  final void Function(String text) onSubmitComment;

  const PostCard({
    super.key,
    required this.post,
    required this.onLikeTap,
    required this.onVoiceReplyTap,
    required this.onSubmitComment,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    widget.onSubmitComment(text);
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final colorScheme = AppTheme.colorScheme;

    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.fontSizeLevel,
        AppSettings.isDarkMode,
        AppSettings.isHighContrast,
      ]),
      builder: (context, _) {
        final isDark = AppSettings.isDarkMode.value;
        final isHighContrast = AppSettings.isHighContrast.value;

        final cardBg = isDark ? const Color(0xFF1E1E1E) : AppTheme.cardColor;
        final titleColor = isDark
            ? Colors.white
            : (isHighContrast ? Colors.black : colorScheme.onSurface);
        final bodyColor = isDark
            ? const Color(0xFFCCCCCC)
            : colorScheme.onSurfaceVariant;
        final chipBg = isDark
            ? const Color(0xFF25382E)
            : colorScheme.secondaryContainer;
        final chipText = isDark
            ? const Color(0xFFB8E6D0)
            : colorScheme.onSecondaryContainer;
        final inputFill = isDark
            ? const Color(0xFF2A2A2A)
            : colorScheme.surfaceContainerHighest;
        final inputTextColor = isDark ? Colors.white : Colors.black87;
        final hintColor = isDark ? const Color(0xFF999999) : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(post.photoUrl, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(
                          AppTheme.fontTitle - 4,
                        ),
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.postText,
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(AppTheme.fontBody),
                        color: bodyColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: post.hashtags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: chipBg,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusPill,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: AppSettings.scaleFont(
                                    AppTheme.fontCaption,
                                  ),
                                  color: chipText,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onLikeTap,
                          child: Row(
                            children: [
                              Icon(
                                post.isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: post.isLiked
                                    ? Colors.redAccent
                                    : bodyColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.likeCount}',
                                style: TextStyle(
                                  fontSize: AppSettings.scaleFont(
                                    AppTheme.fontCaption,
                                  ),
                                  color: bodyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: widget.onVoiceReplyTap,
                          child: Row(
                            children: [
                              Icon(Icons.mic, size: 20, color: bodyColor),
                              const SizedBox(width: 4),
                              Text(
                                '${post.voiceReplyCount}',
                                style: TextStyle(
                                  fontSize: AppSettings.scaleFont(
                                    AppTheme.fontCaption,
                                  ),
                                  color: bodyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: TextStyle(
                              fontSize: AppSettings.scaleFont(14),
                              color: inputTextColor,
                            ),
                            decoration: InputDecoration(
                              hintText: '留言鼓勵一下...',
                              hintStyle: hintColor == null
                                  ? null
                                  : TextStyle(color: hintColor),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: inputFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusPill,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _handleSubmitComment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _handleSubmitComment,
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryColor,
                            child: Icon(
                              Icons.send,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}