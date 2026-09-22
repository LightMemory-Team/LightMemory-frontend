import 'package:image_picker/image_picker.dart';
import '../models/diary_model.dart';
import '../models/diary_reply_model.dart';

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
/// 目前全部回傳假資料，方法簽名照 API 需求表 D-1~D-7；
/// 之後接後端時只改每個方法「內部」的實作，畫面呼叫端完全不用改。
class DiaryService {
  /// D-1：月曆列表
  Future<DiaryMonthResult> getDiaryList({String? month}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return DiaryMonthResult(
      month: month ?? '2026-09',
      hasTodayDiary: false,
      diaries: [
        DiarySummaryModel.fromJson({
          'diary_id': 31,
          'date': '2026-09-10',
          'title': '高雄營隊趣聊記 🎉',
          'photo_url': 'https://picsum.photos/seed/31/400/300',
          'post_text': '我們在高雄小學，和孩子們一起參加三天的營隊，大家圍坐聊天，分享今天的活動點滴。',
          'created_at': '2026-09-10T02:35:00Z',
        }),
      ],
    );
  }

  /// D-2：動態回顧
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
    await Future.delayed(const Duration(seconds: 1));
    return DiaryModel.fromJson({
      'diary_id': 32,
      'date': '2026-09-22',
      'created_at': '2026-09-22T02:31:00Z',
      'status': 'pending',
      'photo_url': 'https://picsum.photos/seed/32/400/300',
      'first_question': '這張照片是在哪裡拍的呢？',
    });
  }

  /// D-4：單篇詳情
  Future<DiaryModel> getDiaryDetail(int diaryId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return DiaryModel.fromJson({
      'diary_id': diaryId,
      'date': '2026-09-22',
      'created_at': '2026-09-22T02:31:00Z',
      'status': 'processing',
      'photo_url': 'https://picsum.photos/seed/32/400/300',
      'first_question': '這張照片是在哪裡拍的呢？',
      'replies': [
        {
          'round_index': 1,
          'question': '這張照片是在哪裡拍的呢？',
          'transcript': '這是我們去高雄小學參加營隊的時候拍的。',
          'audio_url': 'https://example.com/audio32-round1.mp3',
          'is_skipped': false,
        },
      ],
      'pending_question': '聽起來很熱鬧，當天有發生什麼特別的事嗎？',
      'reply_count': 1,
      'is_finalizable': false,
      'is_done': false,
    });
  }

  /// D-5：送出一輪錄音
  Future<ReplySubmitResult> submitReply(
    int diaryId, {
    required XFile audio,
    required int roundIndex,
    bool isForced = false,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return ReplySubmitResult.fromJson({
      'round_index': roundIndex,
      'transcript': '我們跟孩子們一起圍坐聊天。',
      'audio_url': 'https://example.com/audio32-round$roundIndex.mp3',
      'ai_reply': roundIndex >= 4 ? null : '你們聚在一起的畫面一定很溫馨，那天聊了哪些特別的話題呢？',
      'reply_count': roundIndex,
      'is_finalizable': roundIndex >= 2,
      'is_done': roundIndex >= 4,
    });
  }

  /// D-6：跳過本輪（只有已回覆 ≥2 次才會被畫面呼叫，這裡不重複擋）
  Future<ReplySubmitResult> skipReply(int diaryId, {required int roundIndex}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ReplySubmitResult.fromJson({
      'round_index': roundIndex,
      'ai_reply': roundIndex >= 4 ? null : '那我們換個話題，這張照片裡你最喜歡的是什麼呢？',
      'reply_count': roundIndex,
      'is_finalizable': true,
      'is_done': roundIndex >= 4,
    });
  }

  /// D-7：生成日記（真實 API 這支會花 10~30 秒，mock 先模擬 2 秒等待）
  Future<DiaryModel> finalizeDiary(int diaryId) async {
    await Future.delayed(const Duration(seconds: 2));
    return DiaryModel.fromJson({
      'diary_id': diaryId,
      'status': 'done',
      'date': '2026-09-22',
      'created_at': '2026-09-22T02:31:00Z',
      'photo_url': 'https://picsum.photos/seed/32/400/300',
      'title': '高雄營隊趣聊記 🎉',
      'ai_response': '聽起來這三天的營隊充滿歡笑，能和孩子們一起度過真的很棒！',
      'post_text': '我們在高雄小學，和孩子們一起參加三天的營隊，大家圍坐聊天，分享今天的活動點滴，暖心又充實。',
      'hashtags': ['#高雄營隊', '#小學活動', '#親子互動'],
      'category': 'entertainment',
      'invite_text': '王奶奶今天在高雄營隊記錄了一段開心的回憶，點進來看看她說了什麼吧！',
      'is_done': true,
    });
  }
}