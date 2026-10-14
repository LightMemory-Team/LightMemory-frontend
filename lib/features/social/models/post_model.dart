// ============================================================
// 共用轉型工具
// 後端數字欄位有時會是 double，統一轉成 int，避免型別錯誤
// ============================================================

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

List<String> _toStringList(dynamic value) {
  if (value is! List) return [];
  return value.map((e) => e.toString()).toList();
}

/// 貼文或留言的作者（對應 API 需求表 7.2、7.3 的 author）
class AuthorModel {
  final int userId;
  final String displayName;
  final String? avatarUrl;

  const AuthorModel({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      userId: _toInt(json['user_id']),
      displayName: json['display_name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  /// 後端沒有回傳 author 時使用，避免畫面出錯
  static const AuthorModel unknown = AuthorModel(userId: 0, displayName: '');
}

/// 別名：對接說明（10/14）裡作者類別叫 PostAuthor，兩個名字指的是同一個東西
typedef PostAuthor = AuthorModel;

/// 社群動態貼文（對應 API 需求表 7.2；S-1、S-2、S-8、S-11 共用）
///
/// 注意：這個模型跟分享組（Wen）共用，修改欄位前請先跟對方說一聲。
class PostModel {
  final int postId;
  final String postType;
  final int? diaryId;
  final AuthorModel author;
  final bool isMine;
  final String title;
  final String photoUrl;
  final String postText;
  final List<String> hashtags;
  final String category;
  final String date;
  final DateTime postedAt;
  final int likeCount;
  final bool isLiked;
  final int commentCount;
  final int voiceReplyCount;

  /// 以下三個只有作者本人看得到；別人的貼文 shareUrl、isShareEnabled 為 null
  final String? shareUrl;
  final bool? isShareEnabled;
  final String inviteText;

  final List<String> suggestedReplies;

  PostModel({
    required this.postId,
    this.postType = 'diary',
    this.diaryId,
    this.author = AuthorModel.unknown,
    this.isMine = false,
    required this.title,
    required this.photoUrl,
    required this.postText,
    required this.hashtags,
    required this.category,
    required this.date,
    required this.postedAt,
    required this.likeCount,
    required this.isLiked,
    this.commentCount = 0,
    required this.voiceReplyCount,
    this.shareUrl,
    this.isShareEnabled,
    required this.inviteText,
    required this.suggestedReplies,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawAuthor = json['author'];

    return PostModel(
      postId: _toInt(json['post_id']),
      postType: json['post_type']?.toString() ?? 'diary',
      diaryId: _toIntOrNull(json['diary_id']),
      author: rawAuthor is Map<String, dynamic>
          ? AuthorModel.fromJson(rawAuthor)
          : AuthorModel.unknown,
      isMine: json['is_mine'] == true,
      title: json['title']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString() ?? '',
      postText: json['post_text']?.toString() ?? '',
      hashtags: _toStringList(json['hashtags']),
      category: json['category']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      postedAt:
          DateTime.tryParse(json['posted_at']?.toString() ?? '') ??
          DateTime.now(),
      likeCount: _toInt(json['like_count']),
      isLiked: json['is_liked'] == true,
      commentCount: _toInt(json['comment_count']),
      voiceReplyCount: _toInt(json['voice_reply_count']),
      shareUrl: json['share_url']?.toString(),
      isShareEnabled: json['is_share_enabled'] as bool?,
      inviteText: json['invite_text']?.toString() ?? '',
      suggestedReplies: _toStringList(json['suggested_replies']),
    );
  }

  /// 按讚後用來更新畫面，其他欄位維持不變
  PostModel copyWith({int? likeCount, bool? isLiked, int? commentCount}) {
    return PostModel(
      postId: postId,
      postType: postType,
      diaryId: diaryId,
      author: author,
      isMine: isMine,
      title: title,
      photoUrl: photoUrl,
      postText: postText,
      hashtags: hashtags,
      category: category,
      date: date,
      postedAt: postedAt,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      commentCount: commentCount ?? this.commentCount,
      voiceReplyCount: voiceReplyCount,
      shareUrl: shareUrl,
      isShareEnabled: isShareEnabled,
      inviteText: inviteText,
      suggestedReplies: suggestedReplies,
    );
  }
}

/// 語音加油（對應 S-5 列表項目）
///
/// 11 月由分享組（Wen）處理，動態牆這次不使用。
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

/// 文字留言（對應 API 需求表 7.3；S-13 列表、S-14 新增）
class CommentModel {
  final int commentId;

  /// 保留給舊程式使用，值與 author.displayName 相同
  final String senderName;
  final AuthorModel author;
  final bool isMine;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.commentId,
    required this.senderName,
    this.author = AuthorModel.unknown,
    this.isMine = false,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawAuthor = json['author'];
    final AuthorModel author = rawAuthor is Map<String, dynamic>
        ? AuthorModel.fromJson(rawAuthor)
        : AuthorModel.unknown;

    return CommentModel(
      commentId: _toInt(json['comment_id']),
      senderName: json['sender_name']?.toString() ?? author.displayName,
      author: author,
      isMine: json['is_mine'] == true,
      text: json['text']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}