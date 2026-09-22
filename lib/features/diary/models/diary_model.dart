import 'diary_reply_model.dart';

/// 月曆／列表用的精簡版日記資料（D-1 diaries[] 裡的單筆）
class DiarySummaryModel {
  final int diaryId;
  final String date; // YYYY-MM-DD
  final String title;
  final String photoUrl;
  final String postText;
  final DateTime createdAt;

  DiarySummaryModel({
    required this.diaryId,
    required this.date,
    required this.title,
    required this.photoUrl,
    required this.postText,
    required this.createdAt,
  });

  factory DiarySummaryModel.fromJson(Map<String, dynamic> json) {
    return DiarySummaryModel(
      diaryId: json['diary_id'] as int,
      date: json['date'] as String,
      title: json['title'] as String,
      photoUrl: json['photo_url'] as String,
      postText: json['post_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 日記狀態：pending（已上傳照片）／processing（對話進行中）／done／failed
enum DiaryStatus { pending, processing, done, failed }

DiaryStatus diaryStatusFromString(String value) {
  switch (value) {
    case 'pending':
      return DiaryStatus.pending;
    case 'processing':
      return DiaryStatus.processing;
    case 'done':
      return DiaryStatus.done;
    case 'failed':
      return DiaryStatus.failed;
    default:
      return DiaryStatus.pending;
  }
}

/// 單篇日記完整資料：D-3（建立後）、D-4（詳情）、D-7（生成後）都回傳這個形狀，
/// 只是不同階段有些欄位還沒有值（空字串／空陣列／null），跟後端規格保持一致，
/// 畫面端不用另外判斷「這支 API 有沒有回這個欄位」。
class DiaryModel {
  final int diaryId;
  final String date;
  final DateTime createdAt;
  final DiaryStatus status;
  final String photoUrl;
  final String firstQuestion;
  final List<DiaryReplyModel> replies;
  final String? pendingQuestion; // 已生成日記後為 null
  final int replyCount;
  final bool isFinalizable;
  final bool isDone;
  final String title;
  final String aiResponse;
  final String postText;
  final List<String> hashtags;
  final String category;
  final bool isShared;
  final String? shareUrl;
  final String inviteText; // finalize 之後才有值，之前為空字串

  DiaryModel({
    required this.diaryId,
    required this.date,
    required this.createdAt,
    required this.status,
    required this.photoUrl,
    required this.firstQuestion,
    required this.replies,
    required this.pendingQuestion,
    required this.replyCount,
    required this.isFinalizable,
    required this.isDone,
    required this.title,
    required this.aiResponse,
    required this.postText,
    required this.hashtags,
    required this.category,
    required this.isShared,
    required this.shareUrl,
    required this.inviteText,
  });

  factory DiaryModel.fromJson(Map<String, dynamic> json) {
    return DiaryModel(
      diaryId: json['diary_id'] as int,
      date: json['date'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: diaryStatusFromString(json['status'] as String),
      photoUrl: json['photo_url'] as String,
      firstQuestion: json['first_question'] as String? ?? '',
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map((e) => DiaryReplyModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingQuestion: json['pending_question'] as String?,
      replyCount: json['reply_count'] as int? ?? 0,
      isFinalizable: json['is_finalizable'] as bool? ?? false,
      isDone: json['is_done'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      aiResponse: json['ai_response'] as String? ?? '',
      postText: json['post_text'] as String? ?? '',
      hashtags: (json['hashtags'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      category: json['category'] as String? ?? '',
      isShared: json['is_shared'] as bool? ?? false,
      shareUrl: json['share_url'] as String?,
      inviteText: json['invite_text'] as String? ?? '',
    );
  }
}

/// D-2 動態回顧：昨天／去年的今天，任一天沒有日記時為 null
class DiaryReviewItem {
  final int diaryId;
  final String date;
  final String title;
  final String photoUrl;
  final String postText;
  final String audioUrl;

  DiaryReviewItem({
    required this.diaryId,
    required this.date,
    required this.title,
    required this.photoUrl,
    required this.postText,
    required this.audioUrl,
  });

  factory DiaryReviewItem.fromJson(Map<String, dynamic> json) {
    return DiaryReviewItem(
      diaryId: json['diary_id'] as int,
      date: json['date'] as String,
      title: json['title'] as String,
      photoUrl: json['photo_url'] as String,
      postText: json['post_text'] as String,
      audioUrl: json['audio_url'] as String,
    );
  }
}