class HomeData {
  final String userName;
  final String dailyTip;
  final int unreadNotificationCount;

  HomeData({
    required this.userName,
    required this.dailyTip,
    required this.unreadNotificationCount,
  });
}

final mockHomeData = HomeData(
  userName: '玉蘭',
  dailyTip: '今天也要保持大腦活力喔。',
  unreadNotificationCount: 3,
);
