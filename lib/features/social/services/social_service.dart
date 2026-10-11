import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';

/// 社群動態與語音加油資料服務（mock 版）
class SocialService {
  /// S-1：分享日記到社群動態
  Future<PostModel> shareDiary(int diaryId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return PostModel.fromJson({
      'post_id': 8,
      'diary_id': diaryId,
      'title': '高雄營隊趣聊記 🎉',
      'photo_url': 'https://picsum.photos/seed/32/400/300',
      'post_text': '我們在高雄小學，和孩子們一起參加三天的營隊，大家圍坐聊天，分享今天的活動點滴，暖心又充實。',
      'hashtags': ['#高雄營隊', '#小學活動', '#親子互動'],
      'category': 'entertainment',
      'date': '2026-09-22',
      'posted_at': '2026-09-22T02:40:00Z',
      'like_count': 0,
      'is_liked': false,
      'voice_reply_count': 0,
      'share_url': 'https://example.com/share/Zk3v9QpX2mLw7RtA5nHc8Q/',
      'invite_text': '王奶奶今天在高雄營隊記錄了一段開心的回憶，點進來看看她說了什麼吧！',
      'suggested_replies': ['營隊一定很有趣吧！', '看到你和孩子們相處真溫馨～', '下次也帶我一起去！'],
    });
  }

  /// S-2：社群動態列表
  Future<List<PostModel>> getPosts({int page = 1}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      PostModel.fromJson({
        'post_id': 8,
        'diary_id': 31,
        'title': '花燈圈圈樂 ✨',
        'photo_url': 'https://picsum.photos/seed/30/400/300',
        'post_text': '這個週末跟朋友去逛花燈，玩得很開心。',
        'hashtags': ['#花燈', '#朋友聚會', '#長者生活'],
        'category': 'entertainment',
        'date': '2026-09-09',
        'posted_at': '2026-09-09T08:10:00Z',
        'like_count': 1,
        'is_liked': false,
        'voice_reply_count': 1,
        'share_url': 'https://example.com/share/Zk3v9QpX2mLw7RtA5nHc8Q/',
        'invite_text': '林奶奶昨天逛花燈玩得很開心，點進來看看她說了什麼吧！',
        'suggested_replies': ['花燈一定很漂亮吧！', '看起來好熱鬧，下次帶我去～', '你拍的照片真好看！'],
      }),
    ];
  }

  /// S-5：某貼文的語音加油列表
  Future<List<VoiceReplyModel>> getVoiceReplies(int postId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      VoiceReplyModel.fromJson({
        'voice_reply_id': 12,
        'sender_name': '孫女小玲',
        'audio_url': 'https://example.com/reply12.mp3',
        'transcribed_text': '',
        'is_transcribed': false,
        'created_at': '2026-09-09T08:10:00Z',
      }),
    ];
  }

  /// S-6：App 內送出語音加油
  Future<VoiceReplyModel> submitVoiceReply(int postId, XFile audio) async {
    await Future.delayed(const Duration(seconds: 1));
    return VoiceReplyModel.fromJson({
      'voice_reply_id': 13,
      'sender_name': '孫女小玲',
      'audio_url': 'https://example.com/reply13.mp3',
      'transcribed_text': '',
      'is_transcribed': false,
      'created_at': '2026-09-22T09:00:00Z',
    });
  }

  /// 文字留言（草案功能，之後要補 API 需求表）
  Future<CommentModel> submitTextComment(int postId, String text) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return CommentModel.fromJson({
      'comment_id': 1,
      'sender_name': '孫女小玲',
      'text': text,
      'created_at': '2026-09-22T09:05:00Z',
    });
  }

  /// S-7：語音加油一鍵轉文字
  Future<VoiceReplyModel> transcribeVoiceReply(int voiceReplyId) async {
    await Future.delayed(const Duration(seconds: 1));
    return VoiceReplyModel.fromJson({
      'voice_reply_id': voiceReplyId,
      'sender_name': '孫女小玲',
      'audio_url': 'https://example.com/reply12.mp3',
      'transcribed_text': '看到你用心陪伴孩子真令人感動',
      'is_transcribed': true,
      'created_at': '2026-09-09T08:10:00Z',
    });
  }

  /// S-8：按讚／取消按讚
  Future<PostModel> toggleLike(int postId, {required bool like}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return PostModel.fromJson({
      'post_id': postId,
      'diary_id': 31,
      'title': '花燈圈圈樂 ✨',
      'photo_url': 'https://picsum.photos/seed/30/400/300',
      'post_text': '這個週末跟朋友去逛花燈，玩得很開心。',
      'hashtags': ['#花燈', '#朋友聚會', '#長者生活'],
      'category': 'entertainment',
      'date': '2026-09-09',
      'posted_at': '2026-09-09T08:10:00Z',
      'like_count': like ? 2 : 1,
      'is_liked': like,
      'voice_reply_count': 1,
      'share_url': 'https://example.com/share/Zk3v9QpX2mLw7RtA5nHc8Q/',
      'invite_text': '林奶奶昨天逛花燈玩得很開心，點進來看看她說了什麼吧！',
      'suggested_replies': ['花燈一定很漂亮吧！', '看起來好熱鬧，下次帶我去～', '你拍的照片真好看！'],
    });
  }
}