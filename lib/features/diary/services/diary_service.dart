import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/diary_model.dart';
import '../models/diary_reply_model.dart';
import '../../../core/network/auth_headers.dart';
import '../../../core/constants/api_constants.dart';

/// D-1 回應的外層包裝
class DiaryMonthResult {
  final String month;
  final bool hasTodayDiary;
  final List<DiarySummaryModel> diaries;

  DiaryMonthResult({
    required this.month,
    required this.hasTodayDiary,
    required this.diaries,
  });
}

/// D-2 回應的外層包裝
class DiaryReviewResult {
  final DiaryReviewItem? yesterday;
  final DiaryReviewItem? lastYear;

  DiaryReviewResult({required this.yesterday, required this.lastYear});
}

/// 聲影日記資料服務。
/// D-1／D-3／D-5／D-7 已改接真實後端；D-2／D-4／D-6 後端尚未提供，
/// 暫時維持假資料，等後端補齊再換（換的時候畫面呼叫端完全不用改）。
class DiaryService {
  static const String _baseUrl = '${ApiConstants.serverUrl}/api/diary/';

  /// 統一解析後端 `{"data": {...}}` 成功格式／`{"error": {...}}`
  /// 或 `{"detail": "..."}`（例如 token 過期）失敗格式。
  Map<String, dynamic> _unwrap(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('伺服器回應格式錯誤（${response.statusCode}）');
    }
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        json.containsKey('data')) {
      return json['data'] as Map<String, dynamic>;
    }
    final error = json['error'];
    if (error is Map && error['message'] != null) {
      throw Exception(error['message'] as String);
    }
    final detail = json['detail'];
    if (detail is String) {
      throw Exception(detail);
    }
    throw Exception('發生錯誤（${response.statusCode}）');
  }

  /// D-3／D-7 回傳的內容不一定包含 `date`／聊天室進度相關欄位
  /// （不同 API 階段後端本來就不負責回傳這些），這裡補上預設值，
  /// 避免 DiaryModel.fromJson 因為欄位是 required 而噴錯。
  Map<String, dynamic> _fillMissingDiaryFields(Map<String, dynamic> data) {
    final merged = <String, dynamic>{
      'date': '',
      'reply_count': 0,
      'is_finalizable': false,
      'is_done': false,
      'first_question': '',
      'replies': [],
      'pending_question': null,
      'ai_response': '',
      'post_text': '',
      'hashtags': [],
      'category': '',
      'is_shared': false,
      'share_url': null,
      'invite_text': '',
      'title': '',
      ...data,
    };

    // 有些後端回應（例如建立日記時）只有 created_at，沒有 date，
    // 這裡用 created_at 推算出 YYYY-MM-DD 格式的 date 補上，
    // 避免 DiaryModel.fromJson 的 `json['date'] as String` 因為 null 而炸掉。
    final dateValue = merged['date'];
    final needsDateFallback =
        dateValue == null || (dateValue is String && dateValue.isEmpty);
    if (needsDateFallback && merged['created_at'] != null) {
      final createdAt = DateTime.tryParse(merged['created_at'] as String);
      if (createdAt != null) {
        merged['date'] =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
      }
    }

    return merged;
  }

  /// D-1：月曆列表
  Future<DiaryMonthResult> getDiaryList({String? month}) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: month != null ? {'month': month} : null,
    );
    final response = await http.get(uri, headers: await authHeaders(json: false));
    final data = _unwrap(response);
    return DiaryMonthResult(
      month: data['month'] as String,
      hasTodayDiary: data['has_today_diary'] as bool? ?? false,
      diaries: (data['diaries'] as List<dynamic>? ?? [])
          .map((e) => DiarySummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// D-2：動態回顧（後端尚未提供，維持假資料）
  Future<DiaryReviewResult> getDiaryReview() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return DiaryReviewResult(
      yesterday: DiaryReviewItem.fromJson({
        'diary_id': 30,
        'date': '2026-09-09',
        'title': '花燈圈圈樂 ✨',
        'photo_url': 'https://picsum.photos/seed/30/400/300',
        'post_text': '這個週末跟朋友去逛花燈，玩得很開心。',
        'audio_url': 'https://example.com/audio30-round1.mp3',
      }),
      lastYear: null,
    );
  }

  /// D-3：上傳照片、建立日記
  Future<DiaryModel> createDiary(XFile photo) async {
    final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
    request.headers.addAll(await authHeaders(json: false));
    final bytes = await photo.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes('photo', bytes, filename: photo.name),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = _unwrap(response);
    return DiaryModel.fromJson(_fillMissingDiaryFields(data));
  }

  /// D-4：單篇詳情（後端尚未提供）。
  /// 現在流程只有「剛建立完日記、馬上進聊天室」這一種情境，
  /// 聊天室頁改成直接使用 D-3 回傳的資料，不會呼叫到這支，
  /// 故意讓它丟例外，避免哪裡不小心誤用了都不知道。
  Future<DiaryModel> getDiaryDetail(int diaryId) async {
    throw UnimplementedError(
      '後端尚未提供 D-4（單篇日記詳情），請改用建立日記時（D-3）回傳的資料',
    );
  }

  /// D-5：送出一輪錄音
  Future<ReplySubmitResult> submitReply(
    int diaryId, {
    required XFile audio,
    required int roundIndex,
    bool isForced = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$diaryId/replies/');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await authHeaders(json: false));
    request.fields['round_index'] = roundIndex.toString();
    if (isForced) request.fields['force'] = '1';
    final bytes = await audio.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'audio',
        bytes,
        filename: audio.name,
        contentType: MediaType('audio', 'webm'),
      ),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = _unwrap(response);
    return ReplySubmitResult.fromJson(data);
  }

  /// D-6：跳過本輪（後端尚未提供，維持假資料——實測時這個按鈕會是假的，先知道就好）
  Future<ReplySubmitResult> skipReply(
    int diaryId, {
    required int roundIndex,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ReplySubmitResult.fromJson({
      'round_index': roundIndex,
      'ai_reply': roundIndex >= 4 ? null : '那我們換個話題，這張照片裡你最喜歡的是什麼呢？',
      'reply_count': roundIndex,
      'is_finalizable': true,
      'is_done': roundIndex >= 4,
    });
  }

  /// D-7：生成日記
  Future<DiaryModel> finalizeDiary(int diaryId) async {
    final uri = Uri.parse('$_baseUrl$diaryId/finalize/');
    final response = await http.post(uri, headers: await authHeaders(json: false));
    final data = _unwrap(response);
    return DiaryModel.fromJson(_fillMissingDiaryFields(data));
  }
}