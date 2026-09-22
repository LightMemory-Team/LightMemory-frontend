/// 對應 D-4 詳情裡 replies[] 的單輪資料
class DiaryReplyModel {
  final int roundIndex;
  final String question;
  final String transcript;
  final String audioUrl;
  final bool isSkipped;

  DiaryReplyModel({
    required this.roundIndex,
    required this.question,
    required this.transcript,
    required this.audioUrl,
    required this.isSkipped,
  });

  factory DiaryReplyModel.fromJson(Map<String, dynamic> json) {
    return DiaryReplyModel(
      roundIndex: json['round_index'] as int,
      question: json['question'] as String? ?? '',
      transcript: json['transcript'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? '',
      isSkipped: json['is_skipped'] as bool? ?? false,
    );
  }
}

/// D-5（送出一輪錄音）與 D-6（跳過本輪）的回應形狀相同，共用這個模型
class ReplySubmitResult {
  final int roundIndex;
  final String? transcript; // 跳過時沒有這個欄位
  final String? audioUrl;
  final String? aiReply; // 第 4 輪結束後為 null
  final int replyCount;
  final bool isFinalizable;
  final bool isDone;

  ReplySubmitResult({
    required this.roundIndex,
    this.transcript,
    this.audioUrl,
    this.aiReply,
    required this.replyCount,
    required this.isFinalizable,
    required this.isDone,
  });

  factory ReplySubmitResult.fromJson(Map<String, dynamic> json) {
    return ReplySubmitResult(
      roundIndex: json['round_index'] as int,
      transcript: json['transcript'] as String?,
      audioUrl: json['audio_url'] as String?,
      aiReply: json['ai_reply'] as String?,
      replyCount: json['reply_count'] as int,
      isFinalizable: json['is_finalizable'] as bool,
      isDone: json['is_done'] as bool,
    );
  }
}