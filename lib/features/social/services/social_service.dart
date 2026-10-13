import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';

/// 社群動態與語音加油資料服務（mock 版）
///
/// 動態牆（S-2、S-8、S-11、S-13、S-14）：欣紜
/// 分享、語音加油（S-1、S-5、S-6、S-7）：分享組（Wen）
///
/// 目前全部是假資料，10/17 對接時再換成真實 API。
class SocialService {
  // ============================================================
  // 動態牆假資料
  //
  // 用 static 存在記憶體裡，按讚、留言後切換頁面數字也會保留，
  // 方便測試畫面。重新啟動 App 會恢復原狀。
  // ============================================================

  static final List<Map<String, dynamic>> _mockPosts = [
    {
      'post_id': 8,
      'post_type': 'diary',
      'diary_id': 31,
      'author': {'user_id': 5, 'display_name': '林奶奶', 'avatar_url': null},
      'is_mine': false,
      'title': '花燈圈圈樂 ✨',
      'photo_url': 'https://picsum.photos/seed/30/400/300',
      'post_text': '這個週末跟朋友去逛花燈，玩得很開心。',
      'hashtags': ['#花燈', '#朋友聚會', '#長者生活'],
      'category': 'entertainment',
      'date': '2026-10-11',
      'posted_at': '2026-10-11T09:00:00+08:00',
      'like_count': 1,
      'is_liked': false,
      'comment_count': 2,
      'voice_reply_count': 0,
      'share_url': null,
      'is_share_enabled': null,
      'invite_text': '',
      'suggested_replies': ['花燈一定很漂亮吧！', '看起來好熱鬧，下次帶我去～', '你拍的照片真好看！'],
    },
    {
      'post_id': 7,
      'post_type': 'diary',
      'diary_id': 29,
      'author': {'user_id': 1, 'display_name': '我', 'avatar_url': null},
      'is_mine': true,
      'title': '早晨公園散步 🌳',
      'photo_url': 'https://picsum.photos/seed/41/400/300',
      'post_text': '今天早上去公園散步，遇到好多一起運動的老朋友，空氣很好。',
      'hashtags': ['#散步', '#公園', '#運動'],
      'category': 'health',
      'date': '2026-10-10',
      'posted_at': '2026-10-10T07:30:00+08:00',
      'like_count': 3,
      'is_liked': false,
      'comment_count': 1,
      'voice_reply_count': 0,
      'share_url': 'https://example.com/share/Ab12Cd34Ef56Gh78Ij90Kl/',
      'is_share_enabled': true,
      'invite_text': '今天去公園散步，點進來看看吧！',
      'suggested_replies': ['公園空氣一定很好！', '下次一起去走走～'],
    },
    {
      'post_id': 6,
      'post_type': 'diary',
      'diary_id': 27,
      'author': {'user_id': 8, 'display_name': '陳爺爺', 'avatar_url': null},
      'is_mine': false,
      'title': '孫子來家裡玩 🎈',
      'photo_url': 'https://picsum.photos/seed/52/400/300',
      'post_text': '孫子放假來家裡玩，一起包水餃，雖然形狀歪歪的，但吃起來特別香。',
      'hashtags': ['#家人', '#包水餃', '#天倫之樂'],
      'category': 'family',
      'date': '2026-10-08',
      'posted_at': '2026-10-08T18:20:00+08:00',
      'like_count': 5,
      'is_liked': true,
      'comment_count': 0,
      'voice_reply_count': 0,
      'share_url': null,
      'is_share_enabled': null,
      'invite_text': '',
      'suggested_replies': ['水餃看起來好好吃！', '跟孫子一起真溫馨～'],
    },
  ];

  static final Map<int, List<Map<String, dynamic>>> _mockComments = {
    8: [
      {
        'comment_id': 1,
        'sender_name': '陳爺爺',
        'author': {'user_id': 8, 'display_name': '陳爺爺', 'avatar_url': null},
        'is_mine': false,
        'text': '花燈好漂亮！',
        'created_at': '2026-10-11T10:00:00+08:00',
      },
      {
        'comment_id': 2,
        'sender_name': '我',
        'author': {'user_id': 1, 'display_name': '我', 'avatar_url': null},
        'is_mine': true,
        'text': '看起來好熱鬧，下次一起去～',
        'created_at': '2026-10-11T11:30:00+08:00',
      },
    ],
    7: [
      {
        'comment_id': 3,
        'sender_name': '林奶奶',
        'author': {'user_id': 5, 'display_name': '林奶奶', 'avatar_url': null},
        'is_mine': false,
        'text': '早上散步對身體很好喔！',
        'created_at': '2026-10-10T09:00:00+08:00',
      },
    ],
    6: [],
  };

  static int _nextCommentId = 100;

  Map<String, dynamic> _findMockPost(int postId) {
    return _mockPosts.firstWhere(
      (post) => post['post_id'] == postId,
      orElse: () => throw Exception('找不到這則貼文'),
    );
  }

  // ============================================================
  // 動態牆（欣紜）
  // ============================================================

  /// S-2：動態牆列表（依分享時間由新到舊）
  Future<List<PostModel>> getPosts({int page = 1}) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 假資料只有一頁
    if (page > 1) return [];

    return _mockPosts.map(PostModel.fromJson).toList();
  }

  /// S-11：單則貼文詳情
  Future<PostModel> getPost(int postId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return PostModel.fromJson(_findMockPost(postId));
  }

  /// S-8：按讚／取消按讚
  ///
  /// 回傳更新後的貼文，畫面直接用回傳的 likeCount、isLiked 更新。
  Future<PostModel> toggleLike(int postId, {required bool like}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final post = _findMockPost(postId);
    final bool wasLiked = post['is_liked'] == true;

    // 跟後端規則一致：重複按讚、重複取消都不會報錯，只回傳目前狀態
    if (like && !wasLiked) {
      post['is_liked'] = true;
      post['like_count'] = (post['like_count'] as int) + 1;
    } else if (!like && wasLiked) {
      post['is_liked'] = false;
      post['like_count'] = (post['like_count'] as int) - 1;
    }

    return PostModel.fromJson(post);
  }

  /// S-13：留言列表（依留言時間由舊到新）
  Future<List<CommentModel>> getComments(int postId, {int page = 1}) async {
    await Future.delayed(const Duration(milliseconds: 400));

    _findMockPost(postId);

    if (page > 1) return [];

    final comments = _mockComments[postId] ?? [];
    return comments.map(CommentModel.fromJson).toList();
  }

  /// S-14：新增文字留言
  Future<CommentModel> submitTextComment(int postId, String text) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final String trimmed = text.trim();

    // 跟後端規則一致：不可為空、不超過 200 字
    if (trimmed.isEmpty || trimmed.length > 200) {
      throw Exception('留言不可為空，且不超過 200 字');
    }

    final post = _findMockPost(postId);

    final Map<String, dynamic> comment = {
      'comment_id': _nextCommentId++,
      'sender_name': '我',
      'author': {'user_id': 1, 'display_name': '我', 'avatar_url': null},
      'is_mine': true,
      'text': trimmed,
      'created_at': DateTime.now().toIso8601String(),
    };

    _mockComments.putIfAbsent(postId, () => []).add(comment);
    post['comment_count'] = (post['comment_count'] as int) + 1;

    return CommentModel.fromJson(comment);
  }

  // ============================================================
  // 分享、語音加油（分享組 Wen，動態牆這次不使用，請勿修改）
  // ============================================================

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
}