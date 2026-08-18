import 'package:flutter/material.dart';
import '../models/home_data.dart';

class DynamicWallSection extends StatelessWidget {
  final List<WallPost> posts;
  final VoidCallback? onSeeMoreTap;

  const DynamicWallSection({super.key, required this.posts, this.onSeeMoreTap});

  @override
  Widget build(BuildContext context) {
    final safeTextScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題列：統一採用高對比深綠色 #2E6342
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '動態牆',
              textScaler: safeTextScaler,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            GestureDetector(
              onTap: onSeeMoreTap,
              child: Text(
                '更多動態',
                textScaler: safeTextScaler,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2E6342), // 統一顏色：高對比深綠色
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 貼文列表
        if (posts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                '目前尚無動態',
                style: TextStyle(color: Color(0xFF595959), fontSize: 14),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPostCard(context, post, safeTextScaler);
            },
          ),
      ],
    );
  }

  Widget _buildPostCard(
    BuildContext context,
    WallPost post,
    TextScaler textScaler,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 作者資訊與發布時間
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEDE7F6),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF673AB7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  post.authorName,
                  textScaler: textScaler,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
              ),
              Text(
                post.timeAgo,
                textScaler: textScaler,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF595959),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 貼文內文（使用組員 A 定義的 contentText）
          Text(
            post.contentText,
            textScaler: textScaler,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Color(0xFF2B2B2B),
            ),
          ),
          const SizedBox(height: 14),

          // 分隔線
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 10),

          // 互動區：愛心與留言
          Row(
            children: [
              const Icon(
                Icons.favorite_border_rounded,
                size: 18,
                color: Color(0xFF595959),
              ),
              const SizedBox(width: 4),
              Text(
                '${post.likeCount}',
                textScaler: textScaler,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF595959),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 17,
                color: Color(0xFF595959),
              ),
              const SizedBox(width: 4),
              Text(
                '${post.commentCount}',
                textScaler: textScaler,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF595959),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
