class WallPost {
  final String authorName;
  final String? avatarUrl;
  final String timeAgo;
  final String contentText;
  final int likeCount;
  final int commentCount;

  WallPost({
    required this.authorName,
    this.avatarUrl,
    required this.timeAgo,
    required this.contentText,
    required this.likeCount,
    required this.commentCount,
  });
}

class HomeData {
  final String userName;
  final String dailyTip;
  final int unreadNotificationCount;
  final List<WallPost> wallPosts;

  HomeData({
    required this.userName,
    required this.dailyTip,
    required this.unreadNotificationCount,
    required this.wallPosts,
  });
}

final mockHomeData = HomeData(
  userName: '玉蘭',
  dailyTip: '今天也要保持大腦活力喔。',
  unreadNotificationCount: 3,
  wallPosts: [
    WallPost(
      authorName: '我',
      avatarUrl: null,
      timeAgo: '昨天',
      contentText: '昨天練習了書法，感覺心神寧靜，真是有趣的一天！',
      likeCount: 24,
      commentCount: 5,
    ),
  ],
);
