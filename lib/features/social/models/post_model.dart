/// 社群動態貼文（對應 S-2 列表項目）
class PostModel {
  final int postId;
  final int diaryId;
  final String title;
  final String photoUrl;
  final String postText;
  final List<String> hashtags;
  final String category;
  final String date;
  final DateTime postedAt;
  final int likeCount;
  final bool isLiked;
  final int voiceReplyCount;
  final String shareUrl;
  final String inviteText;
  final List<String> suggestedReplies;

  PostModel({
    required this.postId,
    required this.diaryId,
    required this.title,
    required this.photoUrl,
    required this.postText,
    required this.hashtags,
    required this.category,
    required this.date,
    required this.postedAt,
    required this.likeCount,
    required this.isLiked,
    required this.voiceReplyCount,
    required this.shareUrl,
    required this.inviteText,
    required this.suggestedReplies,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      postId: json['post_id'] as int,
      diaryId: json['diary_id'] as int,
      title: json['title'] as String,
      photoUrl: json['photo_url'] as String,
      postText: json['post_text'] as String,
      hashtags: (json['hashtags'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      category: json['category'] as String,
      date: json['date'] as String,
      postedAt: DateTime.parse(json['posted_at'] as String),
      likeCount: json['like_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      voiceReplyCount: json['voice_reply_count'] as int? ?? 0,
      shareUrl: json['share_url'] as String,
      inviteText: json['invite_text'] as String? ?? '',
      suggestedReplies: (json['suggested_replies'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// 語音加油（對應 S-5 列表項目）
class VoiceReplyModel {
  final int voiceReplyId;
  final String senderName;
  final String audioUrl;
  final String transcribedText;
  final bool isTranscribed;
  final DateTime createdAt;

  VoiceReplyModel({
    required this.voiceReplyId,
    required this.senderName,
    required this.audioUrl,
    required this.transcribedText,
    required this.isTranscribed,
    required this.createdAt,
  });

  factory VoiceReplyModel.fromJson(Map<String, dynamic> json) {
    return VoiceReplyModel(
      voiceReplyId: json['voice_reply_id'] as int,
      senderName: json['sender_name'] as String,
      audioUrl: json['audio_url'] as String,
      transcribedText: json['transcribed_text'] as String? ?? '',
      isTranscribed: json['is_transcribed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 文字留言（草案，這次新決定要做，API 需求表沒有規格，
/// 之後要補一份給後端；欄位先照語音加油的形狀類推）
class CommentModel {
  final int commentId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.commentId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['comment_id'] as int,
      senderName: json['sender_name'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}