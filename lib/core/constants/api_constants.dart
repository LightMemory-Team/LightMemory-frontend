/// 後端 API 網址與 Endpoints 常數表
/// （待後端提供正式 API 文件後填入詳細端點）
class ApiConstants {
  // 基礎伺服器網址（範例預留，依後端伺服器 IP/網域修改）
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
