import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../../../theme/app_theme.dart';
import '../../../app_settings.dart';

/// 動態牆貼文卡片（計劃書版）
///
/// 顯示作者、照片、標題、內文、hashtag、按讚數、留言數。
/// 點卡片或留言圖示 → 進入貼文詳情頁（由外層傳入 onTap）。
class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLikeTap;
  final VoidCallback? onTap;

  /// 詳情頁顯示完整內文；列表頁最多顯示 3 行
  final bool showFullText;

  const PostCard({
    super.key,
    required this.post,
    required this.onLikeTap,
    this.onTap,
    this.showFullText = false,
  });

  /// 把 2026-10-11 轉成 10/11 顯示
  String _formatDate(String date) {
    final DateTime? parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return '${parsed.month}/${parsed.day}';
  }

  @override
  Widget build(BuildContext context) {
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
        final accentGreen = isDark
            ? const Color(0xFF4CAF50)
            : AppTheme.primaryColor;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: isHighContrast
                  ? Border.all(
                      color: isDark ? Colors.white : Colors.black,
                      width: 2,
                    )
                  : null,
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
                // ==================================================
                // 作者列：頭貼、名字、日期
                // ==================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Row(
                    children: [
                      _buildAvatar(accentGreen),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    post.author.displayName.isEmpty
                                        ? '使用者'
                                        : post.author.displayName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: AppSettings.scaleFont(
                                        AppTheme.fontBody,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: titleColor,
                                    ),
                                  ),
                                ),
                                if (post.isMine) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: chipBg,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusPill,
                                      ),
                                    ),
                                    child: Text(
                                      '我的',
                                      style: TextStyle(
                                        fontSize: AppSettings.scaleFont(
                                          AppTheme.fontCaption - 2,
                                        ),
                                        color: chipText,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              _formatDate(post.date),
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
                ),

                // ==================================================
                // 照片
                // ==================================================
                if (post.photoUrl.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      post.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: chipBg,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: chipText,
                          ),
                        );
                      },
                    ),
                  ),

                // ==================================================
                // 標題、內文、hashtag
                // ==================================================
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
                        maxLines: showFullText ? null : 3,
                        overflow: showFullText ? null : TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppSettings.scaleFont(AppTheme.fontBody),
                          color: bodyColor,
                          height: 1.5,
                        ),
                      ),
                      if (post.hashtags.isNotEmpty) ...[
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
                      ],
                      const SizedBox(height: 12),

                      // ==============================================
                      // 按讚、留言數
                      // ==============================================
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onLikeTap,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    post.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 24,
                                    color: post.isLiked
                                        ? Colors.redAccent
                                        : bodyColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.likeCount}',
                                    style: TextStyle(
                                      fontSize: AppSettings.scaleFont(
                                        AppTheme.fontBody,
                                      ),
                                      color: bodyColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: onTap,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 22,
                                    color: bodyColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post.commentCount}',
                                    style: TextStyle(
                                      fontSize: AppSettings.scaleFont(
                                        AppTheme.fontBody,
                                      ),
                                      color: bodyColor,
                                    ),
                                  ),
                                ],
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
          ),
        );
      },
    );
  }

  /// 有頭貼網址就顯示圖片，沒有就顯示名字第一個字
  Widget _buildAvatar(Color accentGreen) {
    final String name = post.author.displayName;
    final String initial = name.isEmpty ? '?' : name.characters.first;
    final String? avatarUrl = post.author.avatarUrl;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: accentGreen,
        backgroundImage: NetworkImage(avatarUrl),
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: accentGreen,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: AppSettings.scaleFont(16),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}