/// 後端 API 網址與 Endpoints 常數表
class ApiConstants {
  // 後端伺服器網址（目前是 Cloudflare Tunnel 臨時網址，後端重開就會換）。
  // 網址一換，只要改這一行，所有 service 都會跟著更新。
  // 結尾不要加斜線。
  static const String serverUrl =
      'https://nicholas-output-measuring-wear.trycloudflare.com';

  // 以下為早期預留的範例設定，目前沒有程式使用，保留待之後整理。
  static const String baseUrl = 'http://localhost:8000/api/v1';

  // 請求連線逾時（毫秒）
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 10000;

  // 認證相關端點
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // 首頁與動態牆端點
  static const String homeSummary = '/home/summary';
  static const String wallPosts = '/wall/posts';
  static const String notifications = '/notifications';
  static const String markAllNotificationsRead = '/notifications/read-all';
}