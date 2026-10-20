import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/network/auth_headers.dart';
import '../models/dashboard_models.dart';

/// 健康儀表板的資料來源，對應後端「儀表板與週報表 API 規格書」。
///
/// 沒登入或 token 無效（401）時丟出 [NotLoggedInException]，畫面收到後導回登入。
class DashboardService {
  static const String _baseUrl = '${ApiConstants.serverUrl}/api/dashboard/';

  /// 週報每次打開後端都會呼叫 OpenAI，會慢 1～2 秒，逾時抓寬一點
  static const Duration _timeout = Duration(seconds: 20);

  /// 送出 GET，回傳後端的整包 `{success, data, error}`。
  /// 「資料不足」也是 HTTP 200（success: false），交給呼叫端判斷。
  Future<Map<String, dynamic>> _get(String path) async {
    final response = await http
        .get(Uri.parse('$_baseUrl$path'), headers: await authHeaders())
        .timeout(_timeout);

    if (response.statusCode == 401) {
      throw const NotLoggedInException();
    }

    Map<String, dynamic> json;
    try {
      json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('伺服器回應格式錯誤（${response.statusCode}）');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = json['error'];
      if (error is Map && error['message'] != null) {
        throw Exception(error['message'] as String);
      }
      throw Exception('發生錯誤（${response.statusCode}）');
    }
    return json;
  }

  /// 儀表板首頁：雷達圖（已解鎖）或解鎖進度（未解鎖）
  Future<DashboardOverview> getOverview() async {
    final json = await _get('');
    final success = json['success'] as bool? ?? false;
    final error = json['error'] as Map<String, dynamic>?;
    if (!success && error?['code'] != 'INSUFFICIENT_DATA') {
      throw Exception(error?['message'] ?? '儀表板資料讀取失敗');
    }
    return DashboardOverview.fromApi(
      success: success,
      data: json['data'] as Map<String, dynamic>? ?? {},
      mockStatus: _mockStatus,
      mockPeerAverage: _mockPeerAverage,
    );
  }

  /// 週報表：上一個完整的週（週一到週日）
  Future<WeeklyReport> getWeeklyReport() async {
    final json = await _get('weekly-report/');
    if (json['success'] != true) {
      final error = json['error'] as Map<String, dynamic>?;
      throw Exception(error?['message'] ?? '週報表資料讀取失敗');
    }
    return WeeklyReport.fromJson(json['data'] as Map<String, dynamic>);
  }
}

// 狀態卡片、同齡平均後端沒有提供，等跟後端討論後再決定，先維持原本的假資料

const Map<String, dynamic> _mockStatus = {
  'type': 'keep',
  'title': '請保持!',
  'message': '最近狀態很不錯喔，繼續保持!',
};

const Map<String, dynamic> _mockPeerAverage = {
  'working_memory': 60,
  'attention': 62,
  'math': 58,
  'visual_spatial': 60,
  'executive_function': 58,
  'language': 60,
};
