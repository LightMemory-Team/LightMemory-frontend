import 'package:flutter/material.dart';
import '../../../app_settings.dart';
import '../models/home_data.dart';

class DynamicWallSection extends StatelessWidget {
  final List<WallPost> posts;
  final VoidCallback onSeeMoreTap;

  const DynamicWallSection({
    super.key,
    required this.posts,
    required this.onSeeMoreTap,
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
        final themeGreen = isDark
            ? const Color(0xFF4CAF50)
            : const Color(0xFF2E6342);
        final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final cardBorder = isDark
            ? const Color(0xFF333333)
            : const Color(0xFFE8ECE9);
        final postTextColor = isDark
            ? const Color(0xFFE0E0E0)
            : const Color(0xFF1E1E1E);
        final subTextColor = isDark
            ? const Color(0xFF9E9E9E)
            : const Color(0xFF757575);

        return Column(
          children: [
            // 標題列
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '動態牆',
                  style: TextStyle(
                    fontSize: AppSettings.scaleFont(18),
                    fontWeight: isHighContrast
                        ? FontWeight.w900
                        : FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                GestureDetector(
                  onTap: onSeeMoreTap,
                  child: Text(
                    '更多動態',
                    style: TextStyle(
                      fontSize: AppSettings.scaleFont(14),
                      color: themeGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 動態貼文卡片
            if (posts.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cardBorder,
                    width: isHighContrast ? 2.0 : 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 作者與發文時間
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(
                            0xFF7E57C2,
                          ).withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF7E57C2),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          posts.first.authorName,
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(15),
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          posts.first.timeAgo,
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(12),
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 內文文字
                    Text(
                      posts.first.contentText,
                      style: TextStyle(
                        fontSize: AppSettings.scaleFont(14),
                        color: postTextColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: cardBorder),
                    const SizedBox(height: 10),

                    // 按讚與留言數
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 18,
                          color: subTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${posts.first.likeCount}',
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(13),
                            color: subTextColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: subTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${posts.first.commentCount}',
                          style: TextStyle(
                            fontSize: AppSettings.scaleFont(13),
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
