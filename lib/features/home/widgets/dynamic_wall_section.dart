import 'package:flutter/material.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '動態牆',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: onSeeMoreTap,
              child: const Text(
                '更多動態',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        posts.isEmpty ? const _EmptyWallHint() : _WallPostCard(post: posts.first),
      ],
    );
  }
}

class _EmptyWallHint extends StatelessWidget {
  const _EmptyWallHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '還沒有動態，去聲影日記留下第一篇紀錄吧！',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54, fontSize: 14),
      ),
    );
  }
}

class _WallPostCard extends StatelessWidget {
  final WallPost post;
  const _WallPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    post.avatarUrl != null ? NetworkImage(post.avatarUrl!) : null,
                child: post.avatarUrl == null ? const Icon(Icons.person, size: 18) : null,
              ),
              const SizedBox(width: 8),
              Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(post.timeAgo, style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.contentText, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.favorite_border, size: 16, color: Colors.black45),
              const SizedBox(width: 4),
              Text('${post.likeCount}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.black45),
              const SizedBox(width: 4),
              Text('${post.commentCount}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ),
        ],
      ),
    );
  }
}