import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../../../theme/app_theme.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  /// 按讚/取消讚，卡片只負責通知外部「使用者按了讚」，
  /// 目前是讚還是沒讚由外部依 post.isLiked 決定要呼叫哪一支
  final VoidCallback onLikeTap;
  /// 點擊語音回覆入口（展開列表或開始錄音，由外部決定）
  final VoidCallback onVoiceReplyTap;
  /// 送出文字留言，卡片把輸入框裡的文字往外傳，自己不呼叫 API
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 照片
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.network(post.photoUrl, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題
                Text(
                  post.title,
                  style: TextStyle(
                    fontSize: AppTheme.fontTitle - 4,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                // 貼文內容
                Text(
                  post.postText,
                  style: TextStyle(
                    fontSize: AppTheme.fontBody,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                // hashtag
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
                            color: colorScheme.secondaryContainer,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: AppTheme.fontCaption,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                // 讚 / 語音回覆 操作列
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onLikeTap,
                      child: Row(
                        children: [
                          Icon(
                            post.isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: post.isLiked
                                ? Colors.redAccent
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likeCount}',
                            style: TextStyle(
                              fontSize: AppTheme.fontCaption,
                              color: colorScheme.onSurfaceVariant,
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
                          Icon(
                            Icons.mic,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.voiceReplyCount}',
                            style: TextStyle(
                              fontSize: AppTheme.fontCaption,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 文字留言輸入框
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '留言鼓勵一下...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusPill),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _handleSubmitComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _handleSubmitComment,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryColor,
                        child: const Icon(
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
  }
}